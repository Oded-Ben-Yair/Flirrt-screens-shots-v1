#!/bin/bash

# Flirrt.ai - Git History Cleanup
# Purpose: Remove secrets from git history using git-filter-repo
# CRITICAL: This rewrites git history - create backup first!

set -e

PROJECT_ROOT="/Users/macbookairm1/Flirrt-screens-shots-v1"
cd "$PROJECT_ROOT"

echo "🔒 Git History Cleanup - Removing Secrets"
echo "⚠️  WARNING: This will rewrite git history!"
echo ""

# Check if git-filter-repo is installed
if ! command -v git-filter-repo &> /dev/null; then
    echo "❌ git-filter-repo not installed"
    echo ""
    echo "Installing git-filter-repo..."
    brew install git-filter-repo
fi

# Create safety backup
BACKUP_BRANCH="backup/before-history-cleanup-$(date +%Y%m%d-%H%M%S)"
echo "📦 Creating safety backup: $BACKUP_BRANCH"
git branch "$BACKUP_BRANCH"

# Create safety tag
BACKUP_TAG="pre-cleanup-$(date +%Y%m%d-%H%M%S)"
echo "🏷️  Creating safety tag: $BACKUP_TAG"
git tag "$BACKUP_TAG"

echo ""
echo "✅ Backups created:"
echo "  Branch: $BACKUP_BRANCH"
echo "  Tag: $BACKUP_TAG"
echo ""
echo "To rollback: git reset --hard $BACKUP_TAG"
echo ""

# Create patterns file for git-filter-repo
PATTERNS_FILE="/tmp/flirrt-secrets-patterns.txt"
cat > "$PATTERNS_FILE" << 'EOF'
# xAI API Keys (Grok)
regex:xai-[A-Za-z0-9]{40,}==>REMOVED_XAI_KEY

# ElevenLabs API Keys
regex:sk_[A-Za-z0-9]{40,}==>REMOVED_ELEVENLABS_KEY

# Google Gemini API Keys
regex:AIza[A-Za-z0-9_-]{35}==>REMOVED_GEMINI_KEY

# GitHub Personal Access Tokens
regex:ghp_[A-Za-z0-9]{36}==>REMOVED_GITHUB_PAT

# OpenAI API Keys
regex:sk-proj-[A-Za-z0-9_-]{100,}==>REMOVED_OPENAI_KEY
EOF

echo "🔍 Created patterns file with 5 secret patterns"
echo ""
echo "Starting git-filter-repo... (this may take 1-2 minutes)"
echo ""

# Run git-filter-repo
git filter-repo --replace-text "$PATTERNS_FILE" --force

echo ""
echo "✅ Git history cleaned!"
echo ""
echo "⚠️  IMPORTANT NEXT STEPS:"
echo "  1. Verify secrets are gone: git log -p --all | grep -E 'xai-|sk_|AIza|ghp_'"
echo "  2. Add remote back: git remote add origin <your-repo-url>"
echo "  3. Force push: git push --force-with-lease"
echo ""
echo "If anything goes wrong:"
echo "  git reset --hard $BACKUP_TAG"
echo ""

# Cleanup
rm -f "$PATTERNS_FILE"
