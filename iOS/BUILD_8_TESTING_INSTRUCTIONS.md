# Build 8 Testing Instructions

**Date**: 2025-10-23  
**Build Number**: 8  
**Version**: 1.0 (8)  
**Status**: Uploaded to TestFlight - Processing

---

## Critical Fixes in Build 8

### 1. App Groups Mismatch (ROOT CAUSE FIX)
**Problem**: Code was writing to `group.com.vibe8` but entitlements used `group.com.flirrt`
**Fix**: Updated all 6 files to use consistent `group.com.flirrt` identifier
**Impact**: Main app and keyboard extension can now communicate properly

**Files Fixed**:
- AppConstants.swift:19
- VoiceService.swift:19
- ScreenshotCaptureService.swift:11
- EnhancedKeyboardViewController.swift:11
- PersonalizationView.swift:9-15
- CP6ComprehensiveTests.swift:139

### 2. Background Screenshot Detection (WORKFLOW FIX)
**Problem**: Screenshots taken while keyboard is open (app backgrounded) weren't being processed
**Fix**: Added automatic background screenshot detection when app returns to foreground
**Impact**: Screenshots taken during keyboard usage are now automatically processed

**New Feature**: `checkForBackgroundScreenshots()` in ScreenshotDetectionManager.swift:289-428
- Checks Photos library when app becomes active
- Processes screenshots taken within last 30 minutes while app was backgrounded
- Maintains same API call + App Groups flow

---

## Testing Workflow

### Critical Test: Screenshot While Keyboard Open

This is the exact workflow that was failing before:

**Steps**:
1. Open Flirrt app
2. Sign in with Apple (if needed)
3. Open any dating app (Tinder, Bumble, Hinge, etc.)
4. Open keyboard → Flirrt app goes to background
5. Take screenshot of dating profile
6. Return to Flirrt app
7. App should automatically detect and process the screenshot
8. Return to keyboard
9. Keyboard should show suggestions

**Expected Behavior**:
- Screenshot analyzed within 2-5 seconds
- 3-5 suggestions appear in keyboard
- Backend logs show `/api/v1/flirts` call with `Flirrt/8` user agent
- No errors in Xcode console

**Previous Behavior (Build 2)**:
- Screenshot not detected (app suspended)
- No suggestions appeared
- Zero `/api/v1/flirts` calls

---

## Complete Test Scenarios

### Scenario 1: Fresh Install

**Pre-requisites**: Delete app if installed

**Steps**:
1. Install from TestFlight
2. Launch app
3. Grant Photo Library permission when prompted
4. Sign in with Apple
5. Take a screenshot of any dating profile
6. Return to app
7. Check for automatic analysis

**Expected**:
- Photos permission prompt appears
- Apple sign-in succeeds
- Screenshot processed automatically
- Suggestions saved to App Groups
- Console logs show success

### Scenario 2: Keyboard Integration

**Steps**:
1. Open Settings → General → Keyboard → Keyboards
2. Add "Flirrt" keyboard
3. Grant Full Access when prompted
4. Open any messaging app
5. Switch to Flirrt keyboard
6. Take screenshot (app backgrounds)
7. Return to Flirrt app (foreground)
8. Switch back to keyboard

**Expected**:
- Keyboard added successfully
- Full Access enabled
- Screenshot detected when app returns to foreground
- Suggestions appear in keyboard toolbar
- Can tap to insert suggestion

### Scenario 3: Multiple Screenshots (Session Continuity)

**Steps**:
1. Take screenshot of profile
2. Wait for processing
3. Take screenshot of chat conversation
4. Wait for processing
5. Take screenshot of another profile
6. Check session metadata in console

**Expected**:
- All 3 screenshots processed
- Same session ID maintained (30-min window)
- Screenshot count increments: 1 → 2 → 3
- Context maintained across screenshots
- Quality level tracked

### Scenario 4: Session Timeout

**Steps**:
1. Take screenshot and process
2. Note session ID in console logs
3. Wait 31 minutes
4. Return to app
5. Take another screenshot

**Expected**:
- New session ID created after timeout
- Screenshot count resets to 1
- Previous session expired log message
- Fresh analysis without old context

### Scenario 5: Background → Foreground Cycle

**Steps**:
1. Launch Flirrt
2. Open another app (Flirrt backgrounds)
3. Take 2 screenshots of dating profiles
4. Return to Flirrt (becomes active)
5. Observe automatic processing

**Expected**:
- Console shows: "Looking for screenshots taken in last Xs while app was backgrounded"
- Console shows: "Found 2 screenshot(s) taken while app was backgrounded!"
- Both screenshots processed automatically
- Both saved to App Groups with session metadata

---

## Monitoring & Verification

### Xcode Console Logs (Key Messages)

**App Launch**:
```
✅ Screenshot detection enabled
📝 Loaded active session: session_xxxxx
```

**Background Screenshots Detected**:
```
🔍 Checking for screenshots taken while app was backgrounded
📸 Looking for screenshots taken in last 45s while app was backgrounded
🎯 Found 1 screenshot(s) taken while app was backgrounded!
📸 Processing background screenshot 1/1 - ID: screenshot_xxxxx
```

**Screenshot Processing**:
```
📸 Screenshot processed: 123456 bytes (compressed from ~789012 bytes)
✅ Shared 3 suggestions + session metadata (count: 2, quality: high)
📢 Posted Darwin notification to keyboard
```

**Session Management**:
```
✨ Created new conversation session: session_xxxxx
⏰ Session expired (35 minutes ago)
🔄 Started new conversation
```

### Backend Logs (Render.com)

**Expected Requests**:
```
[POST] 200 /api/v1/auth/validate
userAgent="Flirrt/8 CFNetwork/1568.300.101 Darwin/24.2.0"

[POST] 200 /api/v1/flirts
userAgent="Flirrt/8 CFNetwork/1568.300.101 Darwin/24.2.0"
conversationID="session_xxxxx"
```

**Key Indicators**:
- User agent shows `Flirrt/8` (not Flirrt/7)
- `/api/v1/flirts` endpoint being called
- `conversationID` parameter present
- 200 status codes

### TestFlight Feedback

**Request Testers Report**:
- Screenshot taken while keyboard was open → Did suggestions appear?
- Number of screenshots tested
- Any error messages or crashes
- Keyboard suggestion quality
- Overall app responsiveness

---

## Known Issues & Limitations

### iOS Restrictions
- Keyboard extensions cannot access Photos library directly (Apple limitation)
- Screenshots MUST be processed in main app first
- App Groups used for communication between app and keyboard

### Timing Considerations
- Background screenshot check runs when app becomes active
- 30-second recency check for new screenshots
- 30-minute session timeout for conversation context
- Duplicate screenshot prevention via local identifier tracking

### Network Requirements
- HTTPS connection to backend required
- Backend must be running at production URL
- API keys must be valid (Grok, ElevenLabs, Gemini)

---

## Rollback Plan

If Build 8 has critical issues:

1. **Immediate**: Remove from TestFlight external testing
2. **Revert**: Use git to revert to last stable commit:
   ```bash
   git log --oneline -10
   git revert <commit-hash>
   ```
3. **Notify**: Alert all beta testers via TestFlight
4. **Investigate**: Collect crash logs and console output
5. **Fix**: Address issues in new build

---

## Success Criteria

Build 8 is successful if:

- [ ] Screenshot analysis triggers when taken with keyboard open
- [ ] Backend logs show `/api/v1/flirts` calls with `Flirrt/8`
- [ ] Keyboard displays suggestions after screenshot
- [ ] No crashes during 5+ screenshot workflow
- [ ] Session continuity maintained across multiple screenshots
- [ ] Background detection console logs appear correctly
- [ ] App Groups communication working (keyboard reads suggestions)
- [ ] TestFlight processing completes without warnings

---

## Next Steps After Testing

### If Successful:
1. Invite 10+ external beta testers
2. Collect feedback for 1-2 weeks
3. Monitor backend logs and crash reports
4. Address any minor bugs in Build 9
5. Prepare App Store submission materials

### If Issues Found:
1. Document exact reproduction steps
2. Collect Xcode console logs
3. Capture backend logs from Render
4. Create new build with fixes
5. Re-test before wider distribution

---

## Contact & Support

**Backend**: https://flirrt-api-production.onrender.com
**GitHub**: https://github.com/Oded-Ben-Yair/Flirrt-screens-shots-v1
**Branch**: main
**Build**: 8

**Key Files**:
- `iOS/Flirrt/Services/ScreenshotDetectionManager.swift:289-428` (Background detection)
- `iOS/Flirrt/Config/AppConstants.swift:19` (App Group ID)
- `iOS/Flirrt/Info.plist:24` (Build number)

---

**Generated**: 2025-10-23 by Claude Code
**Build Upload**: Successful ✅
**TestFlight Status**: Processing (check App Store Connect)
