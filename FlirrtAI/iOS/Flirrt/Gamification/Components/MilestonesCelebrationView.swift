//
//  MilestonesCelebrationView.swift
//  Vibe8 (formerly Flirrt)
//
//  Celebration Overlay for Milestone Achievements
//  Created by: iOS Developer Agent (Phase 3, Day 16)
//  Part of: THE VIBE8 FIXING PLAN - Gamification Implementation
//
//  Features:
//  - Full-screen celebration overlay
//  - Confetti/particle effects (optional)
//  - Reward display
//  - Auto-dismiss after 3 seconds
//

import SwiftUI

struct MilestonesCelebrationView: View {
    let milestone: Milestone
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.0

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissWithAnimation()
                }

            VStack(spacing: Vibe8Spacing.lg) {

                // Milestone icon
                Image(systemName: milestone.icon)
                    .font(.system(size: 80))
                    .foregroundStyle(Vibe8Colors.primaryGradient)
                    .scaleEffect(scale)

                // Title
                Text(milestone.title)
                    .font(Vibe8Typography.headline)
                    .foregroundColor(Vibe8Colors.darkGray)

                // Description
                Text(milestone.description)
                    .font(Vibe8Typography.bodyMedium)
                    .foregroundColor(Vibe8Colors.darkGray.opacity(0.7))
                    .multilineTextAlignment(.center)

                // Reward
                VStack(spacing: Vibe8Spacing.sm) {
                    Text("Reward")
                        .font(Vibe8Typography.small())
                        .foregroundColor(Vibe8Colors.darkGray.opacity(0.6))

                    Text(milestone.reward.displayName)
                        .font(Vibe8Typography.subheadline)
                        .foregroundStyle(Vibe8Colors.primaryGradient)
                }
                .padding(Vibe8Spacing.md)
                .background(
                    Vibe8Colors.white
                        .cornerRadius(Vibe8CornerRadius.medium)
                )

                // Dismiss button
                Button(action: {
                    dismissWithAnimation()
                }) {
                    Text("Continue")
                        .font(Vibe8Typography.bodyMedium)
                        .foregroundColor(.white)
                        .padding(.horizontal, Vibe8Spacing.xl)
                        .padding(.vertical, Vibe8Spacing.md)
                        .background(Vibe8Colors.primaryGradient)
                        .cornerRadius(Vibe8CornerRadius.pill)
                }
            }
            .padding(Vibe8Spacing.xl)
            .background(
                Vibe8Colors.white
                    .cornerRadius(Vibe8CornerRadius.large)
                    .shadow(color: Vibe8Shadow.large, radius: 20, x: 0, y: 10)
            )
            .padding(Vibe8Spacing.xl)
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            // Entrance animation
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }

            // Auto-dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                dismissWithAnimation()
            }

            // Haptic feedback
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private func dismissWithAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            scale = 0.8
            opacity = 0.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
}

// MARK: - Preview

#if DEBUG
struct MilestonesCelebrationView_Previews: PreviewProvider {
    static var previews: some View {
        MilestonesCelebrationView(
            milestone: Milestone(
                id: "explorer",
                title: "Explorer",
                description: "You've revealed 10 flirts!",
                requirement: 10,
                reward: Reward(
                    type: .points,
                    value: 100,
                    displayName: "+100 points"
                ),
                icon: "map.fill"
            ),
            onDismiss: {}
        )
        .background(Vibe8Colors.lightGray)
    }
}
#endif
