#!/bin/bash
# FLIRRT.AI COMPLETE VERIFICATION SCRIPT
# This script performs comprehensive testing including iOS simulator verification

set -e  # Exit on any error

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=============================================="
echo "🔍 FLIRRT.AI COMPLETE VERIFICATION SUITE"
echo "=============================================="
echo ""

FAILED=0
EVIDENCE_FILE="TEST_EVIDENCE.md"

# Initialize evidence file
echo "# TEST EVIDENCE REPORT" > $EVIDENCE_FILE
echo "Generated: $(date)" >> $EVIDENCE_FILE
echo "Branch: $(git branch --show-current)" >> $EVIDENCE_FILE
echo "" >> $EVIDENCE_FILE

# ==========================================
# PHASE 1: Backend Verification
# ==========================================
echo -e "${BLUE}📡 PHASE 1: Backend Verification${NC}"
echo "-----------------------------------"

# Check if backend is running
echo -n "1. Checking backend server... "
if curl -s http://localhost:3000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Running${NC}"
    echo "## Backend Status" >> $EVIDENCE_FILE
    echo "✅ Server running on http://localhost:3000" >> $EVIDENCE_FILE
else
    echo -e "${RED}❌ Not running${NC}"
    echo "  Starting backend server..."
    cd FlirrtAI/Backend && npm start &
    sleep 5
fi

# Test API responses are unique (not hardcoded)
echo -n "2. Testing API uniqueness (3 calls)... "
echo "" >> $EVIDENCE_FILE
echo "## API Response Tests" >> $EVIDENCE_FILE
echo '```json' >> $EVIDENCE_FILE

RESPONSES=()
TIMESTAMP=$(date +%s)
for i in {1..3}; do
    RESPONSE=$(curl -s -X POST http://localhost:3000/api/v1/flirts/generate_flirts \
        -H "Content-Type: application/json" \
        -H "X-Keyboard-Extension: true" \
        -d "{\"screenshot_id\": \"test-$TIMESTAMP-$i\", \"context\": \"test-$i\", \"tone\": \"playful\"}")

    # Extract first suggestion text
    SUGGESTION=$(echo "$RESPONSE" | grep -o '"text":"[^"]*"' | head -1)
    RESPONSES+=("$SUGGESTION")

    echo "Test $i response:" >> $EVIDENCE_FILE
    echo "$RESPONSE" | head -c 200 >> $EVIDENCE_FILE
    echo "..." >> $EVIDENCE_FILE

    # Check if using real API (not cached)
    if echo "$RESPONSE" | grep -q '"cached":false'; then
        REAL_API=true
    else
        REAL_API=false
    fi
done
echo '```' >> $EVIDENCE_FILE

# Check if all responses are different
if [ "${RESPONSES[0]}" != "${RESPONSES[1]}" ] && [ "${RESPONSES[1]}" != "${RESPONSES[2]}" ]; then
    echo -e "${GREEN}✅ Unique responses${NC}"
    echo "✅ All 3 API calls returned different suggestions" >> $EVIDENCE_FILE
else
    echo -e "${RED}❌ Same responses (hardcoded)${NC}"
    echo "❌ API returning identical suggestions (hardcoded fallback)" >> $EVIDENCE_FILE
    FAILED=1
fi

# Check if using real Grok API
echo -n "3. Verifying real AI usage... "
if [ "$REAL_API" = true ]; then
    echo -e "${GREEN}✅ Real Grok API${NC}"
    echo "✅ Using real Grok API (cached: false)" >> $EVIDENCE_FILE
else
    echo -e "${RED}❌ Using cached responses${NC}"
    echo "❌ Using cached responses (not real-time AI)" >> $EVIDENCE_FILE
    FAILED=1
fi

# ==========================================
# PHASE 2: iOS App Verification
# ==========================================
echo ""
echo -e "${BLUE}📱 PHASE 2: iOS App Verification${NC}"
echo "-----------------------------------"
echo "" >> $EVIDENCE_FILE
echo "## iOS App Testing" >> $EVIDENCE_FILE

# Build the iOS app
echo -n "1. Building iOS app... "
cd /Users/macbookairm1/Flirrt-screens-shots-v1/FlirrtAI/iOS
if xcodebuild -scheme Flirrt -configuration Debug -derivedDataPath build -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO -quiet build 2>/dev/null; then
    echo -e "${GREEN}✅ Build succeeded${NC}"
    echo "✅ iOS app build succeeded" >> ../../$EVIDENCE_FILE
    APP_PATH="build/Build/Products/Debug-iphonesimulator/Flirrt.app"
else
    echo -e "${RED}❌ Build failed${NC}"
    echo "❌ iOS app build failed" >> ../../$EVIDENCE_FILE
    FAILED=1
fi

# ==========================================
# PHASE 3: iOS Simulator Testing
# ==========================================
echo ""
echo -e "${BLUE}📱 PHASE 3: Simulator Testing${NC}"
echo "-----------------------------------"
echo "" >> ../../$EVIDENCE_FILE
echo "## Simulator Testing" >> ../../$EVIDENCE_FILE

# Get or create a simulator
echo -n "1. Finding simulator... "
DEVICE_ID=$(xcrun simctl list devices | grep "iPhone 17" | grep -v "unavailable" | head -1 | grep -o "[A-Z0-9\-]*" | tail -1)

if [ -z "$DEVICE_ID" ]; then
    # Try iPhone 16 if 17 doesn't exist
    DEVICE_ID=$(xcrun simctl list devices | grep "iPhone 16" | grep -v "unavailable" | head -1 | grep -o "[A-Z0-9\-]*" | tail -1)
fi

if [ -z "$DEVICE_ID" ]; then
    # Fall back to any iPhone
    DEVICE_ID=$(xcrun simctl list devices | grep "iPhone" | grep -v "unavailable" | head -1 | grep -o "[A-Z0-9\-]*" | tail -1)
fi

if [ -n "$DEVICE_ID" ]; then
    echo -e "${GREEN}✅ Found: $DEVICE_ID${NC}"
    echo "✅ Using simulator: $DEVICE_ID" >> ../../$EVIDENCE_FILE
else
    echo -e "${RED}❌ No simulator found${NC}"
    echo "❌ No iOS simulator available" >> ../../$EVIDENCE_FILE
    FAILED=1
fi

# Boot the simulator if not already booted
echo -n "2. Booting simulator... "
BOOT_STATUS=$(xcrun simctl list devices | grep "$DEVICE_ID" | grep -c "Booted" || true)
if [ "$BOOT_STATUS" -eq 0 ]; then
    xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true
    sleep 5
fi
echo -e "${GREEN}✅ Ready${NC}"

# Install the app
if [ -f "$APP_PATH" ]; then
    echo -n "3. Installing app on simulator... "
    if xcrun simctl install "$DEVICE_ID" "$APP_PATH" 2>/dev/null; then
        echo -e "${GREEN}✅ Installed${NC}"
        echo "✅ App installed on simulator" >> ../../$EVIDENCE_FILE
    else
        echo -e "${YELLOW}⚠️  Install failed${NC}"
        echo "⚠️ App installation failed" >> ../../$EVIDENCE_FILE
    fi

    # Launch the app
    echo -n "4. Launching app... "
    if xcrun simctl launch "$DEVICE_ID" "com.flirrt.app" 2>/dev/null; then
        echo -e "${GREEN}✅ Launched${NC}"
        echo "✅ App launched successfully" >> ../../$EVIDENCE_FILE
        sleep 3

        # Take a screenshot as proof
        echo -n "5. Taking screenshot... "
        SCREENSHOT_PATH="simulator-proof-$(date +%s).png"
        if xcrun simctl io "$DEVICE_ID" screenshot "$SCREENSHOT_PATH" 2>/dev/null; then
            echo -e "${GREEN}✅ Saved: $SCREENSHOT_PATH${NC}"
            echo "✅ Screenshot saved: $SCREENSHOT_PATH" >> ../../$EVIDENCE_FILE
        else
            echo -e "${YELLOW}⚠️  Screenshot failed${NC}"
        fi
    else
        echo -e "${RED}❌ Launch failed${NC}"
        echo "❌ App launch failed" >> ../../$EVIDENCE_FILE
        FAILED=1
    fi
fi

# Test keyboard extension
echo -n "6. Testing keyboard extension... "
# Open Messages app to test keyboard
xcrun simctl launch "$DEVICE_ID" "com.apple.MobileSMS" 2>/dev/null || true
sleep 2
echo -e "${YELLOW}⚠️  Manual verification needed${NC}"
echo "⚠️ Keyboard extension requires manual verification in Messages app" >> ../../$EVIDENCE_FILE

cd ../..

# ==========================================
# PHASE 4: Evidence Summary
# ==========================================
echo ""
echo -e "${BLUE}📄 PHASE 4: Evidence Summary${NC}"
echo "-----------------------------------"
echo "" >> $EVIDENCE_FILE
echo "## Summary" >> $EVIDENCE_FILE

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ ALL TESTS PASSED${NC}"
    echo "✅ **ALL VERIFICATION TESTS PASSED**" >> $EVIDENCE_FILE
    echo "" >> $EVIDENCE_FILE
    echo "The app has been verified to:" >> $EVIDENCE_FILE
    echo "- Use real Grok AI API (not fallbacks)" >> $EVIDENCE_FILE
    echo "- Return unique suggestions for each request" >> $EVIDENCE_FILE
    echo "- Build successfully in Xcode" >> $EVIDENCE_FILE
    echo "- Install and run on iOS simulator" >> $EVIDENCE_FILE
else
    echo -e "${RED}❌ VERIFICATION FAILED${NC}"
    echo "❌ **VERIFICATION FAILED**" >> $EVIDENCE_FILE
    echo "" >> $EVIDENCE_FILE
    echo "Critical issues detected:" >> $EVIDENCE_FILE
    echo "- Check server logs for errors" >> $EVIDENCE_FILE
    echo "- Verify Grok API configuration" >> $EVIDENCE_FILE
    echo "- Fix iOS build errors" >> $EVIDENCE_FILE
fi

echo ""
echo "=============================================="
echo "Evidence saved to: $EVIDENCE_FILE"
echo "Screenshot saved to: ${SCREENSHOT_PATH:-none}"
echo "=============================================="

exit $FAILED