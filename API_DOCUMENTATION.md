# Vibe8.AI API Documentation

**Version:** 1.0.0
**Base URL (Production):** `https://vibe8-api-production.onrender.com/api/v1`
**Base URL (Development):** `http://localhost:3000/api/v1`
**Last Updated:** October 18, 2025

---

## Table of Contents

1. [Authentication](#authentication)
2. [Endpoints](#endpoints)
   - [Health Check](#health-check)
   - [Flirt Generation](#flirt-generation)
   - [Progress & Gamification](#progress--gamification)
   - [Voice Services](#voice-services)
   - [Account Management](#account-management)
   - [Legal & Compliance](#legal--compliance)
3. [Data Models](#data-models)
4. [Error Handling](#error-handling)
5. [Rate Limiting](#rate-limiting)
6. [Examples](#examples)

---

## Authentication

### JWT Bearer Token

All authenticated endpoints require a JWT token in the Authorization header.

```http
Authorization: Bearer <jwt_token>
```

### Getting a Token

**POST** `/auth/login`

```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "user_123",
      "email": "user@example.com",
      "age_verified": true
    }
  }
}
```

**Note:** Most endpoints are currently open for MVP. Authentication will be enforced in v1.1.

---

## Endpoints

### Health Check

#### GET `/health`

Check if the API and services are operational.

**Headers:** None required

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
  },
  "version": "1.0.0"
}
```

**Status Codes:**
- `200`: Service is healthy
- `503`: Service is unhealthy

---

### Flirt Generation

#### POST `/flirts/generate_flirts`

Generate personalized conversation suggestions from a screenshot.

**Headers:**
```http
Content-Type: application/json
Authorization: Bearer <token>  (optional in MVP)
```

**Request Body:**
```json
{
  "image_data": "base64_encoded_screenshot_data",
  "suggestion_type": "opener",
  "tone": "playful",
  "user_id": "user_123",
  "context": {
    "dating_goal": "casual",
    "experience_level": "beginner"
  }
}
```

**Parameters:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `image_data` | string | Yes | Base64-encoded screenshot (PNG/JPEG) |
| `screenshot_id` | string | No* | ID of previously uploaded screenshot |
| `suggestion_type` | string | Yes | `"opener"` or `"reply"` |
| `tone` | string | No | `"playful"`, `"serious"`, `"witty"`, `"romantic"` (default: `"playful"`) |
| `user_id` | string | No | User identifier for personalization |
| `context` | object | No | Additional context (dating_goal, experience_level) |

*Either `image_data` or `screenshot_id` must be provided.

**Response:**
```json
{
  "success": true,
  "data": {
    "suggestions": [
      {
        "id": "sugg_abc123",
        "text": "I noticed you're into hiking! Big Sur or Yosemite?",
        "confidence": 92,
        "reasoning": "References specific interest from profile, offers two choices to encourage response, friendly and engaging tone.",
        "next_steps": "If they respond with a location, share your own hiking experience there. Ask about their favorite trail or most memorable hike.",
        "tone": "playful",
        "category": "opener"
      },
      {
        "id": "sugg_def456",
        "text": "That photo from Big Sur looks incredible! Have you done the McWay Falls trail?",
        "confidence": 88,
        "reasoning": "Specific photo reference shows genuine interest, mentions specific location and trail to demonstrate knowledge.",
        "next_steps": "Share your experience with coastal hikes. Ask for recommendations for other trails in the area.",
        "tone": "playful",
        "category": "opener"
      },
      {
        "id": "sugg_ghi789",
        "text": "Fellow outdoor enthusiast here! What's been your favorite adventure so far?",
        "confidence": 85,
        "reasoning": "Establishes common interest, open-ended question encourages detailed response.",
        "next_steps": "Listen for specific activities they mention (climbing, camping, etc.) and ask follow-up questions about those.",
        "tone": "playful",
        "category": "opener"
      }
    ],
    "coaching": {
      "overall_strategy": "Focus on shared outdoor interests. The profile emphasizes hiking and nature photography. All suggestions reference these interests to establish common ground. Confidence scores are high (85-92%) because the profile provides specific details to work with.",
      "tone_analysis": "Profile suggests adventurous, active person. Playful tone works well here - not too serious, but showing genuine interest. Avoid overly formal language.",
      "next_steps": "After initial response, transition from general outdoor interests to planning a specific activity. Look for opportunities to suggest a hiking date or sharing favorite spots.",
      "conversation_flow": "Opener → Discuss shared interests → Share experiences → Find common ground → Suggest activity",
      "red_flags": "None detected. Profile appears genuine and detailed.",
      "confidence_explanation": "High confidence (85-92%) due to: 1) Detailed profile with specific interests, 2) Clear common ground (hiking), 3) Multiple conversation hooks available."
    },
    "metadata": {
      "screenshot_id": "ss_xyz789",
      "analysis_timestamp": "2025-10-18T12:00:00.000Z",
      "profile_type": "complete",
      "ai_models_used": ["gemini-2.5-pro", "gpt-4", "grok-4"],
      "is_refresh": false,
      "moderation_passed": true
    }
  }
}
```

**Status Codes:**
- `200`: Success
- `400`: Invalid request (missing image_data or screenshot_id)
- `413`: Image too large (> 10MB)
- `422`: Unprocessable entity (invalid image format)
- `429`: Rate limit exceeded
- `500`: Internal server error

---

#### POST `/flirts/refresh`

Generate new suggestions for the same screenshot/context.

**Headers:**
```http
Content-Type: application/json
Authorization: Bearer <token>  (optional in MVP)
```

**Request Body:**
```json
{
  "screenshot_id": "ss_xyz789",
  "suggestion_type": "opener",
  "tone": "witty",
  "previous_suggestions": [
    "I noticed you're into hiking! Big Sur or Yosemite?",
    "That photo from Big Sur looks incredible! Have you done the McWay Falls trail?"
  ]
}
```

**Parameters:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `screenshot_id` | string | Yes | ID of previously analyzed screenshot |
| `suggestion_type` | string | Yes | `"opener"` or `"reply"` |
| `tone` | string | No | New tone preference (default: previous tone) |
| `previous_suggestions` | array | No | Array of previously generated suggestion texts (to avoid duplicates) |

**Response:** Same structure as `/generate_flirts`, with `metadata.is_refresh: true`

**Status Codes:**
- `200`: Success
- `400`: Invalid screenshot_id
- `404`: Screenshot not found
- `429`: Rate limit exceeded
- `500`: Internal server error

---

### Progress & Gamification

#### GET `/flirts/progress`

Get user's progress, level, achievements, and stats.

**Headers:**
```http
Authorization: Bearer <token>
```

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `user_id` | string | No | User ID (extracted from token if authenticated) |

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
      "xp_to_next": 150,
      "percentage_to_next": 75,
      "icon": "🎯"
    },
    "stats": {
      "messages_sent": 45,
      "profiles_analyzed": 20,
      "screenshots_analyzed": 32,
      "successful_conversations": 12,
      "avg_confidence_score": 87.5,
      "daily_streak": 7,
      "longest_streak": 14,
      "total_xp": 450,
      "member_since": "2025-10-01T00:00:00.000Z"
    },
    "achievements": {
      "unlocked": [
        {
          "id": "first_steps",
          "title": "First Steps",
          "description": "Generated your first suggestion",
          "icon": "🎉",
          "xp_reward": 50,
          "unlocked_at": "2025-10-01T12:00:00.000Z"
        },
        {
          "id": "getting_started",
          "title": "Getting Started",
          "description": "Generated 10 suggestions",
          "icon": "🚀",
          "xp_reward": 100,
          "unlocked_at": "2025-10-05T15:30:00.000Z"
        }
      ],
      "locked": [
        {
          "id": "suggestion_master",
          "title": "Suggestion Master",
          "description": "Generate 50 suggestions",
          "icon": "🏆",
          "xp_reward": 200,
          "progress": 45,
          "requirement": 50,
          "percentage": 90
        },
        {
          "id": "daily_dedication",
          "title": "Daily Dedication",
          "description": "Maintain a 7-day streak",
          "icon": "🔥",
          "xp_reward": 250,
          "progress": 7,
          "requirement": 7,
          "percentage": 100,
          "ready_to_unlock": true
        }
      ],
      "total": 12,
      "unlocked_count": 2,
      "locked_count": 10
    },
    "recent_activity": [
      {
        "type": "suggestion_generated",
        "timestamp": "2025-10-18T11:00:00.000Z",
        "xp_earned": 10
      },
      {
        "type": "achievement_unlocked",
        "achievement_id": "getting_started",
        "timestamp": "2025-10-05T15:30:00.000Z",
        "xp_earned": 100
      }
    ]
  }
}
```

**Status Codes:**
- `200`: Success
- `401`: Unauthorized (token required)
- `404`: User not found
- `500`: Internal server error

---

### Voice Services

#### POST `/voice/upload_sample`

Upload a voice sample for voice cloning.

**Headers:**
```http
Content-Type: multipart/form-data
Authorization: Bearer <token>
```

**Request Body (form-data):**
```
voice_sample: <audio_file>  (30 seconds minimum, WAV/MP3/M4A)
user_id: user_123
```

**Response:**
```json
{
  "success": true,
  "data": {
    "voice_id": "voice_abc123",
    "status": "processing",
    "estimated_completion": "2025-10-18T12:05:00.000Z",
    "sample_duration": 32.5,
    "quality_score": 95
  }
}
```

**Status Codes:**
- `200`: Upload successful
- `400`: Invalid audio file
- `413`: File too large (> 10MB)
- `422`: Audio too short (< 30 seconds)
- `500`: Internal server error

---

#### POST `/voice/generate`

Generate a voice message from text using cloned voice.

**Headers:**
```http
Content-Type: application/json
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "text": "Hey! Your profile caught my eye. I love hiking too!",
  "voice_id": "voice_abc123",
  "background_sound": "beach",
  "user_id": "user_123"
}
```

**Parameters:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `text` | string | Yes | Text to convert to speech (max 500 characters) |
| `voice_id` | string | Yes | Voice clone ID from `/voice/upload_sample` |
| `background_sound` | string | No | `"beach"`, `"party"`, `"forest"`, `"none"` (default: `"none"`) |
| `user_id` | string | Yes | User identifier |

**Response:**
```json
{
  "success": true,
  "data": {
    "audio_url": "https://vibe8-api.onrender.com/audio/msg_xyz789.mp3",
    "audio_id": "msg_xyz789",
    "duration": 5.2,
    "text": "Hey! Your profile caught my eye. I love hiking too!",
    "expires_at": "2025-10-25T12:00:00.000Z"
  }
}
```

**Status Codes:**
- `200`: Success
- `400`: Invalid request
- `404`: Voice ID not found
- `413`: Text too long
- `429`: Rate limit exceeded
- `500`: Internal server error

---

### Account Management

#### GET `/account/profile`

Get user profile information.

**Headers:**
```http
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "user_123",
    "email": "user@example.com",
    "birthdate": "1990-01-01",
    "age_verified": true,
    "preferences": {
      "tone": "playful",
      "dating_goal": "casual",
      "experience_level": "confident"
    },
    "voice_clone_id": "voice_abc123",
    "created_at": "2025-10-01T00:00:00.000Z",
    "updated_at": "2025-10-18T12:00:00.000Z"
  }
}
```

---

#### PUT `/account/profile`

Update user profile preferences.

**Headers:**
```http
Content-Type: application/json
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "tone": "witty",
  "dating_goal": "relationship",
  "experience_level": "expert"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "message": "Profile updated successfully",
    "updated_fields": ["tone", "dating_goal", "experience_level"]
  }
}
```

---

#### DELETE `/account/delete`

Request account deletion (GDPR/CCPA compliance).

**Headers:**
```http
Content-Type: application/json
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "reason": "No longer using the service",
  "confirm": true
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "deletion_id": "del_xyz789",
    "scheduled_for": "2025-10-25T00:00:00.000Z",
    "message": "Your account will be deleted within 7 days. All data will be permanently removed."
  }
}
```

**Status Codes:**
- `200`: Deletion scheduled
- `400`: Confirmation not provided
- `401`: Unauthorized
- `500`: Internal server error

---

### Legal & Compliance

#### GET `/legal/privacy-policy`

Get privacy policy in HTML or JSON format.

**Headers:** None required

**Query Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `format` | string | No | `"html"` or `"json"` (default: `"html"`) |

**Response (HTML):**
```html
<!DOCTYPE html>
<html>
<head>
    <title>Vibe8.AI Privacy Policy</title>
</head>
<body>
    <h1>Privacy Policy</h1>
    <p>Last Updated: October 18, 2025</p>
    ...
</body>
</html>
```

**Response (JSON):**
```json
{
  "success": true,
  "data": {
    "title": "Privacy Policy",
    "last_updated": "2025-10-18",
    "sections": [
      {
        "heading": "Data Collection",
        "content": "We collect..."
      }
    ]
  }
}
```

---

#### GET `/legal/terms`

Get terms of service.

**Response:** Same structure as `/legal/privacy-policy`

---

#### POST `/legal/export-data`

Request data export (GDPR compliance).

**Headers:**
```http
Content-Type: application/json
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "email": "user@example.com",
  "format": "json"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "export_id": "export_xyz789",
    "status": "processing",
    "estimated_completion": "2025-10-18T13:00:00.000Z",
    "download_url_expires_at": "2025-10-25T12:00:00.000Z"
  }
}
```

---

## Data Models

### Suggestion Object

```typescript
interface Suggestion {
  id: string;                  // Unique suggestion ID (e.g., "sugg_abc123")
  text: string;                // Suggestion text
  confidence: number;          // 0-100 confidence score
  reasoning: string;           // Why this suggestion works
  next_steps: string;          // What to do after they respond
  tone: string;                // "playful" | "serious" | "witty" | "romantic"
  category: string;            // "opener" | "reply"
  created_at?: string;         // ISO timestamp
}
```

### Coaching Object

```typescript
interface Coaching {
  overall_strategy: string;       // High-level strategy explanation
  tone_analysis: string;          // Analysis of profile tone
  next_steps: string;             // Advice for continuing conversation
  conversation_flow?: string;     // Expected conversation progression
  red_flags?: string;             // Potential issues detected
  confidence_explanation: string; // Why confidence scores are what they are
}
```

### Level Object

```typescript
interface Level {
  level: number;            // 1-5
  title: string;            // "Beginner" | "Learner" | "Confident" | "Skilled" | "Expert"
  current_xp: number;       // Current XP
  next_level_at: number;    // XP required for next level
  xp_to_next: number;       // XP remaining to next level
  percentage_to_next: number; // 0-100
  icon: string;             // Emoji icon
}
```

### Achievement Object

```typescript
interface Achievement {
  id: string;               // Unique achievement ID
  title: string;            // Achievement title
  description: string;      // What user needs to do
  icon: string;             // Emoji icon
  xp_reward: number;        // XP earned when unlocked
  unlocked_at?: string;     // ISO timestamp (if unlocked)
  progress?: number;        // Current progress (if locked)
  requirement?: number;     // Requirement to unlock (if locked)
  percentage?: number;      // 0-100 progress percentage (if locked)
  ready_to_unlock?: boolean; // True if requirements met but not yet unlocked
}
```

---

## Error Handling

### Error Response Format

All errors follow this structure:

```json
{
  "success": false,
  "error": {
    "code": "INVALID_REQUEST",
    "message": "Missing required field: image_data",
    "details": {
      "field": "image_data",
      "provided": null,
      "expected": "base64 string"
    }
  }
}
```

### Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `INVALID_REQUEST` | 400 | Malformed request or missing required fields |
| `UNAUTHORIZED` | 401 | Missing or invalid authentication token |
| `FORBIDDEN` | 403 | Authenticated but not authorized for this action |
| `NOT_FOUND` | 404 | Resource not found (user, screenshot, etc.) |
| `IMAGE_TOO_LARGE` | 413 | Image exceeds 10MB limit |
| `TEXT_TOO_LONG` | 413 | Text exceeds character limit |
| `INVALID_IMAGE_FORMAT` | 422 | Image format not supported (use PNG/JPEG) |
| `RATE_LIMIT_EXCEEDED` | 429 | Too many requests, try again later |
| `CONTENT_MODERATION_FAILED` | 451 | Generated content flagged by moderation |
| `INTERNAL_ERROR` | 500 | Server error, try again later |
| `AI_SERVICE_ERROR` | 502 | External AI service unavailable |
| `SERVICE_UNAVAILABLE` | 503 | API temporarily unavailable |

---

## Rate Limiting

### Limits

| Endpoint | Limit | Window |
|----------|-------|--------|
| `/flirts/generate_flirts` | 20 requests | 1 hour |
| `/flirts/refresh` | 50 requests | 1 hour |
| `/voice/generate` | 10 requests | 1 hour |
| `/voice/upload_sample` | 5 requests | 1 day |
| All other endpoints | 100 requests | 1 hour |

### Rate Limit Headers

Responses include rate limit information:

```http
X-RateLimit-Limit: 20
X-RateLimit-Remaining: 15
X-RateLimit-Reset: 1697640000
```

### Rate Limit Exceeded Response

```json
{
  "success": false,
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Rate limit exceeded. Try again in 1800 seconds.",
    "details": {
      "limit": 20,
      "remaining": 0,
      "reset_at": "2025-10-18T13:00:00.000Z"
    }
  }
}
```

---

## Examples

### Example 1: Generate Suggestions from Screenshot

**cURL:**
```bash
curl -X POST https://vibe8-api-production.onrender.com/api/v1/flirts/generate_flirts \
  -H "Content-Type: application/json" \
  -d '{
    "image_data": "iVBORw0KGgoAAAANSUhEUgAA...",
    "suggestion_type": "opener",
    "tone": "playful",
    "user_id": "user_123"
  }'
```

**JavaScript (fetch):**
```javascript
const response = await fetch('https://vibe8-api-production.onrender.com/api/v1/flirts/generate_flirts', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    image_data: base64Screenshot,
    suggestion_type: 'opener',
    tone: 'playful',
    user_id: 'user_123'
  })
});

const data = await response.json();
console.log(data.data.suggestions);
```

**Swift (URLSession):**
```swift
let url = URL(string: "https://vibe8-api-production.onrender.com/api/v1/flirts/generate_flirts")!
var request = URLRequest(url: url)
request.httpMethod = "POST"
request.setValue("application/json", forHTTPHeaderField: "Content-Type")

let body: [String: Any] = [
    "image_data": imageData.base64EncodedString(),
    "suggestion_type": "opener",
    "tone": "playful",
    "user_id": "user_123"
]
request.httpBody = try? JSONSerialization.data(withJSONObject: body)

URLSession.shared.dataTask(with: request) { data, response, error in
    guard let data = data else { return }
    let result = try? JSONDecoder().decode(FlirtResponse.self, from: data)
    print(result?.data.suggestions)
}.resume()
```

---

### Example 2: Refresh Suggestions

**cURL:**
```bash
curl -X POST https://vibe8-api-production.onrender.com/api/v1/flirts/refresh \
  -H "Content-Type: application/json" \
  -d '{
    "screenshot_id": "ss_xyz789",
    "suggestion_type": "opener",
    "tone": "witty",
    "previous_suggestions": [
      "Previous suggestion 1",
      "Previous suggestion 2"
    ]
  }'
```

---

### Example 3: Get User Progress

**cURL:**
```bash
curl -X GET https://vibe8-api-production.onrender.com/api/v1/flirts/progress \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

**JavaScript:**
```javascript
const response = await fetch('https://vibe8-api-production.onrender.com/api/v1/flirts/progress', {
  headers: {
    'Authorization': `Bearer ${token}`
  }
});

const data = await response.json();
console.log(`Level: ${data.data.level.level} - ${data.data.level.title}`);
console.log(`XP: ${data.data.level.current_xp}/${data.data.level.next_level_at}`);
console.log(`Achievements: ${data.data.achievements.unlocked_count}/12`);
```

---

### Example 4: Generate Voice Message

**cURL:**
```bash
curl -X POST https://vibe8-api-production.onrender.com/api/v1/voice/generate \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  -d '{
    "text": "Hey! Your profile caught my eye. I love hiking too!",
    "voice_id": "voice_abc123",
    "background_sound": "beach",
    "user_id": "user_123"
  }'
```

---

**Version:** 1.0.0
**Last Updated:** October 18, 2025

For API support, contact: support@vibe8.ai
