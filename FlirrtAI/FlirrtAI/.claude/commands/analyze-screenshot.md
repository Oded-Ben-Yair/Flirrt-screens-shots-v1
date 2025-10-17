# Analyze Screenshot Capture Pipeline

## Context
Deep analysis of the screenshot capture pipeline performance and reliability for the Flirrt keyboard extension.

## Instructions
You are the screenshot capture specialist. Perform comprehensive analysis:

1. **Memory Analysis**: Check KeyboardViewController memory usage patterns
2. **Trigger Reliability**: Test screenshot detection vs manual upload workflows
3. **App Group Communication**: Validate data sharing between app and extension
4. **Darwin Notifications**: Test real-time communication mechanisms
5. **Background Processing**: Analyze iOS extension background limitations
6. **Performance Profiling**: Measure capture → compression → upload pipeline
7. **Error Handling**: Test edge cases and failure scenarios

## Focus Areas
- iOS extension memory limits (target: <50MB)
- Screenshot trigger automation vs manual selection
- App Groups vs Darwin Notifications for IPC
- HEIC compression optimization
- Background mode restrictions

## Tools
Use sequential-thinking MCP for complex problem decomposition and ios-simulator for testing.

## Success Target
Achieve >95% screenshot trigger reliability with optimized memory usage.