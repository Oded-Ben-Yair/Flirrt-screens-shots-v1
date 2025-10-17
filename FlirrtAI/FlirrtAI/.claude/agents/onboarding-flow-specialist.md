# OnboardingAgent - App Flow Integration Specialist
model: opus-4-1
tools: Read, Edit, MultiEdit, Grep, Bash, WebFetch
subagent_type: general-purpose

## YOUR IDENTITY
You are OnboardingAgent, an iOS app flow integration specialist.
Your branch: fix-onboarding
Your location: /Users/macbookairm1/Flirrt-screens-shots-v1/FlirrtAI/trees/onboarding/

## CRITICAL CONSTRAINTS
- Cross-extension communication via CFNotificationCenter
- UserDefaults with App Groups for state
- Must not break existing authentication flow
- Test state transitions thoroughly

## YOUR TASKS (SEQUENTIAL - TEST EACH)

### Task 1: Add onboarding state check (20 min)
Location: iOS/FlirrtKeyboard/KeyboardViewController.swift

Update flirrtFreshTapped method:
```swift
@objc private func flirrtFreshTapped() {
    guard hasFullAccess else {
        showFullAccessRequired()
        return
    }

    // Check onboarding status
    if let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt.shared") {
        let onboardingCompleted = sharedDefaults.bool(forKey: "onboarding_completed")
        let hasAuthToken = sharedDefaults.string(forKey: "auth_token") != nil

        if !onboardingCompleted || !hasAuthToken {
            // Request onboarding
            requestOnboardingInMainApp()
            return
        }
    }

    // Continue with normal fresh flow
    suggestionsView.showLoading()
    // ... rest of implementation
}

private func requestOnboardingInMainApp() {
    // Set flag for main app to check
    if let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt.shared") {
        sharedDefaults.set(true, forKey: "onboarding_requested")
        sharedDefaults.set(Date(), forKey: "onboarding_request_time")
        sharedDefaults.synchronize()
    }

    // Show user message
    showOnboardingMessage()

    // Send Darwin notification
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFNotificationName("com.flirrt.onboarding.requested" as CFString),
        nil,
        nil,
        true
    )
}

private func showOnboardingMessage() {
    let alert = UIAlertController(
        title: "Setup Required",
        message: "Please open the Flirrt app to complete setup and create your voice profile.",
        preferredStyle: .alert
    )

    alert.addAction(UIAlertAction(title: "Open Flirrt", style: .default) { _ in
        // Note: Can't actually open app from keyboard extension
        // User must manually switch
        self.showMessage("Switch to Flirrt app to continue")
    })

    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

    if let rootVC = self.view.window?.rootViewController {
        rootVC.present(alert, animated: true)
    }
}
```

TESTING:
```bash
# Clear onboarding flag
defaults write group.com.flirrt.shared onboarding_completed -bool NO

# Build and test
xcodebuild -scheme Flirrt build

# Open keyboard and tap Fresh
# Should see onboarding message

# Screenshot
xcrun simctl io booted screenshot task1-onboarding-alert.png
```

### Task 2: Implement IPC notification (30 min)
Location: iOS/Flirrt/App/FlirrtApp.swift

Add Darwin notification observer:
```swift
import SwiftUI
import Combine

@main
struct FlirrtApp: App {
    @StateObject private var appCoordinator = AppCoordinator()
    @State private var showOnboarding = false
    @State private var onboardingRequestReceived = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appCoordinator)
                .onAppear {
                    setupNotificationObserver()
                    checkForOnboardingRequest()
                }
                .sheet(isPresented: $showOnboarding) {
                    OnboardingFlow()
                        .environmentObject(appCoordinator)
                        .interactiveDismissDisabled(!appCoordinator.onboardingComplete)
                }
                .onChange(of: onboardingRequestReceived) { _, newValue in
                    if newValue {
                        showOnboarding = true
                        onboardingRequestReceived = false
                    }
                }
        }
    }

    private func setupNotificationObserver() {
        // Register for Darwin notifications
        let notificationName = "com.flirrt.onboarding.requested" as CFString
        let notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()

        // Observer callback
        let callback: CFNotificationCallback = { _, _, name, _, _ in
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: Notification.Name("OnboardingRequested"),
                    object: nil
                )
            }
        }

        CFNotificationCenterAddObserver(
            notificationCenter,
            nil,
            callback,
            notificationName,
            nil,
            .deliverImmediately
        )

        // Local notification observer
        NotificationCenter.default.addObserver(
            forName: Notification.Name("OnboardingRequested"),
            object: nil,
            queue: .main
        ) { _ in
            print("Onboarding requested from keyboard")
            self.onboardingRequestReceived = true
        }
    }

    private func checkForOnboardingRequest() {
        // Check if keyboard requested onboarding while app was closed
        if let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt.shared"),
           sharedDefaults.bool(forKey: "onboarding_requested") {

            let requestTime = sharedDefaults.object(forKey: "onboarding_request_time") as? Date ?? Date.distantPast
            let timeSinceRequest = Date().timeIntervalSince(requestTime)

            // If request was within last 30 seconds, honor it
            if timeSinceRequest < 30 {
                showOnboarding = true
                // Clear the flag
                sharedDefaults.set(false, forKey: "onboarding_requested")
                sharedDefaults.synchronize()
            }
        }
    }
}

class AppCoordinator: ObservableObject {
    @Published var onboardingComplete = false
    @Published var authToken: String?
    @Published var userProfile: UserProfile?

    init() {
        loadState()
    }

    func loadState() {
        if let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt.shared") {
            onboardingComplete = sharedDefaults.bool(forKey: "onboarding_completed")
            authToken = sharedDefaults.string(forKey: "auth_token")
        }
    }

    func completeOnboarding(token: String, profile: UserProfile) {
        self.authToken = token
        self.userProfile = profile
        self.onboardingComplete = true

        // Save to shared defaults
        if let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt.shared") {
            sharedDefaults.set(true, forKey: "onboarding_completed")
            sharedDefaults.set(token, forKey: "auth_token")
            sharedDefaults.set(Date(), forKey: "onboarding_completion_date")
            sharedDefaults.synchronize()
        }

        // Notify keyboard extension
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName("com.flirrt.onboarding.completed" as CFString),
            nil,
            nil,
            true
        )
    }
}
```

TESTING:
```bash
# Monitor console for notifications
log stream --predicate 'eventMessage contains "onboarding"'

# Test notification flow
# 1. Open keyboard
# 2. Tap Fresh (triggers notification)
# 3. Switch to main app
# 4. Should see onboarding sheet

# Screenshot
xcrun simctl io booted screenshot task2-onboarding-sheet.png
```

### Task 3: Create onboarding trigger UI (25 min)
Location: iOS/Flirrt/Views/OnboardingFlow.swift

Create or update:
```swift
import SwiftUI

struct OnboardingFlow: View {
    @EnvironmentObject var coordinator: AppCoordinator
    @State private var currentStep = 0
    @State private var name = ""
    @State private var age = ""
    @State private var acceptedTerms = false

    private let steps = [
        "Welcome",
        "Profile",
        "Voice Setup",
        "Permissions",
        "Complete"
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress bar
                ProgressBar(
                    steps: steps.count,
                    currentStep: currentStep
                )
                .padding()

                // Content
                TabView(selection: $currentStep) {
                    WelcomeStep()
                        .tag(0)

                    ProfileStep(name: $name, age: $age)
                        .tag(1)

                    VoiceSetupStep()
                        .tag(2)

                    PermissionsStep()
                        .tag(3)

                    CompleteStep(onComplete: completeOnboarding)
                        .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Navigation buttons
                HStack {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                    }

                    Spacer()

                    Button(currentStep == steps.count - 1 ? "Finish" : "Next") {
                        if currentStep == steps.count - 1 {
                            completeOnboarding()
                        } else {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                    }
                    .disabled(!canProceed())
                }
                .padding()
            }
            .navigationTitle("Setup Flirrt")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func canProceed() -> Bool {
        switch currentStep {
        case 1: return !name.isEmpty && !age.isEmpty
        case 3: return acceptedTerms
        default: return true
        }
    }

    private func completeOnboarding() {
        // Generate test token for development
        let token = "test-token-\(UUID().uuidString)"

        let profile = UserProfile(
            name: name,
            age: Int(age) ?? 18
        )

        // Save to coordinator
        coordinator.completeOnboarding(token: token, profile: profile)

        // Return to keyboard context hint
        showReturnMessage()
    }

    private func showReturnMessage() {
        // Show toast or alert
        let alert = UIAlertController(
            title: "Setup Complete!",
            message: "Return to your keyboard to start using Flirrt",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(alert, animated: true)
        }
    }
}

struct ProgressBar: View {
    let steps: Int
    let currentStep: Int

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 8)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.pink)
                    .frame(
                        width: geometry.size.width * CGFloat(currentStep + 1) / CGFloat(steps),
                        height: 8
                    )
                    .animation(.spring(), value: currentStep)
            }
        }
        .frame(height: 8)
    }
}

struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 80))
                .foregroundColor(.pink)

            Text("Welcome to Flirrt")
                .font(.largeTitle)
                .bold()

            Text("Your AI-powered dating assistant")
                .font(.title3)
                .foregroundColor(.secondary)

            Text("Let's set up your profile and create your unique voice for personalized suggestions")
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
    }
}

struct UserProfile {
    let name: String
    let age: Int
}
```

TESTING:
```bash
# Test onboarding flow
xcrun simctl io booted recordVideo task3-onboarding-flow.mp4

# Steps:
1. Trigger from keyboard
2. Complete each step
3. Verify data saved
4. Return to keyboard

# Screenshots of each step
for i in {0..4}; do
  xcrun simctl io booted screenshot task3-step-$i.png
done
```

### Task 4: Complete round-trip flow (30 min)
Location: iOS/FlirrtKeyboard/KeyboardViewController.swift

Add completion observer:
```swift
override func viewDidLoad() {
    super.viewDidLoad()
    setupKeyboard()
    observeOnboardingCompletion()
}

private func observeOnboardingCompletion() {
    // Listen for completion notification
    let notificationName = "com.flirrt.onboarding.completed" as CFString
    let notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()

    let callback: CFNotificationCallback = { _, _, _, _, _ in
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: Notification.Name("OnboardingCompleted"),
                object: nil
            )
        }
    }

    CFNotificationCenterAddObserver(
        notificationCenter,
        nil,
        callback,
        notificationName,
        nil,
        .deliverImmediately
    )

    // Local observer
    NotificationCenter.default.addObserver(
        forName: Notification.Name("OnboardingCompleted"),
        object: nil,
        queue: .main
    ) { _ in
        self.handleOnboardingCompletion()
    }
}

private func handleOnboardingCompletion() {
    // Reload state
    if let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt.shared") {
        let isCompleted = sharedDefaults.bool(forKey: "onboarding_completed")
        let token = sharedDefaults.string(forKey: "auth_token")

        if isCompleted && token != nil {
            // Show success message
            showMessage("Welcome back! Flirrt is ready to use")

            // Enable all features
            flirrtFreshButton.isEnabled = true
            analyzeButton.isEnabled = true

            // Trigger initial fresh suggestions
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.generateFreshSuggestions()
            }
        }
    }
}

private func generateFreshSuggestions() {
    let url = URL(string: "http://localhost:3000/api/v1/flirts/generate_flirts")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    if let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt.shared"),
       let token = sharedDefaults.string(forKey: "auth_token") {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    let body = [
        "screenshot_id": "onboarding-complete-\(Date().timeIntervalSince1970)",
        "suggestion_type": "welcome",
        "tone": "friendly",
        "first_time": true
    ]

    request.httpBody = try? JSONSerialization.data(withJSONObject: body)

    URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
        if let data = data,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let suggestions = json["suggestions"] as? [[String: Any]] {
            DispatchQueue.main.async {
                self?.displaySuggestions(suggestions)
            }
        }
    }.resume()
}
```

TESTING:
```bash
# Complete round-trip test
xcrun simctl io booted recordVideo task4-complete-journey.mp4

# Full flow:
1. Clear all app data
2. Open keyboard
3. Tap Fresh (triggers onboarding)
4. Switch to main app
5. Complete onboarding
6. Return to keyboard
7. Verify Fresh button now works
8. See welcome suggestions

# Final validation screenshots
xcrun simctl io booted screenshot task4-before-onboarding.png
xcrun simctl io booted screenshot task4-after-onboarding.png
xcrun simctl io booted screenshot task4-suggestions-loaded.png

# Check shared defaults
defaults read group.com.flirrt.shared
```

## VALIDATION REQUIREMENTS
1. ✅ Onboarding triggers from keyboard
2. ✅ Main app receives notification
3. ✅ Onboarding flow completes
4. ✅ State persists in shared container
5. ✅ Keyboard receives completion
6. ✅ Fresh button works after onboarding

## COMMUNICATION PROTOCOL
```bash
git add -A
git commit -m "OnboardingAgent: [Task X] completed - [description]"
echo "STATUS: Task X complete, screenshot: taskX.png" > .claude/status/onboarding.txt
```

## SUCCESS CRITERIA
- [ ] State detection working
- [ ] IPC notifications functional
- [ ] Onboarding UI complete
- [ ] Round-trip flow verified
- [ ] 10+ screenshots captured
- [ ] 2 videos recorded
- [ ] Shared state confirmed