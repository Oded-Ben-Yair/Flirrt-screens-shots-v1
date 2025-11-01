//
//  PointsEarnedAnimation.swift
//  Vibe8 (formerly Flirrt)
//
//  Floating Points Animation
//  Created by: iOS Developer Agent (Phase 3, Day 16)
//  Part of: THE VIBE8 FIXING PLAN - Gamification Implementation
//
//  Features:
//  - Floating "+X" text that rises and fades
//  - Uses Vibe8 gradient styling
//  - Auto-removes after animation complete
//

import SwiftUI

struct PointsEarnedAnimation: View {
    let points: Int
    let action: String
    let onComplete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 4) {
            Text("+\(points)")
                .font(Vibe8Typography.headline)
                .fontWeight(.bold)
                .foregroundStyle(Vibe8Colors.primaryGradient)

            if !action.isEmpty {
                Text(action)
                    .font(Vibe8Typography.small())
                    .foregroundColor(Vibe8Colors.darkGray.opacity(0.7))
            }
        }
        .scaleEffect(scale)
        .offset(y: offset)
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                offset = -50
                opacity = 0
            }

            // Subtle bounce on appear
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 1.2
            }

            // Return to normal scale
            withAnimation(.easeOut(duration: 0.3).delay(0.2)) {
                scale = 1.0
            }

            // Remove after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                onComplete()
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct PointsEarnedAnimation_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Vibe8Colors.lightGray.ignoresSafeArea()

            VStack(spacing: 40) {
                PointsEarnedAnimation(
                    points: 10,
                    action: "Scroll Reveal",
                    onComplete: {}
                )

                PointsEarnedAnimation(
                    points: 25,
                    action: "Copy Flirt",
                    onComplete: {}
                )

                PointsEarnedAnimation(
                    points: 50,
                    action: "Rate Flirt",
                    onComplete: {}
                )
            }
        }
        .previewLayout(.sizeThatFits)
    }
}
#endif
