# 📘 IMPLEMENTATION GUIDE - FLIRRT.AI FIXES

## 🎯 OBJECTIVE
Fix the non-functional keyboard extension buttons to connect with backend APIs and enable all features.

## ⏱️ ESTIMATED TIME
- Total: 2-3 hours
- Issue #1 (API Connection): 45 minutes
- Issue #2 (Screenshot): 45 minutes
- Issue #3 (Voice Scripts): 30 minutes
- Issue #4 (Onboarding): 30 minutes
- Testing: 30 minutes

## 📋 PRE-REQUISITES

### 1. Verify Environment
```bash
# Navigate to project
cd /Users/macbookairm1/Flirrt-screens-shots-v1/FlirrtAI

# Check backend is running
curl http://localhost:3000/health

# Open Xcode project (NOT Package.swift)
open FlirrtXcode.xcodeproj
```

### 2. Check Simulator
```bash
# List simulators
xcrun simctl list devices

# Boot if needed
xcrun simctl boot 237F6A2D-72E4-49C2-B5E0-7B3F973C6814
```

## 🛠️ STEP-BY-STEP FIXES

### STEP 1: Fix Keyboard API Connection (PRIORITY 1)

#### 1.1 Open the keyboard view controller
```bash
open iOS/FlirrtKeyboard/KeyboardViewController.swift
```

#### 1.2 Add network capabilities
At the top of the file, ensure these imports exist:
```swift
import UIKit
import Foundation
import os.log
```

#### 1.3 Replace flirrtFreshTapped method (Line 171)
```swift
@objc private func flirrtFreshTapped() {
    guard hasFullAccess else {
        showFullAccessRequired()
        return
    }

    // Show loading state
    suggestionsView.showLoading()

    // Prepare API request
    let url = URL(string: "http://localhost:3000/api/v1/generate_flirts")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    // Get auth token from shared container
    var authToken: String?
    if let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt.shared") {
        authToken = sharedDefaults.string(forKey: "auth_token")
    }

    // Use test token if no real token available
    if authToken == nil {
        authToken = "test-token-for-development"
    }

    request.setValue("Bearer \(authToken!)", forHTTPHeaderField: "Authorization")

    // Create request body
    let body: [String: Any] = [
        "screenshot_id": "fresh-\(Date().timeIntervalSince1970)",
        "suggestion_type": "opener",
        "tone": "playful",
        "user_preferences": [:]
    ]

    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
    } catch {
        os_log("Failed to serialize request body", log: logger, type: .error)
        return
    }

    // Make API call
    let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
        guard let self = self else { return }

        if let error = error {
            os_log("API request failed: %@", log: self.logger, type: .error, error.localizedDescription)
            DispatchQueue.main.async {
                self.suggestionsView.showError("Connection failed")
            }
            return
        }

        guard let data = data else {
            os_log("No data received", log: self.logger, type: .error)
            return
        }

        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let suggestions = json["suggestions"] as? [[String: Any]] {

                // Convert to Suggestion objects
                var suggestionObjects: [Suggestion] = []
                for suggestionData in suggestions {
                    if let text = suggestionData["text"] as? String {
                        let suggestion = Suggestion(
                            id: suggestionData["id"] as? String ?? UUID().uuidString,
                            text: text,
                            tone: suggestionData["tone"] as? String ?? "casual",
                            confidence: suggestionData["confidence"] as? Double ?? 0.5,
                            voiceAvailable: suggestionData["voice_available"] as? Bool ?? false
                        )
                        suggestionObjects.append(suggestion)
                    }
                }

                DispatchQueue.main.async {
                    self.suggestionsView.setSuggestions(suggestionObjects)
                    os_log("Loaded %d suggestions from API", log: self.logger, type: .info, suggestionObjects.count)
                }
            }
        } catch {
            os_log("Failed to parse response: %@", log: self.logger, type: .error, error.localizedDescription)

            // Fall back to default suggestions
            DispatchQueue.main.async {
                self.suggestionsView.setSuggestions(self.createDefaultSuggestions())
            }
        }
    }

    task.resume()
}
```

#### 1.4 Test the Fresh button
1. Build and run the app
2. Open Messages app in simulator
3. Switch to Flirrt keyboard
4. Tap "Fresh" button
5. Check backend logs for incoming request
6. Verify suggestions appear

### STEP 2: Add Screenshot Capture (PRIORITY 2)

#### 2.1 Update Info.plist for keyboard extension
```bash
open iOS/FlirrtKeyboard/Info.plist
```

Add before closing </dict>:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Flirrt analyzes screenshots to provide conversation suggestions</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Flirrt saves enhanced screenshots</string>
```

#### 2.2 Import Photos framework
In KeyboardViewController.swift, add after other imports:
```swift
import Photos
```

#### 2.3 Add screenshot monitoring
Add this method after analyzeTapped (around line 250):
```swift
private func setupScreenshotObserver() {
    // Monitor for screenshot notifications
    PHPhotoLibrary.shared().register(self)

    // Check for recent screenshots on keyboard activation
    checkForRecentScreenshot()
}

private func checkForRecentScreenshot() {
    PHPhotoLibrary.requestAuthorization { [weak self] status in
        guard status == .authorized else {
            os_log("Photo library access not authorized", log: self?.logger ?? OSLog.default, type: .info)
            return
        }

        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 1

        // Only get screenshots
        fetchOptions.predicate = NSPredicate(
            format: "mediaType = %d AND mediaSubtype = %d",
            PHAssetMediaType.image.rawValue,
            PHAssetMediaSubtype.photoScreenshot.rawValue
        )

        let screenshots = PHAsset.fetchAssets(with: fetchOptions)

        guard let latestScreenshot = screenshots.firstObject else { return }

        // Check if screenshot is recent (within last 60 seconds)
        let screenshotDate = latestScreenshot.creationDate ?? Date.distantPast
        let timeSinceScreenshot = Date().timeIntervalSince(screenshotDate)

        if timeSinceScreenshot < 60 {
            os_log("Recent screenshot detected, auto-analyzing", log: self?.logger ?? OSLog.default, type: .info)
            DispatchQueue.main.async {
                self?.processScreenshot(latestScreenshot)
            }
        }
    }
}

private func processScreenshot(_ asset: PHAsset) {
    let manager = PHImageManager.default()
    let options = PHImageRequestOptions()
    options.deliveryMode = .highQualityFormat
    options.isSynchronous = false

    manager.requestImageDataAndOrientation(for: asset, options: options) { [weak self] data, _, _, _ in
        guard let imageData = data else { return }
        self?.uploadScreenshotToBackend(imageData)
    }
}

private func uploadScreenshotToBackend(_ imageData: Data) {
    // Show loading
    DispatchQueue.main.async {
        self.suggestionsView.showLoading()
    }

    let url = URL(string: "http://localhost:3000/api/v1/analyze_screenshot")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"

    let boundary = "Boundary-\(UUID().uuidString)"
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

    // Add auth token
    if let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt.shared"),
       let token = sharedDefaults.string(forKey: "auth_token") {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    } else {
        request.setValue("Bearer test-token", forHTTPHeaderField: "Authorization")
    }

    // Build multipart form data
    var body = Data()

    // Add image data
    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"screenshot\"; filename=\"screenshot.jpg\"\r\n".data(using: .utf8)!)
    body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
    body.append(imageData)
    body.append("\r\n".data(using: .utf8)!)

    // Add context
    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"context\"\r\n\r\n".data(using: .utf8)!)
    body.append("dating_app_screenshot".data(using: .utf8)!)
    body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

    request.httpBody = body

    URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
        guard let self = self else { return }

        if let data = data,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let screenshotId = json["screenshot_id"] as? String {

            os_log("Screenshot uploaded, ID: %@", log: self.logger, type: .info, screenshotId)

            // Now generate flirts for this screenshot
            self.generateFlirtsForScreenshot(screenshotId)
        } else {
            os_log("Screenshot upload failed", log: self.logger, type: .error)
            DispatchQueue.main.async {
                self.suggestionsView.showError("Analysis failed")
            }
        }
    }.resume()
}

private func generateFlirtsForScreenshot(_ screenshotId: String) {
    // Similar to flirrtFreshTapped but with specific screenshot_id
    let url = URL(string: "http://localhost:3000/api/v1/generate_flirts")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    if let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt.shared"),
       let token = sharedDefaults.string(forKey: "auth_token") {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    } else {
        request.setValue("Bearer test-token", forHTTPHeaderField: "Authorization")
    }

    let body: [String: Any] = [
        "screenshot_id": screenshotId,
        "suggestion_type": "response",
        "tone": "witty"
    ]

    request.httpBody = try? JSONSerialization.data(withJSONObject: body)

    URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
        // Same response handling as flirrtFreshTapped
        // Parse suggestions and display them
        guard let data = data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let suggestions = json["suggestions"] as? [[String: Any]] else {
            return
        }

        var suggestionObjects: [Suggestion] = []
        for suggestionData in suggestions {
            if let text = suggestionData["text"] as? String {
                let suggestion = Suggestion(
                    id: suggestionData["id"] as? String ?? UUID().uuidString,
                    text: text,
                    tone: suggestionData["tone"] as? String ?? "casual",
                    confidence: suggestionData["confidence"] as? Double ?? 0.5,
                    voiceAvailable: false
                )
                suggestionObjects.append(suggestion)
            }
        }

        DispatchQueue.main.async {
            self?.suggestionsView.setSuggestions(suggestionObjects)
        }
    }.resume()
}
```

#### 2.4 Call setup in viewDidLoad
Add to viewDidLoad() method:
```swift
override func viewDidLoad() {
    super.viewDidLoad()
    // ... existing code ...
    setupScreenshotObserver()
}
```

### STEP 3: Add Voice Script Interface (PRIORITY 3)

#### 3.1 Open VoiceRecordingView
```bash
open iOS/Flirrt/Views/VoiceRecordingView.swift
```

#### 3.2 Add script selection UI
After line 30 (inside the main VStack), add:
```swift
// Script selection section
VStack(alignment: .leading, spacing: 16) {
    Text("Voice Training Script")
        .font(.title2)
        .fontWeight(.bold)
        .foregroundColor(.white)

    // Script options
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 12) {
            ForEach(["Friendly", "Flirty", "Confident", "Playful"], id: \.self) { tone in
                Button(action: {
                    selectedScriptTone = tone
                    loadScriptForTone(tone)
                }) {
                    Text(tone)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedScriptTone == tone ? Color.pink : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }
            }
        }
    }

    // Script text
    if !currentScript.isEmpty {
        VStack(alignment: .leading, spacing: 8) {
            Text("Please read this text aloud:")
                .font(.caption)
                .foregroundColor(.gray)

            Text(currentScript)
                .font(.body)
                .foregroundColor(.white)
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.pink.opacity(0.3), lineWidth: 1)
                )
        }
    }

    // Background noise toggle
    Toggle("Add Background Ambience", isOn: $includeBackgroundNoise)
        .foregroundColor(.white)
        .tint(.pink)
}
.padding(.horizontal)
```

#### 3.3 Add state variables
At the top of the struct, add:
```swift
@State private var selectedScriptTone = "Friendly"
@State private var currentScript = ""
@State private var includeBackgroundNoise = false

private let scripts = [
    "Friendly": "Hi there! I noticed we both love hiking and outdoor adventures. Last weekend I discovered this amazing trail with a waterfall. The view was absolutely breathtaking! What's your favorite spot to explore?",
    "Flirty": "Well hello gorgeous! Your smile just brightened my entire day. I have to know - what's the story behind that amazing photo? You look like you were having the time of your life!",
    "Confident": "I know exactly what I want in life, and meeting interesting people like you is definitely part of it. Your profile caught my attention because you seem genuine and fun. Want to grab coffee and see if we click?",
    "Playful": "Okay, serious question time: Would you rather fight one horse-sized duck or a hundred duck-sized horses? Your answer determines if we're compatible. No pressure though!"
]

private func loadScriptForTone(_ tone: String) {
    currentScript = scripts[tone] ?? ""
}
```

#### 3.4 Modify upload to include script info
In the uploadRecording method, add script metadata:
```swift
// Add to the multipart form data
body.append("--\(boundary)\r\n".data(using: .utf8)!)
body.append("Content-Disposition: form-data; name=\"script_tone\"\r\n\r\n".data(using: .utf8)!)
body.append(selectedScriptTone.data(using: .utf8)!)
body.append("\r\n".data(using: .utf8)!)

body.append("--\(boundary)\r\n".data(using: .utf8)!)
body.append("Content-Disposition: form-data; name=\"include_background\"\r\n\r\n".data(using: .utf8)!)
body.append(String(includeBackgroundNoise).data(using: .utf8)!)
body.append("\r\n".data(using: .utf8)!)
```

### STEP 4: Connect Fresh to Onboarding (PRIORITY 4)

#### 4.1 Update keyboard to trigger onboarding
In KeyboardViewController.swift, modify flirrtFreshTapped:
```swift
@objc private func flirrtFreshTapped() {
    guard hasFullAccess else {
        showFullAccessRequired()
        return
    }

    // Check if this is first time use
    let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt.shared")
    let hasCompletedOnboarding = sharedDefaults?.bool(forKey: "has_completed_onboarding") ?? false

    if !hasCompletedOnboarding {
        // Request main app to show onboarding
        sharedDefaults?.set(true, forKey: "needs_onboarding")
        sharedDefaults?.synchronize()

        // Show message to user
        showOnboardingRequired()

        // Post notification to main app
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName("com.flirrt.needs.onboarding" as CFString),
            nil, nil, true
        )

        return
    }

    // Continue with normal fresh suggestions
    // ... (existing API call code from Step 1)
}

private func showOnboardingRequired() {
    let alert = UIAlertController(
        title: "Setup Required",
        message: "Please open the Flirrt app to complete your profile setup",
        preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: "OK", style: .default))

    if let rootVC = self.view.window?.rootViewController {
        rootVC.present(alert, animated: true)
    }
}
```

#### 4.2 Update main app to listen for onboarding request
In iOS/Flirrt/App/FlirrtApp.swift, add:
```swift
.onAppear {
    // Listen for onboarding request from keyboard
    NotificationCenter.default.addObserver(
        forName: NSNotification.Name("com.flirrt.needs.onboarding"),
        object: nil,
        queue: .main
    ) { _ in
        // Check shared defaults
        if let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt.shared"),
           sharedDefaults.bool(forKey: "needs_onboarding") {
            // Show onboarding
            appCoordinator.showOnboarding = true
            sharedDefaults.set(false, forKey: "needs_onboarding")
        }
    }
}
```

## 🧪 TESTING PROCEDURE

### Test 1: Fresh Button
1. Open Messages app
2. Switch to Flirrt keyboard
3. Tap "Fresh" button
4. Expected: Loading indicator → 3 suggestions appear
5. Check backend logs for `/api/v1/generate_flirts` request

### Test 2: Screenshot Analysis
1. Take a screenshot of any dating profile
2. Within 60 seconds, open Messages
3. Switch to Flirrt keyboard
4. Expected: Auto-analysis starts
5. Check backend logs for `/api/v1/analyze_screenshot` request

### Test 3: Voice Scripts
1. Open main Flirrt app
2. Go to Voice tab
3. Select a script tone
4. See script text displayed
5. Record yourself reading it
6. Submit recording

### Test 4: Onboarding Flow
1. Clear app data: `xcrun simctl erase 237F6A2D-72E4-49C2-B5E0-7B3F973C6814`
2. Reinstall app
3. Open Messages → Flirrt keyboard
4. Tap Fresh button
5. Expected: Alert to open main app
6. Open main app → See onboarding

## 🚀 BUILD & DEPLOY

### Final Build
```bash
# Clean build
xcodebuild -project FlirrtXcode.xcodeproj \
  -scheme Flirrt \
  -destination 'platform=iOS Simulator,id=237F6A2D-72E4-49C2-B5E0-7B3F973C6814' \
  clean build

# Install to simulator
xcrun simctl install booted \
  build/Build/Products/Debug-iphonesimulator/Flirrt.app
```

### Verify All Features
```bash
# Run automated tests
cd Agents
node SimulatorTestAgent.js --full-test
```

## ✅ SUCCESS CRITERIA

- [ ] Fresh button generates 3 suggestions from backend
- [ ] Analyze button processes screenshots
- [ ] Screenshots auto-trigger analysis within 60 seconds
- [ ] Voice recording shows script options
- [ ] First-time users see onboarding
- [ ] All API calls show in backend logs
- [ ] No memory warnings in keyboard extension

## 🆘 TROUBLESHOOTING

### Issue: Network requests fail
- Check backend is running: `curl http://localhost:3000/health`
- Verify simulator can access localhost
- Check auth token in shared UserDefaults

### Issue: Photos access denied
- Reset privacy settings: Settings → Privacy → Photos
- Grant access when prompted
- Check Info.plist has usage descriptions

### Issue: Keyboard doesn't appear
- Settings → General → Keyboard → Keyboards
- Add Flirrt keyboard
- Enable "Allow Full Access"

### Issue: Memory warnings
- Check keyboard extension stays under 60MB
- Use Instruments to profile memory usage
- Remove unnecessary assets/code