#!/bin/bash

# Flirrt.ai - Build & Test Automation
# Purpose: Build iOS app with zero warnings target
# Best Practice: Swift 6 compliance, Oct 2025 standards

set -e

PROJECT_ROOT="/Users/macbookairm1/Flirrt-screens-shots-v1/FlirrtAI"
IOS_DIR="$PROJECT_ROOT/iOS"

cd "$IOS_DIR"

echo "🔨 Building Flirrt.ai iOS App..."
echo "Target: Zero warnings"
echo ""

# Find any available iPhone simulator
SIMULATOR=$(xcrun simctl list devices available | grep "iPhone" | grep -v "Plus\|Pro\|Max\|Air" | head -n 1 | sed 's/^[[:space:]]*//' | sed 's/ (.*//')

if [ -z "$SIMULATOR" ]; then
    echo "❌ No iPhone simulator found"
    exit 1
fi

echo "Using simulator: $SIMULATOR"

# Build for simulator
xcodebuild \
    -scheme Flirrt \
    -configuration Debug \
    -destination "platform=iOS Simulator,name=$SIMULATOR" \
    -derivedDataPath "$IOS_DIR/.build" \
    -quiet \
    clean build 2>&1 | tee /tmp/flirrt-build.log

# Parse warnings and errors
WARNINGS=$(grep -c "warning:" /tmp/flirrt-build.log || echo "0")
ERRORS=$(grep -c "error:" /tmp/flirrt-build.log || echo "0")

echo ""
echo "📊 Build Results:"
echo "  Errors: $ERRORS"
echo "  Warnings: $WARNINGS"
echo ""

if [ "$ERRORS" -gt 0 ]; then
    echo "❌ Build failed with $ERRORS error(s)"
    grep "error:" /tmp/flirrt-build.log
    exit 1
fi

if [ "$WARNINGS" -gt 5 ]; then
    echo "⚠️  Warning count ($WARNINGS) exceeds target (<5)"
    echo "  Top warnings:"
    grep "warning:" /tmp/flirrt-build.log | head -n 10
else
    echo "✅ Build succeeded with $WARNINGS warning(s) (target: <5)"
fi

# Find the built app
APP_PATH=$(find "$IOS_DIR/.build" -name "Flirrt.app" -type d | head -n 1)

if [ -n "$APP_PATH" ]; then
    echo ""
    echo "📱 App built at:"
    echo "  $APP_PATH"
    echo ""
    echo "To install on simulator:"
    echo "  xcrun simctl install booted \"$APP_PATH\""
fi

exit 0
