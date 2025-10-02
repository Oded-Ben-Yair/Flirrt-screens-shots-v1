#!/bin/bash
cd "/Users/macbookairm1/Flirrt-screens-shots-v1/FlirrtAI"

# Agent: perf-2
# Focus: network-efficiency
# Branch: perf/network
# Category: perf

echo "🤖 Agent perf-2 starting..."

# Set up git branch
git checkout -b "perf/network" 2>/dev/null || git checkout "perf/network"

# Run specific tests based on category
case "perf" in
    ui)
        cd iOS
        if [ "network-efficiency" == "keyboard-extension" ]; then
            # Priority 1: Fix keyboard API connection
            echo "🔧 Fixing keyboard API connection..."
            # Test keyboard functionality
            xcodebuild test \
                -scheme Flirrt \
                -destination 'platform=iOS Simulator,id=237F6A2D-72E4-49C2-B5E0-7B3F973C6814' \
                -only-testing:FlirrtTests/KeyboardExtensionTests \
                2>&1 | tee ../logs/agents/perf-2.log
        fi
        ;;
    api)
        cd Backend
        npm test -- --testNamePattern="network-efficiency" 2>&1 | tee ../logs/agents/perf-2.log
        ;;
    perf)
        # Performance testing
        echo "📊 Running performance tests for network-efficiency..."
        ;;
esac

echo "✅ Agent perf-2 completed"
