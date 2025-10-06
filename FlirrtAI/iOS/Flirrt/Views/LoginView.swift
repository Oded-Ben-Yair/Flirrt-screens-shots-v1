import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var showingAgeVerification = false
    @State private var birthDate = Date()
    @State private var agreedToTerms = false
    @State private var showingTerms = false
    @State private var showingPrivacyPolicy = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.black, Color.gray.opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 40) {
                    Spacer(minLength: 60)

                    // App Logo and Title
                    VStack(spacing: 20) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 100))
                            .foregroundStyle(.pink, .purple)
                            .accessibilityLabel("Flirrt AI logo")

                        VStack(spacing: 8) {
                            Text("Flirrt AI")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)

                            Text("Your Personal Flirting Assistant")
                                .font(.title3)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                    }

                    // Features Preview
                    VStack(spacing: 16) {
                        FeatureHighlight(
                            icon: "brain.head.profile",
                            title: "AI-Powered Analysis",
                            description: "Get instant advice on your conversations"
                        )

                        FeatureHighlight(
                            icon: "waveform",
                            title: "Voice Cloning",
                            description: "Send personalized voice messages"
                        )

                        FeatureHighlight(
                            icon: "heart.text.square",
                            title: "Perfect Flirts",
                            description: "AI-generated conversation starters"
                        )
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 40)

                    // Authentication Section
                    VStack(spacing: 20) {
                        // Terms Agreement
                        HStack(alignment: .top, spacing: 12) {
                            Button(action: {
                                agreedToTerms.toggle()
                            }) {
                                Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                                    .font(.title3)
                                    .foregroundColor(agreedToTerms ? .pink : .gray)
                            }
                            .accessibilityLabel(agreedToTerms ? "Terms agreed" : "Agree to terms")

                            VStack(alignment: .leading, spacing: 4) {
                                Text("I agree to the ")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                + Text("Terms of Service")
                                    .font(.caption)
                                    .foregroundColor(.pink)
                                    .underline()
                                + Text(" and ")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                + Text("Privacy Policy")
                                    .font(.caption)
                                    .foregroundColor(.pink)
                                    .underline()
                            }
                            .onTapGesture {
                                showingTerms = true
                            }

                            Spacer()
                        }
                        .padding(.horizontal)

                        // Apple Sign In Button
                        SignInWithAppleButton { request in
                            request.requestedScopes = [.fullName, .email]
                        } onCompletion: { result in
                            // Handle in AuthManager
                        }
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 50)
                        .cornerRadius(12)
                        .disabled(!agreedToTerms || authManager.isLoading)
                        .opacity(agreedToTerms ? 1.0 : 0.6)
                        .padding(.horizontal)
                        .accessibilityLabel("Sign in with Apple")
                        .onTapGesture {
                            if agreedToTerms {
                                authManager.signInWithApple()
                            }
                        }

                        // Custom Sign In Button (fallback)
                        Button(action: {
                            if agreedToTerms {
                                authManager.signInWithApple()
                            }
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
                            .frame(height: 50)
                            .background(Color.black)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .disabled(!agreedToTerms || authManager.isLoading)
                        .opacity(agreedToTerms ? 1.0 : 0.6)
                        .padding(.horizontal)
                        .accessibilityLabel("Continue with Apple")

                        // Age verification disclaimer
                        Text("You must be 18 or older to use Flirrt")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal)

                        // Loading state
                        if authManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .pink))
                                .scaleEffect(1.2)
                        }

                        // Error message
                        if let error = authManager.error {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        // Debug Testing Bypass (works on simulator and device)
                        #if DEBUG
                        VStack(spacing: 12) {
                            Divider()
                                .padding(.horizontal)

                            Button(action: {
                                // Set demo user in standard UserDefaults
                                UserDefaults.standard.set("demo-user-\(UUID().uuidString)", forKey: AppConstants.UserDefaultsKeys.userId)
                                UserDefaults.standard.set("Demo User", forKey: AppConstants.UserDefaultsKeys.userName)
                                UserDefaults.standard.set("demo@flirrt.test", forKey: AppConstants.UserDefaultsKeys.userEmail)
                                UserDefaults.standard.set(true, forKey: AppConstants.UserDefaultsKeys.onboardingCompleted)
                                UserDefaults.standard.set(true, forKey: AppConstants.UserDefaultsKeys.ageVerified)

                                // Save to App Group for keyboard access
                                if let sharedDefaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier) {
                                    sharedDefaults.set("demo-user-\(UUID().uuidString)", forKey: AppConstants.UserDefaultsKeys.userId)
                                    sharedDefaults.set("demo-token-\(UUID().uuidString)", forKey: AppConstants.UserDefaultsKeys.authToken)
                                    sharedDefaults.set(true, forKey: AppConstants.UserDefaultsKeys.hasFullAccess)
                                    sharedDefaults.synchronize()
                                    print("✅ Demo user saved to App Group")
                                }

                                // Bypass authentication
                                authManager.isAuthenticated = true
                                authManager.ageVerified = true

                                print("🎭 Running in Debug/Testing Mode")
                            }) {
                                HStack {
                                    Image(systemName: "person.fill.questionmark")
                                        .font(.title3)

                                    Text("Continue as Guest (Testing)")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.orange)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            .accessibilityLabel("Continue as guest for debug testing")

                            Text("Debug Testing Mode")
                                .font(.caption2)
                                .foregroundColor(.orange.opacity(0.7))
                        }
                        #endif
                    }

                    Spacer(minLength: 40)
                }
            }
        }
        .sheet(isPresented: $showingAgeVerification) {
            AgeVerificationView(birthDate: $birthDate) {
                authManager.verifyAge(birthDate)
                showingAgeVerification = false
            }
        }
        .sheet(isPresented: $showingTerms) {
            TermsAndPrivacyView(showingTerms: $showingTerms, showingPrivacy: $showingPrivacyPolicy)
        }
        .preferredColorScheme(.dark)
        .onChange(of: authManager.isAuthenticated) { isAuthenticated in
            if isAuthenticated && !authManager.ageVerified {
                showingAgeVerification = true
            }
        }
    }
}

// MARK: - Supporting Views

struct FeatureHighlight: View {
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
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.leading)
            }

            Spacer()
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
    }
}

struct AgeVerificationView: View {
    @Binding var birthDate: Date
    let onConfirm: () -> Void
    @Environment(\.dismiss) private var dismiss

    private var minimumDate: Date {
        Calendar.current.date(byAdding: .year, value: -100, to: Date()) ?? Date()
    }

    private var maximumDate: Date {
        Calendar.current.date(byAdding: .year, value: -13, to: Date()) ?? Date()
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(spacing: 16) {
                    Image(systemName: "calendar")
                        .font(.system(size: 60))
                        .foregroundColor(.pink)

                    Text("Age Verification")
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Text("Please confirm your birth date to continue. You must be 18 or older to use Flirrt.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                VStack(spacing: 20) {
                    Text("Birth Date")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)

                    DatePicker(
                        "Birth Date",
                        selection: $birthDate,
                        in: minimumDate...maximumDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .accessibilityLabel("Select your birth date")
                }

                Spacer()

                Button(action: onConfirm) {
                    Text("Confirm")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.pink)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .accessibilityLabel("Confirm birth date")
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct TermsAndPrivacyView: View {
    @Binding var showingTerms: Bool
    @Binding var showingPrivacy: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Terms of Service")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("By using Flirrt AI, you agree to these terms and conditions...")
                            .font(.body)

                        // Add actual terms content here
                        Text("""
                        1. You must be 18 years or older to use this service.
                        2. You are responsible for your interactions and communications.
                        3. We use AI to provide suggestions and analysis.
                        4. Your privacy and data security are important to us.
                        5. You may delete your account and data at any time.
                        """)
                        .font(.body)
                        .foregroundColor(.secondary)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Privacy Policy")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Your privacy is important to us. Here's how we handle your data...")
                            .font(.body)

                        // Add actual privacy policy content here
                        Text("""
                        • We collect minimal personal information
                        • Voice recordings are used only for AI training
                        • Data is encrypted and stored securely
                        • You can request data deletion at any time
                        • We don't share personal data with third parties
                        """)
                        .font(.body)
                        .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Terms & Privacy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Preview
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(AuthManager())
    }
}