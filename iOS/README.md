# 📱 Vibe8 iOS App

## Overview
The Vibe8 iOS app is built with SwiftUI and Swift Package Manager, targeting iOS 16.0+. It includes the main app, keyboard extension, and share extension.

## 🛠️ Build Instructions

### Prerequisites
- Xcode 26.0+
- iOS 18.6+ Simulator
- macOS Sequoia or later

### Building with Xcode
```bash
# Open in Xcode
xed .

# Or build from command line
xcodebuild -scheme Vibe8 \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  build
```

### Swift Package Manager
```bash
# Resolve dependencies
swift package resolve

# Build (note: won't create .app bundle)
swift build
```

## 📦 Project Structure

```
iOS/
├── Package.swift              # SPM configuration
├── Vibe8/                   # Main app target
│   ├── App/
│   │   └── Vibe8App.swift  # App entry point
│   ├── Models/
│   │   └── VoiceModels.swift # Data models
│   ├── Services/
│   │   ├── APIClient.swift   # Network layer
│   │   ├── AuthManager.swift # Authentication
│   │   └── VoiceRecordingManager.swift
│   ├── Views/
│   │   ├── AppCoordinator.swift
│   │   ├── LoginView.swift
│   │   ├── MainTabView.swift
│   │   ├── OnboardingView.swift
│   │   └── VoiceRecordingView.swift
│   └── Resources/
│       └── PrivacyInfo.xcprivacy
│
├── Vibe8Keyboard/           # Keyboard extension
│   └── KeyboardViewController.swift
│
└── Vibe8Share/              # Share extension
    └── ShareViewController.swift
```

## 🎯 Key Components

### Authentication (AuthManager.swift)
- Apple Sign In integration
- JWT token management with Keychain
- Age verification (18+ requirement)

### API Client (APIClient.swift)
- Alamofire-based networking
- Real API integration (no mocks)
- Multipart form uploads for images/audio

### Voice Recording (VoiceRecordingManager.swift)
- AVAudioRecorder setup
- 3-minute max recording
- AAC format, 44.1kHz sample rate
- File size optimization

### Keyboard Extension
- Memory limit: 60MB
- Shared data via App Groups
- Quick suggestion access

## 🔧 Configuration

### App Groups
```
group.com.vibe8.ai.shared
```

### Bundle Identifiers
- Main App: `ios.Vibe8`
- Keyboard: `ios.Vibe8.Vibe8Keyboard`
- Share: `ios.Vibe8.Vibe8Share`

### Capabilities Required
- Sign In with Apple
- App Groups
- Keychain Sharing
- Push Notifications

## 🧪 Testing

### Unit Tests
```bash
xcodebuild test \
  -scheme Vibe8 \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

### UI Testing
```bash
# Run UI tests
xcodebuild test \
  -scheme Vibe8UITests \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

### Automated Testing
```bash
cd ../Agents
node SimulatorTestAgent.js --full-test
```

## 📱 Simulator Management

### Create Simulator
```bash
xcrun simctl create "Vibe8 Test Device" \
  com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro \
  com.apple.CoreSimulator.SimRuntime.iOS-18-6
```

### Boot Simulator
```bash
xcrun simctl boot <device-id>
open -a Simulator
```

### Install App
```bash
xcrun simctl install booted /path/to/Vibe8.app
```

### Launch App
```bash
xcrun simctl launch booted ios.Vibe8
```

### Take Screenshot
```bash
xcrun simctl io booted screenshot screenshot.png
```

## 🐛 Debugging

### View Logs
```bash
xcrun simctl spawn booted log stream --level=debug | grep Vibe8
```

### Reset Simulator
```bash
xcrun simctl erase <device-id>
```

### Clear Keychain
```bash
xcrun simctl keychain booted reset
```

## 📊 Memory Optimization

### Keyboard Extension Limits
- Max memory: 60MB
- Optimization strategies:
  - Lazy loading of resources
  - Image compression
  - Minimal dependencies
  - Cache management

### Monitor Memory Usage
```swift
// In KeyboardViewController
func getMemoryUsage() -> Int {
    var info = mach_task_basic_info()
    // ... implementation
    return Int(info.resident_size)
}
```

## 🚀 Performance Tips

1. **Build Speed**
   - Use incremental builds
   - Cache SPM dependencies
   - Disable code coverage for debug builds

2. **Runtime Performance**
   - Optimize image assets
   - Use lazy loading for views
   - Minimize API calls

3. **Testing Speed**
   - Use `build-for-testing` and `test-without-building`
   - Run tests in parallel
   - Use simulator snapshots

## 🔐 Security

### Keychain Access
- Service: `com.vibe8.ai`
- Access Group: Shared between app and extensions

### API Keys
- Never hardcode in source
- Use environment variables
- Store in Keychain for production

### Data Protection
- Enable File Protection
- Use HTTPS only
- Implement certificate pinning

## 📝 Code Style

### SwiftUI Best Practices
- Use `@StateObject` for view models
- Prefer `@EnvironmentObject` for shared state
- Extract complex views into components

### Naming Conventions
- Views: `*View.swift`
- Models: Singular nouns
- Managers: `*Manager.swift`
- Extensions: `Type+Feature.swift`

## 🚢 Release Process

1. **Update Version**
   ```bash
   # In Package.swift
   version: "1.0.0"
   ```

2. **Archive**
   ```bash
   xcodebuild archive \
     -scheme Vibe8 \
     -archivePath build/Vibe8.xcarchive
   ```

3. **Export**
   ```bash
   xcodebuild -exportArchive \
     -archivePath build/Vibe8.xcarchive \
     -exportPath build \
     -exportOptionsPlist ExportOptions.plist
   ```

4. **Upload to TestFlight**
   ```bash
   xcrun altool --upload-app \
     --file build/Vibe8.ipa \
     --type ios \
     --apiKey $API_KEY \
     --apiIssuer $ISSUER_ID
   ```

## 🆘 Troubleshooting

### Build Errors

**"Module not found"**
```bash
swift package clean
swift package resolve
```

**"Code signing required"**
```bash
CODE_SIGNING_ALLOWED=NO xcodebuild build
```

**"Simulator not found"**
```bash
xcrun simctl list devices
# Use the correct device ID
```

### Runtime Issues

**Keyboard not appearing**
- Check Full Access permission
- Verify App Group configuration
- Review memory usage

**API calls failing**
- Check backend server status
- Verify network permissions
- Review API client configuration

## 📚 Resources
- [Apple Developer Documentation](https://developer.apple.com)
- [Swift Package Manager](https://swift.org/package-manager/)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)

---
Built with SwiftUI and ❤️