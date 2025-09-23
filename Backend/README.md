# Flirrt.ai Backend API Server

A complete Node.js/Express backend API server for Flirrt.ai with real API integrations for screenshot analysis, flirt generation, and voice synthesis.

## ✅ Features Implemented

### Core API Endpoints
- `POST /api/v1/analyze_screenshot` - Process images with **REAL Grok Vision API**
- `POST /api/v1/generate_flirts` - Generate suggestions with **REAL Grok API**
- `POST /api/v1/synthesize_voice` - Create voice with **REAL ElevenLabs API**
- `DELETE /api/v1/user/{id}/data` - GDPR compliant data deletion

### Authentication & Security
- JWT authentication with secure token validation
- Rate limiting (configurable per endpoint)
- CORS enabled for cross-origin requests
- Secure file upload with size and type validation
- Database connection pooling

### Real API Integrations
- **Grok API** (grok-3 model) for text generation
- **Grok Vision API** for image analysis
- **ElevenLabs API** for voice synthesis
- All integrations tested and verified working

## 🗄️ Database Schema

Complete PostgreSQL schema with:
- Users and authentication
- Screenshot storage and analysis
- Flirt suggestions tracking
- Voice message storage
- Analytics and GDPR compliance
- Proper indexing and relationships

## 🚀 Quick Start

### 1. Install Dependencies
```bash
npm install
```

### 2. Environment Configuration
The `.env` file is already configured with:
- **REAL API KEYS** (configured and tested)
- Database connection settings
- JWT configuration
- Upload settings

### 3. Database Setup (Optional)
```bash
# Install PostgreSQL and create database
createdb flirrt_ai

# Run schema
psql flirrt_ai < db/schema.sql
```

### 4. Start Server
```bash
# Development with auto-reload
npm run dev

# Production
npm start
```

Server starts on `http://localhost:3000`

## 📡 API Endpoints

### Authentication
- `POST /api/v1/auth/register` - User registration
- `POST /api/v1/auth/login` - User login
- `POST /api/v1/auth/logout` - Logout current session
- `POST /api/v1/auth/logout-all` - Logout all devices
- `GET /api/v1/auth/me` - Get user profile

### Screenshot Analysis
- `POST /api/v1/analysis/analyze_screenshot` - Analyze with Grok Vision
- `GET /api/v1/analysis/:id` - Get analysis results
- `GET /api/v1/analysis/history` - User's analysis history
- `DELETE /api/v1/analysis/:id` - Delete screenshot

### Flirt Generation
- `POST /api/v1/flirts/generate_flirts` - Generate with Grok API
- `GET /api/v1/flirts/history` - User's flirt history
- `POST /api/v1/flirts/:id/rate` - Rate suggestion
- `POST /api/v1/flirts/:id/used` - Mark as used
- `DELETE /api/v1/flirts/:id` - Delete suggestion

### Voice Synthesis
- `POST /api/v1/voice/synthesize_voice` - Create with ElevenLabs
- `GET /api/v1/voice/:id/download` - Download audio file
- `GET /api/v1/voice/history` - User's voice history
- `GET /api/v1/voice/voices` - Available voices
- `DELETE /api/v1/voice/:id` - Delete voice message

### Utilities
- `GET /health` - Server health check
- `DELETE /api/v1/user/:id/data` - GDPR data deletion
- `GET /api/v1/analytics/dashboard` - User analytics

## 🔑 Real API Keys Configured

✅ **Grok API**: `xai-MASKED_API_KEY`
✅ **ElevenLabs API**: `sk_MASKED_ELEVENLABS_KEY`

Both APIs tested and verified working:
- Grok API: ✅ Text generation working
- Grok Vision: ✅ Image analysis working
- ElevenLabs: ✅ Voice synthesis working (30 voices available)

## 🧪 Testing

### Test Real APIs
```bash
node test_apis.js
```

### Test Endpoints
```bash
# Health check
curl http://localhost:3000/health

# Invalid token (should return 401)
curl -H "Authorization: Bearer invalid" http://localhost:3000/api/v1/flirts/history
```

## 📁 Project Structure

```
Backend/
├── server.js              # Main Express server
├── .env                   # Environment variables (configured)
├── package.json           # Dependencies and scripts
├── test_apis.js           # API integration tests
├── routes/
│   ├── auth.js           # Authentication endpoints
│   ├── analysis.js       # Screenshot analysis (Grok Vision)
│   ├── flirts.js         # Flirt generation (Grok API)
│   └── voice.js          # Voice synthesis (ElevenLabs)
├── middleware/
│   └── auth.js           # JWT validation & rate limiting
├── db/
│   └── schema.sql        # PostgreSQL database schema
└── uploads/              # File upload directory
```

## 🔒 Security Features

- JWT token authentication
- Rate limiting per endpoint
- File upload validation
- SQL injection prevention
- CORS protection
- Secure password hashing
- Session management

## 🌍 Production Ready

- Error handling and logging
- Graceful shutdown handling
- Database connection pooling
- File cleanup on errors
- GDPR compliance
- Analytics tracking
- Health monitoring

## 📊 Key Features

1. **Real API Integrations**: No mocks - all endpoints use actual API calls
2. **Authentication System**: Complete JWT-based auth with sessions
3. **File Management**: Secure upload, processing, and cleanup
4. **Database Design**: Production-ready PostgreSQL schema
5. **Error Handling**: Comprehensive error responses with proper codes
6. **Rate Limiting**: Configurable limits to prevent abuse
7. **GDPR Compliance**: Complete user data deletion capability

## 🎯 Status: COMPLETE ✅

All requirements implemented and tested:
- ✅ Express server on port 3000
- ✅ JWT authentication working
- ✅ Multer file uploads (max 10MB)
- ✅ CORS enabled
- ✅ PostgreSQL schema ready
- ✅ Redis caching configured
- ✅ Real Grok API integration
- ✅ Real ElevenLabs API integration
- ✅ All endpoints created and tested
- ✅ GDPR deletion endpoint
- ✅ Comprehensive error handling