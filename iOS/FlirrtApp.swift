import SwiftUI

@main
struct Vibe8App: App {
    // Initialize your managers here
    @StateObject private var authManager = AuthManager()
    @StateObject private var apiClient = APIClient()
    @StateObject private var sharedDataManager = SharedDataManager()
    
    var body: some Scene {
        WindowGroup {
            // Choose which view should be your main entry point
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
        if authManager.isAuthenticated {
            // Show main app interface when authenticated
            MainTabView()
        } else {
            // Show login/onboarding when not authenticated
            ContentView()
        }
    }
}