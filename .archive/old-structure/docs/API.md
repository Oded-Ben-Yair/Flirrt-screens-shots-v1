# API Documentation

Backend API reference for Vibe8AI server.

**Base URL**: `http://localhost:3000/api/v1`

**Version**: 1.0
**Last Updated**: October 2025

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

## 🛡️ Security & Validation

### Input Validation
All API endpoints enforce strict input validation to prevent security vulnerabilities and ensure data integrity.

**Validation Features**:
- Whitelist-based parameter validation
- XSS (Cross-Site Scripting) protection on all text inputs
- Path traversal attack prevention
- SQL injection protection via parameterized queries
- DoS protection via input length limits

**Error Response Format**:
All validation errors follow this standardized format:
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Detailed error message",
    "details": {}
  }
}
```

### XSS Protection
All user-supplied text inputs are sanitized using the `xss` library before processing:
- HTML tags are stripped
- Script tags are removed
- Style tags are blocked
- Only plain text is accepted

**Protected Fields**:
- `context` (flirt generation)
- `feedback` (rating endpoints)
- `preferences` (analysis endpoints)
- `text` (voice synthesis)
- All other user-supplied text

### Validation Rules

#### Screenshot ID
- **Format**: Alphanumeric with hyphens and underscores only
- **Max Length**: 100 characters
- **Example Valid**: `screenshot-123_abc`, `test_screenshot_2024`
- **Example Invalid**: `screenshot@123`, `../../../etc/passwd`

**Error Response**:
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid screenshot ID format"
  }
}
```

#### Suggestion Type
- **Type**: Enum (whitelist enforced)
- **Valid Values**:
  - `opener` - Opening message for new conversations
  - `reply` - Reply to received message
  - `question` - Question-based suggestions
  - `compliment` - Compliment suggestions
  - `icebreaker` - Ice-breaker messages
  - `response` - General response suggestions
  - `continuation` - Conversation continuation
- **Example Valid**: `"suggestion_type": "opener"`
- **Example Invalid**: `"suggestion_type": "custom_type"`

**Error Response**:
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid suggestion type. Must be one of: opener, reply, question, compliment, icebreaker, response, continuation"
  }
}
```

#### Tone
- **Type**: Enum (whitelist enforced)
- **Valid Values**:
  - `playful` - Light and fun tone
  - `direct` - Straightforward approach
  - `thoughtful` - Deep and meaningful
  - `witty` - Clever and humorous
  - `romantic` - Sweet and romantic
  - `casual` - Relaxed and friendly
  - `bold` - Confident and daring
- **Example Valid**: `"tone": "playful"`
- **Example Invalid**: `"tone": "aggressive"`

**Error Response**:
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid tone. Must be one of: playful, direct, thoughtful, witty, romantic, casual, bold"
  }
}
```

#### Text Input
- **Max Length**: 1000 characters
- **Security**: XSS sanitized (HTML tags stripped)
- **Applies To**: `context`, `feedback`, `text` parameters

**Error Response**:
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Text too long. Maximum 1000 characters allowed"
  }
}
```

#### Voice Model
- **Type**: Enum (ElevenLabs models)
- **Valid Values**:
  - `eleven_monolingual_v1` - English only, faster
  - `eleven_multilingual_v1` - Multiple languages
  - `eleven_multilingual_v2` - Enhanced multilingual
- **Optional**: Yes (defaults to `eleven_multilingual_v2`)

**Error Response**:
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid voice model. Must be one of: eleven_monolingual_v1, eleven_multilingual_v1, eleven_multilingual_v2"
  }
}
```

#### Voice ID
- **Format**: Alphanumeric only
- **Max Length**: 50 characters
- **Example Valid**: `21m00Tcm4TlvDq8ikWAM`
- **Example Invalid**: `voice-id-with-dashes`
- **Optional**: Yes

**Error Response**:
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid voice ID format"
  }
}
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

**Validation**:
- `screenshot_id` (optional): Alphanumeric + hyphens/underscores, max 100 chars
- `suggestion_type` (required): Must be one of 7 valid types (see Validation Rules)
- `tone` (required): Must be one of 7 valid tones (see Validation Rules)
- `context` (optional): Max 1000 chars, XSS sanitized

**Valid Request Example**:
```json
{
  "screenshot_id": "screenshot_abc123",
  "suggestion_type": "opener",
  "tone": "playful",
  "context": "First message on Tinder"
}
```

**Invalid Request Example**:
```json
{
  "screenshot_id": "../../../etc/passwd",
  "suggestion_type": "invalid_type",
  "tone": "aggressive"
}
```

**Success Response**:
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
      }
    ],
    "request_id": "uuid"
  }
}
```

**Validation Error Response**:
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid suggestion type. Must be one of: opener, reply, question, compliment, icebreaker, response, continuation"
  }
}
```

**Rate Limiting**: 100 requests/hour per user (planned)

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

**Validation**:
- `user_preferences` (required): Object with user profile data
- All text fields: XSS sanitized
- No specific field validation (flexible user input)

**Response**: Same as `generate_flirts`

**Performance**: 10-20 seconds typical

**Rate Limiting**: 50 requests/hour per user (planned)

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

**Validation**:
- `screenshot` (required): File must be present, size limits apply
- `context` (optional): Max 1000 chars, XSS sanitized
- `preferences` (optional): XSS sanitized if provided
- File types: JPEG, PNG, HEIC only

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

**Validation Error Response**:
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Screenshot file is required"
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

**Rate Limiting**: 30 requests/hour per user (planned)

---

### Orchestrated Flirts (V2 API)

#### `POST /api/v1/orchestrated-flirts/generate`
Dual-model AI pipeline (Gemini + Grok) for highest quality.

**Authentication**: Required

**Request Body**:
```json
{
  "image_data": "base64_encoded_image_data",
  "screenshot_id": "uuid",
  "suggestion_type": "opener",
  "tone": "playful",
  "user_preferences": {
    "communication_style": "Playful",
    "confidence_level": 7
  },
  "context": "First message on Bumble",
  "pipeline_strategy": "auto",
  "bypass_cache": false
}
```

**Validation**:
- `image_data` (required): Base64 encoded image
- `screenshot_id` (optional): Alphanumeric + hyphens/underscores, max 100 chars
- `suggestion_type` (optional): Must be one of 7 valid types
- `tone` (optional): Must be one of 7 valid tones
- `context` (optional): Max 1000 chars, XSS sanitized
- `pipeline_strategy` (optional): "auto", "fast", "standard", or "comprehensive"

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

**Rate Limiting**: 20 requests per 15 minutes

---

## 🔄 Voice Synthesis

#### `POST /api/v1/voice/synthesize`
Convert text to speech using ElevenLabs voice models.

**Authentication**: Required (or keyboard bypass)

**Request Body**:
```json
{
  "text": "Hey! How's your day going?",
  "voice_id": "21m00Tcm4TlvDq8ikWAM",
  "voice_model": "eleven_multilingual_v2",
  "background_sound": "beach"
}
```

**Validation**:
- `text` (required): Max 1000 chars, XSS sanitized
- `voice_id` (optional): Alphanumeric only, max 50 chars
- `voice_model` (optional): Must be one of 3 ElevenLabs models (see Validation Rules)
- `background_sound` (optional): No validation (flexible input)

**Valid Request Example**:
```json
{
  "text": "I love your smile!",
  "voice_id": "21m00Tcm4TlvDq8ikWAM",
  "voice_model": "eleven_multilingual_v2"
}
```

**Invalid Request Example**:
```json
{
  "text": "<script>alert('xss')</script>Very long text...",
  "voice_id": "invalid-voice-id-format",
  "voice_model": "custom_model"
}
```

**Success Response**:
```json
{
  "success": true,
  "data": {
    "audio_url": "https://...",
    "voice_id": "21m00Tcm4TlvDq8ikWAM",
    "duration_seconds": 3.2
  }
}
```

**Validation Error Response**:
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Text too long. Maximum 1000 characters allowed"
  }
}
```

**Rate Limiting**: 50 requests/hour per user (planned)

---

## ⚠️ Error Codes

### Validation Errors (400)
| Code | HTTP Status | Meaning |
|------|-------------|---------|
| `VALIDATION_ERROR` | 400 | General validation failure |
| `MISSING_REQUIRED_FIELD` | 400 | Required field is missing |
| `INVALID_FORMAT` | 400 | Invalid format (e.g., screenshot_id) |
| `INVALID_INPUT` | 400 | Invalid input value |

### Authentication Errors (401)
| Code | HTTP Status | Meaning |
|------|-------------|---------|
| `AUTHENTICATION_FAILED` | 401 | Authentication failed |
| `INVALID_TOKEN` | 401 | Invalid JWT token |
| `TOKEN_EXPIRED` | 401 | JWT token has expired |

### Authorization Errors (403)
| Code | HTTP Status | Meaning |
|------|-------------|---------|
| `ACCESS_DENIED` | 403 | Access denied |
| `INSUFFICIENT_PERMISSIONS` | 403 | Insufficient permissions |

### Not Found Errors (404)
| Code | HTTP Status | Meaning |
|------|-------------|---------|
| `RESOURCE_NOT_FOUND` | 404 | Resource not found |
| `SCREENSHOT_NOT_FOUND` | 404 | Screenshot not found |
| `SUGGESTION_NOT_FOUND` | 404 | Suggestion not found |
| `VOICE_MESSAGE_NOT_FOUND` | 404 | Voice message not found |

### Timeout Errors (408, 504)
| Code | HTTP Status | Meaning |
|------|-------------|---------|
| `REQUEST_TIMEOUT` | 408/504 | Request timeout |
| `API_TIMEOUT` | 504 | External API timeout |

### Rate Limit Errors (429)
| Code | HTTP Status | Meaning |
|------|-------------|---------|
| `RATE_LIMIT_EXCEEDED` | 429 | Rate limit exceeded |
| `QUOTA_EXCEEDED` | 429 | API quota exceeded |

### Server Errors (500)
| Code | HTTP Status | Meaning |
|------|-------------|---------|
| `INTERNAL_SERVER_ERROR` | 500 | Internal server error |
| `DATABASE_ERROR` | 500 | Database operation failed |
| `CACHE_ERROR` | 500 | Cache operation failed |

### External API Errors (502, 503)
| Code | HTTP Status | Meaning |
|------|-------------|---------|
| `EXTERNAL_API_ERROR` | 502 | External API error |
| `GROK_API_ERROR` | 503 | Grok API failure |
| `ELEVENLABS_API_ERROR` | 503 | ElevenLabs API failure |
| `GEMINI_API_ERROR` | 503 | Gemini API failure |
| `SERVICE_UNAVAILABLE` | 503 | Service temporarily unavailable |

### Processing Errors
| Code | HTTP Status | Meaning |
|------|-------------|---------|
| `FLIRT_GENERATION_ERROR` | 500 | Flirt generation failed |
| `VOICE_SYNTHESIS_ERROR` | 500 | Voice synthesis failed |
| `IMAGE_PROCESSING_ERROR` | 500 | Image processing failed |
| `STREAM_ERROR` | 500 | Streaming error |

### Special Cases
| Code | HTTP Status | Meaning |
|------|-------------|---------|
| `NEEDS_MORE_CONTEXT` | 200 | Screenshot lacks context (not an error) |

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

### Current Implementation
**Status**: Partial rate limiting in production

**Active Rate Limits**:
- **Orchestrated Flirts**: 20 requests per 15 minutes
- **All Other Endpoints**: No limits (development mode)

### Planned Rate Limits (Per User)

| Endpoint | Limit | Window | Reason |
|----------|-------|--------|--------|
| `/generate_flirts` | 100 req | 1 hour | Standard API usage |
| `/generate_personalized_openers` | 50 req | 1 hour | Expensive AI calls |
| `/analyze_screenshot` | 30 req | 1 hour | Vision API costs |
| `/orchestrated-flirts/generate` | 20 req | 15 min | **ACTIVE** - Dual AI pipeline |
| `/voice/synthesize` | 50 req | 1 hour | Voice synthesis costs |
| `/health` | Unlimited | - | Health check |

### Rate Limit Headers
When rate limiting is enabled, responses include:
```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1696248000
```

### Rate Limit Exceeded Response
```json
{
  "success": false,
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Rate limit exceeded",
    "details": {
      "retry_after": 3600
    }
  }
}
```

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

## 📋 Quick Reference

### Validation Rules Summary

| Parameter | Type | Valid Values | Max Length | Optional | XSS Protected |
|-----------|------|--------------|------------|----------|---------------|
| `screenshot_id` | String | Alphanumeric + `-_` | 100 chars | Yes | No |
| `suggestion_type` | Enum | 7 types (see below) | - | No | No |
| `tone` | Enum | 7 tones (see below) | - | No | No |
| `context` | String | Any text | 1000 chars | Yes | Yes |
| `feedback` | String | Any text | 1000 chars | Yes | Yes |
| `text` | String | Any text | 1000 chars | No | Yes |
| `voice_model` | Enum | 3 models (see below) | - | Yes | No |
| `voice_id` | String | Alphanumeric only | 50 chars | Yes | No |

### Valid Suggestion Types (7)
```
opener, reply, question, compliment, icebreaker, response, continuation
```

### Valid Tones (7)
```
playful, direct, thoughtful, witty, romantic, casual, bold
```

### Valid Voice Models (3)
```
eleven_monolingual_v1, eleven_multilingual_v1, eleven_multilingual_v2
```

### Common Validation Errors

| Error Code | Common Cause | Fix |
|------------|--------------|-----|
| `VALIDATION_ERROR` | Invalid parameter value | Check parameter against whitelist |
| `MISSING_REQUIRED_FIELD` | Missing required parameter | Include all required fields |
| `INVALID_FORMAT` | Invalid string format | Use alphanumeric + allowed chars only |
| `INVALID_INPUT` | Input doesn't match rules | Check max length and format rules |

### Security Best Practices

1. **Always Sanitize User Input**: All text fields are XSS-sanitized server-side, but validate client-side too
2. **Use Whitelisted Values**: Only use documented enum values for `suggestion_type`, `tone`, `voice_model`
3. **Validate Length**: Keep all text inputs under 1000 characters
4. **Screenshot IDs**: Never include special characters or path separators (`/`, `\`, `..`)
5. **Rate Limiting**: Respect rate limits to avoid `RATE_LIMIT_EXCEEDED` errors
6. **Authentication**: Always include valid JWT token or keyboard extension header

### Testing Checklist

Before testing endpoints, verify:
- [ ] All required parameters are included
- [ ] Enum values match documented whitelists
- [ ] Text inputs are under 1000 characters
- [ ] Screenshot IDs use only alphanumeric + `-_`
- [ ] Voice IDs use only alphanumeric characters
- [ ] Authentication headers are included
- [ ] Request payload is valid JSON

### Example Valid Request
```bash
curl -X POST http://localhost:3000/api/v1/flirts/generate_flirts \
  -H "Content-Type: application/json" \
  -H "X-Keyboard-Extension: true" \
  -d '{
    "suggestion_type": "opener",
    "tone": "playful",
    "context": "First message on dating app"
  }'
```

### Example Invalid Request (Multiple Errors)
```bash
curl -X POST http://localhost:3000/api/v1/flirts/generate_flirts \
  -H "Content-Type: application/json" \
  -d '{
    "screenshot_id": "../../../etc/passwd",
    "suggestion_type": "custom_type",
    "tone": "aggressive",
    "context": "<script>alert('xss')</script>"
  }'
```

**Expected Response**: `VALIDATION_ERROR` - Invalid suggestion type

---

## 🔗 Related Documentation
- [ARCHITECTURE.md](./ARCHITECTURE.md) - System design
- [FEATURES.md](./FEATURES.md) - Feature documentation
- [SETUP.md](./SETUP.md) - Installation guide
- [KNOWN_ISSUES.md](./KNOWN_ISSUES.md) - Current bugs
- [Backend/utils/validation.js](../Backend/utils/validation.js) - Validation implementation
- [Backend/VALIDATION_INTEGRATION_REPORT.md](../Backend/VALIDATION_INTEGRATION_REPORT.md) - Validation integration details

---

## 📚 Additional Resources

### Validation Implementation
See `/Backend/utils/validation.js` for exact validation logic:
- `validateScreenshotId()` - Screenshot ID validation
- `validateSuggestionType()` - Suggestion type whitelist
- `validateTone()` - Tone whitelist
- `validateTextLength()` - Text length validation
- `validateVoiceModel()` - Voice model whitelist
- `validateVoiceId()` - Voice ID format validation
- `sanitizeText()` - XSS sanitization

### Error Handling
See `/Backend/utils/errorHandler.js` for error handling utilities:
- `sendErrorResponse()` - Standardized error responses
- `errorCodes` - All error code constants
- `httpStatus` - HTTP status code constants

### Testing
See `/Backend/tests/validation-enforcement.test.js` for validation test suite:
- 38 comprehensive test cases
- Coverage for all validation functions
- Integration tests for endpoint validation

---

**Version**: 1.0
**Last Updated**: October 2025
**Validation Coverage**: 100% (23 validations across all endpoints)
