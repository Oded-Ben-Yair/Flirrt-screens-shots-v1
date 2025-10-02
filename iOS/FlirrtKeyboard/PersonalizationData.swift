//
//  PersonalizationData.swift
//  Flirrt
//
//  Created on 2025-10-01
//  Personalization profile storage using App Groups for keyboard extension access
//

import Foundation

// MARK: - Enums

/// User's dating experience level
enum DatingExperience: String, Codable, Sendable, CaseIterable {
    case newToDating = "New to dating"
    case someExperience = "Some experience"
    case prettyExperienced = "Pretty experienced"
    case datingExpert = "Dating expert"

    var displayName: String { rawValue }
}

/// Dating goals (multi-select)
enum DatingGoal: String, Codable, Sendable, CaseIterable {
    case casualDating = "Casual dating"
    case seriousRelationship = "Serious relationship"
    case friendship = "Friendship"
    case somethingFun = "Something fun"
    case notSureYet = "Not sure yet"
    case openToAnything = "Open to anything"

    var displayName: String { rawValue }
}

/// Communication style preference
enum CommunicationStyle: String, Codable, Sendable, CaseIterable {
    case direct = "Direct"
    case playful = "Playful"
    case thoughtful = "Thoughtful"
    case funny = "Funny"
    case mysterious = "Mysterious"

    var displayName: String { rawValue }

    var emoji: String {
        switch self {
        case .direct: return "🎯"
        case .playful: return "😄"
        case .thoughtful: return "💭"
        case .funny: return "😂"
        case .mysterious: return "🌙"
        }
    }
}

/// User interests (multi-select)
enum Interest: String, Codable, Sendable, CaseIterable {
    case sports = "Sports"
    case music = "Music"
    case movies = "Movies"
    case reading = "Reading"
    case travel = "Travel"
    case food = "Food"
    case fitness = "Fitness"
    case art = "Art"
    case technology = "Technology"
    case nature = "Nature"
    case gaming = "Gaming"
    case photography = "Photography"

    var displayName: String { rawValue }

    var emoji: String {
        switch self {
        case .sports: return "⚽️"
        case .music: return "🎵"
        case .movies: return "🎬"
        case .reading: return "📚"
        case .travel: return "✈️"
        case .food: return "🍕"
        case .fitness: return "💪"
        case .art: return "🎨"
        case .technology: return "💻"
        case .nature: return "🌿"
        case .gaming: return "🎮"
        case .photography: return "📸"
        }
    }
}

/// Conversation topics (multi-select)
enum ConversationTopic: String, Codable, Sendable, CaseIterable {
    case dreams = "Dreams and goals"
    case humor = "Humor and jokes"
    case deepQuestions = "Deep questions"
    case currentEvents = "Current events"
    case hobbies = "Hobbies"
    case adventures = "Adventures"
    case food = "Food and dining"
    case entertainment = "Entertainment"
    case philosophy = "Philosophy"
    case dailyLife = "Daily life"

    var displayName: String { rawValue }

    var emoji: String {
        switch self {
        case .dreams: return "✨"
        case .humor: return "😄"
        case .deepQuestions: return "🤔"
        case .currentEvents: return "📰"
        case .hobbies: return "🎯"
        case .adventures: return "🗺"
        case .food: return "🍽"
        case .entertainment: return "🎭"
        case .philosophy: return "💭"
        case .dailyLife: return "☕️"
        }
    }
}

// MARK: - PersonalizationProfile

/// Complete user personalization profile from onboarding questionnaire
struct PersonalizationProfile: Codable, Sendable {
    // Question 1: Dating experience
    var datingExperience: DatingExperience?

    // Question 2: Dating goals (multi-select)
    var datingGoals: [DatingGoal]

    // Question 3: Communication style
    var communicationStyle: CommunicationStyle?

    // Question 4: Confidence level (1-10)
    var confidenceLevel: Int?

    // Question 5: Interests (multi-select)
    var interests: [Interest]

    // Question 6: Ideal first date
    var idealFirstDate: String?

    // Question 7: Conversation topics (multi-select)
    var conversationTopics: [ConversationTopic]

    // Question 8: Flirting comfort level (1-10)
    var flirtingComfort: Int?

    // Metadata
    var createdAt: Date
    var updatedAt: Date
    var version: Int

    init(
        datingExperience: DatingExperience? = nil,
        datingGoals: [DatingGoal] = [],
        communicationStyle: CommunicationStyle? = nil,
        confidenceLevel: Int? = nil,
        interests: [Interest] = [],
        idealFirstDate: String? = nil,
        conversationTopics: [ConversationTopic] = [],
        flirtingComfort: Int? = nil
    ) {
        self.datingExperience = datingExperience
        self.datingGoals = datingGoals
        self.communicationStyle = communicationStyle
        self.confidenceLevel = confidenceLevel
        self.interests = interests
        self.idealFirstDate = idealFirstDate
        self.conversationTopics = conversationTopics
        self.flirtingComfort = flirtingComfort

        let now = Date()
        self.createdAt = now
        self.updatedAt = now
        self.version = 1
    }

    // MARK: - Computed Properties

    /// Check if profile has all required fields completed
    var isComplete: Bool {
        return datingExperience != nil &&
               !datingGoals.isEmpty &&
               communicationStyle != nil &&
               confidenceLevel != nil &&
               !interests.isEmpty &&
               idealFirstDate != nil && !(idealFirstDate?.isEmpty ?? true) &&
               !conversationTopics.isEmpty &&
               flirtingComfort != nil
    }

    /// Calculate completion percentage (0-100)
    var completionPercentage: Int {
        var completedFields = 0
        let totalFields = 8

        if datingExperience != nil { completedFields += 1 }
        if !datingGoals.isEmpty { completedFields += 1 }
        if communicationStyle != nil { completedFields += 1 }
        if confidenceLevel != nil { completedFields += 1 }
        if !interests.isEmpty { completedFields += 1 }
        if idealFirstDate != nil && !(idealFirstDate?.isEmpty ?? true) { completedFields += 1 }
        if !conversationTopics.isEmpty { completedFields += 1 }
        if flirtingComfort != nil { completedFields += 1 }

        return Int((Double(completedFields) / Double(totalFields)) * 100)
    }

    /// Human-readable summary for debugging
    var summary: String {
        return """
        PersonalizationProfile:
        - Experience: \(datingExperience?.displayName ?? "N/A")
        - Goals: \(datingGoals.map { $0.displayName }.joined(separator: ", "))
        - Style: \(communicationStyle?.displayName ?? "N/A")
        - Confidence: \(confidenceLevel.map { "\($0)/10" } ?? "N/A")
        - Interests: \(interests.map { $0.displayName }.joined(separator: ", "))
        - First Date: \(idealFirstDate ?? "N/A")
        - Topics: \(conversationTopics.map { $0.displayName }.joined(separator: ", "))
        - Flirting Comfort: \(flirtingComfort.map { "\($0)/10" } ?? "N/A")
        - Complete: \(isComplete ? "Yes" : "No") (\(completionPercentage)%)
        """
    }

    /// Serialize to JSON for backend API
    func toJSON() -> [String: Any] {
        var json: [String: Any] = [:]

        json["dating_experience"] = datingExperience?.rawValue
        json["dating_goals"] = datingGoals.map { $0.rawValue }
        json["communication_style"] = communicationStyle?.rawValue
        json["confidence_level"] = confidenceLevel
        json["interests"] = interests.map { $0.rawValue }
        json["ideal_first_date"] = idealFirstDate
        json["conversation_topics"] = conversationTopics.map { $0.rawValue }
        json["flirting_comfort"] = flirtingComfort
        json["completion_percentage"] = completionPercentage
        json["is_complete"] = isComplete
        json["version"] = version

        return json
    }

    /// Estimated storage size in bytes
    var estimatedSizeBytes: Int {
        guard let data = try? JSONEncoder().encode(self) else { return 0 }
        return data.count
    }
}

// MARK: - PersonalizationError

enum PersonalizationError: Error, LocalizedError {
    case appGroupsNotConfigured
    case encodingFailed
    case decodingFailed
    case profileNotFound
    case storageFull
    case invalidData

    var errorDescription: String? {
        switch self {
        case .appGroupsNotConfigured:
            return "App Groups not configured. Check entitlements for 'group.com.flirrt.shared'"
        case .encodingFailed:
            return "Failed to encode personalization profile"
        case .decodingFailed:
            return "Failed to decode personalization profile"
        case .profileNotFound:
            return "No personalization profile found"
        case .storageFull:
            return "Storage limit exceeded (max 512KB for App Groups)"
        case .invalidData:
            return "Invalid profile data"
        }
    }
}

// MARK: - PersonalizationStorageManager

/// Thread-safe storage manager for personalization profile using App Groups
@MainActor
final class PersonalizationStorageManager {

    // MARK: - Constants

    /// App Group identifier (must match entitlements)
    private static let appGroupIdentifier = "group.com.flirrt.shared"

    /// UserDefaults key for storing profile
    private static let profileKey = "flirrt_personalization_profile_v1"

    /// Maximum allowed storage size (512KB App Groups limit)
    private static let maxStorageSizeBytes = 512 * 1024

    /// Target storage size to stay well under limit
    private static let targetStorageSizeBytes = 50 * 1024 // 50KB target

    // MARK: - Shared Instance

    static let shared = PersonalizationStorageManager()

    private init() {}

    // MARK: - Private Properties

    private var userDefaults: UserDefaults? {
        UserDefaults(suiteName: Self.appGroupIdentifier)
    }

    // MARK: - Public Methods

    /// Save personalization profile to App Groups
    /// - Parameter profile: The profile to save
    /// - Throws: PersonalizationError if save fails
    /// - Returns: Actual storage size used in bytes
    @discardableResult
    func saveProfile(_ profile: PersonalizationProfile) throws -> Int {
        guard let userDefaults = userDefaults else {
            throw PersonalizationError.appGroupsNotConfigured
        }

        // Update metadata
        var updatedProfile = profile
        updatedProfile.updatedAt = Date()
        updatedProfile.version += 1

        // Encode profile
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        guard let data = try? encoder.encode(updatedProfile) else {
            throw PersonalizationError.encodingFailed
        }

        // Check storage size
        let sizeBytes = data.count
        if sizeBytes > Self.maxStorageSizeBytes {
            throw PersonalizationError.storageFull
        }

        // Save to App Groups
        userDefaults.set(data, forKey: Self.profileKey)
        userDefaults.synchronize() // Force immediate save

        // Log success
        os_log("✅ Saved personalization profile - Size: %d bytes (%d%% of target)",
               log: OSLog.default, type: .info, sizeBytes,
               Int((Double(sizeBytes) / Double(Self.targetStorageSizeBytes)) * 100))

        return sizeBytes
    }

    /// Load personalization profile from App Groups
    /// - Returns: The loaded profile, or nil if not found
    /// - Throws: PersonalizationError if load fails
    func loadProfile() throws -> PersonalizationProfile? {
        let startTime = CFAbsoluteTimeGetCurrent()

        guard let userDefaults = userDefaults else {
            throw PersonalizationError.appGroupsNotConfigured
        }

        guard let data = userDefaults.data(forKey: Self.profileKey) else {
            return nil // Profile not found (not an error, user hasn't completed onboarding)
        }

        // Decode profile
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let profile = try? decoder.decode(PersonalizationProfile.self, from: data) else {
            throw PersonalizationError.decodingFailed
        }

        let elapsedMs = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        os_log("✅ Loaded personalization profile - Time: %.2f ms, Size: %d bytes",
               log: OSLog.default, type: .info, elapsedMs, data.count)

        return profile
    }

    /// Check if a profile exists without loading it (fast)
    /// - Returns: True if profile exists
    func hasProfile() -> Bool {
        guard let userDefaults = userDefaults else { return false }
        return userDefaults.data(forKey: Self.profileKey) != nil
    }

    /// Delete personalization profile from App Groups
    func deleteProfile() {
        guard let userDefaults = userDefaults else { return }
        userDefaults.removeObject(forKey: Self.profileKey)
        userDefaults.synchronize()

        os_log("🗑 Deleted personalization profile", log: OSLog.default, type: .info)
    }

    /// Get profile metadata without full deserialization (fast check)
    func getProfileMetadata() -> (exists: Bool, sizeBytes: Int, lastUpdated: Date?) {
        guard let userDefaults = userDefaults else {
            return (false, 0, nil)
        }

        guard let data = userDefaults.data(forKey: Self.profileKey) else {
            return (false, 0, nil)
        }

        // Quick metadata extraction without full decode
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let profile = try? decoder.decode(PersonalizationProfile.self, from: data) {
            return (true, data.count, profile.updatedAt)
        }

        return (true, data.count, nil)
    }

    /// Validate App Groups configuration
    func validateConfiguration() -> Bool {
        guard let userDefaults = userDefaults else {
            os_log("❌ App Groups not configured for identifier: %@",
                   log: OSLog.default, type: .error, Self.appGroupIdentifier)
            return false
        }

        // Test write
        let testKey = "flirrt_app_groups_test"
        userDefaults.set(Date().timeIntervalSince1970, forKey: testKey)
        userDefaults.synchronize()

        let canRead = userDefaults.object(forKey: testKey) != nil
        userDefaults.removeObject(forKey: testKey)

        if canRead {
            os_log("✅ App Groups configured correctly: %@",
                   log: OSLog.default, type: .info, Self.appGroupIdentifier)
        } else {
            os_log("❌ App Groups write/read test failed",
                   log: OSLog.default, type: .error)
        }

        return canRead
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension PersonalizationProfile {
    /// Create a sample profile for testing
    static var sample: PersonalizationProfile {
        PersonalizationProfile(
            datingExperience: .someExperience,
            datingGoals: [.casualDating, .somethingFun],
            communicationStyle: .playful,
            confidenceLevel: 7,
            interests: [.music, .movies, .food, .travel],
            idealFirstDate: "Coffee at a cozy cafe with good conversation",
            conversationTopics: [.humor, .hobbies, .adventures, .food],
            flirtingComfort: 6
        )
    }

    /// Create a minimal profile for testing
    static var minimal: PersonalizationProfile {
        PersonalizationProfile(
            datingExperience: .newToDating,
            datingGoals: [.notSureYet],
            communicationStyle: .thoughtful,
            confidenceLevel: 5,
            interests: [.reading],
            idealFirstDate: "Something simple",
            conversationTopics: [.dailyLife],
            flirtingComfort: 4
        )
    }
}
#endif
