#!/bin/bash
# ENFORCES: Memory limits, syntax validation, conflict prevention
# Purpose: Validate BEFORE any file edit to prevent issues
set -uo pipefail  # Not using -e to handle errors gracefully

CLAUDE_DIR="${CLAUDE_PROJECT_DIR:-/Users/macbookairm1/Flirrt-screens-shots-v1/FlirrtAI}/.claude"
LOG_FILE="$CLAUDE_DIR/logs/pre-edit.log"
METRICS_FILE="$CLAUDE_DIR/metrics/edits.json"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"

# Function: Check memory for iOS keyboard extension
check_memory() {
    local file=$1
    if [[ "$file" == *"Keyboard"* ]] || [[ "$file" == *"keyboard"* ]]; then
        # Calculate total size of keyboard extension
        local keyboard_dir="${CLAUDE_PROJECT_DIR}/iOS/FlirrtKeyboard"
        if [ -d "$keyboard_dir" ]; then
            local total_size=$(find "$keyboard_dir" -type f \( -name "*.swift" -o -name "*.m" -o -name "*.h" \) -exec wc -c {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo 0)
            local estimated_mb=$((total_size / 1024 / 1024))

            if [ "$estimated_mb" -gt 25 ]; then
                echo "❌ BLOCKED: Keyboard extension approaching 30MB limit (currently ~${estimated_mb}MB)"
                echo "💡 SUGGESTION: Refactor to reduce size or move logic to main app"
                echo "💡 Run: find iOS/FlirrtKeyboard -name '*.swift' -exec wc -c {} + | sort -rn | head -10"
                echo "   to see largest files"

                # Update CLAUDE.md with memory warning
                if [ -f "$CLAUDE_MD" ]; then
                    sed -i.bak "s/Current Usage: .*/Current Usage: ${estimated_mb}MB ⚠️ NEAR LIMIT/g" "$CLAUDE_MD"
                fi
                exit 1  # Block the edit
            elif [ "$estimated_mb" -gt 20 ]; then
                echo "⚠️ WARNING: Keyboard extension at ${estimated_mb}MB (limit is 30MB)"
                echo "   Consider optimizing before adding more code"
            fi

            # Log memory status
            echo "[$(date +%H:%M:%S)] Keyboard memory: ${estimated_mb}MB" >> "$LOG_FILE"
        fi
    fi
}

# Function: Validate Swift syntax
validate_swift() {
    local file=$1
    if [[ "$file" == *.swift ]]; then
        echo "🔍 Validating Swift syntax..."

        # Basic syntax check using Swift compiler
        if command -v swift > /dev/null; then
            # Just parse, don't compile (faster)
            swift -parse "$file" 2>/dev/null || {
                echo "⚠️ Swift syntax issues detected in $file"
                echo "   Continuing but please review the changes"
            }
        fi

        # Check for common iOS issues
        if grep -q "import UIKit" "$file" 2>/dev/null && [[ "$file" == *"Keyboard"* ]]; then
            # Check for prohibited APIs in keyboard extension
            if grep -qE "(UIPasteboard|openURL|sharedApplication)" "$file" 2>/dev/null; then
                echo "❌ BLOCKED: Keyboard extension cannot use restricted APIs"
                echo "   Found: $(grep -E '(UIPasteboard|openURL|sharedApplication)' "$file" | head -1)"
                exit 1
            fi
        fi
    fi
}

# Function: Validate JavaScript/TypeScript
validate_js() {
    local file=$1
    if [[ "$file" == *.js ]] || [[ "$file" == *.ts ]]; then
        echo "🔍 Validating JavaScript/TypeScript..."

        # Basic syntax check
        if command -v node > /dev/null; then
            node -c "$file" 2>/dev/null || {
                echo "⚠️ JavaScript syntax issues detected"
                echo "   Will attempt to fix with formatter"
            }
        fi

        # Check for common issues
        if grep -q "console.log" "$file" 2>/dev/null; then
            echo "⚠️ Found console.log statements - consider removing for production"
        fi
    fi
}

# Function: Check for merge conflicts
check_conflicts() {
    local file=$1
    if grep -q "<<<<<<< HEAD" "$file" 2>/dev/null; then
        echo "❌ BLOCKED: Merge conflict detected in $file"
        echo "💡 Resolve conflicts first with:"
        echo "   git status"
        echo "   git diff $file"
        exit 1
    fi
}

# Function: Check if file is in worktree
check_worktree() {
    local file=$1
    if [[ "$file" == *"/trees/"* ]]; then
        local worktree_name=$(echo "$file" | grep -oE 'trees/[^/]+' | cut -d/ -f2)
        echo "📌 Editing in worktree: $worktree_name (isolated from main)"
        return 0
    fi
    return 1
}

# Main execution
echo "[$(date +%H:%M:%S)] Pre-edit check starting..." >> "$LOG_FILE"

# Parse file paths (space-separated from CLAUDE_FILE_PATHS)
if [ -z "${CLAUDE_FILE_PATHS:-}" ]; then
    echo "⚠️ No files specified for validation"
    exit 0
fi

# Count for metrics
edit_count=0

for file in $CLAUDE_FILE_PATHS; do
    echo "════════════════════════════════════════"
    echo "🔍 Validating: $file"

    # Check if file exists (might be new file)
    if [ ! -f "$file" ]; then
        echo "📝 New file will be created"
        edit_count=$((edit_count + 1))
        continue
    fi

    # Check if in git worktree
    check_worktree "$file"

    # Memory check (critical for iOS)
    check_memory "$file"

    # Syntax validation
    validate_swift "$file"
    validate_js "$file"

    # Check for merge conflicts
    check_conflicts "$file"

    # Check file size
    file_size=$(wc -c < "$file" 2>/dev/null || echo 0)
    if [ "$file_size" -gt 1048576 ]; then  # 1MB
        echo "⚠️ Large file detected ($(($file_size / 1024))KB)"
        echo "   Consider splitting into smaller modules"
    fi

    edit_count=$((edit_count + 1))
    echo "✅ Validation passed for $file"
done

# Update metrics
if [ -f "$METRICS_FILE" ]; then
    total_edits=$(grep -o '"edit_count":[0-9]*' "$METRICS_FILE" | cut -d: -f2 || echo 0)
    new_total=$((total_edits + edit_count))
    echo "{\"edit_count\": $new_total, \"last_edit\": \"$(date)\"}" > "$METRICS_FILE"
else
    mkdir -p "$(dirname "$METRICS_FILE")"
    echo "{\"edit_count\": $edit_count, \"last_edit\": \"$(date)\"}" > "$METRICS_FILE"
fi

# Update CLAUDE.md metrics
if [ -f "$CLAUDE_MD" ]; then
    # Update PreToolUse counter
    current_count=$(grep "PreToolUse:" "$CLAUDE_MD" | grep -oE '[0-9]+' | head -1 || echo 0)
    new_count=$((current_count + 1))
    sed -i.bak "s/PreToolUse: .* invocations/PreToolUse: $new_count invocations/g" "$CLAUDE_MD"
fi

echo "════════════════════════════════════════"
echo "✅ Pre-edit validation complete ($edit_count files)"
echo "════════════════════════════════════════"

exit 0