# FLIRRT.AI TRANSFORMATION GUIDE FOR CLAUDE-CODE SONNET 4.5

**Date:** October 17, 2025  
**Target:** Transform Flirrt.AI MVP into Production-Ready Dating Wingman  
**Executor:** Claude Code Sonnet 4.5 with Agent SDK  
**Repository:** Oded-Ben-Yair/Flirrt-screens-shots-v1

---

## EXECUTIVE SUMMARY

This guide provides complete, step-by-step instructions for transforming the Flirrt.AI MVP into a sophisticated, AI-powered dating coach. You (Claude Code Sonnet 4.5) will use your advanced agentic capabilities, including subagents, checkpoints, and MCP integration, to execute this transformation.

**Critical Context:**
- You have **30+ hours of focus** capability (Sonnet 4.5)
- Use **checkpoints** at every major milestone
- Create **subagents** for parallel iOS/backend work
- All information is current as of **October 17, 2025**
- Target platform: **iOS 26** with **Liquid Glass** design
- Keyboard framework: **KeyboardKit 9.9**

---

## SECTION 1: ENVIRONMENT SETUP

### 1.1 Prerequisites Check

Before starting, verify:

```bash
# Check Xcode version (should be 26+)
xcodebuild -version

# Check Swift version (should be 6.3+)
swift --version

# Check Node.js version (should be 22+)
node --version

# Check if repository is cloned
cd /path/to/Flirrt-screens-shots-v1
```

### 1.2 Create Flirrt.AI Development Plugin

Create `.claude-plugin/flirrt-ai-dev.json`:

```json
{
  "name": "flirrt-ai-dev",
  "version": "1.0.0",
  "description": "Flirrt.AI comprehensive development plugin with specialized subagents",
  "agents": [
    {
      "name": "ios-architect",
      "description": "iOS development subagent specializing in Swift, SwiftUI, KeyboardKit 9.9, and iOS 26 Liquid Glass design",
      "systemPrompt": "You are an expert iOS developer with deep knowledge of Swift 6.3, SwiftUI, KeyboardKit 9.9, AVFoundation, and iOS 26 Liquid Glass design language. You understand keyboard extensions, App Groups, and iOS privacy/security best practices. You write clean, performant, and maintainable code."
    },
    {
      "name": "backend-architect",
      "description": "Backend development subagent specializing in Node.js, Express, AI orchestration, and database design",
      "systemPrompt": "You are an expert backend developer with deep knowledge of Node.js, Express.js, PostgreSQL, Redis, AI model orchestration (GPT-5, Gemini 2.5, Grok-4, Perplexity), and scalable API design. You understand conversation session management, caching strategies, and async job processing."
    },
    {
      "name": "ai-integration-specialist",
      "description": "AI integration subagent specializing in multi-LLM orchestration and prompt engineering",
      "systemPrompt": "You are an expert in AI model integration and prompt engineering. You understand the strengths of GPT-5 Pro (coaching/reasoning), Gemini 2.5 Pro (multi-image/2M context), Grok-4 (real-time trends), and Perplexity Sonar (research/citations). You design sophisticated prompt templates and multi-model orchestration strategies."
    },
    {
      "name": "qa-engineer",
      "description": "Testing and quality assurance subagent",
      "systemPrompt": "You are an expert QA engineer specializing in iOS and backend testing. You write comprehensive unit tests, integration tests, and E2E tests. You understand XCTest, Jest, and API testing best practices."
    }
  ],
  "mcpServers": [
    {
      "name": "xcode-build",
      "description": "Build and test Xcode projects",
      "command": "xcodebuild",
      "args": ["-project", "iOS/Flirrt.xcodeproj", "-scheme", "Flirrt", "-sdk", "iphonesimulator"]
    }
  ],
  "slashCommands": [
    {
      "name": "build-ios",
      "description": "Build iOS app in Xcode simulator",
      "command": "cd iOS && xcodebuild -project Flirrt.xcodeproj -scheme Flirrt -sdk iphonesimulator build"
    },
    {
      "name": "test-backend",
      "description": "Run backend tests",
      "command": "cd Backend && npm test"
    },
    {
      "name": "checkpoint-save",
      "description": "Save current progress as checkpoint",
      "command": "git add -A && git commit -m 'Checkpoint: [DESCRIBE]' && git tag checkpoint-$(date +%Y%m%d-%H%M%S)"
    }
  ],
  "hooks": [
    {
      "name": "pre-build",
      "description": "Validate code before building",
      "command": "./scripts/pre-build-check.sh"
    }
  ]
}
```

### 1.3 Install Plugin

```bash
/plugin install .claude-plugin/flirrt-ai-dev.json
```

### 1.4 Create Checkpoint Strategy

Create checkpoints at these milestones:
1. **CP-1:** After environment setup and dependency installation
2. **CP-2:** After KeyboardKit integration
3. **CP-3:** After multi-screenshot context implementation
4. **CP-4:** After voice UI enablement
5. **CP-5:** After coaching persona implementation
6. **CP-6:** After full testing suite completion

Use `/checkpoint-save` command at each milestone.

---

## SECTION 2: CRITICAL BUG FIXES (PRIORITY 1)

### 2.1 Fix KeyboardViewController Memory Leak

**File:** `iOS/FlirrtKeyboard/KeyboardViewController.swift`

**Issue:** CFNotification observer not removed, causing memory leak and potential crash.

**Fix:**

```swift
class KeyboardViewController: UIInputViewController {
    private var notificationName: CFNotificationName?
    
    deinit {
        // CRITICAL: Remove CFNotification observer to prevent memory leak
        if let name = notificationName {
            CFNotificationCenterRemoveObserver(
                CFNotificationCenterGetDarwinNotifyCenter(),
                Unmanaged.passUnretained(self).toOpaque(),
                name,
                nil
            )
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Store notification name for cleanup
        notificationName = CFNotificationName("com.flirrt.screenshot" as CFString)
        
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            screenshotCallback,
            notificationName!.rawValue,
            nil,
            .deliverImmediately
        )
    }
}
```

### 2.2 Remove Photo Library Access from Keyboard Extension

**File:** `iOS/FlirrtKeyboard/KeyboardViewController.swift`

**Issue:** Accessing Photos from keyboard extension violates privacy/sandbox rules and will cause App Store rejection.

**Fix:**

1. **Delete all PHPhotoLibrary code** from `KeyboardViewController.swift`
2. **Move screenshot detection to main app**
3. **Use App Groups to share data**

**New Architecture:**

```
Main App (Flirrt.AI)
  ├── Screenshot Detection (PHPhotoLibrary access here)
  ├── Image Processing
  └── Share via App Groups → Keyboard Extension reads sanitized data
```

**Implementation:**

```swift
// In Main App (ViewController.swift)
import Photos

class ScreenshotManager {
    static let shared = ScreenshotManager()
    private let appGroupID = "group.com.flirrt.shared"
    
    func detectAndProcessScreenshot() {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            
            // Fetch latest screenshot
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.fetchLimit = 1
            
            let screenshots = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            guard let latestScreenshot = screenshots.firstObject else { return }
            
            // Process and save to App Group
            self.processAndShare(asset: latestScreenshot)
        }
    }
    
    private func processAndShare(asset: PHAsset) {
        // Convert to image, upload to backend, save metadata to App Group
        let sharedDefaults = UserDefaults(suiteName: appGroupID)
        sharedDefaults?.set(/* screenshot metadata */, forKey: "latestScreenshot")
    }
}

// In Keyboard Extension (KeyboardViewController.swift)
// Remove ALL PHPhotoLibrary code
// Read from App Groups instead
let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt.shared")
if let screenshotData = sharedDefaults?.dictionary(forKey: "latestScreenshot") {
    // Use screenshot data
}
```

### 2.3 Fix APIClient Security Issues

**File:** `iOS/Flirrt/Services/APIClient.swift`

**Issues:**
1. Logging sensitive response data
2. Base64 encoding images (memory bloat)
3. Force-unwrapping (crash risk)

**Fixes:**

```swift
import Alamofire
import OSLog

class APIClient {
    static let shared = APIClient()
    private let logger = Logger(subsystem: "com.flirrt.api", category: "network")
    
    private init() {
        // Enforce singleton
    }
    
    // BEFORE (BAD):
    // print("REAL API ERROR: \(error)")
    // print("Response: \(response.data)")
    
    // AFTER (GOOD):
    func handleError(_ error: Error) {
        logger.error("API request failed: \(error.localizedDescription, privacy: .public)")
        // DO NOT log response data - may contain sensitive info
    }
    
    // BEFORE (BAD): Base64 encoding for images
    func generateFlirtsFromImage(imageData: Data) async throws -> FlirtResponse {
        let base64String = imageData.base64EncodedString() // Memory bloat!
        // ... send in JSON
    }
    
    // AFTER (GOOD): Multipart upload
    func generateFlirtsFromImage(imageData: Data) async throws -> FlirtResponse {
        return try await withCheckedThrowingContinuation { continuation in
            AF.upload(multipartFormData: { formData in
                formData.append(imageData, withName: "image", fileName: "screenshot.jpg", mimeType: "image/jpeg")
            }, to: "\(baseURL)/api/v1/flirts/analyze")
            .validate()
            .responseDecodable(of: FlirtResponse.self) { response in
                switch response.result {
                case .success(let data):
                    continuation.resume(returning: data)
                case .failure(let error):
                    self.handleError(error)
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // BEFORE (BAD): Force unwrapping
    let uidData = userId.data(using: .utf8)!
    
    // AFTER (GOOD): Safe unwrapping
    guard let uidData = userId.data(using: .utf8) else {
        throw APIError.encodingError
    }
}

enum APIError: Error {
    case encodingError
    case invalidResponse
    case unauthorized
}
```

**CHECKPOINT:** After completing all bug fixes, run `/checkpoint-save` with description "CP-1: Critical bug fixes completed"

---

## SECTION 3: KEYBOARDKIT INTEGRATION (PRIORITY 2)

### 3.1 Install KeyboardKit 9.9

**Add to `iOS/Flirrt.xcodeproj`:**

1. Open Xcode
2. File → Add Package Dependencies
3. Enter: `https://github.com/KeyboardKit/KeyboardKit`
4. Version: 9.9.0 or later
5. Add to both `Flirrt` and `FlirrtKeyboard` targets

### 3.2 Create New Keyboard View Controller

**File:** `iOS/FlirrtKeyboard/FlirrtKeyboardViewController.swift`

```swift
import KeyboardKit
import SwiftUI

class FlirrtKeyboardViewController: KeyboardInputViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Enable iOS 26 Liquid Glass design
        if #available(iOS 26.0, *) {
            setIsLiquidGlassEnabled(true)
        }
        
        // Setup Flirrt custom toolbar
        setupFlirrtToolbar()
        
        // Configure keyboard appearance
        setupKeyboardAppearance()
    }
    
    override func viewWillSetupKeyboardView() {
        super.viewWillSetupKeyboardView()
        
        // KeyboardKit will automatically provide QWERTY layout
        // We just need to add our custom toolbar on top
    }
    
    private func setupFlirrtToolbar() {
        // Create SwiftUI toolbar view
        let toolbarView = FlirrtToolbarView(
            onScreenshotTap: { [weak self] in
                self?.handleScreenshotAnalysis()
            },
            onRefreshTap: { [weak self] in
                self?.handleRefreshSuggestions()
            },
            onVoiceTap: { [weak self] in
                self?.handleVoiceMessage()
            }
        )
        
        // Add toolbar above keyboard
        let hostingController = UIHostingController(rootView: toolbarView)
        addChild(hostingController)
        view.addSubview(hostingController.view)
        
        // Layout constraints
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    private func setupKeyboardAppearance() {
        // Customize KeyboardKit appearance to match Flirrt branding
        // KeyboardKit 9.9 automatically handles Liquid Glass design for iOS 26+
    }
    
    private func handleScreenshotAnalysis() {
        // Deep link to main app for screenshot analysis
        // (Photo Library access must be in main app, not keyboard extension)
        if let url = URL(string: "flirrt://analyze-screenshot") {
            openURL(url)
        }
    }
    
    private func handleRefreshSuggestions() {
        // Trigger suggestion refresh
        NotificationCenter.default.post(name: .refreshSuggestions, object: nil)
    }
    
    private func handleVoiceMessage() {
        // Open voice message UI in main app
        if let url = URL(string: "flirrt://voice-message") {
            openURL(url)
        }
    }
    
    private func openURL(_ url: URL) {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                application.open(url)
                return
            }
            responder = responder?.next
        }
    }
}

// MARK: - Flirrt Toolbar View

struct FlirrtToolbarView: View {
    let onScreenshotTap: () -> Void
    let onRefreshTap: () -> Void
    let onVoiceTap: () -> Void
    
    @State private var suggestions: [String] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Suggestion chips (horizontally scrollable)
            if !suggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            SuggestionChip(text: suggestion) {
                                // Insert suggestion into text field
                                insertSuggestion(suggestion)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                }
                .frame(height: 40)
            }
            
            // Action buttons
            HStack(spacing: 16) {
                ToolbarButton(icon: "camera.fill", label: "Analyze", action: onScreenshotTap)
                ToolbarButton(icon: "arrow.clockwise", label: "Refresh", action: onRefreshTap)
                ToolbarButton(icon: "mic.fill", label: "Voice", action: onVoiceTap)
                Spacer()
            }
            .padding(.horizontal, 12)
            .frame(height: 40)
        }
        .background(Color(UIColor.systemBackground).opacity(0.95))
        .onReceive(NotificationCenter.default.publisher(for: .suggestionsUpdated)) { notification in
            if let newSuggestions = notification.object as? [String] {
                withAnimation {
                    suggestions = newSuggestions
                }
            }
        }
    }
    
    private func insertSuggestion(_ text: String) {
        // Insert text into text field
        // This will be handled by KeyboardKit's text document proxy
    }
}

struct SuggestionChip: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.blue.gradient)
                )
        }
    }
}

struct ToolbarButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(label)
                    .font(.system(size: 10))
            }
            .foregroundColor(.blue)
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let suggestionsUpdated = Notification.Name("suggestionsUpdated")
    static let refreshSuggestions = Notification.Name("refreshSuggestions")
}
```

### 3.3 Update Info.plist

**File:** `iOS/FlirrtKeyboard/Info.plist`

Update `NSExtensionPrincipalClass` to point to new view controller:

```xml
<key>NSExtension</key>
<dict>
    <key>NSExtensionAttributes</key>
    <dict>
        <key>IsASCIICapable</key>
        <false/>
        <key>PrefersRightToLeft</key>
        <false/>
        <key>PrimaryLanguage</key>
        <string>en-US</string>
        <key>RequestsOpenAccess</key>
        <true/>
    </dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.ui-services.keyboard</string>
    <key>NSExtensionPrincipalClass</key>
    <string>$(PRODUCT_MODULE_NAME).FlirrtKeyboardViewController</string>
</dict>
```

### 3.4 Test Keyboard Integration

```bash
/build-ios
```

**Manual Testing:**
1. Run app in simulator
2. Go to Settings → General → Keyboard → Keyboards → Add New Keyboard
3. Select "Flirrt"
4. Open any app with text input
5. Switch to Flirrt keyboard
6. Verify QWERTY layout appears
7. Verify Flirrt toolbar appears above keyboard

**CHECKPOINT:** After successful KeyboardKit integration, run `/checkpoint-save` with description "CP-2: KeyboardKit 9.9 integration completed"

---

## SECTION 4: MULTI-SCREENSHOT CONTEXT IMPLEMENTATION (PRIORITY 3)

### 4.1 Backend: Conversation Session Model

**File:** `Backend/models/ConversationSession.js`

```javascript
const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const ConversationSession = sequelize.define('ConversationSession', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  userId: {
    type: DataTypes.STRING,
    allowNull: false,
    index: true
  },
  title: {
    type: DataTypes.STRING,
    allowNull: true
  },
  status: {
    type: DataTypes.ENUM('active', 'archived', 'deleted'),
    defaultValue: 'active'
  },
  contextSummary: {
    type: DataTypes.TEXT,
    allowNull: true,
    comment: 'AI-generated summary of conversation context'
  },
  participantNames: {
    type: DataTypes.JSON,
    allowNull: true,
    comment: 'Names of people in the conversation'
  },
  conversationStage: {
    type: DataTypes.ENUM('initial', 'building_rapport', 'flirting', 'ready_for_date', 'dating'),
    defaultValue: 'initial'
  },
  metadata: {
    type: DataTypes.JSON,
    allowNull: true
  }
}, {
  timestamps: true,
  indexes: [
    { fields: ['userId', 'status'] },
    { fields: ['createdAt'] }
  ]
});

module.exports = ConversationSession;
```

**File:** `Backend/models/Screenshot.js`

```javascript
const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Screenshot = sequelize.define('Screenshot', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true
  },
  sessionId: {
    type: DataTypes.UUID,
    allowNull: false,
    references: {
      model: 'ConversationSessions',
      key: 'id'
    }
  },
  imageUrl: {
    type: DataTypes.STRING,
    allowNull: false
  },
  sequenceNumber: {
    type: DataTypes.INTEGER,
    allowNull: false,
    comment: 'Order of screenshot in conversation'
  },
  extractedText: {
    type: DataTypes.TEXT,
    allowNull: true,
    comment: 'OCR or AI-extracted text from screenshot'
  },
  analysisResult: {
    type: DataTypes.JSON,
    allowNull: true,
    comment: 'AI analysis of this screenshot'
  },
  metadata: {
    type: DataTypes.JSON,
    allowNull: true
  }
}, {
  timestamps: true,
  indexes: [
    { fields: ['sessionId', 'sequenceNumber'] }
  ]
});

module.exports = Screenshot;
```

### 4.2 Backend: Conversation API Endpoints

**File:** `Backend/routes/conversations.js`

```javascript
const express = require('express');
const router = express.Router();
const ConversationSession = require('../models/ConversationSession');
const Screenshot = require('../models/Screenshot');
const { authenticateToken } = require('../middleware/auth');
const { analyzeConversationContext } = require('../services/aiOrchestrator');

// Start new conversation session
router.post('/start', authenticateToken, async (req, res) => {
  try {
    const { title } = req.body;
    
    const session = await ConversationSession.create({
      userId: req.user.id,
      title: title || `Conversation ${new Date().toLocaleDateString()}`
    });
    
    res.json({
      success: true,
      session: {
        id: session.id,
        title: session.title,
        status: session.status,
        createdAt: session.createdAt
      }
    });
  } catch (error) {
    console.error('Error creating conversation session:', error);
    res.status(500).json({ success: false, error: 'Failed to create session' });
  }
});

// Add screenshot to session
router.post('/:sessionId/add-screenshot', authenticateToken, async (req, res) => {
  try {
    const { sessionId } = req.params;
    const { imageUrl } = req.body;
    
    // Verify session belongs to user
    const session = await ConversationSession.findOne({
      where: { id: sessionId, userId: req.user.id }
    });
    
    if (!session) {
      return res.status(404).json({ success: false, error: 'Session not found' });
    }
    
    // Get next sequence number
    const lastScreenshot = await Screenshot.findOne({
      where: { sessionId },
      order: [['sequenceNumber', 'DESC']]
    });
    
    const sequenceNumber = lastScreenshot ? lastScreenshot.sequenceNumber + 1 : 1;
    
    // Create screenshot record
    const screenshot = await Screenshot.create({
      sessionId,
      imageUrl,
      sequenceNumber
    });
    
    // Get total screenshot count
    const totalScreenshots = await Screenshot.count({ where: { sessionId } });
    
    res.json({
      success: true,
      screenshot: {
        id: screenshot.id,
        sequenceNumber: screenshot.sequenceNumber
      },
      contextCompleteness: calculateContextCompleteness(totalScreenshots),
      needsMoreContext: totalScreenshots < 3 // Suggest at least 3 screenshots for good context
    });
  } catch (error) {
    console.error('Error adding screenshot:', error);
    res.status(500).json({ success: false, error: 'Failed to add screenshot' });
  }
});

// Analyze conversation with full context
router.post('/:sessionId/analyze', authenticateToken, async (req, res) => {
  try {
    const { sessionId } = req.params;
    
    // Verify session belongs to user
    const session = await ConversationSession.findOne({
      where: { id: sessionId, userId: req.user.id }
    });
    
    if (!session) {
      return res.status(404).json({ success: false, error: 'Session not found' });
    }
    
    // Get all screenshots in order
    const screenshots = await Screenshot.findAll({
      where: { sessionId },
      order: [['sequenceNumber', 'ASC']]
    });
    
    if (screenshots.length === 0) {
      return res.status(400).json({ success: false, error: 'No screenshots in session' });
    }
    
    // Use Gemini 2.5 Pro for multi-image analysis (2M token context window)
    const analysis = await analyzeConversationContext({
      sessionId,
      screenshots: screenshots.map(s => s.imageUrl),
      previousContext: session.contextSummary,
      conversationStage: session.conversationStage
    });
    
    // Update session with analysis results
    await session.update({
      contextSummary: analysis.contextSummary,
      participantNames: analysis.participantNames,
      conversationStage: analysis.conversationStage
    });
    
    res.json({
      success: true,
      analysis: {
        suggestions: analysis.suggestions,
        coaching: analysis.coaching,
        conversationStage: analysis.conversationStage,
        nextSteps: analysis.nextSteps,
        readyForDate: analysis.readyForDate
      }
    });
  } catch (error) {
    console.error('Error analyzing conversation:', error);
    res.status(500).json({ success: false, error: 'Failed to analyze conversation' });
  }
});

// Get conversation context
router.get('/:sessionId/context', authenticateToken, async (req, res) => {
  try {
    const { sessionId } = req.params;
    
    const session = await ConversationSession.findOne({
      where: { id: sessionId, userId: req.user.id },
      include: [{
        model: Screenshot,
        as: 'screenshots',
        order: [['sequenceNumber', 'ASC']]
      }]
    });
    
    if (!session) {
      return res.status(404).json({ success: false, error: 'Session not found' });
    }
    
    res.json({
      success: true,
      session: {
        id: session.id,
        title: session.title,
        contextSummary: session.contextSummary,
        conversationStage: session.conversationStage,
        screenshots: session.screenshots.map(s => ({
          id: s.id,
          sequenceNumber: s.sequenceNumber,
          imageUrl: s.imageUrl
        }))
      }
    });
  } catch (error) {
    console.error('Error fetching context:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch context' });
  }
});

function calculateContextCompleteness(screenshotCount) {
  // Gamification: Calculate context completeness percentage
  const optimalCount = 5; // Ideal number of screenshots for full context
  return Math.min(100, (screenshotCount / optimalCount) * 100);
}

module.exports = router;
```

### 4.3 Backend: AI Orchestrator Update

**File:** `Backend/services/aiOrchestrator.js`

Add new function for multi-image conversation analysis:

```javascript
const { GoogleGenerativeAI } = require('@google/generative-ai');

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

async function analyzeConversationContext({ sessionId, screenshots, previousContext, conversationStage }) {
  try {
    // Use Gemini 2.5 Pro for multi-image analysis
    const model = genAI.getGenerativeModel({ model: 'gemini-2.5-pro' });
    
    // Prepare images for Gemini
    const imageParts = await Promise.all(
      screenshots.map(async (url) => {
        const response = await fetch(url);
        const buffer = await response.buffer();
        return {
          inlineData: {
            data: buffer.toString('base64'),
            mimeType: 'image/jpeg'
          }
        };
      })
    );
    
    // Construct prompt for conversation analysis
    const prompt = `You are an expert dating coach analyzing a conversation between two people based on ${screenshots.length} screenshots.

Previous context summary: ${previousContext || 'None - this is the first analysis'}
Current conversation stage: ${conversationStage}

Analyze these screenshots in sequence and provide:

1. **Context Summary**: A brief summary of the conversation so far (who's talking, what's the vibe, how long have they been chatting)

2. **Participant Names**: Extract the names of the people in the conversation

3. **Conversation Stage**: Determine the current stage:
   - initial: Just started chatting
   - building_rapport: Getting to know each other
   - flirting: Clear romantic interest
   - ready_for_date: Time to ask them out
   - dating: Already dating

4. **Flirt Suggestions**: Provide 3 specific, contextual suggestions for what to say next. Each suggestion should:
   - Be authentic and match the conversation tone
   - Move the conversation forward
   - Show personality and confidence

5. **Coaching Advice**: Provide strategic advice on:
   - What's working well in this conversation
   - What to avoid
   - How to escalate (if appropriate)
   - When/how to suggest meeting in person

6. **Next Steps**: What should the user do next?

7. **Ready for Date**: Boolean - is it time to ask them out?

Format your response as JSON with these exact keys: contextSummary, participantNames (array), conversationStage, suggestions (array of 3 strings), coaching (object with keys: working, avoid, escalation, meetingAdvice), nextSteps (string), readyForDate (boolean)`;
    
    // Call Gemini 2.5 Pro with all images
    const result = await model.generateContent([prompt, ...imageParts]);
    const response = await result.response;
    const text = response.text();
    
    // Parse JSON response
    const analysis = JSON.parse(text);
    
    return analysis;
    
  } catch (error) {
    console.error('Error in conversation analysis:', error);
    throw error;
  }
}

module.exports = {
  analyzeConversationContext,
  // ... other exports
};
```

### 4.4 iOS: Conversation Session View

**File:** `iOS/Flirrt/Views/ConversationSessionView.swift`

```swift
import SwiftUI
import PhotosUI

struct ConversationSessionView: View {
    @StateObject private var viewModel = ConversationSessionViewModel()
    @State private var selectedImages: [UIImage] = []
    @State private var showingImagePicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Context Completeness Progress
                ContextProgressBar(
                    completeness: viewModel.contextCompleteness,
                    screenshotCount: viewModel.screenshots.count
                )
                .padding()
                
                // Screenshot Grid
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                        ForEach(viewModel.screenshots) { screenshot in
                            ScreenshotThumbnail(screenshot: screenshot)
                        }
                        
                        // Add Screenshot Button
                        AddScreenshotButton {
                            showingImagePicker = true
                        }
                    }
                    .padding()
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    if viewModel.needsMoreContext {
                        Text("Add more screenshots for better context")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    Button(action: {
                        viewModel.analyzeConversation()
                    }) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("Analyze Conversation")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.screenshots.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Conversation Context")
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImages: $selectedImages) { images in
                    viewModel.addScreenshots(images)
                }
            }
            .sheet(item: $viewModel.analysisResult) { result in
                AnalysisResultView(result: result)
            }
        }
    }
}

struct ContextProgressBar: View {
    let completeness: Double
    let screenshotCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Context Completeness")
                    .font(.headline)
                Spacer()
                Text("\(Int(completeness))%")
                    .font(.headline)
                    .foregroundColor(completeness >= 100 ? .green : .orange)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * (completeness / 100))
                }
            }
            .frame(height: 12)
            
            Text("\(screenshotCount) screenshot\(screenshotCount == 1 ? "" : "s") added")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// ... (Additional supporting views)
```

**CHECKPOINT:** After multi-screenshot context implementation, run `/checkpoint-save` with description "CP-3: Multi-screenshot context system completed"

---

## SECTION 5: VOICE UI & AUDIO MIXING (PRIORITY 4)

### 5.1 Enable Voice Recording View

**File:** `iOS/Flirrt/Views/VoiceRecordingView.swift`

This file already exists but is disabled. Enable it in navigation:

```swift
// In MainTabView.swift or equivalent
NavigationLink("Voice Messages", destination: VoiceRecordingView())
```

### 5.2 Implement Audio Mixing Service

**File:** `iOS/Flirrt/Services/AudioMixingService.swift`

```swift
import AVFoundation
import Foundation

enum BackgroundSound: String, CaseIterable {
    case beach = "beach_waves"
    case party = "party_ambience"
    case forest = "forest_birds"
    case cafe = "cafe_chatter"
    case rain = "gentle_rain"
    
    var displayName: String {
        switch self {
        case .beach: return "Beach"
        case .party: return "Party"
        case .forest: return "Forest"
        case .cafe: return "Café"
        case .rain: return "Rain"
        }
    }
}

class AudioMixingService {
    static let shared = AudioMixingService()
    
    private let audioEngine = AVAudioEngine()
    private let mixer = AVAudioMixerNode()
    
    private init() {
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        audioEngine.attach(mixer)
        audioEngine.connect(mixer, to: audioEngine.outputNode, format: nil)
    }
    
    /// Mix voice audio with background sound
    /// - Parameters:
    ///   - voiceURL: URL of the voice audio file (from ElevenLabs)
    ///   - backgroundSound: Background sound to mix
    ///   - voiceVolume: Volume of voice (0.0 to 1.0)
    ///   - backgroundVolume: Volume of background (0.0 to 1.0)
    ///   - completion: Completion handler with URL of mixed audio
    func mixVoiceWithBackground(
        voiceURL: URL,
        backgroundSound: BackgroundSound,
        voiceVolume: Float = 1.0,
        backgroundVolume: Float = 0.3,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Load voice audio file
                let voiceAsset = AVAsset(url: voiceURL)
                
                // Load background sound from bundle
                guard let backgroundURL = Bundle.main.url(
                    forResource: backgroundSound.rawValue,
                    withExtension: "mp3"
                ) else {
                    throw AudioMixingError.backgroundSoundNotFound
                }
                let backgroundAsset = AVAsset(url: backgroundURL)
                
                // Create composition
                let composition = AVMutableComposition()
                
                // Add voice track
                guard let voiceTrack = composition.addMutableTrack(
                    withMediaType: .audio,
                    preferredTrackID: kCMPersistentTrackID_Invalid
                ) else {
                    throw AudioMixingError.failedToCreateTrack
                }
                
                guard let voiceAssetTrack = voiceAsset.tracks(withMediaType: .audio).first else {
                    throw AudioMixingError.invalidAudioFile
                }
                
                try voiceTrack.insertTimeRange(
                    CMTimeRange(start: .zero, duration: voiceAsset.duration),
                    of: voiceAssetTrack,
                    at: .zero
                )
                
                // Add background track
                guard let backgroundTrack = composition.addMutableTrack(
                    withMediaType: .audio,
                    preferredTrackID: kCMPersistentTrackID_Invalid
                ) else {
                    throw AudioMixingError.failedToCreateTrack
                }
                
                guard let backgroundAssetTrack = backgroundAsset.tracks(withMediaType: .audio).first else {
                    throw AudioMixingError.invalidAudioFile
                }
                
                // Loop background if needed to match voice duration
                var currentTime = CMTime.zero
                while currentTime < voiceAsset.duration {
                    let remainingDuration = voiceAsset.duration - currentTime
                    let insertDuration = min(backgroundAsset.duration, remainingDuration)
                    
                    try backgroundTrack.insertTimeRange(
                        CMTimeRange(start: .zero, duration: insertDuration),
                        of: backgroundAssetTrack,
                        at: currentTime
                    )
                    
                    currentTime = currentTime + insertDuration
                }
                
                // Create audio mix to control volumes
                let audioMix = AVMutableAudioMix()
                
                let voiceParams = AVMutableAudioMixInputParameters(track: voiceTrack)
                voiceParams.setVolume(voiceVolume, at: .zero)
                
                let backgroundParams = AVMutableAudioMixInputParameters(track: backgroundTrack)
                backgroundParams.setVolume(backgroundVolume, at: .zero)
                
                audioMix.inputParameters = [voiceParams, backgroundParams]
                
                // Export mixed audio
                let outputURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension("m4a")
                
                guard let exportSession = AVAssetExportSession(
                    asset: composition,
                    presetName: AVAssetExportPresetAppleM4A
                ) else {
                    throw AudioMixingError.exportFailed
                }
                
                exportSession.outputURL = outputURL
                exportSession.outputFileType = .m4a
                exportSession.audioMix = audioMix
                
                exportSession.exportAsynchronously {
                    DispatchQueue.main.async {
                        switch exportSession.status {
                        case .completed:
                            completion(.success(outputURL))
                        case .failed, .cancelled:
                            completion(.failure(exportSession.error ?? AudioMixingError.exportFailed))
                        default:
                            break
                        }
                    }
                }
                
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}

enum AudioMixingError: Error {
    case backgroundSoundNotFound
    case failedToCreateTrack
    case invalidAudioFile
    case exportFailed
}
```

### 5.3 Add Background Sounds to Bundle

Download or create the following audio files and add to `iOS/Flirrt/Resources/Audio/`:
- `beach_waves.mp3`
- `party_ambience.mp3`
- `forest_birds.mp3`
- `cafe_chatter.mp3`
- `gentle_rain.mp3`

Ensure they are added to the Xcode project and included in the app target.

### 5.4 Update Voice Message Flow

**File:** `iOS/Flirrt/Views/VoiceMessageView.swift`

```swift
import SwiftUI

struct VoiceMessageView: View {
    @StateObject private var viewModel = VoiceMessageViewModel()
    @State private var selectedBackground: BackgroundSound = .beach
    @State private var selectedSuggestion: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Suggestion to convert to voice
            Text(selectedSuggestion)
                .font(.title3)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            
            // Background sound picker
            VStack(alignment: .leading, spacing: 12) {
                Text("Background Sound")
                    .font(.headline)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(BackgroundSound.allCases, id: \.self) { sound in
                            BackgroundSoundButton(
                                sound: sound,
                                isSelected: selectedBackground == sound
                            ) {
                                selectedBackground = sound
                            }
                        }
                    }
                }
            }
            
            // Generate Voice Button
            Button(action: {
                viewModel.generateVoiceMessage(
                    text: selectedSuggestion,
                    background: selectedBackground
                )
            }) {
                HStack {
                    if viewModel.isGenerating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "mic.fill")
                        Text("Generate Voice Message")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(viewModel.isGenerating)
            
            // Play/Share Controls
            if let audioURL = viewModel.generatedAudioURL {
                HStack(spacing: 20) {
                    Button(action: {
                        viewModel.playAudio()
                    }) {
                        Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 50))
                    }
                    
                    ShareLink(item: audioURL) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 30))
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Voice Message")
    }
}

struct BackgroundSoundButton: View {
    let sound: BackgroundSound
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: iconForSound(sound))
                    .font(.system(size: 30))
                Text(sound.displayName)
                    .font(.caption)
            }
            .frame(width: 80, height: 80)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(12)
        }
    }
    
    private func iconForSound(_ sound: BackgroundSound) -> String {
        switch sound {
        case .beach: return "water.waves"
        case .party: return "music.note.list"
        case .forest: return "leaf.fill"
        case .cafe: return "cup.and.saucer.fill"
        case .rain: return "cloud.rain.fill"
        }
    }
}
```

**CHECKPOINT:** After voice UI and audio mixing implementation, run `/checkpoint-save` with description "CP-4: Voice UI and audio mixing completed"

---

## SECTION 6: COACHING PERSONA & AI ENHANCEMENT (PRIORITY 5)

### 6.1 Create Coaching Prompt Templates

**File:** `Backend/prompts/coachingPersona.js`

```javascript
const COACHING_PERSONA = `You are an expert dating coach and wingman. Your name is Flirrt, and you're here to help people build genuine connections.

Your personality:
- Supportive and encouraging, never judgmental
- Confident but not arrogant
- Playful and fun, with a sense of humor
- Emotionally intelligent and perceptive
- Focused on authenticity over pickup lines

Your approach:
- You don't just give lines to copy - you explain WHY they work
- You help users understand the psychology of attraction
- You teach them to read social cues and conversation dynamics
- You encourage them to be their best, authentic selves
- You know when to be bold and when to be patient

Your expertise:
- Reading conversation tone and energy
- Identifying conversation stages (initial contact, building rapport, flirting, ready for date)
- Suggesting when and how to escalate (move from texting to calling to meeting)
- Helping users avoid common mistakes (being too eager, too passive, too generic)
- Balancing playfulness with genuine interest

Remember: The goal isn't just to get a date - it's to help build a real connection.`;

const ANALYSIS_PROMPT_TEMPLATE = `${COACHING_PERSONA}

You're analyzing a conversation based on screenshots. Here's what you need to do:

1. **Understand the Context**
   - Who's talking? What's the vibe?
   - How long have they been chatting?
   - What's the energy level?
   - Any red flags or green flags?

2. **Assess the Conversation Stage**
   - initial: Just started, still feeling each other out
   - building_rapport: Getting comfortable, finding common ground
   - flirting: Clear romantic interest, playful energy
   - ready_for_date: Time to suggest meeting in person
   - dating: Already dating, maintaining connection

3. **Provide Flirt Suggestions**
   Give 3 specific suggestions for what to say next. Each should:
   - Match the conversation's tone and energy
   - Move things forward (don't just maintain status quo)
   - Show personality and confidence
   - Be authentic (no cheesy pickup lines unless the conversation is already playful)

4. **Coach, Don't Just Suggest**
   For each suggestion, briefly explain:
   - WHY this works (psychology, timing, tone)
   - What it accomplishes (builds rapport, shows interest, creates intrigue, etc.)

5. **Strategic Advice**
   - What's working well in this conversation?
   - What should they avoid?
   - How can they escalate (if appropriate)?
   - Is it time to suggest meeting in person? If so, how?

6. **Next Steps**
   Give clear, actionable advice on what to do next.

Current conversation stage: {{conversationStage}}
Number of screenshots analyzed: {{screenshotCount}}

Provide your analysis in the following JSON format:
{
  "contextSummary": "Brief summary of the conversation",
  "participantNames": ["Name1", "Name2"],
  "conversationStage": "one of: initial, building_rapport, flirting, ready_for_date, dating",
  "suggestions": [
    {
      "text": "The actual message to send",
      "reasoning": "Why this works",
      "tone": "playful/sincere/bold/curious/etc"
    }
  ],
  "coaching": {
    "working": "What's going well",
    "avoid": "What to avoid",
    "escalation": "How to move forward",
    "meetingAdvice": "When/how to suggest meeting (if applicable)"
  },
  "nextSteps": "Clear action items",
  "readyForDate": true/false,
  "confidenceScore": 0-100 (how confident you are in this analysis)
}`;

module.exports = {
  COACHING_PERSONA,
  ANALYSIS_PROMPT_TEMPLATE
};
```

### 6.2 Update AI Orchestrator with GPT-5 Pro

**File:** `Backend/services/aiOrchestrator.js`

```javascript
const { OpenAI } = require('openai');
const { COACHING_PERSONA, ANALYSIS_PROMPT_TEMPLATE } = require('../prompts/coachingPersona');

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
});

async function generateCoachingResponse({ screenshots, conversationStage, previousAnalysis }) {
  try {
    // Use GPT-5 Pro for coaching (best reasoning and personality)
    const prompt = ANALYSIS_PROMPT_TEMPLATE
      .replace('{{conversationStage}}', conversationStage)
      .replace('{{screenshotCount}}', screenshots.length);
    
    // Note: GPT-5 uses /v1/responses endpoint, not /v1/chat/completions
    const response = await fetch('https://api.openai.com/v1/responses', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: 'gpt-5-pro',
        input: prompt,
        // Include screenshot data here
      })
    });
    
    const result = await response.json();
    const analysis = JSON.parse(result.output);
    
    return analysis;
    
  } catch (error) {
    console.error('Error generating coaching response:', error);
    throw error;
  }
}

module.exports = {
  generateCoachingResponse,
  // ... other exports
};
```

### 6.3 Add Refresh Suggestions Endpoint

**File:** `Backend/routes/flirts.js`

```javascript
// Add new endpoint for regenerating suggestions
router.post('/regenerate', authenticateToken, async (req, res) => {
  try {
    const { sessionId, excludeSuggestions } = req.body;
    
    // Get session context
    const session = await ConversationSession.findByPk(sessionId);
    const screenshots = await Screenshot.findAll({
      where: { sessionId },
      order: [['sequenceNumber', 'ASC']]
    });
    
    // Generate new suggestions with different temperature for variety
    const analysis = await generateCoachingResponse({
      screenshots: screenshots.map(s => s.imageUrl),
      conversationStage: session.conversationStage,
      previousAnalysis: session.contextSummary,
      temperature: 0.9, // Higher temperature for more variety
      excludeSuggestions // Don't repeat these
    });
    
    res.json({
      success: true,
      suggestions: analysis.suggestions,
      coaching: analysis.coaching
    });
    
  } catch (error) {
    console.error('Error regenerating suggestions:', error);
    res.status(500).json({ success: false, error: 'Failed to regenerate suggestions' });
  }
});
```

### 6.4 iOS: Enhanced Suggestion Display

**File:** `iOS/Flirrt/Views/SuggestionCardView.swift`

```swift
import SwiftUI

struct SuggestionCardView: View {
    let suggestion: Suggestion
    @State private var showExplanation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Suggestion Text
            Text(suggestion.text)
                .font(.body)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            
            // Metadata
            HStack {
                // Tone Badge
                Text(suggestion.tone.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(toneColor(suggestion.tone).opacity(0.2))
                    .foregroundColor(toneColor(suggestion.tone))
                    .cornerRadius(8)
                
                Spacer()
                
                // Explain Why Button
                Button(action: {
                    withAnimation {
                        showExplanation.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "lightbulb.fill")
                        Text("Why this works")
                    }
                    .font(.caption)
                    .foregroundColor(.orange)
                }
            }
            
            // Explanation (expandable)
            if showExplanation {
                VStack(alignment: .leading, spacing: 8) {
                    Text("💡 Why this works:")
                        .font(.caption.bold())
                    
                    Text(suggestion.reasoning)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
                .transition(.opacity.combined(with: .scale))
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                Button(action: {
                    copyToClipboard(suggestion.text)
                }) {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption)
                }
                
                Button(action: {
                    // Insert into text field
                }) {
                    Label("Use", systemImage: "checkmark.circle")
                        .font(.caption)
                }
                
                Button(action: {
                    // Generate voice message
                }) {
                    Label("Voice", systemImage: "mic.fill")
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private func toneColor(_ tone: String) -> Color {
        switch tone.lowercased() {
        case "playful": return .purple
        case "sincere": return .blue
        case "bold": return .red
        case "curious": return .green
        default: return .gray
        }
    }
    
    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
        // Show toast notification
    }
}

struct Suggestion: Identifiable {
    let id = UUID()
    let text: String
    let reasoning: String
    let tone: String
}
```

**CHECKPOINT:** After coaching persona implementation, run `/checkpoint-save` with description "CP-5: Coaching persona and AI enhancement completed"

---

## SECTION 7: TESTING & QUALITY ASSURANCE (PRIORITY 6)

### 7.1 Create Testing Subagent

Activate the `qa-engineer` subagent from your plugin:

```bash
/agent activate qa-engineer
```

### 7.2 iOS Unit Tests

**File:** `iOS/FlirrtTests/ConversationSessionTests.swift`

```swift
import XCTest
@testable import Flirrt

class ConversationSessionTests: XCTestCase {
    
    func testSessionCreation() async throws {
        let api = APIClient.shared
        let session = try await api.createConversationSession(title: "Test Conversation")
        
        XCTAssertNotNil(session.id)
        XCTAssertEqual(session.title, "Test Conversation")
        XCTAssertEqual(session.status, "active")
    }
    
    func testAddScreenshot() async throws {
        let api = APIClient.shared
        let session = try await api.createConversationSession(title: "Test")
        
        let testImage = UIImage(systemName: "photo")!
        let imageData = testImage.jpegData(compressionQuality: 0.8)!
        
        let result = try await api.addScreenshot(to: session.id, imageData: imageData)
        
        XCTAssertEqual(result.sequenceNumber, 1)
        XCTAssertTrue(result.needsMoreContext)
    }
    
    func testContextCompleteness() async throws {
        let api = APIClient.shared
        let session = try await api.createConversationSession(title: "Test")
        
        // Add 5 screenshots
        for i in 1...5 {
            let testImage = UIImage(systemName: "photo")!
            let imageData = testImage.jpegData(compressionQuality: 0.8)!
            _ = try await api.addScreenshot(to: session.id, imageData: imageData)
        }
        
        let context = try await api.getConversationContext(sessionId: session.id)
        XCTAssertEqual(context.screenshots.count, 5)
        XCTAssertGreaterThanOrEqual(context.contextCompleteness, 100)
    }
}
```

### 7.3 Backend Integration Tests

**File:** `Backend/tests/conversations.test.js`

```javascript
const request = require('supertest');
const app = require('../app');
const { ConversationSession, Screenshot } = require('../models');

describe('Conversation API', () => {
  let authToken;
  let sessionId;
  
  beforeAll(async () => {
    // Get auth token
    const response = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: 'test@example.com', password: 'password' });
    authToken = response.body.token;
  });
  
  test('POST /api/v1/conversations/start - Create new session', async () => {
    const response = await request(app)
      .post('/api/v1/conversations/start')
      .set('Authorization', `Bearer ${authToken}`)
      .send({ title: 'Test Conversation' });
    
    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.body.session.title).toBe('Test Conversation');
    
    sessionId = response.body.session.id;
  });
  
  test('POST /api/v1/conversations/:id/add-screenshot - Add screenshot', async () => {
    const response = await request(app)
      .post(`/api/v1/conversations/${sessionId}/add-screenshot`)
      .set('Authorization', `Bearer ${authToken}`)
      .send({ imageUrl: 'https://example.com/screenshot1.jpg' });
    
    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.body.screenshot.sequenceNumber).toBe(1);
  });
  
  test('POST /api/v1/conversations/:id/analyze - Analyze conversation', async () => {
    // Add multiple screenshots first
    for (let i = 2; i <= 3; i++) {
      await request(app)
        .post(`/api/v1/conversations/${sessionId}/add-screenshot`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ imageUrl: `https://example.com/screenshot${i}.jpg` });
    }
    
    const response = await request(app)
      .post(`/api/v1/conversations/${sessionId}/analyze`)
      .set('Authorization', `Bearer ${authToken}`);
    
    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.body.analysis).toHaveProperty('suggestions');
    expect(response.body.analysis).toHaveProperty('coaching');
    expect(response.body.analysis.suggestions.length).toBeGreaterThan(0);
  });
});
```

### 7.4 E2E Testing Script

**File:** `scripts/e2e-test.sh`

```bash
#!/bin/bash

echo "🧪 Running Flirrt.AI End-to-End Tests"
echo "======================================"

# Backend tests
echo "📦 Testing Backend..."
cd Backend
npm test
if [ $? -ne 0 ]; then
    echo "❌ Backend tests failed"
    exit 1
fi
cd ..

# iOS tests
echo "📱 Testing iOS App..."
cd iOS
xcodebuild test \
  -project Flirrt.xcodeproj \
  -scheme Flirrt \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=18.0'
if [ $? -ne 0 ]; then
    echo "❌ iOS tests failed"
    exit 1
fi
cd ..

echo "✅ All tests passed!"
```

**CHECKPOINT:** After completing testing suite, run `/checkpoint-save` with description "CP-6: Full testing suite completed"

---

## SECTION 8: FINAL INTEGRATION & DEPLOYMENT

### 8.1 Update Environment Variables

**File:** `Backend/.env.example`

```env
# Database
DATABASE_URL=postgresql://user:password@localhost:5432/flirrt

# Redis
REDIS_URL=redis://localhost:6379

# AI APIs
OPENAI_API_KEY=your_openai_api_key_here
GEMINI_API_KEY=your_gemini_api_key_here
GROK_API_KEY=your_grok_api_key_here
PERPLEXITY_API_KEY=your_perplexity_api_key_here
ELEVENLABS_API_KEY=your_elevenlabs_api_key_here

# JWT
JWT_SECRET=your_jwt_secret_here

# App Configuration
NODE_ENV=production
PORT=3000
```

### 8.2 iOS Build Configuration

Update `iOS/Flirrt/Config.xcconfig`:

```
// API Endpoints
API_BASE_URL = https://flirrt-api.onrender.com

// App Group ID
APP_GROUP_ID = group.com.flirrt.shared

// Deep Link Scheme
URL_SCHEME = flirrt
```

### 8.3 Deployment Checklist

- [ ] All critical bugs fixed (CP-1)
- [ ] KeyboardKit integrated (CP-2)
- [ ] Multi-screenshot context working (CP-3)
- [ ] Voice UI functional (CP-4)
- [ ] Coaching persona implemented (CP-5)
- [ ] All tests passing (CP-6)
- [ ] Environment variables configured
- [ ] Backend deployed to Render
- [ ] iOS app builds successfully
- [ ] TestFlight beta uploaded

### 8.4 Performance Validation

Run performance tests:

```bash
# Backend load test
cd Backend
npm run load-test

# iOS memory profiling
cd iOS
xcodebuild -project Flirrt.xcodeproj \
  -scheme Flirrt \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -enableAddressSanitizer YES \
  -enableThreadSanitizer YES
```

---

## SECTION 9: EXECUTION STRATEGY FOR CLAUDE-CODE

### 9.1 Recommended Subagent Workflow

**Phase 1: Bug Fixes (Day 1)**
- Activate `ios-architect` subagent
- Execute Section 2 (Critical Bug Fixes)
- Run tests
- Create CP-1 checkpoint

**Phase 2: Keyboard Overhaul (Days 2-3)**
- Keep `ios-architect` active
- Execute Section 3 (KeyboardKit Integration)
- Test in simulator
- Create CP-2 checkpoint

**Phase 3: Backend Enhancement (Days 4-5)**
- Activate `backend-architect` subagent
- Execute Section 4.1-4.3 (Backend conversation system)
- Run backend tests
- Parallel: `ios-architect` works on Section 4.4 (iOS conversation views)
- Create CP-3 checkpoint

**Phase 4: Voice Features (Day 6)**
- `ios-architect` executes Section 5 (Voice UI & Audio Mixing)
- Test voice generation and mixing
- Create CP-4 checkpoint

**Phase 5: AI Enhancement (Days 7-8)**
- Activate `ai-integration-specialist` subagent
- Execute Section 6.1-6.2 (Coaching prompts & GPT-5 integration)
- `ios-architect` executes Section 6.3-6.4 (iOS suggestion UI)
- Test end-to-end coaching flow
- Create CP-5 checkpoint

**Phase 6: Testing & QA (Days 9-10)**
- Activate `qa-engineer` subagent
- Execute Section 7 (All testing)
- Fix any discovered issues
- Create CP-6 checkpoint

**Phase 7: Integration & Deployment (Day 11)**
- All subagents collaborate
- Execute Section 8 (Final integration)
- Deploy to staging
- Final validation

### 9.2 Checkpoint Recovery

If anything goes wrong, roll back to last checkpoint:

```bash
git tag --list "checkpoint-*"  # List all checkpoints
git checkout checkpoint-YYYYMMDD-HHMMSS  # Restore checkpoint
```

### 9.3 Progress Tracking

Create a progress tracking file:

**File:** `PROGRESS.md`

```markdown
# Flirrt.AI Transformation Progress

## Checkpoints
- [ ] CP-1: Critical bug fixes
- [ ] CP-2: KeyboardKit integration
- [ ] CP-3: Multi-screenshot context
- [ ] CP-4: Voice UI & audio mixing
- [ ] CP-5: Coaching persona
- [ ] CP-6: Testing suite
- [ ] CP-7: Deployment

## Current Status
- **Phase:** [Current phase]
- **Active Subagent:** [Current subagent]
- **Last Checkpoint:** [Last checkpoint ID]
- **Issues:** [Any blockers]

## Next Steps
1. [Next immediate task]
2. [Following task]
3. [After that]
```

---

## SECTION 10: SUCCESS CRITERIA

### 10.1 Feature Completeness

All features must be fully functional:

1. ✅ **Full QWERTY Keyboard** with Flirrt toolbar
2. ✅ **Multi-Screenshot Context** with gamified progress tracking
3. ✅ **Voice Messages** with background sound mixing
4. ✅ **Refresh Suggestions** with variety
5. ✅ **Coaching Persona** with "why this works" explanations
6. ✅ **Reduced Suggestion Overload** (1-3 chips, not 5 items)

### 10.2 Performance Targets

- Screenshot analysis: < 3 seconds
- Suggestion regeneration: < 2 seconds
- Voice synthesis + mixing: < 5 seconds
- Keyboard load time: < 500ms
- Memory usage (keyboard): < 40MB

### 10.3 Code Quality

- All critical bugs fixed (from GPT-5 analysis)
- No force-unwrapping in production code
- All API calls use proper error handling
- Sensitive data not logged
- All tests passing (100% critical path coverage)

### 10.4 User Experience

- Liquid Glass design on iOS 26
- Smooth animations and transitions
- Clear progress indicators
- Helpful error messages
- Intuitive navigation

---

## APPENDIX A: TROUBLESHOOTING

### Issue: KeyboardKit not building

**Solution:**
```bash
cd iOS
rm -rf ~/Library/Developer/Xcode/DerivedData
xcodebuild clean
xcodebuild -project Flirrt.xcodeproj -scheme Flirrt
```

### Issue: Gemini 2.5 Pro API errors

**Solution:**
Check API key and quota:
```bash
curl -H "Authorization: Bearer $GEMINI_API_KEY" \
  https://generativelanguage.googleapis.com/v1/models
```

### Issue: Audio mixing fails

**Solution:**
Verify background sound files are in bundle:
```bash
cd iOS/Flirrt/Resources/Audio
ls -la *.mp3
```

---

## APPENDIX B: API REFERENCE

### Conversation API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/v1/conversations/start` | POST | Create new conversation session |
| `/api/v1/conversations/:id/add-screenshot` | POST | Add screenshot to session |
| `/api/v1/conversations/:id/analyze` | POST | Analyze conversation with full context |
| `/api/v1/conversations/:id/context` | GET | Get conversation context |
| `/api/v1/flirts/regenerate` | POST | Regenerate suggestions |

### iOS Deep Links

| URL | Action |
|-----|--------|
| `flirrt://analyze-screenshot` | Open screenshot analysis |
| `flirrt://voice-message` | Open voice message UI |
| `flirrt://conversation/:id` | Open specific conversation |

---

## APPENDIX C: RESOURCES

### Documentation Links
- [KeyboardKit Documentation](https://docs.keyboardkit.com/)
- [Claude Agent SDK](https://www.anthropic.com/engineering/building-agents-with-the-claude-agent-sdk)
- [Gemini 2.5 Pro API](https://ai.google.dev/gemini-api/docs)
- [GPT-5 Documentation](https://platform.openai.com/docs/)
- [ElevenLabs API](https://elevenlabs.io/docs)

### Code Examples
- [iOS Audio Mixing Tutorial](https://medium.com/@ian.mundy/audio-mixing-on-ios-4cd51dfaac9a)
- [KeyboardKit Examples](https://github.com/KeyboardKit/KeyboardKit)
- [Claude Code iOS Setup](https://gist.github.com/joelklabo/6df9fa603bec3478dec7efc17ea44596)

---

## FINAL NOTES

This guide is comprehensive and designed to be executed by Claude Code Sonnet 4.5 with full agentic capabilities. Use your 30+ hours of focus, create checkpoints frequently, and leverage subagents for parallel work.

**Remember:**
- Test frequently
- Save checkpoints at every milestone
- Use subagents for specialized tasks
- Refer back to this guide whenever uncertain
- The goal is a production-ready dating wingman app

Good luck! 🚀

---

**END OF IMPLEMENTATION GUIDE**

