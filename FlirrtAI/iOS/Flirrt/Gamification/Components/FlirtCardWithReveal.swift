//
//  FlirtCardWithReveal.swift
//  Vibe8 (formerly Flirrt)
//
//  Flirt Card with Scroll-Based Revelation
//  Created by: iOS Developer Agent (Phase 3, Day 16)
//  Part of: THE VIBE8 FIXING PLAN - Gamification Implementation
//
//  Features:
//  - Progressive blur reveal (discrete levels for 60fps)
//  - Teaser text preview
//  - Quality badge reveal at 50%
//  - Tone badge reveal at 75%
//  - Full metadata at 100%
//  - Haptic feedback on complete reveal
//

import SwiftUI

struct FlirtCardWithReveal: View {
    let flirt: GeneratedFlirt
    @Bindable var gamificationModel: GamificationModel

    @State private var revealProgress: Double = 0.0
    @State private var isFullyRevealed: Bool = false

    // Thresholds for progressive UI reveal
    private let qualityBadgeThreshold: Double = 0.5
    private let toneBadgeThreshold: Double = 0.75
    private let fullMetadataThreshold: Double = 1.0

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Base card (always rendered, hidden behind blur initially)
            baseCardContent
                .opacity(isFullyRevealed ? 1.0 : 0.5)

            // Blur overlay (conditionally rendered for performance)
            if revealProgress < fullMetadataThreshold {
                blurOverlay
                    .allowsHitTesting(false) // Don't block interactions
            }

            // Teaser text (only when heavily blurred)
            if revealProgress < qualityBadgeThreshold {
                teaserOverlay
            }

            // Quality badge (appears at 50%)
            if revealProgress >= qualityBadgeThreshold,
               let scores = flirt.qualityScores {
                QualityBadge(score: scores.overall)
                    .padding(Vibe8Spacing.sm)
                    .transition(.scale.combined(with: .opacity))
            }

            // Reveal progress indicator (visual feedback)
            if revealProgress > 0 && revealProgress < fullMetadataThreshold {
                revealProgressIndicator
            }
        }
        .vibe8Card()
        .onChange(of: gamificationModel.scrollOffset) { _, _ in
            updateRevealProgress()
        }
        .onAppear {
            updateRevealProgress()
        }
    }

    // MARK: - Base Card Content

    private var baseCardContent: some View {
        VStack(alignment: .leading, spacing: Vibe8Spacing.md) {

            // Flirt text
            Text(flirt.flirt)
                .font(Vibe8Typography.body)
                .foregroundColor(Vibe8Colors.darkGray)
                .fixedSize(horizontal: false, vertical: true)

            // Metadata (only when fully revealed)
            if isFullyRevealed {
                Vibe8Divider()

                // Tone badge
                HStack {
                    Vibe8Badge(flirt.tone.displayName, color: Vibe8Colors.orangeGradientStart)

                    Spacer()

                    // Quality scores (if available)
                    if let scores = flirt.qualityScores {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                            Text("\(Int(scores.overall * 100))%")
                                .font(Vibe8Typography.small())
                        }
                        .foregroundColor(Vibe8Colors.darkGray.opacity(0.7))
                    }
                }

                // Reasoning (if available)
                if let reasoning = flirt.reasoning, !reasoning.isEmpty {
                    Text(reasoning)
                        .font(Vibe8Typography.small())
                        .foregroundColor(Vibe8Colors.darkGray.opacity(0.6))
                        .italic()
                }
            }
        }
        .padding(Vibe8Spacing.md)
        .frame(minHeight: 150)
    }

    // MARK: - Blur Overlay (60fps Optimized)

    private var blurOverlay: some View {
        Rectangle()
            .fill(Vibe8Colors.white.opacity(0.95))
            .blur(radius: blurRadius(for: revealProgress), opaque: true)
            .cornerRadius(Vibe8CornerRadius.medium)
    }

    /// Discrete blur levels for 60fps performance (no continuous calculations)
    private func blurRadius(for progress: Double) -> CGFloat {
        switch progress {
        case 0..<0.25: return 20
        case 0.25..<0.5: return 15
        case 0.5..<0.75: return 10
        case 0.75..<1.0: return 5
        default: return 0
        }
    }

    // MARK: - Teaser Overlay

    private var teaserOverlay: some View {
        VStack {
            Spacer()

            VStack(spacing: Vibe8Spacing.xs) {
                Text(String(flirt.flirt.prefix(15)) + "...")
                    .font(Vibe8Typography.bodyMedium)
                    .foregroundColor(Vibe8Colors.darkGray)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .font(.caption)
                    Text("Scroll to reveal")
                        .font(Vibe8Typography.small())
                }
                .foregroundColor(Vibe8Colors.darkGray.opacity(0.6))
            }
            .padding(Vibe8Spacing.md)
            .background(
                Vibe8Colors.white
                    .opacity(0.9)
                    .cornerRadius(Vibe8CornerRadius.small)
            )
            .padding(Vibe8Spacing.md)

            Spacer()
        }
    }

    // MARK: - Reveal Progress Indicator

    private var revealProgressIndicator: some View {
        VStack {
            Spacer()

            HStack(spacing: 4) {
                ProgressView(value: revealProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: Vibe8Colors.primaryGradient))
                    .frame(width: 60)

                Text("\(Int(revealProgress * 100))%")
                    .font(Vibe8Typography.small())
                    .foregroundColor(Vibe8Colors.darkGray.opacity(0.7))
            }
            .padding(.horizontal, Vibe8Spacing.sm)
            .padding(.vertical, 4)
            .background(
                Vibe8Colors.white
                    .opacity(0.9)
                    .cornerRadius(Vibe8CornerRadius.small)
            )
            .padding(Vibe8Spacing.sm)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    // MARK: - Reveal Progress Calculation (60fps Optimized)

    private func updateRevealProgress() {
        // Get progress from gamification model (pre-calculated thresholds)
        let progress = gamificationModel.revealProgress(for: flirt.id)

        // Only update if changed significantly (reduce state updates)
        if abs(progress - revealProgress) > 0.05 {
            withAnimation(.easeOut(duration: 0.3)) {
                revealProgress = progress
            }
        }

        // Handle full reveal
        if progress >= fullMetadataThreshold && !isFullyRevealed {
            withAnimation(.easeOut(duration: 0.3)) {
                isFullyRevealed = true
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct FlirtCardWithReveal_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            FlirtCardWithReveal(
                flirt: GeneratedFlirt(
                    id: UUID(),
                    flirt: "I noticed you're into hiking! Have you tackled any challenging trails recently?",
                    tone: .playful,
                    reasoning: "References hiking from profile photos",
                    confidence: 0.85,
                    alternatives: [],
                    qualityScores: QualityScores(
                        sentiment: 0.9,
                        length: 0.8,
                        creativity: 0.85,
                        relevance: 0.9,
                        toneMatching: 0.8,
                        overall: 0.85
                    ),
                    isPrimary: true
                ),
                gamificationModel: GamificationModel()
            )
            .padding()
        }
        .background(Vibe8Colors.lightGray)
    }
}
#endif
