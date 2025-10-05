import Foundation
import Alamofire
import UIKit

class APIClient: ObservableObject {
    static let shared = APIClient()

    private let baseURL = "http://localhost:3000/api/v1"
    private let session: Session

    @Published var isLoading = false
    @Published var error: Error?

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = Session(configuration: configuration)
    }

    // MARK: - Authentication
    func authenticateWithApple(userIdentifier: String, identityToken: Data?, authorizationCode: Data?) async throws -> AuthResponse {
        let parameters: [String: Any] = [
            "userIdentifier": userIdentifier,
            "identityToken": identityToken?.base64EncodedString() ?? "",
            "authorizationCode": authorizationCode?.base64EncodedString() ?? ""
        ]

        return try await withCheckedThrowingContinuation { continuation in
            session.request("\(baseURL)/auth/apple",
                          method: .post,
                          parameters: parameters,
                          encoding: JSONEncoding.default)
                .validate()
                .responseDecodable(of: AuthResponse.self) { response in
                    switch response.result {
                    case .success(let authResponse):
                        continuation.resume(returning: authResponse)
                    case .failure(let error):
                        // REAL ERROR - NO FALLBACK
                        print("REAL API ERROR - Apple Auth Failed: \(error)")
                        continuation.resume(throwing: error)
                    }
                }
        }
    }

    func validateToken(_ token: String) async throws -> ValidationResponse {
        return try await withCheckedThrowingContinuation { continuation in
            session.request("\(baseURL)/auth/validate",
                          method: .post,
                          headers: ["Authorization": "Bearer \(token)"])
                .validate()
                .responseDecodable(of: ValidationResponse.self) { response in
                    switch response.result {
                    case .success(let validationResponse):
                        continuation.resume(returning: validationResponse)
                    case .failure(let error):
                        print("REAL API ERROR - Token Validation Failed: \(error)")
                        continuation.resume(throwing: error)
                    }
                }
        }
    }

    // MARK: - Screenshot Analysis (REAL GROK API)
    func analyzeScreenshot(imageData: Data, userId: String, context: AnalysisContext? = nil) async throws -> ScreenshotAnalysis {
        let formData = MultipartFormData()

        // Add image
        formData.append(imageData, withName: "image", fileName: "screenshot.jpg", mimeType: "image/jpeg")

        // Add user ID
        formData.append(userId.data(using: .utf8)!, withName: "user_id")

        // Add optional context
        if let context = context {
            let contextData = try JSONEncoder().encode(context)
            formData.append(contextData, withName: "context", mimeType: "application/json")
        }

        return try await withCheckedThrowingContinuation { continuation in
            session.upload(multipartFormData: formData, to: "\(baseURL)/analyze_screenshot")
                .validate()
                .responseDecodable(of: ScreenshotAnalysis.self) { response in
                    switch response.result {
                    case .success(let analysis):
                        print("REAL GROK ANALYSIS SUCCESS: Confidence = \(analysis.confidenceScore)")
                        continuation.resume(returning: analysis)
                    case .failure(let error):
                        // REAL ERROR FROM GROK - NO MOCK
                        print("REAL GROK API ERROR: \(error)")
                        print("Response: \(response.data?.string ?? "No data")")
                        continuation.resume(throwing: error)
                    }
                }
        }
    }

    // MARK: - Flirt Generation (REAL GROK API)
    func generateFlirts(analysisId: String, tone: String = "playful", count: Int = 3) async throws -> FlirtResponse {
        let parameters: [String: Any] = [
            "analysis_id": analysisId,
            "tone_preference": tone,
            "count": count,
            "constraints": [
                "max_length": 280,
                "include_emoji": true,
                "avoid_topics": ["politics", "religion"]
            ]
        ]

        return try await withCheckedThrowingContinuation { continuation in
            session.request("\(baseURL)/generate_flirts",
                          method: .post,
                          parameters: parameters,
                          encoding: JSONEncoding.default)
                .validate()
                .responseDecodable(of: FlirtResponse.self) { response in
                    switch response.result {
                    case .success(let flirtResponse):
                        print("REAL GROK FLIRTS GENERATED: \(flirtResponse.suggestions.count) suggestions")
                        continuation.resume(returning: flirtResponse)
                    case .failure(let error):
                        print("REAL GROK FLIRT GENERATION ERROR: \(error)")
                        continuation.resume(throwing: error)
                    }
                }
        }
    }

    // MARK: - Flirt Generation from Screenshot Image (REAL GROK VISION API)
    func generateFlirtsFromImage(
        imageData: Data,
        suggestionType: SuggestionType = .opener,
        tone: String = "playful",
        context: String = ""
    ) async throws -> FlirtSuggestionResponse {
        // Convert image to base64
        let base64Image = imageData.base64EncodedString()

        let parameters: [String: Any] = [
            "image_data": base64Image,
            "suggestion_type": suggestionType.rawValue,
            "tone": tone,
            "context": context,
            "user_preferences": [:]
        ]

        return try await withCheckedThrowingContinuation { continuation in
            session.request("\(baseURL)/flirts/generate_flirts",
                          method: .post,
                          parameters: parameters,
                          encoding: JSONEncoding.default)
                .validate()
                .responseDecodable(of: FlirtSuggestionResponse.self) { response in
                    switch response.result {
                    case .success(let flirtResponse):
                        print("✅ GROK VISION FLIRTS: \(flirtResponse.flirts.count) suggestions generated")
                        continuation.resume(returning: flirtResponse)
                    case .failure(let error):
                        print("❌ GROK VISION ERROR: \(error)")
                        if let data = response.data {
                            print("Response data: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
                        }
                        continuation.resume(throwing: error)
                    }
                }
        }
    }

    // MARK: - Voice Synthesis (REAL ELEVENLABS API)
    func synthesizeVoice(text: String, voiceId: String, emotion: String = "confident") async throws -> VoiceResponse {
        let parameters: [String: Any] = [
            "text": text,
            "user_voice_id": voiceId,
            "emotion": emotion,
            "speed": "normal",
            "user_preferences": [
                "pause_before_punchline": true,
                "emphasis_style": "moderate"
            ]
        ]

        return try await withCheckedThrowingContinuation { continuation in
            session.request("\(baseURL)/synthesize_voice",
                          method: .post,
                          parameters: parameters,
                          encoding: JSONEncoding.default)
                .validate()
                .responseDecodable(of: VoiceResponse.self) { response in
                    switch response.result {
                    case .success(let voiceResponse):
                        print("REAL ELEVENLABS SUCCESS: Audio URL = \(voiceResponse.audioURL)")
                        print("Duration: \(voiceResponse.durationSeconds)s, Size: \(voiceResponse.fileSizeMB)MB")
                        continuation.resume(returning: voiceResponse)
                    case .failure(let error):
                        print("REAL ELEVENLABS API ERROR: \(error)")
                        continuation.resume(throwing: error)
                    }
                }
        }
    }

    // MARK: - Voice Clone Upload (REAL ELEVENLABS)
    func uploadVoiceClone(audioData: Data, userId: String) async throws -> VoiceCloneResponse {
        let formData = MultipartFormData()

        formData.append(audioData, withName: "voice_sample", fileName: "voice.m4a", mimeType: "audio/mp4")
        formData.append(userId.data(using: .utf8)!, withName: "user_id")

        return try await withCheckedThrowingContinuation { continuation in
            session.upload(multipartFormData: formData, to: "\(baseURL)/voice/clone")
                .validate()
                .responseDecodable(of: VoiceCloneResponse.self) { response in
                    switch response.result {
                    case .success(let cloneResponse):
                        print("REAL ELEVENLABS CLONE SUCCESS: Voice ID = \(cloneResponse.voiceId)")
                        continuation.resume(returning: cloneResponse)
                    case .failure(let error):
                        print("REAL ELEVENLABS CLONE ERROR: \(error)")
                        continuation.resume(throwing: error)
                    }
                }
        }
    }

    // MARK: - User Data Deletion (GDPR Compliance)
    func deleteUserData(userId: String, deletionType: String = "complete") async throws -> DeletionResponse {
        let parameters: [String: Any] = [
            "deletion_type": deletionType,
            "verification": [
                "email_confirmation": true,
                "reason": "user_request"
            ],
            "jurisdiction": "US"
        ]

        return try await withCheckedThrowingContinuation { continuation in
            session.request("\(baseURL)/user/\(userId)/data",
                          method: .delete,
                          parameters: parameters,
                          encoding: JSONEncoding.default)
                .validate()
                .responseDecodable(of: DeletionResponse.self) { response in
                    switch response.result {
                    case .success(let deletionResponse):
                        continuation.resume(returning: deletionResponse)
                    case .failure(let error):
                        print("REAL DELETION ERROR: \(error)")
                        continuation.resume(throwing: error)
                    }
                }
        }
    }
}

// MARK: - Response Models
struct AuthResponse: Codable {
    let token: String
    let user: User
}

struct ValidationResponse: Codable {
    let valid: Bool
    let user: User?
}

struct ScreenshotAnalysis: Codable {
    let analysisId: String
    let conversationAnalysis: ConversationAnalysis
    let personalizationData: PersonalizationData?
    let timestamp: Date
    let processingTimeMs: Int
    let confidenceScore: Double

    enum CodingKeys: String, CodingKey {
        case analysisId = "analysis_id"
        case conversationAnalysis = "conversation_analysis"
        case personalizationData = "personalization_data"
        case timestamp
        case processingTimeMs = "processing_time_ms"
        case confidenceScore = "confidence_score"
    }
}

struct ConversationAnalysis: Codable {
    let conversationStage: String
    let otherPersonInterestLevel: String
    let conversationTone: String
    let keyTopicsIdentified: [String]
    let personalityIndicators: PersonalityIndicators

    enum CodingKeys: String, CodingKey {
        case conversationStage = "conversation_stage"
        case otherPersonInterestLevel = "other_person_interest_level"
        case conversationTone = "conversation_tone"
        case keyTopicsIdentified = "key_topics_identified"
        case personalityIndicators = "personality_indicators"
    }
}

struct PersonalityIndicators: Codable {
    let humorAppreciation: String
    let directnessPreference: String
    let intelligenceLevel: String

    enum CodingKeys: String, CodingKey {
        case humorAppreciation = "humor_appreciation"
        case directnessPreference = "directness_preference"
        case intelligenceLevel = "intelligence_level"
    }
}

struct PersonalizationData: Codable {
    let userHumorStyle: String?
    let successfulTopics: [String]?
    let optimalDirectness: String?

    enum CodingKeys: String, CodingKey {
        case userHumorStyle = "user_humor_style"
        case successfulTopics = "successful_topics"
        case optimalDirectness = "optimal_directness"
    }
}

struct FlirtResponse: Codable {
    let suggestions: [FlirtSuggestion]
    let refreshAvailable: Bool
    let personalizationUpdated: Bool

    enum CodingKeys: String, CodingKey {
        case suggestions
        case refreshAvailable = "refresh_available"
        case personalizationUpdated = "personalization_updated"
    }
}

// NOTE: FlirtSuggestion model is now imported from Models/FlirtSuggestion.swift

struct VoiceResponse: Codable {
    let audioURL: String
    let durationSeconds: Double
    let fileSizeMB: Double
    let format: String
    let expiresAt: Date

    enum CodingKeys: String, CodingKey {
        case audioURL = "audio_url"
        case durationSeconds = "duration_seconds"
        case fileSizeMB = "file_size_mb"
        case format
        case expiresAt = "expires_at"
    }
}

struct VoiceCloneResponse: Codable {
    let voiceId: String
    let status: String
    let processingTime: Int

    enum CodingKeys: String, CodingKey {
        case voiceId = "voice_id"
        case status
        case processingTime = "processing_time"
    }
}

struct DeletionResponse: Codable {
    let deletionId: String
    let status: String
    let estimatedCompletion: Date

    enum CodingKeys: String, CodingKey {
        case deletionId = "deletion_id"
        case status
        case estimatedCompletion = "estimated_completion"
    }
}

struct AnalysisContext: Codable {
    let relationshipGoal: String
    let userBio: String?
    let platform: String?

    enum CodingKeys: String, CodingKey {
        case relationshipGoal = "relationship_goal"
        case userBio = "user_bio"
        case platform
    }
}

// Helper extension
extension Data {
    var string: String? {
        String(data: self, encoding: .utf8)
    }
}