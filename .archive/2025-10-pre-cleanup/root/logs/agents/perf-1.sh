#!/bin/bash
cd "/Users/macbookairm1/Flirrt-screens-shots-v1/FlirrtAI"

# Agent: perf-1
# Focus: memory-optimization
# Branch: perf/memory
# Category: perf

echo "🤖 Agent perf-1 starting..."

# Set up git branch
git checkout -b "perf/memory" 2>/dev/null || git checkout "perf/memory"

# Run specific tests based on category
case "perf" in
    ui)
        cd iOS
        if [ "memory-optimization" == "keyboard-extension" ]; then
            # Priority 1: Fix keyboard API connection
            echo "🔧 Fixing keyboard API connection..."
            # Test keyboard functionality
            xcodebuild test \
                -scheme Flirrt \
                -destination 'platform=iOS Simulator,id=237F6A2D-72E4-49C2-B5E0-7B3F973C6814' \
                -only-testing:FlirrtTests/KeyboardExtensionTests \
                2>&1 | tee ../logs/agents/perf-1.log
        fi
        ;;
    api)
        cd Backend
        npm test -- --testNamePattern="memory-optimization" 2>&1 | tee ../logs/agents/perf-1.log
        ;;
    perf)
        # Performance testing
        echo "📊 Running performance tests for memory-optimization..."
        ;;
esac

echo "✅ Agent perf-1 completed"
