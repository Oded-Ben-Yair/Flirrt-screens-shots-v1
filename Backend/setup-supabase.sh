#!/bin/bash
# Automated Supabase Setup Script for Vibe8.AI
# This script creates a Supabase project and configures the database

set -e

echo "🚀 Vibe8.AI Supabase Setup"
echo "=========================="
echo ""

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "📦 Installing Supabase CLI..."
    brew install supabase/tap/supabase
fi

# Login to Supabase
echo "🔐 Logging into Supabase..."
echo "Please follow the browser prompts to authenticate..."
supabase login

# Create new project
echo ""
echo "📋 Project Configuration"
read -p "Enter project name (default: vibe8-production): " PROJECT_NAME
PROJECT_NAME=${PROJECT_NAME:-vibe8-production}

read -p "Enter database password (min 12 chars): " -s DB_PASSWORD
echo ""

read -p "Enter region (default: us-east-1): " REGION
REGION=${REGION:-us-east-1}

echo ""
echo "🏗️  Creating Supabase project..."
supabase projects create "$PROJECT_NAME" \
  --db-password "$DB_PASSWORD" \
  --region "$REGION"

# Get project details
PROJECT_REF=$(supabase projects list | grep "$PROJECT_NAME" | awk '{print $1}')
echo "✅ Project created: $PROJECT_REF"

# Link local project
echo "🔗 Linking local project..."
supabase link --project-ref "$PROJECT_REF"

# Run migrations
echo "📊 Running database migrations..."
supabase db push

# Get connection details
echo ""
echo "🔑 Retrieving connection details..."
API_URL=$(supabase projects api-keys --project-ref "$PROJECT_REF" | grep "API URL" | awk '{print $3}')
ANON_KEY=$(supabase projects api-keys --project-ref "$PROJECT_REF" | grep "anon" | awk '{print $2}')
SERVICE_KEY=$(supabase projects api-keys --project-ref "$PROJECT_REF" | grep "service_role" | awk '{print $2}')

# Create .env configuration
echo ""
echo "📝 Creating environment configuration..."
cat > .env.supabase << EOF
# Supabase Configuration for Vibe8.AI
SUPABASE_URL=$API_URL
SUPABASE_ANON_KEY=$ANON_KEY
SUPABASE_SERVICE_KEY=$SERVICE_KEY
DATABASE_URL=postgresql://postgres:$DB_PASSWORD@db.$PROJECT_REF.supabase.co:5432/postgres
EOF

echo ""
echo "✅ Supabase setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Add these environment variables to Render:"
echo "   - SUPABASE_URL"
echo "   - SUPABASE_SERVICE_KEY"
echo "   - DATABASE_URL"
echo ""
echo "2. Copy from .env.supabase file"
echo ""
echo "3. Redeploy backend on Render"
echo ""
echo "🎉 Database is ready for production!"

