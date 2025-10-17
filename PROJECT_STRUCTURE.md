# Project Structure - Flirrt.AI

**Last Updated**: October 17, 2025
**Purpose**: Clear directory layout for external reviewers

---

## 📂 Root Directory Overview

```
Flirrt-screens-shots-v1/           # Repository root
├── Backend/                       # ✅ REVIEW THIS - Backend API
├── iOS/                           # ✅ REVIEW THIS - iOS Application
├── Flirrt/                        # 📄 Design docs (not code)
├── .archive/                      # 🗑️ IGNORE - Old code
├── privacy-policy.html            # ✅ Privacy policy
├── README.md                      # ✅ Start here
├── CODE_REVIEW_GUIDE.md           # ✅ Review guide
└── TESTFLIGHT_MANUAL_STEPS.md     # 📘 Deployment guide
```

---

## ✅ REVIEW THESE DIRECTORIES

### 1. Backend/ - Node.js API Server

**Entry Point**: `Backend/server.js`

```
Backend/
├── server.js                      # Main server (START HERE)
├── package.json                   # Dependencies
├── .env.example                   # Environment variables template
│
├── routes/                        # API endpoints
│   ├── flirts.js                  # Core flirt generation logic ⭐
│   ├── auth.js                    # User authentication
│   ├── analysis.js                # Screenshot analysis
│   ├── voice.js                   # Voice synthesis (optional)
│   └── status.js                  # Health check
│
├── services/                      # Business logic
│   ├── grok4FastService.js        # Grok AI integration ⭐
│   ├── geminiVisionService.js     # Google Gemini integration
│   ├── database.js                # Database access layer
│   ├── logger.js                  # Logging utility
│   └── aiOrchestrator.js          # AI pipeline coordinator
│
├── middleware/                    # Express middleware
│   ├── auth.js                    # JWT authentication
│   ├── validation.js              # Input validation ⭐
│   ├── optimizedUpload.js         # File upload handling
│   └── correlationId.js           # Request tracing
│
├── config/                        # Configuration
│   ├── database.js                # DB configuration
│   ├── constants.js               # App constants
│   └── timeouts.js                # Timeout settings
│
├── tests/                         # Jest tests
│   ├── api.test.js                # API endpoint tests
│   ├── validation-enforcement.test.js
│   └── comprehensiveQA.test.js
│
└── data/                          # SQLite database (gitignored)
    └── flirrt.db
```

**Key Files for Security Review**:
- `middleware/auth.js` - Authentication logic
- `middleware/validation.js` - Input validation
- `services/grok4FastService.js` - AI API integration
- `routes/flirts.js` - Core business logic

---

### 2. iOS/ - iOS Application

**Entry Point**: `iOS/Flirrt.xcodeproj` (Open in Xcode)

```
iOS/
├── Flirrt.xcodeproj/              # Xcode project file
│   └── project.pbxproj            # Project configuration
│
├── Flirrt/                        # Main app target
│   ├── App/
│   │   └── FlirrtApp.swift        # App entry point
│   │
│   ├── Config/
│   │   └── AppConstants.swift     # API URLs, configuration ⭐
│   │
│   ├── Services/                  # Business logic
│   │   ├── APIClient.swift        # Network layer ⭐
│   │   ├── AuthManager.swift      # Authentication
│   │   ├── SharedDataManager.swift # App Groups data sharing
│   │   └── ScreenshotDetectionManager.swift
│   │
│   ├── Views/                     # SwiftUI views
│   │   ├── ContentView.swift      # Main view
│   │   ├── LoginView.swift        # Login screen
│   │   ├── MainTabView.swift      # Tab navigation
│   │   ├── SettingsView.swift     # Settings screen
│   │   └── ScreenshotAnalysisView.swift # Screenshot analysis UI
│   │
│   ├── Models/                    # Data models
│   │   ├── FlirtSuggestion.swift  # Flirt data model
│   │   └── PersonalizationData.swift
│   │
│   ├── Resources/
│   │   └── Info.plist             # App metadata
│   │
│   └── Flirrt.entitlements       # iOS entitlements (App Groups)
│
├── FlirrtKeyboard/                # Keyboard extension target ⭐
│   ├── KeyboardViewController.swift # Keyboard logic (CRITICAL)
│   ├── FlirrtKeyboard.entitlements
│   └── FlirrtKeyboard-Info.plist
│
└── FlirrtShare/                   # Share extension target
    ├── ShareViewController.swift  # Screenshot sharing
    ├── FlirrtShare.entitlements
    └── FlirrtShare-Info.plist
```

**Key Files for Security Review**:
- `Flirrt/Config/AppConstants.swift` - API configuration, no hardcoded keys
- `Flirrt/Services/APIClient.swift` - Network security, HTTPS enforcement
- `FlirrtKeyboard/KeyboardViewController.swift` - Keyboard extension logic
- `Flirrt/Flirrt.entitlements` - App permissions

---

## 📄 SKIM THESE (Design Docs)

### 3. Flirrt/ - Design Package (Not Implementation)

```
Flirrt/
├── CLAUDE.md                      # Design instructions (outdated)
├── deliverables/                  # Design specs (not code)
└── research/                      # Research notes
```

**Note**: This directory contains the *original design specifications*, not the actual implementation. The real code is in `Backend/` and `iOS/`.

**Ignore for code review** - Reference only if you need to understand design decisions.

---

## 🗑️ IGNORE THESE

### 4. .archive/ - Old Code (Archived)

```
.archive/
└── old-structure/                 # Previous directory structure
    ├── FlirrtAI-legacy/           # Old nested structure
    ├── Backend-old/               # Outdated backend
    └── iOS-old/                   # Outdated iOS code
```

**Do not review** - This is archived code from previous iterations.

---

## 📘 Documentation Files (Root)

### Essential Docs

| File | Purpose | Priority |
|------|---------|----------|
| `README.md` | Project overview | ⭐ START HERE |
| `CODE_REVIEW_GUIDE.md` | Review checklist | ⭐ CRITICAL |
| `privacy-policy.html` | Privacy policy | ⭐ LEGAL |
| `PROJECT_STRUCTURE.md` | This file | 📘 Reference |
| `TESTFLIGHT_MANUAL_STEPS.md` | TestFlight guide | 📘 Deployment |

### Session Summaries (Optional)

```
├── SESSION_SUMMARY_OCT_11.md      # Development session notes
├── NEXT_SESSION_TESTFLIGHT.md     # Next steps
├── START_TESTING_NOW.md           # Testing guide
└── IPAD_TESTING_GUIDE.md          # iPad test scenarios
```

**Note**: These are internal development notes. Not critical for code review.

---

## 🔍 Review Priority Guide

### Critical Files (Review First)

**Backend**:
1. `Backend/server.js` - Server entry point
2. `Backend/routes/flirts.js` - Core logic
3. `Backend/middleware/auth.js` - Authentication
4. `Backend/middleware/validation.js` - Input validation
5. `Backend/services/grok4FastService.js` - AI integration

**iOS**:
1. `iOS/Flirrt/Config/AppConstants.swift` - Configuration
2. `iOS/Flirrt/Services/APIClient.swift` - Network layer
3. `iOS/FlirrtKeyboard/KeyboardViewController.swift` - Keyboard extension
4. `iOS/Flirrt/Services/SharedDataManager.swift` - Data sharing

### High Priority

**Backend**:
- `Backend/services/database.js` - Database access
- `Backend/middleware/optimizedUpload.js` - File uploads
- `Backend/config/database.js` - DB configuration

**iOS**:
- `iOS/Flirrt/Views/ContentView.swift` - Main UI
- `iOS/Flirrt/Services/AuthManager.swift` - Auth management
- `iOS/FlirrtShare/ShareViewController.swift` - Share extension

### Medium Priority

**Backend**:
- `Backend/tests/*.test.js` - Test suites
- `Backend/services/logger.js` - Logging
- `Backend/routes/*.js` - Other endpoints

**iOS**:
- `iOS/Flirrt/Views/*.swift` - UI components
- `iOS/Flirrt/Models/*.swift` - Data models

### Low Priority

- Documentation files (except CODE_REVIEW_GUIDE.md)
- Session summaries
- Deployment guides (unless testing deployment)

---

## 🚨 What to Watch For

### Security Issues
- [ ] No API keys in code (check `AppConstants.swift`, `server.js`)
- [ ] HTTPS enforced (check `APIClient.swift`)
- [ ] Input validation (check `middleware/validation.js`)
- [ ] SQL injection prevention (check `services/database.js`)
- [ ] Authentication bypass (check `middleware/auth.js`)

### Code Quality Issues
- [ ] Force unwrapping in Swift (search for `!`)
- [ ] Callback hell in JavaScript (should use async/await)
- [ ] Memory leaks in keyboard extension
- [ ] Race conditions in concurrent operations
- [ ] Proper error handling

### Architecture Issues
- [ ] Tight coupling between components
- [ ] Missing error recovery
- [ ] Poor separation of concerns
- [ ] Hardcoded values that should be config

---

## 📊 File Counts (For Reference)

```
Backend:
- Routes: 8 files
- Services: 15 files
- Middleware: 5 files
- Tests: 3 files
Total: ~31 key files

iOS:
- Views: 10 SwiftUI views
- Services: 6 service classes
- Models: 3 data models
- Extensions: 2 (Keyboard, Share)
Total: ~40 key files

Documentation: ~15 markdown files
```

**Estimated Review Time**: 6-8 hours for thorough review

---

## 🛠️ Quick Commands

### Navigate to Code

```bash
cd /Users/macbookairm1/Flirrt-screens-shots-v1

# Backend
cd Backend
npm install
npm test
npm start

# iOS
cd iOS
open Flirrt.xcodeproj
```

### Check Git Status

```bash
git status
git log --oneline -10
```

### Find Files

```bash
# Find all Swift files
find iOS -name "*.swift" | grep -v ".build"

# Find all JavaScript files
find Backend -name "*.js" | grep -v node_modules

# Find configuration files
find . -name "*.plist" -o -name "*.entitlements" -o -name "*.json"
```

---

## 💡 Tips for Reviewers

### First Time Reviewers

1. **Start with README.md** - Get project overview
2. **Read CODE_REVIEW_GUIDE.md** - Understand review focus areas
3. **Check this file** - Understand directory structure
4. **Review critical files first** - Follow priority guide above
5. **Run tests** - Verify backend tests pass
6. **Check for secrets** - Look for API keys in code

### Security Reviewers

Focus on:
- `Backend/middleware/auth.js`
- `Backend/middleware/validation.js`
- `iOS/Flirrt/Config/AppConstants.swift`
- `iOS/Flirrt/Services/APIClient.swift`
- All `.entitlements` files

### iOS Reviewers

Focus on:
- `iOS/Flirrt.xcodeproj/project.pbxproj` - Project config
- `iOS/FlirrtKeyboard/KeyboardViewController.swift` - Main logic
- `iOS/Flirrt/Services/` - All service classes
- Memory management (weak/unowned references)

### Backend Reviewers

Focus on:
- `Backend/server.js` - Server setup
- `Backend/routes/` - All API endpoints
- `Backend/services/` - Business logic
- `Backend/middleware/` - Request processing

---

## 📞 Questions?

If directory structure is still unclear:
- **Check**: `README.md` for high-level overview
- **Check**: `CODE_REVIEW_GUIDE.md` for detailed file paths
- **Ask**: odedbenyair@gmail.com

---

**Last Updated**: October 17, 2025
**Repository**: https://github.com/Oded-Ben-Yair/Flirrt-screens-shots-v1
**Status**: ✅ Cleaned and organized for external review
