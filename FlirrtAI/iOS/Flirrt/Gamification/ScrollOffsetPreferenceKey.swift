//
//  ScrollOffsetPreferenceKey.swift
//  Vibe8 (formerly Flirrt)
//
//  Scroll Position Tracking for Gamification
//  Created by: iOS Developer Agent (Phase 3, Day 16)
//  Part of: THE VIBE8 FIXING PLAN - Gamification Implementation
//
//  PreferenceKey for efficient scroll offset tracking without
//  per-frame layout recalculations (60fps optimization)
//

import SwiftUI

// MARK: - ScrollOffsetPreferenceKey

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - ScrollOffsetModifier

struct ScrollOffsetModifier: ViewModifier {
    let coordinateSpace: String
    let onChange: (CGFloat) -> Void

    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: geometry.frame(in: .named(coordinateSpace)).minY
                    )
                }
            )
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                onChange(value)
            }
    }
}

extension View {
    /// Track scroll offset efficiently for gamification
    /// - Parameters:
    ///   - coordinateSpace: Named coordinate space for the ScrollView
    ///   - onChange: Callback with current scroll offset
    func trackScrollOffset(
        in coordinateSpace: String = "scroll",
        onChange: @escaping (CGFloat) -> Void
    ) -> some View {
        modifier(ScrollOffsetModifier(coordinateSpace: coordinateSpace, onChange: onChange))
    }
}
