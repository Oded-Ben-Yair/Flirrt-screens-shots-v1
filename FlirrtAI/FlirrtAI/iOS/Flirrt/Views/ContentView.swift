import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var apiClient: APIClient
    @EnvironmentObject private var sharedDataManager: SharedDataManager
    @EnvironmentObject private var screenshotManager: ScreenshotDetectionManager

    @State private var showingVoiceRecording = false
    @State private var showingScreenshotAnalysis = false

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // App Header
                VStack(spacing: 16) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.pink)

                    Text("Flirrt AI")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Your Personal Flirting Assistant")
                        .font(.headline)
                        .foregroundColor(.gray)
                }

                Spacer()

                // Authentication Section
                if authManager.isAuthenticated {
                    authenticatedContent
                } else {
                    unauthenticatedContent
                }

                Spacer()
            }
            .padding()
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
        .sheet(isPresented: $showingVoiceRecording) {
            VoiceRecordingView()
        }
        .sheet(isPresented: $showingScreenshotAnalysis) {
            ScreenshotAnalysisView()
        }
    }

    // MARK: - Authenticated Content
    private var authenticatedContent: some View {
        VStack(spacing: 20) {
            // Welcome Message
            VStack(spacing: 8) {
                Text("Welcome back!")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                if let user = authManager.currentUser {
                    Text(user.fullName ?? user.email ?? "User")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }

            // Voice Recording Section
            VStack(spacing: 16) {
                Text("Voice Clone Setup")
                    .font(.headline)
                    .foregroundColor(.white)

                if sharedDataManager.currentVoiceId != nil {
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.green)

                        Text("Voice clone ready!")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                } else {
                    Button(action: {
                        showingVoiceRecording = true
                    }) {
                        HStack {
                            Image(systemName: "waveform.circle.fill")
                                .font(.title2)

                            Text("Create Voice Clone")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [Color.pink, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                }
            }

            // Main Features
            VStack(spacing: 12) {
                FeatureButton(
                    icon: "camera.fill",
                    title: "Analyze Screenshot",
                    description: "Get instant flirting advice"
                ) {
                    showingScreenshotAnalysis = true
                }

                FeatureButton(
                    icon: "message.fill",
                    title: "Generate Flirts",
                    description: "AI-powered conversation starters"
                ) {
                    // TODO: Implement flirt generation
                }

                FeatureButton(
                    icon: "speaker.wave.3.fill",
                    title: "Voice Messages",
                    description: "Send flirts with your voice",
                    isEnabled: sharedDataManager.currentVoiceId != nil
                ) {
                    // TODO: Implement voice message sending
                }
            }

            // Logout Button
            Button(action: {
                authManager.logout()
            }) {
                Text("Logout")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
            .padding(.top)
        }
    }

    // MARK: - Unauthenticated Content
    private var unauthenticatedContent: some View {
        VStack(spacing: 20) {
            Text("Get ready to level up your dating game!")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                FeaturePreview(
                    icon: "brain.head.profile",
                    title: "AI-Powered Analysis",
                    description: "Smart screenshot analysis"
                )

                FeaturePreview(
                    icon: "waveform",
                    title: "Voice Cloning",
                    description: "Your personal voice assistant"
                )

                FeaturePreview(
                    icon: "heart.text.square",
                    title: "Perfect Flirts",
                    description: "Personalized conversation starters"
                )
            }

            Button(action: {
                authManager.signInWithApple()
            }) {
                HStack {
                    Image(systemName: "applelogo")
                        .font(.title2)

                    Text("Continue with Apple")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.black)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
            }
            .disabled(authManager.isLoading)

            if let error = authManager.error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Supporting Views

struct FeatureButton: View {
    let icon: String
    let title: String
    let description: String
    let isEnabled: Bool
    let action: () -> Void

    init(icon: String, title: String, description: String, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.description = description
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.pink)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
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
            .background(Color.black.opacity(0.3))
            .cornerRadius(12)
            .opacity(isEnabled ? 1.0 : 0.6)
        }
        .disabled(!isEnabled)
    }
}

struct FeaturePreview: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.pink)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding()
        .background(Color.black.opacity(0.2))
        .cornerRadius(12)
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthManager())
            .environmentObject(APIClient())
            .environmentObject(SharedDataManager())
    }
}