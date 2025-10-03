# Edge Case Test Scenarios - Comprehensive Validation

**Purpose**: Stress-test intelligent profile analysis with real-world challenging scenarios
**Target Accuracy**: 100% field consistency maintained across all edge cases

---

## Scenario Categories

### 1. **Minimal Profiles** (Information Scarcity)

#### 1.1 Empty Profile
**Description**: Single photo, no bio, no interests, no prompts
**Expected Behavior**:
- `screenshot_type`: "profile"
- `profile_score`: 1-2/10
- `needs_more_scrolling`: true
- `message_to_user`: "This profile is very minimal. Please scroll to see if there's more content..."

**Test Criteria**:
- Must not hallucinate bio content
- Should extract visual elements from photo (clothing, setting, etc.)
- Should request more information

#### 1.2 Emoji-Only Bio
**Description**: Bio contains only emojis (e.g., "🔥💪🎸🌊☕")
**Expected Behavior**:
- `profile_score`: 3-4/10
- Extract interests from emoji context (fire=hot, bicep=fitness, guitar=music, wave=beach, coffee=cafe culture)
- Generate suggestions referencing emoji themes
- `reasoning` should mention "emoji-based profile"

**Test Criteria**:
- Must interpret emojis meaningfully
- Should still ask for more text content
- Suggestions should be playful about minimal text

#### 1.3 Ultra-Short Bio
**Description**: Single word or very short phrase (e.g., "hey 🙃", "idk lol", "ask me")
**Expected Behavior**:
- `profile_score`: 2-3/10
- Extract personality hint (casual, playful) from tone
- `needs_more_scrolling`: true
- Suggestions should acknowledge minimal effort

**Test Criteria**:
- Must not over-interpret limited text
- Should politely request more content
- Tone detection from minimalism

---

### 2. **Multilingual Profiles** (Language Complexity)

#### 2.1 Mixed Languages (English + Hebrew)
**Description**: Bio switches between English and Hebrew mid-sentence
**Expected Behavior**:
- Extract both languages correctly
- `extracted_details.bio_text` contains full mixed-language text
- Suggestions can reference both language elements
- `profile_score`: Based on content richness, not language

**Test Criteria**:
- Hebrew diacritics preserved
- Right-to-left text handled correctly
- Context understood across language switches

#### 2.2 Spanish/Portuguese Profile
**Description**: Entire bio in Spanish or Portuguese
**Expected Behavior**:
- Extract Spanish/Portuguese text correctly
- Translate key interests to English in `key_hooks`
- Suggestions in English (since our prompts are English)
- `reasoning` may mention Spanish/Portuguese context

**Test Criteria**:
- Accented characters preserved (á, é, í, ó, ú, ñ, ã, õ)
- Cultural references understood
- Humor/tone detected across language barrier

#### 2.3 Emoji + Hebrew + English Mix
**Description**: "I love ☕ and קפה and coffee shops"
**Expected Behavior**:
- Understand all three mean "coffee"
- Extract interest as "coffee culture"
- Not duplicate interests
- Acknowledge multilingual playfulness

---

### 3. **Visual Challenges** (Image Quality)

#### 3.1 Low Quality Screenshot
**Description**: Blurry, pixelated, or dark image
**Expected Behavior**:
- `extracted_details.visual_elements`: May include "low image quality"
- Still attempt OCR on visible text
- `profile_score`: Penalized if bio unreadable
- May request clearer screenshot

**Test Criteria**:
- Graceful degradation
- Honest about readability issues
- No hallucinated text

#### 3.2 Cropped Profile
**Description**: Screenshot cuts off top/bottom/sides of profile
**Expected Behavior**:
- Extract visible content only
- `needs_more_scrolling`: true if incomplete
- `message_to_user`: "Profile appears cut off, please share full screenshot"
- `visual_elements` may note "partially visible"

**Test Criteria**:
- Detect incomplete UI elements
- Request full profile view
- Work with available information

#### 3.3 Multiple Profiles in Screenshot
**Description**: User accidentally screenshotted swipe queue (multiple cards visible)
**Expected Behavior**:
- `screenshot_type`: "profile"
- Focus on primary/largest profile visible
- `message_to_user`: May note multiple profiles, suggest one at a time
- Extract from most prominent card

---

### 4. **Dating App UI Variations**

#### 4.1 Bumble Layout
**Characteristics**: Yellow theme, prompts format, "Women make the first move"
**Expected Behavior**:
- Detect prompts as primary content source
- Extract prompt questions + answers separately
- `visual_elements`: May note Bumble UI
- Suggestions use prompt content

#### 4.2 Hinge Layout
**Characteristics**: Vertical scroll, photo captions, voice prompts, dating preferences
**Expected Behavior**:
- Extract photo captions as bio-like content
- Parse prompts: "My most irrational fear", "I'm weirdly attracted to", etc.
- `interests`: Include prompt themes
- Suggestions reference specific prompts

#### 4.3 Tinder Classic
**Characteristics**: Minimalist, stacked photos, short bio, Spotify/Instagram badges
**Expected Behavior**:
- Extract bio from centered text area
- Note Spotify artists if visible
- Instagram username if shown
- `profile_score`: Often lower (less content than Bumble/Hinge)

#### 4.4 Coffee Meets Bagel
**Characteristics**: Icebreaker questions, detailed preferences, "beans" gamification
**Expected Behavior**:
- Parse icebreaker Q&A format
- Extract from preference sections
- Handle structured data (height, religion, etc.)

---

### 5. **Content Edge Cases**

#### 5.1 Profile with Video Thumbnail
**Description**: Profile includes video with play button overlayExpected Behavior**:
- `visual_elements`: Include "video thumbnail"
- Extract any visible text from video preview
- `message_to_user`: May note videos can't be analyzed, ask for bio screenshot
- Still generate suggestions from static content

#### 5.2 Instagram/Snapchat Links
**Description**: Bio contains social media handles: "@username" or "snap: xxx"
**Expected Behavior**:
- Extract social handles as `visual_elements` or separate field
- `interests`: May infer "active on social media"
- Suggestions can reference social presence
- `reasoning`: "Profile includes Instagram, suggests outgoing personality"

#### 5.3 Lengthy Bio (Paragraph)
**Description**: 3-5 sentence bio with multiple topics
**Expected Behavior**:
- `profile_score`: 9-10/10
- Extract multiple interests/hooks
- `key_hooks`: 5-8 specific topics
- Suggestions diverse, each references different hook
- `confidence`: Higher due to rich content

#### 5.4 Prompt-Only Profile (No Traditional Bio)
**Description**: Dating apps like Hinge/Bumble with only prompt answers
**Expected Behavior**:
- `extracted_details.bio_text`: Combine prompt answers
- `interests`: Infer from prompt content
- `profile_score`: 6-8/10 (structured content is good)
- Suggestions reference specific prompts by name

---

### 6. **Personality/Tone Detection**

#### 6.1 Sarcastic/Ironic Bio
**Description**: "Definitely not here to find love 🙄 Just collecting matches like Pokémon"
**Expected Behavior**:
- Detect sarcasm/irony in tone
- `key_hooks`: Include "sarcastic humor", "self-aware"
- Suggestions match sarcastic energy
- `reasoning`: "Matches their ironic tone"

#### 6.2 Serious/Wholesome Bio
**Description**: "Family-oriented, love hiking and volunteering. Looking for genuine connection."
**Expected Behavior**:
- Detect sincere, wholesome tone
- `key_hooks`: "family values", "outdoors", "volunteer work", "genuine"
- Suggestions respectful, not overly playful
- `confidence`: Higher for serious tone

#### 6.3 Flirty/Confident Bio
**Description**: "Can't promise I won't steal your hoodie 😏 Wine bar enthusiast and terrible dancer"
**Expected Behavior**:
- Detect confident, flirty tone
- `key_hooks`: "playful flirting", "wine culture", "self-deprecating humor"
- Suggestions match flirty energy
- `reasoning`: "Reciprocates their confident vibe"

---

### 7. **Error/Invalid Cases**

#### 7.1 Chat Conversation (Instagram DM)
**Already Tested**: ✅ 100% accuracy
**Expected**: `screenshot_type: "chat"`, ask for profile

#### 7.2 Settings Screen
**Description**: User screenshotted dating app settings, not profile
**Expected Behavior**:
- `screenshot_type`: "other" or "settings"
- `needs_more_scrolling`: true
- `profile_score`: 0/10
- `message_to_user`: "This appears to be a settings screen. Please screenshot a dating profile."

#### 7.3 App Store Listing
**Description**: Screenshot of dating app in App Store
**Expected Behavior**:
- `screenshot_type`: "other" or "app_store"
- `message_to_user`: "This is an app listing, not a profile. Please open the dating app and screenshot a profile."

#### 7.4 Web Browser (Dating Site)
**Description**: Desktop browser showing dating website
**Expected Behavior**:
- Still extract profile content if visible
- `visual_elements`: May note "desktop browser", "web version"
- `profile_score`: Based on content, not platform
- Suggestions still functional

---

### 8. **Privacy/Sensitive Content**

#### 8.1 Profile with Face Blurred/Hidden
**Description**: User blurs own face in main photos
**Expected Behavior**:
- Extract bio/prompts normally
- `visual_elements`: Note "face obscured" or focus on visible elements (clothing, background)
- `profile_score`: Not penalized for privacy choice
- Suggestions focus on bio, not appearance

#### 8.2 Profile with Location/Work Info
**Description**: Bio includes specific workplace, school, or exact address
**Expected Behavior**:
- Extract content normally
- `interests`: Infer from job/school type
- Suggestions reference field/institution generally, not specific details
- No privacy warnings (that's user's choice to share)

#### 8.3 Profile with Contact Info
**Description**: Bio includes phone, email, WhatsApp number
**Expected Behavior**:
- Extract as part of bio text
- `key_hooks`: May note "eager to connect off-app"
- Suggestions acknowledge openness
- No filtering (user chose to share)

---

## Testing Protocol

### For Each Edge Case:

1. **Create/Find Real Screenshot**
   - Actual dating app profiles (anonymize names)
   - Or mock realistic screenshots

2. **Send to API**
   ```bash
   curl -X POST 'http://localhost:3000/api/v1/flirts/generate_flirts' \
     -H 'Content-Type: application/json' \
     -d '{
       "image_data": "<base64_encoded_screenshot>",
       "suggestion_type": "opener",
       "tone": "playful"
     }'
   ```

3. **Validate Response**
   - ✅ All 5 required fields present
   - ✅ `reasoning` and `references` in every suggestion
   - ✅ Appropriate `profile_score`
   - ✅ Logical `needs_more_scrolling` decision
   - ✅ Suggestions are contextual and personalized

4. **Record Results**
   - Screenshot filename
   - Response time
   - Field completeness (✓ or ✗)
   - Suggestion quality (1-5 stars)
   - Notes on behavior

---

## Success Criteria

**Target**: 90%+ edge cases handled correctly

**"Handled Correctly" Means**:
- All required fields present (100%)
- `screenshot_type` accurate (profile/chat/other)
- `profile_score` reasonable (±2 points subjective)
- `needs_more_scrolling` logical
- Suggestions relevant to extracted content
- No hallucinated information
- Graceful degradation on poor quality

**Acceptable Failures**:
- Emoji misinterpretation (fire emoji = angry instead of hot)
- OCR errors on very low quality images
- Cultural references missed in non-English text
- Tone misread (sarcasm detected as serious, or vice versa)

**Unacceptable Failures**:
- Missing required fields
- Hallucinated bio content
- Chat detected as profile
- Complete failure to extract visible text
- Suggestions unrelated to profile content

---

## Priority Edge Cases (Test First)

1. **Emoji-Only Bio** (Common on Tinder)
2. **Prompt-Only Profile** (Bumble/Hinge standard)
3. **Mixed Language** (Common in multicultural areas)
4. **Low Quality Screenshot** (Real-world user behavior)
5. **Cropped Profile** (User error)
6. **Sarcastic Bio** (Tone detection challenge)
7. **Video Thumbnail** (Media limitation)
8. **Settings Screen** (User error detection)

---

*Last Updated: October 3, 2025*
*Status: Ready for edge case validation testing*
*Current Baseline: 100% consistency on standard cases*
