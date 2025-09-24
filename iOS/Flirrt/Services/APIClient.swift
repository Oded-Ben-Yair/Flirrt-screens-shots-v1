import Foundation
import Alamofire
import UIKit
import OSLog

@MainActor
final class APIClient: ObservableObject {
    static let shared = APIClient()

    private let baseURL = "http://localhost:3000/api/v1"
    private let session: Session
    private let logger = Logger(subsystem: "com.flirrt.app", category: "APIClient")

    @Published var isLoading = false
    @Published var error: Error?

    // Task management for cancellation
    private var activeTasks = Set<Task<Void, Never>>()

    // Actor for thread-safe network operations
    private actor NetworkManager {
        private var requestCount: Int = 0

        func incrementRequests() -> Int {
            requestCount += 1
            return requestCount
        }

        func getRequestCount() -> Int {
            return requestCount
        }
    }

    private let networkManager = NetworkManager()

    init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = Session(configuration: configuration)
        logger.info("APIClient initialized with base URL: \(self.baseURL)")
    }

    deinit {
        cancelAllTasks()
        logger.info("APIClient deinitialized")
    }

    func cancelAllTasks() {
        for task in activeTasks {
            task.cancel()
        }
        activeTasks.removeAll()
        logger.info("Cancelled all active tasks")
    }

    // MARK: - Batch Operations with TaskGroup

    /// Perform multiple API operations concurrently using TaskGroup
    func performBatchOperations<T: Sendable>(
        operations: [() async throws -> T]
    ) async throws -> [Result<T, Error>] {
        return try await withThrowingTaskGroup(of: Result<T, Error>.self) { group in
            // Add all operations to the task group
            for operation in operations {
                group.addTask {
                    do {
                        let result = try await operation()
                        return .success(result)
                    } catch {
                        return .failure(error)
                    }
                }
            }

            // Collect results as they complete
            var results: [Result<T, Error>] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
    }

    /// Analyze multiple screenshots concurrently
    func analyzeMultipleScreenshots(
        imageDataArray: [Data],
        userId: String,
        context: AnalysisContext? = nil
    ) async throws -> [ScreenshotAnalysis] {
        let operations = imageDataArray.map { imageData in
            { [weak self] in
                guard let self = self else { throw APIError.clientUnavailable }
                return try await self.analyzeScreenshot(imageData: imageData, userId: userId, context: context)
            }
        }

        let results = try await performBatchOperations(operations: operations)

        // Extract successful results and log failures
        return results.compactMap { result in
            switch result {
            case .success(let analysis):
                return analysis
            case .failure(let error):
                logger.error("Screenshot analysis failed: \(error.localizedDescription)")
                return nil
            }
        }
    }

    /// Generate flirts for multiple analysis results concurrently
    func generateFlirtsForMultipleAnalyses(
        analysisIds: [String],
        tone: String = "playful",
        count: Int = 3
    ) async throws -> [FlirtResponse] {
        let operations = analysisIds.map { analysisId in
            { [weak self] in
                guard let self = self else { throw APIError.clientUnavailable }
                return try await self.generateFlirts(analysisId: analysisId, tone: tone, count: count)
            }
        }

        let results = try await performBatchOperations(operations: operations)

        return results.compactMap { result in
            switch result {
            case .success(let flirtResponse):
                return flirtResponse
            case .failure(let error):
                logger.error("Flirt generation failed: \(error.localizedDescription)")
                return nil
            }
        }
    }

    /// Synthesize voice for multiple text inputs concurrently
    func synthesizeMultipleVoices(
        texts: [String],
        voiceId: String,
        emotion: String = "confident"
    ) async throws -> [VoiceResponse] {
        let operations = texts.map { text in
            { [weak self] in
                guard let self = self else { throw APIError.clientUnavailable }
                return try await self.synthesizeVoice(text: text, voiceId: voiceId, emotion: emotion)
            }
        }

        let results = try await performBatchOperations(operations: operations)

        return results.compactMap { result in
            switch result {
            case .success(let voiceResponse):
                return voiceResponse
            case .failure(let error):
                logger.error("Voice synthesis failed: \(error.localizedDescription)")
                return nil
            }
        }
    }

    /// Process complete workflow: Analysis -> Flirt Generation -> Voice Synthesis
    func processCompleteWorkflow(
        imageData: Data,
        userId: String,
        voiceId: String,
        context: AnalysisContext? = nil,
        tone: String = "playful",
        emotion: String = "confident"
    ) async throws -> WorkflowResult {
        return try await withThrowingTaskGroup(of: Void.self) { group in
            var analysis: ScreenshotAnalysis?
            var flirtResponse: FlirtResponse?
            var voiceResponses: [VoiceResponse] = []

            // Step 1: Analyze screenshot
            group.addTask { @MainActor in
                self.isLoading = true
                analysis = try await self.analyzeScreenshot(imageData: imageData, userId: userId, context: context)
            }

            try await group.next()

            guard let analysisResult = analysis else {
                throw APIError.analysisRequired
            }

            // Step 2: Generate flirts based on analysis
            group.addTask {
                flirtResponse = try await self.generateFlirts(
                    analysisId: analysisResult.analysisId,
                    tone: tone
                )
            }

            try await group.next()

            guard let flirts = flirtResponse else {
                throw APIError.flirtGenerationRequired
            }

            // Step 3: Synthesize voice for all flirt suggestions
            let flirtTexts = flirts.suggestions.map { $0.text }

            group.addTask {
                voiceResponses = try await self.synthesizeMultipleVoices(
                    texts: flirtTexts,
                    voiceId: voiceId,
                    emotion: emotion
                )
            }

            try await group.next()

            await MainActor.run {
                self.isLoading = false
            }

            return WorkflowResult(
                analysis: analysisResult,
                flirts: flirts,
                voiceResponses: voiceResponses
            )
        }
    }

    // MARK: - Authentication
    func authenticateWithApple(userIdentifier: String, identityToken: Data?, authorizationCode: Data?) async throws -> AuthResponse {
        let requestId = await networkManager.incrementRequests()
        logger.info("Starting Apple authentication request #\(requestId) for user: \(userIdentifier)")

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
                        self.logger.info("Apple authentication successful for request #\(requestId)")
                        continuation.resume(returning: authResponse)
                    case .failure(let error):
                        self.logger.error("Apple authentication failed for request #\(requestId): \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                }
        }
    }

    func validateToken(_ token: String) async throws -> ValidationResponse {
        let requestId = await networkManager.incrementRequests()
        logger.info("Starting token validation request #\(requestId)")
        return try await withCheckedThrowingContinuation { continuation in
            session.request("\(baseURL)/auth/validate",
                          method: .post,
                          headers: ["Authorization": "Bearer \(token)"])
                .validate()
                .responseDecodable(of: ValidationResponse.self) { response in
                    switch response.result {
                    case .success(let validationResponse):
                        self.logger.info("Token validation successful for request #\(requestId)")
                        continuation.resume(returning: validationResponse)
                    case .failure(let error):
                        self.logger.error("Token validation failed for request #\(requestId): \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                }
        }
    }

    // MARK: - Screenshot Analysis (REAL GROK API)
    func analyzeScreenshot(imageData: Data, userId: String, context: AnalysisContext? = nil) async throws -> ScreenshotAnalysis {
        let requestId = await networkManager.incrementRequests()
        logger.info("Starting screenshot analysis request #\(requestId) for user: \(userId)")
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
                        self.logger.info("Screenshot analysis successful for request #\(requestId): Confidence = \(analysis.confidenceScore)")
                        continuation.resume(returning: analysis)
                    case .failure(let error):
                        self.logger.error("Screenshot analysis failed for request #\(requestId): \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                }
        }
    }

    // MARK: - Flirt Generation (REAL GROK API)
    func generateFlirts(analysisId: String, tone: String = "playful", count: Int = 3) async throws -> FlirtResponse {
        let requestId = await networkManager.incrementRequests()
        logger.info("Starting flirt generation request #\(requestId) for analysis: \(analysisId)")
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
                        self.logger.info("Flirt generation successful for request #\(requestId): \(flirtResponse.suggestions.count) suggestions")
                        continuation.resume(returning: flirtResponse)
                    case .failure(let error):
                        self.logger.error("Flirt generation failed for request #\(requestId): \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                }
        }
    }

    // MARK: - Voice Synthesis (REAL ELEVENLABS API)
    func synthesizeVoice(text: String, voiceId: String, emotion: String = "confident") async throws -> VoiceResponse {
        let requestId = await networkManager.incrementRequests()
        logger.info("Starting voice synthesis request #\(requestId) for voice: \(voiceId)")
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
                        self.logger.info("Voice synthesis successful for request #\(requestId): Duration \(voiceResponse.durationSeconds)s")
                        continuation.resume(returning: voiceResponse)
                    case .failure(let error):
                        self.logger.error("Voice synthesis failed for request #\(requestId): \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                }
        }
    }

    // MARK: - Voice Clone Upload (REAL ELEVENLABS)
    func uploadVoiceClone(audioData: Data, userId: String) async throws -> VoiceCloneResponse {
        let requestId = await networkManager.incrementRequests()
        logger.info("Starting voice clone upload request #\(requestId) for user: \(userId)")
        let formData = MultipartFormData()

        formData.append(audioData, withName: "voice_sample", fileName: "voice.m4a", mimeType: "audio/mp4")
        formData.append(userId.data(using: .utf8)!, withName: "user_id")

        return try await withCheckedThrowingContinuation { continuation in
            session.upload(multipartFormData: formData, to: "\(baseURL)/voice/clone")
                .validate()
                .responseDecodable(of: VoiceCloneResponse.self) { response in
                    switch response.result {
                    case .success(let cloneResponse):
                        self.logger.info("Voice clone upload successful for request #\(requestId): Voice ID = \(cloneResponse.voiceId)")
                        continuation.resume(returning: cloneResponse)
                    case .failure(let error):
                        self.logger.error("Voice clone upload failed for request #\(requestId): \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                }
        }
    }

    // MARK: - User Data Deletion (GDPR Compliance)
    func deleteUserData(userId: String, deletionType: String = "complete") async throws -> DeletionResponse {
        let requestId = await networkManager.incrementRequests()
        logger.info("Starting user data deletion request #\(requestId) for user: \(userId)")
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
                        self.logger.info("User data deletion successful for request #\(requestId): Status = \(deletionResponse.status)")
                        continuation.resume(returning: deletionResponse)
                    case .failure(let error):
                        self.logger.error("User data deletion failed for request #\(requestId): \(error.localizedDescription)")
                        continuation.resume(throwing: error)
                    }
                }
        }
    }
}

// MARK: - Concurrency-Safe Response Models
struct AuthResponse: Codable, Sendable {
    let token: String
    let user: User
}

struct ValidationResponse: Codable, Sendable {
    let valid: Bool
    let user: User?
}

struct ScreenshotAnalysis: Codable, Sendable {
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

struct ConversationAnalysis: Codable, Sendable {
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

struct PersonalityIndicators: Codable, Sendable {
    let humorAppreciation: String
    let directnessPreference: String
    let intelligenceLevel: String

    enum CodingKeys: String, CodingKey {
        case humorAppreciation = "humor_appreciation"
        case directnessPreference = "directness_preference"
        case intelligenceLevel = "intelligence_level"
    }
}

struct PersonalizationData: Codable, Sendable {
    let userHumorStyle: String?
    let successfulTopics: [String]?
    let optimalDirectness: String?

    enum CodingKeys: String, CodingKey {
        case userHumorStyle = "user_humor_style"
        case successfulTopics = "successful_topics"
        case optimalDirectness = "optimal_directness"
    }
}

struct FlirtResponse: Codable, Sendable {
    let suggestions: [FlirtSuggestion]
    let refreshAvailable: Bool
    let personalizationUpdated: Bool

    enum CodingKeys: String, CodingKey {
        case suggestions
        case refreshAvailable = "refresh_available"
        case personalizationUpdated = "personalization_updated"
    }
}

struct FlirtSuggestion: Codable, Sendable {
    let id: String
    let text: String
    let tone: String
    let confidence: Double
    let reasoning: String
    let voiceAvailable: Bool
    let expectedOutcome: String
    let backupSuggestion: String?

    enum CodingKeys: String, CodingKey {
        case id, text, tone, confidence, reasoning
        case voiceAvailable = "voice_available"
        case expectedOutcome = "expected_outcome"
        case backupSuggestion = "backup_suggestion"
    }
}

struct VoiceResponse: Codable, Sendable {
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

struct VoiceCloneResponse: Codable, Sendable {
    let voiceId: String
    let status: String
    let processingTime: Int

    enum CodingKeys: String, CodingKey {
        case voiceId = "voice_id"
        case status
        case processingTime = "processing_time"
    }
}

struct DeletionResponse: Codable, Sendable {
    let deletionId: String
    let status: String
    let estimatedCompletion: Date

    enum CodingKeys: String, CodingKey {
        case deletionId = "deletion_id"
        case status
        case estimatedCompletion = "estimated_completion"
    }
}

struct AnalysisContext: Codable, Sendable {
    let relationshipGoal: String
    let userBio: String?
    let platform: String?

    enum CodingKeys: String, CodingKey {
        case relationshipGoal = "relationship_goal"
        case userBio = "user_bio"
        case platform
    }
}

// MARK: - Workflow Result
struct WorkflowResult: Sendable {
    let analysis: ScreenshotAnalysis
    let flirts: FlirtResponse
    let voiceResponses: [VoiceResponse]
}

// MARK: - API Errors
enum APIError: Error, Sendable {
    case clientUnavailable
    case analysisRequired
    case flirtGenerationRequired
    case networkUnavailable
    case invalidResponse
    case taskCancelled
}

// MARK: - User Model
struct User: Codable, Sendable {
    let id: String
    let email: String?
    let name: String?
    let createdAt: Date
}

// Helper extension
extension Data {
    var string: String? {
        String(data: self, encoding: .utf8)
    }
}