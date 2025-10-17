#!/bin/bash

# Flirrt.ai - Simulator Cleanup Automation
# Purpose: Clean up duplicate simulators and ensure single fresh simulator
# Best Practice: Aligned with Oct 2025 xcrun simctl standards

set -e

echo "🧹 Starting iOS Simulator Cleanup..."

# Get all booted simulators
BOOTED_SIMS=$(xcrun simctl list devices | grep "Booted" | grep -oE '\([A-F0-9-]{36}\)' | tr -d '()')

if [ -z "$BOOTED_SIMS" ]; then
    echo "✅ No booted simulators found"
else
    echo "📱 Found booted simulators:"
    echo "$BOOTED_SIMS"

    # Shutdown all but keep device info
    for UDID in $BOOTED_SIMS; do
        echo "  Shutting down $UDID..."
        xcrun simctl shutdown "$UDID" 2>/dev/null || true
    done
    echo "✅ All simulators shut down"
fi

# Clean up old data
echo "🗑️  Erasing old simulator data..."
xcrun simctl erase all

# Find iPhone 16 simulator (or latest iPhone)
IPHONE_16=$(xcrun simctl list devices available | grep "iPhone 16" | grep -v "Plus\|Pro" | head -n 1 | grep -oE '\([A-F0-9-]{36}\)' | tr -d '()')

if [ -z "$IPHONE_16" ]; then
    echo "⚠️  iPhone 16 not found, using latest iPhone..."
    IPHONE_16=$(xcrun simctl list devices available | grep "iPhone" | tail -n 1 | grep -oE '\([A-F0-9-]{36}\)' | tr -d '()')
fi

if [ -n "$IPHONE_16" ]; then
    echo "🚀 Booting fresh simulator: $IPHONE_16"
    xcrun simctl boot "$IPHONE_16"

    # Open Simulator.app
    open -a Simulator

    echo "✅ Simulator cleanup complete!"
    echo "📱 Active simulator: $IPHONE_16"
    echo ""
    echo "To install app:"
    echo "  xcrun simctl install $IPHONE_16 <path-to-Flirrt.app>"
else
    echo "❌ No iPhone simulator found"
    exit 1
fi
