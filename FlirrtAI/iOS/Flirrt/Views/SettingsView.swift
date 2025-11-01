import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var showingDataDeletionAlert = false
    @State private var showingLogoutAlert = false
    @State private var showingTermsAndPrivacy = false
    @State private var showingDataExport = false
    @State private var notificationsEnabled = true
    @State private var voiceProcessingEnabled = true
    @State private var analyticsEnabled = false
    @State private var darkModeEnabled = true
    @State private var gamificationEnabled = true // Phase 3: Gamification toggle

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Privacy & Data Section
                    SettingsSection(title: "Privacy & Data") {
                        VStack(spacing: 0) {
                            SettingsToggleRow(
                                icon: "bell.fill",
                                title: "Push Notifications",
                                description: "Receive app notifications",
                                isOn: $notificationsEnabled,
                                color: .blue
                            )

                            SettingsDivider()

                            SettingsToggleRow(
                                icon: "waveform",
                                title: "Voice Processing",
                                description: "Allow voice analysis and cloning",
                                isOn: $voiceProcessingEnabled,
                                color: .purple
                            )

                            SettingsDivider()

                            SettingsToggleRow(
                                icon: "chart.bar.fill",
                                title: "Analytics",
                                description: "Help improve the app with usage data",
                                isOn: $analyticsEnabled,
                                color: .green
                            )
                        }
                    }

                    // Data Management Section
                    SettingsSection(title: "Data Management") {
                        VStack(spacing: 0) {
                            SettingsActionRow(
                                icon: "square.and.arrow.up",
                                title: "Export My Data",
                                description: "Download a copy of your data",
                                color: .blue
                            ) {
                                showingDataExport = true
                            }

                            SettingsDivider()

                            SettingsActionRow(
                                icon: "trash.fill",
                                title: "Delete All Data",
                                description: "Permanently remove all your data",
                                color: .red
                            ) {
                                showingDataDeletionAlert = true
                            }
                        }
                    }

                    // Consent Management Section
                    SettingsSection(title: "Consent Management") {
                        VStack(spacing: 0) {
                            ConsentStatusCard()

                            SettingsDivider()

                            SettingsActionRow(
                                icon: "doc.text",
                                title: "Terms & Privacy Policy",
                                description: "Review our terms and privacy policy",
                                color: .gray
                            ) {
                                showingTermsAndPrivacy = true
                            }

                            SettingsDivider()

                            SettingsActionRow(
                                icon: "checkmark.shield",
                                title: "Manage Consent",
                                description: "Update your consent preferences",
                                color: .green
                            ) {
                                // TODO: Show consent management
                            }
                        }
                    }

                    // App Preferences Section
                    SettingsSection(title: "App Preferences") {
                        VStack(spacing: 0) {
                            SettingsToggleRow(
                                icon: "moon.fill",
                                title: "Dark Mode",
                                description: "Use dark theme",
                                isOn: $darkModeEnabled,
                                color: .indigo
                            )

                            SettingsDivider()

                            SettingsToggleRow(
                                icon: "gamecontroller.fill",
                                title: "Gamification",
                                description: "Points, streaks, and scroll-to-reveal mechanics",
                                isOn: $gamificationEnabled,
                                color: .orange
                            )
                            .onChange(of: gamificationEnabled) { _, newValue in
                                UserDefaults.standard.set(newValue, forKey: "gamification.enabled")
                            }

                            SettingsDivider()

                            SettingsActionRow(
                                icon: "star.fill",
                                title: "Premium Features",
                                description: "Upgrade to unlock more features",
                                color: .yellow
                            ) {
                                // TODO: Show premium upgrade
                            }
                        }
                    }

                    // Support Section
                    SettingsSection(title: "Support") {
                        VStack(spacing: 0) {
                            SettingsActionRow(
                                icon: "questionmark.circle.fill",
                                title: "Help & FAQ",
                                description: "Get help and find answers",
                                color: .blue
                            ) {
                                // TODO: Show help
                            }

                            SettingsDivider()

                            SettingsActionRow(
                                icon: "envelope.fill",
                                title: "Contact Support",
                                description: "Get in touch with our team",
                                color: .green
                            ) {
                                sendSupportEmail()
                            }

                            SettingsDivider()

                            SettingsActionRow(
                                icon: "star.fill",
                                title: "Rate the App",
                                description: "Leave a review on the App Store",
                                color: .orange
                            ) {
                                requestAppReview()
                            }
                        }
                    }

                    // Account Section
                    SettingsSection(title: "Account") {
                        VStack(spacing: 0) {
                            if let user = authManager.currentUser {
                                AccountInfoCard(user: user)

                                SettingsDivider()
                            }

                            SettingsActionRow(
                                icon: "rectangle.portrait.and.arrow.right",
                                title: "Sign Out",
                                description: "Sign out of your account",
                                color: .red
                            ) {
                                showingLogoutAlert = true
                            }
                        }
                    }

                    // App Info
                    VStack(spacing: 8) {
                        Text("Flirrt AI")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Text("Version 1.0.0")
                            .font(.caption2)
                            .foregroundColor(.gray.opacity(0.7))
                    }
                    .padding(.top, 20)

                    Spacer(minLength: 100)
                }
                .padding(.horizontal)
                .padding(.top)
            }
            .background(
                LinearGradient(
                    colors: [Color.black, Color.gray.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                // Load gamification setting
                gamificationEnabled = UserDefaults.standard.bool(forKey: "gamification.enabled")
                // Default to true if not set
                if !UserDefaults.standard.bool(forKey: "gamification.settingInitialized") {
                    gamificationEnabled = true
                    UserDefaults.standard.set(true, forKey: "gamification.enabled")
                    UserDefaults.standard.set(true, forKey: "gamification.settingInitialized")
                }
            }
        }
        .alert("Delete All Data", isPresented: $showingDataDeletionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAllUserData()
            }
        } message: {
            Text("This action cannot be undone. All your data, including voice recordings, conversation history, and preferences will be permanently deleted.")
        }
        .alert("Sign Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authManager.logout()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .sheet(isPresented: $showingTermsAndPrivacy) {
            TermsAndPrivacyView(showingTerms: .constant(true), showingPrivacy: .constant(false))
        }
        .sheet(isPresented: $showingDataExport) {
            DataExportView(isPresented: $showingDataExport)
        }
        .preferredColorScheme(darkModeEnabled ? .dark : .light)
    }

    private func deleteAllUserData() {
        // TODO: Implement data deletion
        // This should call the API to delete all user data
        Task {
            do {
                // Call API to delete data
                // await apiClient.deleteAllUserData()

                // Clear local data
                UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKeys.onboardingComplete)
                UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKeys.ageVerified)

                // Sign out
                authManager.logout()
            } catch {
                // Handle error
                print("Failed to delete user data: \(error)")
            }
        }
    }

    private func sendSupportEmail() {
        if let url = URL(string: "mailto:support@flirrt.ai?subject=Flirrt%20AI%20Support") {
            UIApplication.shared.open(url)
        }
    }

    private func requestAppReview() {
        if let url = URL(string: "https://apps.apple.com/app/id123456789?action=write-review") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Supporting Views

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                content
            }
            .background(Color.black.opacity(0.3))
            .cornerRadius(12)
        }
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    let description: String
    @Binding var isOn: Bool
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(.pink)
                .accessibilityLabel(title)
        }
        .padding()
    }
}

struct SettingsActionRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
        }
        .accessibilityLabel("\(title): \(description)")
    }
}

struct SettingsDivider: View {
    var body: some View {
        Divider()
            .background(Color.gray.opacity(0.3))
            .padding(.leading, 56)
    }
}

struct ConsentStatusCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.shield.fill")
                    .font(.title3)
                    .foregroundColor(.green)

                Text("Consent Status")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                ConsentItem(title: "Terms of Service", isConsented: true)
                ConsentItem(title: "Privacy Policy", isConsented: true)
                ConsentItem(title: "Data Processing", isConsented: true)
                ConsentItem(title: "Voice Analysis", isConsented: true)
                ConsentItem(title: "Analytics", isConsented: false)
            }
        }
        .padding()
    }
}

struct ConsentItem: View {
    let title: String
    let isConsented: Bool

    var body: some View {
        HStack {
            Image(systemName: isConsented ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.caption)
                .foregroundColor(isConsented ? .green : .red)

            Text(title)
                .font(.caption)
                .foregroundColor(.gray)

            Spacer()
        }
    }
}

struct AccountInfoCard: View {
    let user: User

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title3)
                    .foregroundColor(.blue)

                Text("Account Information")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                if let fullName = user.fullName {
                    AccountInfoRow(label: "Name", value: fullName)
                }

                if let email = user.email {
                    AccountInfoRow(label: "Email", value: email)
                }

                AccountInfoRow(label: "Member since", value: formatDate(user.createdAt))
                AccountInfoRow(label: "Age Verified", value: user.ageVerified ? "Yes" : "No")

                if user.voiceId != nil {
                    AccountInfoRow(label: "Voice Clone", value: "Active")
                }
            }
        }
        .padding()
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct AccountInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)

            Spacer()

            Text(value)
                .font(.caption)
                .foregroundColor(.white)
        }
    }
}

struct DataExportView: View {
    @Binding var isPresented: Bool
    @State private var isExporting = false
    @State private var exportComplete = false

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 16) {
                    Image(systemName: "square.and.arrow.up.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    Text("Export Your Data")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Download a copy of all your data including conversations, voice recordings, and preferences.")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                if exportComplete {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.green)

                        Text("Export Complete!")
                            .font(.headline)
                            .foregroundColor(.green)

                        Text("Your data has been prepared and will be sent to your email address.")
                            .font(.body)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                } else {
                    VStack(spacing: 16) {
                        Text("What's included:")
                            .font(.headline)
                            .foregroundColor(.white)

                        VStack(alignment: .leading, spacing: 8) {
                            ExportItem(text: "Conversation history and analysis")
                            ExportItem(text: "Voice recordings and clones")
                            ExportItem(text: "App preferences and settings")
                            ExportItem(text: "Usage statistics")
                        }
                    }

                    if isExporting {
                        VStack(spacing: 16) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                .scaleEffect(1.5)

                            Text("Preparing your data...")
                                .font(.body)
                                .foregroundColor(.gray)
                        }
                    } else {
                        Button(action: {
                            startExport()
                        }) {
                            Text("Start Export")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                }

                Spacer()
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.black, Color.gray.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .disabled(isExporting)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func startExport() {
        isExporting = true

        // Simulate export process
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            isExporting = false
            exportComplete = true
        }

        // TODO: Implement actual data export
        // Task {
        //     do {
        //         try await apiClient.exportUserData()
        //         await MainActor.run {
        //             isExporting = false
        //             exportComplete = true
        //         }
        //     } catch {
        //         await MainActor.run {
        //             isExporting = false
        //             // Show error
        //         }
        //     }
        // }
    }
}

struct ExportItem: View {
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundColor(.green)

            Text(text)
                .font(.body)
                .foregroundColor(.white)

            Spacer()
        }
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(AuthManager())
    }
}