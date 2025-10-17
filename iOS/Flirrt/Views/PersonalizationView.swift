import SwiftUI

/// CP-5: Personalization View for Coaching Persona
/// Simplified settings for tone, goal, and experience level
/// Saves to App Groups for keyboard access
struct PersonalizationView: View {

    @Environment(\.presentationMode) var presentationMode
    @AppStorage("tone_preference", store: UserDefaults(suiteName: "group.com.flirrt")) private var tonePreference = "playful"
    @AppStorage("dating_goal", store: UserDefaults(suiteName: "group.com.flirrt")) private var datingGoal = "casual"
    @AppStorage("experience_level", store: UserDefaults(suiteName: "group.com.flirrt")) private var experienceLevel = "beginner"

    @State private var showingSaveConfirmation = false

    private let appGroupID = "group.com.flirrt"

    var body: some View {
        NavigationView {
            ZStack {
                // Background - iOS 26 Liquid Glass
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.15),
                        Color.black
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.badge.checkmark")
                                .font(.system(size: 60))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.pink, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )

                            Text("Coaching Preferences")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)

                            Text("Personalize your AI dating coach")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 32)
                        .padding(.bottom, 16)

                        // Tone Preference Section
                        PreferenceSection(
                            title: "Tone",
                            subtitle: "How should your coach sound?",
                            icon: "waveform.circle.fill",
                            iconColor: .pink
                        ) {
                            VStack(spacing: 12) {
                                PreferenceButton(
                                    title: "😄 Playful",
                                    subtitle: "Fun and lighthearted suggestions",
                                    isSelected: tonePreference == "playful",
                                    action: { tonePreference = "playful" }
                                )

                                PreferenceButton(
                                    title: "💼 Serious",
                                    subtitle: "Thoughtful and intentional",
                                    isSelected: tonePreference == "serious",
                                    action: { tonePreference = "serious" }
                                )

                                PreferenceButton(
                                    title: "😏 Witty",
                                    subtitle: "Clever and charming",
                                    isSelected: tonePreference == "witty",
                                    action: { tonePreference = "witty" }
                                )

                                PreferenceButton(
                                    title: "💕 Romantic",
                                    subtitle: "Heartfelt and genuine",
                                    isSelected: tonePreference == "romantic",
                                    action: { tonePreference = "romantic" }
                                )
                            }
                        }

                        // Dating Goal Section
                        PreferenceSection(
                            title: "Dating Goal",
                            subtitle: "What are you looking for?",
                            icon: "target",
                            iconColor: .purple
                        ) {
                            VStack(spacing: 12) {
                                PreferenceButton(
                                    title: "🎉 Casual",
                                    subtitle: "Fun and relaxed connections",
                                    isSelected: datingGoal == "casual",
                                    action: { datingGoal = "casual" }
                                )

                                PreferenceButton(
                                    title: "💑 Relationship",
                                    subtitle: "Looking for something serious",
                                    isSelected: datingGoal == "relationship",
                                    action: { datingGoal = "relationship" }
                                )

                                PreferenceButton(
                                    title: "👥 Friends",
                                    subtitle: "Friendship and connections",
                                    isSelected: datingGoal == "friends",
                                    action: { datingGoal = "friends" }
                                )

                                PreferenceButton(
                                    title: "🔍 Exploring",
                                    subtitle: "Open to possibilities",
                                    isSelected: datingGoal == "exploring",
                                    action: { datingGoal = "exploring" }
                                )
                            }
                        }

                        // Experience Level Section
                        PreferenceSection(
                            title: "Experience Level",
                            subtitle: "How much dating experience do you have?",
                            icon: "chart.bar.fill",
                            iconColor: .blue
                        ) {
                            VStack(spacing: 12) {
                                PreferenceButton(
                                    title: "🌱 Beginner",
                                    subtitle: "New to the dating scene",
                                    isSelected: experienceLevel == "beginner",
                                    action: { experienceLevel = "beginner" }
                                )

                                PreferenceButton(
                                    title: "📚 Learner",
                                    subtitle: "Building confidence",
                                    isSelected: experienceLevel == "learner",
                                    action: { experienceLevel = "learner" }
                                )

                                PreferenceButton(
                                    title: "💪 Confident",
                                    subtitle: "Comfortable with dating",
                                    isSelected: experienceLevel == "confident",
                                    action: { experienceLevel = "confident" }
                                )

                                PreferenceButton(
                                    title: "👑 Expert",
                                    subtitle: "Very experienced",
                                    isSelected: experienceLevel == "expert",
                                    action: { experienceLevel = "expert" }
                                )
                            }
                        }

                        // Info Card
                        InfoCard()

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        savePreferences()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.pink)
                }
            }
        }
        .overlay(
            SaveConfirmationOverlay(isShowing: $showingSaveConfirmation)
        )
    }

    private func savePreferences() {
        // Preferences are automatically saved via @AppStorage to App Groups
        // Just show confirmation
        withAnimation {
            showingSaveConfirmation = true
        }

        // Hide after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showingSaveConfirmation = false
            }
        }

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

// MARK: - Supporting Views

struct PreferenceSection<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
                    .frame(width: 32, height: 32)
                    .background(iconColor.opacity(0.2))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Content
            content()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct PreferenceButton: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()

            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color.clear : Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.pink, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 24, height: 24)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.pink.opacity(0.15) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        isSelected ?
                            LinearGradient(
                                colors: [.pink, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                colors: [.white.opacity(0.1), .white.opacity(0.1)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InfoCard: View {
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "lightbulb.fill")
                .font(.title2)
                .foregroundColor(.yellow)

            VStack(alignment: .leading, spacing: 4) {
                Text("Your AI Coach Learns")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Text("These preferences help your AI dating coach provide more personalized suggestions that match your style and goals.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.yellow.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
    }
}

struct SaveConfirmationOverlay: View {
    @Binding var isShowing: Bool

    var body: some View {
        VStack {
            Spacer()

            if isShowing {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.green)

                    Text("Preferences saved!")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.9))
                        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.bottom, 40)
        .animation(.spring(), value: isShowing)
    }
}

// MARK: - Preview
struct PersonalizationView_Previews: PreviewProvider {
    static var previews: some View {
        PersonalizationView()
            .preferredColorScheme(.dark)
    }
}
