#!/bin/bash

# Flirrt.ai - Pre-Push Validation
# Purpose: Ensure no secrets in git history before pushing
# Best Practice: GitHub secret scanning compliance

set -e

echo "🔒 Pre-Push Validation - Checking for secrets..."

# Check if git-filter-repo is installed
if ! command -v git-filter-repo &> /dev/null; then
    echo "⚠️  git-filter-repo not installed"
    echo "  Install: brew install git-filter-repo"
    echo ""
fi

# Scan for potential secrets in recent commits
echo "🔍 Scanning recent commits for secrets..."

PATTERNS=(
    "xai-[A-Za-z0-9]{40,}"
    "sk_[A-Za-z0-9]{40,}"
    "AIza[A-Za-z0-9_-]{35}"
    "ghp_[A-Za-z0-9]{36}"
)

FOUND_SECRETS=0

for PATTERN in "${PATTERNS[@]}"; do
    if git log -p --all -S"$PATTERN" --regexp-ignore-case | grep -qE "$PATTERN"; then
        echo "❌ Found potential secret matching: $PATTERN"
        FOUND_SECRETS=$((FOUND_SECRETS + 1))
    fi
done

if [ $FOUND_SECRETS -gt 0 ]; then
    echo ""
    echo "🚫 PUSH BLOCKED: $FOUND_SECRETS secret pattern(s) found in git history"
    echo ""
    echo "To fix:"
    echo "  1. Run: FlirrtAI/scripts/clean-git-history.sh"
    echo "  2. Force push to remote: git push --force-with-lease"
    echo ""
    exit 1
else
    echo "✅ No secrets detected in git history"
    echo "✅ Safe to push to remote"
fi

# Check for large files
echo ""
echo "📦 Checking for large files..."
LARGE_FILES=$(git ls-files -z | xargs -0 du -h | awk '$1 ~ /M$/ { print $0 }' | sort -rh | head -n 5)

if [ -n "$LARGE_FILES" ]; then
    echo "⚠️  Large files found (consider Git LFS):"
    echo "$LARGE_FILES"
else
    echo "✅ No unusually large files"
fi

echo ""
echo "✅ Pre-push validation complete!"
