#!/bin/bash
# CRITICAL: Attempts to recover from errors automatically
# Purpose: Handle failures gracefully and attempt fixes
set -uo pipefail

CLAUDE_DIR="${CLAUDE_PROJECT_DIR:-/Users/macbookairm1/Flirrt-screens-shots-v1/FlirrtAI}/.claude"
ERROR_LOG="$CLAUDE_DIR/logs/errors.log"
RECOVERY_LOG="$CLAUDE_DIR/logs/recovery.log"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
STATE_FILE="$CLAUDE_DIR/state/error-patterns.json"

# Capture error details from environment or arguments
ERROR_TYPE="${1:-unknown}"
ERROR_MSG="${2:-No message provided}"
ERROR_FILE="${3:-}"
ERROR_CONTEXT="${4:-}"

# Function: Log error with timestamp
log_error() {
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] ERROR: $ERROR_TYPE - $ERROR_MSG - $ERROR_FILE" >> "$ERROR_LOG"
    echo "[$timestamp] Recovery attempt for: $ERROR_TYPE" >> "$RECOVERY_LOG"
}

# Function: Update CLAUDE.md with error pattern
update_error_patterns() {
    if [ -f "$CLAUDE_MD" ]; then
        # Check if this error type already exists
        if grep -q "$ERROR_TYPE" "$CLAUDE_MD"; then
            # Increment counter
            old_count=$(grep "$ERROR_TYPE" "$CLAUDE_MD" | grep -oE '\[[0-9]+\]' | grep -oE '[0-9]+' | head -1 || echo 0)
            new_count=$((old_count + 1))
            sed -i.bak "s/$ERROR_TYPE: \[[0-9]*\]/$ERROR_TYPE: [$new_count]/g" "$CLAUDE_MD"
        else
            # Add new error type
            echo "- $ERROR_TYPE: [1] → Recovery attempted" >> "$CLAUDE_MD"
        fi

        # Update ErrorRecovery counter
        current_count=$(grep "ErrorRecovery:" "$CLAUDE_MD" | grep -oE '[0-9]+' | head -1 || echo 0)
        new_count=$((current_count + 1))
        sed -i.bak "s/ErrorRecovery: .* recoveries/ErrorRecovery: $new_count recoveries/g" "$CLAUDE_MD"
    fi
}

# Function: Attempt memory recovery
recover_memory() {
    echo "🧹 Attempting memory recovery..."

    # Clear cache
    if [ -d "$CLAUDE_DIR/cache" ]; then
        echo "   Clearing cache directory..."
        rm -rf "$CLAUDE_DIR/cache/"* 2>/dev/null || true
        echo "   ✅ Cache cleared"
    fi

    # Clear old logs
    if [ -d "$CLAUDE_DIR/logs" ]; then
        echo "   Removing old logs..."
        find "$CLAUDE_DIR/logs" -type f -mtime +7 -delete 2>/dev/null || true
        echo "   ✅ Old logs removed"
    fi

    # For iOS keyboard extension memory issues
    if [[ "$ERROR_FILE" == *"Keyboard"* ]]; then
        echo "   iOS Keyboard extension memory issue detected"
        echo "   Suggestions:"
        echo "   1. Remove unused imports"
        echo "   2. Minimize image assets"
        echo "   3. Use lazy loading"
        echo "   4. Move complex logic to main app"

        # Check for large assets
        if [ -d "${CLAUDE_PROJECT_DIR}/iOS/FlirrtKeyboard" ]; then
            echo "   Largest files in keyboard extension:"
            find "${CLAUDE_PROJECT_DIR}/iOS/FlirrtKeyboard" -type f -exec ls -lh {} \; 2>/dev/null | sort -rh -k5 | head -5
        fi
    fi

    echo "   ♻️ Restarting with reduced context..."
    return 0
}

# Function: Recover from MCP server failures
recover_mcp() {
    local server="${ERROR_MSG%%:*}"  # Extract server name
    echo "🔄 Attempting MCP recovery for: $server"

    # Kill existing process
    pkill -f "$server" 2>/dev/null || true
    sleep 1

    # Try to restart
    echo "   Attempting to restart $server..."
    (npx "@modelcontextprotocol/server-$server" > /dev/null 2>&1 &) || {
        echo "   ❌ Could not restart $server"
        echo "   📡 Falling back to native tools"

        # Update CLAUDE.md to show fallback mode
        if [ -f "$CLAUDE_MD" ]; then
            sed -i.bak "s/\[$server: .*\]/[$server: ❌ Fallback mode]/g" "$CLAUDE_MD"
        fi
        return 1
    }

    echo "   ✅ $server restarted"
    return 0
}

# Function: Recover from syntax errors
recover_syntax() {
    echo "🔧 Attempting syntax error recovery..."

    if [ -n "$ERROR_FILE" ] && [ -f "$ERROR_FILE" ]; then
        echo "   File: $ERROR_FILE"

        # Swift auto-fix
        if [[ "$ERROR_FILE" == *.swift ]]; then
            echo "   Running Swift auto-corrections..."
            # Try swiftlint autocorrect
            if command -v swiftlint > /dev/null; then
                swiftlint autocorrect --path "$ERROR_FILE" 2>/dev/null && {
                    echo "   ✅ SwiftLint corrections applied"
                } || echo "   ⚠️ SwiftLint could not fix all issues"
            fi

            # Try swift-format
            if command -v swift-format > /dev/null; then
                swift-format -i "$ERROR_FILE" 2>/dev/null && {
                    echo "   ✅ Swift-format corrections applied"
                } || true
            fi
        fi

        # JavaScript auto-fix
        if [[ "$ERROR_FILE" == *.js ]] || [[ "$ERROR_FILE" == *.ts ]]; then
            echo "   Running JavaScript auto-corrections..."
            # Try ESLint fix
            if command -v eslint > /dev/null; then
                eslint --fix "$ERROR_FILE" 2>/dev/null && {
                    echo "   ✅ ESLint corrections applied"
                } || echo "   ⚠️ ESLint could not fix all issues"
            fi

            # Try Prettier
            if command -v prettier > /dev/null; then
                prettier --write "$ERROR_FILE" 2>/dev/null && {
                    echo "   ✅ Prettier formatting applied"
                } || true
            fi
        fi
    else
        echo "   No file specified for syntax recovery"
    fi

    return 0
}

# Function: Recover from test failures
recover_test() {
    echo "🧪 Handling test failure..."

    # Re-run with verbose output for debugging
    if [[ "$ERROR_FILE" == *"/iOS/"* ]]; then
        echo "   Re-running iOS tests with verbose output..."
        (cd "${CLAUDE_PROJECT_DIR}/iOS" && swift test --verbose 2>&1 | head -50) || true
    elif [[ "$ERROR_FILE" == *"/Backend/"* ]]; then
        echo "   Re-running backend tests with verbose output..."
        (cd "${CLAUDE_PROJECT_DIR}/Backend" && npm test -- --verbose 2>&1 | head -50) || true
    fi

    echo "   💡 Test failure logged for manual review"
    echo "   Consider:"
    echo "   1. Updating test expectations"
    echo "   2. Fixing the implementation"
    echo "   3. Adding mock data"

    return 0
}

# Function: Recover from git conflicts
recover_git() {
    echo "🔀 Attempting git conflict recovery..."

    if [ -n "$ERROR_FILE" ] && [ -f "$ERROR_FILE" ]; then
        echo "   File with conflict: $ERROR_FILE"

        # Check conflict markers
        if grep -q "<<<<<<< HEAD" "$ERROR_FILE"; then
            echo "   Conflict markers detected"
            echo "   Options:"
            echo "   1. Accept current changes: git checkout --ours $ERROR_FILE"
            echo "   2. Accept incoming changes: git checkout --theirs $ERROR_FILE"
            echo "   3. Manual merge required"

            # Show conflict preview
            echo "   Conflict preview:"
            grep -A2 -B2 "<<<<<<< HEAD" "$ERROR_FILE" | head -20
        fi
    else
        # General git status check
        echo "   Checking git status..."
        (cd "${CLAUDE_PROJECT_DIR}" && git status --short) || true
    fi

    return 0
}

# Function: Recover from build failures
recover_build() {
    echo "🏗️ Attempting build recovery..."

    # iOS build recovery
    if [[ "$ERROR_MSG" == *"xcodebuild"* ]] || [[ "$ERROR_MSG" == *"swift"* ]]; then
        echo "   iOS build failure detected"
        echo "   Cleaning build artifacts..."
        if [ -d "${CLAUDE_PROJECT_DIR}/iOS/build" ]; then
            rm -rf "${CLAUDE_PROJECT_DIR}/iOS/build"
            echo "   ✅ Build directory cleaned"
        fi
        if [ -d "${CLAUDE_PROJECT_DIR}/iOS/.build" ]; then
            rm -rf "${CLAUDE_PROJECT_DIR}/iOS/.build"
            echo "   ✅ SPM build cache cleaned"
        fi
    fi

    # Node.js build recovery
    if [[ "$ERROR_MSG" == *"npm"* ]] || [[ "$ERROR_MSG" == *"node"* ]]; then
        echo "   Node.js build failure detected"
        echo "   Cleaning node_modules..."
        if [ -d "${CLAUDE_PROJECT_DIR}/Backend/node_modules" ]; then
            echo "   Running npm ci..."
            (cd "${CLAUDE_PROJECT_DIR}/Backend" && npm ci) || {
                echo "   Removing node_modules and retrying..."
                rm -rf "${CLAUDE_PROJECT_DIR}/Backend/node_modules"
                (cd "${CLAUDE_PROJECT_DIR}/Backend" && npm install) || true
            }
        fi
    fi

    return 0
}

# Main recovery logic
log_error

echo "════════════════════════════════════════"
echo "🔧 Error Recovery System Activated"
echo "Error Type: $ERROR_TYPE"
echo "Error Message: $ERROR_MSG"
echo "════════════════════════════════════════"

# Attempt recovery based on error type
case "$ERROR_TYPE" in
    "memory_overflow"|"memory_limit"|"out_of_memory")
        recover_memory
        ;;

    "mcp_failure"|"mcp_error"|"server_down")
        recover_mcp
        ;;

    "syntax_error"|"parse_error"|"compilation_error")
        recover_syntax
        ;;

    "test_failure"|"test_error")
        recover_test
        ;;

    "git_conflict"|"merge_conflict")
        recover_git
        ;;

    "build_failure"|"build_error")
        recover_build
        ;;

    "network_error"|"timeout")
        echo "🌐 Network error detected"
        echo "   Waiting 5 seconds before retry..."
        sleep 5
        echo "   Ready to retry operation"
        ;;

    *)
        echo "⚠️ Unknown error type: $ERROR_TYPE"
        echo "📋 Logging for manual review..."
        echo "   Check: $ERROR_LOG"
        ;;
esac

# Update error tracking
update_error_patterns

# Save error pattern for learning
if [ ! -f "$STATE_FILE" ]; then
    echo '{"error_patterns": {}}' > "$STATE_FILE"
fi

# Update state file with this error
timestamp=$(date +%s)
cat "$STATE_FILE" | jq ".error_patterns.\"$ERROR_TYPE\" += 1" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE" 2>/dev/null || true

echo "════════════════════════════════════════"
echo "✅ Recovery attempt complete"
echo "📊 Check logs at: $RECOVERY_LOG"
echo "════════════════════════════════════════"

# Exit with success to allow continuation
exit 0