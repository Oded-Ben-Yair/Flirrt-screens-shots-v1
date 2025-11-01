//
//  ScrollViewModel.swift
//  Flirrt (Vibe8)
//
//  ScrollView iOS 18 APIs integration for gamification
//  Provides scroll position tracking and geometry for progressive content revelation
//

import SwiftUI

/// Scroll view model for tracking scroll state and implementing gamification mechanics
/// Integrates iOS 18 ScrollPosition and ScrollGeometry APIs
/// Will be used by Gamification Specialist Agent in Week 4
@MainActor
@Observable
final class ScrollViewModel {

    // MARK: - Scroll Position

    /// Current scroll position (iOS 18+)
    var scrollPosition: ScrollPosition = .init()

    /// Current scroll offset (y-axis)
    var scrollOffset: CGFloat = 0

    /// Previous scroll offset (for calculating velocity)
    private var previousScrollOffset: CGFloat = 0

    /// Scroll velocity (points per update)
    var scrollVelocity: CGFloat = 0

    /// Scroll direction
    var scrollDirection: ScrollDirection = .idle

    enum ScrollDirection {
        case idle
        case up
        case down
    }

    // MARK: - Content Tracking

    /// Visible content IDs (for tracking what user has seen)
    var visibleContentIds: Set<String> = []

    /// Content that has been revealed (gamification tracking)
    var revealedContentIds: Set<String> = []

    /// Total content count
    var totalContentCount: Int = 0

    /// Percentage of content revealed
    var revealProgress: Double {
        guard totalContentCount > 0 else { return 0 }
        return Double(revealedContentIds.count) / Double(totalContentCount)
    }

    // MARK: - Scroll State

    /// Is currently scrolling
    var isScrolling: Bool = false

    /// Has user scrolled past initial threshold (engagement metric)
    var hasEngaged: Bool = false

    /// Scroll engagement threshold (points)
    private let engagementThreshold: CGFloat = 300

    // MARK: - Initialization

    init(totalContentCount: Int = 0) {
        self.totalContentCount = totalContentCount
    }

    // MARK: - Scroll Tracking

    /// Handle scroll geometry changes (iOS 18+)
    func handleScrollGeometryChange(oldOffset: CGFloat, newOffset: CGFloat) {
        // Update scroll offset
        scrollOffset = newOffset

        // Calculate velocity
        scrollVelocity = newOffset - previousScrollOffset
        previousScrollOffset = newOffset

        // Determine direction
        if scrollVelocity > 1 {
            scrollDirection = .down
        } else if scrollVelocity < -1 {
            scrollDirection = .up
        } else {
            scrollDirection = .idle
        }

        // Track engagement
        if !hasEngaged && abs(scrollOffset) > engagementThreshold {
            hasEngaged = true
        }

        // Mark as scrolling
        isScrolling = abs(scrollVelocity) > 0.1
    }

    /// Track visible content (called from view)
    func trackVisibleContent(id: String) {
        visibleContentIds.insert(id)
    }

    /// Reveal content (gamification mechanic)
    func revealContent(id: String) {
        revealedContentIds.insert(id)
    }

    /// Reset scroll state (e.g., when navigating away)
    func reset() {
        scrollOffset = 0
        previousScrollOffset = 0
        scrollVelocity = 0
        scrollDirection = .idle
        isScrolling = false
        hasEngaged = false
        visibleContentIds.removeAll()
        revealedContentIds.removeAll()
    }

    // MARK: - Content Revelation Logic (for Gamification)

    /// Determine if content should be revealed based on scroll position
    /// Will be enhanced by Gamification Specialist Agent in Week 4
    func shouldRevealContent(at index: Int, itemHeight: CGFloat) -> Bool {
        let revealThreshold = CGFloat(revealedContentIds.count) * itemHeight
        return scrollOffset > revealThreshold
    }

    /// Get content reveal delay (for staggered animations)
    func getRevealDelay(for index: Int) -> Double {
        return Double(index) * 0.1 // 100ms between reveals
    }
}

// MARK: - Scroll Metrics (Analytics)

extension ScrollViewModel {
    /// Get scroll engagement metrics
    var scrollMetrics: ScrollMetrics {
        ScrollMetrics(
            totalScrollDistance: abs(scrollOffset),
            maxScrollVelocity: scrollVelocity,
            contentRevealPercentage: revealProgress,
            hasEngaged: hasEngaged,
            visibleContentCount: visibleContentIds.count
        )
    }
}

struct ScrollMetrics {
    let totalScrollDistance: CGFloat
    let maxScrollVelocity: CGFloat
    let contentRevealPercentage: Double
    let hasEngaged: Bool
    let visibleContentCount: Int
}

// MARK: - Preview Helpers

#if DEBUG
extension ScrollViewModel {
    static var preview: ScrollViewModel {
        ScrollViewModel(totalContentCount: 20)
    }

    static var previewWithProgress: ScrollViewModel {
        let model = ScrollViewModel(totalContentCount: 20)
        model.scrollOffset = 500
        model.hasEngaged = true
        model.revealedContentIds = Set(["1", "2", "3", "4", "5"])
        return model
    }
}
#endif
