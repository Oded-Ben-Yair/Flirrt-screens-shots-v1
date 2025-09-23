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
        // In a real app, you'd use ASAuthorizationAppleIDProvider
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