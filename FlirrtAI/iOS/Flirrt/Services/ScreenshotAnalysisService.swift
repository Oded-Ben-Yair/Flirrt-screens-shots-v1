//
//  ScreenshotAnalysisService.swift
//  Vibe8 (formerly Flirrt)
//
//  Vibe8 Screenshot Analysis Service
//  Created by: AI/ML Engineer Agent
//  Backend: Gemini 2.5 Pro + GPT-5 pipeline
//
//  Implements THE VIBE8 FIXING PLAN Phase 2 iOS client integration
//

import Foundation
import UIKit

/// Screenshot Analysis Result from Gemini 2.5 Pro
struct ScreenshotAnalysis: Codable, Identifiable {
    let id = UUID()
    let context: String
    let personality: PersonalityTraits?
    let scene: SceneContext?
    let confidence: Double
    let visualFeatures: VisualFeatures?

    enum CodingKeys: String, CodingKey {
        case context, personality, scene, confidence, visualFeatures
    }
}

struct PersonalityTraits: Codable {
    let energyLevel: String?
    let socialStyle: String?
    let lifestyleIndicators: [String]?
    let confidenceLevel: String?
}

struct SceneContext: Codable {
    let photoType: String?
    let socialContext: String?
    let mood: String?
    let timeContext: String?
}

struct VisualFeatures: Codable {
    let clothingStyle: String?
    let setting: String?
    let activities: [String]?
    let props: [String]?
}

/// Generated Flirt from GPT-5
struct GeneratedFlirt: Codable, Identifiable {
    let id = UUID()
    let flirt: String
    let tone: String
    let reasoning: String?
    let confidence: Double?
    let qualityScores: QualityScores?
    let isPrimary: Bool

    enum CodingKeys: String, CodingKey {
        case flirt, tone, reasoning, confidence, qualityScores, isPrimary
    }
}

struct QualityScores: Codable {
    let overall: Double
    let sentiment: Double
    let length: Double
    let creativity: Double
    let relevance: Double
    let toneMatching: Double
}

/// Complete API Response
struct AnalyzeAndGenerateResponse: Codable {
    let success: Bool
    let analysis: ScreenshotAnalysis
    let flirts: [GeneratedFlirt]
    let performance: PerformanceMetrics
    let metadata: ResponseMetadata
}

struct PerformanceMetrics: Codable {
    let analysisLatency: Int
    let generationLatency: Int
    let totalLatency: Int
    let meetsTarget: Bool
}

struct ResponseMetadata: Codable {
    let latency: Int?
    let model: String?
    let modelVersion: String?
    let timestamp: String
    let pipelineVersion: String?
}

/// Error responses
struct APIError: Codable {
    let success: Bool
    let error: String
    let code: String
    let details: String?
}

@MainActor
class ScreenshotAnalysisService: ObservableObject {

    // MARK: - Configuration

    private let baseURL: String
    private let apiVersion = "v2"
    private let timeout: TimeInterval = 15.0 // 15 second timeout

    @Published var isLoading = false
    @Published var lastError: String?
    @Published var latestAnalysis: ScreenshotAnalysis?
    @Published var latestFlirts: [GeneratedFlirt] = []
    @Published var performanceMetrics: PerformanceMetrics?

    // MARK: - Initialization

    init(baseURL: String = "https://your-backend-url.com") {
        // TODO: Replace with actual backend URL from environment/config
        self.baseURL = baseURL
    }

    // MARK: - Public API

    /// Analyze Screenshot and Generate Flirts (Combined Pipeline)
    ///
    /// - Parameters:
    ///   - image: UIImage to analyze
    ///   - tone: Desired tone (playful, confident, casual, romantic, witty)
    ///   - suggestionType: Type of suggestion (opener, response, continuation)
    ///   - count: Number of alternatives to generate (default: 3)
    /// - Returns: Complete analysis and flirt results
    func analyzeAndGenerateFlirts(
        image: UIImage,
        tone: FlirtTone = .playful,
        suggestionType: SuggestionType = .opener,
        count: Int = 3
    ) async throws -> AnalyzeAndGenerateResponse {

        isLoading = true
        lastError = nil

        defer { isLoading = false }

        // Convert image to JPEG data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw ScreenshotAnalysisError.invalidImage
        }

        // Resize if too large (optimization from research)
        let resizedImageData: Data
        if imageData.count > 5 * 1024 * 1024 { // > 5MB
            guard let resizedImage = resizeImage(image, maxDimension: 1024),
                  let resizedData = resizedImage.jpegData(compressionQuality: 0.7) else {
                throw ScreenshotAnalysisError.invalidImage
            }
            resizedImageData = resizedData
        } else {
            resizedImageData = imageData
        }

        // Build URL
        guard let url = URL(string: "\(baseURL)/api/\(apiVersion)/vibe8/analyze-and-generate") else {
            throw ScreenshotAnalysisError.invalidURL
        }

        // Build multipart/form-data request
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeout

        // Add auth token if available
        if let token = getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Build multipart body
        var body = Data()

        // Add screenshot image
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"screenshot\"; filename=\"screenshot.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(resizedImageData)
        body.append("\r\n".data(using: .utf8)!)

        // Add tone parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"tone\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(tone.rawValue)\r\n".data(using: .utf8)!)

        // Add suggestion_type parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"suggestion_type\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(suggestionType.rawValue)\r\n".data(using: .utf8)!)

        // Add count parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"count\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(count)\r\n".data(using: .utf8)!)

        // End boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Check HTTP status
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ScreenshotAnalysisError.networkError
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            // Try to parse error response
            if let errorResponse = try? JSONDecoder().decode(APIError.self, from: data) {
                lastError = errorResponse.error
                throw ScreenshotAnalysisError.apiError(errorResponse.error, errorResponse.code)
            }
            throw ScreenshotAnalysisError.httpError(httpResponse.statusCode)
        }

        // Parse success response
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let result = try decoder.decode(AnalyzeAndGenerateResponse.self, from: data)

        // Cache results
        latestAnalysis = result.analysis
        latestFlirts = result.flirts
        performanceMetrics = result.performance

        return result
    }

    /// Analyze Screenshot Only (without flirt generation)
    /// Useful for preview/validation before generating flirts
    func analyzeScreenshot(image: UIImage) async throws -> ScreenshotAnalysis {
        isLoading = true
        lastError = nil

        defer { isLoading = false }

        // Convert image to JPEG data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw ScreenshotAnalysisError.invalidImage
        }

        // Build URL
        guard let url = URL(string: "\(baseURL)/api/\(apiVersion)/vibe8/analyze-screenshot") else {
            throw ScreenshotAnalysisError.invalidURL
        }

        // Build multipart/form-data request
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10.0 // Shorter timeout for analysis only

        // Add auth token if available
        if let token = getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Build multipart body
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"screenshot\"; filename=\"screenshot.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)

        // Check HTTP status
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ScreenshotAnalysisError.networkError
        }

        // Parse response
        struct AnalysisOnlyResponse: Codable {
            let success: Bool
            let analysis: ScreenshotAnalysis
        }

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let result = try decoder.decode(AnalysisOnlyResponse.self, from: data)

        // Cache result
        latestAnalysis = result.analysis

        return result.analysis
    }

    // MARK: - Helper Methods

    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage? {
        let size = image.size
        let aspectRatio = size.width / size.height

        let newSize: CGSize
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }

        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage
    }

    private func getAuthToken() -> String? {
        // TODO: Integrate with actual auth system
        // For MVP, return test token or nil
        return UserDefaults.standard.string(forKey: "auth_token")
    }
}

// MARK: - Enums

enum FlirtTone: String, Codable, CaseIterable {
    case playful = "playful"
    case confident = "confident"
    case casual = "casual"
    case romantic = "romantic"
    case witty = "witty"

    var displayName: String {
        rawValue.capitalized
    }

    var description: String {
        switch self {
        case .playful: return "Light and fun"
        case .confident: return "Direct and self-assured"
        case .casual: return "Relaxed and friendly"
        case .romantic: return "Warm and genuine"
        case .witty: return "Clever and intelligent"
        }
    }
}

enum SuggestionType: String, Codable {
    case opener = "opener"
    case response = "response"
    case continuation = "continuation"
}

enum ScreenshotAnalysisError: LocalizedError {
    case invalidImage
    case invalidURL
    case networkError
    case httpError(Int)
    case apiError(String, String)
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Could not process the image. Please try another screenshot."
        case .invalidURL:
            return "Invalid server URL configuration."
        case .networkError:
            return "Network connection error. Please check your internet connection."
        case .httpError(let code):
            return "Server error (HTTP \(code)). Please try again later."
        case .apiError(let message, _):
            return message
        case .decodingError:
            return "Could not understand server response. Please try again."
        }
    }
}
