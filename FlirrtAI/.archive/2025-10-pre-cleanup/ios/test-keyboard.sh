#!/bin/bash
echo "Testing Flirrt Keyboard Extension"
echo "================================="

# Kill and restart Messages to ensure fresh state
xcrun simctl terminate "iPhone 16" com.apple.MobileSMS 2>/dev/null
sleep 1
xcrun simctl launch "iPhone 16" com.apple.MobileSMS
sleep 2

# Take screenshot
xcrun simctl io "iPhone 16" screenshot keyboard-test-1.png

# Test API through keyboard
echo "Testing keyboard API integration..."
curl -X POST http://localhost:3000/api/v1/flirts/generate_flirts \
  -H "Content-Type: application/json" \
  -H "X-Keyboard-Extension: true" \
  -d '{"screenshot_id": "keyboard-test", "context": "messages", "tone": "flirty"}' \
  | jq '.data.suggestions[0].text'

echo "Keyboard extension test complete"
