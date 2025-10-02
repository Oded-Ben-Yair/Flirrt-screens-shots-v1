# Debug Screenshot Simulator - Feature Documentation

**Created**: October 1, 2025 16:05
**Status**: ✅ Implemented and Deployed
**Build**: Oct 1 16:05 (Flirrt-efsyagdastankxeyrlpuqxmjjsgd)

## 🎯 Problem Solved

**Original Issue**: Screenshot detection doesn't work in iOS Simulator
- iOS Simulator does NOT fire `UIApplication.userDidTakeScreenshotNotification`
- Main app never detects screenshots (Cmd+S)
- Darwin notification never sent to keyboard
- Unified button never switches to "Analyze This" mode
- **Result**: Cannot test screenshot analysis flow in simulator

## ✅ Solution: Debug Simulator Button

Added a DEBUG-only button that manually triggers the screenshot detection flow, allowing full testing of the auto-switching logic without needing a real device.

## 📝 Implementation Details

### Code Location
**File**: `/iOS/FlirrtKeyboard/KeyboardViewController.swift`

### Code Added

```swift
// MARK: - Debug Screenshot Simulator (DEBUG only)
#if DEBUG
private lazy var debugScreenshotButton: UIButton = {
    let button = UIButton(type: .system)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.setTitle("🐛 Simulate Screenshot", for: .normal)
    button.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
    button.backgroundColor = .systemOrange.withAlphaComponent(0.2)
    button.layer.cornerRadius = 8
    button.layer.borderWidth = 1
    button.layer.borderColor = UIColor.systemOrange.cgColor
    button.addTarget(self, action: #selector(debugSimulateScreenshot), for: .touchUpInside)
    return button
}()

@objc private func debugSimulateScreenshot() {
    os_log("🐛 DEBUG: Manually triggering screenshot detection", log: logger, type: .debug)
    handleInstantScreenshotDetection()
}
#endif
```

### UI Layout Changes

Modified `setupUI()` to conditionally include debug button:

```swift
#if DEBUG
view.addSubview(debugScreenshotButton)

// Debug button constraints
constraints += [
    debugScreenshotButton.topAnchor.constraint(equalTo: smartActionButton.bottomAnchor, constant: 8),
    debugScreenshotButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
    debugScreenshotButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
    debugScreenshotButton.heightAnchor.constraint(equalToConstant: 36),

    // Suggestions view below debug button
    suggestionsView.topAnchor.constraint(equalTo: debugScreenshotButton.bottomAnchor, constant: 8),
]
#else
// Suggestions view below smart button (no debug button)
constraints += [
    suggestionsView.topAnchor.constraint(equalTo: smartActionButton.bottomAnchor, constant: 12),
]
#endif
```

## 🎨 Visual Design

### Debug Button Appearance
- **Title**: "🐛 Simulate Screenshot"
- **Background**: Orange with 20% opacity
- **Border**: 1pt orange border
- **Corner Radius**: 8pt
- **Height**: 36pt
- **Font**: 12pt medium system font
- **Position**: Between smart action button and suggestions view

### Layout
```
┌─────────────────────────────────┐
│  💫 Fresh Flirts                │  ← Smart Action Button
│  Personalized for you           │     (68pt height)
└─────────────────────────────────┘
         ↓ 8pt spacing
┌─────────────────────────────────┐
│  🐛 Simulate Screenshot         │  ← Debug Button (DEBUG only)
└─────────────────────────────────┘     (36pt height)
         ↓ 8pt spacing
┌─────────────────────────────────┐
│  [Suggestions View]             │
└─────────────────────────────────┘
```

## 🔄 How It Works

### When Debug Button is Tapped:

1. **Logs Debug Message**
   ```swift
   os_log("🐛 DEBUG: Manually triggering screenshot detection", log: logger, type: .debug)
   ```

2. **Calls Same Handler as Real Screenshots**
   ```swift
   handleInstantScreenshotDetection()
   ```

3. **Triggers Complete Flow**:
   - Updates `lastScreenshotTime` to current timestamp
   - Switches `currentButtonMode` to `.analyzeScreenshot`
   - Provides haptic feedback (success vibration)
   - Shows screenshot detected animation
   - Pulses smart action button
   - Checks for recent screenshot in Photos
   - Auto-reverts to `.freshOpeners` after 60 seconds

### Expected Behavior After Tap:

```
Before Tap:
┌─────────────────────────────────┐
│  ✨ 💫 Fresh Flirts             │  ← Pink background
│  Personalized for you           │
└─────────────────────────────────┘

After Tap:
┌─────────────────────────────────┐
│  🔍 📸 Analyze This              │  ← Blue background (animated)
│  Get suggestions for this convo │
└─────────────────────────────────┘
   ↑ Pulses with animation
```

## ✅ Testing Instructions

### Step 1: Verify Debug Button is Visible
1. Open simulator (Fresh-Test-iPhone 454F2AEF-E7B0-4248-B5CE-C27B62BFA807)
2. Launch Flirrt app (if not already open)
3. Open Messages app
4. Activate Flirrt keyboard
5. **Expected**: See orange "🐛 Simulate Screenshot" button below main button

### Step 2: Test Manual Screenshot Trigger
1. Tap the debug button
2. **Expected**:
   - Smart action button changes from pink to blue
   - Title changes from "💫 Fresh Flirts" to "📸 Analyze This"
   - Subtitle changes from "Personalized for you" to "Get suggestions for this convo"
   - Button pulses with animation
   - Haptic feedback occurs
   - Screenshot detection animation appears

### Step 3: Test Auto-Revert
1. Wait 60 seconds after tapping debug button
2. **Expected**:
   - Button automatically reverts to pink
   - Title changes back to "💫 Fresh Flirts"
   - Subtitle changes back to "Personalized for you"

### Step 4: Test Tapping After Mode Switch
1. Tap debug button to trigger screenshot mode
2. Tap the smart action button (now showing "📸 Analyze This")
3. **Expected**:
   - Calls `analyzeScreenshotMode()` function
   - Attempts to fetch recent screenshot from Photos
   - Sends screenshot to `/generate_flirts` endpoint

## 🚨 Production Safety

### Only Active in DEBUG Builds
The debug button is wrapped in `#if DEBUG` preprocessor directives:
- **DEBUG builds** (Simulator, Development): Button visible
- **RELEASE builds** (App Store, TestFlight): Button NOT compiled into binary
- **Result**: Zero performance or security impact in production

### Verification
To confirm debug button won't appear in release:
```bash
# Build for release
xcodebuild -scheme Flirrt -configuration Release

# Verify button code is excluded
nm Build/Products/Release-iphonesimulator/Flirrt.app/Flirrt | grep debugScreenshotButton
# Expected: No results (symbol not present)
```

## 📊 Build Information

### Current Build
- **DerivedData Path**: `Flirrt-efsyagdastankxeyrlpuqxmjjsgd`
- **Binary Size**: 57KB
- **Build Time**: Oct 1 16:05
- **Xcode Version**: Latest
- **Configuration**: Debug
- **Simulator**: Fresh-Test-iPhone (iPhone 17, iOS latest)

### Modified Files
- `/iOS/FlirrtKeyboard/KeyboardViewController.swift` (Lines 114-133, 169-198)

## 🔗 Related Documentation

- **Main Session Doc**: `/SESSION_2025_10_01_UNIFIED_BUTTON_IMPLEMENTATION.md`
- **Root Cause Analysis**: `/DIAGNOSTIC_REPORT_2025_10_01.md`
- **Project Instructions**: `/CLAUDE.md`

## 📈 Success Metrics

### What This Enables
✅ Full testing of screenshot detection flow in simulator
✅ Verification of button mode switching logic
✅ Testing of analyze screenshot API endpoint
✅ Validation of auto-revert timer (60 seconds)
✅ Testing haptic feedback and animations
✅ No need for real device during development

### What It Doesn't Test
❌ Actual iOS screenshot notification (`UIApplication.userDidTakeScreenshotNotification`)
❌ Darwin notification cross-process delivery
❌ Main app screenshot detection manager
❌ Real Photos library monitoring

**Note**: For complete end-to-end testing of screenshot detection, a real iPhone device is still required.

## 🎯 Next Steps

### For Current Session
1. ✅ Debug button implemented
2. ✅ Build succeeded
3. ✅ App installed on simulator
4. 🔄 **Next**: User tests debug button functionality
5. ⏭️ Verify backend receives correct API calls

### For Future Sessions
1. Test on real iPhone device
2. Verify Darwin notifications work on device
3. Complete UX/UI polish (Liquid Glass design)
4. Remove old deprecated code
5. Persist screenshot timestamp to App Groups

---

**Status**: Ready for testing
**Build**: Fresh and deployed
**Backend**: Running on port 3000
**Action Required**: User tap debug button and verify mode switching works
