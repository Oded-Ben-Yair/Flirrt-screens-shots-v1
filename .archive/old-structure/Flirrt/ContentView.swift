import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authManager: AuthManager

    var body: some View {
        if authManager.isAuthenticated {
            MainTabView()
        } else {
            LoginView()
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "heart.fill")
                    Text("Vibe8")
                }

            VoiceRecordingView()
                .tabItem {
                    Image(systemName: "mic.fill")
                    Text("Voice")
                }

            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .accentColor(.pink)
    }
}

struct HomeView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Welcome to Vibe8 AI")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Your AI-powered dating conversation assistant")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Spacer()
            }
            .padding()
            .navigationTitle("Vibe8")
        }
    }
}

struct LoginView: View {
    @EnvironmentObject private var authManager: AuthManager

    var body: some View {
        VStack(spacing: 30) {
            Text("Welcome to Vibe8 AI")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Sign in to get started with AI-powered conversation assistance")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Button("Sign in with Apple") {
                authManager.signInWithApple()
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.roundedRectangle)

            Spacer()
        }
        .padding()
    }
}

struct VoiceRecordingView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Voice Recording")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Record your voice for AI cloning")
                    .foregroundColor(.secondary)

                Spacer()
            }
            .padding()
            .navigationTitle("Voice")
        }
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Spacer()
            }
            .padding()
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Supporting Classes
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false

    func signInWithApple() {
        // Apple Sign In implementation
        isAuthenticated = true
    }
}

class APIClient: ObservableObject {
    // API client implementation
}

class SharedDataManager: ObservableObject {
    // Shared data management
}

struct AppCoordinator: View {
    var body: some View {
        ContentView()
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
}