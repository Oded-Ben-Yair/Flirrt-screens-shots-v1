# 🧪 TEST SCENARIOS - FLIRRT.AI

## 📋 Test Environment Setup

### Prerequisites
```bash
# 1. Start backend server
cd Backend
npm start

# 2. Open another terminal to watch logs
tail -f Backend/server.log

# 3. Boot simulator
xcrun simctl boot 237F6A2D-72E4-49C2-B5E0-7B3F973C6814

# 4. Build and install app
cd ..
xcodebuild -project FlirrtXcode.xcodeproj -scheme Flirrt \
  -destination 'platform=iOS Simulator,id=237F6A2D-72E4-49C2-B5E0-7B3F973C6814' \
  clean build install
```

## 🔴 CURRENT STATE (BROKEN)
User testing on 2025-09-23 revealed:
- Fresh button: Nothing happens when tapped
- Analyze button: Nothing happens when tapped
- Screenshots: Don't trigger keyboard activation
- Voice: No script reading interface
- Onboarding: Not connected to Fresh button

## ✅ EXPECTED STATE (AFTER FIXES)

### Test Scenario 1: Fresh Button Functionality

#### Steps:
1. Open Messages app in simulator
2. Tap text field to show keyboard
3. Switch to Flirrt keyboard (globe icon)
4. Tap "🔥 Fresh" button

#### Expected Results:
- ✅ Loading indicator appears immediately
- ✅ Backend log shows: `POST /api/v1/generate_flirts`
- ✅ 3 suggestion cards appear within 2 seconds
- ✅ Each card shows flirt text
- ✅ Tapping a card inserts text into message field

#### Backend Log Pattern:
```
[2025-09-23T10:00:00] POST /api/v1/generate_flirts
Body: {"screenshot_id":"fresh-1695465600","suggestion_type":"opener","tone":"playful"}
[2025-09-23T10:00:01] Grok API called successfully
[2025-09-23T10:00:01] Response sent: 3 suggestions
```

#### Failure Indicators:
- ❌ No loading indicator
- ❌ No backend log entry
- ❌ Default/hardcoded suggestions appear
- ❌ Error message displayed

---

### Test Scenario 2: Screenshot Auto-Analysis

#### Setup:
1. Open Safari or any app with content
2. Take a screenshot (Volume Up + Power)
3. Immediately (within 60 seconds) open Messages

#### Steps:
1. Switch to Flirrt keyboard
2. Wait 2-3 seconds

#### Expected Results:
- ✅ Keyboard automatically shows "Analyzing screenshot..."
- ✅ Backend logs show screenshot upload
- ✅ Backend logs show analysis request
- ✅ Context-aware suggestions appear
- ✅ Suggestions relate to screenshot content

#### Backend Log Pattern:
```
[2025-09-23T10:01:00] POST /api/v1/analyze_screenshot
[2025-09-23T10:01:00] File received: screenshot.jpg (2.3MB)
[2025-09-23T10:01:01] Grok Vision API called
[2025-09-23T10:01:02] Analysis complete: screenshot_id=scr-abc123
[2025-09-23T10:01:02] POST /api/v1/generate_flirts
[2025-09-23T10:01:03] Generated 3 context-aware suggestions
```

#### Failure Indicators:
- ❌ No automatic analysis
- ❌ Permission denied for photos
- ❌ No backend activity
- ❌ Generic suggestions instead of context-aware

---

### Test Scenario 3: Manual Analyze Button

#### Steps:
1. Take a screenshot of a dating profile
2. Open Messages app
3. Switch to Flirrt keyboard
4. Tap "🔍 Analyze" button

#### Expected Results:
- ✅ Photo library permission request (first time)
- ✅ Latest screenshot is selected automatically
- ✅ Upload progress indicator
- ✅ Analysis results in 2-4 seconds
- ✅ Suggestions match the profile content

#### Validation Points:
- Screenshot must be less than 60 seconds old
- File size must be under 10MB
- Must have "Allow Full Access" enabled

---

### Test Scenario 4: Voice Cloning with Scripts

#### Steps:
1. Open main Flirrt app
2. Navigate to Voice tab
3. Select "Flirty" script tone
4. Read displayed script aloud
5. Toggle "Add Background Ambience" ON
6. Press record for 30 seconds
7. Stop and submit recording

#### Expected Results:
- ✅ Script text clearly visible
- ✅ Recording timer shows progress
- ✅ Submit button enabled after recording
- ✅ Backend receives audio file
- ✅ Backend logs show script_tone="Flirty"
- ✅ Backend logs show include_background=true
- ✅ Success message displayed

#### Backend Log Pattern:
```
[2025-09-23T10:02:00] POST /api/v1/voice/clone
[2025-09-23T10:02:00] Audio file received: 1.2MB
[2025-09-23T10:02:00] Script tone: Flirty
[2025-09-23T10:02:00] Background noise: true
[2025-09-23T10:02:01] ElevenLabs API called
[2025-09-23T10:02:05] Voice clone created: voice-xyz789
```

---

### Test Scenario 5: First-Time Onboarding Flow

#### Setup:
```bash
# Reset app data
xcrun simctl uninstall booted com.flirrt.app
# Reinstall
xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/Flirrt.app
```

#### Steps:
1. Open Messages app
2. Switch to Flirrt keyboard
3. Tap "Fresh" button (as first-time user)

#### Expected Results:
- ✅ Alert: "Please open Flirrt app to complete setup"
- ✅ Shared UserDefaults flag set
- ✅ Opening main app shows onboarding
- ✅ Onboarding has 4 screens
- ✅ Can complete questionnaire
- ✅ After completion, keyboard Fresh button works

#### Validation:
```bash
# Check shared defaults
xcrun simctl spawn booted defaults read group.com.flirrt.shared
# Should show: has_completed_onboarding = 1
```

---

## 🔍 BACKEND MONITORING

### Commands to Monitor
```bash
# Watch all API calls
tail -f Backend/server.log | grep "POST\|GET"

# Watch only flirt generation
tail -f Backend/server.log | grep "generate_flirts"

# Watch errors only
tail -f Backend/server.log | grep "ERROR\|error"

# Check server health
curl http://localhost:3000/health
```

### Expected Backend Activity
1. **Fresh Button**: 1 API call to `/generate_flirts`
2. **Screenshot**: 2 API calls - `/analyze_screenshot` then `/generate_flirts`
3. **Voice Clone**: 1 API call to `/voice/clone`
4. **Onboarding**: No API calls (local only)

---

## 📱 SIMULATOR VALIDATION

### Check Keyboard Installation
```bash
# List installed keyboards
xcrun simctl spawn booted defaults read com.apple.Preferences | grep -A5 keyboard

# Check if Flirrt keyboard is enabled
xcrun simctl spawn booted defaults read com.apple.Preferences | grep "com.flirrt"
```

### Check App Groups
```bash
# Verify shared container exists
xcrun simctl spawn booted ls /Users/$(whoami)/Library/Developer/CoreSimulator/Devices/237F6A2D-72E4-49C2-B5E0-7B3F973C6814/data/Containers/Shared/AppGroup/

# Check shared UserDefaults
xcrun simctl spawn booted defaults read group.com.flirrt.shared
```

---

## 🐛 DEBUGGING FAILURES

### If Fresh Button Doesn't Work:
1. Check backend is running: `curl http://localhost:3000/health`
2. Check keyboard has Full Access enabled
3. Check auth token in shared UserDefaults
4. Check backend logs for incoming requests
5. Use Safari Developer Tools to inspect network

### If Screenshot Analysis Fails:
1. Check Photos permission granted
2. Verify screenshot is < 60 seconds old
3. Check file size < 10MB
4. Verify multipart form data format
5. Check Grok API key is valid

### If Voice Recording Fails:
1. Check microphone permission
2. Verify audio format is M4A
3. Check file size < 5MB
4. Verify ElevenLabs API key
5. Check network connectivity

---

## 🎯 ACCEPTANCE CRITERIA

### Must Pass (P0):
- [ ] Fresh button generates suggestions from backend
- [ ] Analyze button processes screenshots
- [ ] Suggestions can be inserted into text field
- [ ] Backend logs show all API calls

### Should Pass (P1):
- [ ] Screenshot auto-triggers within 60 seconds
- [ ] Voice recording with scripts works
- [ ] Onboarding flow connects to Fresh button
- [ ] Error messages display appropriately

### Nice to Have (P2):
- [ ] Offline fallback suggestions
- [ ] Suggestion caching
- [ ] Voice synthesis playback
- [ ] Preference persistence

---

## 🚀 AUTOMATED TESTING

### Run Full Test Suite
```bash
cd Agents
node SimulatorTestAgent.js --full-test
```

### Expected Output:
```
=== Flirrt.ai Test Report ===
✅ App Installation: PASSED
✅ Keyboard Registration: PASSED
✅ Fresh Button API: PASSED
✅ Screenshot Analysis: PASSED
✅ Voice Recording: PASSED
✅ Onboarding Flow: PASSED

Total: 6/6 tests passed
Time: 45 seconds
```

### Manual Verification Checklist:
- [ ] User can see Flirrt keyboard in settings
- [ ] Keyboard appears when switching input methods
- [ ] Fresh button visually responds to tap
- [ ] Loading states appear during API calls
- [ ] Suggestions animate in smoothly
- [ ] Error states are user-friendly
- [ ] Voice scripts are readable
- [ ] Onboarding is intuitive

---

## 📊 PERFORMANCE BENCHMARKS

### Expected Response Times:
- Fresh suggestions: < 2 seconds
- Screenshot analysis: < 4 seconds
- Voice clone: < 10 seconds
- Keyboard launch: < 500ms
- Suggestion insertion: Instant

### Memory Limits:
- Keyboard extension: < 60MB
- Main app: < 200MB
- Backend server: < 512MB

---

## 📝 TEST REPORT TEMPLATE

```markdown
## Test Run: [DATE]

### Environment:
- iOS Version: 18.6
- Simulator: iPhone 16 Pro
- Backend: Running on localhost:3000
- Tester: [Name]

### Results:

| Test | Status | Notes |
|------|--------|-------|
| Fresh Button | ✅/❌ | [Details] |
| Screenshot Auto | ✅/❌ | [Details] |
| Analyze Button | ✅/❌ | [Details] |
| Voice Scripts | ✅/❌ | [Details] |
| Onboarding | ✅/❌ | [Details] |

### Issues Found:
1. [Issue description]
2. [Issue description]

### Backend Logs:
```
[Paste relevant logs]
```

### Screenshots:
[Attach any relevant screenshots]
```

---

## ⚡ QUICK VALIDATION

For rapid testing after fixes:
```bash
# Quick test script
curl -X POST http://localhost:3000/api/v1/generate_flirts \
  -H "Authorization: Bearer test-token" \
  -H "Content-Type: application/json" \
  -d '{"screenshot_id":"test-123","suggestion_type":"opener","tone":"playful"}'

# Should return 3 suggestions
# If it works, the keyboard should too!
```