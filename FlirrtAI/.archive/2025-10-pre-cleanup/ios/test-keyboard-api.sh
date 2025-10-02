#!/bin/bash

echo "Testing keyboard API endpoints..."

# Test Fresh button API call
echo -e "\n1. Testing Fresh button (generate_flirts)..."
curl -X POST http://localhost:3000/api/v1/flirts/generate_flirts \
  -H "Content-Type: application/json" \
  -d '{
    "screenshot_id": "test-screenshot-id",
    "tone": "casual",
    "user_profile": {
      "style": "playful",
      "age": 25
    }
  }' | jq .

# Test Analyze button API call
echo -e "\n2. Testing Analyze button (conversation analysis)..."
curl -X POST http://localhost:3000/api/v1/flirts/generate_flirts \
  -H "Content-Type: application/json" \
  -d '{
    "tone": "analytical",
    "context": "conversation analysis",
    "user_profile": {
      "style": "thoughtful",
      "age": 25
    }
  }' | jq .

echo -e "\nAPI tests complete!"