import SwiftUI
import AuthenticationServices
import KeychainAccess

class AuthManager: NSObject, ObservableObject {
    @Published var isAuthenticated = false
    @Published var user: User?
    @Published var isLoading = false
    @Published var error: String?
    @Published var ageVerified = false

    private let keychain = Keychain(service: "com.flirrt.ai")
    private var apiClient: APIClient!

    var currentUser: User? {
        return user
    }

    @MainActor override init() {
        self.apiClient = APIClient()
        super.init()
        checkAuthStatus()
        checkAgeVerification()
    }

    func checkAuthStatus() {
        if let token = try? keychain.getString("jwt_token") {
            validateToken(token)
        }
    }

    private func checkAgeVerification() {
        ageVerified = UserDefaults.standard.bool(forKey: "age_verified")
    }

    func signInWithApple() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    func verifyAge(_ birthDate: Date) {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())

        if let age = ageComponents.year, age >= 18 {
            ageVerified = true
            saveAgeVerification()
        } else {
            error = "You must be 18 or older to use Flirrt"
            ageVerified = false
        }
    }

    private func validateToken(_ token: String) {
        Task {
            do {
                let response = try await apiClient.validateToken(token)
                if response.valid {
                    await MainActor.run {
                        self.isAuthenticated = true
                        self.user = response.user
                        self.updateSharedAuthenticationState(isAuthenticated: true, userId: response.user?.id)
                    }
                }
            } catch {
                try? keychain.remove("jwt_token")
            }
        }
    }

    private func saveAgeVerification() {
        UserDefaults.standard.set(true, forKey: "age_verified")
        if let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt.shared") {
            sharedDefaults.set(true, forKey: "age_verified")
        }
    }

    func logout() {
        try? keychain.remove("jwt_token")
        UserDefaults.standard.removeObject(forKey: "age_verified")
        if let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt.shared") {
            sharedDefaults.removeObject(forKey: "age_verified")
            sharedDefaults.removeObject(forKey: "user_authenticated")
            sharedDefaults.removeObject(forKey: "user_id")
        }
        isAuthenticated = false
        user = nil
        ageVerified = false
        updateSharedAuthenticationState(isAuthenticated: false, userId: nil)
    }

    private func updateSharedAuthenticationState(isAuthenticated: Bool, userId: String?) {
        if let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt.shared") {
            sharedDefaults.set(isAuthenticated, forKey: "user_authenticated")
            sharedDefaults.set(userId, forKey: "user_id")
            sharedDefaults.synchronize()
        }
    }
}

extension AuthManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }

        Task {
            do {
                let response = try await apiClient.authenticateWithApple(
                    userIdentifier: credential.user,
                    identityToken: credential.identityToken,
                    authorizationCode: credential.authorizationCode
                )

                try keychain.set(response.token, key: "jwt_token")

                await MainActor.run {
                    self.user = response.user
                    self.isAuthenticated = true
                    self.updateSharedAuthenticationState(isAuthenticated: true, userId: response.user.id)
                }
            } catch {
                await MainActor.run {
                    self.error = "Authentication failed: \(error.localizedDescription)"
                }
            }
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        self.error = "Sign in failed: \(error.localizedDescription)"
    }
}

extension AuthManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return UIWindow()
        }
        return window
    }
}

struct User: Codable, Identifiable, Sendable {
    let id: String
    let email: String?
    let fullName: String?
    let voiceId: String?
    let createdAt: Date
    let ageVerified: Bool
}