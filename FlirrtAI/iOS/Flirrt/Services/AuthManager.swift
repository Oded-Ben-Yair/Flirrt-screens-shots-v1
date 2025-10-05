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
    private let apiClient = APIClient()

    var currentUser: User? {
        return user
    }

    override init() {
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
        ageVerified = UserDefaults.standard.bool(forKey: AppConstants.UserDefaultsKeys.ageVerified)
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
                    }
                }
            } catch {
                try? keychain.remove("jwt_token")
            }
        }
    }

    private func saveAgeVerification() {
        UserDefaults.standard.set(true, forKey: AppConstants.UserDefaultsKeys.ageVerified)
        if let sharedDefaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier) {
            sharedDefaults.set(true, forKey: AppConstants.UserDefaultsKeys.ageVerified)
        }
    }

    func logout() {
        try? keychain.remove("jwt_token")
        UserDefaults.standard.removeObject(forKey: AppConstants.UserDefaultsKeys.ageVerified)
        if let sharedDefaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier) {
            sharedDefaults.removeObject(forKey: AppConstants.UserDefaultsKeys.ageVerified)
        }
        isAuthenticated = false
        user = nil
        ageVerified = false
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
        guard let window = UIApplication.shared.windows.first else {
            return UIWindow()
        }
        return window
    }
}

struct User: Codable, Identifiable {
    let id: String
    let email: String?
    let fullName: String?
    let voiceId: String?
    let createdAt: Date
    let ageVerified: Bool
}