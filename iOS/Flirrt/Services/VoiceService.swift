import Foundation
import AVFoundation
import UIKit

/**
 * Voice Service - ElevenLabs Integration
 * CRITICAL: Voice recording and processing ONLY in main app (NOT keyboard extension)
 *
 * Features:
 * - Voice cloning with ElevenLabs API
 * - Text-to-speech synthesis
 * - Audio mixing with background sounds
 * - Voice sample recording with AVAudioRecorder
 */
class VoiceService: NSObject {
    static let shared = VoiceService()

    private let apiClient = APIClient.shared
    private let appGroupID = "group.com.flirrt"

    // Audio recording
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingSession: AVAudioSession?

    // Voice clone storage
    private var currentVoiceCloneID: String?

    // Background sounds
    enum BackgroundSound: String, CaseIterable {
        case none = "None"
        case beach = "Beach Waves"
        case party = "Party Ambience"
        case forest = "Forest Nature"

        var filename: String? {
            switch self {
            case .none: return nil
            case .beach: return "beach"
            case .party: return "party"
            case .forest: return "forest"
            }
        }
    }

    private override init() {
        super.init()
        loadVoiceCloneID()
    }

    // MARK: - Microphone Permission

    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if granted {
                    print("🎤 Microphone permission granted")
                } else {
                    print("❌ Microphone permission denied")
                }
                completion(granted)
            }
        }
    }

    func checkMicrophonePermission() -> AVAudioSession.RecordPermission {
        return AVAudioSession.sharedInstance().recordPermission
    }

    // MARK: - Voice Recording

    func startRecording(completion: @escaping (Result<URL, Error>) -> Void) {
        // Request permission first
        requestMicrophonePermission { [weak self] granted in
            guard granted else {
                completion(.failure(VoiceError.microphonePermissionDenied))
                return
            }

            self?.setupRecordingSession()
            self?.beginRecording(completion: completion)
        }
    }

    private func setupRecordingSession() {
        recordingSession = AVAudioSession.sharedInstance()

        do {
            try recordingSession?.setCategory(.playAndRecord, mode: .default)
            try recordingSession?.setActive(true)
            print("✅ Audio session configured for recording")
        } catch {
            print("❌ Failed to setup audio session: \(error.localizedDescription)")
        }
    }

    private func beginRecording(completion: @escaping (Result<URL, Error>) -> Void) {
        // Create temporary recording file
        let recordingURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("voice_sample_\(UUID().uuidString).m4a")

        // Configure audio settings (ElevenLabs requires specific format)
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()

            print("🎙️ Recording started: \(recordingURL.lastPathComponent)")

            // Auto-stop after 30 seconds (ElevenLabs recommendation: 10-30 seconds)
            DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
                self?.stopRecording(completion: completion)
            }

        } catch {
            print("❌ Recording failed: \(error.localizedDescription)")
            completion(.failure(error))
        }
    }

    func stopRecording(completion: @escaping (Result<URL, Error>) -> Void) {
        guard let recorder = audioRecorder, recorder.isRecording else {
            completion(.failure(VoiceError.notRecording))
            return
        }

        let recordingURL = recorder.url
        recorder.stop()

        print("⏹️ Recording stopped: \(recordingURL.lastPathComponent)")
        completion(.success(recordingURL))
    }

    func cancelRecording() {
        audioRecorder?.stop()
        audioRecorder?.deleteRecording()
        audioRecorder = nil
        print("🚫 Recording cancelled")
    }

    // MARK: - Voice Cloning

    func uploadVoiceClone(audioURL: URL, userId: String) async throws -> String {
        // Read audio data
        let audioData = try Data(contentsOf: audioURL)

        print("📤 Uploading voice sample: \(audioData.count) bytes")

        // Upload to backend (which calls ElevenLabs)
        let response = try await apiClient.uploadVoiceClone(audioData: audioData, userId: userId)

        // Save voice clone ID
        currentVoiceCloneID = response.voiceId
        saveVoiceCloneID(response.voiceId)

        print("✅ Voice clone created: \(response.voiceId)")

        return response.voiceId
    }

    func hasVoiceClone() -> Bool {
        return currentVoiceCloneID != nil
    }

    func getVoiceCloneID() -> String? {
        return currentVoiceCloneID
    }

    private func saveVoiceCloneID(_ voiceID: String) {
        UserDefaults.standard.set(voiceID, forKey: "userVoiceCloneID")

        // Also save to App Group for keyboard access (if needed)
        if let sharedDefaults = UserDefaults(suiteName: appGroupID) {
            sharedDefaults.set(voiceID, forKey: "userVoiceCloneID")
            sharedDefaults.synchronize()
        }
    }

    private func loadVoiceCloneID() {
        currentVoiceCloneID = UserDefaults.standard.string(forKey: "userVoiceCloneID")

        if currentVoiceCloneID != nil {
            print("📝 Loaded voice clone ID: \(currentVoiceCloneID!)")
        }
    }

    func deleteVoiceClone() {
        currentVoiceCloneID = nil
        UserDefaults.standard.removeObject(forKey: "userVoiceCloneID")

        if let sharedDefaults = UserDefaults(suiteName: appGroupID) {
            sharedDefaults.removeObject(forKey: "userVoiceCloneID")
            sharedDefaults.synchronize()
        }

        print("🗑️ Voice clone deleted")
    }

    // MARK: - Text-to-Speech

    func synthesizeSpeech(
        text: String,
        emotion: String = "confident",
        backgroundSound: BackgroundSound = .none
    ) async throws -> URL {
        guard let voiceCloneID = currentVoiceCloneID else {
            throw VoiceError.noVoiceClone
        }

        print("🎙️ Synthesizing speech: \(text.prefix(50))...")

        // Call backend API for voice synthesis
        let response = try await apiClient.synthesizeVoice(
            text: text,
            voiceId: voiceCloneID,
            emotion: emotion
        )

        // Download audio file
        guard let audioURL = URL(string: response.audioURL) else {
            throw VoiceError.invalidAudioURL
        }

        let (localURL, _) = try await URLSession.shared.download(from: audioURL)

        // Move to app's temp directory
        let destinationURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("synthesized_\(UUID().uuidString).mp3")

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }

        try FileManager.default.moveItem(at: localURL, to: destinationURL)

        print("✅ Speech synthesized: \(destinationURL.lastPathComponent)")

        // Mix with background sound if requested
        if backgroundSound != .none {
            return try await mixAudioWithBackground(voiceURL: destinationURL, background: backgroundSound)
        }

        return destinationURL
    }

    // MARK: - Audio Mixing

    private func mixAudioWithBackground(voiceURL: URL, background: BackgroundSound) async throws -> URL {
        guard let backgroundFilename = background.filename else {
            return voiceURL
        }

        print("🎵 Mixing audio with \(background.rawValue)...")

        // Load background sound from bundle
        guard let backgroundURL = Bundle.main.url(forResource: backgroundFilename, withExtension: "mp3") else {
            print("⚠️ Background sound not found: \(backgroundFilename).mp3, using original audio")
            return voiceURL
        }

        // Create composition
        let composition = AVMutableComposition()

        // Add voice track
        let voiceAsset = AVURLAsset(url: voiceURL)
        guard let voiceTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw VoiceError.audioMixingFailed
        }

        let voiceDuration = try await voiceAsset.load(.duration)
        try voiceTrack.insertTimeRange(
            CMTimeRangeMake(start: .zero, duration: voiceDuration),
            of: voiceAsset.tracks(withMediaType: .audio)[0],
            at: .zero
        )

        // Add background track
        let backgroundAsset = AVURLAsset(url: backgroundURL)
        guard let backgroundTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw VoiceError.audioMixingFailed
        }

        try backgroundTrack.insertTimeRange(
            CMTimeRangeMake(start: .zero, duration: voiceDuration),
            of: backgroundAsset.tracks(withMediaType: .audio)[0],
            at: .zero
        )

        // Create audio mix to control volumes
        let voiceParams = AVMutableAudioMixInputParameters(track: voiceTrack)
        voiceParams.setVolume(1.0, at: .zero) // Voice at 100%

        let backgroundParams = AVMutableAudioMixInputParameters(track: backgroundTrack)
        backgroundParams.setVolume(0.2, at: .zero) // Background at 20%

        let audioMix = AVMutableAudioMix()
        audioMix.inputParameters = [voiceParams, backgroundParams]

        // Export mixed audio
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("mixed_\(UUID().uuidString).m4a")

        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetAppleM4A
        ) else {
            throw VoiceError.audioMixingFailed
        }

        exportSession.audioMix = audioMix
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a

        await exportSession.export()

        if let error = exportSession.error {
            throw error
        }

        print("✅ Audio mixed successfully: \(outputURL.lastPathComponent)")

        return outputURL
    }

    // MARK: - Audio Playback

    func playAudio(url: URL, completion: @escaping (Bool) -> Void) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()

            print("▶️ Playing audio: \(url.lastPathComponent)")

        } catch {
            print("❌ Playback failed: \(error.localizedDescription)")
            completion(false)
        }
    }

    func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        print("⏹️ Audio stopped")
    }

    func isPlaying() -> Bool {
        return audioPlayer?.isPlaying ?? false
    }
}

// MARK: - AVAudioRecorderDelegate

extension VoiceService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            print("✅ Recording finished successfully")
        } else {
            print("❌ Recording failed")
        }
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        if let error = error {
            print("❌ Recording encode error: \(error.localizedDescription)")
        }
    }
}

// MARK: - AVAudioPlayerDelegate

extension VoiceService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("⏹️ Playback finished")
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        if let error = error {
            print("❌ Playback decode error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Error Types

enum VoiceError: Error, LocalizedError {
    case microphonePermissionDenied
    case notRecording
    case noVoiceClone
    case invalidAudioURL
    case audioMixingFailed

    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Microphone permission denied. Please grant permission in Settings."
        case .notRecording:
            return "No active recording session."
        case .noVoiceClone:
            return "No voice clone available. Please record your voice first."
        case .invalidAudioURL:
            return "Invalid audio URL received from server."
        case .audioMixingFailed:
            return "Failed to mix audio tracks."
        }
    }
}
