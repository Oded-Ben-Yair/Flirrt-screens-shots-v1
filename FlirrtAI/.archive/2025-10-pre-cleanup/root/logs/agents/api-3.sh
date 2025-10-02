#!/bin/bash
cd "/Users/macbookairm1/Flirrt-screens-shots-v1/FlirrtAI"

# Agent: api-3
# Focus: data-validation
# Branch: api/validation
# Category: api

echo "🤖 Agent api-3 starting..."

# Set up git branch
git checkout -b "api/validation" 2>/dev/null || git checkout "api/validation"

# Run specific tests based on category
case "api" in
    ui)
        cd iOS
        if [ "data-validation" == "keyboard-extension" ]; then
            # Priority 1: Fix keyboard API connection
            echo "🔧 Fixing keyboard API connection..."
            # Test keyboard functionality
            xcodebuild test \
                -scheme Flirrt \
                -destination 'platform=iOS Simulator,id=237F6A2D-72E4-49C2-B5E0-7B3F973C6814' \
                -only-testing:FlirrtTests/KeyboardExtensionTests \
                2>&1 | tee ../logs/agents/api-3.log
        fi
        ;;
    api)
        cd Backend
        npm test -- --testNamePattern="data-validation" 2>&1 | tee ../logs/agents/api-3.log
        ;;
    perf)
        # Performance testing
        echo "📊 Running performance tests for data-validation..."
        ;;
esac

echo "✅ Agent api-3 completed"
