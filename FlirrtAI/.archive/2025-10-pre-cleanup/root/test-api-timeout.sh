#!/bin/bash
# Test script for API timeout validation
# This tests 5 consecutive API calls to verify 0% timeout rate

echo "=========================================="
echo "API TIMEOUT TEST - 5 CONSECUTIVE CALLS"
echo "=========================================="
echo ""

SUCCESS_COUNT=0
FAIL_COUNT=0
TIMEOUT_COUNT=0

for i in {1..5}; do
    echo "Test $i/5:"
    echo "---------"

    START_TIME=$(date +%s)

    # Make API call with 40 second timeout (should complete in 35s max)
    RESPONSE=$(curl -s -X POST http://localhost:3000/api/v1/flirts/generate_flirts \
        -H "Content-Type: application/json" \
        -H "X-Keyboard-Extension: true" \
        -d "{\"screenshot_id\": \"timeout-test-$(date +%s)-$i\", \"context\": \"test-$i\", \"tone\": \"playful\"}" \
        --max-time 40 2>&1)

    EXIT_CODE=$?
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    if [ $EXIT_CODE -eq 0 ]; then
        # Extract suggestion and check if it's unique
        SUGGESTION=$(echo "$RESPONSE" | jq -r '.data.suggestions[0].text' 2>/dev/null)
        CACHED=$(echo "$RESPONSE" | jq -r '.data.cached' 2>/dev/null)

        if [ "$SUGGESTION" != "null" ] && [ "$SUGGESTION" != "" ]; then
            echo "✅ SUCCESS (${DURATION}s)"
            echo "Cached: $CACHED"
            echo "Suggestion: ${SUGGESTION:0:80}..."
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        else
            echo "❌ FAILED - Invalid response"
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
    elif [ $EXIT_CODE -eq 28 ]; then
        echo "⏱️  TIMEOUT after ${DURATION}s"
        TIMEOUT_COUNT=$((TIMEOUT_COUNT + 1))
    else
        echo "❌ ERROR (code: $EXIT_CODE)"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi

    echo ""

    # Small delay between requests
    sleep 2
done

echo "=========================================="
echo "TEST RESULTS SUMMARY"
echo "=========================================="
echo "✅ Successful: $SUCCESS_COUNT/5"
echo "❌ Failed: $FAIL_COUNT/5"
echo "⏱️  Timeouts: $TIMEOUT_COUNT/5"
echo ""

if [ $TIMEOUT_COUNT -eq 0 ]; then
    echo "🎉 SUCCESS: 0% timeout rate achieved!"
    exit 0
else
    TIMEOUT_RATE=$((TIMEOUT_COUNT * 100 / 5))
    echo "⚠️  WARNING: ${TIMEOUT_RATE}% timeout rate"
    exit 1
fi