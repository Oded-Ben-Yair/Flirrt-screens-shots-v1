# 🎯 CONVERSATION CONTEXT IMPLEMENTATION - CLAUDE-CODE ORCHESTRATION PROMPT

## 📋 MISSION

Implement the conversation context feature for Vibe8.AI using **multi-agent orchestration** with Anthropic's sub-agent pattern. This is the killer feature that makes users want to provide more screenshots for better AI suggestions.

---

## 🏗️ MULTI-AGENT ORCHESTRATION STRATEGY

**You are the Lead Orchestrator.** Your job is to coordinate 4 specialized sub-agents working in parallel:

### Agent Roles:

1. **Backend Agent** - Database, API, conversation context logic
2. **Frontend Agent** - iOS conversationID tracking, UI implementation  
3. **Testing Agent** - Create scenarios, run tests, validate quality
4. **Quality Agent** - Evaluate results, suggest improvements, iterate

### How to Use Sub-Agents:

```typescript
// Example: Spawn sub-agents for parallel execution
const backendAgent = await spawnSubAgent({
  role: "Backend Developer",
  task: "Setup Supabase database and integrate conversationContext",
  context: "See CONVERSATION_CONTEXT_IMPLEMENTATION_PLAN.md Phase 2 Backend Tasks"
});

const frontendAgent = await spawnSubAgent({
  role: "iOS Developer", 
  task: "Implement conversationID tracking in ScreenshotDetectionManager",
  context: "See CONVERSATION_CONTEXT_IMPLEMENTATION_PLAN.md Phase 2 Frontend Tasks"
});

const testingAgent = await spawnSubAgent({
  role: "QA Engineer",
  task: "Create 5 new high-tension test scenarios",
  context: "See CONVERSATION_CONTEXT_IMPLEMENTATION_PLAN.md Phase 2 Testing Tasks"
});

// Wait for all agents to complete
await Promise.all([backendAgent, frontendAgent, testingAgent]);
```

---

## 📖 IMPLEMENTATION PLAN

**Pull the latest code:**
```bash
cd ~/Flirrt-screens-shots-v1
git pull origin main
```

**Read the complete plan:**
- File: `CONVERSATION_CONTEXT_IMPLEMENTATION_PLAN.md` (in repo)
- This contains the bulletproof 4-phase implementation plan
- Every technical detail is specified

---

## 🚀 EXECUTION PHASES

### PHASE 1: SETUP & RESEARCH (2 hours, Parallel)

**Spawn 3 sub-agents in parallel:**

#### Backend Agent:
- Setup Supabase database (free tier)
- Run migrations for conversation_sessions, screenshots, flirt_suggestions tables
- Configure DATABASE_URL in Render environment variables
- Test database connection
- Analyze existing conversationContext.js code

#### Frontend Agent:
- Research iOS App Groups best practices for conversationID storage
- Analyze ScreenshotDetectionManager.swift current flow
- Plan where to inject conversationID tracking
- Document Darwin notification payload structure

#### Testing Agent:
- Analyze existing chat scenarios (scenario_01 through scenario_05)
- Extract conversation flow patterns
- Identify what makes good multi-screenshot context
- Document gaps in current test coverage

**Checkpoint:** Report completion of Phase 1, share findings

---

### PHASE 2: CORE IMPLEMENTATION (4 hours, Parallel)

**Spawn 3 sub-agents in parallel:**

#### Backend Agent:

**Task 1:** Integrate conversationContext with aiOrchestrator
- File: `Backend/services/aiOrchestrator.js`
- Add conversationContext require
- Modify `analyzeAndGenerateFlirts()` function
- Add session management
- Add conversation history retrieval
- Add context prompt building
- Add "needsMoreContext" detection logic
- See implementation plan for complete code

**Task 2:** Enhance GPT-4O system prompt
- Add conversation context instructions
- Add incomplete conversation detection
- Add missing context identification
- Return structured JSON with context metadata

**Task 3:** Update API endpoint
- File: `Backend/routes/flirts.js`
- Accept conversationID parameter
- Pass conversationID to aiOrchestrator
- Return context metadata in response

#### Frontend Agent:

**Task 1:** Implement conversationID tracking
- File: `iOS/Flirrt/Services/ScreenshotDetectionManager.swift`
- Add conversationID property
- Add conversation timeout logic (30 minutes)
- Implement `getOrCreateConversationID()` method
- Save conversationID to App Groups
- Pass conversationID to API requests

**Task 2:** Handle context requests
- Add `handleContextRequest()` method
- Show notification when more context needed
- Display context message to user

#### Testing Agent:

**Task 1:** Create 5 new high-tension scenarios
- Scenario 06: Late Night Flirting → Hookup
- Scenario 07: First Date Planning → Sealing Deal
- Scenario 08: Post-Match → Aggressive Opener
- Scenario 09: Slow Burn → Escalation
- Scenario 10: Resistance Handling → Persistence

Each scenario needs:
- 6 screenshots showing conversation progression
- validation.txt file with conversation flow
- High sexual tension and date-pushing

**Checkpoint:** Report completion of Phase 2, demonstrate working integration

---

### PHASE 3: UI & GAMIFICATION (3 hours, Parallel)

**Spawn 3 sub-agents in parallel:**

#### Backend Agent:

**Task 1:** Enhance "needsMoreContext" logic
- Analyze message timestamps
- Detect conversation references
- Identify topic changes
- Calculate conversation completeness score

**Task 2:** Add gamification to API response
- Add progress tracking (2/3 screenshots)
- Add unlock messages
- Add context score (0-1 scale)
- Add achievement triggers

#### Frontend Agent:

**Task 1:** Build context request UI in keyboard
- File: `iOS/FlirrtKeyboard/KeyboardViewController.swift`
- Create progress banner view
- Add progress bar animation
- Add context message label
- Add "Take Another Screenshot" button
- Add deep link to main app

**Task 2:** Add gamification visual elements
- Progress ring animation
- Confetti effect at 3/3 screenshots
- Badge system
- Quality score visualization

#### Testing Agent:

**Task 1:** Test all 10 scenarios
- Test each with 1, 2, and 3 screenshots
- Validate context understanding improves
- Document quality improvements
- Create test results matrix

**Checkpoint:** Report completion of Phase 3, demonstrate UI working

---

### PHASE 4: ITERATION TO PERFECTION (3 hours, Sequential)

**Spawn Quality Agent:**

#### Quality Agent:

**Task 1:** Comprehensive quality testing
- Test all 10 scenarios with 1, 2, 3 screenshots
- Evaluate each on 7 metrics:
  1. Context Accuracy (references specific details)
  2. Progression (moves toward date/hookup)
  3. Sexual Tension (appropriate escalation)
  4. Personalization (uses names, interests)
  5. Originality (avoids clichés)
  6. Effectiveness (likely to get response)
  7. Context Improvement (quality increase with more screenshots)

**Task 2:** Use GPT-4O as judge
- Create evaluation prompt
- Score each suggestion 0-10 on each metric
- Calculate average scores
- Identify patterns in low-scoring suggestions

**Task 3:** Iterative improvement
- Adjust GPT-4O system prompt based on findings
- Adjust Grok-4 Fast prompt based on findings
- Re-test all scenarios
- Repeat until all scenarios score 8.5+/10

**Task 4:** Edge case testing
- Very short conversations (2-3 messages)
- Very long conversations (50+ messages)
- Multiple topics in one conversation
- Screenshots taken out of order
- Duplicate screenshots

**Checkpoint:** Report final quality scores, confirm all criteria met

---

## ✅ SUCCESS CRITERIA

### Functional Requirements:
- [ ] Database stores conversation history
- [ ] API accepts and tracks conversationID
- [ ] Frontend generates and persists conversationID
- [ ] AI requests more context when needed
- [ ] Keyboard displays context request UI
- [ ] Gamification elements working

### Quality Requirements:
- [ ] All 10 scenarios score 8.5+/10
- [ ] Context accuracy: 90%+ (references specific details)
- [ ] Date-pushing: 100% (every suggestion includes date invitation)
- [ ] Sexual tension: 85%+ (appropriate escalation)
- [ ] Improvement with context: 20%+ quality increase from 1→3 screenshots

### Performance Requirements:
- [ ] API latency: <15s with 3 screenshots
- [ ] Database queries: <100ms
- [ ] Frontend conversationID lookup: <10ms

---

## 🎯 ANTHROPIC BEST PRACTICES TO APPLY

Based on "How we built our multi-agent research system":

1. **Think like your agents** - Simulate the full flow before implementing
2. **Teach agents how to delegate** - Give clear task boundaries
3. **Scale effort to complexity** - Simple conversations need less context
4. **Tool design is critical** - Database schema must support efficient queries
5. **Let agents improve themselves** - Use GPT-4O to suggest prompt improvements
6. **Start wide, then narrow** - Broad context first, then specific details
7. **Guide thinking process** - Use extended thinking for planning
8. **Parallel execution** - Multiple screenshots analyzed simultaneously

---

## 📊 REPORTING REQUIREMENTS

After each phase, report:

1. **Completion Status** - What was accomplished
2. **Code Changes** - Files modified, key changes made
3. **Test Results** - What was tested, results
4. **Blockers** - Any issues encountered
5. **Next Steps** - What's needed for next phase

---

## 🚨 CRITICAL NOTES

1. **This is the killer feature** - Take extra care with quality
2. **Test thoroughly** - Don't skip testing steps
3. **Iterate to perfection** - Don't settle for "good enough"
4. **Use parallel execution** - Leverage sub-agents for speed
5. **Consult LLMs** - Use GPT-4O/Grok-4 for advice when stuck
6. **Document everything** - Future agents may need to understand this

---

## 🎓 RESOURCES

- **Implementation Plan:** `CONVERSATION_CONTEXT_IMPLEMENTATION_PLAN.md`
- **Existing Code:** `Backend/services/conversationContext.js`
- **Test Scenarios:** `/upload/flirrt_test_files/chat_scenarios/`
- **Anthropic Guide:** https://www.anthropic.com/engineering/built-multi-agent-research-system

---

## 🚀 START COMMAND

```bash
# Pull latest code
cd ~/Flirrt-screens-shots-v1
git pull origin main

# Read implementation plan
cat CONVERSATION_CONTEXT_IMPLEMENTATION_PLAN.md

# Begin Phase 1 with parallel sub-agents
# (Use your sub-agent orchestration capabilities)
```

---

## 💬 COMMUNICATION

Report back after each phase with:
- ✅ What's complete
- 🧪 Test results
- 📊 Quality scores
- ⚠️ Any issues
- ⏭️ Ready for next phase

---

**LET'S BUILD THE KILLER FEATURE! 🚀**

Remember: This is what makes Vibe8.AI special. Users will WANT to provide more screenshots because they see the quality improve. Make it perfect!

