#!/bin/bash

echo "Masking secrets in all files..."

# Mask xAI API keys
find . -type f -name "*.js" -o -name "*.swift" -o -name "*.md" -o -name "*.json" -o -name ".env*" | while read file; do
    if [[ -f "$file" ]]; then
        # xAI keys
        sed -i '' 's/xai-[A-Za-z0-9]\{80,\}/xai-MASKED_API_KEY/g' "$file" 2>/dev/null
        # GitHub tokens
        sed -i '' 's/ghp_[A-Za-z0-9]\{36,\}/ghp_MASKED_TOKEN/g' "$file" 2>/dev/null
        # ElevenLabs keys
        sed -i '' 's/sk_[a-f0-9]\{48\}/sk_MASKED_ELEVENLABS_KEY/g' "$file" 2>/dev/null
        # OpenAI keys
        sed -i '' 's/sk-proj-[A-Za-z0-9_-]\{48,\}/sk-proj-MASKED_OPENAI_KEY/g' "$file" 2>/dev/null
    fi
done

echo "Creating .env.example..."
cat > Backend/.env.example << 'EOF'
# Server Configuration
PORT=3000
NODE_ENV=development

# API Keys - Replace with your actual keys
GROK_API_KEY=xai-YOUR_API_KEY_HERE
ELEVENLABS_API_KEY=sk_YOUR_API_KEY_HERE

# JWT Configuration
JWT_SECRET=your_jwt_secret_here
JWT_EXPIRES_IN=24h

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=flirrt_ai
DB_USER=postgres
DB_PASSWORD=postgres

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=

# API URLs
GROK_API_URL=https://api.x.ai/v1
ELEVENLABS_API_URL=https://api.elevenlabs.io/v1

# Upload Configuration
MAX_FILE_SIZE=10485760
UPLOAD_DIR=./uploads

# Rate Limiting
RATE_LIMIT_WINDOW=900000
RATE_LIMIT_MAX=30
EOF

echo "Secrets masked successfully!"