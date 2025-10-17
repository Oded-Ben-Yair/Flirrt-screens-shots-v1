#!/bin/bash

curl -X POST 'http://localhost:3000/api/v1/flirts/generate_flirts' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer demo-token-12345' \
  -d '{
    "screenshot_id": "test-123",
    "image_data": "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==",
    "suggestion_type": "opener",
    "tone": "playful"
  }'
