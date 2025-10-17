import SwiftUI
import AuthenticationServices

// Authentication Manager
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: String?
    @Published var currentUser: User?
    
    init() {
        // Check if user was previously authenticated
        checkAuthenticationStatus()
    }
    
    func signInWithApple() {
        isLoading = true
        error = nil
        
        // Simulate Apple Sign In for testing
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isAuthenticated = true
            self.isLoading = false
            self.currentUser = User(
                id: "test_user_123",
                fullName: "Test User", 
                email: "test@example.com"
            )
            
            // Save authentication state
            UserDefaults.standard.set(true, forKey: "isAuthenticated")
        }
    }
    
    func logout() {
        isAuthenticated = false
        currentUser = nil
        error = nil
        
        // Clear stored authentication
        UserDefaults.standard.removeObject(forKey: "isAuthenticated")
    }
    
    private func checkAuthenticationStatus() {
        // Check if user was previously signed in
        let wasAuthenticated = UserDefaults.standard.bool(forKey: "isAuthenticated")
        if wasAuthenticated {
            self.isAuthenticated = true
            self.currentUser = User(
                id: "test_user_123",
                fullName: "Test User",
                email: "test@example.com"
            )
        }
    }
}

// User model
struct User: Identifiable, Codable {
    let id: String
    let fullName: String?
    let email: String?
}

// API Client for handling network requests
class APIClient: ObservableObject {
    @Published var isLoading = false
    @Published var error: String?
    
    // Placeholder methods for your app's functionality
    func analyzeScreenshot(_ image: UIImage) async throws {
        // Implement screenshot analysis API call
        isLoading = true
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 second delay for demo
        isLoading = false
    }
    
    func generateFlirt(context: String) async throws -> String {
        // Implement flirt generation API call
        isLoading = true
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 second delay for demo
        isLoading = false
        return "Hey! Are you a magician? Because every time I look at you, everyone else disappears! ✨"
    }
}

// Shared Data Manager for app-wide state
class SharedDataManager: ObservableObject {
    @Published var currentVoiceId: String?
    @Published var userPreferences: [String: Any] = [:]
    
    init() {
        loadPersistedData()
    }
    
    func setVoiceId(_ id: String) {
        currentVoiceId = id
        UserDefaults.standard.set(id, forKey: "currentVoiceId")
    }
    
    func clearVoiceData() {
        currentVoiceId = nil
        UserDefaults.standard.removeObject(forKey: "currentVoiceId")
    }
    
    private func loadPersistedData() {
        currentVoiceId = UserDefaults.standard.string(forKey: "currentVoiceId")
    }
}