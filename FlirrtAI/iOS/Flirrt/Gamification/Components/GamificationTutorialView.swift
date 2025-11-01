//
//  GamificationTutorialView.swift
//  Vibe8 (formerly Flirrt)
//
//  First-Time User Tutorial Overlay
//  Created by: iOS Developer Agent (Phase 3, Day 20)
//  Part of: THE VIBE8 FIXING PLAN - Gamification Implementation
//
//  Features:
//  - Multi-step tutorial (3 steps)
//  - Explains scroll-to-reveal mechanic
//  - Introduces points & streak system
//  - Auto-shows on first app launch
//  - Can be dismissed or skipped
//

import SwiftUI

struct GamificationTutorialView: View {
    @State private var currentStep: Int = 0
    let onComplete: () -> Void

    private let steps: [TutorialStep] = [
        TutorialStep(
            icon: "arrow.down.circle.fill",
            title: "Scroll to Reveal",
            description: "Flirts start blurred. Scroll down to reveal them and earn 10 points per flirt!",
            color: .purple
        ),
        TutorialStep(
            icon: "star.fill",
            title: "Earn Points",
            description: "Copy flirts (25pts), rate them (50pts), and generate new ones (100pts) to earn more points!",
            color: .orange
        ),
        TutorialStep(
            icon: "flame.fill",
            title: "Build Your Streak",
            description: "Return daily to build your streak and earn 2x-3x point multipliers!",
            color: .red
        )
    ]

    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture {
                    // Allow tap outside to skip
                    skipTutorial()
                }

            VStack(spacing: Vibe8Spacing.xl) {

                Spacer()

                // Tutorial content
                VStack(spacing: Vibe8Spacing.lg) {

                    // Icon
                    Image(systemName: currentStepData.icon)
                        .font(.system(size: 80))
                        .foregroundColor(currentStepData.color)
                        .transition(.scale.combined(with: .opacity))

                    // Title
                    Text(currentStepData.title)
                        .font(Vibe8Typography.headline)
                        .foregroundColor(Vibe8Colors.darkGray)
                        .transition(.opacity)

                    // Description
                    Text(currentStepData.description)
                        .font(Vibe8Typography.bodyMedium)
                        .foregroundColor(Vibe8Colors.darkGray.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Vibe8Spacing.lg)
                        .transition(.opacity)
                }
                .padding(Vibe8Spacing.xl)
                .background(
                    Vibe8Colors.white
                        .cornerRadius(Vibe8CornerRadius.large)
                        .shadow(color: Vibe8Shadow.large, radius: 20, x: 0, y: 10)
                )
                .padding(.horizontal, Vibe8Spacing.xl)

                Spacer()

                // Navigation
                VStack(spacing: Vibe8Spacing.md) {

                    // Step indicators
                    HStack(spacing: 8) {
                        ForEach(0..<steps.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentStep ?
                                      Vibe8Colors.primaryGradient :
                                      AnyShapeStyle(Color.white.opacity(0.3)))
                                .frame(width: 8, height: 8)
                        }
                    }

                    // Action buttons
                    HStack(spacing: Vibe8Spacing.md) {
                        // Skip button
                        if currentStep < steps.count - 1 {
                            Button(action: skipTutorial) {
                                Text("Skip")
                                    .font(Vibe8Typography.bodyMedium)
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.horizontal, Vibe8Spacing.lg)
                                    .padding(.vertical, Vibe8Spacing.md)
                            }
                        }

                        Spacer()

                        // Next/Done button
                        Button(action: nextStep) {
                            Text(currentStep < steps.count - 1 ? "Next" : "Got it!")
                                .font(Vibe8Typography.bodyMedium)
                                .foregroundColor(.white)
                                .padding(.horizontal, Vibe8Spacing.xl)
                                .padding(.vertical, Vibe8Spacing.md)
                                .background(Vibe8Colors.primaryGradient)
                                .cornerRadius(Vibe8CornerRadius.pill)
                        }
                    }
                    .padding(.horizontal, Vibe8Spacing.xl)
                }
                .padding(.bottom, Vibe8Spacing.xxl)
            }
        }
    }

    // MARK: - Computed Properties

    private var currentStepData: TutorialStep {
        steps[currentStep]
    }

    // MARK: - Actions

    private func nextStep() {
        if currentStep < steps.count - 1 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentStep += 1
            }
        } else {
            completeTutorial()
        }
    }

    private func skipTutorial() {
        completeTutorial()
    }

    private func completeTutorial() {
        // Mark tutorial as completed
        UserDefaults.standard.set(true, forKey: "gamification.tutorialCompleted")

        // Haptic feedback
        UINotificationFeedbackGenerator().notificationOccurred(.success)

        // Dismiss
        onComplete()
    }
}

// MARK: - Tutorial Step Model

struct TutorialStep {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

// MARK: - Tutorial Manager

class GamificationTutorialManager {
    static let shared = GamificationTutorialManager()

    var shouldShowTutorial: Bool {
        !UserDefaults.standard.bool(forKey: "gamification.tutorialCompleted")
    }

    func resetTutorial() {
        UserDefaults.standard.set(false, forKey: "gamification.tutorialCompleted")
    }
}

// MARK: - Preview

#if DEBUG
struct GamificationTutorialView_Previews: PreviewProvider {
    static var previews: some View {
        GamificationTutorialView(onComplete: {})
    }
}
#endif
