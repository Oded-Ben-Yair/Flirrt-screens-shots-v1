# Features Documentation

Complete guide to all Vibe8AI features, their status, and usage.

---

## 🎯 Core Features

### 1. Keyboard Extension
**Status**: ✅ Partially Working

The main interface for Vibe8AI - an iOS custom keyboard that provides AI-powered suggestions.

#### How It Works:
1. Enable Vibe8 keyboard in iOS Settings
2. Switch to Vibe8 keyboard in any app (Messages, Tinder, etc.)
3. Tap the smart action button
4. Get AI-generated flirt suggestions
5. Tap a suggestion to insert it

#### Smart Button Modes:
- **💫 Fresh Flirts** (Default): Generates opener suggestions based on your personalization
- **📸 Analyze This** (After screenshot): Generates contextual responses based on conversation

#### Current Limitations:
- Screenshot detection not reliable yet
- API integration has intermittent connectivity issues
- See [KNOWN_ISSUES.md](./KNOWN_ISSUES.md) for details

---

### 2. Screenshot Analysis
**Status**: ❌ In Development

Analyzes dating app conversation screenshots to provide context-aware suggestions.

#### Intended Flow:
1. Take screenshot of conversation in any app
2. Keyboard automatically detects screenshot
3. Button changes to "📸 Analyze This"
4. Tap button → AI analyzes conversation
5. Get 3 contextual response suggestions

#### AI Analysis Pipeline:
1. **Gemini Vision** - Analyzes screenshot for:
   - Conversation history and context
   - Person's messaging style
   - Emotional tone
   - Topics discussed
2. **Grok** - Generates responses based on:
   - Gemini's analysis
   - Your personalization profile
   - Conversation context

#### Current Status:
- ✅ Backend analysis API working
- ✅ Image compression implemented (62% reduction)
- ❌ Screenshot detection not triggering reliably
- ❌ Darwin notification not reaching keyboard

**Workaround**: Use "Fresh Flirts" mode for now

---

### 3. Personalization System
**Status**: ✅ Working

Learns your style and preferences to generate better suggestions.

#### Onboarding Questionnaire:
Collects information about:
- **Dating Experience**: New to dating → Dating expert
- **Dating Goals**: Casual, serious relationship, friendship, etc.
- **Communication Style**: Direct, playful, thoughtful, funny, mysterious
- **Confidence Level**: 1-10 scale
- **Interests**: Sports, music, movies, travel, etc.
- **Ideal First Date**: Custom text input
- **Conversation Topics**: Dreams, humor, deep questions, etc.
- **Flirting Comfort**: 1-10 scale

#### How It's Used:
- Stored in App Groups for cross-app sharing
- Keyboard loads profile on launch
- Sent to backend with every API request
- Influences AI tone, style, and content

#### Data Storage:
- Location: `UserDefaults` in `group.com.vibe8.shared`
- Format: JSON with versioning
- Persistence: Survives app restarts
- Privacy: Never leaves your device except for API requests

---

### 4. Voice Cloning & Synthesis
**Status**: 🟡 Partially Implemented

Record your voice to create audio messages with your cloned voice.

#### Voice Recording Flow:
1. Complete onboarding questionnaire
2. Tap "Create Voice Clone" button
3. Read provided script while recording
4. Voice uploaded to ElevenLabs
5. Voice ID saved for future use

#### Voice Script Options:
- Casual conversation snippets
- Flirty phrases
- Thoughtful questions
- Funny one-liners

#### Background Noise Options:
- 🏖️ Beach waves
- 🐦 Birds chirping
- 🎉 Party atmosphere
- ☕ Coffee shop ambiance
- 🌧️ Rain sounds

#### Current Status:
- ✅ Recording UI complete and functional
- ✅ Script selector working
- ✅ Background noise picker implemented
- ❌ ElevenLabs API integration pending
- ❌ Playback not yet connected

---

### 5. Authentication
**Status**: ✅ Working

Secure user authentication using Apple Sign In.

#### Features:
- Sign in with Apple (one-tap authentication)
- Automatic account creation
- JWT token management
- Keychain storage for credentials
- Session persistence

#### Security:
- No password storage
- Apple-managed authentication
- JWT tokens for API authorization
- Keychain for secure credential storage

---

## 🔧 Backend Features

### AI Orchestration
**Status**: ✅ Working

Multi-model AI pipeline for generating high-quality suggestions.

#### Dual-Model Architecture:
1. **Gemini Vision** (Analysis)
   - Detailed image analysis
   - Context extraction
   - Conversation understanding

2. **Grok** (Generation)
   - Fast response generation (<10s avg)
   - Contextual flirts
   - Personalization-aware

#### Quality Assurance:
- Confidence scoring (0.0-1.0)
- Uniqueness validation (no duplicates)
- Content filtering
- Circuit breaker for API failures

#### Performance Metrics:
- Response time: 9-22 seconds
- Success rate: 100% (when backend is running)
- Timeout protection: 30 seconds

---

### Database (SQLite)
**Status**: ✅ Working

Local SQLite database for caching and analytics.

#### Tables:
- `users` - User profiles and authentication
- `screenshots` - Analyzed screenshots metadata
- `suggestions` - Generated flirt suggestions
- `voice_clones` - Voice ID mappings

#### Features:
- Automatic schema migration
- Foreign key constraints
- Indexed for performance
- Transaction support

---

## 📱 iOS App Features

### Main App Screens

#### 1. Welcome/Login Screen
- Gradient background (black → gray)
- "Continue with Apple" button
- Feature preview cards

#### 2. Onboarding Flow
- 4-page introduction
- Interactive questionnaire
- Progress indicators
- Skip option

#### 3. Main Dashboard
- Welcome message with user name
- Voice clone status
- Quick action buttons
- Logout option

#### 4. Settings
- Account information
- Keyboard setup instructions
- Voice clone management
- Privacy settings

---

## 🎨 Design System

### Color Palette:
- **Primary**: Pink (`.systemPink`)
- **Background**: Black → Gray gradient
- **Text**: White primary, Gray secondary
- **Accents**: Blue (analyze mode), Green (success)

### Typography:
- Headlines: Bold, large
- Body: Regular, readable
- Buttons: Semibold, prominent

### Animations:
- Smooth transitions (0.3s ease)
- Button press feedback
- Loading indicators
- Haptic feedback for important actions

---

## 🚀 Upcoming Features

### Planned (Not Yet Implemented):
- [ ] Profile photo upload for context
- [ ] Chat history import
- [ ] Custom tone creation
- [ ] Suggestion favoriting
- [ ] Usage analytics dashboard
- [ ] Multi-language support
- [ ] Video message suggestions
- [ ] AR filters for profile photos

---

## 📊 Feature Comparison

| Feature | Main App | Keyboard | Backend |
|---------|----------|----------|---------|
| Authentication | ✅ | N/A | ✅ |
| Personalization | ✅ | Reads | ✅ |
| Screenshot Analysis | ❌ | ❌ | ✅ |
| Flirt Generation | N/A | 🟡 | ✅ |
| Voice Recording | ✅ | N/A | 🟡 |
| Voice Synthesis | ❌ | ❌ | 🟡 |

Legend: ✅ Working | 🟡 Partial | ❌ Broken/Pending

---

## 💡 Usage Tips

### For Best Results:
1. **Complete full onboarding** - Don't skip, be honest about preferences
2. **Enable Full Access** - Required for keyboard to make API requests
3. **Keep backend running** - Ensure `npm start` is running before using keyboard
4. **Give context** - Include conversation screenshots when possible
5. **Personalize suggestions** - Update your profile as your style evolves

### Performance Tips:
1. **Restart keyboard** if it becomes sluggish (switch away and back)
2. **Close other apps** to free memory for keyboard
3. **Wait for suggestions** - AI takes 10-20 seconds to generate quality responses
4. **Check network** - Keyboard needs internet for API calls

---

**Next Steps:**
- Read [ARCHITECTURE.md](./ARCHITECTURE.md) to understand how it all works
- Check [KNOWN_ISSUES.md](./KNOWN_ISSUES.md) for current limitations
- Review [API.md](./API.md) for backend integration details
