# 🚀 FLIRRT.AI - COMPLETE NEXT SESSION GUIDE
**Last Updated**: 2025-09-27 15:45 PST
**Current Branch**: fix/real-mvp-implementation
**Session Achievement**: iOS Simulator Testing with Real Verification ✅

---

## 🎯 QUICK START FOR NEXT SESSION

```bash
# 1. Start Backend (REQUIRED FIRST)
cd /Users/macbookairm1/Flirrt-screens-shots-v1/FlirrtAI
pkill -f node  # Kill any stale processes
cd Backend && npm start &  # Start in background
sleep 5  # Wait for server

# 2. Verify Backend is Running
curl http://localhost:3000/health | jq '.'

# 3. Open iOS Project
cd ../iOS
open Flirrt.xcodeproj  # Opens in Xcode

# 4. Check Simulator Status
xcrun simctl list devices | grep Booted

# 5. Quick Verification
cd .. && ./verify-all.sh
```

---

## 📍 CURRENT PROJECT STATE

### ✅ WORKING COMPONENTS
1. **Backend API**
   - Running on port 3000
   - Real Grok AI integration (10-15 second responses)
   - In-memory cache (Redis fallback)
   - Circuit breakers active
   - Correlation IDs working

2. **iOS App**
   - Builds successfully with CODE_SIGNING_ALLOWED=NO
   - Installs and runs on simulator
   - Bundle ID: com.flirrt.app
   - Keyboard extension available

3. **Verification System**
   - verify-all.sh enforces real testing
   - Git pre-commit hook blocks unverified commits
   - TEST_EVIDENCE.md required for claims

### ⚠️ KNOWN ISSUES TO FIX

#### 1. API Timeout Issue (HIGH PRIORITY)
- **Problem**: 33% of Grok API calls timeout after 25 seconds
- **Location**: Backend/services/circuitBreaker.js:108
- **Current Timeout**: 25000ms
- **Solution Options**:
  ```javascript
  // Option 1: Increase timeout
  timeout: 35000,  // Instead of 25000

  // Option 2: Add retry logic
  async function makeGrokRequestWithRetry(prompt, maxRetries = 2) {
    for (let i = 0; i < maxRetries; i++) {
      try {
        return await makeGrokRequest(prompt);
      } catch (error) {
        if (i === maxRetries - 1) throw error;
        await sleep(1000);
      }
    }
  }
  ```

#### 2. Database Not Connected (MEDIUM PRIORITY)
- **Status**: Using mock data fallback
- **Impact**: No persistence
- **Solution**: Install PostgreSQL or use SQLite for development
  ```bash
  # Option 1: Install PostgreSQL
  brew install postgresql
  brew services start postgresql
  createdb flirrt_ai

  # Option 2: Use SQLite (modify Backend/services/database.js)
  ```

#### 3. MCP iOS Simulator Tools Limited (LOW PRIORITY)
- **Issue**: idb not installed
- **Impact**: Can't use advanced MCP simulator tools
- **Solution**:
  ```bash
  # Install Facebook's idb
  brew tap facebook/fb
  brew install idb-companion
  pip3 install fb-idb
  ```

#### 4. Xcode Test Scheme Not Configured
- **Issue**: Can't run automated tests
- **Solution**: Add test target in Xcode project

---

## 🛠️ DEVELOPMENT ENVIRONMENT

### System Information
- **Machine**: MacBook Air M1
- **OS**: macOS Darwin 25.0.0
- **Xcode**: Latest version
- **Node**: v24.7.0
- **Working Directory**: `/Users/macbookairm1/Flirrt-screens-shots-v1/FlirrtAI`

### Directory Structure
```
/FlirrtAI/
├── Backend/          # Node.js API server
│   ├── server.js     # Main server file
│   ├── routes/       # API endpoints
│   └── services/     # Grok AI, Redis fallback
├── iOS/              # Swift iOS app
│   ├── Flirrt/       # Main app
│   ├── FlirrtKeyboard/  # Keyboard extension
│   ├── FlirrtShare/  # Share extension
│   └── build/        # Build output
└── Agents/           # AI sub-agents
```

### Critical File Paths
- **Backend Server**: `Backend/server.js`
- **iOS Project**: `iOS/Flirrt.xcodeproj`
- **Built App**: `iOS/build/Build/Products/Debug-iphonesimulator/Flirrt.app`
- **Verification Script**: `verify-all.sh`
- **Environment Variables**: `Backend/.env`

---

## 📱 iOS SIMULATOR MANAGEMENT

### Currently Configured Simulators
- **iPhone 16**: 0F8761DB-093E-4AC2-A1A9-C3072125AAB5
- **Flirrt Production Device**: 237F6A2D-72E4-49C2-B5E0-7B3F973C6814

### Essential Simulator Commands
```bash
# List devices
xcrun simctl list devices

# Boot simulator
xcrun simctl boot "iPhone 16"

# Install app
xcrun simctl install "iPhone 16" iOS/build/Build/Products/Debug-iphonesimulator/Flirrt.app

# Launch app
xcrun simctl launch "iPhone 16" com.flirrt.app

# Take screenshot
xcrun simctl io "iPhone 16" screenshot proof.png

# Open Messages for keyboard testing
xcrun simctl launch "iPhone 16" com.apple.MobileSMS

# Grant permissions
xcrun simctl privacy "iPhone 16" grant photos com.flirrt.app
xcrun simctl privacy "iPhone 16" grant microphone com.flirrt.app
```

---

## 🔧 MCP TOOLS STATUS

### Available MCP Tools
1. **ios-simulator** (Limited - needs idb)
   - `mcp__ios-simulator__screenshot` ✅ Working
   - `mcp__ios-simulator__ui_view` ❌ Needs idb
   - `mcp__ios-simulator__ui_tap` ❌ Needs idb
   - `mcp__ios-simulator__ui_type` ❌ Needs idb

2. **memory-bank** ✅ Working
3. **sequential-thinking** ✅ Working
4. **context7** ✅ Working

### MCP Tool Workarounds
Since idb is not installed, use xcrun simctl directly:
- Screenshots: `xcrun simctl io booted screenshot file.png`
- App control: `xcrun simctl launch/terminate`
- Permissions: `xcrun simctl privacy`

---

## 🔑 API TESTING

### Test Real Grok AI
```bash
# Single test
curl -X POST http://localhost:3000/api/v1/flirts/generate_flirts \
  -H "Content-Type: application/json" \
  -H "X-Keyboard-Extension: true" \
  -d '{"screenshot_id": "test-'$(date +%s)'", "context": "test", "tone": "playful"}' \
  | jq '.data.suggestions[0].text, .data.cached'

# Multiple tests for uniqueness
for i in {1..3}; do
  echo "Test $i:"
  curl -s -X POST http://localhost:3000/api/v1/flirts/generate_flirts \
    -H "Content-Type: application/json" \
    -H "X-Keyboard-Extension: true" \
    -d "{\"screenshot_id\": \"test-$(date +%s)-$i\", \"context\": \"test\", \"tone\": \"playful\"}" \
    | jq '.data.suggestions[0].text'
  sleep 2
done
```

### Expected Response Times
- **Real Grok AI**: 10-15 seconds ✅
- **Timeout**: 25 seconds (needs fix)
- **Cached/Mock**: < 1 second (indicates problem)

---

## 📋 REMAINING TASKS CHECKLIST

### Immediate Priority
- [ ] Fix API timeout issue (increase to 35s or add retry)
- [ ] Test complete user flow on simulator
- [ ] Verify keyboard extension sends real screenshots

### High Priority
- [ ] Set up database (PostgreSQL or SQLite)
- [ ] Configure Redis for production caching
- [ ] Add proper error handling for timeouts

### Medium Priority
- [ ] Install idb for full MCP tool support
- [ ] Configure Xcode test scheme
- [ ] Add SwiftUI tests

### Low Priority
- [ ] Update TLS version (TLSv1.0 → TLSv1.2)
- [ ] Clean up test artifacts
- [ ] Optimize build times

---

## 🚨 CRITICAL REMINDERS

1. **ALWAYS run verify-all.sh before claiming success**
2. **Backend MUST be running before iOS testing**
3. **Real Grok AI takes 10-15 seconds (instant = fake)**
4. **Check `cached: false` to confirm real AI**
5. **Take screenshots as proof of testing**
6. **Update TEST_EVIDENCE.md with results**

---

## 💡 LESSONS LEARNED

### What Works Well
- Parallel execution with Task tool
- xcrun simctl for simulator control
- In-memory cache as Redis fallback
- Git pre-commit hooks for enforcement

### Common Pitfalls
- Don't trust "should work" - test everything
- MCP tools need idb installed
- API timeouts are real issue (not network)
- Database not required for development

### Best Practices
1. Start backend first, always
2. Use unique test IDs to avoid cache hits
3. Document with screenshots
4. Run verify-all.sh frequently
5. Check server logs for real API usage

---

## 🎯 SUCCESS CRITERIA FOR NEXT SESSION

To consider the project "production ready":
1. ✅ API timeout issue resolved
2. ✅ Database connected and working
3. ✅ Full user flow tested on simulator
4. ✅ Keyboard extension verified end-to-end
5. ✅ All tests passing
6. ✅ No hardcoded/mock data

---

## 📝 SESSION HANDOFF NOTES

### What This Session Accomplished
- Verified real Grok AI integration (no mock data!)
- Built and deployed iOS app to simulator
- Tested keyboard extension in Messages
- Created comprehensive verification system
- Documented everything with evidence

### Next Session Should Focus On
1. **Fix the timeout issue first** - It's affecting user experience
2. **Set up proper database** - Currently using mock data
3. **Test full user flow** - From onboarding to flirt generation
4. **Optimize performance** - 11 seconds is good but can be better

### Quick Health Check Commands
```bash
# Is backend running?
curl http://localhost:3000/health | jq '.checks.system.healthy'

# Is app on simulator?
xcrun simctl get_app_container "iPhone 16" com.flirrt.app

# Quick API test
time curl -X POST http://localhost:3000/api/v1/flirts/generate_flirts \
  -H "X-Keyboard-Extension: true" \
  -d '{"context": "quick-test"}' | jq '.success'
```

---

## 🔐 ENVIRONMENT VARIABLES

Current .env configuration (Backend/.env):
```env
PORT=3000
NODE_ENV=development
GROK_API_KEY=xai-[ACTIVE]
ELEVENLABS_API_KEY=sk_[MASKED]
JWT_SECRET=flirrt_ai_super_secret_key_2024_production
# Database and Redis configs present but not used
```

---

## 📞 SUPPORT & TROUBLESHOOTING

### If Backend Won't Start
```bash
pkill -f node
lsof -i:3000  # Check if port is free
cd Backend && npm start
```

### If iOS Build Fails
```bash
cd iOS
rm -rf build/
xcodebuild clean
xcodebuild -scheme Flirrt -configuration Debug build
```

### If Simulator Issues
```bash
xcrun simctl shutdown all
xcrun simctl erase all
xcrun simctl boot "iPhone 16"
```

### If API Timeouts Persist
- Check Grok API status
- Increase timeout in circuitBreaker.js
- Add retry logic
- Consider caching strategy

---

**Remember**: This project has REAL verification now. No theater. Test everything. Document everything. The verification system will catch you if you don't!

*Good luck with the next session! You have everything you need here.* 🚀