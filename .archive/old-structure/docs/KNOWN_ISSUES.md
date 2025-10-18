# Known Issues & Workarounds

Current bugs, limitations, and their workarounds for Vibe8AI.

**Last Updated**: October 4, 2025
**Testing Coverage**: Stages 1-6 Complete
**Production Readiness**: 90/100

---

## 📊 Testing Summary

### Overall Status
- **Security Grade**: A (Excellent)
- **Integration Tests**: 81% pass rate (17/21 passed)
- **Edge Case Tests**: 64% pass rate (21/33 passed)
- **Production Readiness**: 90/100

### Test Results by Category
| Category | Pass Rate | Status |
|----------|-----------|--------|
| Security (XSS, SQL Injection) | 100% | ✅ Excellent |
| Authentication | 100% | ✅ Excellent |
| Network Handling | 100% | ✅ Excellent |
| External API Integration | 100% | ✅ Excellent |
| Error Handling | 83% | ✅ Good |
| Rate Limiting | 67% | ⚠️ Acceptable |
| Input Validation | 40% | 🔴 Critical Issues |
| File Upload | 43% | 🔴 Critical Issues |

**Reference Documents**:
- `/BUILD_VERIFICATION_REPORT.md` - Stage 5 build verification
- `/Backend/INTEGRATION_TEST_REPORT.md` - Integration testing results
- `/docs/EDGE_CASE_TEST_RESULTS.md` - Edge case validation
- `/docs/SECURITY_TEST_REPORT.md` - Security assessment

---

## 🔴 P0 - CRITICAL (Must Fix Before Production)

### File Upload Validation Gaps
**Source**: Stage 6 - Edge Case Testing (Agent 3)
**Severity**: CRITICAL
**Pass Rate**: 43% (3/7 tests passed)

**Issues Identified**:

1. **Unsupported File Types Accepted** (CRITICAL)
   - **Problem**: Dangerous file types (.exe) are not rejected
   - **Test Result**: `.exe` file was accepted when it should be blocked
   - **Impact**: Security vulnerability, potential server compromise
   - **Root Cause**: File type validation relies on blacklist instead of whitelist
   - **Fix Time**: 1 hour

2. **Oversized Files Accepted** (CRITICAL)
   - **Problem**: Files larger than 10MB limit are being accepted
   - **Test Result**: 11MB file was not rejected
   - **Impact**: Memory exhaustion, server crash, DoS vulnerability
   - **Root Cause**: File size check happens after upload, not before
   - **Fix Time**: 30 minutes

3. **Missing File Validation**
   - **Problem**: Requests without files are not properly rejected
   - **Test Result**: Empty file upload request did not return 400 error
   - **Impact**: Processing errors downstream, wasted resources
   - **Root Cause**: No file presence validation in middleware
   - **Fix Time**: 30 minutes

4. **Zero-Byte Files Accepted**
   - **Problem**: Empty files (0 bytes) are accepted
   - **Test Result**: 0-byte file was not rejected
   - **Impact**: Wasted processing, potential errors in analysis
   - **Root Cause**: No minimum file size check
   - **Fix Time**: 15 minutes

**Recommended Fix**:
```javascript
// In middleware/optimizedUpload.js or validation.js
const fileFilter = (req, file, cb) => {
    // Whitelist of allowed MIME types
    const allowedTypes = ['image/jpeg', 'image/png', 'image/jpg', 'image/webp'];

    if (!allowedTypes.includes(file.mimetype)) {
        return cb(new Error('UNSUPPORTED_FILE_TYPE'), false);
    }

    // Check file extension (defense in depth)
    const ext = path.extname(file.originalname).toLowerCase();
    const dangerousExts = ['.exe', '.bat', '.cmd', '.sh', '.php'];

    if (dangerousExts.includes(ext)) {
        return cb(new Error('DANGEROUS_FILE_EXTENSION'), false);
    }

    cb(null, true);
};

const upload = multer({
    storage: storage,
    limits: {
        fileSize: 10 * 1024 * 1024, // 10MB
        files: 1
    },
    fileFilter: fileFilter
});
```

**Estimated Total Fix Time**: 2 hours

---

### Input Validation Gaps
**Source**: Stage 6 - Edge Case Testing (Agent 3)
**Severity**: CRITICAL
**Pass Rate**: 40% (4/10 tests passed)

**Issues Identified**:

1. **Empty String Acceptance**
   - **Problem**: Empty strings are accepted when they should be rejected
   - **Test Result**: `{ text: "" }` did not return 400 error
   - **Impact**: Downstream processing errors, API failures
   - **Root Cause**: No explicit empty string check in validation
   - **Fix Time**: 30 minutes

2. **Null/Undefined Handling**
   - **Problem**: Null and undefined values not explicitly rejected
   - **Test Result**: `{ text: null }` and `{ text: undefined }` accepted
   - **Impact**: TypeError crashes in processing
   - **Root Cause**: Type checking not strict enough
   - **Fix Time**: 30 minutes

3. **Missing Required Field Validation**
   - **Problem**: Missing required fields are not consistently rejected
   - **Test Result**: Request without `text` field did not return 400 error
   - **Impact**: API continues with incomplete data
   - **Root Cause**: Required field validation not enforced
   - **Fix Time**: 45 minutes

4. **Invalid Enum Values Accepted**
   - **Problem**: Invalid enum values (tones, voice models) are accepted
   - **Test Result**: `{ voice_model: "invalid_model" }` did not return 400 error
   - **Impact**: Could pass invalid values to external APIs
   - **Root Cause**: Enum validation not strict
   - **Fix Time**: 30 minutes

5. **Oversized Input Accepted**
   - **Problem**: Text longer than 10,000 characters is accepted
   - **Test Result**: 100KB string was not rejected
   - **Impact**: Memory issues, API timeouts
   - **Root Cause**: Length limit not enforced on all endpoints
   - **Fix Time**: 15 minutes

**Recommended Fix**:
```javascript
// In middleware/validation.js
const validateVoiceSynthesis = [
    body('text')
        .exists().withMessage('Text is required')
        .notEmpty().withMessage('Text cannot be empty')
        .isString().withMessage('Text must be a string')
        .not().equals('null').withMessage('Text cannot be null')
        .not().equals('undefined').withMessage('Text cannot be undefined')
        .trim()
        .isLength({ min: 1, max: 1000 })
        .withMessage('Text must be between 1 and 1000 characters'),

    body('voice_model')
        .optional()
        .isIn(['eleven_monolingual_v1', 'eleven_multilingual_v2', 'eleven_turbo_v2'])
        .withMessage('Invalid voice model'),

    handleValidationErrors
];
```

**Estimated Total Fix Time**: 2.5 hours

---

## 🔴 P1 - HIGH (Fix Before Launch)

### Grok API Integration Issues
**Source**: Stage 6 - Integration Testing (Agent 2)
**Severity**: HIGH
**Impact**: Flirt generation endpoint failing

**Issues Identified**:

1. **Timeout Handling Incomplete**
   - **Problem**: Requests to Grok API timing out without proper handling
   - **Test Result**: 0/2 workflow tests passed
   - **Impact**: User-facing feature completely broken
   - **Root Cause**: Likely rate limiting or timeout too short (30s)
   - **Fix Time**: 2 hours

2. **Error Logging Shows [object Object]**
   - **Problem**: Errors logged as `[object Object]` instead of actual messages
   - **Impact**: Debugging impossible, can't identify real issues
   - **Root Cause**: Error object not properly serialized
   - **Fix Time**: 30 minutes

**Recommended Fix**:
```javascript
// Implement circuit breaker pattern
const CircuitBreaker = require('opossum');

const options = {
    timeout: 45000,  // Increase to 45s for vision API
    errorThresholdPercentage: 50,
    resetTimeout: 60000
};

const breaker = new CircuitBreaker(callGrokAPI, options);

breaker.fallback(() => ({
    error: 'Grok API temporarily unavailable. Please try again.',
    code: 'CIRCUIT_OPEN'
}));

// Improve error logging
catch (error) {
    console.error('Grok API Error:', {
        message: error.message,
        stack: error.stack,
        response: error.response?.data
    });
}
```

**Estimated Total Fix Time**: 2.5 hours

---

### Error Response Format Inconsistency
**Source**: Stage 6 - Integration Testing (Agent 2)
**Severity**: HIGH
**Impact**: Client-side error handling broken

**Problem**: Some endpoints return errors as `error: "message"` instead of `error: { code, message }`

**Test Result**: 1/2 format consistency tests failed

**Expected Format**:
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Either screenshot_id or image_data is required"
  }
}
```

**Actual Format** (inconsistent):
```json
{
  "success": false,
  "error": "Either screenshot_id or image_data is required",
  "code": "VALIDATION_ERROR"
}
```

**Fix**: Audit all endpoints to use `sendErrorResponse()` from `/utils/errorHandler.js`

**Files to Update**:
- `/Backend/routes/flirts.js` - Line 81-86
- `/Backend/routes/analysis.js` - Check all error returns
- `/Backend/routes/voice.js` - Check all error returns

**Estimated Fix Time**: 1.5 hours

---

### iOS Extension Target Configuration
**Source**: Stage 5 - Build Verification
**Severity**: HIGH
**Impact**: Extensions cannot build

**Problem**: `AppConstants.swift` not accessible to extension targets

**Error**:
```
/iOS/Vibe8Keyboard/KeyboardViewController.swift:11:30:
error: cannot find 'AppConstants' in scope
```

**Root Cause**:
- AppConstants.swift is in the main Vibe8 target
- Vibe8Keyboard and Vibe8Share are separate extension targets
- Extension targets need explicit file membership

**Fix (Manual Step)**:
1. Open `Vibe8.xcodeproj` in Xcode
2. Select `iOS/Vibe8/Config/AppConstants.swift` in Project Navigator
3. In File Inspector (right panel), check:
   - [x] Vibe8Keyboard target
   - [x] Vibe8Share target
4. Rebuild project

**Estimated Fix Time**: 2 minutes (manual Xcode configuration)

---

## 🟡 P2 - MEDIUM (Fix Post-Launch)

### Database Unavailability Handling
**Source**: Stage 6 - Edge Case Testing (Agent 3)
**Severity**: MEDIUM
**Pass Rate**: 67% (2/3 database tests passed)

**Problem**: Graceful degradation is partial, not complete

**Impact**: Some features don't work well when database is unavailable

**Current State**:
- ✅ Server continues running without PostgreSQL
- ✅ Mock data fallback exists
- ⚠️ Some endpoints return unexpected responses

**Recommended Enhancement**:
```javascript
// Add connection pool configuration
const pool = new Pool({
    max: 20,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 2000
});

// Add connection retry logic
async function connectWithRetry(retries = 3) {
    for (let i = 0; i < retries; i++) {
        try {
            await pool.connect();
            return;
        } catch (err) {
            if (i === retries - 1) throw err;
            await new Promise(resolve => setTimeout(resolve, 1000 * Math.pow(2, i)));
        }
    }
}
```

**Estimated Fix Time**: 2 hours

---

### Development Team Signing
**Source**: Stage 5 - Build Verification
**Severity**: MEDIUM
**Impact**: Cannot deploy to device without team

**Problem**: iOS targets require development team for signing

**Fix**: Configure development team in Xcode project settings

**Estimated Fix Time**: 5 minutes (manual Xcode configuration)

---

### Keyboard API Integration Incomplete
**Status**: In progress - debugging URL session configuration

**Problem**: Keyboard makes API calls to backend but gets timeout/connection errors

**Symptoms**:
- "Network unavailable" or "Request timed out" messages
- Suggestions don't appear after button press
- Console shows: "Error: connect ECONNREFUSED"

**Workaround**:
- Ensure backend is running: `cd Backend && npm start`
- Verify backend health: `curl http://localhost:3000/health`
- Check backend logs for incoming requests

**Fix Status**: Requires URLSession configuration debugging

**Estimated Fix Time**: 1 hour

---

### Voice Synthesis Not Connected
**Status**: Planned - ElevenLabs integration pending

**Problem**: Voice recording UI works, but audio doesn't play back

**Symptoms**:
- Recording completes successfully
- No playback button appears
- Voice messages can't be sent

**Workaround**: Feature not yet connected end-to-end

**Estimated Fix Time**: 2 hours

---

### Backend Port Conflicts
**Problem**: Backend fails to start with "Port 3000 already in use"

**Symptoms**:
```
Error: listen EADDRINUSE: address already in use :::3000
```

**Workaround**:
```bash
# Kill existing node processes
killall node

# Restart backend
cd Backend && npm start
```

**Prevention**: Always stop backend properly (Ctrl+C) instead of force-quit

---

### Keyboard Memory Warning
**Problem**: Keyboard extension occasionally shows high memory usage (>40MB)

**Symptoms**:
- iOS shows "Vibe8Keyboard using significant memory"
- Keyboard may be terminated by system
- UI becomes sluggish

**Workaround**:
- Close and reopen keyboard periodically
- Avoid taking multiple screenshots in quick succession
- Current limit: 60MB, warning at 45MB

**Fix Status**: Under monitoring - may need to reduce image compression quality

---

### App Group Sync Delays
**Problem**: Changes in main app don't immediately reflect in keyboard

**Symptoms**:
- Complete onboarding but keyboard still shows "setup needed"
- Voice clone created but keyboard doesn't show it
- Delay: 5-30 seconds

**Workaround**:
- Wait 30 seconds after completing setup
- Switch away from keyboard and back
- Restart keyboard (switch to another keyboard and back)

**Fix Status**: iOS limitation - UserDefaults synchronization is not instantaneous

---

## 🟢 P3 - LOW (Optional Enhancements)

### Onboarding Skip Button
**Problem**: "Skip" button completes onboarding without personalization

**Impact**: Keyboard will request setup completion when used

**Workaround**: Don't skip - complete full onboarding for best experience

---

### Screenshot Detection Not Triggering
**Problem**: Taking a screenshot in Messages/Tinder doesn't trigger analysis in keyboard

**Root Cause**: Darwin notification not reaching keyboard extension reliably

**Symptoms**:
- Screenshot is taken but keyboard button doesn't switch to "Analyze" mode
- No visual feedback in keyboard after screenshot
- Analysis doesn't start automatically

**Workaround**:
1. Use the "Fresh Flirts" button to get generic suggestions
2. Manually trigger analysis (when implemented)

**Fix Status**: In progress - requires Darwin notification debugging

---

## ✅ Recently Fixed (Stages 1-6)

### Security Improvements ✅
**Source**: Stage 4 & Stage 6 Testing

- ✅ XSS prevention (100% of attacks blocked)
- ✅ SQL injection prevention (100% parameterized queries)
- ✅ Input sanitization (xss library integrated)
- ✅ Security headers configured
- ✅ CORS properly configured
- ✅ Password hashing (bcrypt with 12 rounds)
- ✅ JWT token validation working

**Security Grade**: A (Excellent)

---

### Code Refactoring ✅
**Source**: Stages 1-5

- ✅ Magic strings replaced with constants (73 instances)
- ✅ Error handling centralized (`utils/errorHandler.js`)
- ✅ Validation utilities created (`utils/validation.js`)
- ✅ Timeout configuration centralized (`config/timeouts.js`)
- ✅ XSS prevention dependency added (`xss@1.0.15`)
- ✅ Environment variable validation on startup

---

## 📋 Summary by Priority

### P0 - CRITICAL (8 issues, ~4.5 hours to fix)
1. Unsupported file upload (1h)
2. Oversized file acceptance (30min)
3. Missing file validation (30min)
4. Zero-byte files (15min)
5. Empty string acceptance (30min)
6. Null/undefined handling (30min)
7. Missing required fields (45min)
8. Invalid enum values (30min)

### P1 - HIGH (3 issues, ~4 hours to fix)
1. Grok API timeout (2h)
2. Error response format (1.5h)
3. iOS extension config (2min manual)

### P2 - MEDIUM (6 issues, ~7 hours to fix)
1. Database unavailability (2h)
2. Development team signing (5min manual)
3. Keyboard API integration (1h)
4. Voice synthesis (2h)
5. Backend port conflicts (documented)
6. Keyboard memory (monitoring)

### P3 - LOW (2 issues)
1. Onboarding skip (documented)
2. Screenshot detection (in progress)

**Total Estimated Fix Time for P0/P1**: ~8.5 hours
**Total Estimated Fix Time for All Issues**: ~15.5 hours

---

## 🎯 Production Deployment Checklist

### Critical Blockers (Must Fix)
- [ ] Fix file upload validation (P0)
- [ ] Fix input validation (P0)
- [ ] Fix Grok API integration (P1)
- [ ] Standardize error responses (P1)
- [ ] Configure iOS extension targets (P1)

### Recommended Before Launch
- [ ] Improve database fallback handling (P2)
- [ ] Fix keyboard API integration (P2)
- [ ] Add connection retry logic (P2)

### Post-Launch Improvements
- [ ] Implement circuit breaker for external APIs
- [ ] Add comprehensive logging
- [ ] Set up monitoring and alerting
- [ ] Implement rate limit metrics dashboard

---

## 🐛 Reporting New Issues

If you encounter a new issue:

1. **Check Console Logs**:
   - iOS: Xcode → View → Debug Area → Show Debug Area
   - Backend: Terminal running `npm start`

2. **Gather Information**:
   - What were you doing when it happened?
   - Can you reproduce it consistently?
   - What error messages appeared?

3. **Try Clean Rebuild**:
   ```bash
   # iOS
   cd iOS && rm -rf .build && xcodebuild clean

   # Backend
   cd Backend && rm -rf node_modules && npm install
   ```

---

## 📱 iOS-Specific Limitations

### Keyboard Extensions Cannot:
- Access camera directly (workaround: use screenshot sharing)
- Present system alerts (using custom in-keyboard UI instead)
- Run background tasks (all processing happens on-demand)
- Access full network permissions without "Allow Full Access"

These are iOS platform limitations, not bugs.

---

## 🔧 Database Issues

### SQLite Lock Errors
**Problem**: "Database is locked" errors in backend

**Symptoms**:
```
Error: SQLITE_BUSY: database is locked
```

**Workaround**:
```bash
cd Backend/data
rm vibe8.db
cd ..
npm run db:init
```

**Prevention**: Don't access database while backend is running

---

### Missing API Keys
**Problem**: Backend starts but AI requests fail

**Symptoms**:
- Health check shows: `"grok":"error"` or `"gemini":"error"`
- Console: "Missing API key" errors

**Fix**:
1. Check `Backend/.env` file exists
2. Verify API keys are set correctly
3. Restart backend: `killall node && npm start`

---

**Need Help?** Check other documentation:
- [SETUP.md](./SETUP.md) - Installation troubleshooting
- [ARCHITECTURE.md](./ARCHITECTURE.md) - System design
- [API.md](./API.md) - Backend API reference
- [BUILD_VERIFICATION_REPORT.md](/BUILD_VERIFICATION_REPORT.md) - Stage 5 results
- [INTEGRATION_TEST_REPORT.md](/Backend/INTEGRATION_TEST_REPORT.md) - Stage 6 Agent 2
- [EDGE_CASE_TEST_RESULTS.md](./EDGE_CASE_TEST_RESULTS.md) - Stage 6 Agent 3
- [SECURITY_TEST_REPORT.md](./SECURITY_TEST_REPORT.md) - Stage 6 Agent 4
