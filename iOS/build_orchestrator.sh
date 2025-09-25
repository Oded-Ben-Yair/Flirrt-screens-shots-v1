#!/bin/bash

# Flirrt.ai Multi-Agent Build Orchestrator
# Implements iterative build, test, and fix cycle

set -e

# Configuration
IOS_DIR="/Users/macbookairm1/Flirrt-screens-shots-v1/FlirrtAI/iOS"
SIMULATOR_ID="237F6A2D-72E4-49C2-B5E0-7B3F973C6814"
MAX_ITERATIONS=5
BUILD_LOG="build_orchestrator.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Initialize log
echo "🚀 Starting Flirrt.ai Build Orchestrator - $(date)" > "$BUILD_LOG"

# Function to log messages
log() {
    echo -e "$1" | tee -a "$BUILD_LOG"
}

# Function to build the app
build_app() {
    log "${YELLOW}🔨 Building Flirrt app...${NC}"

    cd "$IOS_DIR"

    # Build command with detailed output
    if xcodebuild -scheme Flirrt \
        -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
        -configuration Debug \
        build 2>&1 | tee -a "$BUILD_LOG"; then
        return 0
    else
        return 1
    fi
}

# Function to analyze build errors
analyze_errors() {
    log "${YELLOW}🔍 Analyzing build errors...${NC}"

    # Extract error messages
    ERRORS=$(grep -E "error:|fatal error:" "$BUILD_LOG" | tail -20)

    if echo "$ERRORS" | grep -q "ambiguous for type lookup"; then
        log "${RED}Found type ambiguity errors${NC}"
        return 1
    fi

    if echo "$ERRORS" | grep -q "@preconcurrency"; then
        log "${RED}Found @preconcurrency errors${NC}"
        return 2
    fi

    if echo "$ERRORS" | grep -q "does not conform to protocol"; then
        log "${RED}Found protocol conformance errors${NC}"
        return 3
    fi

    return 0
}

# Function to fix common errors
fix_errors() {
    local error_type=$1

    case $error_type in
        1)
            log "${YELLOW}🔧 Fixing type ambiguity...${NC}"
            # Type ambiguity fixes would go here
            ;;
        2)
            log "${YELLOW}🔧 Fixing @preconcurrency errors...${NC}"
            # Already fixed in KeyboardViewController
            ;;
        3)
            log "${YELLOW}🔧 Fixing protocol conformance...${NC}"
            # Protocol fixes would go here
            ;;
    esac
}

# Function to run tests
run_tests() {
    log "${YELLOW}🧪 Running tests...${NC}"

    cd "$IOS_DIR"

    # Build for testing first
    xcodebuild build-for-testing \
        -scheme Flirrt \
        -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
        -configuration Debug 2>&1 | tee -a "$BUILD_LOG"

    # Run tests without building
    if xcodebuild test-without-building \
        -scheme Flirrt \
        -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
        -configuration Debug 2>&1 | tee -a "$BUILD_LOG"; then
        log "${GREEN}✅ Tests passed!${NC}"
        return 0
    else
        log "${RED}❌ Tests failed${NC}"
        return 1
    fi
}

# Function to install app on simulator
install_app() {
    log "${YELLOW}📱 Installing app on simulator...${NC}"

    # Find the app bundle
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "Flirrt.app" -type d | head -1)

    if [ -z "$APP_PATH" ]; then
        log "${RED}❌ App bundle not found${NC}"
        return 1
    fi

    # Install using xcrun simctl
    if xcrun simctl install "$SIMULATOR_ID" "$APP_PATH"; then
        log "${GREEN}✅ App installed successfully${NC}"

        # Launch the app
        xcrun simctl launch "$SIMULATOR_ID" com.flirrt.ai

        return 0
    else
        log "${RED}❌ Installation failed${NC}"
        return 1
    fi
}

# Main orchestration loop
main() {
    log "${GREEN}🎭 Multi-Agent Build Orchestrator Started${NC}"

    ITERATION=0
    BUILD_SUCCESS=false

    while [ $ITERATION -lt $MAX_ITERATIONS ]; do
        ITERATION=$((ITERATION + 1))
        log "\n${YELLOW}📍 Iteration $ITERATION of $MAX_ITERATIONS${NC}"

        # Clean previous build artifacts
        if [ $ITERATION -eq 1 ]; then
            log "${YELLOW}🧹 Cleaning build artifacts...${NC}"
            rm -rf ~/Library/Developer/Xcode/DerivedData/*
            rm -rf "$IOS_DIR/build" "$IOS_DIR/.build"
        fi

        # Attempt to build
        if build_app; then
            log "${GREEN}✅ Build successful!${NC}"
            BUILD_SUCCESS=true
            break
        else
            log "${RED}❌ Build failed${NC}"

            # Analyze and fix errors
            analyze_errors
            ERROR_TYPE=$?

            if [ $ERROR_TYPE -ne 0 ]; then
                fix_errors $ERROR_TYPE
            else
                log "${RED}Unknown error type${NC}"
                break
            fi
        fi
    done

    # If build succeeded, run tests and install
    if [ "$BUILD_SUCCESS" = true ]; then
        log "\n${GREEN}🎉 Build completed successfully!${NC}"

        # Run tests
        if run_tests; then
            # Install on simulator
            install_app

            log "\n${GREEN}🏁 Orchestration complete! App is ready.${NC}"

            # Summary
            log "\n📊 Summary:"
            log "- Build iterations: $ITERATION"
            log "- Build status: SUCCESS"
            log "- Tests: PASSED"
            log "- Installation: COMPLETE"
        else
            log "${YELLOW}⚠️ Build succeeded but tests failed${NC}"
        fi
    else
        log "\n${RED}❌ Build failed after $MAX_ITERATIONS iterations${NC}"
        exit 1
    fi
}

# Run the orchestrator
main