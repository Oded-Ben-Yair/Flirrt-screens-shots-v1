# Flirrt.ai Production Testing Checklist

## 🎯 Overview

Complete testing checklist for validating all Flirrt.ai features in production with cloud backend.

**Testing Environment:**
- Backend: Render.com (HTTPS)
- Device: iPad with iOS 18
- API: Grok Vision, ElevenLabs, Gemini

---

## 📋 Pre-Deployment Checklist

### Backend Verification:
- [ ] Render.com service deployed successfully
- [ ] Health endpoint returns 200 OK: `https://flirrt-api-production.onrender.com/health`
- [ ] All API keys configured in environment variables
- [ ] Environment shows `"environment": "production"`
- [ ] Services status shows:
  ```json
  {
    "grok_api": "configured",
    "elevenlabs_api": "configured",
    "gemini_api": "configured"
  }
  ```

### iOS App Configuration:
- [ ] AppConstants.swift updated with production Render URL
- [ ] NSLocalNetworkUsageDescription removed from Info.plist
- [ ] Build configuration set to Release (or Debug for initial testing)
- [ ] All compilation errors resolved

---

## 🧪 Feature Testing Scenarios

### ✅ Scenario 1: Complete Dating Profile Screenshot

**Setup:**
1. Open any dating app (Tinder, Bumble, Hinge, etc.)
2. Find a profile with:
   - Multiple photos
   - Detailed bio text
   - Interests/hobbies visible
   - Name, age visible

**Test Steps:**
1. Take screenshot of profile (Home + Volume Up)
2. Open Messages app (or any app with text input)
3. Tap text field → Switch to Flirrt keyboard
4. Wait for keyboard to detect screenshot

**Expected Results:**
- [ ] Keyboard shows "Analyzing screenshot..." status
- [ ] Within 5-10 seconds, displays status: "✅ Great profile! Found plenty of details"
- [ ] Shows 5 personalized flirt suggestions
- [ ] Each suggestion references specific profile details (name, bio, interests)
- [ ] Suggestions have playful/witty tone
- [ ] No network errors

**Success Criteria:**
```
✅ screenshot_type: "profile"
✅ profile_score: >= 6
✅ needs_more_scrolling: false
✅ suggestions.length: 5
✅ Each suggestion.text references profile details
```

---

### ✅ Scenario 2: Incomplete Profile (Minimal Info)

**Setup:**
1. Find a dating profile with:
   - Only 1-2 photos
   - No bio text OR very short bio
   - No interests/hobbies visible

**Test Steps:**
1. Take screenshot of incomplete profile
2. Open text field → Switch to Flirrt keyboard
3. Wait for analysis

**Expected Results:**
- [ ] Keyboard detects profile but shows message:
  - "📸 I can see photos but no bio text or interests. Please scroll down to show more of the profile..."
- [ ] Shows **action button**: "📸 Retake Screenshot" or "Scroll & Retry"
- [ ] NO flirt suggestions displayed (empty array)
- [ ] Tapping action button re-triggers screenshot detection

**Success Criteria:**
```
✅ screenshot_type: "profile"
✅ profile_score: < 6
✅ needs_more_scrolling: true
✅ suggestions: []
✅ action button visible
```

---

### ✅ Scenario 3: Empty Chat Conversation

**Setup:**
1. Open dating app chat with someone
2. Find a conversation with NO messages yet (empty chat screen)
3. Take screenshot

**Test Steps:**
1. Take screenshot of empty chat
2. Open text field → Switch to Flirrt keyboard
3. Wait for analysis

**Expected Results:**
- [ ] Keyboard detects chat type
- [ ] Shows message:
  - "📱 This is a chat conversation, not a profile. Please screenshot the person's dating profile instead for better openers."
- [ ] Shows **action button**: "📸 Screenshot Profile"
- [ ] NO suggestions displayed
- [ ] Tapping button triggers new screenshot detection

**Success Criteria:**
```
✅ screenshot_type: "chat"
✅ has_conversation: false
✅ needs_more_scrolling: true
✅ suggestions: []
✅ message asks for profile screenshot
```

---

### ✅ Scenario 4: Active Chat with Messages

**Setup:**
1. Open dating app chat with ongoing conversation
2. Ensure at least 3-5 messages visible
3. Last message should be from the other person
4. Take screenshot

**Test Steps:**
1. Take screenshot of active conversation
2. Open text field → Switch to Flirrt keyboard
3. Wait for analysis

**Expected Results:**
- [ ] Keyboard detects chat with messages
- [ ] Shows status: "💬 Great! I can see the conversation. Here are some ways to continue:"
- [ ] Displays 5 conversation continuation suggestions
- [ ] Each suggestion:
  - References the last message or conversation context
  - Maintains conversation tone (casual, flirty, friendly, etc.)
  - Feels natural as a reply
- [ ] Uses `showChatContinuation()` UI (green status text)

**Success Criteria:**
```
✅ screenshot_type: "chat"
✅ has_conversation: true
✅ needs_more_scrolling: false
✅ suggestions.length: 5
✅ extracted_details.last_message_from_them: <actual message text>
✅ Suggestions reference conversation context
```

---

### ✅ Scenario 5: Network Error Handling

**Test Cases:**

**A) Timeout Error:**
1. Enable airplane mode on iPad
2. Take screenshot
3. Switch to Flirrt keyboard

**Expected:**
- [ ] Shows error: "Network error: The request timed out"
- [ ] OR: "No internet connection. Please check your network."
- [ ] Shows retry button
- [ ] Tapping retry re-attempts analysis

**B) Backend Unavailable:**
1. Stop Render service temporarily
2. Take screenshot
3. Switch to keyboard

**Expected:**
- [ ] Shows error: "Backend unavailable. Try again in a moment."
- [ ] Shows retry button
- [ ] After service restarts, retry works

**C) Invalid API Response:**
(Simulate by causing backend to return malformed JSON)

**Expected:**
- [ ] Shows error: "Could not analyze screenshot. Please try again."
- [ ] Logs error details to console
- [ ] Shows retry button

**Success Criteria:**
```
✅ All errors show user-friendly messages
✅ All errors have retry mechanism
✅ No crashes on network failures
✅ Console logs show detailed error info
```

---

## 🔍 Edge Case Testing

### Additional Test Cases:
- [ ] **Screenshot of non-dating content** (e.g., random photo):
  - Should show: "This doesn't appear to be a dating profile or chat. Please screenshot a dating app."

- [ ] **Profile in different language** (Hebrew, Spanish, etc.):
  - Should extract bio text in original language
  - Should generate suggestions in English (or match language if configured)

- [ ] **Very long bio text**:
  - Should analyze full content
  - Should generate relevant suggestions without truncation

- [ ] **Profile with only emojis in bio**:
  - Should acknowledge emojis as content
  - Should generate creative suggestions based on emoji meanings

- [ ] **Multiple screenshots in quick succession**:
  - Should handle latest screenshot
  - Should not mix up contexts

- [ ] **App backgrounded during analysis**:
  - Should complete analysis when app returns
  - Should show results when user returns

---

## 📊 Performance Benchmarks

### Response Times:
- [ ] Complete profile analysis: **< 10 seconds**
- [ ] Incomplete profile detection: **< 5 seconds**
- [ ] Empty chat detection: **< 5 seconds**
- [ ] Active chat analysis: **< 10 seconds**
- [ ] Network errors show immediately: **< 3 seconds**

### Resource Usage:
- [ ] Memory usage stable (no leaks)
- [ ] CPU usage returns to baseline after analysis
- [ ] No battery drain issues
- [ ] Keyboard remains responsive throughout

---

## ✅ Post-Testing Validation

### Success Metrics:
- [ ] All 5 primary scenarios pass ✅
- [ ] All edge cases handled gracefully ✅
- [ ] No crashes or freezes ✅
- [ ] User experience smooth and intuitive ✅
- [ ] Error messages helpful and actionable ✅

### Known Limitations (Expected):
- Database optional (no user data persistence yet)
- Authentication disabled for MVP testing
- Rate limiting disabled for MVP

### Production Readiness Checklist:
- [ ] All features working end-to-end
- [ ] HTTPS communication verified
- [ ] No local network dependencies
- [ ] Error handling comprehensive
- [ ] User feedback clear and actionable
- [ ] Performance within acceptable limits

---

## 🐛 Bug Reporting Template

If you encounter issues, document using this format:

**Bug Title:** [Brief description]

**Scenario:** [Which scenario: 1, 2, 3, 4, or 5]

**Steps to Reproduce:**
1. [Step 1]
2. [Step 2]
3. [Step 3]

**Expected Behavior:**
[What should happen]

**Actual Behavior:**
[What actually happened]

**Screenshots/Logs:**
[Attach screenshots or copy console logs]

**Device Info:**
- Device: iPad Pro/Air/Mini
- iOS Version: 18.x
- Keyboard Version: 1.0.0

---

## 📝 Testing Notes

### Session Info:
- **Date:** __________
- **Tester:** __________
- **Backend URL:** https://flirrt-api-production.onrender.com
- **Build Version:** __________

### Test Results Summary:
- Scenario 1 (Complete Profile): ☐ Pass ☐ Fail
- Scenario 2 (Incomplete Profile): ☐ Pass ☐ Fail
- Scenario 3 (Empty Chat): ☐ Pass ☐ Fail
- Scenario 4 (Active Chat): ☐ Pass ☐ Fail
- Scenario 5 (Network Errors): ☐ Pass ☐ Fail
- Edge Cases: ☐ Pass ☐ Fail

### Overall Status:
☐ **READY FOR PRODUCTION** - All tests pass
☐ **NEEDS FIXES** - Issues found (document above)
☐ **BLOCKED** - Cannot test (specify reason)

---

**Last Updated:** October 6, 2025
**Version:** 1.0.0
**Status:** Ready for Testing
