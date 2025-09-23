import SwiftUI

@main
struct FlirrtApp: App {
    // Initialize your managers here
    @StateObject private var authManager = AuthManager()
    @StateObject private var apiClient = APIClient()
    @StateObject private var sharedDataManager = SharedDataManager()
    
    var body: some Scene {
        WindowGroup {
            // App coordinator to handle navigation flow
            AppCoordinator()
                .environmentObject(authManager)
                .environmentObject(apiClient)
                .environmentObject(sharedDataManager)
        }
    }
}

// App Coordinator to handle navigation flow
struct AppCoordinator: View {
    @EnvironmentObject private var authManager: AuthManager
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                // Show main app interface when authenticated
                MainTabView()
            } else {
                // Show login/onboarding when not authenticated
                ContentView()
            }
        }
        .preferredColorScheme(.dark)
    }
}