# 🚨 CRITICAL FIXES REQUIRED - FLIRRT.AI

**DATE**: 2025-09-23
**STATUS**: App installed but keyboard extension non-functional
**PRIORITY**: URGENT - User tested and buttons don't work

## 📍 START HERE - QUICK CONTEXT
The Flirrt.ai iOS app is built and installed with keyboard extension enabled, but the Fresh/Analyze buttons in the keyboard DO NOT WORK. They only trigger local methods without any backend API calls. Screenshots don't activate the keyboard. Voice cloning lacks script reading. Onboarding flow isn't connected.

## 🔴 ISSUE #1: Keyboard Buttons Not Working

### Current Problem
When user taps "Fresh" or "Analyze" buttons in keyboard extension, nothing happens.

### Evidence
- User testing screenshots show buttons visible but non-functional
- Code inspection shows buttons only call local methods
- No HTTP requests made to backend

### Broken Code Location
**File**: `/Users/macbookairm1/Flirrt-screens-shots-v1/FlirrtAI/iOS/FlirrtKeyboard/KeyboardViewController.swift`
**Lines**: 171-189

```swift
// CURRENT BROKEN CODE:
@objc private func flirrtFreshTapped() {
    guard hasFullAccess else {
        showFullAccessRequired()
        return
    }
    // PROBLEM: Only loads local data, no API call
    loadOpenerSuggestions()
}

@objc private func analyzeTapped() {
    guard hasFullAccess else {
        showFullAccessRequired()
        return
    }
    // PROBLEM: Only sends notification, no actual API call
    requestScreenshotAnalysis()
}
```

### Required Fix
```swift
// REQUIRED WORKING CODE:
import Foundation

@objc private func flirrtFreshTapped() {
    guard hasFullAccess else {
        showFullAccessRequired()
        return
    }

    // Call backend to get fresh openers
    let url = URL(string: "http://localhost:3000/api/v1/generate_flirts")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    // Get auth token from shared container
    if let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt.shared"),
       let token = sharedDefaults.string(forKey: "auth_token") {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    let body = [
        "screenshot_id": "fresh-\(Date().timeIntervalSince1970)",
        "suggestion_type": "opener",
        "tone": "playful"
    ]

    request.httpBody = try? JSONSerialization.data(withJSONObject: body)

    URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
        if let data = data,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let suggestions = json["suggestions"] as? [[String: Any]] {
            // Process and display suggestions
            DispatchQueue.main.async {
                self?.displaySuggestions(suggestions)
            }
        }
    }.resume()
}

@objc private func analyzeTapped() {
    guard hasFullAccess else {
        showFullAccessRequired()
        return
    }

    // Get latest screenshot from Photos
    // This requires PHPhotoLibrary implementation (see Issue #2)
    captureAndAnalyzeScreenshot()
}
```

## 🔴 ISSUE #2: Screenshot Not Triggering Keyboard

### Current Problem
Taking a screenshot doesn't activate keyboard or trigger analysis.

### Required Implementation
**File**: `iOS/FlirrtKeyboard/Info.plist`
**Add**:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Flirrt needs access to analyze your screenshots for conversation suggestions</string>
```

**File**: `iOS/FlirrtKeyboard/KeyboardViewController.swift`
**Add Import**:
```swift
import Photos
```

**Add Method**:
```swift
private func captureAndAnalyzeScreenshot() {
    // Request photo library access
    PHPhotoLibrary.requestAuthorization { status in
        guard status == .authorized else { return }

        // Get latest screenshot
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 1
        fetchOptions.predicate = NSPredicate(format: "mediaType = %d AND mediaSubtype = %d",
                                            PHAssetMediaType.image.rawValue,
                                            PHAssetMediaSubtype.photoScreenshot.rawValue)

        let screenshots = PHAsset.fetchAssets(with: fetchOptions)
        guard let latestScreenshot = screenshots.firstObject else { return }

        // Check if screenshot is recent (within last 60 seconds)
        let screenshotDate = latestScreenshot.creationDate ?? Date()
        if Date().timeIntervalSince(screenshotDate) > 60 { return }

        // Get image data
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat

        manager.requestImageDataAndOrientation(for: latestScreenshot, options: options) { [weak self] data, _, _, _ in
            guard let imageData = data else { return }
            self?.uploadScreenshotToBackend(imageData)
        }
    }
}

private func uploadScreenshotToBackend(_ imageData: Data) {
    let url = URL(string: "http://localhost:3000/api/v1/analyze_screenshot")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"

    let boundary = "Boundary-\(UUID().uuidString)"
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

    // Add auth token
    if let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt.shared"),
       let token = sharedDefaults.string(forKey: "auth_token") {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    // Create multipart body
    var body = Data()
    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"screenshot\"; filename=\"screenshot.jpg\"\r\n".data(using: .utf8)!)
    body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
    body.append(imageData)
    body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

    request.httpBody = body

    URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
        if let data = data,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let screenshotId = json["screenshot_id"] as? String {
            // Now generate flirts based on screenshot
            self?.generateFlirtsForScreenshot(screenshotId)
        }
    }.resume()
}
```

## 🔴 ISSUE #3: Voice Cloning Missing Script Feature

### Current Problem
Voice recording exists but no way for user to read provided scripts.

### Required Changes
**File**: `iOS/Flirrt/Views/VoiceRecordingView.swift`
**Line**: After line 50 (in the VStack)

**Add**:
```swift
// Script selection section
VStack(alignment: .leading, spacing: 12) {
    Text("Read this script:")
        .font(.headline)
        .foregroundColor(.white)

    // Predefined scripts
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 12) {
            ForEach(voiceScripts, id: \.self) { script in
                Button(action: {
                    selectedScript = script
                }) {
                    Text(script.title)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedScript == script ? Color.pink : Color.gray.opacity(0.3))
                        .cornerRadius(15)
                }
            }
        }
    }

    // Script text display
    if let script = selectedScript {
        Text(script.text)
            .font(.body)
            .foregroundColor(.white)
            .padding()
            .background(Color.black.opacity(0.3))
            .cornerRadius(10)
    }

    // Background noise options
    HStack {
        Text("Background:")
        Picker("Background", selection: $backgroundNoise) {
            Text("None").tag("none")
            Text("Coffee Shop").tag("coffee")
            Text("Street").tag("street")
            Text("Office").tag("office")
        }
        .pickerStyle(SegmentedPickerStyle())
    }
}
.padding()
```

**Add Properties**:
```swift
@State private var selectedScript: VoiceScript?
@State private var backgroundNoise = "none"

private let voiceScripts = [
    VoiceScript(title: "Friendly", text: "Hi there! I noticed we have a lot in common. I love hiking and photography too. What's your favorite trail you've explored recently?"),
    VoiceScript(title: "Flirty", text: "Well hello gorgeous! Your smile just made my day. I have to know - what's the story behind that amazing photo?"),
    VoiceScript(title: "Funny", text: "Quick question: on a scale of 1 to 10, how much do you love dad jokes? Because I've got a million of them and I need to know if we're compatible!")
]

struct VoiceScript: Hashable {
    let title: String
    let text: String
}
```

## 🔴 ISSUE #4: Fresh Start Not Connected to Onboarding

### Current Problem
"Fresh" button should start onboarding flow with social network analysis.

### Required Fix
**File**: `iOS/FlirrtKeyboard/KeyboardViewController.swift`
**In flirrtFreshTapped() method**:

```swift
@objc private func flirrtFreshTapped() {
    guard hasFullAccess else {
        showFullAccessRequired()
        return
    }

    // Check if onboarding completed
    if let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt.shared"),
       !sharedDefaults.bool(forKey: "onboarding_completed") {
        // Signal main app to show onboarding
        sharedDefaults.set(true, forKey: "show_onboarding_request")
        sharedDefaults.synchronize()

        // Post notification to main app
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName("com.flirrt.show.onboarding" as CFString),
            nil, nil, true
        )

        // Show message to user
        showMessage("Please switch to Flirrt app to complete setup")
        return
    }

    // If onboarding complete, generate fresh suggestions
    generateFreshSuggestions()
}
```

**File**: `iOS/Flirrt/App/FlirrtApp.swift`
**Add Observer**:
```swift
.onAppear {
    // Listen for onboarding request from keyboard
    NotificationCenter.default.addObserver(
        forName: NSNotification.Name("com.flirrt.show.onboarding"),
        object: nil,
        queue: .main
    ) { _ in
        appCoordinator.showOnboarding = true
    }
}
```

## 🔧 BACKEND ENDPOINTS REFERENCE

### 1. Screenshot Analysis
```
POST /api/v1/analyze_screenshot
Headers:
  - Authorization: Bearer {token}
  - Content-Type: multipart/form-data
Body:
  - screenshot: (file)
  - context: (optional string)
Response:
  {
    "screenshot_id": "abc-123",
    "analysis": {...},
    "confidence": 0.95
  }
```

### 2. Generate Flirts
```
POST /api/v1/generate_flirts
Headers:
  - Authorization: Bearer {token}
  - Content-Type: application/json
Body:
  {
    "screenshot_id": "abc-123",
    "suggestion_type": "opener|response|continuation",
    "tone": "playful|witty|romantic|casual|bold"
  }
Response:
  {
    "suggestions": [
      {
        "id": "1",
        "text": "Hey there!",
        "confidence": 0.9,
        "tone": "playful"
      }
    ]
  }
```

## 🎯 TESTING CHECKLIST

After implementing fixes:

1. **Test Fresh Button**:
   - [ ] Tap Fresh in keyboard
   - [ ] Should see loading indicator
   - [ ] Should display 3 suggestions
   - [ ] Tapping suggestion inserts text

2. **Test Analyze Button**:
   - [ ] Take screenshot first
   - [ ] Open Messages within 60 seconds
   - [ ] Tap Analyze button
   - [ ] Should analyze screenshot
   - [ ] Should show relevant suggestions

3. **Test Voice Script**:
   - [ ] Open Voice tab
   - [ ] See script options
   - [ ] Select script
   - [ ] Record reading script
   - [ ] Submit for cloning

4. **Test Onboarding Flow**:
   - [ ] Clear app data
   - [ ] Tap Fresh button
   - [ ] Should redirect to main app
   - [ ] Complete onboarding
   - [ ] Return to keyboard
   - [ ] Fresh button now works

## ⚠️ IMPORTANT CONSTRAINTS

1. **Memory Limit**: Keyboard extension MUST stay under 60MB
2. **Network**: Extension needs App Groups for shared auth token
3. **Photos Access**: Requires Info.plist permission strings
4. **Background Processing**: Not allowed in keyboard extension

## 🚀 IMPLEMENTATION ORDER

1. Fix keyboard API calls (Issue #1) - PRIORITY 1
2. Add screenshot capture (Issue #2) - PRIORITY 2
3. Add voice scripts (Issue #3) - PRIORITY 3
4. Connect onboarding (Issue #4) - PRIORITY 4

Start with Issue #1 as it's blocking all functionality!