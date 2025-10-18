# Autonomous Build Guide for claude-code

**Objective:** Complete the Vibe8.AI iOS build autonomously without requiring manual GUI steps.

---

## Current Status

✅ **Completed:**
- `ContentView.swift` updated to use `EnhancedScreenshotAnalysisView`
- `AppCoordinator.swift` updated to use `ModernOnboardingView`
- API client methods verified

⚠️ **Remaining:** Add 4 new Swift files to Xcode project

---

## Option 1: Programmatic Addition (Recommended)

Use the Ruby script to add files programmatically:

```bash
# Install xcodeproj gem if not already installed
gem install xcodeproj

# Run the script to add files
ruby add_files_to_xcode.rb
```

This will automatically add all 4 new Swift files to the Xcode project and target.

---

## Option 2: Manual Addition via Xcode GUI

If Option 1 fails, use Xcode GUI:

1. Open `iOS/Flirrt.xcodeproj` in Xcode
2. Right-click "Views" folder → "Add Files to 'Flirrt'..."
3. Select all 4 files:
   - `EnhancedScreenshotAnalysisView.swift`
   - `ModernOnboardingView.swift`
   - `MultiScreenshotPicker.swift`
   - `VoicePlaybackView.swift`
4. Check "Copy items if needed" and ensure "Flirrt" target is selected
5. Click "Add"

---

## Build & Test

After adding files:

```bash
# Clean build folder
xcodebuild clean -project iOS/Flirrt.xcodeproj -scheme Flirrt

# Build the app
xcodebuild -project iOS/Flirrt.xcodeproj -scheme Flirrt -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15'

# If successful, run on simulator
open -a Simulator
xcodebuild -project iOS/Flirrt.xcodeproj -scheme Flirrt -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15' -derivedDataPath ./build
```

---

## Troubleshooting

### If build fails with "file not found":
- Verify files exist: `ls -la iOS/Flirrt/Views/*.swift`
- Re-run the Ruby script

### If Ruby script fails:
- Check if xcodeproj gem is installed: `gem list xcodeproj`
- Install if missing: `gem install xcodeproj`
- Fall back to Option 2 (manual GUI)

### If compilation errors occur:
- Check that all environment objects are properly passed
- Verify import statements in new files
- Look for missing model definitions (e.g., `FlirtSuggestion`)

---

## Success Criteria

✅ All 4 files added to Xcode project  
✅ Build completes without errors  
✅ App launches on simulator  
✅ Onboarding flow displays correctly  

Report back with build status and any errors encountered.

