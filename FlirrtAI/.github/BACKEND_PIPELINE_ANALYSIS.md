# Backend AI Pipeline Analysis - Trained vs Untrained
**Date**: November 1, 2025
**Purpose**: Identify correct trained AI pipeline for screenshot analysis + flirt generation

---

## Current Backend Routes

### 1. `/api/v1/flirts/generate_flirts` (Currently Used by iOS Keyboard)
**File**: `Backend/routes/flirts.js`

**Pipeline**: Grok-2-vision-1212 (x.ai) - SINGLE MODEL
- Grok-2-vision does BOTH:
  1. Screenshot analysis
  2. Flirt generation

**Status**: ⚠️ **PARTIALLY TRAINED**
- Uses Grok-2-vision which is functional
- BUT: Single-model approach, not the dual-model trained pipeline

**iOS Keyboard Configuration**:
```swift
// iOS/FlirrtKeyboard/KeyboardViewController.swift:340
let apiURL = "\(AppConstants.apiBaseURL)/flirts/generate_flirts"
```

---

### 2. `/api/v2/vibe8/analyze-and-generate` (Available but Unused)
**File**: `Backend/routes/vibe8-flirts.js`

**Pipeline**: Gemini 2.5 Pro + GPT-5 - DUAL MODEL
- Step 1: `geminiVisionService.analyzeScreenshot()` - Screenshot analysis
- Step 2: `gpt5FlirtService.generateFlirts()` - Flirt generation with coaching tone

**Status**: ❌ **OLD/UNTRAINED** (per user message)
- User said: "gemini is the old one not the trained one"
- Gemini should be replaced with Grok-4

**Server Configuration**:
```javascript
// Backend/server.js:38, 122
app.use('/api/v2/vibe8', vibe8FlirtsRoutes); // Gemini + GPT-5 pipeline
```

---

### 3. Grok-4 Fast Routes (NOT MOUNTED)
**File**: `Backend/routes/grok4Fast.js`

**Pipeline**: Grok-4 Fast (Azure) - SINGLE MODEL
- Uses Azure Grok-4 deployment
- NOT a dual-model pipeline

**Status**: ⚠️ **NOT MOUNTED IN SERVER.JS**
- Route file exists but not imported/mounted
- Would need to be integrated

---

## Service Layer Analysis

### ✅ GPT-5 Flirt Service (TRAINED)
**File**: `Backend/services/gpt5FlirtService.js`

**Capabilities**:
- Azure OpenAI GPT-5 (Standard deployment)
- Coaching tone implementation
- Quality evaluation framework
- Takes `screenshotAnalysis` as input parameter

**Key Features**:
```javascript
// Line 107-108: Expects screenshot analysis as input
async generateFlirts(params) {
    const {
        screenshotAnalysis,  // ← From analysis step
        tone = 'playful',
        suggestionType = 'opener',
        ...
    } = params;
```

**Configuration**:
```javascript
// Line 22-26
this.endpoint = 'https://brn-azai.cognitiveservices.azure.com/openai/deployments/gpt-5/chat/completions'
this.apiKey = process.env.GPT5_KEY || process.env.AZURE_OPENAI_KEY
this.modelVersion = '2025-08-07'
```

**Status**: ✅ **PRODUCTION READY - THIS IS THE TRAINED FLIRT GENERATOR**

---

### ⚠️ Grok-4 Fast Service (Needs Integration)
**File**: `Backend/services/grok4FastService.js`

**Capabilities**:
- Grok-4 Fast reasoning model (for analysis)
- Grok-4 Fast non-reasoning model (for quick tasks)
- Intelligent model selection
- Streaming support

**Models**:
```javascript
// Line 24-41
reasoning: {
    name: 'grok-4-fast-reasoning',
    contextWindow: 2000000, // 2M tokens
    timeout: 8000,
    features: ['reasoning', 'analysis', 'complex_logic']
},
nonReasoning: {
    name: 'grok-4-fast-non-reasoning',
    contextWindow: 2000000,
    timeout: 3000,
    features: ['generation', 'creative_writing', 'quick_responses']
}
```

**Status**: ⚠️ **EXISTS BUT NOT INTEGRATED WITH GPT-5 PIPELINE**

---

### ❌ Gemini Vision Service (OLD/UNTRAINED)
**File**: `Backend/services/geminiVisionService.js` (assumed to exist)

**Status**: ❌ **DEPRECATED - User confirmed this is the old untrained version**

---

## CORRECT TRAINED PIPELINE (User Requirement)

### User's Message: "grok 4 and gpt, not gemini, gemini is the old one not the trained one"

**Required Architecture**:
```
iOS Keyboard Screenshot
    ↓
1. Grok-4 Fast (Azure) → Screenshot Analysis
    ↓
2. GPT-5 (Azure) → Flirt Generation (Coaching Tone)
    ↓
iOS Keyboard Display
```

---

## Issues Identified

### ❌ Issue #1: Keyboard Calls Wrong Route
**Current**: iOS keyboard calls `/api/v1/flirts/generate_flirts` (Grok-2-vision single model)
**Should Be**: Grok-4 + GPT-5 dual-model pipeline

### ❌ Issue #2: No Grok-4 + GPT-5 Route Exists
**Problem**:
- `/api/v2/vibe8` uses Gemini + GPT-5 (Gemini is old/untrained)
- Grok-4 Fast service exists but not integrated with GPT-5
- No route combines Grok-4 (analysis) + GPT-5 (generation)

### ❌ Issue #3: Server.js Doesn't Mount Grok-4 Routes
**Current server.js**:
```javascript
// Line 36-38
const flirtRoutes = require('./routes/flirts');  // Grok-2-vision
const vibe8FlirtsRoutes = require('./routes/vibe8-flirts'); // Gemini + GPT-5

// NOT IMPORTED:
// const grok4FastRoutes = require('./routes/grok4Fast');
```

---

## SOLUTION: Create Grok-4 + GPT-5 Pipeline

### Option 1: Modify vibe8-flirts.js
**Replace**: `geminiVisionService` with `grok4FastService`

**Changes Required**:
1. Update `Backend/routes/vibe8-flirts.js`:
   - Line 48-56: Replace Gemini with Grok-4
   - Keep GPT-5 generation intact (already trained)

2. Update `Backend/server.js`:
   - Comment clarifies it's Grok-4 + GPT-5 (not Gemini)

3. Update iOS keyboard:
   - Change endpoint from `/api/v1/flirts/generate_flirts` → `/api/v2/vibe8/analyze-and-generate`

**Pros**:
- Minimal code changes
- Reuses existing route structure
- GPT-5 integration already working

**Cons**:
- Repurposes "vibe8" route (naming confusion)

---

### Option 2: Create New Route `/api/v2/trained/analyze-and-generate`
**Create**: New route file `Backend/routes/trained-flirts.js`

**Pipeline**:
1. Grok-4 Fast (screenshot analysis)
2. GPT-5 (flirt generation with coaching tone)

**Changes Required**:
1. Create `Backend/routes/trained-flirts.js`
2. Mount in `Backend/server.js`
3. Update iOS keyboard endpoint
4. Mark old routes as deprecated

**Pros**:
- Clean separation (trained vs untrained)
- Clear naming convention
- No confusion with old pipelines

**Cons**:
- More code to write
- Need to test new route

---

## RECOMMENDED SOLUTION: Option 2

### Create `/api/v2/trained/analyze-and-generate` Route

**Implementation Plan**:
1. ✅ Create `Backend/routes/trained-flirts.js`:
   - Import `grok4FastService` (analysis)
   - Import `gpt5FlirtService` (generation)
   - Implement dual-model pipeline

2. ✅ Mount route in `Backend/server.js`:
   ```javascript
   const trainedFlirtsRoutes = require('./routes/trained-flirts');
   app.use('/api/v2/trained', trainedFlirtsRoutes);
   ```

3. ✅ Update iOS keyboard endpoint:
   ```swift
   // iOS/FlirrtKeyboard/KeyboardViewController.swift
   let apiURL = "\(AppConstants.apiBaseURL)/api/v2/trained/analyze-and-generate"
   ```

4. ✅ Update iOS APIClient:
   ```swift
   // iOS/Flirrt/Services/APIClient.swift
   // Add new method for trained pipeline
   ```

5. ✅ Mark old routes as deprecated:
   - Add comments to `flirts.js` and `vibe8-flirts.js`
   - Document migration path

---

## Files to Modify

### Backend:
1. **CREATE**: `Backend/routes/trained-flirts.js` (new Grok-4 + GPT-5 route)
2. **MODIFY**: `Backend/server.js` (mount new route)
3. **MODIFY**: `Backend/routes/flirts.js` (add deprecation comment)
4. **MODIFY**: `Backend/routes/vibe8-flirts.js` (add deprecation comment)

### iOS:
1. **MODIFY**: `iOS/FlirrtKeyboard/KeyboardViewController.swift` (update endpoint)
2. **MODIFY**: `iOS/Flirrt/Services/APIClient.swift` (add trained pipeline method)
3. **MODIFY**: `iOS/Flirrt/Services/AppConstants.swift` (if API base URL needs update)

---

## Environment Variables Verification

### Required for Grok-4 + GPT-5:
```bash
# Grok-4 (Azure)
GROK4_DEPLOYMENT_NAME=grok-4-fast-reasoning
GROK4_ENDPOINT=https://brn-azai.services.ai.azure.com/models/chat/completions
GROK4_KEY=<YOUR_AZURE_AI_KEY_HERE>

# GPT-5 (Azure)
GPT5_ENDPOINT=https://brn-azai.cognitiveservices.azure.com/openai/deployments/gpt-5/chat/completions
GPT5_KEY=<YOUR_AZURE_OPENAI_KEY_HERE>
GPT5_MODEL_VERSION=2025-08-07
```

**Status**: ✅ All keys present in user's CLAUDE.md

---

## Next Steps

1. **Immediate**: Create `trained-flirts.js` route with Grok-4 + GPT-5 pipeline
2. **Testing**: Verify dual-model pipeline works correctly
3. **Integration**: Update iOS keyboard to use new endpoint
4. **Cleanup**: Mark old routes as deprecated
5. **LLM Review**: Consult all LLMs (GPT-5-Codex, Manus, GPT-5-Pro) on architecture
6. **Git Commit**: Clean commit with clear documentation

---

## Summary

**Current State**: ❌ iOS keyboard uses single-model Grok-2-vision pipeline
**Required State**: ✅ Grok-4 (analysis) + GPT-5 (coaching flirts) dual-model pipeline
**Solution**: Create new `/api/v2/trained/analyze-and-generate` route
**Status**: Ready to implement

---

## Questions for LLM Consultation

1. **GPT-5-Codex**: Review dual-model pipeline architecture for technical soundness
2. **Manus**: Analyze complete user flow from screenshot → flirt display
3. **GPT-5-Pro**: Verify GPT-5 coaching tone implementation meets requirements
4. **Sequential Thinking**: Verify edge cases and error handling

After all LLMs agree, proceed to testing → git commit → Mac handoff.
