import SwiftUI

struct AppCoordinator: View {
    @EnvironmentObject private var authManager: AuthManager

    @State private var isOnboardingComplete = UserDefaults.standard.bool(forKey: "onboarding_complete")
    @State private var isPersonalizationComplete = UserDefaults.standard.bool(forKey: "personalization_complete")

    var body: some View {
        Group {
            if !authManager.isAuthenticated {
                // Show login if not authenticated
                LoginView()
                    .transition(.opacity)
            } else if !authManager.ageVerified {
                // Show age verification if not verified
                AgeVerificationFlow()
                    .transition(.opacity)
            } else if !isOnboardingComplete {
                // Show onboarding for first-time users
                OnboardingView(isOnboardingComplete: $isOnboardingComplete)
                    .transition(.slide)
            } else if !isPersonalizationComplete {
                // Show personalization questionnaire
                PersonalizationQuestionnaireView(
                    isPresented: .constant(true),
                    onComplete: {
                        isPersonalizationComplete = true
                    }
                )
                .transition(.opacity)
            } else {
                // Show main app
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: authManager.isAuthenticated)
        .animation(.easeInOut(duration: 0.5), value: authManager.ageVerified)
        .animation(.easeInOut(duration: 0.5), value: isOnboardingComplete)
        .animation(.easeInOut(duration: 0.5), value: isPersonalizationComplete)
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            // Update state when UserDefaults change
            isOnboardingComplete = UserDefaults.standard.bool(forKey: "onboarding_complete")
            isPersonalizationComplete = UserDefaults.standard.bool(forKey: "personalization_complete")
        }
    }
}

// MARK: - Age Verification Flow

struct AgeVerificationFlow: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var birthDate = Date()
    @Environment(\.dismiss) private var dismiss

    private var minimumDate: Date {
        Calendar.current.date(byAdding: .year, value: -100, to: Date()) ?? Date()
    }

    private var maximumDate: Date {
        Calendar.current.date(byAdding: .year, value: -13, to: Date()) ?? Date()
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color.gray.opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                VStack(spacing: 20) {
                    Image(systemName: "calendar.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.pink)

                    Text("Age Verification Required")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)

                    Text("Please confirm your birth date to continue. You must be 18 or older to use Flirrt.")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                VStack(spacing: 20) {
                    Text("Birth Date")
                        .font(.headline)
                        .foregroundColor(.white)
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
                    .padding(.horizontal)
                    .accessibilityLabel("Select your birth date")
                }

                Button(action: {
                    authManager.verifyAge(birthDate)
                }) {
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

                if let error = authManager.error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                Button("Sign Out") {
                    authManager.logout()
                }
                .font(.subheadline)
                .foregroundColor(.gray)
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Preview
struct AppCoordinator_Previews: PreviewProvider {
    static var previews: some View {
        AppCoordinator()
            .environmentObject(AuthManager())
    }
}