//
//  GamificationProgressBar.swift
//  Vibe8 (formerly Flirrt)
//
//  Persistent HUD showing points, streak, and milestone progress
//  Created by: iOS Developer Agent (Phase 3, Day 16)
//  Part of: THE VIBE8 FIXING PLAN - Gamification Implementation
//
//  Features:
//  - Points balance with star icon
//  - Streak count with flame animation
//  - Progress bar to next milestone
//  - Floating above scroll content (sticky header)
//

import SwiftUI

struct GamificationProgressBar: View {
    @Bindable var model: GamificationModel

    var body: some View {
        HStack(spacing: Vibe8Spacing.md) {

            // Points
            pointsSection

            Vibe8Divider()
                .frame(width: 1, height: 20)

            // Streak
            streakSection

            Vibe8Divider()
                .frame(width: 1, height: 20)

            // Milestone progress
            milestoneSection
        }
        .padding(.horizontal, Vibe8Spacing.md)
        .padding(.vertical, Vibe8Spacing.sm)
        .background(
            Vibe8Colors.white
                .shadow(color: Vibe8Shadow.small, radius: 4, x: 0, y: 2)
        )
        .cornerRadius(Vibe8CornerRadius.medium)
        .padding(.horizontal, Vibe8Spacing.md)
    }

    // MARK: - Points Section

    private var pointsSection: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.system(size: 14))
                .foregroundStyle(Vibe8Colors.primaryGradient)

            Text("\(model.totalPoints)")
                .font(Vibe8Typography.caption(.bold))
                .foregroundColor(Vibe8Colors.darkGray)
        }
    }

    // MARK: - Streak Section

    private var streakSection: some View {
        HStack(spacing: 4) {
            StreakFlameView(streak: model.currentStreak)

            Text("\(model.currentStreak)")
                .font(Vibe8Typography.caption(.bold))
                .foregroundColor(Vibe8Colors.darkGray)

            // Multiplier badge
            if model.streakMultiplier > 1.0 {
                Text("\(Int(model.streakMultiplier))x")
                    .font(Vibe8Typography.small())
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Vibe8Colors.primaryGradient)
                    .cornerRadius(Vibe8CornerRadius.small)
            }
        }
    }

    // MARK: - Milestone Section

    private var milestoneSection: some View {
        HStack(spacing: Vibe8Spacing.xs) {
            if let nextMilestone = model.nextMilestone() {
                // Progress bar
                ProgressView(value: model.progressToNextMilestone())
                    .progressViewStyle(LinearProgressViewStyle(
                        tint: Vibe8Colors.primaryGradient
                    ))
                    .frame(width: 60)

                // Milestone icon
                Image(systemName: nextMilestone.icon)
                    .font(.system(size: 12))
                    .foregroundColor(Vibe8Colors.darkGray.opacity(0.6))
            } else {
                // All milestones achieved
                Image(systemName: "trophy.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Vibe8Colors.primaryGradient)
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct GamificationProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Vibe8Spacing.lg) {
            // No streak
            GamificationProgressBar(model: {
                let model = GamificationModel()
                return model
            }())

            // 3-day streak (2x multiplier)
            GamificationProgressBar(model: {
                let model = GamificationModel()
                model.totalPoints = 1500
                model.currentStreak = 3
                return model
            }())

            // 7-day streak (3x multiplier)
            GamificationProgressBar(model: {
                let model = GamificationModel()
                model.totalPoints = 5000
                model.currentStreak = 7
                return model
            }())
        }
        .padding()
        .background(Vibe8Colors.lightGray)
        .previewLayout(.sizeThatFits)
    }
}
#endif
