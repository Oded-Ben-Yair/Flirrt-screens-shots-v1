# Flirrt.ai Research Notes - September 22, 2025

## Replit Agent 3 Best Practices

### Autonomous Operations & Planning
• Agent 3 offers 200 minutes of autonomous operation without human intervention (10x more than previous versions)
• Three operating modes: Build (default code writing), Plan (safe ideation), Edit (targeted modifications)
• Planning stages are free - only implementation triggers billing
• Source: [Replit Blog - Agent 3](https://blog.replit.com/introducing-agent-3-our-most-autonomous-agent-yet) - September 2025

### Prompting Patterns
• Break complex requests into iterative steps rather than single massive prompts
• Attach supporting materials (API docs, screenshots, code examples) for better context
• Use "Improve Prompt" feature to transform basic ideas into detailed instructions
• Clear, specific prompts with concrete acceptance criteria improve accuracy
• Source: [Replit Agent Guide](https://docs.replit.com/replitai/agent) - 2025

### File Output Discipline
• Checkpoint system creates snapshots at completion of each request
• Rollback capability to any previous checkpoint with full context preservation
• Agent automatically handles project scaffolding, dependency management, deployment config
• Source: [OPTIWEB - Replit Agent Prompting](https://optiwebdesign.com/2025/08/28/replit-agent-prompting-how-to-build-in-replit/) - August 28, 2025

## Claude-Code & MCP (Model Context Protocol) Patterns

### MCP Architecture Overview
• Open standard connecting AI systems with data sources via unified protocol
• Three layers: MCP Clients (Claude Code), MCP Servers (tools/APIs), Transport (stdio/HTTP/SSE)
• Replaces fragmented integrations with single protocol standard
• Source: [Anthropic - Model Context Protocol](https://www.anthropic.com/news/model-context-protocol) - 2025

### Best Practices for Claude-Code
• Use CLAUDE.md as auto-loaded context file for project guidance
• Apply /clear command frequently between tasks to reset context window
• Request file reading first, explicitly delay code writing until planning complete
• Use Markdown checklist files for complex multi-step tasks
• Source: [Anthropic - Claude Code Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices) - 2025

### Optimal MCP Configuration
• Recommended setup: Serena (semantic code search) + Context7 (documentation) + sequential thinking
• Users report 60-70% time reduction on complex features with proper MCP setup
• Popular servers: GitHub, Postgres, Puppeteer, Google Drive, Slack integration
• Source: [Claude MCP Community](https://www.claudemcp.com/) - 2025

### Token Management
• 10,000 token warning threshold for MCP tool output (configurable to 25,000)
• @ mentions for resource access from connected MCP servers
• Slash commands from MCP servers formatted as /mcp__servername__promptname
• Source: [Claude Docs - MCP](https://docs.claude.com/en/docs/claude-code/mcp) - 2025

## iOS Keyboard Extension Architecture (2025)

### Critical Memory Constraints
• 60 MB RAM limit for keyboard extensions (device dependent, was 48 MB historically)
• Process persists after keyboard disappears, but view controller recreated each time
• Avoid Interface Builder/Storyboards - loading takes up to 1 second causing glitches
• Use imageWithContentsOfFile: instead of imageNamed: to avoid persistent cache
• Source: [Stack Overflow - iOS Keyboard Memory Limits](https://stackoverflow.com/questions/44275990/memory-limit-for-keyboard-extension) - 2025

### Full Access Requirements
• RequestsOpenAccess = True in NSExtension -> NSExtensionAttributes plist required
• User must manually enable "Allow Full Access" in Settings > General > Keyboards
• Without Full Access: No network access, limited App Groups functionality
• With Full Access: Network, iCloud, Location Services, Address Book, Gallery access
• Source: [Apple Developer - Configuring Open Access](https://developer.apple.com/documentation/uikit/keyboards_and_input/creating_a_custom_keyboard/configuring_open_access_for_a_custom_keyboard) - 2025

### App Groups Integration
• Both main app and extension must share same App Group ID
• Extension needs Full Access for App Groups to work on device (simulator always grants full access)
• Data sharing pattern: Extension can read app data without Full Access, app cannot read extension data without Full Access
• Source: [Stack Overflow - App Groups Extension](https://stackoverflow.com/questions/41828150/ios-keyboard-extensionapp-groups) - 2025

### Performance Best Practices
• Release allocated objects in viewWillDisappear to manage memory pressure
• Test on actual devices - debug builds have higher memory limits than release
• Cannot access biometric authentication (Touch ID/Face ID)
• Source: [Medium - Custom iOS Keyboard Limitations](https://medium.com/@inFullMobile/limitations-of-custom-ios-keyboards-3be88dfb694) - 2025

## Share Extension for Screenshot Upload

### Compliant Data Paths
• Screenshots return as UIImage objects (public.image type), not file URLs
• Use loadItem(forTypeIdentifier:) for screenshots vs loadFileRepresentation for photos
• App Groups container provides secure shared storage between app and extension
• Darwin notifications enable real-time sync between processes
• Source: [Stack Overflow - Screenshot Share Extension](https://stackoverflow.com/questions/53896372/how-to-fetch-screenshot-in-ios-share-extension) - 2025

### Architecture Pattern
```
App Group Container/
├── uploads/screenshots/
├── shared_data/
└── cache/
```
• UserDefaults for metadata sharing, Keychain for sensitive tokens
• Background URL sessions with shared container identifier for large uploads
• Source: [Fleksy Blog - Share Extension Data Sharing](https://www.fleksy.com/blog/communicating-between-an-ios-app-extensions-using-app-groups/) - 2025

## Grok API Capabilities & Pricing (2025)

### Vision Support Confirmed
• grok-vision-beta and grok-2-vision-012 models available for image analysis
• Supports OCR, document processing, screenshot analysis, spatial understanding
• 256,000 token context window for latest models
• Source: [xAI Docs - Models](https://docs.x.ai/docs/models) - 2025

### Pricing Structure
• Grok 4: $3.00/1M input tokens, $15.00/1M output tokens, $0.75/1M cached tokens
• Grok 3: Same pricing as Grok 4
• Live Search: $25.00/1K sources ($0.025 per source)
• Free tier: $150/month API credits for teams with data sharing opt-in
• Source: [xAI API Pricing](https://x.ai/api) - 2025

### Rate Limits & Features
• RPM and TPM based rate limiting with 60-second rolling windows
• Function calling, structured outputs, real-time search capabilities
• OpenAI/Anthropic compatible REST API with official Python SDK
• Source: [xAI Docs - Consumption and Rate Limits](https://docs.x.ai/docs/consumption-and-rate-limits) - 2025

## ElevenLabs Voice Cloning Requirements

### Consent & Rights Framework
• Must confirm "right and consent to clone the voice" before upload
• Voice Captcha verification required for Professional Voice Cloning
• Misuse results in permanent platform bans
• License is perpetual, irrevocable, nonexclusive, royalty-free, worldwide
• Source: [ElevenLabs Terms of Service](https://elevenlabs.io/terms-of-use) - 2025

### Sample Length Requirements
• Instant Voice Cloning (IVC): 1-2 minutes minimum, 3 minutes maximum (more detrimental)
• Professional Voice Cloning (PVC): 30 minutes minimum, 3 hours optimal
• PVC processing time: 2-4 hours after verification
• Source: [ElevenLabs Voice Cloning Guide](https://elevenlabs.io/docs/product-guides/voices/voice-cloning) - 2025

### Technical Standards
• MP3 192kbps+ recommended, clean audio without reverb/artifacts
• Single speaker, consistent recording conditions
• ~20cm microphone distance, acoustically-treated room preferred
• Business tier and above includes API access
• Source: [ElevenLabs Voice Cloning Documentation](https://elevenlabs.io/docs/product-guides/voices/voice-cloning/instant-voice-cloning) - 2025

## App Store Review Guidelines & Privacy (2025)

### Keyboard Extension Restrictions
• Collect user activity only to enhance keyboard functionality
• Advertising prohibited in extensions (limited to main app binary)
• Cannot include Apple emoji in keyboard extensions
• Must have clear privacy policies for Full Access permissions
• Source: [Apple App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) - 2025

### Privacy Manifest Requirements (Mandatory since May 1, 2024)
• Active Input Modes API declaration required for custom keyboards
• Privacy manifest file (PrivacyInfo.xcprivacy) mandatory
• No storage of sensitive data except for obvious user services
• Source: [Bitrise - Apple Privacy Manifest Enforcement](https://bitrise.io/blog/post/enforcement-of-apple-privacy-manifest-starting-from-may-1-2024) - May 1, 2024

### MDM & Enterprise Controls
• Document and keyboard extensions obey Managed Open In rules
• Apps can deny custom keyboards using shouldAllowExtensionPointIdentifier
• SecureTextEntry prevents custom keyboards on password fields
• Source: [Apple Support - Extensions in iOS](https://support.apple.com/en-ke/guide/security/secabd3504cd/web) - 2025

## OCR vs Multimodal LLM Performance

### Accuracy Comparison
• GPT-4.5 Preview: 85-90% accuracy (best overall)
• Claude 3.7 Sonnet: 85-88% accuracy
• AWS Textract: 75-80% accuracy
• Google Vision: 70-75% accuracy
• LLMs excel at handwriting: 80-85% vs 64% for traditional OCR
• Source: [Vellum AI - Document Data Extraction 2025](https://www.vellum.ai/blog/document-data-extraction-in-2025-llms-vs-ocrs) - 2025

### Cost Analysis (per 1000 pages)
• GPT-4o Vision: $10-20
• AWS Textract: $1.50
• Google Vision: $1.50
• EasyOCR: <$1
• Source: [TableFlow - OCR vs LLMs](https://tableflow.com/blog/ocr-vs-llms) - 2025

### Best Use Cases
• LLMs: Complex layouts, handwriting, multilingual, contextual understanding
• Traditional OCR: High-volume clean text, cost-sensitive, deterministic results
• Hybrid approach recommended: LLM primary + OCR fallback for cost optimization
• Source: [Modal Blog - Open Source OCR Models](https://modal.com/blog/8-top-open-source-ocr-models-compared) - 2025

## AI Safety & Content Moderation (2025)

### Major Policy Updates
• Meta emergency policy changes (August-September 2025) after leaked documents showed romantic chat allowances with minors
• OpenAI introduced new guardrails (September 2025): No flirtatious conversations with minors, blocked suicide/self-harm discussions
• FTC launched investigations into 7 major AI companies regarding chatbot safety for minors
• Source: [TechCrunch - Meta AI Rules](https://techcrunch.com/2025/08/14/leaked-meta-ai-rules-show-chatbots-were-allowed-to-have-romantic-chats-with-kids/) - August 14, 2025

### Content Safety Frameworks
• Azure AI Content Safety: Hate, violence, sexual, custom categories
• Google Gemini Safety: CSAM, harassment, dangerous, toxic, violent, profanity detection
• Multimodal understanding across text, images, video, audio
• Source: [Microsoft Learn - Azure AI Content Safety](https://learn.microsoft.com/en-us/azure/ai-foundry/ai-services/content-safety-overview) - 2025

### Implementation Requirements
• Age verification protocols with default restrictive settings
• Content risk taxonomies for child-AI interactions
• Multi-layered filtering: automated flagging + human oversight
• Parental control systems for supervision and restrictions
• Source: [U.S. News - ChatGPT New Rules for Minors](https://www.usnews.com/news/u-s-news-decision-points/articles/2025-09-17/no-flirting-or-talk-of-suicide-chatgpt-gets-new-rules-for-minors) - September 17, 2025

## Privacy Compliance & Data Protection (2025)

### 2025 State Law Updates
• New laws effective January 1, 2025: Iowa, Delaware, Nebraska, New Hampshire (Jan 15: New Jersey)
• July 2025: Tennessee, Minnesota (July 31), Maryland
• Enhanced minor protections (13-17 age group), mandatory data protection assessments
• Source: [White & Case - 2025 State Privacy Laws](https://www.whitecase.com/insight-alert/2025-state-privacy-laws-what-businesses-need-know-compliance) - 2025

### Consent Management Technical Requirements
• Real-time GTM integration for instant consent signals
• Geographic logic auto-adaptation (GDPR vs CCPA vs state laws)
• Granular controls: separate analytics, advertising, personalization consent
• Comprehensive audit trails with timestamps, versions, user choices
• Source: [Secure Privacy - Mobile App Consent iOS 2025](https://secureprivacy.ai/blog/mobile-app-consent-ios-2025) - 2025

### KMS & PII Redaction
• AWS: Macie (PII discovery) + Comprehend (ML detection) + Glue DataBrew (transformation)
• Google Cloud: Cloud DLP (150+ infotypes) + KMS integration + format-preserving encryption
• 16+ PII parameters supported: email, phone, SSN, credit cards, addresses
• Confidence scoring with adjustable thresholds for redaction decisions
• Source: [HanaByte - Detecting PII in AWS 2025](https://www.hanabyte.com/detecting-and-protecting-pii-in-aws-in-2025/) - 2025