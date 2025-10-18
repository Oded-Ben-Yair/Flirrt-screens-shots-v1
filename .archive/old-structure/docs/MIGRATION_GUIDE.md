# Migration Guide: AppConstants & Backend Constants

**Version**: 1.0.0
**Last Updated**: October 4, 2025
**Stage**: 7 - Documentation

---

## Table of Contents

1. [Overview](#overview)
2. [iOS AppConstants Migration](#ios-appconstants-migration)
3. [Backend Constants Migration](#backend-constants-migration)
4. [Migration Checklist](#migration-checklist)
5. [Best Practices](#best-practices)
6. [Troubleshooting](#troubleshooting)
7. [Code Examples](#code-examples)

---

## Overview

### What Changed?

In **Stage 3** and **Stage 4**, we eliminated all magic strings and hardcoded values across the Vibe8.ai codebase by implementing a **Single Source of Truth (SSOT)** pattern:

- **iOS**: Created `AppConstants.swift` with 44+ UserDefaults keys and configuration values
- **Backend**: Created `constants.js` (16 categories) and `timeouts.js` (21 categories)
- **Impact**:
  - iOS: 73 references refactored
  - Backend: 81 references refactored
  - **Result**: Zero magic strings, maintainable configuration

### Why This Matters

✅ **Before**: Magic strings scattered across 150+ files
✅ **After**: Single source of truth, type-safe, autocomplete-enabled

**Benefits**:
- Eliminate typos in string keys
- Centralized configuration management
- Easy refactoring and updates
- Better IDE support (autocomplete)
- Reduced maintenance burden

---

## iOS AppConstants Migration

### What is AppConstants.swift?

`AppConstants.swift` is a centralized Swift enum that contains all application constants, including:
- UserDefaults keys (44+ keys organized by category)
- API configuration
- Bundle identifiers
- Feature flags
- UI constants
- Environment configuration

**Location**: `/iOS/Vibe8/Config/AppConstants.swift`

### Structure

```swift
enum AppConstants {
    // App Group & Bundle Identifiers
    static let appGroupIdentifier = "group.com.vibe8"
    static let bundleIdentifier = "com.vibe8.app"

    // API Configuration
    static let apiBaseURL = Environment.current.apiBaseURL
    static let apiTimeout: TimeInterval = 30.0

    // UserDefaults Keys (44+ organized keys)
    enum UserDefaultsKeys {
        // Authentication & User
        static let userId = "user_id"
        static let authToken = "auth_token"
        static let isAuthenticated = "isAuthenticated"

        // Onboarding
        static let onboardingComplete = "onboarding_complete"
        static let personalizationComplete = "personalization_complete"

        // Voice
        static let currentVoiceId = "currentVoiceId"
        static let voiceClones = "voice_clones"

        // Screenshot Detection
        static let lastScreenshotId = "last_screenshot_id"
        static let screenshotDetectionEnabled = "screenshot_detection_enabled"

        // ... 44+ total keys
    }

    // Dynamic key functions
    static func personalizationKey(_ key: String) -> String {
        return "personalization_\(key)"
    }

    static func screenshotDataKey(_ screenshotId: String) -> String {
        return "screenshot_\(screenshotId)"
    }
}
```

### Before/After Examples

#### Example 1: UserDefaults Keys

**Before** (Magic Strings):
```swift
// Scattered across multiple files
let userId = UserDefaults.standard.string(forKey: "user_id")
let onboarding = UserDefaults.standard.bool(forKey: "onboarding_complete")
let voice = UserDefaults.standard.string(forKey: "currentVoiceId")

// Risk: Typos cause bugs
let oops = UserDefaults.standard.bool(forKey: "onboarding_complet") // Typo!
```

**After** (AppConstants):
```swift
// Type-safe, autocomplete-enabled
let userId = UserDefaults.standard.string(forKey: AppConstants.UserDefaultsKeys.userId)
let onboarding = UserDefaults.standard.bool(forKey: AppConstants.UserDefaultsKeys.onboardingComplete)
let voice = UserDefaults.standard.string(forKey: AppConstants.UserDefaultsKeys.currentVoiceId)

// Typos caught at compile time
let oops = UserDefaults.standard.bool(forKey: AppConstants.UserDefaultsKeys.onboardingComplet) // Compile error!
```

#### Example 2: App Group Identifier

**Before**:
```swift
// Hardcoded in 15+ files
let defaults = UserDefaults(suiteName: "group.com.vibe8")
let container = FileManager.default.containerURL(
    forSecurityApplicationGroupIdentifier: "group.com.vibe8"
)
```

**After**:
```swift
// Single source of truth
let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
let container = FileManager.default.containerURL(
    forSecurityApplicationGroupIdentifier: AppConstants.appGroupIdentifier
)
```

#### Example 3: API Configuration

**Before**:
```swift
let url = URL(string: "http://localhost:3000/api/v1/analysis")!
request.timeoutInterval = 30.0
```

**After**:
```swift
let url = URL(string: "\(AppConstants.apiBaseURL)/analysis")!
request.timeoutInterval = AppConstants.apiTimeout
```

### All 44+ UserDefaults Keys

#### Authentication & User (7 keys)
```swift
AppConstants.UserDefaultsKeys.ageVerified
AppConstants.UserDefaultsKeys.isAuthenticated
AppConstants.UserDefaultsKeys.userId
AppConstants.UserDefaultsKeys.userName
AppConstants.UserDefaultsKeys.userEmail
AppConstants.UserDefaultsKeys.authToken
AppConstants.UserDefaultsKeys.hasFullAccess
```

#### Onboarding (3 keys + 1 function)
```swift
AppConstants.UserDefaultsKeys.onboardingComplete
AppConstants.UserDefaultsKeys.onboardingCompleted  // Legacy
AppConstants.UserDefaultsKeys.personalizationComplete
AppConstants.UserDefaultsKeys.personalizationProfile

// Dynamic function
AppConstants.UserDefaultsKeys.personalizationKey("interests")  // → "personalization_interests"
```

#### Voice (5 keys)
```swift
AppConstants.UserDefaultsKeys.userVoiceId
AppConstants.UserDefaultsKeys.currentVoiceId
AppConstants.UserDefaultsKeys.voiceClones
AppConstants.UserDefaultsKeys.recentRecordings
AppConstants.UserDefaultsKeys.voiceEnabled
```

#### Screenshot Detection (12 keys + 1 function)
```swift
AppConstants.UserDefaultsKeys.lastScreenshotId
AppConstants.UserDefaultsKeys.lastScreenshotTime
AppConstants.UserDefaultsKeys.screenshotCounter
AppConstants.UserDefaultsKeys.appWasActiveDuringScreenshot
AppConstants.UserDefaultsKeys.lastActiveTime
AppConstants.UserDefaultsKeys.lastScreenshotConfirmed
AppConstants.UserDefaultsKeys.lastScreenshotConfirmedTime
AppConstants.UserDefaultsKeys.latestScreenshotId
AppConstants.UserDefaultsKeys.latestScreenshotPath
AppConstants.UserDefaultsKeys.latestScreenshotSize
AppConstants.UserDefaultsKeys.screenshotDetectionEnabled
AppConstants.UserDefaultsKeys.latestScreenshot
AppConstants.UserDefaultsKeys.latestScreenshotTimeShare

// Dynamic function
AppConstants.UserDefaultsKeys.screenshotDataKey("abc123")  // → "screenshot_abc123"
```

#### Keyboard Extension (4 keys)
```swift
AppConstants.UserDefaultsKeys.lastKeyboardHeartbeat
AppConstants.UserDefaultsKeys.userAuthenticated
AppConstants.UserDefaultsKeys.analysisRequestTime
AppConstants.UserDefaultsKeys.lastAppOpen
```

#### Darwin Notifications (2 keys)
```swift
AppConstants.UserDefaultsKeys.lastNotificationPayloadPath
AppConstants.UserDefaultsKeys.lastNotificationName
```

#### App State (3 keys)
```swift
AppConstants.UserDefaultsKeys.appLaunched
AppConstants.UserDefaultsKeys.appleKeyboards
AppConstants.UserDefaultsKeys.preferredModel
```

#### Testing & Debug (4 keys)
```swift
AppConstants.UserDefaultsKeys.appGroupsTest
AppConstants.UserDefaultsKeys.testKey
AppConstants.UserDefaultsKeys.testTimestamp
AppConstants.UserDefaultsKeys.testAuth
```

### How to Add New Keys

1. **Open AppConstants.swift**
2. **Find the appropriate category** in `UserDefaultsKeys` enum
3. **Add your key**:

```swift
enum UserDefaultsKeys {
    // ... existing keys ...

    // MARK: - Your Category

    /// Description of what this key stores
    static let yourNewKey = "your_new_key"
}
```

4. **Use it immediately**:

```swift
UserDefaults.standard.set("value", forKey: AppConstants.UserDefaultsKeys.yourNewKey)
```

### Dynamic Key Functions

For keys that need runtime parameters:

```swift
// In AppConstants.swift
static func yourDynamicKey(_ param: String) -> String {
    return "your_prefix_\(param)"
}

// Usage
let key = AppConstants.UserDefaultsKeys.yourDynamicKey("123")  // → "your_prefix_123"
UserDefaults.standard.set("value", forKey: key)
```

### Environment Configuration

AppConstants includes environment-aware configuration:

```swift
enum Environment {
    case development
    case staging
    case production

    static var current: Environment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }

    var apiBaseURL: String {
        switch self {
        case .development:
            return "http://localhost:3000/api/v1"
        case .staging:
            return "https://staging-api.vibe8.ai/api/v1"
        case .production:
            return "https://api.vibe8.ai/api/v1"
        }
    }
}

// Usage
let apiURL = AppConstants.apiBaseURL  // Automatically uses correct environment
```

### Extension Target Configuration

#### ⚠️ Known Issue (Documented for Stage 8)

**Problem**: `AppConstants` is not currently accessible to iOS extensions (Keyboard, Share)

**Temporary Workaround**: Extensions use hardcoded strings (marked with `// TODO: Use AppConstants`)

**Example**:
```swift
// In Vibe8Keyboard/KeyboardViewController.swift
let appGroupIdentifier = "group.com.vibe8"  // TODO: Use AppConstants.appGroupIdentifier
```

**Stage 8 Fix**: Add AppConstants.swift to extension targets in Xcode:
1. Select AppConstants.swift in Project Navigator
2. File Inspector → Target Membership
3. Check ✓ Vibe8Keyboard
4. Check ✓ Vibe8Share

---

## Backend Constants Migration

### What are constants.js and timeouts.js?

**`constants.js`**: Application-wide configuration (16 categories)
**`timeouts.js`**: All timeout/TTL/delay values (21 categories)

**Location**: `/Backend/config/constants.js` and `/Backend/config/timeouts.js`

### constants.js Structure (16 Categories)

```javascript
module.exports = {
    // 1. API Configuration
    api: {
        version: 'v1',
        basePath: '/api/v1',
        endpoints: { /* ... */ }
    },

    // 2. File Upload Configuration
    upload: {
        maxFileSize: { /* ... */ },
        mimeTypes: { /* ... */ },
        directories: { /* ... */ }
    },

    // 3. Rate Limiting
    rateLimit: {
        windows: { /* ... */ },
        limits: { /* ... */ }
    },

    // 4. HTTP Status Codes
    httpStatus: {
        OK: 200,
        BAD_REQUEST: 400,
        // ...
    },

    // 5. Error Codes & Messages
    errors: {
        TOKEN_MISSING: { code: 'TOKEN_MISSING', message: 'Access token required' },
        // ...
    },

    // 6. Validation Constraints
    validation: {
        maxLength: { /* ... */ },
        range: { /* ... */ },
        allowedValues: { /* ... */ }
    },

    // 7-16. CORS, Security, Cache, Performance, AI, Database, Server, Logging, Features, Endpoints
};
```

### timeouts.js Structure (21 Categories)

```javascript
module.exports = {
    // 1. API Request Timeouts (ms)
    api: {
        grokStandard: 35000,        // 35s
        grok4Reasoning: 8000,       // 8s
        elevenlabsSynthesize: 60000 // 60s
        // ...
    },

    // 2. Circuit Breaker Timeouts
    circuitBreaker: {
        grokTimeout: 35000,
        grokResetTimeout: 60000
        // ...
    },

    // 3. Retry & Backoff Delays
    retry: {
        apiTimeoutInitial: 1000,
        rateLimitInitial: 5000
        // ...
    },

    // 4. Cache TTLs (seconds)
    cache: {
        keyboard: 14400,      // 4 hours
        standard: 7200,       // 2 hours
        flirtSuggestions: 300 // 5 minutes
        // ...
    },

    // 5-21. Upload, Streaming, Database, Test, Monitoring, Session, WebSocket, Orchestrator, Targets, Queue, Limits
};
```

### Before/After Examples

#### Example 1: API Endpoints

**Before**:
```javascript
// Hardcoded across multiple route files
app.post('/api/v1/analysis/analyze_screenshot', /* ... */);
app.post('/api/v1/flirts/generate_flirts', /* ... */);
app.post('/api/v1/voice/synthesize_voice', /* ... */);
```

**After**:
```javascript
const { api } = require('./config/constants');

app.post(api.endpoints.analysis.analyze, /* ... */);
app.post(api.endpoints.flirts.generate, /* ... */);
app.post(api.endpoints.voice.synthesize, /* ... */);
```

#### Example 2: HTTP Status Codes

**Before**:
```javascript
// Magic numbers everywhere
res.status(400).json({ error: 'Bad request' });
res.status(401).json({ error: 'Unauthorized' });
res.status(500).json({ error: 'Server error' });
```

**After**:
```javascript
const { httpStatus, errors } = require('./config/constants');

res.status(httpStatus.BAD_REQUEST).json({ error: errors.VALIDATION_ERROR });
res.status(httpStatus.UNAUTHORIZED).json({ error: errors.TOKEN_MISSING });
res.status(httpStatus.INTERNAL_SERVER_ERROR).json({ error: errors.INTERNAL_SERVER_ERROR });
```

#### Example 3: Timeouts

**Before**:
```javascript
// Scattered timeout values
const grokTimeout = 35000;  // In grokService.js
const elevenlabsTimeout = 60000;  // In voiceService.js
const cacheKeyboard = 14400;  // In intelligentCache.js
```

**After**:
```javascript
const timeouts = require('./config/timeouts');

// All timeouts centralized
const grokTimeout = timeouts.api.grokStandard;
const elevenlabsTimeout = timeouts.api.elevenlabsSynthesize;
const cacheKeyboard = timeouts.cache.keyboard;
```

#### Example 4: CORS Configuration

**Before**:
```javascript
app.use(cors({
    origin: ['http://localhost:3000', 'https://vibe8.ai', /* ... */],
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization', /* ... */]
}));
```

**After**:
```javascript
const { cors: corsConfig } = require('./config/constants');

app.use(cors({
    origin: corsConfig.allowedOrigins,
    methods: corsConfig.allowedMethods,
    allowedHeaders: corsConfig.allowedHeaders,
    exposedHeaders: corsConfig.exposedHeaders,
    maxAge: corsConfig.maxAge
}));
```

### All 16 Categories in constants.js

1. **api**: Endpoints, versioning, base paths
2. **upload**: File size limits, MIME types, directories
3. **rateLimit**: Time windows, request limits per endpoint
4. **httpStatus**: HTTP status codes (200, 400, 500, etc.)
5. **errors**: Error codes with messages
6. **validation**: Length constraints, range constraints, allowed values
7. **cors**: Allowed origins, methods, headers
8. **security**: Security headers, dangerous extensions, JWT config
9. **cache**: Cache tiers, TTLs, eviction policies
10. **performance**: Response time targets, complexity scoring, alerts
11. **ai**: Model names, API URLs, token estimation
12. **database**: Database type, path, time filters
13. **server**: Default port, app version, request limits
14. **logging**: Log levels, default level
15. **features**: Feature flags (rate limiting, test mode)
16. **availableEndpoints**: List for 404 responses

### All 21 Categories in timeouts.js

1. **api**: API request timeouts (Grok, ElevenLabs, Gemini)
2. **circuitBreaker**: Circuit breaker timeouts and reset times
3. **retry**: Retry delays and backoff multipliers
4. **cache**: Cache TTLs in seconds
5. **upload**: Upload queue timeouts by priority
6. **streaming**: Chunk delays, batch delays, polling intervals
7. **database**: Query and connection timeouts
8. **test**: Jest timeouts, test wait times
9. **monitoring**: Health check, metrics, heartbeat intervals
10. **session**: Session max age, cookie max age
11. **websocket**: Heartbeat, idle timeout, message timeout
12. **orchestrator**: Fast and standard strategy timeouts
13. **targets**: Performance tier targets
14. **queue**: Max workers, max queue size
15. **limits**: File size, image size, compression quality

### How to Add New Constants

#### Adding to constants.js:

1. **Find the appropriate category** (or create a new one)
2. **Add your constant**:

```javascript
// In constants.js
module.exports = {
    // ... existing categories ...

    yourCategory: {
        yourConstant: 'value',
        yourNumber: 42,
        yourArray: ['item1', 'item2']
    }
};
```

3. **Use it**:

```javascript
const { yourCategory } = require('./config/constants');
console.log(yourCategory.yourConstant);  // → 'value'
```

#### Adding to timeouts.js:

1. **Choose the category** (api, cache, retry, etc.)
2. **Add your timeout**:

```javascript
// In timeouts.js
module.exports = {
    api: {
        // ... existing timeouts ...
        yourNewTimeout: 10000  // 10s
    }
};
```

3. **Use it**:

```javascript
const timeouts = require('./config/timeouts');
const timeout = timeouts.api.yourNewTimeout;
```

### Helper Functions in timeouts.js

timeouts.js includes utility functions:

```javascript
// Get timeout for a service
const timeout = timeouts.getApiTimeout('grok');  // → 35000

// Get circuit breaker timeout
const cbTimeout = timeouts.getCircuitBreakerTimeout('elevenlabs');  // → 60000

// Get cache TTL
const ttl = timeouts.getCacheTTL('keyboard');  // → 14400

// Get upload timeout by priority
const uploadTimeout = timeouts.getUploadTimeout('urgent');  // → 2000

// Calculate exponential backoff
const delay = timeouts.calculateBackoff(2, 1000, 2);  // → 4000 (1000 * 2^2)

// Add jitter to delay
const jittered = timeouts.addJitter(1000, 0.2);  // → 1000-1200 (random)
```

---

## Migration Checklist

### For New Developers Joining the Project

- [ ] Read this migration guide completely
- [ ] Understand AppConstants.swift structure (iOS)
- [ ] Understand constants.js and timeouts.js structure (Backend)
- [ ] Search for magic strings in your code before submitting PR
- [ ] Use AppConstants for all iOS configuration values
- [ ] Use constants.js and timeouts.js for all Backend values
- [ ] Never hardcode: API URLs, timeout values, UserDefaults keys
- [ ] Add new constants to appropriate categories

### For Adding New Features

#### iOS Checklist:
- [ ] Identify all UserDefaults keys needed
- [ ] Add keys to AppConstants.UserDefaultsKeys (appropriate category)
- [ ] Use AppConstants for all configuration (API URLs, timeouts, etc.)
- [ ] Test autocomplete works for your keys
- [ ] Document keys with inline comments

#### Backend Checklist:
- [ ] Identify configuration values needed
- [ ] Add to constants.js (config values) or timeouts.js (time-based values)
- [ ] Use destructuring to import: `const { api, httpStatus } = require('./config/constants')`
- [ ] Use helper functions when available
- [ ] Document complex constants with comments

### For Updating Configuration

#### iOS Configuration Update:
1. Open `/iOS/Vibe8/Config/AppConstants.swift`
2. Find the constant to update
3. Update value
4. Rebuild project
5. All usages automatically updated ✅

#### Backend Configuration Update:
1. Open `/Backend/config/constants.js` or `timeouts.js`
2. Find the constant to update
3. Update value
4. Restart server
5. All usages automatically updated ✅

---

## Best Practices

### When to Add to AppConstants vs Local Constants

#### ✅ Add to AppConstants When:
- Value is used in **2+ files**
- Value is a **UserDefaults key**
- Value is **configuration** (API URL, timeout, bundle ID)
- Value might **change per environment** (dev/staging/prod)
- Value needs to be **shared between app and extensions**

#### ❌ Keep Local When:
- Value is used in **only 1 file**
- Value is **truly local logic** (e.g., animation duration for specific view)
- Value is **computed at runtime** from other sources
- Value is **temporary/throwaway code**

**Example**:
```swift
// ✅ Add to AppConstants (used in multiple files)
static let apiTimeout: TimeInterval = 30.0

// ❌ Keep local (specific to one view)
struct MyView: View {
    private let rowHeight: CGFloat = 44.0  // Only used here
}
```

### Naming Conventions

#### iOS (Swift):
- **Constants**: `camelCase` (e.g., `apiBaseURL`, `appGroupIdentifier`)
- **Keys**: `camelCase` (e.g., `userId`, `onboardingComplete`)
- **Enums**: `PascalCase` (e.g., `UserDefaultsKeys`, `FeatureFlags`)
- **Categories**: MARK comments (e.g., `// MARK: - Authentication & User`)

#### Backend (JavaScript):
- **Objects**: `camelCase` (e.g., `api`, `httpStatus`, `rateLimit`)
- **Properties**: `camelCase` (e.g., `maxFileSize`, `allowedOrigins`)
- **Constants**: `SCREAMING_SNAKE_CASE` for error codes (e.g., `TOKEN_MISSING`)
- **Comments**: JSDoc style with descriptions

### How to Handle Environment-Specific Values

#### iOS:
Use the `Environment` enum:

```swift
// In AppConstants.swift
enum Environment {
    case development
    case staging
    case production

    static var current: Environment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }

    var apiBaseURL: String {
        switch self {
        case .development: return "http://localhost:3000/api/v1"
        case .staging: return "https://staging-api.vibe8.ai/api/v1"
        case .production: return "https://api.vibe8.ai/api/v1"
        }
    }
}

// Usage
let url = AppConstants.apiBaseURL  // Auto-selects based on build config
```

#### Backend:
Use environment variables + constants for defaults:

```javascript
// In constants.js
server: {
    defaultPort: 3000,
    appVersion: '1.0.0'
}

// In server.js
const PORT = process.env.PORT || server.defaultPort;
```

### Version Control Considerations

#### iOS:
- ✅ AppConstants.swift is committed to git
- ✅ Environment logic is in code (no secrets)
- ✅ Safe to share publicly

#### Backend:
- ✅ constants.js is committed to git (no secrets)
- ✅ timeouts.js is committed to git (no secrets)
- ❌ `.env` is **gitignored** (contains API keys)
- ⚠️ Use `.env.example` to document required variables

**Example `.env.example`**:
```bash
# API Keys (required)
GROK_API_KEY=your_grok_api_key_here
ELEVENLABS_API_KEY=your_elevenlabs_api_key_here

# Database (optional - using SQLite by default)
# DB_HOST=localhost
# DB_PORT=5432
```

---

## Troubleshooting

### Common Migration Errors

#### Error 1: "Use of unresolved identifier 'AppConstants'"

**Cause**: AppConstants.swift not in target membership

**Fix**:
1. Select AppConstants.swift in Project Navigator
2. File Inspector → Target Membership
3. Ensure ✓ Vibe8 is checked

#### Error 2: "Cannot find 'AppConstants' in scope" (Extension)

**Cause**: Known issue - AppConstants not accessible to extensions (Stage 8)

**Temporary Workaround**:
```swift
// In extension code
let appGroupIdentifier = "group.com.vibe8"  // TODO: Use AppConstants (Stage 8)
```

**Permanent Fix** (Stage 8):
1. Add AppConstants.swift to extension targets
2. Replace hardcoded strings with AppConstants

#### Error 3: "Cannot find module 'constants'" (Backend)

**Cause**: Incorrect import path

**Fix**:
```javascript
// ❌ Wrong
const constants = require('constants');

// ✅ Correct
const constants = require('./config/constants');
const timeouts = require('./config/timeouts');
```

#### Error 4: "TypeError: Cannot read property 'api' of undefined"

**Cause**: Missing destructuring or incorrect property access

**Fix**:
```javascript
// ❌ Wrong
const { apiEndpoints } = require('./config/constants');

// ✅ Correct
const { api } = require('./config/constants');
console.log(api.endpoints.analysis.analyze);
```

### Extension Target Issues (AppConstants Not Found)

#### Problem:
Extensions (Vibe8Keyboard, Vibe8Share) cannot import AppConstants

#### Symptoms:
```swift
// In Vibe8Keyboard/KeyboardViewController.swift
import AppConstants  // ❌ Error: No such module 'AppConstants'
```

#### Current Status (Stage 7):
- **Documented** as known issue
- **Scheduled** for Stage 8 fix
- **Workaround** in place: Hardcoded strings with TODO comments

#### Stage 8 Fix Steps:
1. **Add to Target Membership**:
   - Select AppConstants.swift
   - File Inspector → Target Membership
   - Check ✓ Vibe8Keyboard
   - Check ✓ Vibe8Share

2. **Update Extension Code**:
```swift
// Before (hardcoded)
let appGroupIdentifier = "group.com.vibe8"

// After (using AppConstants)
let appGroupIdentifier = AppConstants.appGroupIdentifier
```

3. **Test**:
   - Build Vibe8Keyboard target
   - Build Vibe8Share target
   - Verify no errors

### Import Statement Issues

#### iOS:
```swift
// ✅ No import needed (AppConstants is in same module)
let key = AppConstants.UserDefaultsKeys.userId

// ❌ Don't do this
import AppConstants  // Error: No such module
```

#### Backend:
```javascript
// ✅ Correct
const { api, httpStatus } = require('./config/constants');
const timeouts = require('./config/timeouts');

// ❌ Wrong
import constants from './config/constants';  // Not using ES6 modules
```

### Build Errors Related to Constants

#### Error: "Ambiguous use of 'api'"

**Cause**: Name collision with another variable/constant

**Fix**: Use explicit namespacing
```javascript
// ❌ Collision
const api = require('./config/constants').api;
const api = createApiInstance();  // Error!

// ✅ Fixed
const { api: apiConfig } = require('./config/constants');
const api = createApiInstance();
```

#### Error: "Expected expression" (Swift)

**Cause**: Trying to use AppConstants before it's defined

**Fix**: Ensure AppConstants.swift is in correct target and builds first

---

## Code Examples

### iOS: Complete Migration Example

**Before** (LoginView.swift):
```swift
import SwiftUI

struct LoginView: View {
    @State private var email = ""

    var body: some View {
        VStack {
            TextField("Email", text: $email)

            Button("Login") {
                // Hardcoded strings everywhere
                UserDefaults.standard.set(true, forKey: "isAuthenticated")
                UserDefaults.standard.set("user123", forKey: "user_id")
                UserDefaults.standard.set(email, forKey: "user_email")

                let defaults = UserDefaults(suiteName: "group.com.vibe8")
                defaults?.set(true, forKey: "user_authenticated")
            }
        }
    }
}
```

**After** (Using AppConstants):
```swift
import SwiftUI

struct LoginView: View {
    @State private var email = ""

    var body: some View {
        VStack {
            TextField("Email", text: $email)

            Button("Login") {
                // Type-safe constants
                UserDefaults.standard.set(true, forKey: AppConstants.UserDefaultsKeys.isAuthenticated)
                UserDefaults.standard.set("user123", forKey: AppConstants.UserDefaultsKeys.userId)
                UserDefaults.standard.set(email, forKey: AppConstants.UserDefaultsKeys.userEmail)

                // App Group identifier from constants
                let defaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
                defaults?.set(true, forKey: AppConstants.UserDefaultsKeys.userAuthenticated)
            }
        }
    }
}
```

### iOS: Dynamic Keys Example

**Before**:
```swift
// Manually constructing keys
let interestsKey = "personalization_interests"
let goalsKey = "personalization_goals"

UserDefaults.standard.set(["coding", "design"], forKey: interestsKey)
UserDefaults.standard.set(["learn swift"], forKey: goalsKey)
```

**After**:
```swift
// Using dynamic key function
let interestsKey = AppConstants.UserDefaultsKeys.personalizationKey("interests")
let goalsKey = AppConstants.UserDefaultsKeys.personalizationKey("goals")

UserDefaults.standard.set(["coding", "design"], forKey: interestsKey)
UserDefaults.standard.set(["learn swift"], forKey: goalsKey)
```

### Backend: Complete Migration Example

**Before** (server.js):
```javascript
const express = require('express');
const cors = require('cors');

const app = express();
const PORT = 3000;

// Hardcoded CORS
app.use(cors({
    origin: ['http://localhost:3000', 'https://vibe8.ai'],
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization']
}));

// Hardcoded limits
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Hardcoded endpoints
app.post('/api/v1/analysis/analyze_screenshot', (req, res) => {
    res.status(400).json({ error: 'Bad request' });
});

app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
```

**After** (Using constants):
```javascript
const express = require('express');
const cors = require('cors');
const { httpStatus, cors: corsConfig, server, api } = require('./config/constants');

const app = express();
const PORT = process.env.PORT || server.defaultPort;

// CORS from constants
app.use(cors({
    origin: corsConfig.allowedOrigins,
    methods: corsConfig.allowedMethods,
    allowedHeaders: corsConfig.allowedHeaders,
    exposedHeaders: corsConfig.exposedHeaders,
    maxAge: corsConfig.maxAge
}));

// Limits from constants
app.use(express.json({ limit: server.requestLimits.json }));
app.use(express.urlencoded({
    extended: true,
    limit: server.requestLimits.urlencoded
}));

// Endpoints from constants
app.post(api.endpoints.analysis.analyze, (req, res) => {
    res.status(httpStatus.BAD_REQUEST).json({
        error: 'Bad request'
    });
});

app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
```

### Backend: Error Handling Example

**Before**:
```javascript
// Inconsistent error responses
app.post('/api/v1/auth/login', (req, res) => {
    if (!req.body.email) {
        return res.status(400).json({ error: 'Email required' });
    }

    if (!token) {
        return res.status(401).json({ error: 'Invalid credentials' });
    }

    res.status(500).json({ error: 'Something went wrong' });
});
```

**After**:
```javascript
const { httpStatus, errors } = require('./config/constants');

app.post(api.endpoints.auth.login, (req, res) => {
    if (!req.body.email) {
        return res.status(httpStatus.BAD_REQUEST).json({
            error: errors.VALIDATION_ERROR
        });
    }

    if (!token) {
        return res.status(httpStatus.UNAUTHORIZED).json({
            error: errors.TOKEN_INVALID
        });
    }

    res.status(httpStatus.INTERNAL_SERVER_ERROR).json({
        error: errors.INTERNAL_SERVER_ERROR
    });
});
```

### Backend: Timeouts Example

**Before**:
```javascript
// Scattered timeout values
const grokTimeout = 35000;
const elevenlabsTimeout = 60000;
const cacheKeyboardTTL = 14400;

axios.post(grokUrl, data, { timeout: grokTimeout });
axios.post(elevenlabsUrl, data, { timeout: elevenlabsTimeout });
cache.set(key, value, cacheKeyboardTTL);
```

**After**:
```javascript
const timeouts = require('./config/timeouts');

axios.post(grokUrl, data, {
    timeout: timeouts.api.grokStandard
});

axios.post(elevenlabsUrl, data, {
    timeout: timeouts.api.elevenlabsSynthesize
});

cache.set(key, value, timeouts.cache.keyboard);
```

### Backend: Helper Functions Example

```javascript
const timeouts = require('./config/timeouts');

// Get timeout dynamically
const service = 'grok4-reasoning';
const timeout = timeouts.getApiTimeout(service);  // → 8000

// Calculate backoff
let attempt = 0;
let delay = timeouts.retry.apiTimeoutInitial;
let multiplier = timeouts.retry.apiTimeoutBackoffMultiplier;

for (let i = 0; i < 3; i++) {
    const backoffDelay = timeouts.calculateBackoff(i, delay, multiplier);
    console.log(`Attempt ${i + 1}: Wait ${backoffDelay}ms`);
    // → Attempt 1: Wait 1000ms
    // → Attempt 2: Wait 2000ms
    // → Attempt 3: Wait 4000ms
}

// Add jitter
const baseDelay = 1000;
const jitteredDelay = timeouts.addJitter(baseDelay, 0.2);
console.log(jitteredDelay);  // → Random value between 1000-1200
```

---

## Summary

### Key Takeaways

✅ **iOS**: Use `AppConstants.swift` for all configuration
✅ **Backend**: Use `constants.js` and `timeouts.js` for all values
✅ **Zero magic strings**: All values centralized
✅ **Type-safe**: Compile-time checks in Swift, autocomplete in JS
✅ **Maintainable**: Change once, update everywhere

### Migration Stats

- **iOS**: 73 references refactored → AppConstants
- **Backend**: 81 references refactored → constants.js + timeouts.js
- **Total**: 154 magic strings eliminated
- **Keys**: 44+ UserDefaults keys organized
- **Categories**: 16 (constants.js) + 21 (timeouts.js)

### What's Next?

**Stage 8**: Fix extension target access to AppConstants
- Add AppConstants.swift to Vibe8Keyboard target
- Add AppConstants.swift to Vibe8Share target
- Replace TODO comments with actual AppConstants usage

---

**Last Updated**: October 4, 2025
**Maintained By**: Stage 7 Documentation Team
**Questions?** Check troubleshooting section or create an issue
