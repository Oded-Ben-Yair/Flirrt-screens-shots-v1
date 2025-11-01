//
//  DesignSystem.swift
//  Vibe8 (formerly Flirrt)
//
//  Vibe8 Brand Design System
//  Created by: UX/UI Designer Agent (GPT-5-Pro)
//  Reference: /home/odedbe/design for vibe8/Vibe8 STYLE.png
//

import SwiftUI

// MARK: - Vibe8 Colors

/// Vibe8 brand colors - Orange to Pink gradient
enum Vibe8Colors {

    // MARK: - Primary Gradient

    /// Primary gradient start: Orange
    static let orangeGradientStart = Color(hex: "FFBF0B")

    /// Primary gradient end: Pink
    static let pinkGradientEnd = Color(hex: "FD1782")

    /// Primary brand gradient (Orange → Pink)
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [orangeGradientStart, pinkGradientEnd],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// Vertical gradient (for backgrounds)
    static var primaryGradientVertical: LinearGradient {
        LinearGradient(
            colors: [orangeGradientStart, pinkGradientEnd],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Radial gradient (for special effects)
    static var primaryGradientRadial: RadialGradient {
        RadialGradient(
            colors: [orangeGradientStart, pinkGradientEnd],
            center: .center,
            startRadius: 0,
            endRadius: 300
        )
    }

    // MARK: - Secondary Colors

    /// Dark gray for text and icons
    static let darkGray = Color(hex: "3D3D3D")

    /// White for backgrounds and cards
    static let white = Color.white

    /// Light gray for subtle backgrounds
    static let lightGray = Color(hex: "F5F5F5")

    /// Border gray for dividers and borders
    static let borderGray = Color(hex: "E0E0E0")

    // MARK: - Semantic Colors

    /// Success color
    static let success = Color.green

    /// Error color
    static let error = Color.red

    /// Warning color
    static let warning = Color.orange

    /// Info color
    static let info = Color.blue
}

// MARK: - Vibe8 Typography

/// Vibe8 typography system using Montserrat font family
enum Vibe8Typography {

    // MARK: - Font Weights

    private static let fontFamily = "Montserrat"

    /// Montserrat Regular (400)
    private static func regular(_ size: CGFloat) -> Font {
        .custom("\(fontFamily)-Regular", size: size)
    }

    /// Montserrat Semibold (600)
    private static func semibold(_ size: CGFloat) -> Font {
        .custom("\(fontFamily)-SemiBold", size: size)
    }

    /// Montserrat Bold (700)
    private static func bold(_ size: CGFloat) -> Font {
        .custom("\(fontFamily)-Bold", size: size)
    }

    // MARK: - Text Styles

    /// Large title (32pt, Bold)
    static var largeTitle: Font { bold(32) }

    /// Title (28pt, Bold)
    static var title: Font { bold(28) }

    /// Headline (24pt, Bold)
    static var headline: Font { bold(24) }

    /// Subheadline (20pt, Semibold)
    static var subheadline: Font { semibold(20) }

    /// Body (18pt, Regular)
    static var body: Font { regular(18) }

    /// Body Medium (16pt, Regular)
    static var bodyMedium: Font { regular(16) }

    /// Caption (14pt, Semibold)
    static var caption: Font { semibold(14) }

    /// Small (12pt, Regular)
    static var small: Font { regular(12) }

    // MARK: - Custom Sizes

    /// Custom heading with specific size
    static func heading(_ size: CGFloat = 28) -> Font {
        bold(size)
    }

    /// Custom body with specific size
    static func body(_ size: CGFloat = 16) -> Font {
        regular(size)
    }

    /// Custom caption with specific size
    static func caption(_ size: CGFloat = 14) -> Font {
        semibold(size)
    }

    /// Custom small with specific size
    static func small(_ size: CGFloat = 12) -> Font {
        regular(size)
    }
}

// MARK: - Vibe8 Button Style

/// Primary button style with gradient background
struct Vibe8ButtonStyle: ButtonStyle {
    var isSecondary: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Vibe8Typography.caption())
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                isSecondary
                    ? AnyView(Vibe8Colors.darkGray)
                    : AnyView(Vibe8Colors.primaryGradient)
            )
            .cornerRadius(24)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Secondary button style (outline)
struct Vibe8OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Vibe8Typography.caption())
            .foregroundColor(Vibe8Colors.darkGray)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Vibe8Colors.borderGray, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Vibe8 Card Style

/// Card style with shadow
struct Vibe8CardStyle: ViewModifier {
    var padding: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Vibe8Colors.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

extension View {
    /// Apply Vibe8 card styling
    func vibe8Card(padding: CGFloat = 20) -> some View {
        modifier(Vibe8CardStyle(padding: padding))
    }
}

// MARK: - Vibe8 Spacing

/// Vibe8 spacing system (8pt grid)
enum Vibe8Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Vibe8 Corner Radius

/// Vibe8 corner radius standards
enum Vibe8CornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let pill: CGFloat = 100 // Fully rounded
}

// MARK: - Vibe8 Shadows

/// Vibe8 shadow presets
enum Vibe8Shadow {
    static let small = Color.black.opacity(0.05)
    static let medium = Color.black.opacity(0.08)
    static let large = Color.black.opacity(0.12)

    static func card() -> some View {
        EmptyView()
            .shadow(color: medium, radius: 12, x: 0, y: 4)
    }
}

// MARK: - Color Extension (Hex Support)

extension Color {
    /// Initialize Color from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Vibe8 Navigation Bar

/// Vibe8-branded navigation bar
struct Vibe8NavigationBar: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(Vibe8Typography.heading(24))
                .foregroundStyle(Vibe8Colors.primaryGradient)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Vibe8Colors.white)
    }
}

// MARK: - Vibe8 Badge

/// Small badge component
struct Vibe8Badge: View {
    let text: String
    let color: Color

    init(_ text: String, color: Color = Vibe8Colors.orangeGradientStart) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text)
            .font(Vibe8Typography.small())
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color)
            .cornerRadius(12)
    }
}

// MARK: - Vibe8 Divider

/// Branded divider
struct Vibe8Divider: View {
    var body: some View {
        Rectangle()
            .fill(Vibe8Colors.borderGray)
            .frame(height: 1)
    }
}

// MARK: - Accessibility

extension View {
    /// Apply Vibe8 accessibility standards (WCAG 2.1 AA)
    func vibe8Accessible(
        label: String,
        hint: String? = nil,
        traits: AccessibilityTraits = []
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
            .frame(minWidth: 44, minHeight: 44) // Minimum touch target
    }
}

// MARK: - Preview Helpers

#if DEBUG
struct DesignSystem_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Typography samples
            Text("Vibe8 Design System")
                .font(Vibe8Typography.largeTitle)

            Text("Redefining human communication")
                .font(Vibe8Typography.body)
                .foregroundColor(Vibe8Colors.darkGray)

            // Gradient sample
            Rectangle()
                .fill(Vibe8Colors.primaryGradient)
                .frame(height: 60)
                .cornerRadius(16)

            // Button samples
            Button("Primary Button") {}
                .buttonStyle(Vibe8ButtonStyle())

            Button("Secondary Button") {}
                .buttonStyle(Vibe8ButtonStyle(isSecondary: true))

            Button("Outline Button") {}
                .buttonStyle(Vibe8OutlineButtonStyle())

            // Card sample
            VStack {
                Text("Card Content")
                    .font(Vibe8Typography.body)
            }
            .vibe8Card()

            // Badge sample
            HStack {
                Vibe8Badge("New")
                Vibe8Badge("Popular", color: Vibe8Colors.pinkGradientEnd)
            }
        }
        .padding()
    }
}
#endif
