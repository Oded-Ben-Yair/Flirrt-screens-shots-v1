//
//  GamificationTypes.swift
//  Vibe8 (formerly Flirrt)
//
//  Supporting Types for Gamification System
//  Created by: iOS Developer Agent (Phase 3, Day 16)
//  Part of: THE VIBE8 FIXING PLAN - Gamification Implementation
//
//  Types:
//  - QualityTier: Bronze → Silver → Gold → Platinum progression
//  - Milestone: Achievement milestones with rewards
//  - Reward: Points, badges, unlocks
//  - RevealThreshold: Per-card scroll tracking data
//

import Foundation
import SwiftUI

// MARK: - Quality Tier System

enum QualityTier: String, Codable, CaseIterable {
    case bronze = "bronze"
    case silver = "silver"
    case gold = "gold"
    case platinum = "platinum"

    var displayName: String {
        rawValue.capitalized
    }

    var scoreRange: ClosedRange<Double> {
        switch self {
        case .bronze: return 0.65...0.74
        case .silver: return 0.75...0.84
        case .gold: return 0.85...0.94
        case .platinum: return 0.95...1.0
        }
    }

    var unlockRequirement: UnlockRequirement {
        switch self {
        case .bronze:
            return .none
        case .silver:
            return .flirtsRevealed(3)
        case .gold:
            return .either(
                .flirtsRevealed(6),
                .points(500)
            )
        case .platinum:
            return .either(
                .flirtsRevealed(10),
                .streak(3)
            )
        }
    }

    var badgeColor: Color {
        switch self {
        case .bronze: return .brown
        case .silver: return .gray
        case .gold: return Color(red: 1.0, green: 0.84, blue: 0.0) // Gold color
        case .platinum: return Color(red: 0.9, green: 0.9, blue: 0.98) // Platinum/silver-white
        }
    }

    var icon: String {
        switch self {
        case .bronze: return "medal.fill"
        case .silver: return "medal.fill"
        case .gold: return "star.fill"
        case .platinum: return "crown.fill"
        }
    }

    static func tier(for score: Double) -> QualityTier {
        for tier in QualityTier.allCases.reversed() {
            if tier.scoreRange.contains(score) {
                return tier
            }
        }
        return .bronze
    }
}

// MARK: - Unlock Requirements

indirect enum UnlockRequirement {
    case none
    case flirtsRevealed(Int)
    case points(Int)
    case streak(Int)
    case either(UnlockRequirement, UnlockRequirement)
    case both(UnlockRequirement, UnlockRequirement)

    func isMet(
        flirtsRevealed: Int,
        points: Int,
        streak: Int
    ) -> Bool {
        switch self {
        case .none:
            return true
        case .flirtsRevealed(let required):
            return flirtsRevealed >= required
        case .points(let required):
            return points >= required
        case .streak(let required):
            return streak >= required
        case .either(let req1, let req2):
            return req1.isMet(flirtsRevealed: flirtsRevealed, points: points, streak: streak) ||
                   req2.isMet(flirtsRevealed: flirtsRevealed, points: points, streak: streak)
        case .both(let req1, let req2):
            return req1.isMet(flirtsRevealed: flirtsRevealed, points: points, streak: streak) &&
                   req2.isMet(flirtsRevealed: flirtsRevealed, points: points, streak: streak)
        }
    }

    var displayText: String {
        switch self {
        case .none:
            return "Always available"
        case .flirtsRevealed(let count):
            return "Reveal \(count) flirts"
        case .points(let amount):
            return "\(amount) points"
        case .streak(let days):
            return "\(days)-day streak"
        case .either(let req1, let req2):
            return "\(req1.displayText) OR \(req2.displayText)"
        case .both(let req1, let req2):
            return "\(req1.displayText) AND \(req2.displayText)"
        }
    }
}

// MARK: - Milestone System

struct Milestone: Identifiable, Codable, Hashable {
    let id: String
    let title: String
    let description: String
    let requirement: Int // Number of flirts revealed
    let reward: Reward
    let icon: String

    static let allMilestones: [Milestone] = [
        Milestone(
            id: "explorer",
            title: "Explorer",
            description: "Revealed 10 flirts",
            requirement: 10,
            reward: Reward(
                type: .points,
                value: 100,
                displayName: "+100 points"
            ),
            icon: "map.fill"
        ),
        Milestone(
            id: "connoisseur",
            title: "Connoisseur",
            description: "Revealed 50 flirts",
            requirement: 50,
            reward: Reward(
                type: .points,
                value: 500,
                displayName: "+500 points"
            ),
            icon: "sparkles"
        ),
        Milestone(
            id: "master",
            title: "Master",
            description: "Revealed 100 flirts",
            requirement: 100,
            reward: Reward(
                type: .combo,
                value: 1500,
                displayName: "+1500 points + Exclusive Theme"
            ),
            icon: "trophy.fill"
        )
    ]
}

// MARK: - Reward System

struct Reward: Codable, Hashable {
    enum RewardType: String, Codable {
        case points
        case badge
        case theme
        case combo // Multiple rewards
    }

    let type: RewardType
    let value: Int // Points amount or badge ID
    let displayName: String
}

// MARK: - Revelation Tracking

struct RevealThreshold {
    let flirtId: UUID
    let startY: CGFloat // Top of card in scroll view
    let endY: CGFloat // Point at which card is fully revealed
    let revealDistance: CGFloat // Total pixels to scroll for full reveal

    init(flirtId: UUID, startY: CGFloat, revealDistance: CGFloat) {
        self.flirtId = flirtId
        self.startY = startY
        self.endY = startY + revealDistance
        self.revealDistance = revealDistance
    }

    /// Calculate revelation progress (0.0-1.0) based on current scroll offset
    func progress(for scrollOffset: CGFloat) -> Double {
        // scrollOffset is negative in SwiftUI ScrollView
        let scrolledPast = max(0, abs(scrollOffset) - startY)
        let progress = min(1.0, scrolledPast / revealDistance)
        return progress
    }
}

// MARK: - Point Actions

enum PointAction: String {
    case scrollReveal = "scroll"
    case copyFlirt = "copy"
    case rateFlirt = "rate"
    case generateFlirts = "generate"
    case dailyLogin = "daily_login"
    case unlockPremium = "unlock_premium"
    case regenerateTone = "regenerate_tone"
    case extraAlternatives = "extra_alternatives"
    case priorityAnalysis = "priority_analysis"

    var pointValue: Int {
        switch self {
        // Earning actions
        case .scrollReveal: return 10
        case .copyFlirt: return 25
        case .rateFlirt: return 50
        case .generateFlirts: return 100
        case .dailyLogin: return 200
        // Spending actions (negative)
        case .unlockPremium: return -500
        case .regenerateTone: return -300
        case .extraAlternatives: return -400
        case .priorityAnalysis: return -1000
        }
    }

    var isEarning: Bool {
        pointValue > 0
    }

    var displayName: String {
        switch self {
        case .scrollReveal: return "Scroll Reveal"
        case .copyFlirt: return "Copy Flirt"
        case .rateFlirt: return "Rate Flirt"
        case .generateFlirts: return "Generate Flirts"
        case .dailyLogin: return "Daily Login"
        case .unlockPremium: return "Unlock Premium"
        case .regenerateTone: return "Regenerate"
        case .extraAlternatives: return "Extra Alternatives"
        case .priorityAnalysis: return "Priority Processing"
        }
    }
}

// MARK: - Scroll Velocity Bonus

enum ScrollVelocityBonus {
    case none
    case speed // >500px/sec: +5 points
    case thoughtful // <100px/sec: +10 points

    static func bonus(for velocity: CGFloat) -> ScrollVelocityBonus {
        let absVelocity = abs(velocity)
        if absVelocity > 500 {
            return .speed
        } else if absVelocity < 100 && absVelocity > 0 {
            return .thoughtful
        } else {
            return .none
        }
    }

    var points: Int {
        switch self {
        case .none: return 0
        case .speed: return 5
        case .thoughtful: return 10
        }
    }

    var displayName: String {
        switch self {
        case .none: return ""
        case .speed: return "Speed Bonus"
        case .thoughtful: return "Thoughtful Bonus"
        }
    }
}

// MARK: - Streak Multiplier

struct StreakMultiplier {
    let streak: Int

    var multiplier: Double {
        switch streak {
        case 0...2: return 1.0
        case 3...6: return 2.0
        case 7...: return 3.0
        default: return 1.0
        }
    }

    var displayText: String {
        switch streak {
        case 3...6: return "2x Multiplier!"
        case 7...: return "3x Multiplier!"
        default: return ""
        }
    }

    var icon: String {
        switch streak {
        case 3...6: return "🔥🔥"
        case 7...: return "🔥🔥🔥"
        default: return "🔥"
        }
    }
}

// MARK: - Performance Tracking

struct PerformanceTracker {
    private(set) var frameCount: Int = 0
    private(set) var lastFrameTime: TimeInterval = 0
    private(set) var droppedFrames: Int = 0
    private(set) var avgFrameRate: Double = 60.0

    mutating func recordFrame(at time: TimeInterval) {
        if lastFrameTime > 0 {
            let deltaTime = time - lastFrameTime
            let currentFPS = 1.0 / deltaTime

            // Track dropped frames (below 55fps is considered dropped)
            if currentFPS < 55.0 {
                droppedFrames += 1
            }

            // Moving average of frame rate
            avgFrameRate = (avgFrameRate * 0.9) + (currentFPS * 0.1)
        }

        lastFrameTime = time
        frameCount += 1
    }

    var meetsTarget: Bool {
        avgFrameRate >= 58.0 && droppedFrames < frameCount / 10 // <10% dropped
    }
}
