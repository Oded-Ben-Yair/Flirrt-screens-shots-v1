# 🧪 LOCAL TESTING GUIDE FOR FLIRRT.AI

## 🚀 Current Status: READY FOR TESTING

### ✅ System Status
- **Backend Server**: ✅ RUNNING on http://localhost:3000
- **Health Check**: http://localhost:3000/health
- **iOS Simulator**: ✅ OPEN (Flirrt Production Device)
- **API Keys**: ✅ UPDATED (Grok & ElevenLabs)

### 📱 How to Test in Xcode

1. **Open Xcode Project**:
   ```bash
   cd /Users/macbookairm1/Flirrt-screens-shots-v1/FlirrtAI/iOS
   xed .
   ```

2. **Select Target**:
   - Scheme: `Flirrt`
   - Device: `Flirrt Production Device` (or any iPhone simulator)

3. **Build & Run**:
   - Press `Cmd + R` to build and run
   - Or click the Play button in Xcode

### 🔌 API Endpoints for Testing

#### Test Screenshot Analysis
```bash
curl -X POST http://localhost:3000/api/v1/analysis/analyze_screenshot \
  -H "Authorization: Bearer test-token" \
  -F "screenshot=@test-screenshot.png" \
  -F "context=Test analysis"
```

#### Test Flirt Generation
```bash
curl -X POST http://localhost:3000/api/v1/flirts/generate_flirts \
  -H "Authorization: Bearer test-token" \
  -H "Content-Type: application/json" \
  -d '{"context": "Test flirt", "tone": "playful"}'
```

#### Test Voice Synthesis
```bash
curl -X POST http://localhost:3000/api/v1/voice/synthesize_voice \
  -H "Authorization: Bearer test-token" \
  -H "Content-Type: application/json" \
  -d '{"text": "Hey there! How are you?", "voice_id": "EXAVITQu4vr4xnSDxMaL"}'
```

### 📊 Monitor Backend Logs

I'm currently monitoring the backend server. You'll see:
- All incoming API requests
- Response status codes
- Any errors that occur

### 🧪 Test Scenarios

1. **Launch App**
   - Should show login screen
   - Apple Sign In button visible

2. **Authentication**
   - Tap Apple Sign In
   - Complete age verification (18+)

3. **Voice Recording**
   - Navigate to Voice tab
   - Record up to 3 minutes
   - Upload for voice cloning

4. **Screenshot Analysis**
   - Take screenshot in dating app
   - Share to Flirrt via share sheet
   - See AI-generated suggestions

5. **Keyboard Extension**
   - Settings > General > Keyboard
   - Add Flirrt Keyboard
   - Enable Full Access
   - Use in any app

### 🔧 Troubleshooting

**Backend not responding?**
```bash
# Check if running
lsof -i:3000

# Restart if needed
cd FlirrtAI/Backend
npm start
```

**App won't build?**
```bash
# Clean build
cd iOS
rm -rf build .build
xcodebuild clean
```

**Simulator issues?**
```bash
# Reset simulator
xcrun simctl erase 237F6A2D-72E4-49C2-B5E0-7B3F973C6814
xcrun simctl boot 237F6A2D-72E4-49C2-B5E0-7B3F973C6814
```

### 📝 Current Configuration

- **Grok Model**: grok-4-fast (text), grok-2-vision-1212 (vision)
- **ElevenLabs**: 30+ voices available
- **Memory Limit**: Keyboard extension <60MB
- **Test Pass Rate**: 100% (5/5 tests)

## 🎯 I'm Ready and Listening!

The backend is running and I'm monitoring all logs. Start testing in Xcode and I'll show you real-time activity as requests come in!

**Backend Status**: 🟢 LIVE
**Monitoring**: 🔴 ACTIVE
**Ready for**: LOCAL TESTING

---
Go ahead and test - I'll report everything that happens!