# Setup Guide

Complete installation and configuration guide for Vibe8AI development.

## Prerequisites

### System Requirements
- macOS 13.0+ (for iOS development)
- Xcode 15.0+
- Node.js 18.0+
- npm 9.0+

### API Keys Required
You'll need accounts and API keys for:
- **xAI** (Grok) - https://x.ai/api
- **Google Gemini** - https://ai.google.dev
- **ElevenLabs** - https://elevenlabs.io
- **OpenAI** (optional) - https://openai.com

## Backend Setup

### 1. Install Dependencies
```bash
cd Backend
npm install
```

### 2. Configure Environment Variables
Create `Backend/.env` file:
```env
# AI API Keys
GROK_API_KEY=xai-your_grok_key_here
GEMINI_API_KEY=your_gemini_key_here
ELEVENLABS_API_KEY=sk_your_elevenlabs_key_here
OPENAI_API_KEY=sk-your_openai_key_here  # Optional

# Server Configuration
PORT=3000
NODE_ENV=development

# Security
JWT_SECRET=vibe8_ai_super_secret_key_2024_production

# Database
DB_PATH=./data/vibe8.db
```

### 3. Initialize Database
```bash
npm run db:init  # Creates SQLite database
```

### 4. Start Server
```bash
npm start

# Should see:
# ✅ Server running on http://localhost:3000
# ✅ Database connected
# ✅ AI services initialized
```

### 5. Verify Backend
```bash
curl http://localhost:3000/health

# Expected response:
# {"status":"healthy","services":{"grok":"operational","gemini":"operational"}}
```

## iOS Setup

### 1. Open Xcode Project
```bash
cd iOS
open Vibe8.xcodeproj
```

### 2. Configure Signing & Capabilities

**For Main App (Vibe8 target):**
1. Select Vibe8 target
2. Signing & Capabilities tab
3. Set Team to your Apple Developer account
4. Verify capabilities:
   - ✅ App Groups: `group.com.vibe8.shared`
   - ✅ Keychain Sharing
   - ✅ Sign in with Apple

**For Keyboard Extension (Vibe8Keyboard target):**
1. Select Vibe8Keyboard target
2. Set same Team
3. Verify capabilities:
   - ✅ App Groups: `group.com.vibe8.shared` (same group!)
   - ✅ Keychain Sharing

**For Share Extension (Vibe8Share target):**
1. Select Vibe8Share target
2. Set same Team
3. Verify App Groups capability

### 3. Update Bundle Identifiers (if needed)
If using your own Apple Developer account:
- Vibe8: `com.yourteam.vibe8`
- Vibe8Keyboard: `com.yourteam.vibe8.keyboard`
- Vibe8Share: `com.yourteam.vibe8.share`

Also update App Group to: `group.com.yourteam.vibe8.shared`

### 4. Update API Base URL
Edit `iOS/Vibe8/Services/APIClient.swift`:
```swift
private let baseURL = "http://localhost:3000/api/v1"
// For physical device: use your Mac's IP address
// private let baseURL = "http://192.168.1.100:3000/api/v1"
```

### 5. Build and Run
1. Select "Vibe8" scheme
2. Choose iPhone 15 Simulator (or your device)
3. Cmd+R to build and run

**Expected behavior:**
- App launches
- Shows onboarding flow
- "Continue with Apple" button visible

## Enable Keyboard Extension

### In Simulator/Device:
1. Open Settings app
2. Navigate: General → Keyboard → Keyboards
3. Tap "Add New Keyboard..."
4. Select "Vibe8" from the list
5. Tap "Vibe8" in keyboards list
6. Enable "Allow Full Access"

### Test Keyboard:
1. Open Messages app or Notes
2. Tap to bring up keyboard
3. Tap 🌐 globe icon to switch keyboards
4. Select Vibe8 keyboard
5. Should see Vibe8 interface with button

## Troubleshooting

### Backend Issues

**Port 3000 already in use:**
```bash
killall node
npm start
```

**Database errors:**
```bash
rm -rf data/vibe8.db
npm run db:init
```

**API key errors:**
- Verify `.env` file exists in Backend/
- Check API keys are valid and active
- Restart server after changing .env

### iOS Issues

**Build Fails - "No such module":**
```bash
cd iOS
rm -rf .build
xcodebuild -scheme Vibe8 clean
# Rebuild in Xcode
```

**Signing Error:**
- Ensure Apple Developer account is added to Xcode
- Check all 3 targets have same Team selected
- Verify Bundle IDs are unique

**Keyboard not appearing:**
- Check App Groups match across all targets
- Verify "Allow Full Access" is enabled
- Restart simulator/device

**Crash on launch:**
- Check Console.app for crash logs
- Verify entitlements are configured
- Check Xcode debug console for errors

### Network Issues (Simulator → Backend)

**iOS can't reach localhost:3000:**

Simulator should reach localhost directly. If issues:
```bash
# Get your Mac's IP
ipconfig getifaddr en0

# Update APIClient.swift with IP instead of localhost
```

## Development Workflow

### Typical Development Session:
1. Start backend: `cd Backend && npm start`
2. Open Xcode: `cd iOS && open Vibe8.xcodeproj`
3. Run app in simulator
4. Check backend logs for API calls
5. Use Xcode console for iOS logs

### Recommended Tools:
- **Postman/Insomnia** - Test backend APIs
- **Console.app** - View detailed iOS logs
- **DB Browser for SQLite** - Inspect database

## Next Steps

Once setup is complete:
- Read [ARCHITECTURE.md](./ARCHITECTURE.md) to understand system design
- Review [FEATURES.md](./FEATURES.md) for feature documentation
- Check [KNOWN_ISSUES.md](./KNOWN_ISSUES.md) for current limitations

## Getting Help

- Check documentation in this `docs/` folder
- Review code comments in source files
- Check backend logs: `Backend/logs/`
- Check iOS console in Xcode

---

**Last Updated**: October 2025
