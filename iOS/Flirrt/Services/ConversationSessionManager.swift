//
//  ConversationSessionManager.swift
//  Vibe8
//
//  Created on 2025-10-19.
//  Copyright © 2025 Vibe8. All rights reserved.
//

import Foundation
import OSLog

/// Manages conversation sessions with 30-minute timeout and screenshot grouping
/// Tracks conversation context across multiple screenshots for backend AI
@MainActor
final class ConversationSessionManager: ObservableObject {

    // MARK: - Published Properties
    @Published var currentConversationID: String?
    @Published var conversationStartTime: Date?
    @Published var screenshotCount: Int = 0
    @Published var conversationActive: Bool = false

    // MARK: - Private Properties
    private let logger = Logger(subsystem: "com.vibe8.app", category: "ConversationSession")
    private let sharedDefaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
    private let sessionTimeout: TimeInterval = 30 * 60 // 30 minutes in seconds

    // MARK: - Initialization
    init() {
        logger.info("🔄 ConversationSessionManager initialized")
        loadExistingSession()
    }

    // MARK: - Session Management

    /// Gets or creates a conversation session ID
    /// - Returns: Active conversation ID (existing or new)
    func getOrCreateSession() -> String {
        // Check if we have an active session
        if let existingID = currentConversationID,
           let startTime = conversationStartTime,
           isSessionActive(startTime: startTime) {
            logger.debug("♻️ Reusing active conversation session: \(existingID)")
            updateLastActivity()
            return existingID
        }

        // Create new session
        let newID = generateConversationID()
        let startTime = Date()

        currentConversationID = newID
        conversationStartTime = startTime
        screenshotCount = 0
        conversationActive = true

        logger.info("✨ Created new conversation session: \(newID)")

        // Persist to App Groups
        persistSession()

        return newID
    }

    /// Increments screenshot count for current session
    func incrementScreenshotCount() {
        screenshotCount += 1
        updateLastActivity()

        logger.debug("📸 Screenshot count incremented: \(self.screenshotCount)")

        // Update in App Groups
        sharedDefaults?.set(screenshotCount, forKey: AppConstants.UserDefaultsKeys.conversationScreenshotCount)
        sharedDefaults?.synchronize()
    }

    /// Manually resets the current session
    func resetSession() {
        logger.info("🔄 Manually resetting conversation session")

        currentConversationID = nil
        conversationStartTime = nil
        screenshotCount = 0
        conversationActive = false

        // Clear from App Groups
        sharedDefaults?.removeObject(forKey: AppConstants.UserDefaultsKeys.currentConversationID)
        sharedDefaults?.removeObject(forKey: AppConstants.UserDefaultsKeys.conversationStartTime)
        sharedDefaults?.removeObject(forKey: AppConstants.UserDefaultsKeys.conversationScreenshotCount)
        sharedDefaults?.removeObject(forKey: AppConstants.UserDefaultsKeys.conversationLastActivity)
        sharedDefaults?.synchronize()

        logger.info("✅ Session reset complete")
    }

    /// Checks if the current session is still active (within 30 minutes)
    func isSessionActive() -> Bool {
        guard let startTime = conversationStartTime else {
            return false
        }
        return isSessionActive(startTime: startTime)
    }

    /// Gets current session info for debugging
    func getSessionInfo() -> [String: Any] {
        return [
            "conversation_id": currentConversationID ?? "none",
            "start_time": conversationStartTime?.timeIntervalSince1970 ?? 0,
            "screenshot_count": screenshotCount,
            "active": conversationActive,
            "time_remaining": getTimeRemaining(),
            "session_timeout": sessionTimeout
        ]
    }

    // MARK: - Private Methods

    private func isSessionActive(startTime: Date) -> Bool {
        let elapsed = Date().timeIntervalSince(startTime)
        return elapsed < sessionTimeout
    }

    private func updateLastActivity() {
        let now = Date()
        sharedDefaults?.set(now.timeIntervalSince1970, forKey: AppConstants.UserDefaultsKeys.conversationLastActivity)
        sharedDefaults?.synchronize()
    }

    private func getTimeRemaining() -> TimeInterval {
        guard let startTime = conversationStartTime else {
            return 0
        }
        let elapsed = Date().timeIntervalSince(startTime)
        return max(0, sessionTimeout - elapsed)
    }

    private func generateConversationID() -> String {
        let timestamp = Int(Date().timeIntervalSince1970 * 1000) // Milliseconds
        let random = Int.random(in: 10000...99999)
        return "conv_\(timestamp)_\(random)"
    }

    private func loadExistingSession() {
        guard let conversationID = sharedDefaults?.string(forKey: AppConstants.UserDefaultsKeys.currentConversationID),
              let startTimeInterval = sharedDefaults?.double(forKey: AppConstants.UserDefaultsKeys.conversationStartTime),
              startTimeInterval > 0 else {
            logger.debug("📭 No existing session found")
            return
        }

        let startTime = Date(timeIntervalSince1970: startTimeInterval)

        // Check if session is still valid
        if isSessionActive(startTime: startTime) {
            currentConversationID = conversationID
            conversationStartTime = startTime
            screenshotCount = sharedDefaults?.integer(forKey: AppConstants.UserDefaultsKeys.conversationScreenshotCount) ?? 0
            conversationActive = true

            let minutesRemaining = Int(getTimeRemaining() / 60)
            logger.info("📂 Loaded existing session: \(conversationID) (\(minutesRemaining) min remaining)")
        } else {
            logger.info("⏰ Existing session expired, will create new on next use")
            resetSession()
        }
    }

    private func persistSession() {
        guard let conversationID = currentConversationID,
              let startTime = conversationStartTime else {
            logger.warning("⚠️ Cannot persist session - missing data")
            return
        }

        sharedDefaults?.set(conversationID, forKey: AppConstants.UserDefaultsKeys.currentConversationID)
        sharedDefaults?.set(startTime.timeIntervalSince1970, forKey: AppConstants.UserDefaultsKeys.conversationStartTime)
        sharedDefaults?.set(screenshotCount, forKey: AppConstants.UserDefaultsKeys.conversationScreenshotCount)
        sharedDefaults?.set(Date().timeIntervalSince1970, forKey: AppConstants.UserDefaultsKeys.conversationLastActivity)
        sharedDefaults?.synchronize()

        logger.debug("💾 Session persisted to App Groups")
    }

    // MARK: - Cleanup
    deinit {
        logger.info("🔄 ConversationSessionManager deinitialized")
    }
}

// MARK: - Session Timeout Extension
extension ConversationSessionManager {
    /// Returns human-readable time remaining in session
    var timeRemainingFormatted: String {
        let remaining = getTimeRemaining()
        let minutes = Int(remaining / 60)
        let seconds = Int(remaining.truncatingRemainder(dividingBy: 60))

        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }

    /// Returns percentage of session time remaining (0-100)
    var sessionTimeRemainingPercentage: Double {
        guard let startTime = conversationStartTime else {
            return 0
        }
        let elapsed = Date().timeIntervalSince(startTime)
        let percentage = max(0, min(100, ((sessionTimeout - elapsed) / sessionTimeout) * 100))
        return percentage
    }
}
