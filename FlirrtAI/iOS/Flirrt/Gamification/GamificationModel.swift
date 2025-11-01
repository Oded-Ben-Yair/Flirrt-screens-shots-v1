//
//  GamificationModel.swift
//  Vibe8 (formerly Flirrt)
//
//  Core Gamification State Management
//  Created by: iOS Developer Agent (Phase 3, Day 16)
//  Part of: THE VIBE8 FIXING PLAN - Gamification Implementation
//
//  Uses: Observation framework (iOS 17+) from Phase 1 architecture
//
//  Features:
//  - Points & streak tracking with persistence
//  - Scroll-based revelation progress
//  - Quality tier unlocking
//  - Milestone achievements
//  - 60fps optimized state updates
//

import Foundation
import SwiftUI
import Observation

@MainActor
@Observable
final class GamificationModel {

    // MARK: - Points & Progression

    var totalPoints: Int {
        didSet {
            saveToUserDefaults()
        }
    }

    var currentStreak: Int {
        didSet {
            saveToUserDefaults()
        }
    }

    var lastVisitDate: Date? {
        didSet {
            saveToUserDefaults()
        }
    }

    var hasUsedStreakFreeze: Bool {
        didSet {
            saveToUserDefaults()
        }
    }

    var lastStreakFreezeResetDate: Date? {
        didSet {
            saveToUserDefaults()
        }
    }

    // MARK: - Revelation State

    var revealedFlirts: Set<UUID> = []
    var scrollProgress: [UUID: Double] = [:] // 0.0-1.0 per flirt
    var unlockedTiers: Set<QualityTier> = [.bronze] {
        didSet {
            saveToUserDefaults()
        }
    }

    // MARK: - Scroll Tracking (Performance-Optimized)

    var scrollOffset: CGFloat = 0
    var scrollVelocity: CGFloat = 0
    private var previousScrollOffset: CGFloat = 0
    private var lastScrollUpdateTime: TimeInterval = 0

    // MARK: - Milestones

    var achievedMilestones: Set<String> = [] {
        didSet {
            saveToUserDefaults()
        }
    }

    var pendingRewards: [Reward] = []

    // MARK: - Performance

    private var performanceTracker = PerformanceTracker()
    var frameRate: Double {
        performanceTracker.avgFrameRate
    }

    // MARK: - Reveal Thresholds (Pre-calculated for 60fps)

    private var revealThresholds: [UUID: RevealThreshold] = [:]

    // MARK: - Constants

    private let cardHeight: CGFloat = 200
    private let cardSpacing: CGFloat = 16

    // MARK: - Initialization

    init() {
        // Load persisted data
        self.totalPoints = UserDefaults.standard.integer(forKey: "gamification.totalPoints")
        self.currentStreak = UserDefaults.standard.integer(forKey: "gamification.currentStreak")
        self.lastVisitDate = UserDefaults.standard.object(forKey: "gamification.lastVisitDate") as? Date
        self.hasUsedStreakFreeze = UserDefaults.standard.bool(forKey: "gamification.hasUsedStreakFreeze")
        self.lastStreakFreezeResetDate = UserDefaults.standard.object(forKey: "gamification.lastStreakFreezeResetDate") as? Date

        // Load unlocked tiers
        if let tiersData = UserDefaults.standard.data(forKey: "gamification.unlockedTiers"),
           let tiers = try? JSONDecoder().decode(Set<QualityTier>.self, from: tiersData) {
            self.unlockedTiers = tiers
        }

        // Load achieved milestones
        if let milestones = UserDefaults.standard.array(forKey: "gamification.achievedMilestones") as? [String] {
            self.achievedMilestones = Set(milestones)
        }

        // Update streak on init
        updateStreakStatus()
    }

    // MARK: - Reveal Threshold Setup

    /// Pre-calculate reveal thresholds for all flirts (optimization for 60fps)
    func setupRevealThresholds(for flirts: [GeneratedFlirt]) {
        revealThresholds.removeAll()

        for (index, flirt) in flirts.enumerated() {
            let startY = CGFloat(index) * (cardHeight + cardSpacing)
            let revealDistance = revealDistanceForIndex(index)

            revealThresholds[flirt.id] = RevealThreshold(
                flirtId: flirt.id,
                startY: startY,
                revealDistance: revealDistance
            )
        }
    }

    /// Progressive difficulty: first flirts unlock easier
    private func revealDistanceForIndex(_ index: Int) -> CGFloat {
        switch index {
        case 0...2: return 50 // Easy unlock (first 3)
        case 3...5: return 100 // Medium unlock (flirts 4-6)
        default: return 150 // Full unlock (7+)
        }
    }

    // MARK: - Scroll Updates (60fps Optimized)

    /// Update scroll offset and calculate velocity
    /// Called by ScrollOffsetPreferenceKey
    func updateScrollOffset(_ newOffset: CGFloat) {
        let currentTime = CACurrentMediaTime()

        // Calculate velocity (pixels per second)
        if lastScrollUpdateTime > 0 {
            let deltaTime = currentTime - lastScrollUpdateTime
            let deltaOffset = newOffset - previousScrollOffset

            if deltaTime > 0 {
                scrollVelocity = deltaOffset / CGFloat(deltaTime)
            }
        }

        previousScrollOffset = scrollOffset
        scrollOffset = newOffset
        lastScrollUpdateTime = currentTime

        // Record frame for performance tracking
        performanceTracker.recordFrame(at: currentTime)
    }

    /// Get reveal progress for a specific flirt (0.0-1.0)
    func revealProgress(for flirtId: UUID) -> Double {
        guard let threshold = revealThresholds[flirtId] else {
            return 0.0
        }

        let progress = threshold.progress(for: scrollOffset)
        scrollProgress[flirtId] = progress

        // Check if just became fully revealed
        if progress >= 1.0 && !revealedFlirts.contains(flirtId) {
            handleFlirtRevealed(flirtId)
        }

        return progress
    }

    /// Check if flirt is currently revealed
    func isRevealed(_ flirtId: UUID) -> Bool {
        revealedFlirts.contains(flirtId)
    }

    // MARK: - Points System

    /// Award points for an action with streak multiplier
    func awardPoints(for action: PointAction) {
        let basePoints = action.pointValue
        let multiplier = StreakMultiplier(streak: currentStreak).multiplier
        let finalPoints = Int(Double(basePoints) * multiplier)

        totalPoints += finalPoints

        // Add to pending rewards for UI display
        pendingRewards.append(Reward(
            type: .points,
            value: finalPoints,
            displayName: "+\(finalPoints) points"
        ))

        // Check for milestone achievements
        checkMilestones()
    }

    /// Spend points for premium features
    func spendPoints(for action: PointAction) -> Bool {
        let cost = abs(action.pointValue)

        guard totalPoints >= cost else {
            return false
        }

        totalPoints -= cost
        return true
    }

    /// Get points with scroll velocity bonus
    func awardPointsWithVelocityBonus(for action: PointAction) {
        let velocityBonus = ScrollVelocityBonus.bonus(for: scrollVelocity)

        // Award base points
        awardPoints(for: action)

        // Award velocity bonus if applicable
        if velocityBonus.points > 0 {
            totalPoints += velocityBonus.points
            pendingRewards.append(Reward(
                type: .points,
                value: velocityBonus.points,
                displayName: "\(velocityBonus.displayName) +\(velocityBonus.points)"
            ))
        }
    }

    // MARK: - Flirt Revelation

    private func handleFlirtRevealed(_ flirtId: UUID) {
        revealedFlirts.insert(flirtId)

        // Award points with velocity bonus
        awardPointsWithVelocityBonus(for: .scrollReveal)

        // Check tier unlocks
        checkTierUnlocks()

        // Check milestones
        checkMilestones()

        // Haptic feedback
        triggerHapticFeedback(style: .light)
    }

    // MARK: - Quality Tier System

    /// Check if a tier should be unlocked
    private func checkTierUnlocks() {
        for tier in QualityTier.allCases {
            if !unlockedTiers.contains(tier) {
                let requirement = tier.unlockRequirement
                if requirement.isMet(
                    flirtsRevealed: revealedFlirts.count,
                    points: totalPoints,
                    streak: currentStreak
                ) {
                    unlockTier(tier)
                }
            }
        }
    }

    private func unlockTier(_ tier: QualityTier) {
        unlockedTiers.insert(tier)

        // Celebrate unlock with reward
        pendingRewards.append(Reward(
            type: .badge,
            value: 0,
            displayName: "\(tier.displayName) Tier Unlocked!"
        ))

        triggerHapticFeedback(style: .medium)
    }

    func isTierUnlocked(_ tier: QualityTier) -> Bool {
        unlockedTiers.contains(tier)
    }

    // MARK: - Milestone System

    private func checkMilestones() {
        for milestone in Milestone.allMilestones {
            if !achievedMilestones.contains(milestone.id) &&
               revealedFlirts.count >= milestone.requirement {
                achieveMilestone(milestone)
            }
        }
    }

    private func achieveMilestone(_ milestone: Milestone) {
        achievedMilestones.insert(milestone.id)

        // Award milestone reward
        totalPoints += milestone.reward.value
        pendingRewards.append(milestone.reward)

        triggerHapticFeedback(style: .success)
    }

    func nextMilestone() -> Milestone? {
        Milestone.allMilestones
            .filter { !achievedMilestones.contains($0.id) }
            .min(by: { $0.requirement < $1.requirement })
    }

    func progressToNextMilestone() -> Double {
        guard let next = nextMilestone() else {
            return 1.0 // All milestones achieved
        }
        return Double(revealedFlirts.count) / Double(next.requirement)
    }

    // MARK: - Streak System

    /// Update streak based on current date
    func updateStreakStatus() {
        let now = Date()
        let calendar = Calendar.current

        guard let lastVisit = lastVisitDate else {
            // First visit
            currentStreak = 1
            lastVisitDate = now
            awardPoints(for: .dailyLogin)
            return
        }

        let daysSinceLastVisit = calendar.dateComponents([.day], from: lastVisit, to: now).day ?? 0

        if daysSinceLastVisit == 0 {
            // Same day, no change
            return
        } else if daysSinceLastVisit == 1 {
            // Consecutive day, increment streak
            currentStreak += 1
            lastVisitDate = now
            awardPoints(for: .dailyLogin)
        } else if daysSinceLastVisit == 2 && !hasUsedStreakFreeze {
            // Missed one day, but can use freeze
            // Don't change streak, mark freeze as used
            hasUsedStreakFreeze = true
            lastVisitDate = now
            awardPoints(for: .dailyLogin)
        } else {
            // Streak broken
            currentStreak = 1
            lastVisitDate = now
            hasUsedStreakFreeze = false
            awardPoints(for: .dailyLogin)
        }

        // Reset streak freeze weekly (every Sunday)
        resetStreakFreezeIfNeeded()
    }

    private func resetStreakFreezeIfNeeded() {
        let now = Date()
        let calendar = Calendar.current

        guard let lastReset = lastStreakFreezeResetDate else {
            lastStreakFreezeResetDate = now
            return
        }

        let daysSinceReset = calendar.dateComponents([.day], from: lastReset, to: now).day ?? 0

        if daysSinceReset >= 7 {
            hasUsedStreakFreeze = false
            lastStreakFreezeResetDate = now
        }
    }

    var streakMultiplier: Double {
        StreakMultiplier(streak: currentStreak).multiplier
    }

    var streakIcon: String {
        StreakMultiplier(streak: currentStreak).icon
    }

    // MARK: - Haptic Feedback

    private func triggerHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        Task { @MainActor in
            UIImpactFeedbackGenerator(style: style).impactOccurred()
        }
    }

    private func triggerHapticFeedback(style: UINotificationFeedbackGenerator.FeedbackType) {
        Task { @MainActor in
            UINotificationFeedbackGenerator().notificationOccurred(style)
        }
    }

    // MARK: - Pending Rewards

    func consumePendingReward() -> Reward? {
        guard !pendingRewards.isEmpty else {
            return nil
        }
        return pendingRewards.removeFirst()
    }

    func clearPendingRewards() {
        pendingRewards.removeAll()
    }

    // MARK: - Persistence

    private func saveToUserDefaults() {
        UserDefaults.standard.set(totalPoints, forKey: "gamification.totalPoints")
        UserDefaults.standard.set(currentStreak, forKey: "gamification.currentStreak")
        UserDefaults.standard.set(lastVisitDate, forKey: "gamification.lastVisitDate")
        UserDefaults.standard.set(hasUsedStreakFreeze, forKey: "gamification.hasUsedStreakFreeze")
        UserDefaults.standard.set(lastStreakFreezeResetDate, forKey: "gamification.lastStreakFreezeResetDate")

        // Save unlocked tiers
        if let tiersData = try? JSONEncoder().encode(unlockedTiers) {
            UserDefaults.standard.set(tiersData, forKey: "gamification.unlockedTiers")
        }

        // Save achieved milestones
        UserDefaults.standard.set(Array(achievedMilestones), forKey: "gamification.achievedMilestones")
    }

    // MARK: - Reset (for testing)

    func resetAllProgress() {
        totalPoints = 0
        currentStreak = 0
        lastVisitDate = nil
        hasUsedStreakFreeze = false
        lastStreakFreezeResetDate = nil
        revealedFlirts.removeAll()
        scrollProgress.removeAll()
        unlockedTiers = [.bronze]
        achievedMilestones.removeAll()
        pendingRewards.removeAll()

        // Clear UserDefaults
        let keys = [
            "gamification.totalPoints",
            "gamification.currentStreak",
            "gamification.lastVisitDate",
            "gamification.hasUsedStreakFreeze",
            "gamification.lastStreakFreezeResetDate",
            "gamification.unlockedTiers",
            "gamification.achievedMilestones"
        ]
        keys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }

    // MARK: - Computed Properties

    var totalFlirtsRevealed: Int {
        revealedFlirts.count
    }

    var meetsPerformanceTarget: Bool {
        performanceTracker.meetsTarget
    }
}
