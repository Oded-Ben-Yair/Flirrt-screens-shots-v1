# API Documentation

Backend API reference for FlirrtAI server.

**Base URL**: `http://localhost:3000/api/v1`

---

## 🔐 Authentication

Most endpoints require authentication via JWT Bearer token.

### Headers
```http
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

### Keyboard Extension Bypass
Keyboard extension can bypass auth with special header:
```http
X-Keyboard-Extension: true
```

---

## 📍 Endpoints

### Health Check

#### `GET /health`
Check server and AI services health.

**Authentication**: None required

**Response**:
```json
{
  "status": "healthy",
  "timestamp": "2025-10-01T12:00:00Z",
  "services": {
    "grok": "operational",
    "gemini": "operational",
    "database": "operational"
  }
}
```

---

### Flirt Generation

#### `POST /api/v1/flirts/generate_flirts`
Generate flirt suggestions (legacy endpoint - works without screenshot).

**Authentication**: Required (or keyboard bypass)

**Request Body**:
```json
{
  "screenshot_id": "optional-string",
  "suggestion_type": "opener" | "response",
  "tone": "playful" | "witty" | "thoughtful" | "funny",
  "context": "optional context string"
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "suggestions": [
      {
        "id": "uuid",
        "text": "Hey! I noticed you're into travel - what's your next adventure?",
        "tone": "playful",
        "confidence": 0.92,
        "voice_available": false
      },
      ...
    ],
    "request_id": "uuid"
  }
}
```

**Error Response**:
```json
{
  "success": false,
  "error": "Error message",
  "code": "ERROR_CODE"
}
```

---

#### `POST /api/v1/flirts/generate_personalized_openers`
Generate personalized opener suggestions based on user profile.

**Authentication**: Required (or keyboard bypass)

**Request Body**:
```json
{
  "user_preferences": {
    "dating_experience": "Pretty experienced",
    "dating_goals": ["Serious relationship"],
    "communication_style": "Playful",
    "confidence_level": 7,
    "interests": ["Travel", "Music", "Food"],
    "ideal_first_date": "Coffee shop conversation",
    "conversation_topics": ["Dreams and goals", "Humor and jokes"],
    "flirting_comfort": 8,
    "completion_percentage": 100
  },
  "request_id": "keyboard-personalized-1234567890"
}
```

**Response**: Same as `generate_flirts`

**Performance**: 10-20 seconds typical

---

### Screenshot Analysis

#### `POST /api/v1/analysis/analyze_screenshot`
Analyze conversation screenshot and generate contextual suggestions.

**Authentication**: Required (or keyboard bypass)

**Content-Type**: `multipart/form-data`

**Form Fields**:
- `screenshot` (file): Image file (JPEG, PNG, or HEIC)
- `compressed` (string): "true" or "false"
- `context` (string): "dating_app_screenshot"

**Request Example**:
```http
POST /api/v1/analysis/analyze_screenshot
Content-Type: multipart/form-data; boundary=----Boundary123
Authorization: Bearer <token>

------Boundary123
Content-Disposition: form-data; name="screenshot"; filename="screenshot.heic"
Content-Type: image/heic

<binary data>
------Boundary123
Content-Disposition: form-data; name="compressed"

true
------Boundary123
Content-Disposition: form-data; name="context"

dating_app_screenshot
------Boundary123--
```

**Success Response**:
```json
{
  "success": true,
  "screenshot_id": "uuid",
  "analysis": {
    "context": "First message exchange",
    "conversation_history": [...],
    "recommended_approach": "playful"
  }
}
```

**Needs More Context Response**:
```json
{
  "success": false,
  "needs_more_context": true,
  "message": "Not enough conversation history visible",
  "action_required": "more_screenshots" | "upload_profile"
}
```

**Performance**: 15-25 seconds (includes Gemini Vision analysis)

---

### Orchestrated Flirts (V2 API)

#### `POST /api/v1/orchestrated-flirts/generate`
Dual-model AI pipeline (Gemini + Grok) for highest quality.

**Authentication**: Required

**Request Body**:
```json
{
  "screenshot_id": "uuid",
  "user_preferences": {
    "communication_style": "Playful",
    "confidence_level": 7,
    ...
  },
  "context": {
    "platform": "tinder",
    "goal": "start_conversation"
  }
}
```

**Response**:
```json
{
  "success": true,
  "data": {
    "suggestions": [...],
    "quality_score": 0.95,
    "processing_time_ms": 12450,
    "models_used": ["gemini-1.5-flash", "grok-beta"]
  }
}
```

---

## 🔄 Voice Synthesis (Coming Soon)

#### `POST /api/v1/voice/synthesize`
Convert text to speech using cloned voice.

**Status**: Planned (ElevenLabs integration)

**Request Body**:
```json
{
  "text": "Hey! How's your day going?",
  "voice_id": "elevenlabs-voice-id",
  "background_sound": "beach" | "birds" | "party" | null
}
```

---

## ⚠️ Error Codes

| Code | HTTP Status | Meaning |
|------|-------------|---------|
| `UNAUTHORIZED` | 401 | Missing/invalid JWT token |
| `VALIDATION_ERROR` | 400 | Invalid request body |
| `AI_SERVICE_ERROR` | 503 | Grok/Gemini API failure |
| `CIRCUIT_OPEN` | 503 | Too many AI failures, circuit breaker open |
| `DATABASE_ERROR` | 500 | SQLite error |
| `TIMEOUT` | 504 | Request exceeded timeout |
| `NEEDS_MORE_CONTEXT` | 200 | Screenshot lacks context (special case) |

---

## 📊 Response Times

| Endpoint | Typical | Max |
|----------|---------|-----|
| `/health` | <50ms | 100ms |
| `/generate_flirts` | 10-15s | 30s |
| `/generate_personalized_openers` | 12-18s | 30s |
| `/analyze_screenshot` | 18-25s | 45s |
| `/orchestrated-flirts/generate` | 20-30s | 60s |

---

## 🔒 Rate Limiting

**Current**: No rate limiting (development)

**Planned**:
- 100 requests/hour per user
- 1000 requests/hour per IP

---

## 🐛 Testing Endpoints

### Test Flirt Generation
```bash
curl -X POST http://localhost:3000/api/v1/flirts/generate_flirts \
  -H "Content-Type: application/json" \
  -H "X-Keyboard-Extension: true" \
  -d '{
    "suggestion_type": "opener",
    "tone": "playful",
    "context": "Test request"
  }'
```

### Test Health Check
```bash
curl http://localhost:3000/health
```

### Test Screenshot Analysis
```bash
curl -X POST http://localhost:3000/api/v1/analysis/analyze_screenshot \
  -H "X-Keyboard-Extension: true" \
  -F "screenshot=@/path/to/screenshot.jpg" \
  -F "compressed=false" \
  -F "context=dating_app_screenshot"
```

---

## 📝 Request/Response Examples

### Personalized Openers (Full Example)

**Request**:
```json
POST /api/v1/flirts/generate_personalized_openers
Content-Type: application/json
X-Keyboard-Extension: true

{
  "user_preferences": {
    "dating_experience": "Some experience",
    "dating_goals": ["Casual dating", "Something fun"],
    "communication_style": "Playful",
    "confidence_level": 6,
    "interests": ["Music", "Travel", "Food"],
    "ideal_first_date": "Grabbing tacos and exploring a new neighborhood",
    "conversation_topics": ["Humor and jokes", "Adventures", "Food and dining"],
    "flirting_comfort": 7,
    "completion_percentage": 100,
    "is_complete": true,
    "version": 1
  },
  "request_id": "keyboard-1234567890"
}
```

**Response** (200 OK):
```json
{
  "success": true,
  "data": {
    "suggestions": [
      {
        "id": "a1b2c3d4",
        "text": "If you could only eat one type of taco for the rest of your life, what would it be? (Asking for a friend who's definitely not planning our first date 🌮)",
        "tone": "playful",
        "confidence": 0.89,
        "voice_available": false
      },
      {
        "id": "e5f6g7h8",
        "text": "I'm building the perfect travel playlist - what's one song that HAS to be on it?",
        "tone": "playful",
        "confidence": 0.92,
        "voice_available": false
      },
      {
        "id": "i9j0k1l2",
        "text": "Real talk: pineapple on pizza - bold choice or crime against humanity? 🍕",
        "tone": "funny",
        "confidence": 0.85,
        "voice_available": false
      }
    ],
    "request_id": "keyboard-1234567890",
    "processing_time_ms": 14523
  }
}
```

---

## 🔗 Related Documentation
- [ARCHITECTURE.md](./ARCHITECTURE.md) - System design
- [FEATURES.md](./FEATURES.md) - Feature documentation
- [SETUP.md](./SETUP.md) - Installation guide
- [KNOWN_ISSUES.md](./KNOWN_ISSUES.md) - Current bugs

---

**Last Updated**: October 2025
