# 🎯 FLIRRT.AI CLAUDE CODE INFRASTRUCTURE
# Last Updated: 2025-09-23 15:35:00
# Session ID: [SESSION_START_HOOK_FILLS_THIS]
# Infrastructure Health: [HEALTH_CHECK_HOOK_UPDATES]

## 🚨 CRITICAL CONSTRAINTS (ENFORCED BY HOOKS)
- iOS Keyboard Extension: MAX 30MB (hook blocks at 25MB)
- API Response Time: <2 seconds (hook alerts at 1.5s)
- Parallel Agents: MAX 10 (queue others)
- Token Usage: 25000 per MCP response (auto-truncate)

## 🤖 ACTIVE INFRASTRUCTURE STATUS
### MCP Servers
- [ ] Context7: [STATUS_HOOK_UPDATES] - Fallback: WebSearch
- [ ] GitHub: [STATUS_HOOK_UPDATES] - Fallback: Bash git commands
- [ ] PostgreSQL: [STATUS_HOOK_UPDATES] - Fallback: Read SQL files
- [ ] FileSystem: [STATUS_HOOK_UPDATES] - Fallback: Native Read/Write

### Hooks Active
- PreToolUse: 0 invocations this session
- PostToolUse: 0 invocations this session
- UserPromptSubmit: 0 invocations this session
- ErrorRecovery: 0 recoveries this session

### Performance Metrics (Auto-Updated)
- Average Fix Time: [METRIC_HOOK_UPDATES]
- Memory Peak: [METRIC_HOOK_UPDATES]
- API Calls Saved by Cache: [METRIC_HOOK_UPDATES]
- Errors Prevented: [METRIC_HOOK_UPDATES]

## 🎬 MANDATORY WORKFLOW (Enforced by Hooks)

### EVERY Code Edit TRIGGERS:
1. pre-edit.sh → Validates syntax & memory
2. post-edit.sh → Formats, lints, tests
3. metrics.sh → Logs performance
4. If error → error-recovery.sh → Attempts fix

### EVERY Task TRIGGERS:
1. task-init.sh → Sets up isolated context
2. task-monitor.sh → Tracks progress
3. task-complete.sh → Merges results
4. If timeout → task-recovery.sh → Restarts with cache

### EVERY Session Start TRIGGERS:
1. infrastructure-check.sh → Validates all systems
2. cache-warm.sh → Preloads common data
3. context-load.sh → Restores previous state

## 🚀 COMMANDS (Auto-Complete with Tab)
/fix-keyboard → Launches specialized agent for keyboard fixes
/fix-screenshot → Launches specialized agent for screenshot
/fix-voice → Launches specialized agent for voice
/fix-onboarding → Launches specialized agent for onboarding
/parallel-fix → Launches ALL agents in parallel
/health-check → Validates entire infrastructure
/error-report → Shows all errors this session
/performance-report → Shows optimization opportunities

## 📊 CURRENT SESSION LEARNINGS (Auto-Added)
<!-- Hooks append learnings here -->
- [2025-09-23 15:35]: Infrastructure initialized

## 🔧 ERROR PATTERNS DETECTED (Auto-Added)
<!-- Hooks append patterns here -->

## 💾 CACHE STATUS
- Hits: 0
- Misses: 0
- Size: 0 MB

## 🎯 NEXT RECOMMENDED ACTION
Configure hooks and test infrastructure health

## 📱 iOS SPECIFIC CONSTRAINTS
### Keyboard Extension Memory Management
- Current Usage: [MEMORY_HOOK_UPDATES]
- Peak Usage: [MEMORY_HOOK_UPDATES]
- Available: [MEMORY_HOOK_UPDATES]
- Auto-cleanup triggers at: 25MB

### Swift/iOS Commands
- Build: `xcodebuild -project FlirrtXcode.xcodeproj -scheme Flirrt`
- Test: `swift test`
- Memory Check: `xcrun simctl get_app_container booted com.flirrt.keyboard`
- Simulator: `xcrun simctl boot 237F6A2D-72E4-49C2-B5E0-7B3F973C6814`

### Backend Commands
- Start: `cd Backend && npm start`
- Test: `cd Backend && npm test`
- Logs: `tail -f Backend/server.log`
- Health: `curl http://localhost:3000/health`

## 🏗️ PROJECT STRUCTURE
```
FlirrtAI/
├── .claude/           # Infrastructure (THIS)
├── iOS/               # Swift app & extensions
├── Backend/           # Node.js API
├── Agents/            # AI sub-agents
└── trees/            # Git worktrees (parallel work)
```

## 📝 ACTIVE FIXES TRACKING
- [ ] Keyboard API Connection (Priority 1)
- [ ] Screenshot Analysis (Priority 2)
- [ ] Voice Scripts UI (Priority 3)
- [ ] Onboarding Flow (Priority 4)

## 🔄 SESSION PERSISTENCE
Previous sessions data stored in: .claude/state/
Metrics accumulated in: .claude/metrics/
Errors logged in: .claude/logs/