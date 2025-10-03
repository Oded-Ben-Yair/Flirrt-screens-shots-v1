import Foundation
import AVFoundation
import Combine

class VoiceRecordingManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var playbackProgress: Double = 0
    @Published var audioLevels: [Float] = []
    @Published var recordingURL: URL?
    @Published var error: VoiceRecordingError?
    @Published var permissionStatus: AVAudioSession.RecordPermission = .undetermined

    // MARK: - Constants
    private let maxRecordingDuration: TimeInterval = 180 // 3 minutes
    private let minRecordingDuration: TimeInterval = 5   // 5 seconds
    private let sampleRate: Double = 44100
    private let numberOfChannels: Int = 1

    // MARK: - Private Properties
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingTimer: Timer?
    private var levelTimer: Timer?
    private var playbackTimer: Timer?
    private var audioSession = AVAudioSession.sharedInstance()
    private var apiClient = APIClient.shared

    // MARK: - Audio Level Monitoring
    private let numberOfSamples = 60 // For waveform visualization

    override init() {
        super.init()
        setupAudioSession()
        checkPermissions()
    }

    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothHFP])
            try audioSession.setActive(true)
        } catch {
            self.error = .audioSessionError(error.localizedDescription)
        }
    }

    // MARK: - Permission Handling
    func checkPermissions() {
        permissionStatus = audioSession.recordPermission
    }

    func requestPermissions() async -> Bool {
        await withCheckedContinuation { continuation in
            audioSession.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionStatus = granted ? .granted : .denied
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    // MARK: - Recording Controls
    func startRecording() async {
        guard permissionStatus == .granted else {
            if await requestPermissions() == false {
                error = .permissionDenied
            }
            return
        }

        guard !isRecording else { return }

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("voice_sample_\(Date().timeIntervalSince1970).m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: numberOfChannels,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 128000 // 128 kbps for good quality but manageable file size
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true

            if audioRecorder?.record() == true {
                recordingURL = audioFilename
                isRecording = true
                recordingDuration = 0
                audioLevels = Array(repeating: 0.0, count: numberOfSamples)

                startRecordingTimer()
                startLevelTimer()
            } else {
                error = .recordingFailed("Failed to start recording")
            }
        } catch {
            self.error = .recordingFailed(error.localizedDescription)
        }
    }

    func stopRecording() {
        guard isRecording else { return }

        audioRecorder?.stop()
        stopRecordingTimer()
        stopLevelTimer()
        isRecording = false

        // Validate minimum duration
        if recordingDuration < minRecordingDuration {
            error = .recordingTooShort
            deleteCurrentRecording()
        }
    }

    func pauseRecording() {
        guard isRecording else { return }
        audioRecorder?.pause()
        stopRecordingTimer()
        stopLevelTimer()
    }

    func resumeRecording() {
        guard !isRecording && audioRecorder != nil else { return }

        if audioRecorder?.record() == true {
            isRecording = true
            startRecordingTimer()
            startLevelTimer()
        }
    }

    // MARK: - Playback Controls
    func startPlayback() {
        guard let url = recordingURL, !isPlaying else { return }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.enableRate = true

            if audioPlayer?.play() == true {
                isPlaying = true
                startPlaybackTimer()
            }
        } catch {
            self.error = .playbackFailed(error.localizedDescription)
        }
    }

    func stopPlayback() {
        audioPlayer?.stop()
        stopPlaybackTimer()
        isPlaying = false
        playbackProgress = 0
    }

    func pausePlayback() {
        audioPlayer?.pause()
        stopPlaybackTimer()
        isPlaying = false
    }

    func resumePlayback() {
        guard audioPlayer != nil && !isPlaying else { return }

        if audioPlayer?.play() == true {
            isPlaying = true
            startPlaybackTimer()
        }
    }

    // MARK: - File Management
    func deleteCurrentRecording() {
        guard let url = recordingURL else { return }

        try? FileManager.default.removeItem(at: url)
        recordingURL = nil
        audioLevels = []
        recordingDuration = 0
        playbackProgress = 0
    }

    func getRecordingData() -> Data? {
        guard let url = recordingURL else { return nil }
        return try? Data(contentsOf: url)
    }

    func getRecordingFileSize() -> Int64? {
        guard let url = recordingURL else { return nil }

        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64
        } catch {
            return nil
        }
    }

    // MARK: - ElevenLabs Integration
    func uploadVoiceClone(userId: String) async throws -> VoiceCloneResponse {
        guard let audioData = getRecordingData() else {
            throw VoiceRecordingError.noRecordingAvailable
        }

        // Check file size (ElevenLabs has limits)
        let maxFileSizeMB: Int64 = 25 * 1024 * 1024 // 25MB
        if let fileSize = getRecordingFileSize(), fileSize > maxFileSizeMB {
            throw VoiceRecordingError.fileTooLarge
        }

        do {
            let response = try await apiClient.uploadVoiceClone(audioData: audioData, userId: userId)
            return response
        } catch {
            throw VoiceRecordingError.uploadFailed(error.localizedDescription)
        }
    }

    // MARK: - Timer Management
    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            self.recordingDuration += 0.1

            // Auto-stop at max duration
            if self.recordingDuration >= self.maxRecordingDuration {
                self.stopRecording()
            }
        }
    }

    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }

    private func startLevelTimer() {
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.updateAudioLevels()
        }
    }

    private func stopLevelTimer() {
        levelTimer?.invalidate()
        levelTimer = nil
    }

    private func startPlaybackTimer() {
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updatePlaybackProgress()
        }
    }

    private func stopPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }

    // MARK: - Audio Level Updates
    private func updateAudioLevels() {
        guard let recorder = audioRecorder, recorder.isRecording else { return }

        recorder.updateMeters()
        let level = recorder.averagePower(forChannel: 0)

        // Convert dB to linear scale (0.0 to 1.0)
        let normalizedLevel = max(0.0, (level + 80.0) / 80.0)

        // Add to levels array and maintain size
        audioLevels.append(normalizedLevel)
        if audioLevels.count > numberOfSamples {
            audioLevels.removeFirst()
        }
    }

    private func updatePlaybackProgress() {
        guard let player = audioPlayer else { return }

        if player.duration > 0 {
            playbackProgress = player.currentTime / player.duration
        }

        if !player.isPlaying {
            stopPlaybackTimer()
            isPlaying = false

            // Reset progress if finished
            if player.currentTime >= player.duration {
                playbackProgress = 0
                player.currentTime = 0
            }
        }
    }

    // MARK: - Utility Methods
    func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func getRemainingTime() -> TimeInterval {
        return maxRecordingDuration - recordingDuration
    }

    func canRecord() -> Bool {
        return permissionStatus == .granted && !isRecording && recordingDuration < maxRecordingDuration
    }

    func hasValidRecording() -> Bool {
        return recordingURL != nil && recordingDuration >= minRecordingDuration
    }
}

// MARK: - AVAudioRecorderDelegate
extension VoiceRecordingManager: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isRecording = false
            self.stopRecordingTimer()
            self.stopLevelTimer()

            if !flag {
                self.error = .recordingFailed("Recording finished unsuccessfully")
                self.deleteCurrentRecording()
            }
        }
    }

    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        DispatchQueue.main.async {
            self.error = .recordingFailed(error?.localizedDescription ?? "Unknown encoding error")
            self.stopRecording()
        }
    }
}

// MARK: - AVAudioPlayerDelegate
extension VoiceRecordingManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
            self.playbackProgress = 0
            self.stopPlaybackTimer()

            if !flag {
                self.error = .playbackFailed("Playback finished unsuccessfully")
            }
        }
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        DispatchQueue.main.async {
            self.error = .playbackFailed(error?.localizedDescription ?? "Unknown playback error")
            self.stopPlayback()
        }
    }
}

// MARK: - Error Types
enum VoiceRecordingError: LocalizedError {
    case permissionDenied
    case audioSessionError(String)
    case recordingFailed(String)
    case playbackFailed(String)
    case recordingTooShort
    case noRecordingAvailable
    case fileTooLarge
    case uploadFailed(String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission is required to record audio."
        case .audioSessionError(let message):
            return "Audio session error: \(message)"
        case .recordingFailed(let message):
            return "Recording failed: \(message)"
        case .playbackFailed(let message):
            return "Playback failed: \(message)"
        case .recordingTooShort:
            return "Recording must be at least 5 seconds long."
        case .noRecordingAvailable:
            return "No recording available to upload."
        case .fileTooLarge:
            return "Recording file is too large for upload."
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        }
    }
}