#!/bin/bash
cd "/Users/macbookairm1/Flirrt-screens-shots-v1/FlirrtAI"

# Agent: api-1
# Focus: auth-system
# Branch: api/auth
# Category: api

echo "🤖 Agent api-1 starting..."

# Set up git branch
git checkout -b "api/auth" 2>/dev/null || git checkout "api/auth"

# Run specific tests based on category
case "api" in
    ui)
        cd iOS
        if [ "auth-system" == "keyboard-extension" ]; then
            # Priority 1: Fix keyboard API connection
            echo "🔧 Fixing keyboard API connection..."
            # Test keyboard functionality
            xcodebuild test \
                -scheme Flirrt \
                -destination 'platform=iOS Simulator,id=237F6A2D-72E4-49C2-B5E0-7B3F973C6814' \
                -only-testing:FlirrtTests/KeyboardExtensionTests \
                2>&1 | tee ../logs/agents/api-1.log
        fi
        ;;
    api)
        cd Backend
        npm test -- --testNamePattern="auth-system" 2>&1 | tee ../logs/agents/api-1.log
        ;;
    perf)
        # Performance testing
        echo "📊 Running performance tests for auth-system..."
        ;;
esac

echo "✅ Agent api-1 completed"
