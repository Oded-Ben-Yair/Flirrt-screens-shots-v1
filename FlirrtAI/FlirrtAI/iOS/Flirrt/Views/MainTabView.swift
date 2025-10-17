import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var apiClient: APIClient
    @EnvironmentObject private var sharedDataManager: SharedDataManager
    @EnvironmentObject private var screenshotManager: ScreenshotDetectionManager

    @State private var selectedTab = 0
    @State private var showingVoiceRecording = false

    var body: some View {
        TabView(selection: $selectedTab) {
            // Home Tab
            HomeView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("Home")
                }
                .tag(0)
                .accessibilityLabel("Home tab")

            // History Tab
            HistoryView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "clock.fill" : "clock")
                    Text("History")
                }
                .tag(1)
                .accessibilityLabel("History tab")

            // Quick Action Tab (Center)
            QuickActionView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Create")
                }
                .tag(2)
                .accessibilityLabel("Quick action tab")

            // Settings Tab
            SettingsView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "gearshape.fill" : "gearshape")
                    Text("Settings")
                }
                .tag(3)
                .accessibilityLabel("Settings tab")

            // Profile Tab
            ProfileView()
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "person.fill" : "person")
                    Text("Profile")
                }
                .tag(4)
                .accessibilityLabel("Profile tab")
        }
        .accentColor(.pink)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingVoiceRecording) {
            VoiceRecordingView()
        }
        .onChange(of: selectedTab) { newTab in
            // Haptic feedback for tab selection
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
    }
}

// MARK: - Home View

struct HomeView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var sharedDataManager: SharedDataManager
    @State private var showingVoiceRecording = false
    @State private var showingScreenshotAnalysis = false
    @State private var showingFlirtGeneration = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Welcome Header
                    VStack(spacing: 8) {
                        Text("Welcome back!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        if let user = authManager.currentUser {
                            Text("Hey, \(user.fullName?.components(separatedBy: " ").first ?? "there")!")
                                .font(.title3)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.top)

                    // Quick Stats
                    HStack(spacing: 16) {
                        StatCard(
                            title: "Flirts Sent",
                            value: "24",
                            icon: "heart.fill",
                            color: .pink
                        )

                        StatCard(
                            title: "Screenshots",
                            value: "12",
                            icon: "camera.fill",
                            color: .blue
                        )

                        StatCard(
                            title: "Success Rate",
                            value: "78%",
                            icon: "chart.line.uptrend.xyaxis",
                            color: .green
                        )
                    }
                    .padding(.horizontal)

                    // Voice Status
                    VoiceStatusCard(
                        hasVoice: sharedDataManager.currentVoiceId != nil,
                        onCreateVoice: {
                            showingVoiceRecording = true
                        }
                    )
                    .padding(.horizontal)

                    // Quick Actions
                    VStack(spacing: 16) {
                        SectionHeader(title: "Quick Actions")

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            QuickActionCard(
                                icon: "camera.viewfinder",
                                title: "Analyze Screenshot",
                                description: "Get instant advice",
                                color: .blue
                            ) {
                                showingScreenshotAnalysis = true
                            }

                            QuickActionCard(
                                icon: "message.badge.waveform",
                                title: "Generate Flirt",
                                description: "AI conversation starter",
                                color: .purple
                            ) {
                                showingFlirtGeneration = true
                            }

                            QuickActionCard(
                                icon: "waveform.path.ecg",
                                title: "Voice Message",
                                description: "Send with your voice",
                                color: .orange,
                                isEnabled: sharedDataManager.currentVoiceId != nil
                            ) {
                                // TODO: Implement voice message creation
                            }

                            QuickActionCard(
                                icon: "sparkles",
                                title: "Magic Suggestions",
                                description: "Personalized tips",
                                color: .yellow
                            ) {
                                // TODO: Implement magic suggestions
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Recent Activity
                    VStack(spacing: 16) {
                        SectionHeader(title: "Recent Activity")

                        RecentActivityList()
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 100)
                }
            }
            .background(
                LinearGradient(
                    colors: [Color.black, Color.gray.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingVoiceRecording) {
            VoiceRecordingView()
        }
        .sheet(isPresented: $showingScreenshotAnalysis) {
            ScreenshotAnalysisView()
        }
        .sheet(isPresented: $showingFlirtGeneration) {
            PlaceholderView(title: "Flirt Generation", subtitle: "AI-powered conversation starters coming soon!")
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

struct VoiceStatusCard: View {
    let hasVoice: Bool
    let onCreateVoice: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: hasVoice ? "checkmark.circle.fill" : "waveform.circle")
                .font(.title)
                .foregroundColor(hasVoice ? .green : .gray)

            VStack(alignment: .leading, spacing: 4) {
                Text(hasVoice ? "Voice Clone Ready" : "Voice Clone Setup")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Text(hasVoice ? "Your AI voice is ready to use" : "Create your personal voice clone")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            Spacer()

            if !hasVoice {
                Button(action: onCreateVoice) {
                    Text("Setup")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.pink)
                        .cornerRadius(20)
                }
                .accessibilityLabel("Setup voice clone")
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let isEnabled: Bool
    let action: () -> Void

    init(icon: String, title: String, description: String, color: Color, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.description = description
        self.color = color
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(color)

                VStack(spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .padding()
            .background(Color.black.opacity(0.3))
            .cornerRadius(12)
            .opacity(isEnabled ? 1.0 : 0.6)
        }
        .disabled(!isEnabled)
        .accessibilityLabel("\(title): \(description)")
    }
}

struct SectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Spacer()
        }
    }
}

struct RecentActivityList: View {
    var body: some View {
        VStack(spacing: 12) {
            ForEach(mockRecentActivity, id: \.id) { activity in
                RecentActivityRow(activity: activity)
            }
        }
    }

    private var mockRecentActivity: [RecentActivity] = [
        RecentActivity(
            id: UUID(),
            type: .screenshot,
            title: "Screenshot Analysis",
            description: "Dating app conversation",
            timestamp: Date().addingTimeInterval(-3600),
            icon: "camera.fill",
            color: .blue
        ),
        RecentActivity(
            id: UUID(),
            type: .flirt,
            title: "Generated Flirt",
            description: "\"Are you a magician?...\"",
            timestamp: Date().addingTimeInterval(-7200),
            icon: "heart.fill",
            color: .pink
        ),
        RecentActivity(
            id: UUID(),
            type: .voice,
            title: "Voice Message",
            description: "Sent to Sarah",
            timestamp: Date().addingTimeInterval(-10800),
            icon: "waveform",
            color: .purple
        )
    ]
}

struct RecentActivityRow: View {
    let activity: RecentActivity

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: activity.icon)
                .font(.title3)
                .foregroundColor(activity.color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                Text(activity.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }

            Spacer()

            Text(timeAgoString(from: activity.timestamp))
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }

    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - History View

struct HistoryView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Coming Soon")
                        .font(.title)
                        .foregroundColor(.white)

                    Text("Your conversation history and analytics will appear here")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [Color.black, Color.gray.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Quick Action View

struct QuickActionView: View {
    @State private var showingActionSheet = false

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Quick Actions")
                    .font(.title)
                    .foregroundColor(.white)

                Button("Show Actions") {
                    showingActionSheet = true
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.pink)
                .cornerRadius(12)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(
                    colors: [Color.black, Color.gray.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationBarHidden(true)
        }
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text("Quick Actions"),
                buttons: [
                    .default(Text("Analyze Screenshot")) { },
                    .default(Text("Generate Flirt")) { },
                    .default(Text("Create Voice Message")) { },
                    .cancel()
                ]
            )
        }
    }
}

// MARK: - Profile View

struct ProfileView: View {
    @EnvironmentObject private var authManager: AuthManager

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        Circle()
                            .fill(Color.pink.opacity(0.2))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.title)
                                    .foregroundColor(.pink)
                            )

                        if let user = authManager.currentUser {
                            Text(user.fullName ?? "User")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)

                            Text(user.email ?? "")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }

                    // Profile Stats
                    HStack(spacing: 16) {
                        ProfileStatCard(title: "Flirts", value: "24")
                        ProfileStatCard(title: "Success", value: "78%")
                        ProfileStatCard(title: "Streak", value: "5")
                    }
                    .padding(.horizontal)

                    // Profile Actions
                    VStack(spacing: 12) {
                        ProfileActionRow(icon: "person.crop.circle", title: "Edit Profile", action: {})
                        ProfileActionRow(icon: "bell", title: "Notifications", action: {})
                        ProfileActionRow(icon: "star", title: "Premium", action: {})
                        ProfileActionRow(icon: "questionmark.circle", title: "Help & Support", action: {})

                        Divider()
                            .background(Color.gray.opacity(0.3))

                        ProfileActionRow(
                            icon: "rectangle.portrait.and.arrow.right",
                            title: "Logout",
                            color: .red
                        ) {
                            authManager.logout()
                        }
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 100)
                }
                .padding(.top)
            }
            .background(
                LinearGradient(
                    colors: [Color.black, Color.gray.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct ProfileStatCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
}

struct ProfileActionRow: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    init(icon: String, title: String, color: Color = .white, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.color = color
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 24)

                Text(title)
                    .font(.body)
                    .foregroundColor(color)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.black.opacity(0.3))
            .cornerRadius(12)
        }
    }
}

// MARK: - Data Models

struct RecentActivity: Identifiable {
    let id: UUID
    let type: ActivityType
    let title: String
    let description: String
    let timestamp: Date
    let icon: String
    let color: Color

    enum ActivityType {
        case screenshot, flirt, voice, analysis
    }
}

// MARK: - Placeholder Views

struct PlaceholderView: View {
    let title: String
    let subtitle: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundColor(.pink)
                
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(
                    colors: [Color.black, Color.gray.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Preview
struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AuthManager())
            .environmentObject(APIClient())
            .environmentObject(SharedDataManager())
    }
}