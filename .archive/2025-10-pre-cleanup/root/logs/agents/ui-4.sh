#!/bin/bash
cd "/Users/macbookairm1/Flirrt-screens-shots-v1/FlirrtAI"

# Agent: ui-4
# Focus: screenshot-capture
# Branch: ui/screenshot
# Category: ui

echo "🤖 Agent ui-4 starting..."

# Set up git branch
git checkout -b "ui/screenshot" 2>/dev/null || git checkout "ui/screenshot"

# Run specific tests based on category
case "ui" in
    ui)
        cd iOS
        if [ "screenshot-capture" == "keyboard-extension" ]; then
            # Priority 1: Fix keyboard API connection
            echo "🔧 Fixing keyboard API connection..."
            # Test keyboard functionality
            xcodebuild test \
                -scheme Flirrt \
                -destination 'platform=iOS Simulator,id=237F6A2D-72E4-49C2-B5E0-7B3F973C6814' \
                -only-testing:FlirrtTests/KeyboardExtensionTests \
                2>&1 | tee ../logs/agents/ui-4.log
        fi
        ;;
    api)
        cd Backend
        npm test -- --testNamePattern="screenshot-capture" 2>&1 | tee ../logs/agents/ui-4.log
        ;;
    perf)
        # Performance testing
        echo "📊 Running performance tests for screenshot-capture..."
        ;;
esac

echo "✅ Agent ui-4 completed"
