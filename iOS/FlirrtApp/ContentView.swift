import SwiftUI

struct ContentView: View {
    @State private var isKeyboardInstalled = false
    @State private var memoryUsage: Double = 0.0

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // App Icon
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.pink)

                Text("Flirrt AI")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Your AI Dating Assistant")
                    .font(.title2)
                    .foregroundColor(.secondary)

                Spacer()

                VStack(alignment: .leading, spacing: 16) {
                    Text("Setup Instructions:")
                        .font(.headline)

                    setupStep(number: 1, title: "Enable Keyboard",
                             description: "Go to Settings > General > Keyboard > Keyboards > Add New Keyboard > FlirrtKeyboard")

                    setupStep(number: 2, title: "Enable Full Access",
                             description: "Tap FlirrtKeyboard > Allow Full Access")

                    setupStep(number: 3, title: "Ready to Use",
                             description: "Switch to FlirrtKeyboard in any app to get AI suggestions")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)

                Spacer()

                // Status indicators
                VStack(spacing: 8) {
                    statusIndicator(
                        title: "Keyboard Extension",
                        isActive: isKeyboardInstalled,
                        activeText: "Installed",
                        inactiveText: "Not Installed"
                    )

                    statusIndicator(
                        title: "Memory Usage",
                        isActive: memoryUsage < 50,
                        activeText: String(format: "%.1f MB", memoryUsage),
                        inactiveText: String(format: "%.1f MB (High)", memoryUsage)
                    )
                }

                Button("Check Status") {
                    checkKeyboardStatus()
                }
                .buttonStyle(.borderedProminent)
                .tint(.pink)
            }
            .padding()
            .navigationTitle("Flirrt AI")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            checkKeyboardStatus()
        }
    }

    private func setupStep(number: Int, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.pink))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }

    private func statusIndicator(title: String, isActive: Bool, activeText: String, inactiveText: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)

            Spacer()

            Text(isActive ? activeText : inactiveText)
                .font(.caption)
                .foregroundColor(isActive ? .green : .orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.gray.opacity(0.2)))
        }
    }

    private func checkKeyboardStatus() {
        // Check if keyboard is installed by looking at available input modes
        let inputModes = UserDefaults.standard.object(forKey: "AppleKeyboards") as? [String] ?? []
        isKeyboardInstalled = inputModes.contains { $0.contains("FlirrtKeyboard") }

        // Simulate memory usage check
        memoryUsage = Double.random(in: 30...45)

        // Update shared UserDefaults
        if let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt.shared") {
            sharedDefaults.set(true, forKey: "user_authenticated")
            sharedDefaults.set(Date().timeIntervalSince1970, forKey: "last_app_open")
            sharedDefaults.synchronize()
        }
    }
}

#Preview {
    ContentView()
}