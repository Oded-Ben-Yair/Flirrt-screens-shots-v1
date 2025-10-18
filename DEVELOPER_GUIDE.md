# Flirrt.AI Developer Guide

**Version:** 1.0.0
**Last Updated:** October 18, 2025

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Development Setup](#development-setup)
4. [Backend Development](#backend-development)
5. [iOS Development](#ios-development)
6. [Testing](#testing)
7. [Deployment](#deployment)
8. [Contributing](#contributing)
9. [Code Style](#code-style)
10. [Troubleshooting](#troubleshooting)

---

## Project Overview

### Technology Stack

**Backend:**
- **Runtime:** Node.js 18+
- **Framework:** Express.js
- **Database:** PostgreSQL 14+
- **ORM:** Sequelize
- **Caching:** Redis (optional)
- **Deployment:** Render.com

**iOS:**
- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI
- **Minimum iOS:** 15.0
- **Target iOS:** 18.0 (Liquid Glass design)
- **Dependencies:** Alamofire (networking)

**AI Services:**
- **Image Analysis:** Google Gemini 2.5 Pro Vision
- **Coaching Persona:** OpenAI GPT-4
- **Backup Generation:** xAI Grok-4
- **Research:** Perplexity Sonar Pro
- **Voice Cloning:** ElevenLabs
- **Content Moderation:** OpenAI Moderation API

### Repository Structure

```
Flirrt-screens-shots-v1/
├── Backend/
│   ├── config/
│   │   ├── database.js          # Database configuration
│   │   └── redis.js             # Redis configuration
│   ├── models/
│   │   ├── User.js              # User model
│   │   ├── Screenshot.js        # Screenshot model
│   │   ├── Suggestion.js        # Suggestion model
│   │   └── index.js             # Model associations
│   ├── routes/
│   │   ├── flirts.js            # Main suggestion endpoints
│   │   ├── legal.js             # Privacy/terms endpoints
│   │   ├── account.js           # Account management
│   │   ├── voice.js             # Voice cloning
│   │   └── streaming.js         # Real-time streaming
│   ├── services/
│   │   ├── aiOrchestrator.js    # AI model coordination
│   │   ├── contentModeration.js # Content filtering
│   │   ├── conversationContext.js # Context management
│   │   ├── gamificationService.js # Levels & achievements
│   │   ├── geminiService.js     # Gemini integration
│   │   ├── grokService.js       # Grok integration
│   │   ├── openaiService.js     # OpenAI integration
│   │   ├── perplexityService.js # Perplexity integration
│   │   └── elevenLabsService.js # ElevenLabs integration
│   ├── tests/
│   │   ├── api.test.js          # API endpoint tests
│   │   └── services.test.js     # Service layer tests
│   ├── server.js                # Main server file
│   ├── package.json             # Dependencies
│   └── .env.example             # Environment variables template
├── iOS/
│   ├── Flirrt/
│   │   ├── Config/
│   │   │   └── AppConstants.swift # API URLs, constants
│   │   ├── Models/
│   │   │   ├── User.swift       # User model
│   │   │   ├── FlirtSuggestion.swift # Suggestion model
│   │   │   ├── PersonalizationData.swift
│   │   │   ├── ProgressData.swift
│   │   │   └── VoiceModels.swift
│   │   ├── Services/
│   │   │   ├── APIClient.swift  # Backend API client
│   │   │   ├── AuthManager.swift # Authentication
│   │   │   ├── VoiceRecordingManager.swift
│   │   │   └── ScreenshotDetectionManager.swift
│   │   ├── Views/
│   │   │   ├── MainTabView.swift # Main tab interface
│   │   │   ├── ScreenshotsView.swift
│   │   │   ├── PersonalizationView.swift
│   │   │   ├── ProgressView.swift
│   │   │   ├── SettingsView.swift
│   │   │   └── AgeVerificationView.swift
│   │   └── FlirrtApp.swift      # App entry point
│   ├── FlirrtKeyboard/
│   │   ├── KeyboardViewController.swift # Keyboard logic
│   │   └── Info.plist           # Keyboard configuration
│   ├── FlirrtShare/
│   │   └── ShareViewController.swift # Share extension
│   ├── Tests/
│   │   ├── APIClientTests.swift
│   │   ├── CP6ComprehensiveTests.swift
│   │   ├── PerformanceTests.swift
│   │   └── IntegrationTestSuite.swift
│   └── Flirrt.xcodeproj         # Xcode project
├── CP1_PROGRESS.md through CP7_PROGRESS.md # Progress tracking
├── APP_REVIEW_NOTES.md          # App Review documentation
├── APP_STORE_METADATA.md        # App Store listing
├── TESTFLIGHT_CHECKLIST.md      # TestFlight workflow
└── README.md                    # Project overview
```

---

## Architecture

### System Architecture

```
┌─────────────────┐
│   iOS App       │
│   (SwiftUI)     │
└────────┬────────┘
         │
         │ HTTPS REST API
         │
┌────────▼────────┐      ┌──────────────┐
│  Express.js     │◄─────┤  PostgreSQL  │
│  Backend        │      │  Database    │
└────────┬────────┘      └──────────────┘
         │
         │ API Calls
         │
┌────────▼──────────────────────────────┐
│         AI Services                    │
│  ┌──────────┬──────────┬──────────┐  │
│  │ Gemini   │ GPT-4    │ Grok-4   │  │
│  │ Vision   │ Coaching │ Backup   │  │
│  └──────────┴──────────┴──────────┘  │
│  ┌──────────┬──────────────────────┐ │
│  │ Perplexity│ ElevenLabs         │ │
│  │ Research  │ Voice Cloning      │ │
│  └──────────┴────────────────────── │ │
└────────────────────────────────────────┘
```

### Data Flow

**Suggestion Generation:**
```
1. User takes screenshot in dating app
2. User selects screenshot in Flirrt.AI
3. iOS uploads screenshot to Backend
4. Backend processes:
   a. Gemini analyzes screenshot (profile/chat)
   b. Conversation context retrieved
   c. User preferences loaded
   d. GPT-4 generates coaching persona + suggestions
   e. Grok-4 generates backup suggestions
   f. Perplexity enriches context
   g. Content moderation filters inappropriate content
   h. Top 3 suggestions selected (highest confidence)
5. Backend returns suggestions + coaching
6. iOS displays in app + saves to App Groups
7. Keyboard reads from App Groups (no network access)
```

**Keyboard Extension:**
```
1. User switches to Flirrt keyboard in any app
2. Keyboard reads suggestions from App Groups
3. User taps suggestion to insert text
4. User taps refresh button (if connected to main app)
5. Main app generates new suggestions
6. Keyboard refreshes display
```

### App Groups Communication

```
Main App                       Keyboard Extension
    │                                 │
    │  Saves suggestions              │
    │  to App Groups                  │
    ├─────────────────────────────────┤
    │  UserDefaults(suiteName:        │
    │  "group.com.flirrt")             │
    │                                  │
    │                      Reads from App Groups
    │◄──────────────────────────────────┤
```

**Shared Data:**
- Latest 3 suggestions
- User preferences (tone, goal, level)
- Screenshot context
- Refresh status

---

## Development Setup

### Prerequisites

**System Requirements:**
- macOS 13.0+ (for iOS development)
- Xcode 15.0+
- Node.js 18+
- PostgreSQL 14+
- Git

**API Keys Required:**
- OpenAI API key (GPT-4 access)
- Google Gemini API key
- xAI Grok API key
- Perplexity API key
- ElevenLabs API key

### Backend Setup

#### 1. Clone Repository

```bash
git clone https://github.com/YOUR_USERNAME/Flirrt-screens-shots-v1.git
cd Flirrt-screens-shots-v1/Backend
```

#### 2. Install Dependencies

```bash
npm install
```

#### 3. Configure Environment Variables

```bash
cp .env.example .env
```

Edit `.env`:
```bash
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/flirrt_dev

# API Keys
GROK_API_KEY=xai-YOUR_GROK_API_KEY
OPENAI_API_KEY=sk-YOUR_OPENAI_API_KEY
GEMINI_API_KEY=AIza-YOUR_GEMINI_API_KEY
PERPLEXITY_API_KEY=pplx-YOUR_PERPLEXITY_API_KEY
ELEVENLABS_API_KEY=sk_YOUR_ELEVENLABS_API_KEY

# Server
NODE_ENV=development
PORT=3000

# JWT
JWT_SECRET=your_super_secret_jwt_key_change_in_production

# Redis (optional)
REDIS_URL=redis://localhost:6379
```

#### 4. Setup Database

```bash
# Create database
createdb flirrt_dev

# Run migrations
npm run migrate

# Seed database (optional)
npm run seed
```

#### 5. Start Development Server

```bash
npm run dev
```

Server will run on `http://localhost:3000`

**Verify:**
```bash
curl http://localhost:3000/health
```

Expected response:
```json
{
  "success": true,
  "status": "healthy",
  "timestamp": "2025-10-18T12:00:00.000Z",
  "services": {
    "database": "connected",
    "redis": "configured",
    "ai_models": "configured"
  }
}
```

### iOS Setup

#### 1. Open Project

```bash
cd ../iOS
open Flirrt.xcodeproj
```

#### 2. Configure Signing

1. Select project in Xcode
2. Select "Flirrt" target
3. Go to "Signing & Capabilities"
4. Select your Development Team
5. Repeat for "FlirrtKeyboard" and "FlirrtShare" targets

#### 3. Update API URL

Edit `iOS/Flirrt/Config/AppConstants.swift`:

```swift
static var baseURL: String {
    switch environment {
    case .development:
        return "http://localhost:3000/api/v1"  // or your local IP
    case .staging:
        return "https://flirrt-api-staging.onrender.com/api/v1"
    case .production:
        return "https://flirrt-api-production.onrender.com/api/v1"
    }
}
```

For simulator testing with localhost:
```swift
return "http://localhost:3000/api/v1"
```

For device testing:
```swift
return "http://YOUR_LOCAL_IP:3000/api/v1"  // e.g., http://192.168.1.100:3000/api/v1
```

#### 4. Configure App Groups

1. Select "Flirrt" target
2. Go to "Signing & Capabilities"
3. Click "+ Capability"
4. Add "App Groups"
5. Check "group.com.flirrt" (create if needed)
6. Repeat for "FlirrtKeyboard" target

#### 5. Run on Simulator

1. Select iPhone 15 Pro simulator
2. Press ⌘R to build and run
3. App should launch and show age verification screen

---

## Backend Development

### API Endpoints

#### Health Check

**GET** `/health`

Returns service status.

**Response:**
```json
{
  "success": true,
  "status": "healthy",
  "timestamp": "2025-10-18T12:00:00.000Z",
  "services": {
    "database": "connected",
    "redis": "configured",
    "ai_models": "configured"
  }
}
```

#### Generate Flirts

**POST** `/api/v1/flirts/generate_flirts`

Generates 3 personalized suggestions.

**Request:**
```json
{
  "image_data": "base64_encoded_screenshot",
  "suggestion_type": "opener",  // or "reply"
  "tone": "playful",  // playful, serious, witty, romantic
  "user_id": "user123"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "suggestions": [
      {
        "id": "sugg_123",
        "text": "I noticed you're into hiking! Big Sur or Yosemite?",
        "confidence": 92,
        "reasoning": "References specific interest...",
        "next_steps": "If they respond with a location..."
      }
    ],
    "coaching": {
      "overall_strategy": "Focus on shared interests...",
      "tone_analysis": "Profile suggests adventurous...",
      "next_steps": "After initial response..."
    },
    "metadata": {
      "profile_type": "complete",
      "screenshot_id": "ss_456"
    }
  }
}
```

#### Refresh Suggestions

**POST** `/api/v1/flirts/refresh`

Generates new suggestions for same context.

**Request:**
```json
{
  "screenshot_id": "ss_456",
  "suggestion_type": "opener",
  "tone": "playful",
  "previous_suggestions": [
    "Previous suggestion 1",
    "Previous suggestion 2"
  ]
}
```

**Response:** Same as generate_flirts

#### Get Progress

**GET** `/api/v1/flirts/progress`

Returns gamification data.

**Response:**
```json
{
  "success": true,
  "data": {
    "level": {
      "level": 3,
      "title": "Confident",
      "current_xp": 450,
      "next_level_at": 600,
      "percentage_to_next": 75
    },
    "stats": {
      "messages_sent": 45,
      "profiles_analyzed": 20,
      "successful_conversations": 12,
      "daily_streak": 7
    },
    "achievements": {
      "unlocked": [
        {"id": "first_steps", "title": "First Steps", "xp": 50}
      ],
      "locked": [
        {"id": "suggestion_master", "title": "Suggestion Master", "requirement": "50 suggestions"}
      ],
      "total": 12
    }
  }
}
```

### Service Layer

#### aiOrchestrator.js

Coordinates multiple AI services for suggestion generation.

**Key Functions:**

```javascript
async function generateSuggestions(context, preferences) {
  // 1. Analyze screenshot with Gemini
  const analysis = await geminiService.analyzeScreenshot(context.imageData);

  // 2. Get conversation context
  const conversationContext = await conversationContextService.getContext(context.userId);

  // 3. Generate coaching with GPT-4
  const coaching = await openaiService.generateCoaching(analysis, preferences);

  // 4. Generate suggestions with Grok
  const suggestions = await grokService.generateSuggestions(analysis, coaching, preferences);

  // 5. Enrich with Perplexity research
  const enriched = await perplexityService.enrichContext(suggestions, analysis);

  // 6. Filter with content moderation
  const filtered = await contentModerationService.filterSuggestions(enriched);

  // 7. Select top 3 by confidence
  const top3 = filtered.sort((a, b) => b.confidence - a.confidence).slice(0, 3);

  return { suggestions: top3, coaching };
}
```

#### gamificationService.js

Manages levels, achievements, and stats.

**Key Functions:**

```javascript
async function calculateLevel(userId) {
  const stats = await getStats(userId);
  const totalXP = stats.total_xp;

  // Level thresholds
  const levels = [
    { level: 1, title: "Beginner", min: 0, max: 99 },
    { level: 2, title: "Learner", min: 100, max: 299 },
    { level: 3, title: "Confident", min: 300, max: 599 },
    { level: 4, title: "Skilled", min: 600, max: 999 },
    { level: 5, title: "Expert", min: 1000, max: Infinity }
  ];

  const currentLevel = levels.find(l => totalXP >= l.min && totalXP <= l.max);
  const nextLevel = levels.find(l => l.level === currentLevel.level + 1);

  return {
    level: currentLevel.level,
    title: currentLevel.title,
    current_xp: totalXP,
    next_level_at: nextLevel ? nextLevel.min : null,
    percentage_to_next: nextLevel ? ((totalXP - currentLevel.min) / (nextLevel.min - currentLevel.min)) * 100 : 100
  };
}
```

### Database Models

#### User Model

```javascript
const User = sequelize.define('User', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  email: {
    type: DataTypes.STRING,
    unique: true,
    allowNull: false
  },
  birthdate: {
    type: DataTypes.DATEONLY,
    allowNull: false
  },
  tone_preference: {
    type: DataTypes.ENUM('playful', 'serious', 'witty', 'romantic'),
    defaultValue: 'playful'
  },
  dating_goal: {
    type: DataTypes.ENUM('casual', 'relationship', 'friends', 'exploring'),
    defaultValue: 'exploring'
  },
  experience_level: {
    type: DataTypes.ENUM('beginner', 'learner', 'confident', 'expert'),
    defaultValue: 'beginner'
  },
  total_xp: {
    type: DataTypes.INTEGER,
    defaultValue: 0
  }
});
```

#### Screenshot Model

```javascript
const Screenshot = sequelize.define('Screenshot', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  user_id: {
    type: DataTypes.UUID,
    allowNull: false,
    references: { model: 'Users', key: 'id' }
  },
  analysis: {
    type: DataTypes.JSONB  // Stores Gemini analysis
  },
  screenshot_type: {
    type: DataTypes.ENUM('profile', 'chat', 'unknown'),
    defaultValue: 'unknown'
  }
});
```

#### Suggestion Model

```javascript
const Suggestion = sequelize.define('Suggestion', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  screenshot_id: {
    type: DataTypes.UUID,
    allowNull: false,
    references: { model: 'Screenshots', key: 'id' }
  },
  text: {
    type: DataTypes.TEXT,
    allowNull: false
  },
  confidence: {
    type: DataTypes.DECIMAL(5, 2),  // 0.00 to 100.00
    allowNull: false
  },
  reasoning: {
    type: DataTypes.TEXT
  },
  next_steps: {
    type: DataTypes.TEXT
  },
  is_used: {
    type: DataTypes.BOOLEAN,
    defaultValue: false
  }
});
```

---

## iOS Development

### Project Structure

**Main App:**
- `FlirrtApp.swift`: App entry point with `@main`
- `AppCoordinator.swift`: Navigation logic
- `MainTabView.swift`: Tab bar interface

**Views:**
- `ScreenshotsView.swift`: Screenshot upload and analysis
- `PersonalizationView.swift`: User preferences
- `ProgressView.swift`: Levels, achievements, stats
- `SettingsView.swift`: App settings

**Services:**
- `APIClient.swift`: Backend communication
- `AuthManager.swift`: User authentication
- `VoiceRecordingManager.swift`: Voice cloning
- `ScreenshotDetectionManager.swift`: Auto-detect screenshots

**Models:**
- `User.swift`: User data model
- `FlirtSuggestion.swift`: Suggestion data model
- `PersonalizationData.swift`: User preferences
- `ProgressData.swift`: Gamification data

### API Client

```swift
class APIClient {
    private let baseURL: String
    private let session: URLSession

    init(baseURL: String) {
        self.baseURL = baseURL
        self.session = URLSession.shared
    }

    func generateFlirts(
        imageData: Data,
        suggestionType: String,
        tone: String,
        completion: @escaping (Result<FlirtResponse, Error>) -> Void
    ) {
        let endpoint = "\\(baseURL)/flirts/generate_flirts"

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "image_data": imageData.base64EncodedString(),
            "suggestion_type": suggestionType,
            "tone": tone
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }

            do {
                let response = try JSONDecoder().decode(FlirtResponse.self, from: data)
                completion(.success(response))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
```

### App Groups

**Saving to App Groups:**

```swift
// Main App
let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt")

// Save suggestions
let suggestionsData = try? JSONEncoder().encode(suggestions)
sharedDefaults?.set(suggestionsData, forKey: "latest_suggestions")

// Save preferences
sharedDefaults?.set("playful", forKey: "tone_preference")
sharedDefaults?.set("casual", forKey: "dating_goal")
```

**Reading from App Groups:**

```swift
// Keyboard Extension
let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt")

// Read suggestions
if let suggestionsData = sharedDefaults?.data(forKey: "latest_suggestions") {
    let suggestions = try? JSONDecoder().decode([FlirtSuggestion].self, from: suggestionsData)
}

// Read preferences
let tone = sharedDefaults?.string(forKey: "tone_preference") ?? "playful"
let goal = sharedDefaults?.string(forKey: "dating_goal") ?? "exploring"
```

### Keyboard Extension

```swift
class KeyboardViewController: UIInputViewController {
    private var suggestions: [FlirtSuggestion] = []
    private var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        loadSuggestionsFromAppGroups()
    }

    private func loadSuggestionsFromAppGroups() {
        let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt")

        if let suggestionsData = sharedDefaults?.data(forKey: "latest_suggestions"),
           let suggestions = try? JSONDecoder().decode([FlirtSuggestion].self, from: suggestionsData) {
            self.suggestions = suggestions
            collectionView.reloadData()
        }
    }

    private func insertSuggestion(_ suggestion: FlirtSuggestion) {
        textDocumentProxy.insertText(suggestion.text)

        // Track usage in main app via App Groups
        var usedSuggestions = sharedDefaults?.array(forKey: "used_suggestions") as? [String] ?? []
        usedSuggestions.append(suggestion.id)
        sharedDefaults?.set(usedSuggestions, forKey: "used_suggestions")
    }
}
```

---

## Testing

### Backend Testing

#### Setup

```bash
cd Backend
npm install --save-dev jest supertest
```

#### Run Tests

```bash
# All tests
npm test

# Specific test file
npm test tests/api.test.js

# With coverage
npm test -- --coverage
```

#### Example Test

```javascript
describe('Flirt Generation', () => {
  test('POST /generate_flirts returns max 3 suggestions', async () => {
    const response = await request(app)
      .post('/api/v1/flirts/generate_flirts')
      .send({
        image_data: 'base64_test_data',
        suggestion_type: 'opener',
        tone: 'playful'
      });

    expect(response.status).toBe(200);
    expect(response.body.data.suggestions.length).toBeLessThanOrEqual(3);
    expect(response.body.data.coaching).toBeDefined();
  });
});
```

### iOS Testing

#### Run Tests in Xcode

1. Press ⌘U to run all tests
2. Or: Product → Test

#### Run Specific Test

```bash
xcodebuild test \
  -scheme Flirrt \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:FlirrtTests/CP6ComprehensiveTests/testRefreshEndpointReturnsMax3Suggestions
```

#### Example Test

```swift
func testRefreshEndpointReturnsMax3Suggestions() {
    let expectation = self.expectation(description: "Refresh should return max 3")

    apiClient.refreshSuggestions(
        screenshotId: "test_123",
        suggestionType: "opener",
        tone: "playful",
        previousSuggestions: ["Test 1", "Test 2"]
    ) { result in
        switch result {
        case .success(let response):
            XCTAssertLessThanOrEqual(response.suggestions.count, 3)
            XCTAssertNotNil(response.coaching)
            expectation.fulfill()
        case .failure(let error):
            XCTFail("Test failed: \\(error)")
        }
    }

    waitForExpectations(timeout: 10.0)
}
```

---

## Deployment

### Backend Deployment (Render.com)

See `Backend/RENDER_DEPLOYMENT_GUIDE.md` for complete instructions.

**Quick Steps:**

1. Create account at https://render.com
2. Connect GitHub repository
3. Create new Web Service
4. Configure:
   - **Root Directory:** `Backend`
   - **Build Command:** `npm install`
   - **Start Command:** `npm start`
5. Add environment variables (all API keys)
6. Deploy

**Environment Variables:**
```
DATABASE_URL=<provided by Render>
GROK_API_KEY=<your key>
OPENAI_API_KEY=<your key>
GEMINI_API_KEY=<your key>
PERPLEXITY_API_KEY=<your key>
ELEVENLABS_API_KEY=<your key>
JWT_SECRET=<your secret>
NODE_ENV=production
PORT=3000
```

### iOS Deployment (TestFlight)

See `TESTFLIGHT_CHECKLIST.md` for complete instructions.

**Quick Steps:**

1. Update Bundle IDs in Xcode (remove `.dev`)
2. Register Bundle IDs at https://developer.apple.com/account
3. Create Distribution Certificate
4. Create 3 Provisioning Profiles (app, keyboard, share)
5. Archive app in Xcode (Product → Archive)
6. Distribute to App Store Connect
7. Wait for processing
8. Invite internal testers
9. Wait 24-48 hours for external testing approval

---

## Contributing

### Branching Strategy

- `main`: Production-ready code
- `develop`: Development branch
- `feature/*`: Feature branches
- `fix/*`: Bug fix branches
- `release/*`: Release preparation

### Workflow

1. Fork repository
2. Create feature branch: `git checkout -b feature/your-feature`
3. Commit changes: `git commit -m "feat: add new feature"`
4. Push to branch: `git push origin feature/your-feature`
5. Create Pull Request

### Commit Message Convention

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**
```
feat(backend): add refresh suggestions endpoint
fix(ios): resolve keyboard memory leak
docs(readme): update setup instructions
test(api): add comprehensive endpoint tests
```

---

## Code Style

### Backend (JavaScript)

**ESLint Configuration:**
```json
{
  "extends": "eslint:recommended",
  "env": {
    "node": true,
    "es2021": true
  },
  "rules": {
    "indent": ["error", 2],
    "quotes": ["error", "single"],
    "semi": ["error", "always"]
  }
}
```

**Naming Conventions:**
- Variables: `camelCase`
- Constants: `UPPER_SNAKE_CASE`
- Functions: `camelCase`
- Classes: `PascalCase`
- Files: `camelCase.js`

### iOS (Swift)

**SwiftLint Configuration:**
```yaml
disabled_rules:
  - trailing_whitespace
line_length: 120
identifier_name:
  min_length: 2
  max_length: 40
```

**Naming Conventions:**
- Variables: `camelCase`
- Constants: `camelCase` or `UPPER_CASE`
- Functions: `camelCase`
- Classes/Structs: `PascalCase`
- Protocols: `PascalCase` (often ending in `-able` or `-Delegate`)
- Files: `PascalCase.swift`

---

## Troubleshooting

### Backend Issues

**Database Connection Failed**
```bash
# Check PostgreSQL is running
pg_isready

# Verify credentials in .env
cat .env | grep DATABASE_URL

# Test connection
psql <DATABASE_URL>
```

**API Keys Invalid**
```bash
# Verify keys are set
echo $GROK_API_KEY

# Test API keys individually
curl -X POST https://api.x.ai/v1/chat/completions \
  -H "Authorization: Bearer $GROK_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model": "grok-4-latest", "messages": [{"role": "user", "content": "test"}]}'
```

### iOS Issues

**App Groups Not Working**
1. Delete app from simulator/device
2. Clean build folder (⇧⌘K)
3. Verify App Groups capability added to both targets
4. Rebuild and reinstall

**Keyboard Not Showing Suggestions**
1. Check App Groups configured correctly
2. Verify suggestions saved to App Groups in main app
3. Debug keyboard with `print()` statements
4. Check Console.app for keyboard logs

**Provisioning Profile Issues**
1. Delete old profiles: Xcode → Preferences → Accounts → Download Manual Profiles
2. Create new profiles at https://developer.apple.com
3. Download and import to Xcode
4. Select correct profile in Signing & Capabilities

---

**Version:** 1.0.0
**Last Updated:** October 18, 2025

For questions or issues, contact: support@flirrt.ai
