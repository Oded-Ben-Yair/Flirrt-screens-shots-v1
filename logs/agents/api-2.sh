#!/bin/bash
cd "/Users/macbookairm1/Flirrt-screens-shots-v1/FlirrtAI"

# Agent: api-2
# Focus: ai-integration
# Branch: api/ai
# Category: api

echo "🤖 Agent api-2 starting..."

# Set up git branch
git checkout -b "api/ai" 2>/dev/null || git checkout "api/ai"

# Run specific tests based on category
case "api" in
    ui)
        cd iOS
        if [ "ai-integration" == "keyboard-extension" ]; then
            # Priority 1: Fix keyboard API connection
            echo "🔧 Fixing keyboard API connection..."
            # Test keyboard functionality
            xcodebuild test \
                -scheme Flirrt \
                -destination 'platform=iOS Simulator,id=237F6A2D-72E4-49C2-B5E0-7B3F973C6814' \
                -only-testing:FlirrtTests/KeyboardExtensionTests \
                2>&1 | tee ../logs/agents/api-2.log
        fi
        ;;
    api)
        cd Backend
        npm test -- --testNamePattern="ai-integration" 2>&1 | tee ../logs/agents/api-2.log
        ;;
    perf)
        # Performance testing
        echo "📊 Running performance tests for ai-integration..."
        ;;
esac

echo "✅ Agent api-2 completed"
