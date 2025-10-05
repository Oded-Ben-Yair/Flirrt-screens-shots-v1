//
//  AppConstants.swift
//  Flirrt
//
//  Created on 2025-10-04.
//  Copyright © 2025 Flirrt. All rights reserved.
//

import Foundation

/// Centralized application constants for Flirrt.ai
/// All magic strings and configuration values should be defined here
enum AppConstants {

    // MARK: - App Group & Bundle Identifiers

    /// Shared app group identifier for data sharing between app and extensions
    /// Used by: App, Keyboard Extension, Share Extension
    static let appGroupIdentifier = "group.com.flirrt"

    /// Main app bundle identifier
    static let bundleIdentifier = "com.flirrt.app"

    /// Keyboard extension bundle identifier
    static let keyboardBundleIdentifier = "com.flirrt.app.keyboard"

    /// Share extension bundle identifier
    static let shareBundleIdentifier = "com.flirrt.app.share"

    // MARK: - API Configuration

    /// Base URL for API endpoints
    /// Development: http://localhost:3000/api/v1
    /// Production: https://api.flirrt.ai/api/v1
    static let apiBaseURL = AppEnvironment.current.apiBaseURL

    /// API request timeout interval in seconds
    static let apiTimeout: TimeInterval = 30.0

    /// API retry attempts for failed requests
    static let apiRetryAttempts = 3

    // MARK: - App Version

    /// Current app version
    static let appVersion = "1.0.0"

    /// Current build number
    static let buildNumber = "1"

    // MARK: - UserDefaults Keys

    enum UserDefaultsKeys {

        // MARK: - Authentication & User

        /// User age verification status
        static let ageVerified = "age_verified"

        /// User authentication status
        static let isAuthenticated = "isAuthenticated"

        /// User unique identifier
        static let userId = "user_id"

        /// User display name
        static let userName = "user_name"

        /// User email address
        static let userEmail = "user_email"

        /// Authentication token
        static let authToken = "auth_token"

        /// Full access permission status
        static let hasFullAccess = "has_full_access"

        // MARK: - Onboarding

        /// Main onboarding completion flag
        static let onboardingComplete = "onboarding_complete"

        /// Alternative onboarding completion flag (legacy)
        static let onboardingCompleted = "onboarding_completed"

        /// Personalization questionnaire completion flag
        static let personalizationComplete = "personalization_complete"

        /// Personalization profile data (App Groups)
        static let personalizationProfile = "flirrt_personalization_profile_v1"

        /// Dynamic personalization keys prefix (e.g., "personalization_interests")
        static func personalizationKey(_ key: String) -> String {
            return "personalization_\(key)"
        }

        // MARK: - Voice

        /// User's cloned voice ID
        static let userVoiceId = "user_voice_id"

        /// Currently selected voice ID
        static let currentVoiceId = "currentVoiceId"

        /// Stored voice clones data
        static let voiceClones = "voice_clones"

        /// Recent voice recordings data
        static let recentRecordings = "recent_recordings"

        /// Voice feature enabled status
        static let voiceEnabled = "voice_enabled"

        // MARK: - Screenshot Detection

        /// Last screenshot unique identifier
        static let lastScreenshotId = "last_screenshot_id"

        /// Last screenshot timestamp
        static let lastScreenshotTime = "last_screenshot_time"

        /// Screenshot counter
        static let screenshotCounter = "screenshot_counter"

        /// App active status during screenshot
        static let appWasActiveDuringScreenshot = "app_was_active_during_screenshot"

        /// Last app active timestamp
        static let lastActiveTime = "last_active_time"

        /// Last screenshot confirmation status
        static let lastScreenshotConfirmed = "last_screenshot_confirmed"

        /// Last screenshot confirmation timestamp
        static let lastScreenshotConfirmedTime = "last_screenshot_confirmed_time"

        /// Latest screenshot unique identifier
        static let latestScreenshotId = "latest_screenshot_id"

        /// Latest screenshot file path
        static let latestScreenshotPath = "latest_screenshot_path"

        /// Latest screenshot file size
        static let latestScreenshotSize = "latest_screenshot_size"

        /// Screenshot detection enabled status
        static let screenshotDetectionEnabled = "screenshot_detection_enabled"

        /// Latest screenshot filename
        static let latestScreenshot = "latest_screenshot"

        /// Latest screenshot time (Share Extension)
        static let latestScreenshotTimeShare = "latest_screenshot_time"

        /// Dynamic screenshot data key (e.g., "screenshot_abc123")
        static func screenshotDataKey(_ screenshotId: String) -> String {
            return "screenshot_\(screenshotId)"
        }

        // MARK: - Keyboard Extension

        /// Last keyboard heartbeat timestamp
        static let lastKeyboardHeartbeat = "last_keyboard_heartbeat"

        /// User authentication status (shared)
        static let userAuthenticated = "user_authenticated"

        /// Analysis request timestamp
        static let analysisRequestTime = "analysis_request_time"

        /// Last app open timestamp
        static let lastAppOpen = "last_app_open"

        // MARK: - Darwin Notifications

        /// Last notification payload file path
        static let lastNotificationPayloadPath = "last_notification_payload_path"

        /// Last notification name
        static let lastNotificationName = "last_notification_name"

        // MARK: - App State

        /// App launched flag
        static let appLaunched = "appLaunched"

        /// System keyboard configurations (Apple)
        static let appleKeyboards = "AppleKeyboards"

        /// Preferred AI model
        static let preferredModel = "preferred_model"

        // MARK: - Testing & Debug

        /// App Groups configuration test
        static let appGroupsTest = "flirrt_app_groups_test"

        /// Test key for validation
        static let testKey = "test_key"

        /// Test timestamp
        static let testTimestamp = "test_timestamp"

        /// Test authentication
        static let testAuth = "test_auth"
    }

    // MARK: - Shared Container Paths

    enum SharedPaths {
        /// Shared user data file
        static let userData = "userData.json"

        /// Shared conversation history
        static let conversationHistory = "conversations.json"

        /// Shared AI suggestions cache
        static let suggestionsCache = "suggestions.json"
    }

    // MARK: - Feature Flags

    enum FeatureFlags {
        /// Enable AI-powered suggestions
        static let aiSuggestionsEnabled = true

        /// Enable analytics tracking
        static let analyticsEnabled = false

        /// Enable debug logging
        static let debugLoggingEnabled = AppEnvironment.current.isDebug
    }

    // MARK: - UI Constants

    enum UI {
        /// Default animation duration
        static let animationDuration: TimeInterval = 0.3

        /// Corner radius for cards
        static let cornerRadius: CGFloat = 12.0

        /// Standard padding
        static let standardPadding: CGFloat = 16.0
    }
}

// MARK: - Environment Configuration

/// Environment-specific configuration (renamed from Environment to avoid SwiftUI conflict)
enum AppEnvironment {
    case development
    case staging
    case production

    /// Current environment (determined at compile time)
    static var current: AppEnvironment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }

    /// Environment-specific API base URL
    var apiBaseURL: String {
        switch self {
        case .development:
            return "http://localhost:3000/api/v1"
        case .staging:
            return "https://staging-api.flirrt.ai/api/v1"
        case .production:
            return "https://api.flirrt.ai/api/v1"
        }
    }

    /// Debug mode flag
    var isDebug: Bool {
        return self == .development
    }
}
