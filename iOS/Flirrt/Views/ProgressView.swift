import SwiftUI

/// CP-5: Progress View for Gamification
/// Displays user level, achievements, and stats
struct ProgressView: View {

    @StateObject private var viewModel = ProgressViewModel()
    @Environment(\.presentationMode) var presentationMode

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
                    VStack(spacing: 24) {
                        // Level Card
                        LevelCard(levelInfo: viewModel.levelInfo)

                        // Stats Grid
                        StatsGrid(stats: viewModel.stats)

                        // Achievements Section
                        AchievementsSection(
                            unlockedAchievements: viewModel.unlockedAchievements,
                            lockedAchievements: viewModel.lockedAchievements
                        )

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.pink)
                }
            }
            .onAppear {
                viewModel.loadProgress()
            }
            .overlay(
                Group {
                    if viewModel.isLoading {
                        LoadingOverlay()
                    }
                }
            )
        }
    }
}

// MARK: - Level Card

struct LevelCard: View {
    let levelInfo: LevelInfo

    var body: some View {
        VStack(spacing: 20) {
            // Level Badge
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.pink, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: .pink.opacity(0.5), radius: 20, y: 10)

                VStack(spacing: 4) {
                    Text("\(levelInfo.level)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("LEVEL")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.8))
                }
            }

            // Level Title
            Text(levelInfo.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            // Progress Bar
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        Capsule()
                            .fill(Color.white.opacity(0.1))

                        // Progress
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.pink, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(levelInfo.percentageToNext) / 100)
                    }
                }
                .frame(height: 12)

                HStack {
                    Text("\(levelInfo.progress) / \(levelInfo.nextLevelAt) successes")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(levelInfo.percentageToNext)%")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.pink)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Stats Grid

struct StatsGrid: View {
    let stats: UserStats

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Stats")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 4)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    icon: "message.fill",
                    value: "\(stats.messagesSent)",
                    label: "Messages",
                    color: .blue
                )

                StatCard(
                    icon: "checkmark.circle.fill",
                    value: "\(stats.successfulConversations)",
                    label: "Successes",
                    color: .green
                )

                StatCard(
                    icon: "person.crop.circle",
                    value: "\(stats.profilesAnalyzed)",
                    label: "Profiles",
                    color: .orange
                )

                StatCard(
                    icon: "arrow.clockwise",
                    value: "\(stats.refreshesUsed)",
                    label: "Refreshes",
                    color: .purple
                )

                StatCard(
                    icon: "flame.fill",
                    value: "\(stats.dailyStreak)",
                    label: "Day Streak",
                    color: .red
                )

                StatCard(
                    icon: "star.fill",
                    value: "\(stats.averageConfidence)%",
                    label: "Avg Confidence",
                    color: .yellow
                )
            }
        }
    }
}

struct StatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.2))
                .clipShape(Circle())

            VStack(spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
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

// MARK: - Achievements Section

struct AchievementsSection: View {
    let unlockedAchievements: [Achievement]
    let lockedAchievements: [Achievement]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Achievements")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Spacer()

                Text("\(unlockedAchievements.count) / \(unlockedAchievements.count + lockedAchievements.count)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)

            // Unlocked Achievements
            if !unlockedAchievements.isEmpty {
                VStack(spacing: 12) {
                    ForEach(unlockedAchievements) { achievement in
                        AchievementCard(achievement: achievement, isUnlocked: true)
                    }
                }
            }

            // Locked Achievements
            if !lockedAchievements.isEmpty {
                VStack(spacing: 12) {
                    ForEach(lockedAchievements.prefix(5)) { achievement in
                        AchievementCard(achievement: achievement, isUnlocked: false)
                    }
                }
            }
        }
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    let isUnlocked: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(isUnlocked ?
                          LinearGradient(
                            colors: [.pink, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          ) :
                          LinearGradient(
                            colors: [.gray.opacity(0.3), .gray.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          )
                    )
                    .frame(width: 60, height: 60)

                Text(achievement.icon)
                    .font(.title)
                    .opacity(isUnlocked ? 1.0 : 0.3)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(isUnlocked ? .white : .secondary)

                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                if !isUnlocked {
                    // Progress
                    Text("\(achievement.progress) / \(achievement.target)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Checkmark for unlocked
            if isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.green)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(isUnlocked ? 0.08 : 0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    isUnlocked ?
                        Color.white.opacity(0.2) :
                        Color.white.opacity(0.05),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Loading Overlay

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)

                Text("Loading progress...")
                    .font(.subheadline)
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.black.opacity(0.9))
            )
        }
    }
}

// MARK: - View Model

@MainActor
class ProgressViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var levelInfo: LevelInfo = LevelInfo.placeholder
    @Published var stats: UserStats = UserStats.placeholder
    @Published var unlockedAchievements: [Achievement] = []
    @Published var lockedAchievements: [Achievement] = []

    func loadProgress() {
        isLoading = true

        Task {
            do {
                // TODO: Call backend API /api/v1/flirts/progress
                // For now, use mock data
                try await Task.sleep(nanoseconds: 1_000_000_000)

                levelInfo = LevelInfo(
                    level: 3,
                    title: "Learner",
                    progress: 12,
                    nextLevelAt: 15,
                    percentageToNext: 80
                )

                stats = UserStats(
                    messagesSent: 47,
                    successfulConversations: 12,
                    profilesAnalyzed: 23,
                    refreshesUsed: 8,
                    dailyStreak: 5,
                    averageConfidence: 82
                )

                unlockedAchievements = Achievement.mockUnlocked
                lockedAchievements = Achievement.mockLocked

                isLoading = false
            } catch {
                print("Failed to load progress: \(error)")
                isLoading = false
            }
        }
    }
}

// MARK: - Data Models

struct LevelInfo {
    let level: Int
    let title: String
    let progress: Int
    let nextLevelAt: Int
    let percentageToNext: Int

    static let placeholder = LevelInfo(
        level: 1,
        title: "Beginner",
        progress: 0,
        nextLevelAt: 5,
        percentageToNext: 0
    )
}

struct UserStats {
    let messagesSent: Int
    let successfulConversations: Int
    let profilesAnalyzed: Int
    let refreshesUsed: Int
    let dailyStreak: Int
    let averageConfidence: Int

    static let placeholder = UserStats(
        messagesSent: 0,
        successfulConversations: 0,
        profilesAnalyzed: 0,
        refreshesUsed: 0,
        dailyStreak: 0,
        averageConfidence: 0
    )
}

struct Achievement: Identifiable {
    let id: String
    let icon: String
    let title: String
    let description: String
    let progress: Int
    let target: Int

    static let mockUnlocked: [Achievement] = [
        Achievement(
            id: "first_message",
            icon: "❄️",
            title: "Ice Breaker",
            description: "Send your first flirt suggestion",
            progress: 1,
            target: 1
        ),
        Achievement(
            id: "ten_messages",
            icon: "💬",
            title: "Conversation Starter",
            description: "Send 10 flirt suggestions",
            progress: 10,
            target: 10
        ),
        Achievement(
            id: "first_success",
            icon: "✨",
            title: "First Connection",
            description: "Have your first successful conversation",
            progress: 1,
            target: 1
        )
    ]

    static let mockLocked: [Achievement] = [
        Achievement(
            id: "five_successes",
            icon: "🎯",
            title: "Confident Communicator",
            description: "Achieve 5 successful conversations",
            progress: 2,
            target: 5
        ),
        Achievement(
            id: "profile_analyzer",
            icon: "🔍",
            title: "Profile Expert",
            description: "Analyze 20 dating profiles",
            progress: 8,
            target: 20
        ),
        Achievement(
            id: "refresh_enthusiast",
            icon: "🔄",
            title: "Perfectionist",
            description: "Use the refresh button 10 times",
            progress: 3,
            target: 10
        ),
        Achievement(
            id: "week_streak",
            icon: "🔥",
            title: "Committed",
            description: "Use Vibe8 for 7 days in a row",
            progress: 2,
            target: 7
        ),
        Achievement(
            id: "expert_level",
            icon: "👑",
            title: "Dating Expert",
            description: "Reach Expert level (Level 11+)",
            progress: 3,
            target: 11
        )
    ]
}

// MARK: - Preview
struct ProgressView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressView()
            .preferredColorScheme(.dark)
    }
}
