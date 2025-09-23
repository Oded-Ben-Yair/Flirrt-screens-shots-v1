# 🚀 Flirrt.ai - AI-Powered Dating Assistant

## ⚠️ CRITICAL STATUS - KEYBOARD EXTENSION BROKEN
**Date**: 2025-09-23
**Issue**: Keyboard extension buttons (Fresh/Analyze) are NOT connected to backend APIs
**Impact**: Core functionality non-operational in production

### 🔴 Immediate Action Required
1. **READ FIRST**: [CRITICAL_FIXES.md](./CRITICAL_FIXES.md) - Exact problems and solutions
2. **IMPLEMENT**: [IMPLEMENTATION_GUIDE.md](./IMPLEMENTATION_GUIDE.md) - Step-by-step fixes
3. **VALIDATE**: [TEST_SCENARIOS.md](./TEST_SCENARIOS.md) - Testing procedures
4. **REFERENCE**: [API_CONTRACTS.md](./API_CONTRACTS.md) - Backend endpoints

### Known Issues (User-Confirmed)
- ❌ Fresh button does nothing when tapped
- ❌ Analyze button does nothing when tapped
- ❌ Screenshots don't trigger keyboard
- ❌ Voice cloning missing script interface
- ❌ Onboarding not connected to Fresh button

---

## Overview
Flirrt.ai is an intelligent iOS application that helps users craft personalized, engaging messages for dating conversations. It uses advanced AI to analyze conversation screenshots and generate contextually appropriate responses with optional voice synthesis.

## 🏗️ Architecture

```
┌──────────────────────────────────────────────────────┐
│                    iOS App (Swift)                    │
├────────────────┬─────────────────┬──────────────────┤
│   Main App     │  Keyboard Ext   │  Share Extension │
│  - Auth/Voice  │  - Quick Reply  │  - Screenshot    │
└────────────────┴─────────────────┴──────────────────┘
                          ⬇️
┌──────────────────────────────────────────────────────┐
│               Backend API (Node.js)                   │
│  - Express Server                                     │
│  - JWT Authentication                                 │
│  - Multi-part Form Upload                            │
└──────────────────────────────────────────────────────┘
                          ⬇️
┌─────────────────────┬────────────────────────────────┐
│   Grok AI (xAI)     │      ElevenLabs API            │
│  - Text Generation  │   - Voice Synthesis            │
│  - Vision Analysis  │   - Voice Cloning              │
└─────────────────────┴────────────────────────────────┘
```

## 📁 Project Structure

```
/FlirrtAI/
├── iOS/                        # iOS Application
│   ├── Flirrt/                # Main app
│   │   ├── App/              # App entry point
│   │   ├── Models/           # Data models
│   │   ├── Views/            # SwiftUI views
│   │   └── Services/         # API & managers
│   ├── FlirrtKeyboard/        # Keyboard extension
│   ├── FlirrtShare/           # Share extension
│   └── Package.swift          # SPM configuration
│
├── Backend/                    # Node.js Server
│   ├── server.js             # Main server
│   ├── routes/               # API endpoints
│   ├── middleware/           # Auth & validation
│   └── .env                  # Environment variables
│
└── Agents/                     # AI Sub-Agents
    ├── ScreenshotAnalyzer.js  # Vision processing
    ├── FlirtGenerator.js      # Message generation
    ├── PersonalizationEngine.js # User preferences
    ├── VoiceSynthesizer.js    # Audio generation
    ├── ConversationCoach.js   # Tips & guidance
    └── SimulatorTestAgent.js  # Automated testing
```

## 🚀 Quick Start

### Prerequisites
- macOS with Xcode 26+
- Node.js 18+
- iOS Simulator (iPhone 16 Pro recommended)
- API Keys for Grok and ElevenLabs

### Backend Setup
```bash
cd Backend
npm install
cp .env.example .env  # Add your API keys
npm start
```

### iOS App Setup
```bash
cd iOS
xed .  # Opens in Xcode
# Press Cmd+R to run
```

### Run Automated Tests
```bash
cd Agents
node SimulatorTestAgent.js --full-test
```

## 🔑 Features

### Core Functionality
- **Smart Screenshot Analysis**: Analyzes dating app conversations using Grok Vision
- **Personalized Suggestions**: Generates 3 contextual flirty responses
- **Voice Synthesis**: Converts text to natural speech with ElevenLabs
- **Voice Cloning**: Create custom voice profile (3-minute sample)
- **Keyboard Extension**: Quick access to suggestions (<60MB memory)
- **Share Extension**: Direct screenshot import from other apps

### AI Capabilities
- Conversation stage detection (early, mid, late)
- Interest level analysis
- Personality matching
- Tone calibration (playful, confident, mysterious)
- Multi-language support

## 📱 iOS Components

### Main App
- **Authentication**: Apple Sign In with age verification (18+)
- **Voice Recording**: High-quality audio capture for voice cloning
- **Settings**: Privacy controls, voice management, personalization

### Keyboard Extension
- Memory-optimized (<60MB limit)
- "Flirrt Fresh" instant suggestions
- Screenshot analysis trigger
- Voice playback support

### Share Extension
- Direct screenshot capture
- Automatic compression (max 10MB)
- App Groups data sharing

## 🔧 API Endpoints

### Authentication
- `POST /api/v1/auth/apple` - Apple Sign In
- `POST /api/v1/auth/validate` - Token validation

### Core Features
- `POST /api/v1/analyze_screenshot` - Process conversation screenshot
- `POST /api/v1/generate_flirts` - Generate flirty responses
- `POST /api/v1/synthesize_voice` - Text-to-speech
- `POST /api/v1/voice/clone` - Upload voice sample

### User Management
- `DELETE /api/v1/user/:id/data` - GDPR-compliant deletion

## 🧪 Testing

### Simulator Testing
```bash
# Run full test suite
node Agents/SimulatorTestAgent.js --full-test

# Individual commands
node Agents/SimulatorTestAgent.js build      # Build only
node Agents/SimulatorTestAgent.js screenshot # Capture screen
```

### Manual Testing
1. Open Xcode: `xed iOS`
2. Select "Flirrt Production Device" simulator
3. Press Cmd+R to run
4. Test features:
   - Sign in with Apple
   - Record voice sample
   - Share screenshot
   - Use keyboard extension

## 🔐 Security & Privacy

- **Data Protection**: All user data encrypted at rest
- **Privacy First**: No conversation content stored
- **Age Verification**: 18+ requirement enforced
- **GDPR Compliant**: Full data deletion support
- **Secure APIs**: JWT authentication, rate limiting

## 📊 Performance

### Targets
- App launch: <2 seconds
- Screenshot analysis: <3 seconds
- Voice generation: <2 seconds
- Keyboard memory: <60MB

### Monitoring
- Real-time error tracking
- API response times
- Memory usage alerts
- Crash reporting

## 🚢 Deployment

### TestFlight Distribution
```bash
# Archive and upload
xcodebuild archive -scheme Flirrt
# Upload to App Store Connect
xcrun altool --upload-app
```

### Backend Deployment
```bash
# Deploy to production server
./deploy-backend.sh production
```

## 🐛 Troubleshooting

### Common Issues

**Simulator Not Found**
```bash
xcrun simctl create "Flirrt Production Device" \
  com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro \
  com.apple.CoreSimulator.SimRuntime.iOS-18-6
```

**Build Fails**
```bash
# Clean build folder
rm -rf iOS/build iOS/.build
# Rebuild
cd iOS && swift build
```

**Backend Connection Failed**
- Verify server running: `lsof -i:3000`
- Check .env file has correct API keys
- Ensure firewall allows localhost:3000

## 📝 License
Proprietary - All rights reserved

## 👥 Contributors
- Built with Claude 3.5 Sonnet
- Powered by Grok AI & ElevenLabs

## 📧 Support
For issues and questions, please check the documentation or contact support.

---
Built with ❤️ for better conversations