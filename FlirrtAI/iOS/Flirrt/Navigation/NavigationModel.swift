//
//  NavigationModel.swift
//  Flirrt (Vibe8)
//
//  Type-safe navigation using NavigationStack (iOS 16+)
//  Migrated to Observation framework (iOS 17+)
//

import SwiftUI

/// Centralized navigation model for type-safe routing throughout the app
/// Uses NavigationStack with explicit Route enum for compile-time safety
@MainActor
@Observable
final class NavigationModel {

    // MARK: - Navigation Path

    /// Navigation stack path - automatically tracked by @Observable
    var path: [Route] = []

    // MARK: - Route Definition

    /// All possible routes in the app
    /// Add new routes here as features are implemented
    enum Route: Hashable {
        // Onboarding & Auth
        case ageVerification
        case signIn
        case onboarding
        case personalization

        // Main Features
        case screenshotAnalysis
        case toneSelection
        case flirtGeneration(screenshot: Data?)
        case flirtResults([Flirt])
        case flirtDetail(Flirt)

        // Voice Features
        case voiceRecording
        case voiceScripts
        case voiceScriptDetail(VoiceScript)
        case voiceCloneManagement

        // Gamification (Week 4)
        case gamifiedDiscovery
        case achievements
        case engagementStats

        // Settings & Profile
        case settings
        case profile
        case preferences
        case about
        case help

        // Hashable conformance for NavigationStack
        static func == (lhs: Route, rhs: Route) -> Bool {
            switch (lhs, rhs) {
            case (.ageVerification, .ageVerification),
                 (.signIn, .signIn),
                 (.onboarding, .onboarding),
                 (.personalization, .personalization),
                 (.screenshotAnalysis, .screenshotAnalysis),
                 (.toneSelection, .toneSelection),
                 (.voiceRecording, .voiceRecording),
                 (.voiceScripts, .voiceScripts),
                 (.voiceCloneManagement, .voiceCloneManagement),
                 (.gamifiedDiscovery, .gamifiedDiscovery),
                 (.achievements, .achievements),
                 (.engagementStats, .engagementStats),
                 (.settings, .settings),
                 (.profile, .profile),
                 (.preferences, .preferences),
                 (.about, .about),
                 (.help, .help):
                return true
            case let (.flirtGeneration(lhsData), .flirtGeneration(rhsData)):
                return lhsData == rhsData
            case let (.flirtResults(lhsFlirts), .flirtResults(rhsFlirts)):
                return lhsFlirts.map { $0.id } == rhsFlirts.map { $0.id }
            case let (.flirtDetail(lhsFlirt), .flirtDetail(rhsFlirt)):
                return lhsFlirt.id == rhsFlirt.id
            case let (.voiceScriptDetail(lhsScript), .voiceScriptDetail(rhsScript)):
                return lhsScript.id == rhsScript.id
            default:
                return false
            }
        }

        func hash(into hasher: inout Hasher) {
            switch self {
            case .ageVerification:
                hasher.combine("ageVerification")
            case .signIn:
                hasher.combine("signIn")
            case .onboarding:
                hasher.combine("onboarding")
            case .personalization:
                hasher.combine("personalization")
            case .screenshotAnalysis:
                hasher.combine("screenshotAnalysis")
            case .toneSelection:
                hasher.combine("toneSelection")
            case .flirtGeneration(let data):
                hasher.combine("flirtGeneration")
                hasher.combine(data)
            case .flirtResults(let flirts):
                hasher.combine("flirtResults")
                hasher.combine(flirts.map { $0.id })
            case .flirtDetail(let flirt):
                hasher.combine("flirtDetail")
                hasher.combine(flirt.id)
            case .voiceRecording:
                hasher.combine("voiceRecording")
            case .voiceScripts:
                hasher.combine("voiceScripts")
            case .voiceScriptDetail(let script):
                hasher.combine("voiceScriptDetail")
                hasher.combine(script.id)
            case .voiceCloneManagement:
                hasher.combine("voiceCloneManagement")
            case .gamifiedDiscovery:
                hasher.combine("gamifiedDiscovery")
            case .achievements:
                hasher.combine("achievements")
            case .engagementStats:
                hasher.combine("engagementStats")
            case .settings:
                hasher.combine("settings")
            case .profile:
                hasher.combine("profile")
            case .preferences:
                hasher.combine("preferences")
            case .about:
                hasher.combine("about")
            case .help:
                hasher.combine("help")
            }
        }
    }

    // MARK: - Navigation Actions

    /// Navigate to a new route
    func navigate(to route: Route) {
        path.append(route)
    }

    /// Navigate to multiple routes at once (e.g., deep linking)
    func navigate(to routes: [Route]) {
        path.append(contentsOf: routes)
    }

    /// Go back one level
    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    /// Go back multiple levels
    func pop(count: Int) {
        guard count > 0, count <= path.count else { return }
        path.removeLast(count)
    }

    /// Go back to root (clear entire stack)
    func popToRoot() {
        path.removeAll()
    }

    /// Replace current route with a new one
    func replace(with route: Route) {
        if !path.isEmpty {
            path.removeLast()
        }
        path.append(route)
    }

    /// Check if currently on a specific route
    func isCurrentRoute(_ route: Route) -> Bool {
        return path.last == route
    }

    /// Get current depth of navigation stack
    var depth: Int {
        return path.count
    }

    /// Check if at root
    var isAtRoot: Bool {
        return path.isEmpty
    }
}

// MARK: - Convenience Extensions

extension NavigationModel {
    /// Common navigation flows

    func navigateToFlirtFlow(screenshot: Data?) {
        navigate(to: .flirtGeneration(screenshot: screenshot))
    }

    func navigateToVoiceFlow() {
        navigate(to: .voiceRecording)
    }

    func navigateToSettings() {
        navigate(to: .settings)
    }
}

// MARK: - Preview Helpers

#if DEBUG
extension NavigationModel {
    static var preview: NavigationModel {
        NavigationModel()
    }

    static var previewWithPath: NavigationModel {
        let model = NavigationModel()
        model.path = [.screenshotAnalysis, .toneSelection]
        return model
    }
}
#endif
