# Architecture Documentation

Technical design and system architecture for FlirrtAI.

---

## 🏗️ System Overview

FlirrtAI is a multi-component system consisting of:
1. **iOS Main App** - User-facing application
2. **iOS Keyboard Extension** - Custom keyboard for suggestions
3. **iOS Share Extension** - For sharing screenshots
4. **Node.js Backend** - AI orchestration and API server
5. **External AI Services** - Grok, Gemini, ElevenLabs

```
┌─────────────────────────────────────────────────────────┐
│                    iOS Device/Simulator                  │
│  ┌──────────────────┐         ┌──────────────────┐     │
│  │   Main App       │◄────────┤ Keyboard Ext.    │     │
│  │  - Authentication│  App    │  - Suggestions   │     │
│  │  - Onboarding    │  Groups │  - Screenshot    │     │
│  │  - Voice Record  │  Data   │  - API Client    │     │
│  └────────┬─────────┘         └─────────┬────────┘     │
│           │                              │              │
│           │        HTTP/JSON             │              │
│           └──────────────┬───────────────┘              │
└─────────────────────────┼──────────────────────────────┘
                          │
                          ▼
                ┌──────────────────┐
                │  Backend Server  │
                │  (Node.js/Express│
                │   SQLite DB)     │
                └────────┬─────────┘
                         │
            ┌────────────┼───────────────┐
            │            │               │
            ▼            ▼               ▼
       ┌────────┐  ┌─────────┐    ┌──────────┐
       │  Grok  │  │ Gemini  │    │ElevenLabs│
       │  (xAI) │  │(Google) │    │  (Voice) │
       └────────┘  └─────────┘    └──────────┘
```

---

## 📱 iOS Architecture

### App Structure

#### Main App Target: `Flirrt`
**Responsibilities:**
- User authentication (Apple Sign In)
- Onboarding questionnaire
- Voice recording and script reading
- Settings and account management

**Key Components:**
```
Flirrt/
├── App/
│   └── FlirrtApp.swift          # App entry point, lifecycle
├── Features/                     # Feature-based organization
│   ├── Onboarding/
│   ├── Main/
│   ├── VoiceRecording/
│   ├── Settings/
│   └── Authentication/
├── Services/
│   ├── APIClient.swift          # Backend communication
│   ├── AuthManager.swift        # Authentication logic
│   ├── SharedDataManager.swift  # App Groups management
│   └── VoiceRecordingManager.swift
└── Models/
    ├── PersonalizationData.swift
    └── VoiceModels.swift
```

#### Keyboard Extension Target: `FlirrtKeyboard`
**Responsibilities:**
- Display suggestions interface
- Detect screenshots (Darwin notifications)
- Make API requests for suggestions
- Insert selected text into host app
- Memory management (<30MB target)

**Key Components:**
```
FlirrtKeyboard/
├── KeyboardViewController.swift  # Main controller (2100→800 lines)
├── SuggestionsView.swift         # UI for displaying suggestions
├── ImageCompressionService.swift # HEIC compression
└── PersonalizationData.swift     # Shared model (duplicate)
```

---

## 🔄 Data Flow

### 1. Onboarding Flow
```
User fills questionnaire
    ↓
PersonalizationProfile created
    ↓
Saved to UserDefaults (App Groups)
    ↓
Keyboard reads profile on launch
    ↓
Profile sent to backend with each API request
```

### 2. Screenshot Analysis Flow (Intended)
```
User takes screenshot
    ↓
iOS posts UIApplication notification
    ↓
Main app receives notification
    ↓
Main app posts Darwin notification
    ↓
Keyboard receives Darwin notification
    ↓
Keyboard switches button to "Analyze" mode
    ↓
User taps button
    ↓
Keyboard compresses image (HEIC)
    ↓
Upload to backend /api/v1/analysis/analyze_screenshot
    ↓
Backend analyzes with Gemini Vision
    ↓
Backend generates flirts with Grok
    ↓
Return suggestions to keyboard
    ↓
Display in SuggestionsView
```

### 3. Fresh Flirts Flow
```
User taps "Fresh Flirts" button
    ↓
Keyboard loads PersonalizationProfile from App Groups
    ↓
POST /api/v1/flirts/generate_personalized_openers
    ↓
Backend receives user preferences
    ↓
Grok generates 3 opener suggestions
    ↓
Return to keyboard
    ↓
Display in SuggestionsView
```

---

## 🔐 Security & Privacy

### App Groups
**ID**: `group.com.flirrt.shared`

**Purpose**: Share data between main app and extensions

**Data Stored:**
- `user_authenticated` (bool)
- `auth_token` (string) - JWT token
- `voice_enabled` (bool)
- `current_voice_id` (string)
- `last_screenshot_time` (double)
- `flirrt_personalization_profile_v1` (Data) - JSON encoded profile

### Keychain Sharing
- Stores Apple Sign In credentials
- JWT tokens for API authentication
- Shared across app and extensions

### Network Security
- HTTPS for production (HTTP for localhost development)
- JWT Bearer token authentication
- Keyboard extension bypass: `X-Keyboard-Extension: true` header

---

## 🧠 Backend Architecture

### Tech Stack
- **Runtime**: Node.js 18+
- **Framework**: Express.js
- **Database**: SQLite3
- **AI**: Grok API, Gemini Vision API, ElevenLabs API

### Project Structure
```
Backend/
├── server.js                 # Express app entry point
├── routes/
│   ├── flirts.js            # Flirt generation endpoints
│   ├── analysis.js          # Screenshot analysis endpoints
│   ├── orchestrated-flirts.js # Dual-model pipeline (v2)
│   └── status.js            # Health check
├── services/
│   ├── grokService.js       # Grok API integration
│   ├── geminiVisionService.js # Gemini Vision integration
│   ├── aiOrchestrator.js    # Multi-model pipeline
│   ├── circuitBreaker.js    # Fault tolerance
│   ├── qualityAssurance.js  # Response validation
│   └── database.js          # SQLite wrapper
├── middleware/
│   ├── auth.js              # JWT verification
│   └── correlationId.js     # Request tracking
└── data/
    └── flirrt.db            # SQLite database file
```

---

## 🤖 AI Pipeline

### Dual-Model Architecture

#### Phase 1: Analysis (Gemini Vision)
**Model**: `gemini-1.5-flash`
**Input**: Screenshot image (compressed HEIC)
**Output**: Detailed JSON analysis

```json
{
  "context": "First message exchange on Tinder",
  "conversation_history": [...],
  "person_style": "casual, friendly",
  "emotional_tone": "positive, interested",
  "topics": ["travel", "coffee"],
  "recommended_approach": "playful, ask about travel"
}
```

#### Phase 2: Generation (Grok)
**Model**: `grok-beta`
**Input**: Gemini analysis + User personalization
**Output**: 3 unique suggestions

```json
{
  "suggestions": [
    {
      "text": "...",
      "tone": "playful",
      "confidence": 0.92
    },
    ...
  ]
}
```

### Circuit Breaker Pattern
Protects against cascading AI API failures:
- **Threshold**: 5 failures in 60 seconds
- **Action**: Open circuit, return cached/fallback
- **Recovery**: Half-open after 30 seconds
- **Reset**: After 3 successful requests

---

## 📊 Database Schema

```sql
-- Users table
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    apple_id TEXT UNIQUE NOT NULL,
    email TEXT,
    full_name TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Screenshots table
CREATE TABLE screenshots (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    image_data BLOB,
    analysis_result TEXT, -- JSON
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Suggestions table
CREATE TABLE suggestions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    screenshot_id INTEGER,
    suggestion_text TEXT NOT NULL,
    tone TEXT,
    confidence REAL,
    selected BOOLEAN DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (screenshot_id) REFERENCES screenshots(id)
);

-- Voice clones table
CREATE TABLE voice_clones (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER,
    elevenlabs_voice_id TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

---

## 🎨 Design Patterns

### Used Patterns:

1. **MVVM** (Model-View-ViewModel) - iOS app architecture
2. **Repository** - Database access abstraction
3. **Circuit Breaker** - API fault tolerance
4. **Factory** - AI service creation
5. **Observer** - Darwin notifications, UserDefaults
6. **Singleton** - Shared managers (APIClient, AuthManager)

---

## 🚀 Performance Optimizations

### iOS Keyboard
- **Memory**: <30MB target (platform limit ~60MB)
- **Image Compression**: 62% reduction with HEIC
- **Lazy Loading**: ImageCompressionService loaded on demand
- **Memory Monitoring**: Proactive cleanup at 45MB threshold

### Backend
- **Response Time**: 9-22 seconds (AI generation)
- **Timeout**: 30 seconds for keyboard requests
- **Concurrency**: Async/await for parallel AI calls
- **Caching**: SQLite for analyzed screenshots

---

## 🔧 Configuration

### Environment Variables (Backend/.env)
```env
GROK_API_KEY          # xAI Grok API key
GEMINI_API_KEY        # Google Gemini API key
ELEVENLABS_API_KEY    # ElevenLabs voice API key
JWT_SECRET            # JWT signing secret
PORT                  # Server port (default: 3000)
DB_PATH               # SQLite database path
```

### iOS Configuration (Xcode)
- **App Groups**: Must match across all targets
- **Bundle IDs**: Unique per target
- **Signing**: Same team for all targets
- **Capabilities**: App Groups, Keychain, Sign in with Apple

---

## 📚 Related Documentation
- [SETUP.md](./SETUP.md) - Installation and configuration
- [API.md](./API.md) - Backend API reference
- [FEATURES.md](./FEATURES.md) - Feature documentation
- [KNOWN_ISSUES.md](./KNOWN_ISSUES.md) - Current limitations
