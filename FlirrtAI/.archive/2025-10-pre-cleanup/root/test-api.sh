#!/bin/bash
# Test API responses for uniqueness and timing

echo "Testing Flirrt API - 3 unique calls with timing"
echo "================================================"

TIMESTAMP=$(date +%s)
RESULTS_FILE="api-test-results.txt"

> $RESULTS_FILE

for i in {1..3}; do
    echo -e "\nTest $i: Starting API call..."
    START_TIME=$(date +%s.%N)

    RESPONSE=$(curl -s -X POST http://localhost:3000/api/v1/flirts/generate_flirts \
        -H "Content-Type: application/json" \
        -H "X-Keyboard-Extension: true" \
        -d "{\"screenshot_id\": \"test-$TIMESTAMP-$i\", \"context\": \"test-context-$i\", \"tone\": \"playful\"}")

    END_TIME=$(date +%s.%N)
    DURATION=$(echo "$END_TIME - $START_TIME" | bc)

    echo "Response time: ${DURATION}s"
    echo "Test $i Response:" >> $RESULTS_FILE
    echo "Duration: ${DURATION}s" >> $RESULTS_FILE
    echo "$RESPONSE" >> $RESULTS_FILE
    echo "---" >> $RESULTS_FILE

    # Extract and display suggestion text
    SUGGESTION=$(echo "$RESPONSE" | jq -r '.data.suggestions[0].text' 2>/dev/null || echo "Error extracting suggestion")
    CACHED=$(echo "$RESPONSE" | jq -r '.data.cached' 2>/dev/null || echo "unknown")

    echo "Cached: $CACHED"
    echo "Suggestion: $SUGGESTION"
    echo ""

    sleep 2
done

echo "Results saved to: $RESULTS_FILE"