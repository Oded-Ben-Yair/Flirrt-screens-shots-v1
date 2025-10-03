# Flirrt.ai Optimization Roadmap

**Last Updated**: 2025-10-03
**Current Path**: A (iOS Keyboard Integration)
**Backend Baseline**: v1 (60% accuracy)

---

## Current Implementation Status

### ✅ Path A: iOS Keyboard Integration (COMPLETED)

**Status**: Implemented and ready for testing
**Commit**: `feat: iOS keyboard intelligence integration (Path A)`
**Tag**: `backend-intelligence-v1` (backend baseline)

**What Was Built**:
1. Intelligent backend prompt with multilingual support (Hebrew + English)
2. Profile completeness detection (1-10 scoring)
3. Chat vs profile detection
4. "Needs more scrolling" logic
5. iOS keyboard updated to handle new response format
6. Automated test suite (`Backend/test-vision-api.js`)

**Test Results** (5 real screenshots):
- Chat Detection: 1/1 (100%)
- Hebrew Extraction: 1/1 (100%)
- Profile Scoring: 3/5 (60%)
- Avg Response Time: 7.29s

**Known Limitation**:
- 40% of responses have inconsistent metadata (missing `reasoning`, `references`)
- Suggestions still work, backend provides defaults

---

## Optimization Paths

### 🔄 Path B: Improve Grok Consistency (40% Format Inconsistency)

**Problem**: Grok occasionally returns old format without new metadata fields

**Goal**: Increase from 60% → 85%+ consistent responses

**Approaches to Test**:

#### B1. Stronger System Constraints
```javascript
// In Backend/routes/flirts.js, update system message:
{
  "role": "system",
  "content": `You are a JSON API. You MUST ALWAYS return valid JSON with ALL required fields.

  VALIDATION CHECKLIST (check before responding):
  ☐ screenshot_type set to "profile" or "chat"
  ☐ needs_more_scrolling is true or false
  ☐ profile_score is number 1-10
  ☐ All suggestions have: text, confidence, reasoning, references

  If you cannot include all fields, respond with an error instead.`
}
```

#### B2. Two-Shot Example Correction
Add negative example showing what NOT to do:

```javascript
// After successful example, add:
ANTI-EXAMPLE (NEVER DO THIS):
{
  "suggestions": [{"text": "Hey there!"}]  // ❌ WRONG - missing fields
}

CORRECT VERSION:
{
  "screenshot_type": "profile",
  "profile_score": 8,
  "needs_more_scrolling": false,
  "suggestions": [{
    "text": "Hey there!",
    "confidence": 0.85,
    "reasoning": "...",
    "references": ["..."]
  }]
}
```

#### B3. Output Format Validation Prompt
```javascript
// Add at end of user message:
text: `...

BEFORE RESPONDING:
1. Generate your analysis
2. Validate it has ALL required fields
3. If any field is missing, ADD IT NOW
4. Then respond

Required fields: screenshot_type, profile_score, needs_more_scrolling, extracted_details, suggestions (with reasoning + references)`
```

#### B4. Temperature Adjustment
```javascript
// Current: temperature: 0.9
// Test: temperature: 0.7  (less creative, more consistent)
```

**How to Test Path B**:
```bash
cd /Users/macbookairm1/Flirrt-screens-shots-v1/FlirrtAI/Backend

# 1. Create experimental branch
git checkout -b optimize/grok-consistency

# 2. Modify routes/flirts.js (try B1, B2, B3, or B4)

# 3. Run test suite
node test-vision-api.js

# 4. Compare results to baseline
# Goal: Increase from 60% to 85%+

# 5. If successful, merge to main branch
git checkout fix/real-mvp-implementation
git merge optimize/grok-consistency

# 6. If unsuccessful, rollback
git checkout fix/real-mvp-implementation
git branch -D optimize/grok-consistency
```

**Rollback Command**:
```bash
git reset --hard backend-intelligence-v1
```

---

### 🐛 Path C: Debug API Response Handling

**Problem**: Understanding why 40% of responses lack metadata

**Goal**: Determine if issue is prompt, model, or parsing

**Debug Steps**:

#### C1. Raw Response Logging
```javascript
// In Backend/routes/flirts.js, after line 331 (Grok API response):
console.log('=== RAW GROK RESPONSE ===');
console.log(JSON.stringify(grokResponse.data, null, 2));
console.log('=========================');
```

Run tests and examine logs to see exact Grok output.

#### C2. Retry Logic with Schema Validation
```javascript
// Add schema validation function
function validateGrokResponse(data) {
  const required = ['screenshot_type', 'profile_score', 'needs_more_scrolling'];
  const missing = required.filter(field => data[field] === undefined);

  if (missing.length > 0) {
    console.warn(`Missing fields: ${missing.join(', ')}`);
    return false;
  }

  if (data.suggestions) {
    for (const s of data.suggestions) {
      if (!s.reasoning || !s.references) {
        console.warn('Suggestion missing reasoning/references');
        return false;
      }
    }
  }

  return true;
}

// In API call section, add retry:
let grokResponse;
let attempt = 0;
const maxAttempts = 2;

while (attempt < maxAttempts) {
  grokResponse = await axios.post(GROK_API_URL, requestBody, { headers });
  const suggestions = grokResponse.data.choices[0].message.content;
  const parsed = typeof suggestions === 'string' ? JSON.parse(suggestions) : suggestions;

  if (validateGrokResponse(parsed)) {
    break; // Success
  }

  attempt++;
  console.log(`Attempt ${attempt} failed validation, retrying...`);
}
```

#### C3. Model Comparison Test
Test with `grok-3` instead of `grok-2-vision-1212`:

```javascript
// In routes/flirts.js line 316:
model: 'grok-3'  // Instead of 'grok-2-vision-1212'
```

Note: `grok-3` may not have vision capabilities. This tests if vision models are less consistent.

**How to Test Path C**:
```bash
cd /Users/macbookairm1/Flirrt-screens-shots-v1/FlirrtAI/Backend

# 1. Create debug branch
git checkout -b debug/api-responses

# 2. Add logging (C1) or retry logic (C2) or model swap (C3)

# 3. Run tests with output capture
node test-vision-api.js 2>&1 | tee debug-output.log

# 4. Analyze logs for patterns
cat debug-output.log | grep -A 10 "RAW GROK RESPONSE"

# 5. Document findings in TEST_EVIDENCE.md

# 6. Rollback
git checkout fix/real-mvp-implementation
git branch -D debug/api-responses
```

**Rollback Command**:
```bash
git reset --hard backend-intelligence-v1
```

---

## Automated Rollback Procedures

### Quick Rollback to Baseline

**Scenario**: Path B or C breaks functionality

**Command**:
```bash
cd /Users/macbookairm1/Flirrt-screens-shots-v1/FlirrtAI

# Option 1: Git tag rollback
git reset --hard backend-intelligence-v1
git status  # Verify clean state

# Option 2: Branch rollback
git checkout fix/real-mvp-implementation
git reset --hard HEAD~1  # If you committed broken changes

# Option 3: File-level rollback
git checkout backend-intelligence-v1 -- Backend/routes/flirts.js
```

### Verify Rollback Success
```bash
# 1. Check git status
git log --oneline -5
# Should show: "feat: iOS keyboard intelligence integration"

# 2. Run baseline tests
cd Backend && node test-vision-api.js
# Should show: 60% accuracy baseline

# 3. Check backend server
npm start
curl http://localhost:3000/health
# Should return: {"success": true, "status": "healthy"}
```

### Safety Backup Before Optimization
```bash
# Create backup branch before trying B or C
git checkout -b backup/before-optimization-$(date +%Y%m%d-%H%M%S)
git checkout fix/real-mvp-implementation
```

---

## Success Criteria

### Path B Success (Grok Consistency)
- ✅ Test suite shows 85%+ metadata consistency
- ✅ Hebrew extraction maintains 100%
- ✅ Chat detection maintains 100%
- ✅ Response time remains <10s
- ✅ No regression in suggestion quality

### Path C Success (API Debugging)
- ✅ Identified root cause of 40% inconsistency
- ✅ Documented Grok model behavior patterns
- ✅ Created mitigation strategy
- ✅ Updated TEST_EVIDENCE.md with findings

---

## Testing Checklist

### Before Optimization
- [ ] Backend server running (`npm start`)
- [ ] Baseline test passes (`node test-vision-api.js`)
- [ ] Git working tree clean (`git status`)
- [ ] Backup branch created

### After Optimization
- [ ] All tests run (`node test-vision-api.js`)
- [ ] Compare to baseline (60% → target)
- [ ] Manual test with new screenshot
- [ ] iOS keyboard still works
- [ ] Update TEST_EVIDENCE.md
- [ ] Commit with clear description

---

## Next Steps (Priority Order)

### 1. Path A: Real iPhone Testing (IMMEDIATE)
**Status**: Code complete, needs device testing
**Blocker**: Simulator screenshots don't save to Photos app

**Steps**:
1. Connect real iPhone via USB
2. Open Xcode → Product → Destination → Your iPhone
3. Build and run Flirrt app
4. Grant Photos permissions
5. Open Messages → Flirrt keyboard
6. Go to Safari → Open dating profile
7. Take screenshot
8. Return to Messages → Observe keyboard

**Expected Behavior**:
- Keyboard detects screenshot within 10s
- Shows "Analyzing screenshot..."
- Returns suggestions OR "needs more scrolling" message

### 2. Path B: Grok Consistency Improvement (NEXT)
**Priority**: Medium
**Impact**: High (40% inconsistency → 85%+ consistency)
**Risk**: Low (easy rollback)

**Recommended**: Try B3 (output validation prompt) first

### 3. Path C: API Response Debugging (OPTIONAL)
**Priority**: Low
**Impact**: Medium (understanding only)
**Risk**: None (logging only)

**Recommended**: Run C1 (raw response logging) in parallel with Path A testing

---

## File Reference

### Key Files for Optimization

**Backend Intelligence**:
- `Backend/routes/flirts.js` (lines 180-325) - Intelligent prompt
- `Backend/test-vision-api.js` (232 lines) - Automated test suite
- `Backend/test-images/` (5 files) - Real screenshot test data

**iOS Keyboard**:
- `iOS/FlirrtKeyboard/KeyboardViewController.swift` (519 lines)
  - Line 476-482: FlirtSuggestion struct
  - Line 336-418: parseAPIResponse (intelligent format)
  - Line 485-505: showNeedsMoreInfo UI state

**Documentation**:
- `TEST_EVIDENCE.md` (lines 356-426) - Iteration 3 results
- `docs/OPTIMIZATION_ROADMAP.md` (this file)

---

## Git Tags and Branches

### Important Tags
- `backend-intelligence-v1` - 60% baseline (safe rollback point)

### Branch Structure
```
fix/real-mvp-implementation (MAIN BRANCH)
├── backend-intelligence-v1 (tag)
├── optimize/grok-consistency (for Path B)
└── debug/api-responses (for Path C)
```

---

## Contact and Support

**AI Model**: grok-2-vision-1212
**Context Window**: 32,768 tokens
**Image Tile Size**: 448x448
**API Endpoint**: https://api.x.ai/v1/chat/completions

**X.AI Documentation**: https://docs.x.ai/

---

*Last Updated: 2025-10-03 16:50 UTC*
*Current Status: Path A complete, awaiting iPhone testing*
*Baseline: 60% accuracy, 7.29s avg response time*
