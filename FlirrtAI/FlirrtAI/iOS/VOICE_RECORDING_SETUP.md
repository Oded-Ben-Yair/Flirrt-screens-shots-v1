# Voice Recording Module Setup Guide

## Overview

The Voice Recording Module provides complete functionality for recording high-quality voice samples, creating voice clones via ElevenLabs API, and managing voice recordings within the Flirrt iOS app.

## Components

### 1. VoiceRecordingManager.swift
- Complete audio recording and playback management
- AVAudioRecorder/AVAudioPlayer setup with high-quality settings
- Real-time audio level monitoring for waveform visualization
- ElevenLabs API integration for voice clone creation
- Proper error handling and permission management
- File size optimization and duration enforcement (2-3 minutes)

### 2. VoiceRecordingView.swift
- SwiftUI interface with modern design
- Real-time waveform visualization
- Recording timer with progress indication
- Start/stop/playback controls
- Quality indicator during recording
- Upload functionality to ElevenLabs
- Comprehensive error handling and user feedback

### 3. VoiceModels.swift
- Complete data structures for voice recordings
- Voice clone management models
- ElevenLabs integration models
- Audio configuration constants
- Voice quality and emotion enums

### 4. SharedDataManager.swift
- Centralized data management for voice recordings
- UserDefaults integration for persistence
- App group sharing support
- Notification system for voice clone events

## Required Info.plist Permissions

Add the following to your main app's Info.plist:

```xml
<!-- REQUIRED: Microphone access -->
<key>NSMicrophoneUsageDescription</key>
<string>Flirrt needs access to your microphone to record voice samples for creating personalized voice clones. This enables the app to generate flirty messages in your own voice.</string>

<!-- OPTIONAL: Background audio processing -->
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

## Integration Steps

### 1. Add to Your Main App

```swift
import SwiftUI

@main
struct YourApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var apiClient = APIClient()
    @StateObject private var sharedDataManager = SharedDataManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(apiClient)
                .environmentObject(sharedDataManager)
        }
    }
}
```

### 2. Present Voice Recording View

```swift
import SwiftUI

struct ContentView: View {
    @State private var showingVoiceRecording = false

    var body: some View {
        NavigationView {
            VStack {
                Button("Record Voice") {
                    showingVoiceRecording = true
                }
                .sheet(isPresented: $showingVoiceRecording) {
                    VoiceRecordingView()
                }
            }
        }
    }
}
```

### 3. Using VoiceRecordingManager Programmatically

```swift
import SwiftUI

class MyViewController: UIViewController {
    private let voiceManager = VoiceRecordingManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupVoiceRecording()
    }

    private func setupVoiceRecording() {
        // Check permissions
        voiceManager.checkPermissions()

        // Request permissions if needed
        Task {
            if voiceManager.permissionStatus != .granted {
                let granted = await voiceManager.requestPermissions()
                if !granted {
                    // Handle permission denied
                    return
                }
            }
        }
    }

    @IBAction func startRecording() {
        Task {
            await voiceManager.startRecording()
        }
    }

    @IBAction func stopRecording() {
        voiceManager.stopRecording()
    }

    @IBAction func uploadVoiceClone() {
        Task {
            do {
                let response = try await voiceManager.uploadVoiceClone(userId: "user123")
                print("Voice clone created: \(response.voiceId)")

                // Store voice ID
                UserDefaults.standard.set(response.voiceId, forKey: "user_voice_id")
            } catch {
                print("Upload failed: \(error)")
            }
        }
    }
}
```

## Features

### Recording Features
- ✅ High-quality audio recording (44.1kHz, AAC, 128kbps)
- ✅ Real-time waveform visualization with 60 sample points
- ✅ 2-3 minute duration enforcement
- ✅ Minimum 5-second recording validation
- ✅ Audio level monitoring for quality feedback
- ✅ Automatic file size optimization
- ✅ Memory-efficient recording management

### User Interface Features
- ✅ Modern SwiftUI design with dark theme
- ✅ Animated recording button with pulse effects
- ✅ Real-time timer and progress indicators
- ✅ Quality indicator during recording
- ✅ Playback controls with progress tracking
- ✅ File management (delete recordings)
- ✅ Recording tips and instructions
- ✅ Comprehensive error handling with user-friendly messages

### ElevenLabs Integration
- ✅ Direct API integration for voice clone creation
- ✅ Secure file upload with proper mime types
- ✅ Response handling and voice ID storage
- ✅ Error handling for upload failures
- ✅ File size validation (25MB limit)

### Permission Handling
- ✅ AVAudioSession permission checking
- ✅ Async permission requests
- ✅ Settings redirect for denied permissions
- ✅ Clear permission status messaging

## File Structure

```
Flirrt/
├── Services/
│   ├── VoiceRecordingManager.swift
│   └── SharedDataManager.swift
├── Views/
│   └── VoiceRecordingView.swift
├── Models/
│   └── VoiceModels.swift
└── Resources/
    └── Info.plist (sample)
```

## Audio Configuration

The module uses the following optimized audio settings:

- **Format**: MPEG-4 AAC (.m4a)
- **Sample Rate**: 44.1 kHz
- **Channels**: Mono (1 channel)
- **Bit Rate**: 128 kbps
- **Quality**: High
- **Max Duration**: 3 minutes
- **Min Duration**: 5 seconds
- **Max File Size**: 25MB

## Error Handling

The module provides comprehensive error handling for:

- 🚫 Permission denied scenarios
- 🚫 Recording failures
- 🚫 Playback errors
- 🚫 File system errors
- 🚫 Network upload failures
- 🚫 Audio session conflicts
- 🚫 Invalid recording durations
- 🚫 File size limit violations

## Testing

To test the voice recording module:

1. **Permission Testing**: Test on device with microphone access granted/denied
2. **Recording Quality**: Test in various environments (quiet/noisy)
3. **Duration Limits**: Test minimum (5s) and maximum (3min) durations
4. **Network Testing**: Test upload with poor/no connectivity
5. **Memory Testing**: Test with multiple recordings
6. **Background Testing**: Test app backgrounding during recording

## Dependencies

- **AVFoundation**: Core audio recording and playback
- **Alamofire**: Network requests for ElevenLabs API
- **SwiftUI**: Modern UI framework
- **Combine**: Reactive data flow

## Notes

- The module is designed as a Swift Package Manager library
- All recordings are stored locally in the app's Documents directory
- Voice IDs are stored securely in UserDefaults and Keychain
- Real-time audio levels are captured for waveform visualization
- The module supports app groups for sharing data between extensions
- Background audio processing requires additional Info.plist configuration
- ElevenLabs API integration requires valid API credentials in APIClient

## Security Considerations

- 🔒 Microphone permissions are properly requested and handled
- 🔒 Voice recordings are stored locally and uploaded securely
- 🔒 API requests use HTTPS with proper certificate validation
- 🔒 Voice IDs are stored in secure UserDefaults
- 🔒 No sensitive data is logged in production builds
- 🔒 Temporary files are properly cleaned up after upload