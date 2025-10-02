# 📡 API CONTRACTS - FLIRRT.AI BACKEND

## 🌐 Base Configuration

### Server Details
- **Base URL**: `http://localhost:3000/api/v1`
- **Production URL**: TBD
- **Authentication**: Bearer token in Authorization header
- **Content Types**: JSON and Multipart Form Data

### Authentication Header
```
Authorization: Bearer {token}
```

### Test Token for Development
```
Bearer test-token-for-development
```

## 🔐 Authentication Endpoints

### 1. Apple Sign In
```http
POST /auth/apple
```

**Request Body:**
```json
{
  "userIdentifier": "apple-user-id",
  "identityToken": "base64-encoded-token",
  "authorizationCode": "base64-encoded-code"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "token": "jwt-token-here",
  "user": {
    "id": "user-123",
    "apple_id": "apple-user-id",
    "created_at": "2025-09-23T10:00:00Z"
  }
}
```

**Error Response (401):**
```json
{
  "success": false,
  "error": "Invalid Apple credentials",
  "code": "INVALID_APPLE_AUTH"
}
```

### 2. Token Validation
```http
POST /auth/validate
```

**Headers:**
```
Authorization: Bearer {token}
```

**Response (200 OK):**
```json
{
  "valid": true,
  "user_id": "user-123",
  "expires_at": "2025-09-24T10:00:00Z"
}
```

## 📸 Screenshot Analysis

### 3. Upload & Analyze Screenshot
```http
POST /analyze_screenshot
```

**Headers:**
```
Authorization: Bearer {token}
Content-Type: multipart/form-data
```

**Multipart Form Fields:**
- `screenshot`: (file) Image file (JPEG/PNG)
- `context`: (string) Optional context like "dating_app_screenshot"
- `preferences`: (JSON) Optional user preferences

**Example cURL:**
```bash
curl -X POST http://localhost:3000/api/v1/analyze_screenshot \
  -H "Authorization: Bearer {token}" \
  -F "screenshot=@screenshot.jpg" \
  -F "context=dating_app_screenshot"
```

**Response (200 OK):**
```json
{
  "success": true,
  "screenshot_id": "scr-abc123",
  "analysis": {
    "profile_type": "dating",
    "detected_elements": ["bio", "photos", "interests"],
    "conversation_context": "match_profile",
    "personality_indicators": ["adventurous", "creative"],
    "suggested_approach": "casual_friendly"
  },
  "confidence": 0.92,
  "processing_time": 1250
}
```

**Error Response (400):**
```json
{
  "success": false,
  "error": "Screenshot file is required",
  "code": "NO_FILE_UPLOADED"
}
```

**Error Response (413):**
```json
{
  "success": false,
  "error": "File too large. Maximum size is 10MB",
  "code": "FILE_TOO_LARGE"
}
```

## 💬 Flirt Generation

### 4. Generate Flirt Suggestions
```http
POST /generate_flirts
```

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "screenshot_id": "scr-abc123",
  "suggestion_type": "opener",
  "tone": "playful",
  "user_preferences": {
    "humor_level": "high",
    "formality": "casual",
    "emoji_usage": "moderate"
  },
  "context": "Just matched on dating app"
}
```

**Parameters:**
- `screenshot_id`: (string) Required - ID from analyze_screenshot or "fresh-{timestamp}" for fresh starts
- `suggestion_type`: (string) Required - One of: "opener", "response", "continuation"
- `tone`: (string) Optional - One of: "playful", "witty", "romantic", "casual", "bold"
- `user_preferences`: (object) Optional - User's style preferences
- `context`: (string) Optional - Additional context

**Response (200 OK):**
```json
{
  "success": true,
  "suggestions": [
    {
      "id": "sug-1",
      "text": "Hey! I noticed you're into hiking too. What's the most breathtaking trail you've conquered?",
      "tone": "playful",
      "confidence": 0.88,
      "voice_available": false,
      "metadata": {
        "length": "short",
        "question_count": 1,
        "emoji_count": 0
      }
    },
    {
      "id": "sug-2",
      "text": "Your adventure photos are amazing! 📸 Is that Yosemite in your third pic?",
      "tone": "casual",
      "confidence": 0.85,
      "voice_available": false,
      "metadata": {
        "length": "short",
        "question_count": 1,
        "emoji_count": 1
      }
    },
    {
      "id": "sug-3",
      "text": "I have to know - how did you get that perfect sunset shot? Professional photographer or just naturally talented?",
      "tone": "flirty",
      "confidence": 0.82,
      "voice_available": false,
      "metadata": {
        "length": "medium",
        "question_count": 2,
        "emoji_count": 0
      }
    }
  ],
  "screenshot_analysis_used": true,
  "generation_model": "grok-3"
}
```

**Error Response (400):**
```json
{
  "success": false,
  "error": "Screenshot ID is required",
  "code": "MISSING_SCREENSHOT_ID"
}
```

**Error Response (429):**
```json
{
  "success": false,
  "error": "Rate limit exceeded. Try again in 60 seconds",
  "code": "RATE_LIMIT_EXCEEDED",
  "retry_after": 60
}
```

## 🎤 Voice Services

### 5. Clone Voice
```http
POST /voice/clone
```

**Headers:**
```
Authorization: Bearer {token}
Content-Type: multipart/form-data
```

**Multipart Form Fields:**
- `audio`: (file) Audio file (M4A/MP3/WAV)
- `name`: (string) Voice profile name
- `description`: (string) Optional description
- `script_tone`: (string) Tone of script read (friendly/flirty/confident/playful)
- `include_background`: (boolean) Whether background noise was included

**Response (200 OK):**
```json
{
  "success": true,
  "voice_id": "voice-xyz789",
  "status": "processing",
  "estimated_completion": "2025-09-23T10:05:00Z",
  "elevenlabs_voice_id": "abc123"
}
```

### 6. Synthesize Speech
```http
POST /voice/synthesize
```

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "text": "Hey there! How's your day going?",
  "voice_id": "voice-xyz789",
  "model_id": "eleven_monolingual_v1",
  "voice_settings": {
    "stability": 0.5,
    "similarity_boost": 0.75,
    "style": 0.5,
    "use_speaker_boost": true
  }
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "audio_url": "http://localhost:3000/audio/syn-abc123.mp3",
  "duration": 2.5,
  "character_count": 28,
  "expires_at": "2025-09-24T10:00:00Z"
}
```

## 📊 User Preferences

### 7. Update Preferences
```http
PUT /users/preferences
```

**Headers:**
```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "communication_style": {
    "humor_level": "high",
    "emoji_usage": "frequent",
    "formality": "casual",
    "flirtiness": "moderate"
  },
  "interests": ["hiking", "photography", "travel"],
  "personality_traits": ["adventurous", "creative", "outgoing"]
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "preferences_updated": true,
  "user_id": "user-123"
}
```

## 🔍 Health Check

### 8. Server Health
```http
GET /health
```

**No Authentication Required**

**Response (200 OK):**
```json
{
  "status": "healthy",
  "timestamp": "2025-09-23T10:00:00Z",
  "services": {
    "database": "connected",
    "redis": "connected",
    "grok_api": "available",
    "elevenlabs_api": "available"
  },
  "version": "1.0.0"
}
```

## 📝 Rate Limiting

### Default Limits
- **Screenshot Analysis**: 20 requests per 15 minutes
- **Flirt Generation**: 30 requests per 15 minutes
- **Voice Clone**: 5 requests per hour
- **Voice Synthesis**: 50 requests per hour

### Rate Limit Headers
Response includes:
```
X-RateLimit-Limit: 30
X-RateLimit-Remaining: 25
X-RateLimit-Reset: 1695465600
```

## 🔴 Error Codes

### Standard Error Response Format
```json
{
  "success": false,
  "error": "Human-readable error message",
  "code": "MACHINE_READABLE_CODE",
  "details": {
    "field": "Additional context if applicable"
  }
}
```

### Common Error Codes
- `UNAUTHORIZED`: Missing or invalid auth token
- `FORBIDDEN`: Valid token but insufficient permissions
- `NOT_FOUND`: Resource doesn't exist
- `BAD_REQUEST`: Invalid request parameters
- `RATE_LIMIT_EXCEEDED`: Too many requests
- `INTERNAL_ERROR`: Server error
- `SERVICE_UNAVAILABLE`: External API down
- `PAYMENT_REQUIRED`: Premium feature

## 🧪 Testing Endpoints

### Test with cURL

#### Test Authentication
```bash
# Get test token
curl -X POST http://localhost:3000/api/v1/auth/apple \
  -H "Content-Type: application/json" \
  -d '{"userIdentifier":"test-user","identityToken":"test","authorizationCode":"test"}'
```

#### Test Flirt Generation (No Screenshot)
```bash
curl -X POST http://localhost:3000/api/v1/generate_flirts \
  -H "Authorization: Bearer test-token" \
  -H "Content-Type: application/json" \
  -d '{
    "screenshot_id": "fresh-'$(date +%s)'",
    "suggestion_type": "opener",
    "tone": "playful"
  }'
```

#### Test Screenshot Analysis
```bash
# First create a test image
echo "test" > test.jpg

# Upload it
curl -X POST http://localhost:3000/api/v1/analyze_screenshot \
  -H "Authorization: Bearer test-token" \
  -F "screenshot=@test.jpg" \
  -F "context=test"
```

## 🔄 WebSocket Events (Future)

### Connection
```javascript
const ws = new WebSocket('ws://localhost:3000/ws');
ws.send(JSON.stringify({
  type: 'auth',
  token: 'jwt-token'
}));
```

### Events
- `suggestion.ready`: New suggestion available
- `voice.cloned`: Voice cloning complete
- `screenshot.analyzed`: Analysis complete

## 📚 Implementation Notes

### For Keyboard Extension
1. Keyboard extensions have limited memory (60MB)
2. Use URLSession instead of third-party libraries
3. Store auth token in shared App Group UserDefaults
4. Handle network failures gracefully with fallback suggestions

### Authentication Flow
1. User signs in with Apple in main app
2. Backend validates with Apple
3. JWT token issued and stored in Keychain
4. Token shared with keyboard via App Group
5. Keyboard uses token for all API calls

### Error Handling
- Always check `success` field first
- Use `code` for programmatic handling
- Display `error` message to user
- Log full response for debugging

## 🚀 Quick Start for Next Session

```swift
// In keyboard extension
let url = URL(string: "http://localhost:3000/api/v1/generate_flirts")!
var request = URLRequest(url: url)
request.httpMethod = "POST"
request.setValue("application/json", forHTTPHeaderField: "Content-Type")
request.setValue("Bearer test-token", forHTTPHeaderField: "Authorization")

let body = [
    "screenshot_id": "fresh-\(Date().timeIntervalSince1970)",
    "suggestion_type": "opener",
    "tone": "playful"
]

request.httpBody = try? JSONSerialization.data(withJSONObject: body)

URLSession.shared.dataTask(with: request) { data, response, error in
    // Handle response
}.resume()
```