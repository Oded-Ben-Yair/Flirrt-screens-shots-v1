# Mac Handoff Guide - Flirrt iOS Keyboard

**Date**: November 1, 2025
**For**: Mac Developer / Claude Agent on Mac
**Status**: ✅ Ready for iOS Testing

---

## 🎯 What Was Implemented

### Trained AI Pipeline (Grok-2-vision + GPT-5)
- **Backend Route**: `/api/v2/trained/analyze-and-generate`
- **File**: `Backend/routes/trained-flirts.js` (449 lines)
- **Architecture**: Dual-model pipeline
  - **Step 1**: Grok-2-vision-1212 for screenshot analysis
  - **Step 2**: GPT-5 (Azure) for coaching-style flirt generation
- **iOS Integration**: Keyboard endpoint updated (line 341 in KeyboardViewController.swift)

### What This Fixes
- ✅ User blocker: "screenshot analyzing in keyboard while chatting"
- ✅ Uses trained Grok + GPT pipeline (not old Gemini pipeline)
- ✅ Coaching tone in flirt suggestions
- ✅ Intelligent early exit if profile incomplete
- ✅ Robust fallback strategy (Grok-only if GPT-5 fails)

---

## 📋 Prerequisites

### Hardware & Software
- [ ] Mac with macOS 14+ (Sonoma or later)
- [ ] Xcode 15+ installed
- [ ] iPhone with iOS 17+ for testing
- [ ] Active Apple Developer account
- [ ] USB cable for iPhone connection

### Backend Access
- [ ] Backend deployed and accessible (Render or local)
- [ ] API credentials configured (Azure OpenAI, xAI Grok)
- [ ] Network connectivity verified

---

## 🚀 Quick Start (Step-by-Step)

### Step 1: Clone Repository (If Not Already Cloned)
```bash
git clone https://github.com/YOUR_USERNAME/FlirrtAI.git
cd FlirrtAI
```

### Step 2: Open Xcode Project
```bash
open iOS/Flirrt.xcodeproj
```

**Or manually**:
1. Launch Xcode
2. File → Open
3. Navigate to `FlirrtAI/iOS/Flirrt.xcodeproj`
4. Click Open

### Step 3: Configure Signing & Teams
1. In Xcode, select **Flirrt** project in navigator (left panel)
2. Select **Flirrt** target
3. Go to **Signing & Capabilities** tab
4. Under **Team**, select your Apple Developer account
   - If not listed, click "Add Account" and sign in
5. Repeat for **FlirrtKeyboard** target:
   - Select **FlirrtKeyboard** target
   - Go to **Signing & Capabilities**
   - Select same Team

### Step 4: Update API Base URL
```swift
// File: iOS/Flirrt/Constants/AppConstants.swift
// Update this line to point to your backend:

static let apiBaseURL = "https://your-backend.onrender.com"  // Render deployment
// OR
static let apiBaseURL = "http://localhost:3000"  // Local development
```

**Important**: If using localhost, iPhone must be on same network as Mac, or use ngrok/tunneling.

### Step 5: Build for iPhone
1. Connect iPhone via USB cable
2. Unlock iPhone and trust computer (if prompted)
3. In Xcode top bar, select your iPhone from device dropdown
4. Press **Cmd + B** to build
5. Wait for build to complete (check status bar)

### Step 6: Run on iPhone
1. Press **Cmd + R** to run
2. Xcode will install app on iPhone
3. If prompted on iPhone, go to Settings → General → Device Management → Trust developer

### Step 7: Enable Custom Keyboard
1. On iPhone, open **Settings**
2. Go to **General → Keyboard → Keyboards**
3. Tap **Add New Keyboard**
4. Find **FlirrtKeyboard** in list
5. Tap to enable
6. Tap **FlirrtKeyboard** again in keyboard list
7. Enable **Allow Full Access** (required for API calls)

### Step 8: Test in Any App
1. Open Safari, Messages, or any dating app
2. Tap in text field to bring up keyboard
3. Tap globe icon 🌐 to switch to FlirrtKeyboard
4. Take a screenshot while viewing chat profile
5. Keyboard should detect screenshot and generate flirts

---

## 🧪 Testing Checklist

### Basic Functionality
- [ ] App launches successfully
- [ ] No Xcode build errors
- [ ] Keyboard appears in Settings → Keyboards
- [ ] Keyboard can be switched to using globe icon
- [ ] Keyboard displays properly

### Screenshot Detection
- [ ] Open dating app (Tinder/Hinge/Bumble)
- [ ] View profile with photos and bio
- [ ] Take screenshot (Volume Up + Power button)
- [ ] Keyboard should show loading indicator
- [ ] Flirt suggestions appear after ~5-7 seconds

### Flirt Generation
- [ ] Multiple suggestions displayed (usually 3-5)
- [ ] Coaching tone present ("Try this...")
- [ ] Suggestions relevant to screenshot
- [ ] User can tap to select and send
- [ ] Different tones work (playful, confident, etc.)

### Edge Cases
- [ ] Incomplete profile → Keyboard shows guidance message
- [ ] Network error → Fallback to basic suggestions
- [ ] Multiple screenshots in quick succession
- [ ] Switching between different apps

---

## ⚙️ Backend Configuration

### Environment Variables Required
```bash
# Backend/.env

# Azure OpenAI (GPT-5)
AZURE_OPENAI_KEY=<YOUR_AZURE_OPENAI_KEY_HERE>
AZURE_OPENAI_ENDPOINT=https://brn-azai.cognitiveservices.azure.com
GPT5_DEPLOYMENT_NAME=gpt-5

# xAI Grok (Vision Analysis)
XAI_API_KEY=YOUR_XAI_API_KEY_HERE
GROK_MODEL=grok-2-vision-1212

# Optional: Redis (for caching)
# REDIS_HOST=localhost
# REDIS_PORT=6379

# Optional: Database (for persistence)
# DATABASE_URL=postgresql://...
```

### Verify Backend Health
```bash
# If backend running locally:
curl http://localhost:3000/health

# If deployed on Render:
curl https://your-backend.onrender.com/health

# Expected response:
{
  "status": "healthy",
  "service": "flirrt-backend",
  "timestamp": "2025-11-01T15:00:00.000Z"
}
```

### Test Trained Pipeline Health
```bash
curl http://localhost:3000/api/v2/trained/health

# Expected response:
{
  "success": true,
  "service": "trained-flirts",
  "models": {
    "grok": { "status": "available", ... },
    "gpt5": { "status": "available", ... }
  },
  "timestamp": "2025-11-01T15:00:00.000Z"
}
```

---

## 🔧 Troubleshooting

### Xcode Build Fails

**Error**: "Signing for 'Flirrt' requires a development team"
- **Fix**: Select your Apple Developer team in Signing & Capabilities

**Error**: "Could not find module 'SomeModule'"
- **Fix**: Check if project uses CocoaPods or SPM dependencies
- Run `pod install` if using CocoaPods

**Error**: "The application could not be verified"
- **Fix**: Trust developer certificate on iPhone (Settings → General → Device Management)

### Keyboard Not Appearing

**Problem**: Keyboard doesn't show up in keyboard list
- **Fix**:
  1. Delete app from iPhone
  2. Rebuild and reinstall
  3. Restart iPhone
  4. Check Settings → General → Keyboard

**Problem**: Globe icon doesn't show FlirrtKeyboard
- **Fix**: Make sure "Allow Full Access" is enabled in Settings

### Screenshot Detection Not Working

**Problem**: Screenshot taken but nothing happens
- **Fix**:
  1. Check Console in Xcode for errors
  2. Verify backend URL is correct in AppConstants.swift
  3. Test backend health endpoint
  4. Check iPhone has internet connection
  5. Verify "Allow Full Access" is enabled

**Problem**: "Network error" shown in keyboard
- **Fix**:
  1. Verify backend is running and accessible
  2. If using localhost, ensure iPhone on same network
  3. Consider using ngrok for local testing: `ngrok http 3000`
  4. Update AppConstants.swift with ngrok URL

### API Errors

**Problem**: "Authentication failed" or 401 errors
- **Fix**: Currently auth is disabled for MVP, but check that endpoint doesn't require token

**Problem**: "Analysis failed" errors
- **Fix**:
  1. Check Grok API key is valid
  2. Verify image is being properly base64 encoded
  3. Check backend logs for detailed error

**Problem**: "Generation failed" errors
- **Fix**:
  1. Check GPT-5 Azure OpenAI credentials
  2. Verify deployment name matches configuration
  3. Backend will fallback to Grok-only if GPT-5 fails

---

## 📊 Performance Expectations

### Target Latencies
- **Grok Analysis**: < 5 seconds
- **GPT-5 Generation**: < 2 seconds
- **Total Pipeline**: < 7 seconds end-to-end

### Quality Metrics
- **Overall Quality Score**: 0.80+ target
- **Sentiment Score**: 0.75+
- **Creativity Score**: 0.80+
- **Coaching Tone**: Present in all suggestions

### What to Monitor
- Response times in Xcode console
- Quality scores in backend logs
- User experience (perceived latency)
- Fallback strategy triggers

---

## 🐛 Known Issues

### 1. Backend Server Startup (Pre-existing)
**Status**: ⚠️ Documented
**Issue**: Server may hang during startup waiting for Redis connection
**Workaround**: Redis check added to prevent crash, but may need local Redis installation
**Impact**: Doesn't affect deployed backend on Render
**Details**: See `.github/SERVER_STARTUP_ISSUE.md`

### 2. Authentication Disabled
**Status**: ⚠️ Intentional for MVP
**Issue**: Route doesn't require authentication tokens
**Impact**: Open to anyone with API access
**Action**: Must enable before public launch
**Line**: Backend/routes/trained-flirts.js:117 (commented out authenticateToken)

### 3. No Content Moderation
**Status**: ⚠️ Must add before production
**Issue**: No filtering for inappropriate suggestions
**Impact**: Could generate policy-violating content
**Action**: Add Azure Content Safety or similar before production

---

## 📱 iOS Code Structure

### Key Files Modified
```
iOS/
├── Flirrt/
│   └── Constants/
│       └── AppConstants.swift          # Line 26: API base URL
└── FlirrtKeyboard/
    └── KeyboardViewController.swift    # Line 341: Endpoint updated
```

### API Call Flow
```swift
// KeyboardViewController.swift:341
let apiURL = "\(AppConstants.apiBaseURL)/api/v2/trained/analyze-and-generate"

// Request format:
{
  "image_data": "<base64_encoded_screenshot>",
  "suggestion_type": "opener",
  "tone": "playful",
  "context": "tinder"
}

// Response format:
{
  "success": true,
  "pipeline": "trained_grok_gpt5",
  "suggestions": [
    {
      "text": "Try this: 'Your hiking photos are incredible! ...'",
      "confidence": 0.87,
      "tone": "playful"
    }
  ],
  "performance": {
    "totalLatency": 6200
  }
}
```

---

## 🔄 Testing Workflow

### Local Development Loop
1. Make changes in Xcode
2. Build (Cmd + B)
3. Run on device (Cmd + R)
4. Test in dating app
5. Check Xcode console for logs
6. Iterate

### Backend Testing
```bash
# Start backend locally
cd Backend
npm start

# In another terminal, test API
curl -X POST http://localhost:3000/api/v2/trained/analyze-and-generate \
  -H "Content-Type: application/json" \
  -d '{
    "image_data": "'"$(base64 -w 0 test_screenshot.jpg)"'",
    "suggestion_type": "opener",
    "tone": "playful"
  }'
```

### Render Deployment Testing
1. Push changes to git
2. Render auto-deploys from main branch
3. Wait for deployment (~2-3 minutes)
4. Test health endpoint
5. Test from iOS app

---

## 📝 Git Workflow

### Branch Strategy
```bash
# This implementation is on main branch
git checkout main
git pull origin main

# To create feature branch:
git checkout -b feature/your-feature-name
```

### Commit Messages
Follow conventional commits:
```bash
git commit -m "feat: add new feature"
git commit -m "fix: resolve issue with X"
git commit -m "docs: update documentation"
```

### Pushing Changes
```bash
git add .
git commit -m "your message"
git push origin main
```

---

## 🎓 Architecture Overview

### Dual-Model Pipeline

```
iOS Keyboard
    ↓ (screenshot as base64)
Backend: /api/v2/trained/analyze-and-generate
    ↓
Step 1: Grok-2-vision Analysis
    ├─→ Extract profile details
    ├─→ Identify conversation context
    ├─→ Check if profile complete
    └─→ If incomplete: return guidance, exit early
    ↓
Step 2: GPT-5 Generation
    ├─→ Generate coaching-style flirts
    ├─→ Apply tone (playful/confident/etc)
    ├─→ Quality evaluation
    └─→ Format for iOS
    ↓
Response to iOS
    └─→ Display in keyboard
```

### Why Dual-Model?
- **Grok-2-vision**: Superior at visual analysis (screenshots, profiles)
- **GPT-5**: Superior at conversational content generation
- **Separation of concerns**: Each model does what it's best at
- **Fallback strategy**: Can use Grok-only if GPT-5 fails

---

## 📚 Documentation References

All implementation details are documented in `.github/`:

| Document | Purpose |
|----------|---------|
| `BACKEND_PIPELINE_ANALYSIS.md` | Initial architecture analysis |
| `TRAINED_PIPELINE_IMPLEMENTATION_COMPLETE.md` | Complete implementation guide |
| `TRAINED_PIPELINE_TECHNICAL_ANALYSIS.md` | Deep technical review (345 lines) |
| `SERVER_STARTUP_ISSUE.md` | Known blocker documentation |
| `LLM_CONSENSUS_SUMMARY.md` | Multi-LLM approval & next steps |
| `MAC_HANDOFF_GUIDE.md` | This document |

---

## ✅ Pre-Flight Checklist

Before testing on iPhone:

### Backend Ready
- [ ] Backend is deployed and accessible
- [ ] Health endpoint returns 200 OK
- [ ] Trained pipeline health check passes
- [ ] Environment variables configured
- [ ] API keys are valid and active

### Xcode Setup
- [ ] Project opens without errors
- [ ] Signing configured with your team
- [ ] Build succeeds (Cmd + B)
- [ ] No red errors in Issue Navigator
- [ ] AppConstants.swift has correct API URL

### iPhone Preparation
- [ ] iPhone updated to iOS 17+
- [ ] Developer mode enabled (if required)
- [ ] USB debugging enabled
- [ ] Device trusted in Xcode
- [ ] Keyboard enabled in Settings
- [ ] "Allow Full Access" enabled

### Test Environment
- [ ] Dating app installed (Tinder/Hinge/Bumble)
- [ ] Test profile visible with bio and photos
- [ ] iPhone has internet connection
- [ ] Network allows API calls (not blocked)

---

## 🚨 Critical Notes

1. **Authentication Disabled**: Currently commented out for MVP testing. Must enable before production.

2. **Rate Limiting**: Set to 20 requests per 15 minutes. May need adjustment based on usage.

3. **Base64 Overhead**: Screenshots sent as base64. Consider image compression for production.

4. **No Caching**: Redis optional and currently not configured. Will improve with caching layer.

5. **Fallback Strategy**: If GPT-5 fails, system falls back to Grok-only suggestions. This is intentional.

6. **Early Exit**: If profile incomplete, keyboard returns guidance instead of flirts. This is expected behavior.

---

## 🎯 Success Criteria

You've successfully handed off if:

✅ Backend deployed and accessible
✅ Xcode builds without errors
✅ App installs on iPhone
✅ Keyboard appears in Settings
✅ Screenshot detection triggers
✅ Flirts appear after ~7 seconds
✅ Suggestions are relevant and coaching-style
✅ User can tap and send suggestions

---

## 📞 Next Steps After Handoff

1. **Test thoroughly** with real screenshots
2. **Measure performance** (actual vs target latencies)
3. **Collect quality metrics** from backend logs
4. **Test edge cases** (incomplete profiles, network errors)
5. **Enable authentication** before wider testing
6. **Add content moderation** before public launch
7. **Implement caching** for cost optimization
8. **Monitor API costs** (Grok + GPT-5 per request)

---

## 💡 Tips for Mac Claude Agent

- **Console is your friend**: Watch Xcode console for real-time logs
- **Backend logs too**: Check backend logs for detailed error messages
- **Network tab**: Use Xcode's Network debugger to inspect API calls
- **Breakpoints**: Set in KeyboardViewController.swift line 340+ to debug API flow
- **Simulator limitations**: Screenshot detection may not work in Simulator, use real iPhone
- **Testing shortcut**: Use curl to test backend directly before iOS testing

---

**Prepared by**: Claude Code
**Last Updated**: November 1, 2025
**Validated**: LLM consensus (93% confidence)
**Status**: ✅ Ready for iOS Testing

**Questions?** Check documentation in `.github/` directory or backend logs for detailed error messages.

Good luck! 🚀
