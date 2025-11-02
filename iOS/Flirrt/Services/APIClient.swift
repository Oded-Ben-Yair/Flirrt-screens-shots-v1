import Foundation
import Alamofire
import UIKit

class APIClient: ObservableObject {
    static let shared = APIClient()

    private let baseURL = AppConstants.apiBaseURL
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
                .responseDecodable(of: AuthResponseWrapper.self) { response in
                    switch response.result {
                    case .success(let wrapper):
                        let authResponse = AuthResponse(from: wrapper)
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

        // Add user ID - CRITICAL FIX: Safe unwrapping
        guard let uidData = userId.data(using: .utf8) else {
            throw APIError.encodingError
        }
        formData.append(uidData, withName: "user_id")

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
                        print("✅ Analysis complete: Confidence = \(analysis.confidenceScore)")
                        continuation.resume(returning: analysis)
                    case .failure(let error):
                        // CRITICAL FIX: Do not log response data (may contain sensitive info)
                        print("❌ Analysis failed: \(error.localizedDescription)")
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
            session.request("\(baseURL)/flirts",
                          method: .post,
                          parameters: parameters,
                          encoding: JSONEncoding.default)
                .validate()
                .responseDecodable(of: FlirtResponse.self) { response in
                    switch response.result {
                    case .success(let flirtResponse):
                        print("✅ Generated \(flirtResponse.suggestions.count) suggestions")
                        continuation.resume(returning: flirtResponse)
                    case .failure(let error):
                        print("❌ Flirt generation failed: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                }
        }
    }

    // MARK: - Flirt Generation from Screenshot Image (REAL GROK VISION API)
    /// CRITICAL FIX: Using multipart upload instead of Base64 to prevent memory bloat
    /// NEW: Added conversationID for multi-screenshot context
    func generateFlirtsFromImage(
        imageData: Data,
        conversationID: String? = nil,
        suggestionType: SuggestionType = .opener,
        tone: String = "playful",
        context: String = ""
    ) async throws -> FlirtSuggestionResponse {
        // CRITICAL FIX: Use multipart upload instead of Base64 encoding
        // Base64 increases memory usage by 33% and can cause crashes with large images

        return try await withCheckedThrowingContinuation { continuation in
            session.upload(
                multipartFormData: { formData in
                    // Add image as multipart data
                    formData.append(imageData, withName: "images[0]", fileName: "screenshot.jpg", mimeType: "image/jpeg")

                    // NEW: Add conversation_id for multi-screenshot context
                    if let conversationID = conversationID,
                       let conversationIDData = conversationID.data(using: .utf8) {
                        formData.append(conversationIDData, withName: "conversationId")
                    }

                    // Add other parameters
                    if let suggestionTypeData = suggestionType.rawValue.data(using: .utf8) {
                        formData.append(suggestionTypeData, withName: "suggestion_type")
                    }
                    if let toneData = tone.data(using: .utf8) {
                        formData.append(toneData, withName: "tone")
                    }
                    if let contextData = context.data(using: .utf8) {
                        formData.append(contextData, withName: "context")
                    }
                },
                to: "\(baseURL)/flirts"
            )
            .validate()
            .responseDecodable(of: FlirtSuggestionResponse.self) { response in
                switch response.result {
                case .success(let flirtResponse):
                    print("✅ Generated \(flirtResponse.flirts.count) suggestions from image")
                    continuation.resume(returning: flirtResponse)
                case .failure(let error):
                    // CRITICAL FIX: Do not log response data (may contain sensitive info)
                    print("❌ Image analysis failed: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - TRAINED PIPELINE: Grok-2-vision + GPT-4O (NEW v2 endpoint)
    /// Generate flirts using the trained dual-model pipeline
    /// Endpoint: POST /api/v2/trained/analyze-and-generate
    func generateFlirtsWithTrainedPipeline(
        imageData: Data,
        suggestionType: SuggestionType = .opener,
        tone: String = "playful",
        context: String = ""
    ) async throws -> FlirtSuggestionResponse {
        // Convert image to base64 for JSON payload
        let base64Image = imageData.base64EncodedString()

        let parameters: [String: Any] = [
            "image_data": base64Image,
            "suggestion_type": suggestionType.rawValue,
            "tone": tone,
            "context": context
        ]

        print("📡 Calling TRAINED pipeline: POST /api/v2/trained/analyze-and-generate")

        return try await withCheckedThrowingContinuation { continuation in
            session.request("\(baseURL)/api/v2/trained/analyze-and-generate",
                          method: .post,
                          parameters: parameters,
                          encoding: JSONEncoding.default)
                .validate()
                .responseDecodable(of: FlirtSuggestionResponse.self) { response in
                    switch response.result {
                    case .success(let flirtResponse):
                        print("✅ TRAINED pipeline: Generated \(flirtResponse.flirts.count) suggestions")
                        continuation.resume(returning: flirtResponse)
                    case .failure(let error):
                        print("❌ TRAINED pipeline failed: \(error.localizedDescription)")
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
                        print("✅ Voice synthesized: \(voiceResponse.durationSeconds)s, \(voiceResponse.fileSizeMB)MB")
                        continuation.resume(returning: voiceResponse)
                    case .failure(let error):
                        print("❌ Voice synthesis failed: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                }
        }
    }

    // MARK: - Voice Clone Upload (REAL ELEVENLABS)
    func uploadVoiceClone(audioData: Data, userId: String) async throws -> VoiceCloneResponse {
        let formData = MultipartFormData()

        formData.append(audioData, withName: "voice_sample", fileName: "voice.m4a", mimeType: "audio/mp4")

        // CRITICAL FIX: Safe unwrapping
        guard let uidData = userId.data(using: .utf8) else {
            throw APIError.encodingError
        }
        formData.append(uidData, withName: "user_id")

        return try await withCheckedThrowingContinuation { continuation in
            session.upload(multipartFormData: formData, to: "\(baseURL)/voice/clone")
                .validate()
                .responseDecodable(of: VoiceCloneResponse.self) { response in
                    switch response.result {
                    case .success(let cloneResponse):
                        print("✅ Voice clone created: \(cloneResponse.voiceId)")
                        continuation.resume(returning: cloneResponse)
                    case .failure(let error):
                        print("❌ Voice clone failed: \(error.localizedDescription)")
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
                        print("✅ Account deletion initiated")
                        continuation.resume(returning: deletionResponse)
                    case .failure(let error):
                        print("❌ Account deletion failed: \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                }
        }
    }
}

// MARK: - Response Models
struct AuthResponseWrapper: Codable {
    let success: Bool
    let data: AuthResponseData
    let message: String?
}

struct AuthResponseData: Codable {
    let user: AuthUser
    let token: String
    let expiresAt: String
}

struct AuthUser: Codable {
    let id: String
    let provider: String
    let mvpMode: Bool
}

struct AuthResponse: Codable {
    let token: String
    let user: User
    
    init(from wrapper: AuthResponseWrapper) {
        self.token = wrapper.data.token
        self.user = User(
            id: wrapper.data.user.id,
            email: nil,
            fullName: nil,
            voiceId: nil,
            createdAt: Date(),
            ageVerified: false
        )
    }
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

// MARK: - Error Types
enum APIError: Error {
    case encodingError
    case invalidResponse
    case unauthorized
    case networkError(String)

    var localizedDescription: String {
        switch self {
        case .encodingError:
            return "Failed to encode data"
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Unauthorized access"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}