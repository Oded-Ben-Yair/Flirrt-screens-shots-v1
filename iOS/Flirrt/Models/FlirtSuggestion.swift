//
//  FlirtSuggestion.swift
//  Vibe8
//
//  Created on 2025-10-03
//  Screenshot analysis flirt suggestion model
//

import Foundation

// MARK: - FlirtSuggestion

/// AI-generated flirt suggestion from screenshot analysis
struct FlirtSuggestion: Identifiable, Codable, Sendable {
    /// Unique identifier for the suggestion
    let id: String

    /// The actual flirt message text
    let text: String

    /// Tone/style of the suggestion (e.g., "playful", "thoughtful", "direct")
    let tone: String

    /// AI confidence score (0.0 - 1.0)
    let confidence: Double

    /// AI reasoning for the suggestion (optional)
    let reasoning: String?

    /// When the suggestion was created
    let createdAt: String?

    /// Type of suggestion (opener, response, follow-up)
    let suggestionType: SuggestionType?

    // MARK: - CodingKeys
    enum CodingKeys: String, CodingKey {
        case id
        case text
        case tone
        case confidence
        case reasoning
        case createdAt = "created_at"
        case suggestionType = "suggestion_type"
    }

    // MARK: - Initializer

    init(
        id: String = UUID().uuidString,
        text: String,
        tone: String,
        confidence: Double,
        reasoning: String? = nil,
        createdAt: String? = nil,
        suggestionType: SuggestionType? = nil
    ) {
        self.id = id
        self.text = text
        self.tone = tone
        self.confidence = confidence
        self.reasoning = reasoning
        self.createdAt = createdAt
        self.suggestionType = suggestionType
    }

    // MARK: - Computed Properties

    /// User-friendly confidence label
    var confidenceLabel: String {
        switch confidence {
        case 0.8...1.0:
            return "High confidence"
        case 0.5..<0.8:
            return "Medium confidence"
        default:
            return "Low confidence"
        }
    }

    /// Emoji representation of confidence level
    var confidenceEmoji: String {
        switch confidence {
        case 0.8...1.0:
            return "🔥"
        case 0.5..<0.8:
            return "👍"
        default:
            return "💡"
        }
    }
}

// MARK: - SuggestionType

/// Type of flirt suggestion
enum SuggestionType: String, Codable, Sendable, CaseIterable {
    case opener = "opener"
    case response = "response"
    case followUp = "follow_up"
    case iceBreaker = "ice_breaker"

    var displayName: String {
        switch self {
        case .opener:
            return "Conversation Opener"
        case .response:
            return "Response"
        case .followUp:
            return "Follow-up"
        case .iceBreaker:
            return "Ice Breaker"
        }
    }

    var icon: String {
        switch self {
        case .opener:
            return "bubble.left.fill"
        case .response:
            return "bubble.right.fill"
        case .followUp:
            return "arrow.turn.down.right"
        case .iceBreaker:
            return "sparkles"
        }
    }
}

// MARK: - FlirtSuggestionResponse

/// API response wrapper for flirt suggestions (matches backend structure)
struct FlirtSuggestionResponse: Codable, Sendable {
    let success: Bool
    let data: FlirtDataResponse?
    let suggestions: [FlirtSuggestion]? // For mock/fallback responses
    let metadata: ResponseMetadata? // For mock/fallback responses
    let error: String?
    let cached: Bool?
    let message: String?

    // Computed property for easy access to suggestions
    var flirts: [FlirtSuggestion] {
        return data?.suggestions ?? suggestions ?? []
    }
}

// MARK: - FlirtDataResponse

/// Data container in the API response
struct FlirtDataResponse: Codable, Sendable {
    let suggestions: [FlirtSuggestion]
    let metadata: ResponseMetadata
}

// MARK: - ResponseMetadata

/// Additional metadata from the API
struct ResponseMetadata: Codable, Sendable {
    let suggestionType: String?
    let tone: String?
    let screenshotId: String?
    let totalSuggestions: Int?
    let generatedAt: String?
    let mock: Bool?
    let mockReason: String?
    // Phase 3: Session metadata for progress tracking
    let session: SessionMetadata?

    enum CodingKeys: String, CodingKey {
        case suggestionType = "suggestion_type"
        case tone
        case screenshotId = "screenshot_id"
        case totalSuggestions = "total_suggestions"
        case generatedAt = "generated_at"
        case mock
        case mockReason = "mock_reason"
        case session
    }
}

// MARK: - SessionMetadata (Phase 3)

/// Session metadata for multi-screenshot context tracking
struct SessionMetadata: Codable, Sendable {
    let sessionId: String?
    let screenshotCount: Int
    let needsMoreContext: Bool
    let contextMessage: String?
    let contextScore: Double?
    let unlockMessage: String?
    let progressPercentage: String?
    let qualityLevel: String?

    enum CodingKeys: String, CodingKey {
        case sessionId
        case screenshotCount
        case needsMoreContext
        case contextMessage
        case contextScore
        case unlockMessage
        case progressPercentage
        case qualityLevel
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension FlirtSuggestion {
    /// Sample suggestion for testing
    static var sample: FlirtSuggestion {
        FlirtSuggestion(
            text: "I noticed you're into hiking! Have you checked out the trails at Big Sur?",
            tone: "playful",
            confidence: 0.85,
            reasoning: "User's profile shows interest in outdoor activities, suggesting a specific location creates engagement",
            suggestionType: .opener
        )
    }

    /// Array of sample suggestions
    static var samples: [FlirtSuggestion] {
        [
            FlirtSuggestion(
                text: "That photo from your trip looks amazing! What was your favorite part?",
                tone: "thoughtful",
                confidence: 0.92,
                reasoning: "Asking about their experience shows genuine interest",
                suggestionType: .opener
            ),
            FlirtSuggestion(
                text: "Coffee enthusiast here too! ☕️ What's your go-to order?",
                tone: "playful",
                confidence: 0.78,
                reasoning: "Finding common ground with shared interests",
                suggestionType: .iceBreaker
            ),
            FlirtSuggestion(
                text: "I'm curious - if you could travel anywhere right now, where would you go?",
                tone: "direct",
                confidence: 0.65,
                reasoning: "Open-ended question encourages detailed response",
                suggestionType: .followUp
            )
        ]
    }
}
#endif
