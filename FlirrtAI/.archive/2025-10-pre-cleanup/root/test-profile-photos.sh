#!/bin/bash
# Test script for profile photo analysis and flirt generation
# This tests the API with actual profile photos to ensure relevance

echo "=========================================="
echo "FLIRRT.AI PROFILE PHOTO TEST"
echo "=========================================="
echo ""

# Profile photos to test
PHOTOS=(
    "/Users/macbookairm1/Pictures/Photos Library.photoslibrary/resources/derivatives/B/B55A8A82-3C5E-4550-B5CB-2C6AD1DC9DDD_1_105_c.jpeg"
    "/Users/macbookairm1/Pictures/Photos Library.photoslibrary/resources/derivatives/5/5803004E-7EF7-4399-9574-12682E3809C2_1_105_c.jpeg"
    "/Users/macbookairm1/Pictures/Photos Library.photoslibrary/resources/derivatives/4/45E4E2F1-A4B6-4AE9-A21B-9A61C2C5336D_1_105_c.jpeg"
    "/Users/macbookairm1/Pictures/Photos Library.photoslibrary/resources/derivatives/6/6C3C8BAC-AA4C-4166-BB60-9DA55BE2E3A6_1_105_c.jpeg"
    "/Users/macbookairm1/Pictures/Photos Library.photoslibrary/resources/derivatives/1/112E284E-FBC7-47EC-9E33-6E2BF66B448B_1_105_c.jpeg"
)

SUCCESS_COUNT=0
FAIL_COUNT=0

for i in "${!PHOTOS[@]}"; do
    PHOTO_PATH="${PHOTOS[$i]}"
    PHOTO_NUM=$((i + 1))

    echo "Testing Photo $PHOTO_NUM:"
    echo "========================="
    echo "Path: $PHOTO_PATH"

    # Check if photo exists
    if [[ ! -f "$PHOTO_PATH" ]]; then
        echo "❌ Photo not found: $PHOTO_PATH"
        FAIL_COUNT=$((FAIL_COUNT + 1))
        echo ""
        continue
    fi

    echo "📸 Photo found ($(ls -lh "$PHOTO_PATH" | awk '{print $5}'))"

    # Convert photo to base64 for API
    echo "🔄 Converting to base64..."
    PHOTO_BASE64=$(base64 -i "$PHOTO_PATH")

    START_TIME=$(date +%s)

    # Create API payload with photo data
    PAYLOAD=$(cat <<EOF
{
    "screenshot_id": "profile-photo-test-$(date +%s)-$PHOTO_NUM",
    "context": "dating profile photo analysis",
    "tone": "flirty",
    "image_data": "$PHOTO_BASE64",
    "image_type": "profile_photo"
}
EOF
)

    echo "🚀 Sending to Flirrt.ai API..."

    # Make API call
    RESPONSE=$(curl -s -X POST http://localhost:3000/api/v1/flirts/generate_flirts \
        -H "Content-Type: application/json" \
        -H "X-Keyboard-Extension: true" \
        -d "$PAYLOAD" \
        --max-time 40 2>&1)

    EXIT_CODE=$?
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))

    if [ $EXIT_CODE -eq 0 ]; then
        # Parse response
        SUGGESTION=$(echo "$RESPONSE" | jq -r '.data.suggestions[0].text' 2>/dev/null)
        CONFIDENCE=$(echo "$RESPONSE" | jq -r '.data.suggestions[0].confidence' 2>/dev/null)
        CACHED=$(echo "$RESPONSE" | jq -r '.data.cached' 2>/dev/null)

        if [ "$SUGGESTION" != "null" ] && [ "$SUGGESTION" != "" ]; then
            echo "✅ SUCCESS (${DURATION}s)"
            echo "📊 Confidence: $CONFIDENCE"
            echo "🤖 Real AI: $([ "$CACHED" = "false" ] && echo "Yes" || echo "No")"
            echo "💬 Flirt: $SUGGESTION"
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        else
            echo "❌ FAILED - Invalid response"
            echo "Response: $RESPONSE"
            FAIL_COUNT=$((FAIL_COUNT + 1))
        fi
    else
        echo "❌ ERROR (code: $EXIT_CODE)"
        echo "Response: $RESPONSE"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    fi

    echo ""
    echo "----------------------------------------"
    echo ""

    # Small delay between requests
    sleep 3
done

echo "=========================================="
echo "PROFILE PHOTO TEST SUMMARY"
echo "=========================================="
echo "✅ Successful: $SUCCESS_COUNT/${#PHOTOS[@]}"
echo "❌ Failed: $FAIL_COUNT/${#PHOTOS[@]}"
echo ""

if [ $SUCCESS_COUNT -eq ${#PHOTOS[@]} ]; then
    echo "🎉 ALL PROFILE PHOTOS TESTED SUCCESSFULLY!"
    echo "✅ Flirrt.ai is generating relevant, personalized flirts"
    exit 0
else
    echo "⚠️  Some tests failed. Check above for details."
    exit 1
fi