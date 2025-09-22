import Foundation
import AVFoundation

// MARK: - Voice Clone Model
struct VoiceClone: Codable, Identifiable {
    let id: String
    let name: String
    let status: VoiceCloneStatus
    let createdAt: Date
    let quality: VoiceQuality
    let sampleDuration: TimeInterval
    let fileSize: Int64
    let elevenLabsVoiceId: String?

    var isReady: Bool {
        return status == .ready && elevenLabsVoiceId != nil
    }

    var statusDescription: String {
        switch status {
        case .processing:
            return "Processing..."
        case .ready:
            return "Ready"
        case .failed:
            return "Failed"
        case .queued:
            return "In queue"
        }
    }

    var qualityDescription: String {
        switch quality {
        case .excellent:
            return "Excellent"
        case .good:
            return "Good"
        case .fair:
            return "Fair"
        case .poor:
            return "Poor"
        }
    }
}

// MARK: - Voice Clone Status
enum VoiceCloneStatus: String, Codable, CaseIterable {
    case processing = "processing"
    case ready = "ready"
    case failed = "failed"
    case queued = "queued"
}

// MARK: - Voice Quality
enum VoiceQuality: String, Codable, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"

    var score: Double {
        switch self {
        case .excellent:
            return 0.9
        case .good:
            return 0.7
        case .fair:
            return 0.5
        case .poor:
            return 0.3
        }
    }

    static func from(score: Double) -> VoiceQuality {
        switch score {
        case 0.8...:
            return .excellent
        case 0.6..<0.8:
            return .good
        case 0.4..<0.6:
            return .fair
        default:
            return .poor
        }
    }
}

// MARK: - Voice Recording Model
struct VoiceRecording: Codable, Identifiable {
    let id: String
    let fileName: String
    let fileURL: URL
    let duration: TimeInterval
    let fileSize: Int64
    let createdAt: Date
    let quality: VoiceQuality
    let averageLevel: Float
    let isUploaded: Bool

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var formattedFileSize: String {
        return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    var createdAtFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
}

// MARK: - Voice Synthesis Request
struct VoiceSynthesisRequest: Codable {
    let text: String
    let voiceId: String
    let emotion: VoiceEmotion
    let speed: VoiceSpeed
    let stability: Double
    let similarityBoost: Double

    init(text: String, voiceId: String, emotion: VoiceEmotion = .confident, speed: VoiceSpeed = .normal, stability: Double = 0.75, similarityBoost: Double = 0.75) {
        self.text = text
        self.voiceId = voiceId
        self.emotion = emotion
        self.speed = speed
        self.stability = stability
        self.similarityBoost = similarityBoost
    }
}

// MARK: - Voice Emotion
enum VoiceEmotion: String, Codable, CaseIterable {
    case confident = "confident"
    case playful = "playful"
    case seductive = "seductive"
    case mysterious = "mysterious"
    case casual = "casual"
    case excited = "excited"

    var displayName: String {
        return rawValue.capitalized
    }

    var description: String {
        switch self {
        case .confident:
            return "Bold and assertive"
        case .playful:
            return "Fun and lighthearted"
        case .seductive:
            return "Smooth and alluring"
        case .mysterious:
            return "Intriguing and enigmatic"
        case .casual:
            return "Relaxed and natural"
        case .excited:
            return "Energetic and enthusiastic"
        }
    }
}

// MARK: - Voice Speed
enum VoiceSpeed: String, Codable, CaseIterable {
    case slow = "slow"
    case normal = "normal"
    case fast = "fast"

    var multiplier: Double {
        switch self {
        case .slow:
            return 0.8
        case .normal:
            return 1.0
        case .fast:
            return 1.2
        }
    }

    var displayName: String {
        return rawValue.capitalized
    }
}

// MARK: - Audio Configuration
struct AudioConfiguration {
    static let defaultSampleRate: Double = 44100
    static let defaultChannels: Int = 1
    static let defaultBitRate: Int = 128000
    static let maxRecordingDuration: TimeInterval = 180 // 3 minutes
    static let minRecordingDuration: TimeInterval = 5   // 5 seconds
    static let maxFileSizeMB: Int64 = 25 * 1024 * 1024  // 25MB
    static let audioFormat: String = "m4a"
    static let mimeType: String = "audio/mp4"

    static let recordingSettings: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: defaultSampleRate,
        AVNumberOfChannelsKey: defaultChannels,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        AVEncoderBitRateKey: defaultBitRate
    ]
}

// MARK: - Voice Recording Statistics
struct VoiceRecordingStats: Codable {
    let totalRecordings: Int
    let totalDuration: TimeInterval
    let averageQuality: VoiceQuality
    let lastRecordingDate: Date?
    let successfulUploads: Int

    var formattedTotalDuration: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        let seconds = Int(totalDuration) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    var uploadSuccessRate: Double {
        guard totalRecordings > 0 else { return 0 }
        return Double(successfulUploads) / Double(totalRecordings)
    }
}

// MARK: - Voice Clone Creation Request
struct VoiceCloneCreationRequest {
    let audioData: Data
    let name: String
    let description: String?
    let labels: [String]

    init(audioData: Data, name: String, description: String? = nil, labels: [String] = []) {
        self.audioData = audioData
        self.name = name
        self.description = description
        self.labels = labels
    }
}

// MARK: - ElevenLabs Voice Settings
struct ElevenLabsVoiceSettings: Codable {
    let stability: Double
    let similarityBoost: Double
    let style: Double?
    let useSpeakerBoost: Bool?

    init(stability: Double = 0.75, similarityBoost: Double = 0.75, style: Double? = nil, useSpeakerBoost: Bool? = nil) {
        self.stability = stability
        self.similarityBoost = similarityBoost
        self.style = style
        self.useSpeakerBoost = useSpeakerBoost
    }

    static let `default` = ElevenLabsVoiceSettings()
    static let highQuality = ElevenLabsVoiceSettings(stability: 0.85, similarityBoost: 0.85)
    static let creative = ElevenLabsVoiceSettings(stability: 0.60, similarityBoost: 0.90)
}