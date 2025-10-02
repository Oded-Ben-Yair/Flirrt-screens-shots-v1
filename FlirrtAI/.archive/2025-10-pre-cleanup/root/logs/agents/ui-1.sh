#!/bin/bash
cd "/Users/macbookairm1/Flirrt-screens-shots-v1/FlirrtAI"

# Agent: ui-1
# Focus: keyboard-extension
# Branch: ui/keyboard
# Category: ui

echo "🤖 Agent ui-1 starting..."

# Set up git branch
git checkout -b "ui/keyboard" 2>/dev/null || git checkout "ui/keyboard"

# Run specific tests based on category
case "ui" in
    ui)
        cd iOS
        if [ "keyboard-extension" == "keyboard-extension" ]; then
            # Priority 1: Fix keyboard API connection
            echo "🔧 Fixing keyboard API connection..."
            # Test keyboard functionality
            xcodebuild test \
                -scheme Flirrt \
                -destination 'platform=iOS Simulator,id=237F6A2D-72E4-49C2-B5E0-7B3F973C6814' \
                -only-testing:FlirrtTests/KeyboardExtensionTests \
                2>&1 | tee ../logs/agents/ui-1.log
        fi
        ;;
    api)
        cd Backend
        npm test -- --testNamePattern="keyboard-extension" 2>&1 | tee ../logs/agents/ui-1.log
        ;;
    perf)
        # Performance testing
        echo "📊 Running performance tests for keyboard-extension..."
        ;;
esac

echo "✅ Agent ui-1 completed"
