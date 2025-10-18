# Keyboard Setup Guide

Step-by-step guide for installing and using the Vibe8AI keyboard.

---

## 📱 Installation

### Step 1: Install the App
1. Open Xcode project
2. Build and run to your device/simulator
3. Complete the onboarding questionnaire
4. **Important**: Don't skip onboarding - keyboard needs your personalization data

### Step 2: Add Keyboard to iOS
1. Open iOS **Settings** app
2. Navigate to: **General** → **Keyboard** → **Keyboards**
3. Tap **"Add New Keyboard..."**
4. Scroll down and select **"Vibe8"** from "THIRD-PARTY KEYBOARDS"

### Step 3: Enable Full Access
1. In **Keyboards** settings, tap **"Vibe8"**
2. Toggle **"Allow Full Access"** to **ON**
3. Confirm the alert (needed for network requests to backend)

**Why Full Access?**
- Required to make API requests to backend server
- Needed to access clipboard for inserting suggestions
- iOS security requirement for network-enabled keyboards

---

## 🎮 Using the Keyboard

### Switching to Vibe8 Keyboard

**Method 1: Globe Icon**
1. Open any app (Messages, Tinder, etc.)
2. Tap text field to bring up keyboard
3. Tap and hold the 🌐 globe icon (bottom-left)
4. Select "Vibe8" from the list

**Method 2: Quick Tap**
1. Tap 🌐 globe icon repeatedly
2. Cycles through all enabled keyboards
3. Stop when you see Vibe8 keyboard

### Keyboard Interface

```
┌─────────────────────────────────────────────┐
│  💫 Fresh Flirts                            │
│  Personalized for you                       │
│  [Large pink/blue button]                   │
├─────────────────────────────────────────────┤
│                                             │
│  [Suggestion 1]                             │
│  [Suggestion 2]                             │
│  [Suggestion 3]                             │
│                                             │
└─────────────────────────────────────────────┘
```

---

## 💡 Usage Modes

### Mode 1: Fresh Flirts (💫)
**When to use**: Starting a new conversation, need opener ideas

**How it works**:
1. Switch to Vibe8 keyboard
2. Button shows "💫 Fresh Flirts"
3. Tap button
4. Wait 10-20 seconds
5. Get 3 personalized opener suggestions
6. Tap one to insert it

**Based on**:
- Your personalization profile
- Communication style preference
- Interests and conversation topics

---

### Mode 2: Analyze Screenshot (📸)
**When to use**: Responding to an ongoing conversation

**How it works** (Intended):
1. Take screenshot of conversation (Side button + Volume Up)
2. Switch to Vibe8 keyboard
3. Button automatically changes to "📸 Analyze This"
4. Tap button
5. Wait 15-25 seconds (analyzing + generating)
6. Get 3 contextual response suggestions
7. Tap one to insert it

**Status**: 🚧 Screenshot detection currently not working reliably
**Workaround**: Use "Fresh Flirts" mode for now

---

## ⏱️ What to Expect

### Response Times
- **Fresh Flirts**: 10-20 seconds
- **Screenshot Analysis**: 15-25 seconds (when working)
- **First Request**: May be slower as backend initializes

### Loading States
1. "Analyzing screenshot..." (if screenshot mode)
2. "Understanding context..."
3. "Generating suggestions..."
4. "Almost ready..."
5. Suggestions appear!

### Success Indicators
- ✅ Haptic feedback when suggestions load
- ✅ Pink/blue highlighting on selected suggestion
- ✅ Text inserted into message field

---

## 🐛 Troubleshooting

### Keyboard Doesn't Appear in List
**Solution**:
1. Rebuild app in Xcode
2. Delete app from device
3. Clean build folder (Cmd+Shift+K)
4. Rebuild and reinstall

### "Full Access Required" Message
**Solution**:
1. Settings → General → Keyboard → Keyboards
2. Tap "Vibe8"
3. Enable "Allow Full Access"
4. Return to app and try again

### Button Does Nothing When Tapped
**Check**:
1. Is backend running? (`cd Backend && npm start`)
2. Test backend health: `curl http://localhost:3000/health`
3. Check Xcode console for error messages
4. Verify network connectivity

### "Complete Setup in Vibe8 App First"
**Solution**:
1. Open main Vibe8 app
2. Complete the onboarding questionnaire
3. Wait 30 seconds
4. Return to keyboard and try again

### Keyboard Uses Too Much Memory
**iOS might show**: "Vibe8Keyboard using significant memory"

**Solutions**:
- Close and reopen keyboard (switch away and back)
- Reduce usage frequency (give it breaks)
- Force close and reopen the app hosting keyboard

### Suggestions Take Forever
**Check**:
1. Backend is running and responding
2. Network connection is active
3. AI API keys are valid in Backend/.env
4. Check backend console for errors

---

## 💪 Best Practices

### For Best Results:
1. **Complete full onboarding** - Don't skip questions
2. **Be honest in personalization** - Better AI matching
3. **Keep backend running** - Must be active for suggestions
4. **Wait for full response** - Don't spam the button
5. **Give feedback** - Try different suggestions to see what works

### Memory Management:
1. **Close when not in use** - Switch back to default keyboard
2. **Avoid rapid-fire requests** - Wait for previous to complete
3. **Restart if sluggish** - Switch away and back fixes most issues

### Network Tips:
1. **Ensure WiFi connection** - Cellular might be slower
2. **Check localhost connectivity** - Backend must be reachable
3. **Use IP for physical device** - Replace localhost with Mac IP

---

## 🎓 Advanced Usage

### Testing Mode (DEBUG Builds Only)
In debug builds, you'll see an orange "🐛 Simulate Screenshot" button.

**Purpose**: Test screenshot analysis without taking real screenshots

**How to use**:
1. Tap the debug button
2. Keyboard acts as if screenshot was just taken
3. Switches to "Analyze" mode
4. Good for testing the flow

**Note**: Won't appear in production/release builds

---

## 📊 Understanding Suggestions

### Tone Indicators:
- **Playful**: Light, fun, teasing
- **Witty**: Clever, smart humor
- **Thoughtful**: Deep, meaningful
- **Funny**: Humor-focused

### Confidence Scores:
- **0.90-1.00**: High confidence, AI is very sure
- **0.80-0.89**: Good confidence, should work well
- **0.70-0.79**: Moderate confidence, might need editing
- **Below 0.70**: Low confidence, consider regenerating

### Selection Tips:
- Read all 3 before choosing
- Consider the conversation context
- Personalize further if needed
- Don't be afraid to mix and match

---

## 🔄 Updating Your Profile

### When to Update:
- Dating goals change
- Gain more confidence
- Discover new interests
- Communication style evolves

### How to Update:
1. Open main Vibe8 app
2. Go to Settings
3. Tap "Update Personalization"
4. Modify your responses
5. Keyboard will use new profile automatically

---

## 🆘 Still Having Issues?

### Check Documentation:
- [KNOWN_ISSUES.md](./KNOWN_ISSUES.md) - Current bugs and workarounds
- [SETUP.md](./SETUP.md) - Full installation guide
- [FEATURES.md](./FEATURES.md) - Feature documentation

### Debug Checklist:
- [ ] Backend is running (`npm start`)
- [ ] Backend health check passes (`curl http://localhost:3000/health`)
- [ ] Keyboard has "Allow Full Access" enabled
- [ ] Onboarding completed in main app
- [ ] App Groups entitlement configured correctly
- [ ] Xcode console shows no errors

### Common Error Messages:

**"Network unavailable"**
→ Backend not running or not reachable

**"Request timed out"**
→ AI API taking too long, try again

**"API request failed"**
→ Check backend logs for errors

**"Complete setup in Vibe8 app first"**
→ Onboarding not completed or data not synced

---

**Need more help?** Check other docs in this folder or review code comments.

---

**Last Updated**: October 2025
