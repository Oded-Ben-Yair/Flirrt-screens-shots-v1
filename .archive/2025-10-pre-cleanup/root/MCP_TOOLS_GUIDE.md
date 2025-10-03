# 🔧 MCP TOOLS COMPLETE GUIDE - FLIRRT.AI
**Created**: 2025-09-27
**Purpose**: Document MCP tools setup, usage, and workarounds

---

## 📱 iOS SIMULATOR MCP TOOL

### Current Status
- **Partially Working** - Screenshots work, UI interaction doesn't
- **Issue**: idb (iOS Debug Bridge) not installed
- **Impact**: Can't use tap, swipe, or type commands

### Working Commands
```bash
# These work without idb
mcp__ios-simulator__screenshot
mcp__ios-simulator__get_booted_sim_id
```

### Non-Working Commands (need idb)
```bash
# These require idb installation
mcp__ios-simulator__ui_describe_all
mcp__ios-simulator__ui_tap
mcp__ios-simulator__ui_type
mcp__ios-simulator__ui_swipe
mcp__ios-simulator__ui_describe_point
mcp__ios-simulator__ui_view
```

### How to Fix
```bash
# Install Facebook's idb
brew tap facebook/fb
brew install idb-companion
pip3 install fb-idb

# Verify installation
idb --version
```

### Workaround Without idb
Use xcrun simctl directly:
```bash
# Screenshots
xcrun simctl io booted screenshot file.png
xcrun simctl io "iPhone 16" screenshot file.png

# App control
xcrun simctl launch booted com.flirrt.app
xcrun simctl terminate booted com.flirrt.app

# Permissions
xcrun simctl privacy booted grant photos com.flirrt.app
xcrun simctl privacy booted grant microphone com.flirrt.app

# Deep links
xcrun simctl openurl booted "flirrt://test"

# Settings
xcrun simctl ui booted appearance dark
```

---

## 🧠 MEMORY BANK MCP TOOL

### Status: ✅ Working

### Available Commands
```python
mcp__memory-bank__create_memory  # Store information
mcp__memory-bank__retrieve_memory  # Recall information
mcp__memory-bank__search_memory  # Search stored data
mcp__memory-bank__list_memories  # List all memories
mcp__memory-bank__delete_memory  # Remove memory
```

### Best Practices
- Store session achievements
- Save error solutions
- Track API response patterns
- Remember file paths and commands

---

## 🤔 SEQUENTIAL THINKING MCP TOOL

### Status: ✅ Working

### Usage
```python
mcp__sequential-thinking__sequentialthinking
# Helps break down complex problems step-by-step
```

### When to Use
- Complex debugging
- Multi-step implementations
- Planning architecture changes
- Analyzing performance issues

---

## 📚 CONTEXT7 MCP TOOL

### Status: ✅ Working

### Commands
```python
mcp__context7__resolve-library-id  # Find library docs
mcp__context7__get-library-docs  # Get documentation
```

### Useful For
- SwiftUI documentation
- Node.js API references
- React Native docs
- Framework documentation

---

## 🎯 TASK TOOL (PARALLEL AGENTS)

### Status: ✅ Working

### Available Agent Types
- `general-purpose` - Research and multi-step tasks
- `statusline-setup` - Configure status line
- `output-style-setup` - Create output styles

### Usage Example
```python
Task(
    description="Fix timeout issue",
    prompt="Analyze and fix the 25-second timeout in circuitBreaker.js",
    subagent_type="general-purpose"
)
```

### Best Practices
1. Use for complex searches
2. Run multiple agents in parallel
3. Provide detailed prompts
4. Specify expected output

---

## 🔍 COMMON MCP TOOL PATTERNS

### Pattern 1: Simulator Control Without idb
```bash
# Since MCP tools don't work, use this pattern:
# 1. Take screenshot with MCP
mcp__ios-simulator__screenshot output_path="test.png"

# 2. Control app with xcrun
xcrun simctl launch booted com.flirrt.app

# 3. Take another screenshot
mcp__ios-simulator__screenshot output_path="test2.png"
```

### Pattern 2: Parallel Testing
```python
# Run multiple tests simultaneously
[
    Task("Test API", "Test flirt generation", "general-purpose"),
    Task("Check logs", "Analyze server logs", "general-purpose"),
    Task("Monitor performance", "Check response times", "general-purpose")
]
```

### Pattern 3: Documentation Search
```python
# When stuck with SwiftUI
mcp__context7__resolve-library-id libraryName="SwiftUI"
mcp__context7__get-library-docs context7CompatibleLibraryID="/apple/swiftui"
```

---

## ⚠️ TROUBLESHOOTING MCP TOOLS

### Issue: "spawn idb ENOENT"
**Cause**: idb not installed
**Fix**: Install idb or use xcrun simctl

### Issue: MCP tool timeout
**Cause**: Tool taking too long
**Fix**: Use background execution or split into smaller tasks

### Issue: Permission denied
**Cause**: macOS security
**Fix**: Grant terminal full disk access in System Settings

---

## 📝 MCP TOOLS CHECKLIST FOR NEXT SESSION

### Immediate Actions
- [ ] Check if idb is installed: `which idb`
- [ ] If not, decide whether to install (optional)
- [ ] Continue using xcrun simctl as primary tool

### MCP Tools to Use
- [x] screenshot - For visual proof
- [x] Task - For parallel execution
- [x] context7 - For documentation
- [x] memory-bank - For storing solutions

### MCP Tools to Avoid (until idb installed)
- [ ] ui_describe_all
- [ ] ui_tap
- [ ] ui_type
- [ ] ui_swipe
- [ ] ui_view

---

## 🚀 QUICK REFERENCE

### Take Screenshot
```bash
# With MCP (works)
mcp__ios-simulator__screenshot output_path="proof.png"

# Without MCP (always works)
xcrun simctl io booted screenshot proof.png
```

### Control App
```bash
# Launch
xcrun simctl launch booted com.flirrt.app

# Terminate
xcrun simctl terminate booted com.flirrt.app

# Install
xcrun simctl install booted path/to/Flirrt.app
```

### Get Info
```bash
# App container
xcrun simctl get_app_container booted com.flirrt.app

# Device list
xcrun simctl list devices

# Booted devices
xcrun simctl list | grep Booted
```

---

*Remember: MCP tools are helpful but not required. xcrun simctl is more reliable and always available!*