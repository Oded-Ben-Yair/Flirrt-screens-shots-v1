//
//  StreakFlameView.swift
//  Vibe8 (formerly Flirrt)
//
//  Animated Flame Icon for Streak Display
//  Created by: iOS Developer Agent (Phase 3, Day 16)
//  Part of: THE VIBE8 FIXING PLAN - Gamification Implementation
//
//  Features:
//  - Pulsing animation on active streaks
//  - Different flame colors based on streak level
//  - Multiple flames for longer streaks (1🔥 → 3🔥 → 7🔥)
//

import SwiftUI

struct StreakFlameView: View {
    let streak: Int

    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<flameCount, id: \.self) { _ in
                Image(systemName: "flame.fill")
                    .font(.system(size: 14))
                    .foregroundColor(flameColor)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .animation(
                        .easeInOut(duration: 0.8)
                        .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            if streak > 0 {
                isAnimating = true
            }
        }
        .onChange(of: streak) { _, newStreak in
            isAnimating = newStreak > 0
        }
    }

    // MARK: - Computed Properties

    private var flameCount: Int {
        switch streak {
        case 0...2: return 1
        case 3...6: return 2
        case 7...: return 3
        default: return 1
        }
    }

    private var flameColor: Color {
        switch streak {
        case 0: return Color.gray // No streak
        case 1...2: return Color.orange // Building streak
        case 3...6: return Color.red // Good streak (2x multiplier)
        case 7...: return Color(red: 1.0, green: 0.27, blue: 0.0) // Hot streak (3x multiplier)
        default: return Color.orange
        }
    }
}

// MARK: - Preview

#if DEBUG
struct StreakFlameView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Vibe8Spacing.lg) {
            HStack {
                Text("No streak:")
                StreakFlameView(streak: 0)
            }

            HStack {
                Text("Day 1:")
                StreakFlameView(streak: 1)
            }

            HStack {
                Text("Day 3 (2x):")
                StreakFlameView(streak: 3)
            }

            HStack {
                Text("Day 7 (3x):")
                StreakFlameView(streak: 7)
            }

            HStack {
                Text("Day 14:")
                StreakFlameView(streak: 14)
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif
