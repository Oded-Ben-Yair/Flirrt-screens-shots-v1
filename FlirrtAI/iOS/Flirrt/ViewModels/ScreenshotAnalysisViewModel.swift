//
//  ScreenshotAnalysisViewModel.swift
//  Vibe8 (formerly Flirrt)
//
//  ViewModel for Screenshot Analysis Flow
//  Created by: AI/ML Engineer Agent
//  Uses: Observation framework (iOS 17+) from Phase 1 architecture
//
//  Orchestrates:
//  - Screenshot capture from photos or camera
//  - Gemini 2.5 Pro analysis
//  - GPT-5 flirt generation
//  - Quality evaluation and display
//

import Foundation
import SwiftUI
import Observation
import PhotosUI

@MainActor
@Observable
final class ScreenshotAnalysisViewModel {

    // MARK: - Published State

    var selectedImage: UIImage?
    var selectedTone: FlirtTone = .playful
    var suggestionType: SuggestionType = .opener

    var isAnalyzing = false
    var analysisResult: ScreenshotAnalysis?
    var generatedFlirts: [GeneratedFlirt] = []
    var performanceMetrics: PerformanceMetrics?

    var errorMessage: String?
    var showError = false

    var currentPhase: AnalysisPhase = .idle

    // MARK: - Services

    private let service: ScreenshotAnalysisService

    // MARK: - Initialization

    init(service: ScreenshotAnalysisService = ScreenshotAnalysisService()) {
        self.service = service
    }

    // MARK: - Public Methods

    /// Start complete analysis + generation pipeline
    func analyzeAndGenerate() async {
        guard let image = selectedImage else {
            showErrorMessage("Please select a screenshot first")
            return
        }

        isAnalyzing = true
        currentPhase = .analyzing
        errorMessage = nil
        showError = false

        do {
            let result = try await service.analyzeAndGenerateFlirts(
                image: image,
                tone: selectedTone,
                suggestionType: suggestionType,
                count: 3
            )

            // Update state with results
            analysisResult = result.analysis
            generatedFlirts = result.flirts
            performanceMetrics = result.performance

            currentPhase = .complete

            // Log performance
            logPerformance(result.performance)

        } catch let error as ScreenshotAnalysisError {
            handleError(error)
        } catch {
            showErrorMessage("Unexpected error: \(error.localizedDescription)")
        }

        isAnalyzing = false
    }

    /// Analyze screenshot only (preview before generating flirts)
    func analyzeScreenshotOnly() async {
        guard let image = selectedImage else {
            showErrorMessage("Please select a screenshot first")
            return
        }

        isAnalyzing = true
        currentPhase = .analyzing
        errorMessage = nil
        showError = false

        do {
            let result = try await service.analyzeScreenshot(image: image)

            analysisResult = result
            currentPhase = .analysisComplete

        } catch let error as ScreenshotAnalysisError {
            handleError(error)
        } catch {
            showErrorMessage("Unexpected error: \(error.localizedDescription)")
        }

        isAnalyzing = false
    }

    /// Continue to flirt generation after analysis preview
    func continueToGeneration() async {
        guard analysisResult != nil else {
            showErrorMessage("Analysis required before generation")
            return
        }

        // If we already have analysis, just run generation
        await analyzeAndGenerate()
    }

    /// Reset to start new analysis
    func reset() {
        selectedImage = nil
        analysisResult = nil
        generatedFlirts = []
        performanceMetrics = nil
        errorMessage = nil
        showError = false
        currentPhase = .idle
    }

    /// Select tone for generation
    func selectTone(_ tone: FlirtTone) {
        selectedTone = tone
    }

    /// Copy flirt to clipboard
    func copyFlirt(_ flirt: GeneratedFlirt) {
        UIPasteboard.general.string = flirt.flirt
        // Could trigger haptic feedback here
    }

    /// Rate flirt quality (for feedback loop)
    func rateFlirt(_ flirt: GeneratedFlirt, rating: Int) {
        // TODO: Send feedback to backend for continuous improvement
        // This implements the user-centric quality assessment from research
        print("User rated flirt with \(rating) stars")
    }

    // MARK: - Private Methods

    private func handleError(_ error: ScreenshotAnalysisError) {
        errorMessage = error.errorDescription
        showError = true
        currentPhase = .error
    }

    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
        currentPhase = .error
    }

    private func logPerformance(_ metrics: PerformanceMetrics) {
        print("""
        📊 Pipeline Performance:
        - Analysis: \(metrics.analysisLatency)ms
        - Generation: \(metrics.generationLatency)ms
        - Total: \(metrics.totalLatency)ms
        - Meets Target: \(metrics.meetsTarget ? "✅" : "❌")
        """)

        // Could send to analytics service here
    }

    // MARK: - Computed Properties

    var hasAnalysis: Bool {
        analysisResult != nil
    }

    var hasFlirts: Bool {
        !generatedFlirts.isEmpty
    }

    var canGenerate: Bool {
        selectedImage != nil && !isAnalyzing
    }

    var primaryFlirt: GeneratedFlirt? {
        generatedFlirts.first(where: { $0.isPrimary }) ?? generatedFlirts.first
    }

    var alternativeFlirts: [GeneratedFlirt] {
        generatedFlirts.filter { !$0.isPrimary }
    }

    var confidenceLevel: ConfidenceLevel {
        guard let confidence = analysisResult?.confidence else {
            return .unknown
        }

        switch confidence {
        case 0.9...:
            return .veryHigh
        case 0.80..<0.9:
            return .high
        case 0.70..<0.80:
            return .medium
        case 0.60..<0.70:
            return .low
        default:
            return .veryLow
        }
    }

    var qualityLevel: QualityLevel {
        guard let quality = primaryFlirt?.qualityScores?.overall else {
            return .unknown
        }

        switch quality {
        case 0.85...:
            return .excellent
        case 0.75..<0.85:
            return .good
        case 0.65..<0.75:
            return .fair
        default:
            return .poor
        }
    }
}

// MARK: - Supporting Types

enum AnalysisPhase: Equatable {
    case idle
    case analyzing
    case analysisComplete
    case generating
    case complete
    case error
}

enum ConfidenceLevel {
    case unknown
    case veryLow
    case low
    case medium
    case high
    case veryHigh

    var displayText: String {
        switch self {
        case .unknown: return "Unknown"
        case .veryLow: return "Very Low"
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .veryHigh: return "Very High"
        }
    }

    var color: Color {
        switch self {
        case .unknown: return .gray
        case .veryLow: return .red
        case .low: return .orange
        case .medium: return .yellow
        case .high: return .green
        case .veryHigh: return .green
        }
    }
}

enum QualityLevel {
    case unknown
    case poor
    case fair
    case good
    case excellent

    var displayText: String {
        switch self {
        case .unknown: return "Unknown"
        case .poor: return "Needs Improvement"
        case .fair: return "Fair"
        case .good: return "Good"
        case .excellent: return "Excellent"
        }
    }

    var color: Color {
        switch self {
        case .unknown: return .gray
        case .poor: return .red
        case .fair: return .orange
        case .good: return .green
        case .excellent: return .green
        }
    }
}
