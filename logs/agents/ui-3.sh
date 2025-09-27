#!/bin/bash
cd "/Users/macbookairm1/Flirrt-screens-shots-v1/FlirrtAI"

# Agent: ui-3
# Focus: onboarding-flow
# Branch: ui/onboarding
# Category: ui

echo "🤖 Agent ui-3 starting..."

# Set up git branch
git checkout -b "ui/onboarding" 2>/dev/null || git checkout "ui/onboarding"

# Run specific tests based on category
case "ui" in
    ui)
        cd iOS
        if [ "onboarding-flow" == "keyboard-extension" ]; then
            # Priority 1: Fix keyboard API connection
            echo "🔧 Fixing keyboard API connection..."
            # Test keyboard functionality
            xcodebuild test \
                -scheme Flirrt \
                -destination 'platform=iOS Simulator,id=237F6A2D-72E4-49C2-B5E0-7B3F973C6814' \
                -only-testing:FlirrtTests/KeyboardExtensionTests \
                2>&1 | tee ../logs/agents/ui-3.log
        fi
        ;;
    api)
        cd Backend
        npm test -- --testNamePattern="onboarding-flow" 2>&1 | tee ../logs/agents/ui-3.log
        ;;
    perf)
        # Performance testing
        echo "📊 Running performance tests for onboarding-flow..."
        ;;
esac

echo "✅ Agent ui-3 completed"
