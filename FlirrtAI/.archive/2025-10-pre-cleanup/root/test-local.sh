#!/bin/bash

# FLIRRT.AI LOCAL TESTING SCRIPT
# Last Updated: 2025-09-29
# This script sets up everything needed for local testing

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  FLIRRT.AI LOCAL TESTING LAUNCHER${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Function to check if process is running
check_process() {
    if pgrep -f "$1" > /dev/null; then
        return 0
    else
        return 1
    fi
}

# Kill any existing backend processes
echo -e "${YELLOW}🔄 Cleaning up existing processes...${NC}"
pkill -f "node.*server.js" 2>/dev/null || true
sleep 2

# Start backend
echo -e "${BLUE}🚀 Starting Backend Server...${NC}"
cd Backend
npm start &
BACKEND_PID=$!
echo -e "${GREEN}✅ Backend started with PID: $BACKEND_PID${NC}"

# Wait for backend to be ready
echo -e "${YELLOW}⏳ Waiting for backend to initialize...${NC}"
sleep 5

# Check backend health
echo -e "${BLUE}🏥 Checking backend health...${NC}"
if curl -s http://localhost:3000/health | grep -q "status"; then
    echo -e "${GREEN}✅ Backend is healthy${NC}"
else
    echo -e "${RED}❌ Backend health check failed${NC}"
fi

# Test API
echo -e "${BLUE}🧪 Testing API endpoint...${NC}"
echo -e "${YELLOW}Generating test flirts (this may take 10-15 seconds)...${NC}"
RESPONSE=$(curl -s -X POST http://localhost:3000/api/v1/flirts/generate_flirts \
  -H "Content-Type: application/json" \
  -H "X-Keyboard-Extension: true" \
  -d '{"screenshot_id": "test-local", "context": "Testing", "tone": "witty"}' \
  --max-time 20)

if echo "$RESPONSE" | grep -q "success.*true"; then
    echo -e "${GREEN}✅ API test successful${NC}"
    echo "$RESPONSE" | python3 -m json.tool | head -20
else
    echo -e "${RED}❌ API test failed${NC}"
fi

echo ""
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  iOS BUILD & SIMULATOR SETUP${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

# Navigate to iOS directory
cd ../iOS

# Build iOS app
echo -e "${BLUE}🔨 Building iOS app for simulator...${NC}"
echo -e "${YELLOW}Note: Signing errors are expected for local testing${NC}"
xcodebuild -project Flirrt.xcodeproj \
  -scheme Flirrt \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -configuration Debug \
  build 2>&1 | grep -E "(BUILD|SUCCEEDED|FAILED|error)" || true

# Check if build succeeded
if [ -d ~/Library/Developer/Xcode/DerivedData/Flirrt-*/Build/Products/Debug-iphonesimulator/Flirrt.app ]; then
    echo -e "${GREEN}✅ iOS app built successfully${NC}"

    # Boot simulator if not already running
    echo -e "${BLUE}📱 Starting iOS Simulator...${NC}"
    xcrun simctl boot "iPhone 17" 2>/dev/null || true
    open -a Simulator

    # Install app
    echo -e "${BLUE}📲 Installing app on simulator...${NC}"
    xcrun simctl install booted ~/Library/Developer/Xcode/DerivedData/Flirrt-*/Build/Products/Debug-iphonesimulator/Flirrt.app

    # Launch app
    echo -e "${BLUE}🚀 Launching Flirrt app...${NC}"
    xcrun simctl launch booted com.flirrt.app

    echo -e "${GREEN}✅ App installed and launched${NC}"
else
    echo -e "${RED}❌ iOS build failed - check Xcode for signing configuration${NC}"
fi

echo ""
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  LOCAL TESTING READY${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""
echo -e "${GREEN}✅ Backend running at: http://localhost:3000${NC}"
echo -e "${GREEN}✅ Health check: http://localhost:3000/health${NC}"
echo -e "${GREEN}✅ API endpoint: http://localhost:3000/api/v1/flirts/generate_flirts${NC}"
echo ""
echo -e "${YELLOW}📝 Next Steps:${NC}"
echo "1. In Simulator: Settings → General → Keyboard → Add Flirrt Keyboard"
echo "2. Open Messages app and switch to Flirrt Keyboard"
echo "3. Take a screenshot and tap 'Analyze Screenshot'"
echo "4. Test voice recording in main app"
echo ""
echo -e "${YELLOW}⚠️  To stop backend: kill $BACKEND_PID${NC}"
echo -e "${YELLOW}⚠️  Or use: pkill -f 'node.*server.js'${NC}"
echo ""
echo -e "${BLUE}Happy Testing! 🎉${NC}"

# Keep script running to maintain backend
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop all services${NC}"
wait $BACKEND_PID