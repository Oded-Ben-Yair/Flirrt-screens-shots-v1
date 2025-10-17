# Infrastructure Health Check
<!-- This command validates the entire Claude Code infrastructure -->

## 🔍 Check Directory Structure
```bash
echo "📁 Checking .claude directory structure..."
for dir in hooks agents commands logs cache metrics health state; do
    if [ -d ".claude/$dir" ]; then
        echo "✅ .claude/$dir exists ($(ls -1 .claude/$dir 2>/dev/null | wc -l | tr -d ' ') files)"
    else
        echo "❌ .claude/$dir missing - creating..."
        mkdir -p ".claude/$dir"
    fi
done
```

## 📎 Check Hook Configuration
```bash
echo -e "\n📎 Checking hooks configuration..."
if [ -f ".claude/settings.json" ]; then
    hook_count=$(grep -c '"command"' .claude/settings.json)
    echo "✅ settings.json exists with $hook_count hooks configured"
else
    echo "❌ settings.json missing!"
fi

echo "🔧 Checking hook scripts..."
for hook in session-init pre-edit post-edit error-recovery; do
    if [ -f ".claude/hooks/$hook.sh" ] && [ -x ".claude/hooks/$hook.sh" ]; then
        echo "✅ $hook.sh is executable"
    else
        echo "❌ $hook.sh missing or not executable"
    fi
done
```

## 🤖 Check MCP Servers
```bash
echo -e "\n🤖 Checking MCP servers..."
for server in context7 github postgres filesystem; do
    if pgrep -f "$server" > /dev/null 2>&1; then
        echo "✅ $server is running (PID: $(pgrep -f "$server" | head -1))"
    else
        echo "⚠️ $server not running (will use fallback)"
    fi
done
```

## 🌳 Check Git Worktrees
```bash
echo -e "\n🌳 Checking git worktrees..."
if [ -d "trees" ]; then
    echo "Worktrees found:"
    for tree in trees/*; do
        if [ -d "$tree" ]; then
            branch=$(cd "$tree" && git branch --show-current 2>/dev/null || echo "detached")
            changes=$(cd "$tree" && git status --short 2>/dev/null | wc -l | tr -d ' ')
            echo "  ✅ $(basename $tree): branch $branch ($changes uncommitted changes)"
        fi
    done
else
    echo "⚠️ No worktrees directory (create with: mkdir trees)"
fi
```

## 📱 Check iOS Environment
```bash
echo -e "\n📱 Checking iOS environment..."
if command -v xcodebuild > /dev/null; then
    echo "✅ Xcode installed ($(xcodebuild -version | head -1))"

    # Check simulator
    if xcrun simctl list devices 2>/dev/null | grep -q Booted; then
        SIM_ID=$(xcrun simctl list devices | grep Booted | head -1 | grep -oE '[A-F0-9-]{36}')
        echo "✅ Simulator running: $SIM_ID"
    else
        echo "⚠️ No simulator running (boot with: xcrun simctl boot <device-id>)"
    fi

    # Check keyboard extension size
    if [ -d "iOS/FlirrtKeyboard" ]; then
        kb_size=$(du -sh iOS/FlirrtKeyboard 2>/dev/null | cut -f1)
        echo "📏 Keyboard extension size: $kb_size"
    fi
else
    echo "⚠️ Xcode not installed or not in PATH"
fi
```

## 🌐 Check Backend Server
```bash
echo -e "\n🌐 Checking backend server..."
if curl -s "http://localhost:3000/health" > /dev/null 2>&1; then
    echo "✅ Backend server is running"
    echo "   Test endpoint: curl http://localhost:3000/health"
else
    echo "❌ Backend server not running"
    echo "   Start with: cd Backend && npm start"
fi
```

## 💾 Check Cache Status
```bash
echo -e "\n💾 Checking cache..."
if [ -d ".claude/cache" ]; then
    cache_size=$(du -sh .claude/cache 2>/dev/null | cut -f1)
    cache_files=$(ls -1 .claude/cache 2>/dev/null | wc -l | tr -d ' ')
    echo "✅ Cache: $cache_size in $cache_files files"

    # Show cached files
    if [ "$cache_files" -gt 0 ]; then
        echo "   Cached items:"
        ls -la .claude/cache | tail -5
    fi
else
    echo "⚠️ No cache directory"
fi
```

## 📊 Check Metrics
```bash
echo -e "\n📊 Checking metrics..."
if [ -f ".claude/metrics/edits.json" ]; then
    edit_count=$(grep -o '"edit_count":[0-9]*' .claude/metrics/edits.json | cut -d: -f2 || echo 0)
    echo "✅ Edit count: $edit_count"
fi

if [ -f ".claude/metrics/performance.json" ]; then
    avg_time=$(grep -o '"average_time":[0-9]*' .claude/metrics/performance.json | cut -d: -f2 || echo 0)
    echo "✅ Average processing time: ${avg_time}s"
fi
```

## 📝 Check CLAUDE.md Status
```bash
echo -e "\n📝 Checking CLAUDE.md..."
if [ -f ".claude/CLAUDE.md" ]; then
    echo "✅ CLAUDE.md exists"

    # Extract key metrics
    session_id=$(grep "Session ID:" .claude/CLAUDE.md | cut -d: -f2- | tr -d ' ')
    last_update=$(grep "Last Updated:" .claude/CLAUDE.md | cut -d: -f2-)

    echo "   Session ID: $session_id"
    echo "   Last Updated:$last_update"
else
    echo "❌ CLAUDE.md missing!"
fi
```

## 🔬 Generate Health Report
```bash
echo -e "\n🔬 Generating health report..."
HEALTH_FILE=".claude/health/report-$(date +%Y%m%d-%H%M%S).json"

cat > "$HEALTH_FILE" << EOF
{
  "timestamp": "$(date)",
  "infrastructure": {
    "hooks_configured": $([ -f ".claude/settings.json" ] && echo "true" || echo "false"),
    "hooks_executable": $([ -x ".claude/hooks/session-init.sh" ] && echo "true" || echo "false"),
    "cache_enabled": $([ -d ".claude/cache" ] && echo "true" || echo "false"),
    "metrics_tracking": $([ -f ".claude/metrics/edits.json" ] && echo "true" || echo "false")
  },
  "environment": {
    "xcode_available": $(command -v xcodebuild > /dev/null && echo "true" || echo "false"),
    "simulator_running": $(xcrun simctl list devices 2>/dev/null | grep -q Booted && echo "true" || echo "false"),
    "backend_running": $(curl -s http://localhost:3000/health > /dev/null 2>&1 && echo "true" || echo "false")
  },
  "performance": {
    "cache_size": "$(du -sh .claude/cache 2>/dev/null | cut -f1 || echo "0")",
    "log_size": "$(du -sh .claude/logs 2>/dev/null | cut -f1 || echo "0")",
    "edit_count": $(grep -o '"edit_count":[0-9]*' .claude/metrics/edits.json 2>/dev/null | cut -d: -f2 || echo 0)
  }
}
EOF

echo "✅ Health report saved to: $HEALTH_FILE"
```

## 📋 Summary
```bash
echo -e "\n════════════════════════════════════════"
echo "📋 INFRASTRUCTURE HEALTH SUMMARY"
echo "════════════════════════════════════════"

# Count successes and warnings
success_count=$(grep -c "✅" /tmp/health-check.tmp 2>/dev/null || echo 0)
warning_count=$(grep -c "⚠️" /tmp/health-check.tmp 2>/dev/null || echo 0)
error_count=$(grep -c "❌" /tmp/health-check.tmp 2>/dev/null || echo 0)

echo "✅ Passed: $success_count checks"
echo "⚠️ Warnings: $warning_count issues"
echo "❌ Failed: $error_count critical items"

if [ "$error_count" -gt 0 ]; then
    echo -e "\n🔧 Run '.claude/hooks/session-init.sh' to fix issues"
else
    echo -e "\n🚀 Infrastructure is healthy and ready!"
fi

echo "════════════════════════════════════════"
```