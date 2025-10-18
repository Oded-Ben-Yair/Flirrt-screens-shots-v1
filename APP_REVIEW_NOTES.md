# App Review Notes for Vibe8.AI

**App Name:** Vibe8.AI - Your Dating Wingman
**Version:** 1.0.0
**Build:** 1
**Bundle ID:** com.vibe8.app
**Category:** Social Networking
**Age Rating:** 17+ (Infrequent/Mild Sexual Content or Nudity)

---

## App Purpose

Vibe8.AI is an AI-powered dating assistant app that helps users improve their dating conversations through intelligent suggestion generation. The app uses advanced AI to analyze dating app screenshots and provide personalized, contextually appropriate conversation suggestions via a custom keyboard extension.

---

## Key Features

### 1. Custom Keyboard Extension
- **Functionality:** Displays up to 3 AI-generated conversation suggestions
- **Privacy:** Keyboard has no "Full Access" - does not collect or transmit user typing data
- **Communication:** Uses App Groups (group.com.vibe8) to share suggestions between main app and keyboard
- **Memory:** Optimized to stay under 50MB memory limit for keyboard extensions

### 2. Screenshot Analysis
- **How it works:** Users take screenshots of dating profiles or conversations
- **AI Processing:** Screenshots analyzed using Gemini 2.5 Pro Vision API
- **Privacy:** Screenshots processed and immediately deleted after analysis
- **Storage:** No screenshots stored permanently on our servers

### 3. AI-Powered Suggestions
- **Models Used:**
  - Google Gemini 2.5 Pro (image analysis)
  - OpenAI GPT-4 (coaching persona and reasoning)
  - xAI Grok-4 (backup generation)
  - Perplexity Sonar Pro (research and context)
- **Max 3 Suggestions:** Changed from 5 to 3 for better UX
- **Coaching Persona:** Includes reasoning, confidence scores, and next steps
- **Refresh Functionality:** Users can generate new alternatives

### 4. Voice Messages (ElevenLabs)
- **Functionality:** Convert text suggestions to voice messages
- **Voice Cloning:** Users can clone their voice (30-second sample)
- **Audio Mixing:** Background sounds (beach, party, forest)
- **Privacy:** Voice samples processed by ElevenLabs, not stored permanently

### 5. Gamification & Progress Tracking
- **Level System:** Beginner → Learner → Confident → Skilled → Expert
- **12 Achievements:** Track usage milestones and accomplishments
- **Stats:** Messages sent, profiles analyzed, daily streaks, avg confidence
- **Purpose:** Encourage consistent app usage and skill development

### 6. Personalization
- **Tone Preferences:** Playful, Serious, Witty, Romantic
- **Dating Goals:** Casual, Relationship, Friends, Exploring
- **Experience Level:** Beginner, Learner, Confident, Expert
- **Storage:** Saved via App Groups for keyboard access

---

## Third-Party Services

### AI Services (Content Generation)
1. **OpenAI GPT-4**
   - Purpose: Coaching persona with reasoning and explanations
   - Data Shared: Screenshot analysis results, user preferences
   - Privacy Policy: https://openai.com/privacy

2. **Google Gemini 2.5 Pro**
   - Purpose: Image analysis (dating profile screenshots)
   - Data Shared: Screenshot images (base64 encoded)
   - Privacy Policy: https://policies.google.com/privacy

3. **xAI Grok-4**
   - Purpose: Backup suggestion generation
   - Data Shared: Screenshot analysis results
   - Privacy Policy: https://x.ai/privacy

4. **Perplexity Sonar Pro**
   - Purpose: Research and context enrichment
   - Data Shared: Query text for research
   - Privacy Policy: https://www.perplexity.ai/privacy

### Voice Services
5. **ElevenLabs**
   - Purpose: Voice cloning and text-to-speech synthesis
   - Data Shared: User voice samples (30 seconds), text to synthesize
   - Privacy Policy: https://elevenlabs.io/privacy

### Content Moderation
6. **OpenAI Moderation API**
   - Purpose: Filter inappropriate content
   - Data Shared: Generated suggestions (text only)
   - Categories Blocked: Harassment, hate speech, explicit content, violence

All third-party services comply with GDPR and CCPA requirements.

---

## Privacy & Data Handling

### Data Collected
- **User Profile:** Email, birthdate (for age verification)
- **Screenshots:** Temporarily processed, then deleted
- **Suggestions:** Text of generated suggestions (stored for history)
- **Voice Samples:** 30-second recording for voice cloning
- **Usage Stats:** Gamification data (messages sent, profiles analyzed, etc.)
- **Preferences:** Tone, goal, experience level

### Data Not Collected
- **Keyboard Typing:** Keyboard extension does NOT have "Full Access" - cannot see what users type
- **Location Data:** Not collected
- **Contacts:** Not accessed
- **Photos:** Only screenshots user explicitly selects
- **Messages:** Not accessed or stored

### Data Encryption
- **In Transit:** All data transmitted via HTTPS (TLS 1.2+)
- **At Rest:** Database encrypted (PostgreSQL on Render.com)
- **API Keys:** Stored as environment variables, never in code

### Data Retention
- **Screenshots:** Deleted immediately after analysis
- **Suggestions:** Retained until user deletes account
- **Voice Samples:** Deleted after voice clone creation
- **User Profile:** Deleted upon account deletion request

### User Rights
- **Account Deletion:** Full deletion within 7 days
- **Data Export:** GDPR-compliant data export available
- **Access Request:** Users can request all stored data

**Privacy Policy URL:** https://[YOUR_DOMAIN]/api/v1/legal/privacy-policy

---

## Age Restriction

### 18+ Enforcement
- **Age Verification:** Required at onboarding
- **Birthdate Check:** Must be 18+ to proceed
- **Storage:** Birthdate stored for compliance
- **Blocking:** Users under 18 cannot access app features

### Why 18+?
- Dating app content is age-restricted (17+ minimum for dating apps)
- Content may reference romantic/dating scenarios
- Voice message feature could be misused by minors

**App Store Age Rating:** 17+ (Infrequent/Mild Sexual Content or Nudity)

---

## Content Moderation

### Moderation System
- **API:** OpenAI Moderation API
- **Triggers:** All generated suggestions scanned before display
- **Blocked Content:**
  - Harassment and bullying
  - Hate speech
  - Sexual content (explicit)
  - Violence and threats
  - Self-harm references

### Moderation Process
1. Suggestion generated by AI
2. Sent to OpenAI Moderation API
3. Flagged content filtered out
4. Only appropriate suggestions shown to user
5. All moderation events logged for review

### User Reporting
- Users can report inappropriate suggestions
- Reported content reviewed manually
- False positives corrected

---

## Demo Account

**For App Review Team:**

Email: demo@vibe8.ai
Password: [PROVIDED SEPARATELY VIA APP STORE CONNECT]

**Demo Instructions:**
1. Log in with demo account
2. Complete age verification (use birthdate: 01/01/1990)
3. Skip voice recording (or record 30-second sample)
4. Grant photo library permission
5. Go to "Screenshots" tab
6. Tap "Take Screenshot" button
7. Select sample profile screenshot (provided in TestFlight notes)
8. Wait for analysis (15-30 seconds)
9. View 3 AI-generated suggestions
10. Enable keyboard: Settings → General → Keyboard → Keyboards → Add New Keyboard → Vibe8
11. Open Notes app or Messages
12. Switch to Vibe8 keyboard
13. Suggestions appear at top of keyboard
14. Tap suggestion to insert text
15. Tap refresh button for new suggestions

**Sample Screenshots Provided:**
- Dating profile screenshot (Clarinha profile example)
- Chat conversation screenshot
- Available in TestFlight description

---

## Test Instructions

### Complete User Flow

**Step 1: First Launch**
- Age verification screen appears
- Enter birthdate (must be 18+)
- Tap "Continue"

**Step 2: Onboarding**
- Voice recording (optional - can skip)
- Photo library permission request
- Keyboard setup instructions

**Step 3: Take Screenshot**
- Navigate to "Screenshots" tab
- Tap "Take Screenshot"
- Select a dating profile screenshot
- Or use camera to capture screenshot

**Step 4: View Suggestions**
- Wait for AI analysis (15-30 seconds)
- 3 suggestions appear with:
  - Suggestion text
  - Confidence score
  - Reasoning/explanation
  - Next steps advice
- Tap refresh for new suggestions

**Step 5: Enable Keyboard**
- Settings → General → Keyboard → Keyboards
- Add New Keyboard → Vibe8
- Allow Full Access: **NO** (not required)

**Step 6: Use Keyboard**
- Open any app (Notes, Messages, etc.)
- Switch to Vibe8 keyboard (globe icon)
- 3 suggestions appear at top
- Tap suggestion to insert text
- Tap refresh for new suggestions
- Switch back to system keyboard with globe icon

**Step 7: Personalization**
- Tap "Settings" tab
- Configure tone preference
- Set dating goal
- Set experience level
- Changes saved to App Groups for keyboard

**Step 8: Progress Tracking**
- View "Progress" tab
- See current level and progress
- View unlocked/locked achievements
- Check stats (messages, profiles, streak)

**Step 9: Account Deletion (Optional)**
- Settings → Account → Delete Account
- Confirm deletion
- All data deleted within 7 days

---

## Technical Details

### App Architecture
- **Main App:** SwiftUI (iOS 15.0+)
- **Keyboard Extension:** UIKit
- **Share Extension:** For sharing screenshots
- **Backend:** Node.js/Express (Render.com)
- **Database:** PostgreSQL
- **Caching:** Redis (optional)

### Memory & Performance
- **Main App:** < 100MB typical usage
- **Keyboard:** < 50MB (required limit)
- **Battery Impact:** Low (background processing minimal)
- **Network:** Efficient (only when generating suggestions)

### Permissions Required
1. **Photo Library:** Select screenshots to analyze
2. **Microphone:** (Optional) Record voice sample for cloning
3. **Keyboard:** Install custom keyboard extension

### Permissions NOT Required
- Full Access keyboard permission (NOT requested)
- Location
- Contacts
- Camera (except for screenshots)
- Push Notifications

### iOS Version Support
- **Minimum:** iOS 15.0
- **Tested On:** iOS 15.0, 16.0, 17.0, 18.0
- **Optimized For:** iOS 18.0 (iOS 26 Liquid Glass design)

---

## App Store Compliance

### Guideline 1.1 - Safety
- ✅ Age restriction enforced (18+)
- ✅ Content moderation active
- ✅ No user-generated content shared publicly
- ✅ Privacy policy accessible

### Guideline 2.1 - App Completeness
- ✅ All features fully functional
- ✅ No placeholder content
- ✅ No crashes or major bugs
- ✅ Tested on multiple devices and iOS versions

### Guideline 2.3 - Accurate Metadata
- ✅ App name matches functionality
- ✅ Screenshots show actual app features
- ✅ Description accurately describes app
- ✅ No misleading claims

### Guideline 3.1.1 - In-App Purchase
- ✅ No in-app purchases (free app)
- ✅ No subscription required
- ✅ All features available to all users

### Guideline 4.0 - Design
- ✅ Modern iOS design (iOS 26 Liquid Glass)
- ✅ Consistent UI throughout
- ✅ Accessibility support
- ✅ Dark mode support

### Guideline 5.1 - Privacy
- ✅ Privacy policy accessible
- ✅ Data collection disclosed
- ✅ User consent obtained
- ✅ Account deletion available
- ✅ GDPR & CCPA compliant

---

## Support & Contact

**Support Email:** support@vibe8.ai
**Website:** https://vibe8.ai
**Privacy Policy:** https://[YOUR_DOMAIN]/api/v1/legal/privacy-policy
**Terms of Service:** https://[YOUR_DOMAIN]/api/v1/legal/terms

**App Review Questions:** reviewsupport@vibe8.ai

---

## Additional Notes

### Why Custom Keyboard Without Full Access?
- Keyboard extension uses App Groups for communication
- No need for Full Access (which would require extensive privacy review)
- More privacy-friendly approach
- Meets all App Store guidelines for keyboard extensions

### Why Multiple AI Services?
- **Redundancy:** Fallback if one service is unavailable
- **Quality:** Different models excel at different tasks
- **Compliance:** All services meet privacy requirements

### Production Backend
- **URL:** https://vibe8-api-production.onrender.com
- **Health Check:** https://vibe8-api-production.onrender.com/health
- **Status:** Production-ready

### Development Team
- **Team:** Solo developer with AI assistance
- **Location:** [YOUR LOCATION]
- **Apple Developer Program ID:** 9L8889KAL6

---

## Changes Since Last Submission

**Version 1.0.0 (Build 1) - Initial Submission**

This is the initial submission for Vibe8.AI.

---

**App Review Team: Thank you for reviewing Vibe8.AI!**

If you have any questions or need clarification on any feature, please contact reviewsupport@vibe8.ai. We are committed to providing a safe, privacy-focused dating assistance app that complies with all App Store guidelines.
