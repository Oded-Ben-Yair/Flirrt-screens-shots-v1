# Known Issues & Workarounds

Current bugs, limitations, and their workarounds for FlirrtAI.

**Last Updated**: October 2025

---

## 🎯 NEXT SESSION PRIORITIES

**START HERE** - These are the debugging priorities for the next session:

### PRIORITY 1: Test This Session's Work (CRITICAL)
**Goal**: Validate cleanup actually works - build app, test UI, verify memory improvements

**Tasks**:
1. Build iOS app: `cd iOS && xcodebuild -scheme Flirrt build`
2. Launch in simulator and verify "How to Use" guide appears (not placeholder buttons)
3. Test "Open Keyboard Settings" button works (deep-link)
4. Enable keyboard and monitor memory usage (should stay <40MB, target <30MB)

**Success Criteria**: App builds without errors, UI displays correctly, memory under target

---

### PRIORITY 2: Debug Screenshot Detection (CRITICAL)
**Goal**: Find where Darwin notification chain breaks

**Current Issue**: Darwin notifications not reaching keyboard extension reliably

**Debug Steps**:
1. Add logging to `FlirrtApp.swift` screenshot detection (~line 50)
2. Add logging to `KeyboardViewController.swift` Darwin notification receiver (~line 1710)
3. Take screenshot in simulator (Cmd+S)
4. Check Xcode console - identify where notification chain breaks
5. Fix notification posting or receiving code

**Expected Flow**:
```
Screenshot taken
→ UIApplication.userDidTakeScreenshotNotification
→ Main app receives notification
→ Posts Darwin notification "com.flirrt.screenshot.detected"
→ Keyboard receives Darwin notification
→ Switches button to "Analyze" mode
```

**Success Criteria**: Screenshot triggers "Analyze" button in keyboard every time

---

### PRIORITY 3: Fix Keyboard-Backend API (HIGH)
**Goal**: Eliminate "Network unavailable" errors

**Current Issue**: Keyboard can't reach backend API reliably

**Debug Steps**:
1. Start backend: `cd Backend && npm start`
2. Test health: `curl http://localhost:3000/health`
3. Check keyboard URL configuration in `KeyboardViewController.swift`
4. Verify "Allow Full Access" is enabled in Settings
5. Test with both localhost and Mac IP address
6. Check URLSession configuration and timeout settings

**Success Criteria**: Keyboard receives suggestions from backend successfully

---

## 🔴 Critical Issues

### Screenshot Detection Not Triggering
**Problem:** Taking a screenshot in Messages/Tinder doesn't trigger analysis in keyboard

**Root Cause:** Darwin notification not reaching keyboard extension reliably

**Symptoms:**
- Screenshot is taken but keyboard button doesn't switch to "Analyze" mode
- No visual feedback in keyboard after screenshot
- Analysis doesn't start automatically

**Workaround:**
1. Use the "Fresh Flirts" button to get generic suggestions
2. Manually trigger analysis (when implemented)

**Fix Status:** In progress - requires Darwin notification debugging

---

### Keyboard API Integration Incomplete
**Problem:** Keyboard makes API calls to backend but gets timeout/connection errors

**Symptoms:**
- "Network unavailable" or "Request timed out" messages
- Suggestions don't appear after button press
- Console shows: "Error: connect ECONNREFUSED"

**Workaround:**
- Ensure backend is running: `cd Backend && npm start`
- Verify backend health: `curl http://localhost:3000/health`
- Check backend logs for incoming requests

**Fix Status:** In progress - debugging URL session configuration

---

### Voice Synthesis Not Connected
**Problem:** Voice recording UI works, but audio doesn't play back

**Symptoms:**
- Recording completes successfully
- No playback button appears
- Voice messages can't be sent

**Workaround:** Feature not yet connected end-to-end

**Fix Status:** Planned - ElevenLabs integration pending

---

## 🟡 Medium Priority

### Backend Port Conflicts
**Problem:** Backend fails to start with "Port 3000 already in use"

**Symptoms:**
```
Error: listen EADDRINUSE: address already in use :::3000
```

**Workaround:**
```bash
# Kill existing node processes
killall node

# Restart backend
cd Backend && npm start
```

**Prevention:** Always stop backend properly (Ctrl+C) instead of force-quit

---

### Keyboard Memory Warning
**Problem:** Keyboard extension occasionally shows high memory usage (>40MB)

**Symptoms:**
- iOS shows "FlirrtKeyboard using significant memory"
- Keyboard may be terminated by system
- UI becomes sluggish

**Workaround:**
- Close and reopen keyboard periodically
- Avoid taking multiple screenshots in quick succession
- Current limit: 60MB, warning at 45MB

**Fix Status:** Under monitoring - may need to reduce image compression quality

---

### App Group Sync Delays
**Problem:** Changes in main app don't immediately reflect in keyboard

**Symptoms:**
- Complete onboarding but keyboard still shows "setup needed"
- Voice clone created but keyboard doesn't show it
- Delay: 5-30 seconds

**Workaround:**
- Wait 30 seconds after completing setup
- Switch away from keyboard and back
- Restart keyboard (switch to another keyboard and back)

**Fix Status:** iOS limitation - UserDefaults synchronization is not instantaneous

---

## 🟢 Minor Issues

### Onboarding Skip Button
**Problem:** "Skip" button completes onboarding without personalization

**Impact:** Keyboard will request setup completion when used

**Workaround:** Don't skip - complete full onboarding for best experience

---

### Placeholder Buttons in Main App
**Problem:** Main app has 3 buttons that do nothing:
- "Analyze Screenshot"
- "Generate Flirts"
- "Voice Messages"

**Impact:** Confusing UX - looks broken

**Workaround:** Ignore these buttons, use keyboard extension instead

**Fix Status:** **FIXING IN THIS SESSION** - removing placeholder buttons

---

### Debug Screenshot Button (DEBUG builds only)
**Problem:** Debug keyboard has orange "Simulate Screenshot" button

**Impact:** Only visible in DEBUG builds, can be confusing

**Workaround:** Ignore - used for testing only

**Note:** This button won't appear in production builds

---

## 📱 iOS-Specific Limitations

### Keyboard Extensions Cannot:
- Access camera directly (workaround: use screenshot sharing)
- Present system alerts (using custom in-keyboard UI instead)
- Run background tasks (all processing happens on-demand)
- Access full network permissions without "Allow Full Access"

These are iOS platform limitations, not bugs.

---

## 🔧 Database Issues

### SQLite Lock Errors
**Problem:** "Database is locked" errors in backend

**Symptoms:**
```
Error: SQLITE_BUSY: database is locked
```

**Workaround:**
```bash
cd Backend/data
rm flirrt.db
cd ..
npm run db:init
```

**Prevention:** Don't access database while backend is running

---

### Missing API Keys
**Problem:** Backend starts but AI requests fail

**Symptoms:**
- Health check shows: `"grok":"error"` or `"gemini":"error"`
- Console: "Missing API key" errors

**Fix:**
1. Check `Backend/.env` file exists
2. Verify API keys are set correctly
3. Restart backend: `killall node && npm start`

---

## 🐛 Reporting New Issues

If you encounter a new issue:

1. **Check Console Logs**:
   - iOS: Xcode → View → Debug Area → Show Debug Area
   - Backend: Terminal running `npm start`

2. **Gather Information**:
   - What were you doing when it happened?
   - Can you reproduce it consistently?
   - What error messages appeared?

3. **Try Clean Rebuild**:
   ```bash
   # iOS
   cd iOS && rm -rf .build && xcodebuild clean

   # Backend
   cd Backend && rm -rf node_modules && npm install
   ```

---

## ✅ Recently Fixed

_(Will be populated as issues are resolved in upcoming sessions)_

---

**Need Help?** Check other documentation:
- [SETUP.md](./SETUP.md) - Installation troubleshooting
- [ARCHITECTURE.md](./ARCHITECTURE.md) - System design
- [API.md](./API.md) - Backend API reference
