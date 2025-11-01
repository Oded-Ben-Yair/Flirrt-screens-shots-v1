//
//  GamificationModelTests.swift
//  FlirrtTests
//
//  Unit tests for GamificationModel
//  Tests points, streaks, milestones, tiers, and persistence
//

import XCTest
@testable import Flirrt

@MainActor
final class GamificationModelTests: XCTestCase {

    var sut: GamificationModel!

    override func setUp() {
        super.setUp()
        // Clear UserDefaults before each test
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "gamification.totalPoints")
        defaults.removeObject(forKey: "gamification.currentStreak")
        defaults.removeObject(forKey: "gamification.lastVisitDate")
        defaults.removeObject(forKey: "gamification.hasUsedStreakFreeze")
        defaults.removeObject(forKey: "gamification.lastStreakFreezeResetDate")
        defaults.removeObject(forKey: "gamification.unlockedTiers")
        defaults.removeObject(forKey: "gamification.achievedMilestones")
        defaults.removeObject(forKey: "gamification.flirtsRevealedCount")
        defaults.synchronize()

        sut = GamificationModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Points System Tests

    func testAwardPoints_ScrollReveal_Awards10Points() {
        // Given
        let initialPoints = sut.totalPoints

        // When
        sut.awardPoints(for: .scrollReveal)

        // Then
        XCTAssertEqual(sut.totalPoints, initialPoints + 10, "Revealing a flirt should award 10 points")
    }

    func testAwardPoints_CopyFlirt_Awards25Points() {
        // Given
        let initialPoints = sut.totalPoints

        // When
        sut.awardPoints(for: .copyFlirt)

        // Then
        XCTAssertEqual(sut.totalPoints, initialPoints + 25, "Copying a flirt should award 25 points")
    }

    func testAwardPoints_RateFlirt_Awards50Points() {
        // Given
        let initialPoints = sut.totalPoints

        // When
        sut.awardPoints(for: .rateFlirt)

        // Then
        XCTAssertEqual(sut.totalPoints, initialPoints + 50, "Rating a flirt should award 50 points")
    }

    func testAwardPoints_GenerateFlirts_Awards100Points() {
        // Given
        let initialPoints = sut.totalPoints

        // When
        sut.awardPoints(for: .generateFlirts)

        // Then
        XCTAssertEqual(sut.totalPoints, initialPoints + 100, "Generating flirts should award 100 points")
    }

    func testAwardPoints_DailyLogin_Awards200Points() {
        // Given
        let initialPoints = sut.totalPoints

        // When
        sut.awardPoints(for: .dailyLogin)

        // Then
        XCTAssertEqual(sut.totalPoints, initialPoints + 200, "Daily login should award 200 points")
    }

    func testAwardPoints_WithMultiplier_MultipliesCorrectly() {
        // Given
        sut.currentStreak = 3 // Should give 2x multiplier
        let basePoints = PointAction.scrollReveal.pointValue // 10 points
        let expectedPoints = basePoints * 2 // 20 points with 2x multiplier
        let initialPoints = sut.totalPoints

        // When
        sut.awardPoints(for: .scrollReveal)

        // Then
        XCTAssertEqual(sut.totalPoints, initialPoints + expectedPoints,
                       "Points should be multiplied by streak multiplier")
    }

    func testSpendPoints_UnlockQualityTier_DeductsCorrectly() {
        // Given
        sut.totalPoints = 1000
        let costToUnlock = 500

        // When
        sut.spendPoints(costToUnlock)

        // Then
        XCTAssertEqual(sut.totalPoints, 500, "Spending points should deduct from balance")
    }

    func testSpendPoints_InsufficientBalance_DoesNotDeduct() {
        // Given
        sut.totalPoints = 100
        let costToUnlock = 500

        // When
        sut.spendPoints(costToUnlock)

        // Then
        XCTAssertEqual(sut.totalPoints, 100, "Should not spend points if balance insufficient")
    }

    // MARK: - Streak System Tests

    func testUpdateStreakStatus_FirstVisit_InitializesStreak() {
        // Given: Fresh install, no previous visit

        // When
        sut.updateStreakStatus()

        // Then
        XCTAssertEqual(sut.currentStreak, 1, "First visit should initialize streak to 1")
        XCTAssertNotNil(sut.lastVisitDate, "Last visit date should be set")
    }

    func testUpdateStreakStatus_SameDay_DoesNotIncrement() {
        // Given
        sut.updateStreakStatus() // First visit
        let initialStreak = sut.currentStreak

        // When
        sut.updateStreakStatus() // Second visit same day

        // Then
        XCTAssertEqual(sut.currentStreak, initialStreak, "Streak should not increment on same day")
    }

    func testUpdateStreakStatus_NextDay_IncrementsStreak() {
        // Given
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        sut.lastVisitDate = yesterday
        sut.currentStreak = 1

        // When
        sut.updateStreakStatus()

        // Then
        XCTAssertEqual(sut.currentStreak, 2, "Streak should increment when visiting next day")
    }

    func testUpdateStreakStatus_MissedDay_WithFreeze_MaintainsStreak() {
        // Given
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        sut.lastVisitDate = twoDaysAgo
        sut.currentStreak = 5
        sut.hasUsedStreakFreeze = false // Freeze available

        // When
        sut.updateStreakStatus()

        // Then
        XCTAssertEqual(sut.currentStreak, 5, "Streak should be maintained with freeze")
        XCTAssertTrue(sut.hasUsedStreakFreeze, "Freeze should be consumed")
    }

    func testUpdateStreakStatus_MissedDay_WithoutFreeze_ResetsStreak() {
        // Given
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        sut.lastVisitDate = twoDaysAgo
        sut.currentStreak = 5
        sut.hasUsedStreakFreeze = true // Freeze already used

        // When
        sut.updateStreakStatus()

        // Then
        XCTAssertEqual(sut.currentStreak, 1, "Streak should reset when missing day without freeze")
    }

    func testStreakMultiplier_Day1To2_Returns1x() {
        // Given
        sut.currentStreak = 2

        // When
        let multiplier = sut.streakMultiplier

        // Then
        XCTAssertEqual(multiplier, 1.0, "Multiplier should be 1x for streak 1-2")
    }

    func testStreakMultiplier_Day3To6_Returns2x() {
        // Given
        sut.currentStreak = 5

        // When
        let multiplier = sut.streakMultiplier

        // Then
        XCTAssertEqual(multiplier, 2.0, "Multiplier should be 2x for streak 3-6")
    }

    func testStreakMultiplier_Day7Plus_Returns3x() {
        // Given
        sut.currentStreak = 10

        // When
        let multiplier = sut.streakMultiplier

        // Then
        XCTAssertEqual(multiplier, 3.0, "Multiplier should be 3x for streak 7+")
    }

    func testStreakFreeze_ResetsMonthly() {
        // Given
        let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        sut.lastStreakFreezeResetDate = lastMonth
        sut.hasUsedStreakFreeze = true

        // When
        sut.checkAndResetStreakFreeze()

        // Then
        XCTAssertFalse(sut.hasUsedStreakFreeze, "Freeze should reset monthly")
    }

    // MARK: - Milestone Tests

    func testCheckMilestones_Explorer_TriggersAt10Flirts() {
        // Given
        sut.flirtsRevealedCount = 9

        // When
        sut.flirtsRevealedCount = 10
        let milestone = sut.checkMilestones()

        // Then
        XCTAssertNotNil(milestone, "Explorer milestone should trigger at 10 flirts")
        XCTAssertEqual(milestone?.type, .explorer)
        XCTAssertEqual(milestone?.reward.points, 100)
    }

    func testCheckMilestones_Connoisseur_TriggersAt50Flirts() {
        // Given
        sut.flirtsRevealedCount = 49

        // When
        sut.flirtsRevealedCount = 50
        let milestone = sut.checkMilestones()

        // Then
        XCTAssertNotNil(milestone, "Connoisseur milestone should trigger at 50 flirts")
        XCTAssertEqual(milestone?.type, .connoisseur)
        XCTAssertEqual(milestone?.reward.points, 500)
    }

    func testCheckMilestones_Master_TriggersAt100Flirts() {
        // Given
        sut.flirtsRevealedCount = 99

        // When
        sut.flirtsRevealedCount = 100
        let milestone = sut.checkMilestones()

        // Then
        XCTAssertNotNil(milestone, "Master milestone should trigger at 100 flirts")
        XCTAssertEqual(milestone?.type, .master)
        XCTAssertEqual(milestone?.reward.points, 1500)
    }

    func testCheckMilestones_AlreadyAchieved_DoesNotTriggerAgain() {
        // Given
        sut.flirtsRevealedCount = 10
        _ = sut.checkMilestones() // First trigger

        // When
        sut.flirtsRevealedCount = 11
        let secondMilestone = sut.checkMilestones()

        // Then
        XCTAssertNil(secondMilestone, "Milestone should not trigger twice")
    }

    func testMilestoneReward_AddsPointsToBalance() {
        // Given
        sut.totalPoints = 100
        sut.flirtsRevealedCount = 10

        // When
        let milestone = sut.checkMilestones()
        if let milestone = milestone {
            sut.awardMilestoneReward(milestone)
        }

        // Then
        XCTAssertEqual(sut.totalPoints, 200, "Milestone reward should add 100 points")
    }

    // MARK: - Quality Tier Tests

    func testUnlockTier_Bronze_AlwaysAvailable() {
        // Given
        let bronze = QualityTier.bronze

        // When
        let canUnlock = sut.canUnlockTier(bronze)

        // Then
        XCTAssertTrue(canUnlock, "Bronze tier should always be available")
    }

    func testUnlockTier_Silver_RequiresFlirts() {
        // Given
        sut.flirtsRevealedCount = 2 // Less than required 3

        // When
        let canUnlock = sut.canUnlockTier(.silver)

        // Then
        XCTAssertFalse(canUnlock, "Silver tier requires 3 flirts revealed")

        // When (after revealing 3)
        sut.flirtsRevealedCount = 3
        let canUnlockNow = sut.canUnlockTier(.silver)

        // Then
        XCTAssertTrue(canUnlockNow, "Silver should unlock at 3 flirts")
    }

    func testUnlockTier_Gold_RequiresFlirtsOrPoints() {
        // Given
        sut.flirtsRevealedCount = 5 // Less than required 6
        sut.totalPoints = 400 // Less than required 500

        // When
        let canUnlock = sut.canUnlockTier(.gold)

        // Then
        XCTAssertFalse(canUnlock, "Gold requires either 6 flirts OR 500 points")

        // When (meet flirts requirement)
        sut.flirtsRevealedCount = 6
        let canUnlockWithFlirts = sut.canUnlockTier(.gold)

        // Then
        XCTAssertTrue(canUnlockWithFlirts, "Gold should unlock with 6 flirts")

        // Given (reset and try with points)
        sut.flirtsRevealedCount = 0
        sut.totalPoints = 500

        // When
        let canUnlockWithPoints = sut.canUnlockTier(.gold)

        // Then
        XCTAssertTrue(canUnlockWithPoints, "Gold should unlock with 500 points")
    }

    func testUnlockTier_Platinum_RequiresFlirtsOrStreak() {
        // Given
        sut.flirtsRevealedCount = 9 // Less than required 10
        sut.currentStreak = 2 // Less than required 3

        // When
        let canUnlock = sut.canUnlockTier(.platinum)

        // Then
        XCTAssertFalse(canUnlock, "Platinum requires either 10 flirts OR 3-day streak")

        // When (meet flirts requirement)
        sut.flirtsRevealedCount = 10
        let canUnlockWithFlirts = sut.canUnlockTier(.platinum)

        // Then
        XCTAssertTrue(canUnlockWithFlirts, "Platinum should unlock with 10 flirts")

        // Given (reset and try with streak)
        sut.flirtsRevealedCount = 0
        sut.currentStreak = 3

        // When
        let canUnlockWithStreak = sut.canUnlockTier(.platinum)

        // Then
        XCTAssertTrue(canUnlockWithStreak, "Platinum should unlock with 3-day streak")
    }

    func testCheckTierUnlocks_AutomaticallyUnlocksTiers() {
        // Given
        sut.flirtsRevealedCount = 10
        sut.currentStreak = 3
        sut.totalPoints = 500

        // When
        sut.checkTierUnlocks()

        // Then
        XCTAssertTrue(sut.unlockedTiers.contains(.bronze), "Bronze should be unlocked")
        XCTAssertTrue(sut.unlockedTiers.contains(.silver), "Silver should be unlocked (3+ flirts)")
        XCTAssertTrue(sut.unlockedTiers.contains(.gold), "Gold should be unlocked (6+ flirts OR 500 pts)")
        XCTAssertTrue(sut.unlockedTiers.contains(.platinum), "Platinum should be unlocked (10+ flirts OR 3-day streak)")
    }

    // MARK: - Scroll Progress Tests

    func testSetupRevealThresholds_CreatesThresholdForEachFlirt() {
        // Given
        let flirts = createMockFlirts(count: 3)

        // When
        sut.setupRevealThresholds(for: flirts)

        // Then
        for flirt in flirts {
            let progress = sut.revealProgress(for: flirt.id)
            XCTAssertNotNil(progress, "Threshold should exist for each flirt")
        }
    }

    func testRevealProgress_NoScroll_Returns0() {
        // Given
        let flirts = createMockFlirts(count: 3)
        sut.setupRevealThresholds(for: flirts)
        sut.scrollOffset = 0

        // When
        let progress = sut.revealProgress(for: flirts[0].id)

        // Then
        XCTAssertEqual(progress, 0.0, "No scroll should mean 0% progress")
    }

    func testRevealProgress_FullScroll_Returns1() {
        // Given
        let flirts = createMockFlirts(count: 3)
        sut.setupRevealThresholds(for: flirts)

        // When: Scroll past first card completely
        sut.scrollOffset = -500 // Enough to fully reveal first card
        let progress = sut.revealProgress(for: flirts[0].id)

        // Then
        XCTAssertGreaterThanOrEqual(progress, 0.9, "Full scroll should approach 100% progress")
    }

    func testRevealProgress_FullReveal_MarkAsRevealed() {
        // Given
        let flirts = createMockFlirts(count: 3)
        sut.setupRevealThresholds(for: flirts)
        let flirtId = flirts[0].id

        // When
        sut.scrollOffset = -500
        _ = sut.revealProgress(for: flirtId)

        // Then
        XCTAssertTrue(sut.revealedFlirts.contains(flirtId), "Fully revealed flirt should be marked")
    }

    func testRevealProgress_FullReveal_AwardsPoints() {
        // Given
        let flirts = createMockFlirts(count: 3)
        sut.setupRevealThresholds(for: flirts)
        let initialPoints = sut.totalPoints

        // When
        sut.scrollOffset = -500
        _ = sut.revealProgress(for: flirts[0].id)

        // Then
        XCTAssertGreaterThan(sut.totalPoints, initialPoints, "Revealing should award points")
    }

    // MARK: - UserDefaults Persistence Tests

    func testPersistence_TotalPoints_SavesAndLoads() {
        // Given
        sut.totalPoints = 500

        // When
        let newModel = GamificationModel()

        // Then
        XCTAssertEqual(newModel.totalPoints, 500, "Points should persist across model instances")
    }

    func testPersistence_CurrentStreak_SavesAndLoads() {
        // Given
        sut.currentStreak = 5

        // When
        let newModel = GamificationModel()

        // Then
        XCTAssertEqual(newModel.currentStreak, 5, "Streak should persist across model instances")
    }

    func testPersistence_UnlockedTiers_SavesAndLoads() {
        // Given
        sut.unlockedTiers = [.bronze, .silver, .gold]

        // When
        let newModel = GamificationModel()

        // Then
        XCTAssertEqual(newModel.unlockedTiers.count, 3, "Unlocked tiers should persist")
        XCTAssertTrue(newModel.unlockedTiers.contains(.gold))
    }

    func testPersistence_AchievedMilestones_SavesAndLoads() {
        // Given
        sut.achievedMilestones = [.explorer, .connoisseur]

        // When
        let newModel = GamificationModel()

        // Then
        XCTAssertEqual(newModel.achievedMilestones.count, 2, "Milestones should persist")
        XCTAssertTrue(newModel.achievedMilestones.contains(.connoisseur))
    }

    func testPersistence_LastVisitDate_SavesAndLoads() {
        // Given
        let now = Date()
        sut.lastVisitDate = now

        // When
        let newModel = GamificationModel()

        // Then
        XCTAssertNotNil(newModel.lastVisitDate)
        // Compare dates within 1 second tolerance (UserDefaults serialization may lose precision)
        let timeDiff = abs(newModel.lastVisitDate!.timeIntervalSince(now))
        XCTAssertLessThan(timeDiff, 1.0, "Last visit date should persist")
    }

    // MARK: - Tutorial Tests

    func testTutorial_DefaultsToNotCompleted() {
        // When
        let shouldShow = GamificationTutorialManager.shared.shouldShowTutorial

        // Then
        XCTAssertTrue(shouldShow, "Tutorial should show on first launch")
    }

    func testTutorial_AfterCompletion_DoesNotShow() {
        // Given
        GamificationTutorialManager.shared.markTutorialCompleted()

        // When
        let shouldShow = GamificationTutorialManager.shared.shouldShowTutorial

        // Then
        XCTAssertFalse(shouldShow, "Tutorial should not show after completion")
    }

    // MARK: - Helper Methods

    private func createMockFlirts(count: Int) -> [GeneratedFlirt] {
        return (0..<count).map { index in
            GeneratedFlirt(
                id: UUID(),
                text: "Mock flirt \(index)",
                tone: .playful,
                qualityScore: 0.85,
                sentiment: 0.8,
                creativity: 0.7,
                relevance: 0.9,
                appropriateness: 0.95
            )
        }
    }
}

// MARK: - Performance Tests

final class GamificationPerformanceTests: XCTestCase {

    @MainActor
    func testScrollPerformance_100Updates_CompletesQuickly() {
        let model = GamificationModel()
        let flirts = (0..<10).map { index in
            GeneratedFlirt(
                id: UUID(),
                text: "Flirt \(index)",
                tone: .playful,
                qualityScore: 0.85,
                sentiment: 0.8,
                creativity: 0.7,
                relevance: 0.9,
                appropriateness: 0.95
            )
        }
        model.setupRevealThresholds(for: flirts)

        measure {
            for offset in stride(from: 0, to: -1000, by: -10) {
                model.scrollOffset = CGFloat(offset)
                for flirt in flirts {
                    _ = model.revealProgress(for: flirt.id)
                }
            }
        }
        // Should complete in < 0.1s for 60fps performance (100 updates x 10 flirts = 1000 calculations)
    }
}
