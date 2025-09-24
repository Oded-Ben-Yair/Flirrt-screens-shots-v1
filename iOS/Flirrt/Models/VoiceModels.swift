import Foundation
import AVFoundation

// MARK: - Voice Clone Model
struct VoiceClone: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let status: VoiceCloneStatus
    let createdAt: Date
    let quality: VoiceQuality
    let sampleDuration: TimeInterval
    let fileSize: Int64
    let elevenLabsVoiceId: String?

    init(id: String, name: String, description: String? = nil, status: VoiceCloneStatus = .ready, createdAt: Date = Date(), quality: VoiceQuality = .good, sampleDuration: TimeInterval = 0, fileSize: Int64 = 0, elevenLabsVoiceId: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.status = status
        self.createdAt = createdAt
        self.quality = quality
        self.sampleDuration = sampleDuration
        self.fileSize = fileSize
        self.elevenLabsVoiceId = elevenLabsVoiceId
    }

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

// MARK: - Voice Script Model
struct VoiceScript: Codable, Identifiable {
    let id: String
    let title: String
    let content: String
    let category: ScriptCategory
    let emotion: VoiceEmotion
    let estimatedDuration: TimeInterval
    let difficulty: ScriptDifficulty
    let tags: [String]
    let icon: String

    init(id: String = UUID().uuidString, title: String, content: String, category: ScriptCategory, emotion: VoiceEmotion, estimatedDuration: TimeInterval, difficulty: ScriptDifficulty, tags: [String] = [], icon: String) {
        self.id = id
        self.title = title
        self.content = content
        self.category = category
        self.emotion = emotion
        self.estimatedDuration = estimatedDuration
        self.difficulty = difficulty
        self.tags = tags
        self.icon = icon
    }

    var formattedDuration: String {
        let minutes = Int(estimatedDuration) / 60
        let seconds = Int(estimatedDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Script Category
enum ScriptCategory: String, Codable, CaseIterable {
    case introduction = "introduction"
    case conversation = "conversation"
    case storytelling = "storytelling"
    case practice = "practice"
    case custom = "custom"

    var displayName: String {
        switch self {
        case .introduction:
            return "Introduction"
        case .conversation:
            return "Conversation"
        case .storytelling:
            return "Storytelling"
        case .practice:
            return "Practice"
        case .custom:
            return "Custom"
        }
    }

    var description: String {
        switch self {
        case .introduction:
            return "Scripts for personal introductions and self-presentation"
        case .conversation:
            return "Natural conversation starters and responses"
        case .storytelling:
            return "Engaging stories and anecdotes"
        case .practice:
            return "Voice training and pronunciation exercises"
        case .custom:
            return "Your own personalized scripts"
        }
    }

    var color: String {
        switch self {
        case .introduction:
            return "blue"
        case .conversation:
            return "green"
        case .storytelling:
            return "purple"
        case .practice:
            return "orange"
        case .custom:
            return "pink"
        }
    }
}

// MARK: - Script Difficulty
enum ScriptDifficulty: String, Codable, CaseIterable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"

    var displayName: String {
        return rawValue.capitalized
    }

    var stars: Int {
        switch self {
        case .beginner:
            return 1
        case .intermediate:
            return 2
        case .advanced:
            return 3
        }
    }

    var color: String {
        switch self {
        case .beginner:
            return "green"
        case .intermediate:
            return "yellow"
        case .advanced:
            return "red"
        }
    }
}

// MARK: - Voice Request Model
struct VoiceRequest: Codable {
    let text: String
    let voiceId: String
    let timestamp: Date

    init(text: String, voiceId: String, timestamp: Date = Date()) {
        self.text = text
        self.voiceId = voiceId
        self.timestamp = timestamp
    }
}

// MARK: - Predefined Voice Scripts
extension VoiceScript {
    static let predefinedScripts: [VoiceScript] = [
        VoiceScript(
            title: "Confident Introduction",
            content: "Hey there! I'm someone who believes life's too short for boring conversations. I love exploring new places, trying foods I can't pronounce, and finding the humor in everyday situations. What about you - what makes you laugh the most?",
            category: .introduction,
            emotion: .confident,
            estimatedDuration: 15.0,
            difficulty: .beginner,
            tags: ["confident", "introduction", "humor"],
            icon: "person.badge.plus"
        ),

        VoiceScript(
            title: "Playful Conversation Starter",
            content: "Okay, I have to ask - if you could only eat one food for the rest of your life, what would it be? And please don't say pizza because that's basically cheating! I'm genuinely curious about your survival food strategy.",
            category: .conversation,
            emotion: .playful,
            estimatedDuration: 12.0,
            difficulty: .beginner,
            tags: ["playful", "question", "food"],
            icon: "bubble.left.and.bubble.right"
        ),

        VoiceScript(
            title: "Mysterious Story",
            content: "So this happened to me last week, and I still can't believe it. I was walking through the city when I noticed someone following me - but not in a creepy way, more like... they were copying every turn I made. Turns out, they were just using the same GPS route to the same coffee shop. We ended up laughing about it over lattes.",
            category: .storytelling,
            emotion: .mysterious,
            estimatedDuration: 20.0,
            difficulty: .intermediate,
            tags: ["mysterious", "story", "coincidence"],
            icon: "book.closed"
        ),

        VoiceScript(
            title: "Seductive Charm",
            content: "There's something I find incredibly attractive about someone who can make me laugh without even trying. The way you see the world, your perspective on things... it's refreshing. I'd love to know what goes on in that beautiful mind of yours.",
            category: .conversation,
            emotion: .seductive,
            estimatedDuration: 14.0,
            difficulty: .advanced,
            tags: ["seductive", "compliment", "charm"],
            icon: "heart.text.square"
        ),

        VoiceScript(
            title: "Voice Training Exercise",
            content: "Let's practice some voice control techniques. Take a deep breath and speak slowly: 'Red leather, yellow leather, red leather, yellow leather.' Now try varying your tone from low to high: 'The quick brown fox jumps over the lazy dog.' Remember to breathe from your diaphragm and project your voice clearly.",
            category: .practice,
            emotion: .casual,
            estimatedDuration: 25.0,
            difficulty: .intermediate,
            tags: ["training", "practice", "pronunciation"],
            icon: "waveform"
        )
    ]

    static func script(for category: ScriptCategory) -> [VoiceScript] {
        return predefinedScripts.filter { $0.category == category }
    }

    static func script(for emotion: VoiceEmotion) -> [VoiceScript] {
        return predefinedScripts.filter { $0.emotion == emotion }
    }

    static func script(for difficulty: ScriptDifficulty) -> [VoiceScript] {
        return predefinedScripts.filter { $0.difficulty == difficulty }
    }
}