# Vibe8.AI - iOS Frontend Build Instructions for claude-code

**Objective:** Integrate the new UI/UX features into the Vibe8.AI iOS app to create a production-ready frontend. This guide provides all necessary steps to update the codebase, add new features, and prepare for testing.

---

## 1. File Inventory

The following new Swift files have been created and are ready for integration:

- `iOS/Flirrt/Views/MultiScreenshotPicker.swift`: A reusable component for selecting 1-3 screenshots from the user's photo library.
- `iOS/Flirrt/Views/EnhancedScreenshotAnalysisView.swift`: A complete redesign of the main analysis screen, incorporating multi-screenshot selection, a tone selector, refresh functionality, and AI coaching display.
- `iOS/Flirrt/Views/VoicePlaybackView.swift`: A UI component for generating and playing back voice messages with a modern audio player interface.
- `iOS/Flirrt/Views/ModernOnboardingView.swift`: A new, interactive onboarding flow to introduce users to the app's features.

---


## 2. Integration Steps

Follow these steps to integrate the new features into the existing Xcode project.

### Step 1: Add New Files to Xcode Project

1.  **Open the Xcode project:** `Flirrt-screens-shots-v1/iOS/Flirrt.xcodeproj`.
2.  **Drag and drop** the four new Swift files (`MultiScreenshotPicker.swift`, `EnhancedScreenshotAnalysisView.swift`, `VoicePlaybackView.swift`, `ModernOnboardingView.swift`) into the `Views` folder in the Xcode project navigator.
3.  **Ensure** that all files are added to the `Flirrt` target.

### Step 2: Replace `ScreenshotAnalysisView` with `EnhancedScreenshotAnalysisView`

1.  In `ContentView.swift`, replace the existing call to `ScreenshotAnalysisView` with `EnhancedScreenshotAnalysisView`.

    ```swift
    // In ContentView.swift
    .sheet(isPresented: $screenshotManager.showAnalysisSheet) {
        EnhancedScreenshotAnalysisView()
            .environmentObject(apiClient)
            .environmentObject(screenshotManager)
    }
    ```

### Step 3: Implement the New Onboarding Flow

1.  In `FlirrtApp.swift`, modify the main view to show `ModernOnboardingView` if the user has not completed onboarding.

    ```swift
    // In FlirrtApp.swift
    import SwiftUI

    @main
    struct FlirrtApp: App {
        @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

        var body: some Scene {
            WindowGroup {
                if hasCompletedOnboarding {
                    ContentView()
                } else {
                    ModernOnboardingView()
                }
            }
        }
    }
    ```

### Step 4: Update `APIClient` for New Endpoints

1.  Ensure that `APIClient.swift` has the necessary methods to support the new features:
    -   `generateFlirtsFromMultipleImages(...)`: To handle multi-screenshot analysis.
    -   `synthesizeVoice(...)`: To generate voice messages.

    The existing backend is already configured for these endpoints, so you just need to ensure the frontend client matches.

---


## 3. Testing & Validation

After integrating the new features, perform the following tests to ensure everything is working correctly.

### Test 1: Onboarding Flow

1.  **Launch the app** for the first time.
2.  **Verify** that the `ModernOnboardingView` is displayed.
3.  **Swipe through** all onboarding pages.
4.  **Tap "Get Started"** on the final page.
5.  **Confirm** that the main `ContentView` is displayed and that the onboarding screen does not appear on subsequent launches.

### Test 2: Multi-Screenshot Analysis

1.  From the main screen, tap **"Select Screenshots"**.
2.  **Select 2-3 screenshots** from the photo library.
3.  **Verify** that the selected screenshots are displayed in the preview grid.
4.  **Select a tone** (e.g., "Witty").
5.  Tap **"Generate Flirts"**.
6.  **Confirm** that 3 flirt suggestions are displayed.

### Test 3: Refresh and Coaching

1.  After getting suggestions, tap the **"New Vibes"** refresh button.
2.  **Verify** that 3 new, different suggestions are displayed.
3.  For each suggestion, tap **"Why This Works"**.
4.  **Confirm** that the AI coaching/reasoning is displayed and is relevant to the suggestion.

### Test 4: Voice Cloning

1.  In the suggestion card, tap the **"Voice"** button.
2.  **Verify** that the `VoicePlaybackView` is displayed as a sheet.
3.  Tap **"Generate Voice Message"**.
4.  **Confirm** that the audio player UI appears and that the voice message plays automatically.
5.  **Test** the play/pause, rewind, and forward controls.

---

## 4. Final Build

Once all tests have passed, create a new build of the app and prepare it for TestFlight distribution. This will be the version used for final user testing before submitting to the App Store.

**This concludes the build instructions. Let me know if you have any questions.**

