#!/bin/bash

echo "🚀 Setting up Flirrt Backend..."

# Install dependencies
echo "📦 Installing Node.js dependencies..."
npm install

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    echo "⚠️ PostgreSQL is not installed. Please install it first."
    echo "   On macOS: brew install postgresql"
    exit 1
fi

# Create database if it doesn't exist
echo "🗄️ Creating database..."
createdb flirrt_ai 2>/dev/null || echo "Database already exists"

# Create database schema
echo "📊 Setting up database schema..."
cat > db/schema.sql << 'EOF'
-- Users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    apple_id VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255),
    full_name VARCHAR(255),
    voice_id VARCHAR(255),
    age_verified BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Screenshots table
CREATE TABLE IF NOT EXISTS screenshots (
    id VARCHAR(255) PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    image_url TEXT,
    analysis_status VARCHAR(50) DEFAULT 'pending',
    analysis_result JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Flirt suggestions table
CREATE TABLE IF NOT EXISTS flirt_suggestions (
    id VARCHAR(255) PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    screenshot_id VARCHAR(255) REFERENCES screenshots(id),
    text TEXT NOT NULL,
    tone VARCHAR(50),
    confidence DECIMAL(3,2),
    voice_available BOOLEAN DEFAULT false,
    used BOOLEAN DEFAULT false,
    rating INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Voice clones table
CREATE TABLE IF NOT EXISTS voice_clones (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    elevenlabs_voice_id VARCHAR(255),
    name VARCHAR(255),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Analytics table
CREATE TABLE IF NOT EXISTS analytics (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    event_type VARCHAR(100),
    event_data JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_screenshots_user_id ON screenshots(user_id);
CREATE INDEX IF NOT EXISTS idx_suggestions_user_id ON flirt_suggestions(user_id);
CREATE INDEX IF NOT EXISTS idx_suggestions_screenshot_id ON flirt_suggestions(screenshot_id);
CREATE INDEX IF NOT EXISTS idx_analytics_user_id ON analytics(user_id);
CREATE INDEX IF NOT EXISTS idx_analytics_event_type ON analytics(event_type);
EOF

# Apply schema
psql -d flirrt_ai -f db/schema.sql 2>/dev/null || echo "Schema already exists"

echo "✅ Backend setup complete!"
echo ""
echo "To start the server, run:"
echo "  npm start"
echo ""
echo "API will be available at:"
echo "  http://localhost:3000/api/v1"