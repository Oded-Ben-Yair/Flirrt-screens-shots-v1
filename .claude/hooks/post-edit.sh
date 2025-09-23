#!/bin/bash
# ENFORCES: Code formatting, testing, documentation updates
# Purpose: Process AFTER every edit to ensure quality and track changes
set -uo pipefail

CLAUDE_DIR="${CLAUDE_PROJECT_DIR:-/Users/macbookairm1/Flirrt-screens-shots-v1/FlirrtAI}/.claude"
LOG_FILE="$CLAUDE_DIR/logs/post-edit.log"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
METRICS_FILE="$CLAUDE_DIR/metrics/performance.json"

echo "[$(date +%H:%M:%S)] Post-edit processing starting..." >> "$LOG_FILE"

# Function: Auto-format Swift code
format_swift() {
    local file=$1
    if [[ "$file" == *.swift ]]; then
        echo "🎨 Formatting Swift file..."

        # Try swiftformat first (preferred)
        if command -v swiftformat > /dev/null; then
            swiftformat "$file" --quiet 2>/dev/null && {
                echo "✅ Formatted with swiftformat"
            } || echo "⚠️ swiftformat failed, trying alternatives..."
        fi

        # Fallback to swift-format
        if command -v swift-format > /dev/null; then
            swift-format -i "$file" 2>/dev/null && {
                echo "✅ Formatted with swift-format"
            } || true
        fi

        # Basic cleanup if no formatters available
        if ! command -v swiftformat > /dev/null && ! command -v swift-format > /dev/null; then
            # At least fix basic whitespace
            sed -i.bak 's/[[:space:]]*$//' "$file"  # Remove trailing whitespace
            echo "📝 Basic whitespace cleanup applied"
        fi
    fi
}

# Function: Auto-format JavaScript/TypeScript
format_js() {
    local file=$1
    if [[ "$file" == *.js ]] || [[ "$file" == *.ts ]] || [[ "$file" == *.jsx ]] || [[ "$file" == *.tsx ]]; then
        echo "🎨 Formatting JavaScript/TypeScript..."

        # Try prettier first (preferred)
        if command -v prettier > /dev/null; then
            prettier --write "$file" 2>/dev/null && {
                echo "✅ Formatted with Prettier"
            } || echo "⚠️ Prettier failed"
        fi

        # Fallback to eslint --fix
        if command -v eslint > /dev/null; then
            eslint --fix "$file" 2>/dev/null && {
                echo "✅ Fixed with ESLint"
            } || true
        fi
    fi
}

# Function: Run relevant tests
run_tests() {
    local file=$1
    local test_passed=true

    # Swift tests for iOS files
    if [[ "$file" == *"/iOS/"* ]] && [[ "$file" == *.swift ]]; then
        if [[ "$file" == *"Test"* ]] || [[ "$file" == *"test"* ]]; then
            echo "🧪 Running iOS tests..."
            if [ -d "${CLAUDE_PROJECT_DIR}/iOS" ]; then
                (cd "${CLAUDE_PROJECT_DIR}/iOS" && swift test --filter "$(basename $file .swift)" 2>/dev/null) || {
                    echo "⚠️ Some tests failed - please review"
                    test_passed=false
                }
            fi
        fi
    fi

    # JavaScript tests for Backend files
    if [[ "$file" == *"/Backend/"* ]] && ([[ "$file" == *.js ]] || [[ "$file" == *.ts ]]); then
        echo "🧪 Running backend tests..."
        if [ -f "${CLAUDE_PROJECT_DIR}/Backend/package.json" ]; then
            (cd "${CLAUDE_PROJECT_DIR}/Backend" && npm test -- --testPathPattern="$(basename $file)" 2>/dev/null) || {
                echo "⚠️ Some tests failed - please review"
                test_passed=false
            }
        fi
    fi

    return $([ "$test_passed" = true ] && echo 0 || echo 1)
}

# Function: Update documentation
update_docs() {
    local file=$1
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    # Append to session learnings in CLAUDE.md
    if [ -f "$CLAUDE_MD" ]; then
        # Add learning entry
        echo "- [$timestamp]: Edited $(basename $file)" >> "$CLAUDE_MD"

        # Update PostToolUse counter
        current_count=$(grep "PostToolUse:" "$CLAUDE_MD" | grep -oE '[0-9]+' | head -1 || echo 0)
        new_count=$((current_count + 1))
        sed -i.bak "s/PostToolUse: .* invocations/PostToolUse: $new_count invocations/g" "$CLAUDE_MD"
    fi

    # Log file changes
    echo "[$timestamp] Modified: $file" >> "$LOG_FILE"
}

# Function: Git operations for worktrees
handle_git() {
    local file=$1

    # Check if in a git worktree
    if [[ "$file" == *"/trees/"* ]]; then
        local worktree_dir=$(echo "$file" | sed 's|/trees/[^/]*/.*|/trees/[^/]*|' | head -1)
        if [ -d "$worktree_dir/.git" ] || [ -f "$worktree_dir/.git" ]; then
            echo "📌 Staging in worktree..."
            (cd "$worktree_dir" && git add "$(realpath --relative-to="$worktree_dir" "$file")" 2>/dev/null) && {
                echo "✅ Staged in worktree: $(basename $worktree_dir)"
            } || echo "⚠️ Could not stage file"
        fi
    else
        # Regular git add if not in worktree
        if [ -d "${CLAUDE_PROJECT_DIR}/.git" ]; then
            (cd "${CLAUDE_PROJECT_DIR}" && git add "$(realpath --relative-to="${CLAUDE_PROJECT_DIR}" "$file")" 2>/dev/null) && {
                echo "✅ Staged in main repository"
            } || true
        fi
    fi
}

# Function: Check for common issues
check_issues() {
    local file=$1

    # Check for TODO comments
    if grep -q "TODO\|FIXME\|XXX\|HACK" "$file" 2>/dev/null; then
        echo "📝 Found TODO/FIXME comments:"
        grep -n "TODO\|FIXME\|XXX\|HACK" "$file" | head -3
    fi

    # Check for sensitive data
    if grep -qE "(api[_-]?key|password|secret|token)" "$file" 2>/dev/null; then
        echo "⚠️ WARNING: Possible sensitive data detected"
        echo "   Please ensure no credentials are hardcoded"
    fi

    # Check line length (Swift guideline: 100 chars)
    if [[ "$file" == *.swift ]]; then
        long_lines=$(awk 'length > 100 {count++} END {print count+0}' "$file")
        if [ "$long_lines" -gt 0 ]; then
            echo "📏 $long_lines lines exceed 100 characters"
        fi
    fi
}

# Function: Update performance metrics
update_metrics() {
    local file=$1
    local start_time=$2
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    if [ -f "$METRICS_FILE" ]; then
        # Parse existing metrics
        total_time=$(grep -o '"total_processing_time":[0-9]*' "$METRICS_FILE" | cut -d: -f2 || echo 0)
        file_count=$(grep -o '"files_processed":[0-9]*' "$METRICS_FILE" | cut -d: -f2 || echo 0)
    else
        total_time=0
        file_count=0
    fi

    # Update metrics
    new_total_time=$((total_time + duration))
    new_file_count=$((file_count + 1))
    avg_time=$((new_total_time / new_file_count))

    mkdir -p "$(dirname "$METRICS_FILE")"
    cat > "$METRICS_FILE" << EOF
{
  "total_processing_time": $new_total_time,
  "files_processed": $new_file_count,
  "average_time": $avg_time,
  "last_file": "$(basename $file)",
  "last_duration": $duration,
  "timestamp": "$(date)"
}
EOF
}

# Main processing loop
if [ -z "${CLAUDE_FILE_PATHS:-}" ]; then
    echo "⚠️ No files to process"
    exit 0
fi

START_TIME=$(date +%s)
processed_count=0

for file in $CLAUDE_FILE_PATHS; do
    echo "════════════════════════════════════════"
    echo "📝 Processing: $file"

    # Skip if file doesn't exist
    if [ ! -f "$file" ]; then
        echo "⚠️ File not found, skipping"
        continue
    fi

    # Auto-format based on file type
    format_swift "$file"
    format_js "$file"

    # Run tests if available
    run_tests "$file" || true

    # Check for common issues
    check_issues "$file"

    # Update documentation
    update_docs "$file"

    # Handle git operations
    handle_git "$file"

    processed_count=$((processed_count + 1))
    echo "✅ Processing complete for $file"
done

# Update metrics
if [ "$processed_count" -gt 0 ]; then
    update_metrics "$file" "$START_TIME"
fi

# Update cache status in CLAUDE.md
if [ -f "$CLAUDE_MD" ] && [ -d "$CLAUDE_DIR/cache" ]; then
    cache_size=$(du -sh "$CLAUDE_DIR/cache" 2>/dev/null | cut -f1 || echo "0")
    cache_files=$(ls -1 "$CLAUDE_DIR/cache" 2>/dev/null | wc -l | tr -d ' ')
    sed -i.bak "s/Size: .*/Size: $cache_size ($cache_files files)/g" "$CLAUDE_MD"
fi

echo "════════════════════════════════════════"
echo "✅ Post-edit processing complete ($processed_count files)"
echo "════════════════════════════════════════"

exit 0