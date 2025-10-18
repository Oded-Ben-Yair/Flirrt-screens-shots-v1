# Vibe8.AI - AI-Powered Dating Assistant

**Version**: 1.0 (Build 1)
**Status**: ✅ Production Ready | 🚀 Deployed on Render.com | 📱 TestFlight Ready

---

## Overview

Vibe8.AI is an iOS application that provides AI-powered flirt suggestions for dating conversations. Users can share screenshots of their chats, and the app analyzes the context to generate personalized, contextual conversation starters and replies.

**Key Features**:
- 📸 Screenshot analysis using AI vision models
- 💬 Context-aware flirt suggestion generation
- ⌨️ Custom keyboard extension for seamless integration
- 🔒 Privacy-first: screenshots deleted immediately after analysis
- 🎯 Personalization based on user preferences

---

## Project Structure

```
Vibe8-screens-shots-v1/
├── Backend/                    # Node.js/Express API Server
│   ├── server.js              # Main server entry point
│   ├── routes/                # API route handlers
│   ├── services/              # AI integration services
│   ├── middleware/            # Auth, validation, upload
│   ├── config/                # Configuration files
│   └── tests/                 # Jest test suites
│
├── iOS/                       # iOS Application (Swift/SwiftUI)
│   ├── Vibe8.xcodeproj       # Xcode project
│   ├── Vibe8/                # Main app target
│   │   ├── Config/            # App configuration
│   │   ├── Services/          # API client, auth manager
│   │   ├── Views/             # SwiftUI views
│   │   └── Models/            # Data models
│   ├── Vibe8Keyboard/        # Keyboard extension target
│   └── Vibe8Share/           # Share extension target
│
├── privacy-policy.html        # Privacy policy for App Store
├── CODE_REVIEW_GUIDE.md       # Guide for external reviewers
├── TESTFLIGHT_MANUAL_STEPS.md # TestFlight distribution guide
└── .archive/                  # Archived old code (not for review)
```

---

## Technology Stack

### Backend (Node.js)
- **Runtime**: Node.js 18+
- **Framework**: Express.js
- **Database**: SQLite (development) / PostgreSQL (production-ready)
- **AI APIs**:
  - Grok Vision API (xAI) - Screenshot analysis
  - Google Gemini - Advanced image analysis
  - ElevenLabs - Voice synthesis (optional feature)
- **Deployment**: Render.com
- **Production URL**: https://vibe8-api-production.onrender.com

### iOS (Swift/SwiftUI)
- **Language**: Swift 5+
- **UI Framework**: SwiftUI
- **Minimum iOS**: 17.0+
- **Architecture**: MVVM pattern
- **Communication**: App Groups (`group.com.vibe8`)
- **Bundle IDs**:
  - Main app: `vibe8.ai`
  - Keyboard: `vibe8.ai.keyboard`
  - Share extension: `vibe8.ai.share`

---

## Getting Started

### For External Reviewers

**Start here**: Read [`CODE_REVIEW_GUIDE.md`](CODE_REVIEW_GUIDE.md)

This guide provides:
- Comprehensive security review checklist
- Code quality guidelines for iOS and Backend
- Testing instructions
- Known issues and technical debt
- Files to prioritize for review

### For Developers

#### 1. Backend Setup

```bash
cd Backend
npm install

# Create .env file with API keys (see Backend/.env.example)
# Required keys: GROK_API_KEY, GEMINI_API_KEY, ELEVENLABS_API_KEY, JWT_SECRET

npm start
# Server runs on http://localhost:3000

# Run tests
npm test
```

#### 2. iOS Setup

```bash
cd iOS
open Vibe8.xcodeproj
```

In Xcode:
1. Select `Vibe8` scheme
2. Select target device (iPhone simulator or real device)
3. Press `Cmd+R` to build and run

**Note**: To test keyboard extension, you need a real device (simulators have limitations)

---

## Key Features Explained

### 1. Screenshot Analysis
- User shares a screenshot from a dating app
- Backend receives image via Share Extension
- Grok Vision API analyzes conversation context
- Generates 5 personalized flirt suggestions
- Screenshot deleted immediately after processing

### 2. Keyboard Extension
- Custom keyboard integrated into dating apps
- "Analyze Screenshot" button triggers screenshot upload
- Displays AI-generated suggestions in keyboard
- One-tap to insert suggestion into conversation
- Respects iOS memory limits (60MB max)

### 3. Personalization
- Learns from user's selection patterns (not yet fully implemented)
- Adapts tone based on conversation context
- Considers user's dating preferences (optional questionnaire)

---

## API Endpoints

### Core Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check |
| `/api/v1/flirts/analyze` | POST | Analyze screenshot + generate suggestions |
| `/api/v1/auth/signup` | POST | User registration |
| `/api/v1/auth/login` | POST | User authentication |
| `/api/v1/voice/synthesize` | POST | Voice message generation (optional) |

**Full API documentation**: See `Backend/routes/` for implementation details

---

## Security & Privacy

### Data Handling
- ✅ **No API keys in code**: All keys in environment variables
- ✅ **HTTPS enforced**: Production uses SSL/TLS
- ✅ **Screenshots deleted**: Immediately after analysis
- ✅ **User data encrypted**: Passwords hashed, JWT tokens for auth
- ✅ **App Groups sandboxed**: iOS inter-process communication secured

### Privacy Policy
- **Location**: [`privacy-policy.html`](privacy-policy.html)
- **Hosted at**: https://oded-ben-yair.github.io/Vibe8-screens-shots-v1/privacy-policy.html
- **Compliance**: GDPR/CCPA ready

### Known Security Considerations
- No end-to-end encryption for screenshots (processed on server)
- No crash reporting integrated yet
- API rate limiting implemented but could be enhanced

---

## Testing

### Backend Tests
```bash
cd Backend
npm test
```

**Test suites**:
- `tests/api.test.js` - API endpoint tests
- `tests/validation-enforcement.test.js` - Input validation tests
- `tests/comprehensiveQA.test.js` - Quality assurance tests

### iOS Tests
⚠️ Limited unit tests currently. Manual testing performed via:
- `iOS/PRODUCTION_TESTING_CHECKLIST.md` - Test scenarios
- TestFlight beta testing

### Manual Test Scenarios
See `IPAD_TESTING_GUIDE.md` for comprehensive manual test instructions.

---

## Deployment

### Backend Deployment (Render.com)
**Guide**: `Backend/RENDER_DEPLOYMENT_GUIDE.md`

**Quick steps**:
1. Sign up at https://render.com
2. Create Web Service from GitHub repo
3. Root directory: `Backend`
4. Build command: `npm install`
5. Start command: `npm start`
6. Add environment variables from `.env`

### iOS Deployment (TestFlight)
**Guide**: `TESTFLIGHT_MANUAL_STEPS.md`

**Quick steps**:
1. Register bundle IDs at https://developer.apple.com/account
2. Create app at https://appstoreconnect.apple.com
3. Create distribution certificate + provisioning profiles
4. Archive in Xcode: Product → Archive
5. Upload to App Store Connect
6. Wait for processing (10-15 min)
7. Invite beta testers

---

## Configuration

### Environment Variables (Backend)

Create `Backend/.env`:
```bash
# AI APIs
GROK_API_KEY=xai-your-key-here
GEMINI_API_KEY=your-gemini-key
ELEVENLABS_API_KEY=sk_your-elevenlabs-key

# App
JWT_SECRET=your-secret-key
NODE_ENV=production
PORT=3000

# Database (optional, defaults to SQLite)
DATABASE_URL=postgresql://user:pass@host:5432/dbname
```

### iOS Configuration

**File**: `iOS/Vibe8/Config/AppConstants.swift`

```swift
static var apiBaseURL: String {
    switch environment {
    case .development:
        return "http://localhost:3000/api/v1"
    case .production:
        return "https://vibe8-api-production.onrender.com/api/v1"
    }
}
```

---

## Development Workflow

### Branching Strategy
- **main**: Production-ready code
- **development**: Active development (not currently used)
- Feature branches: Created as needed

### Commit Guidelines
- Use conventional commits: `feat:`, `fix:`, `docs:`, `chore:`
- Reference issues when applicable
- Keep commits atomic and focused

### Code Review Process
See `CODE_REVIEW_GUIDE.md` for comprehensive review checklist.

---

## Known Issues & Technical Debt

### High Priority
1. **No end-to-end tests** - Only unit and integration tests
2. **Limited error tracking** - No crash reporting service
3. **Database not fully deployed** - Using SQLite for MVP

### Medium Priority
1. **Voice features disabled in UI** - Backend ready but not exposed
2. **No caching layer** - Every request hits AI APIs
3. **Keyboard memory optimization** - Could be improved

### Low Priority
1. **UI polish needed** - Functional but basic
2. **No localization** - English only
3. **No analytics** - No usage tracking

**Full list**: See `CODE_REVIEW_GUIDE.md` section 🚨 Known Issues

---

## Performance Benchmarks

### iOS App
- Cold start: < 2s
- Screenshot detection: < 2s
- API response: 2-5s (AI processing)
- Memory usage (keyboard): ~20MB (limit: 60MB)

### Backend
- Response time: 2-5s (depends on AI API)
- Throughput: ~100 req/min (Render free tier)
- Uptime: 99.9% (Render SLA)

---

## Contributing

### For External Contributors
1. Fork the repository
2. Create a feature branch
3. Make your changes with tests
4. Submit a pull request
5. Ensure CI passes (when implemented)

### Code Style
- **Swift**: Follow Swift API Design Guidelines
- **JavaScript**: ES6+, async/await (no callbacks)
- **Linting**: Not yet configured (TODO)

---

## License

**Status**: Not yet licensed (to be added)

---

## Contact & Support

**Developer**: Oded Ben Yair
**Email**: odedbenyair@gmail.com
**Repository**: https://github.com/Oded-Ben-Yair/Vibe8-screens-shots-v1

**API Status**: https://vibe8-api-production.onrender.com/health

---

## Quick Links

| Resource | URL |
|----------|-----|
| **Privacy Policy** | https://oded-ben-yair.github.io/Vibe8-screens-shots-v1/privacy-policy.html |
| **Backend API** | https://vibe8-api-production.onrender.com |
| **Apple Developer** | https://developer.apple.com/account |
| **App Store Connect** | https://appstoreconnect.apple.com |
| **Render Dashboard** | https://dashboard.render.com |
| **xAI Console** | https://console.x.ai |

---

## Roadmap

### v1.0 (Current - MVP)
- ✅ Screenshot analysis
- ✅ AI flirt generation
- ✅ iOS keyboard extension
- ✅ Share extension
- ✅ Basic personalization

### v1.1 (Next)
- ⏳ Enhanced personalization engine
- ⏳ Voice message feature (UI)
- ⏳ Improved caching
- ⏳ Analytics integration
- ⏳ UI polish

### v2.0 (Future)
- 📋 Android support
- 📋 Real-time conversation coaching
- 📋 Premium subscription features
- 📋 Advanced AI personalities
- 📋 Multi-language support

---

**Last Updated**: October 17, 2025
**Version**: 1.0 (Build 1)
**Status**: ✅ Production Ready

---

**Ready for external code review!** 🚀

For reviewers: Start with [`CODE_REVIEW_GUIDE.md`](CODE_REVIEW_GUIDE.md)
