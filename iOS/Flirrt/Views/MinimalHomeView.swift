import SwiftUI

/// Minimal home view - All features happen in keyboard extension
/// Main app is just for setup and settings
struct MinimalHomeView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var showingSettings = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.black, Color.gray.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 40) {
                    Spacer()

                    // App Logo and Status
                    VStack(spacing: 20) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 100))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.pink, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .accessibilityLabel("Vibe8 AI logo")

                        Text("Vibe8 AI")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)

                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Keyboard Ready")
                                .font(.title3)
                                .foregroundColor(.green)
                        }
                        .accessibilityLabel("Keyboard status: Ready")
                    }

                    // Instructions
                    VStack(spacing: 20) {
                        Text("How to use:")
                            .font(.headline)
                            .foregroundColor(.white)

                        VStack(alignment: .leading, spacing: 16) {
                            InstructionRow(
                                number: "1",
                                text: "Add Vibe8 keyboard in iOS Settings",
                                icon: "keyboard"
                            )

                            InstructionRow(
                                number: "2",
                                text: "Take a screenshot of any dating profile",
                                icon: "camera.fill"
                            )

                            InstructionRow(
                                number: "3",
                                text: "Open Vibe8 keyboard for AI suggestions",
                                icon: "sparkles"
                            )
                        }
                    }
                    .padding(.horizontal, 30)

                    // Action Buttons
                    VStack(spacing: 16) {
                        Button(action: {
                            openIOSSettings()
                        }) {
                            HStack {
                                Image(systemName: "keyboard.badge.ellipsis")
                                    .font(.title3)
                                Text("Open iOS Settings")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                LinearGradient(
                                    colors: [Color.pink, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                        .accessibilityLabel("Open iOS Settings to add keyboard")

                        Button(action: {
                            showingSettings = true
                        }) {
                            HStack {
                                Image(systemName: "gearshape.fill")
                                    .font(.title3)
                                Text("App Settings")
                                    .font(.headline)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .accessibilityLabel("Open app settings")
                    }
                    .padding(.horizontal, 30)

                    Spacer()

                    // Version info
                    VStack(spacing: 8) {
                        if let user = authManager.currentUser {
                            Text("Signed in as \(user.email ?? "User")")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }

                        Text("Version 1.0.0")
                            .font(.caption2)
                            .foregroundColor(.gray.opacity(0.7))
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .preferredColorScheme(.dark)
    }

    private func openIOSSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Supporting Views

struct InstructionRow: View {
    let number: String
    let text: String
    let icon: String

    var body: some View {
        HStack(spacing: 16) {
            // Number circle
            ZStack {
                Circle()
                    .fill(Color.pink.opacity(0.2))
                    .frame(width: 32, height: 32)

                Text(number)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.pink)
            }

            // Text and icon
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(.gray)
                    .frame(width: 24)

                Text(text)
                    .font(.body)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(number): \(text)")
    }
}

// MARK: - Preview

struct MinimalHomeView_Previews: PreviewProvider {
    static var previews: some View {
        MinimalHomeView()
            .environmentObject(AuthManager())
    }
}
