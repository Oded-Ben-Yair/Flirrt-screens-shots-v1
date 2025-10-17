import SwiftUI

/**
 * Age Verification View
 * CRITICAL: Dating apps require 18+ age verification for App Store approval
 *
 * Features:
 * - Birthdate picker with DatePicker
 * - Age calculation (must be 18+)
 * - Persistent storage of birthdate
 * - Blocks access if under 18
 * - Clear UI with privacy explanation
 */
struct AgeVerificationView: View {
    @State private var birthdate = Calendar.current.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    @State private var isAgeVerified = false
    @State private var showError = false
    @State private var errorMessage = ""

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                // iOS 26 Liquid Glass background
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.2, blue: 0.4).opacity(0.1),
                        Color(red: 1.0, green: 0.4, blue: 0.6).opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 30) {
                    Spacer()

                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.pink, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("Age Verification")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        Text("You must be 18 or older to use Flirrt")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }

                    Spacer()

                    // Birthdate Picker
                    VStack(spacing: 20) {
                        Text("Select your birthdate")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)

                        DatePicker(
                            "Birthdate",
                            selection: $birthdate,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxHeight: 200)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(.ultraThinMaterial)
                        )
                        .padding(.horizontal, 20)

                        // Age display
                        if let age = calculateAge(from: birthdate) {
                            Text("Age: \(age) years old")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(age >= 18 ? .green : .red)
                        }
                    }

                    Spacer()

                    // Privacy note
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)

                            Text("Your birthdate is stored securely and privately")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }

                        Text("We use this information only for age verification")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 40)
                    .multilineTextAlignment(.center)

                    // Continue button
                    Button(action: verifyAge) {
                        HStack(spacing: 12) {
                            Text("Continue")
                                .font(.system(size: 18, weight: .semibold))

                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [.pink, .red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16, style: .continuous)
                    }
                    .padding(.horizontal, 20)

                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .alert("Age Verification", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Age Calculation

    private func calculateAge(from birthdate: Date) -> Int? {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthdate, to: Date())
        return ageComponents.year
    }

    // MARK: - Verification

    private func verifyAge() {
        guard let age = calculateAge(from: birthdate) else {
            showError(message: "Invalid birthdate selected")
            return
        }

        if age < 18 {
            showError(message: "You must be at least 18 years old to use Flirrt. We're sorry, but we can't allow access to users under 18.")
            return
        }

        // Save birthdate for compliance
        saveBirthdate(birthdate)

        // Mark as verified
        UserDefaults.standard.set(true, forKey: "ageVerified")
        UserDefaults.standard.synchronize()

        print("✅ Age verified: \(age) years old")

        // Dismiss view
        dismiss()
    }

    private func showError(message: String) {
        errorMessage = message
        showError = true

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    private func saveBirthdate(_ date: Date) {
        UserDefaults.standard.set(date, forKey: "userBirthdate")
        UserDefaults.standard.synchronize()

        print("📝 Birthdate saved for compliance")
    }

    // MARK: - Public Helper

    static func isAgeVerified() -> Bool {
        return UserDefaults.standard.bool(forKey: "ageVerified")
    }

    static func requiresAgeVerification() -> Bool {
        return !isAgeVerified()
    }

    static func getUserAge() -> Int? {
        guard let birthdate = UserDefaults.standard.object(forKey: "userBirthdate") as? Date else {
            return nil
        }

        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthdate, to: Date())
        return ageComponents.year
    }
}

// MARK: - Preview

#Preview {
    AgeVerificationView()
}
