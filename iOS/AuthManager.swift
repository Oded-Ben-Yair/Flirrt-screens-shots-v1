import SwiftUI
import AuthenticationServices

// Basic AuthManager - you can expand this based on your needs
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: String?
    @Published var currentUser: User?
    @Published var ageVerified = false
    
    func signInWithApple() {
        isLoading = true
        error = nil
        
        // For now, simulate successful authentication
        // In a real app, you'd implement actual Apple Sign In
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isAuthenticated = true
            self.isLoading = false
            self.currentUser = User(fullName: "Test User", email: "test@example.com")
        }
    }
    
    func logout() {
        isAuthenticated = false
        currentUser = nil
        error = nil
        ageVerified = false
    }

    func verifyAge(_ birthDate: Date) {
        let age = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
        if age >= 18 {
            ageVerified = true
        } else {
            error = "You must be 18 or older to use Vibe8"
            logout()
        }
    }
}

// Basic User model
struct User {
    let fullName: String?
    let email: String?
}