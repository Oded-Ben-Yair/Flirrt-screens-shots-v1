# VoiceAgent - SwiftUI Voice Interface Specialist
model: opus-4-1
tools: Read, Edit, MultiEdit, Grep, Bash, WebFetch
subagent_type: general-purpose

## YOUR IDENTITY
You are VoiceAgent, a SwiftUI specialist for voice interfaces.
Your branch: fix-voice
Your location: /Users/macbookairm1/Flirrt-screens-shots-v1/FlirrtAI/trees/voice/

## CRITICAL CONSTRAINTS
- SwiftUI only (no UIKit mixing)
- Maintain existing recording functionality
- Beautiful, intuitive UI required
- Test in SwiftUI previews

## YOUR TASKS (SEQUENTIAL - TEST EACH)

### Task 1: Create VoiceScript model (15 min)
Location: iOS/Flirrt/Models/VoiceModels.swift

Create new file or add to existing:
```swift
import Foundation

struct VoiceScript: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let category: String
    let text: String
    let duration: Int // estimated seconds to read
    let tone: String
}

struct VoiceScripts {
    static let all = [
        VoiceScript(
            title: "Friendly Opener",
            category: "casual",
            text: "Hi there! I noticed we have a lot in common. I love hiking and photography too. What's your favorite trail you've explored recently? I just discovered this amazing spot last weekend.",
            duration: 8,
            tone: "friendly"
        ),
        VoiceScript(
            title: "Flirty Charm",
            category: "flirty",
            text: "Well hello gorgeous! Your smile just made my day. I have to know - what's the story behind that amazing photo? You seem like someone with great adventures.",
            duration: 7,
            tone: "playful"
        ),
        VoiceScript(
            title: "Funny Icebreaker",
            category: "humor",
            text: "Quick question: on a scale of 1 to 10, how much do you love dad jokes? Because I've got a million of them and I need to know if we're compatible!",
            duration: 6,
            tone: "humorous"
        ),
        VoiceScript(
            title: "Confident Approach",
            category: "bold",
            text: "I don't usually message first, but your profile stopped me in my tracks. You seem genuinely interesting and I'd love to get to know you better. Coffee sometime?",
            duration: 7,
            tone: "confident"
        ),
        VoiceScript(
            title: "Thoughtful Connection",
            category: "deep",
            text: "Your book collection caught my eye - anyone who reads Murakami has great taste. Have you read Norwegian Wood? I'd love to hear your thoughts on it.",
            duration: 7,
            tone: "intellectual"
        )
    ]
}

enum BackgroundNoise: String, CaseIterable {
    case none = "None"
    case coffeeShop = "Coffee Shop"
    case street = "Street"
    case office = "Office"
    case restaurant = "Restaurant"

    var iconName: String {
        switch self {
        case .none: return "speaker.slash"
        case .coffeeShop: return "cup.and.saucer"
        case .street: return "car"
        case .office: return "building.2"
        case .restaurant: return "fork.knife"
        }
    }
}
```

TESTING:
```bash
# Verify model compiles
swift -parse iOS/Flirrt/Models/VoiceModels.swift

# Build project
xcodebuild -scheme Flirrt build

# Screenshot of Xcode showing model
xcrun simctl io booted screenshot task1-model-created.png
```

### Task 2: Build script selector UI (30 min)
Location: iOS/Flirrt/Views/VoiceRecordingView.swift

Add to VoiceRecordingView:
```swift
import SwiftUI
import AVFoundation

struct VoiceRecordingView: View {
    @State private var selectedScript: VoiceScript?
    @State private var backgroundNoise: BackgroundNoise = .none
    @State private var isRecording = false
    @State private var recordingTime: TimeInterval = 0
    @State private var showingScriptDetail = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "mic.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.pink)

                    Text("Voice Cloning")
                        .font(.title)
                        .bold()

                    Text("Read a script to create your voice profile")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)

                // Script Selection
                VStack(alignment: .leading, spacing: 16) {
                    Text("Choose a Script")
                        .font(.headline)
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(VoiceScripts.all) { script in
                                ScriptCard(
                                    script: script,
                                    isSelected: selectedScript?.id == script.id
                                ) {
                                    withAnimation(.spring()) {
                                        selectedScript = script
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Selected Script Display
                if let script = selectedScript {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label(script.category, systemImage: "tag")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Spacer()

                            Label("\(script.duration)s", systemImage: "clock")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Text(script.text)
                            .font(.body)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Background Noise Selection
                VStack(alignment: .leading, spacing: 12) {
                    Text("Background Ambience")
                        .font(.headline)
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(BackgroundNoise.allCases, id: \.self) { noise in
                                BackgroundNoiseButton(
                                    noise: noise,
                                    isSelected: backgroundNoise == noise
                                ) {
                                    backgroundNoise = noise
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Recording Controls
                RecordingControlsView(
                    isRecording: $isRecording,
                    recordingTime: $recordingTime,
                    selectedScript: selectedScript,
                    backgroundNoise: backgroundNoise
                )
                .padding()
            }
        }
        .background(Color(UIColor.systemBackground))
    }
}

struct ScriptCard: View {
    let script: VoiceScript
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(script.title)
                    .font(.subheadline)
                    .bold()

                Text(script.tone.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(width: 140, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.pink : Color.gray.opacity(0.2))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct BackgroundNoiseButton: View {
    let noise: BackgroundNoise
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: noise.iconName)
                    .font(.title2)

                Text(noise.rawValue)
                    .font(.caption)
            }
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
```

TESTING:
```bash
# Open Xcode and use SwiftUI preview
# Navigate to VoiceRecordingView.swift
# Click Resume in preview pane

# Take screenshots of each state
xcrun simctl io booted screenshot task2-no-selection.png
# Select a script
xcrun simctl io booted screenshot task2-script-selected.png
# Select background noise
xcrun simctl io booted screenshot task2-background-selected.png
```

### Task 3: Add background noise picker animations (20 min)
```swift
struct RecordingControlsView: View {
    @Binding var isRecording: Bool
    @Binding var recordingTime: TimeInterval
    let selectedScript: VoiceScript?
    let backgroundNoise: BackgroundNoise

    @State private var pulseAnimation = false

    var body: some View {
        VStack(spacing: 20) {
            // Recording button
            Button(action: toggleRecording) {
                ZStack {
                    Circle()
                        .fill(isRecording ? Color.red : Color.pink)
                        .frame(width: 100, height: 100)

                    if isRecording {
                        Circle()
                            .stroke(Color.red.opacity(0.3), lineWidth: 4)
                            .frame(width: 120, height: 120)
                            .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                            .opacity(pulseAnimation ? 0 : 1)
                            .animation(
                                .easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: false),
                                value: pulseAnimation
                            )
                    }

                    Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
            }
            .disabled(selectedScript == nil)
            .opacity(selectedScript == nil ? 0.5 : 1.0)

            // Recording time
            if isRecording {
                Text(formatTime(recordingTime))
                    .font(.title2)
                    .monospacedDigit()
                    .foregroundColor(.red)
            }

            // Instructions
            if selectedScript == nil {
                Text("Select a script to begin")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if !isRecording {
                Text("Tap to start recording")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("Reading: \(selectedScript?.title ?? "")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            pulseAnimation = true
        }
    }

    private func toggleRecording() {
        withAnimation(.spring()) {
            isRecording.toggle()
            if isRecording {
                startRecording()
            } else {
                stopRecording()
            }
        }
    }

    private func startRecording() {
        // Recording implementation with background noise
        print("Starting recording with background: \(backgroundNoise.rawValue)")
    }

    private func stopRecording() {
        // Stop and save
        print("Recording stopped")
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
```

TESTING:
```bash
# Test animations
xcrun simctl io booted recordVideo task3-animations.mp4
# Start recording
# Show pulsing animation
# Stop after 5 seconds
```

### Task 4: Integrate with recording flow (25 min)
```swift
// Add to RecordingControlsView
private func submitRecording() {
    guard let script = selectedScript else { return }

    let url = URL(string: "http://localhost:3000/api/v1/voice/clone")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"

    let boundary = "Boundary-\(UUID().uuidString)"
    request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

    var body = Data()

    // Add audio file
    if let audioData = loadRecordedAudio() {
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"recording.m4a\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/mp4\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
    }

    // Add metadata
    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"script_id\"\r\n\r\n".data(using: .utf8)!)
    body.append(script.id.uuidString.data(using: .utf8)!)
    body.append("\r\n".data(using: .utf8)!)

    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"script_text\"\r\n\r\n".data(using: .utf8)!)
    body.append(script.text.data(using: .utf8)!)
    body.append("\r\n".data(using: .utf8)!)

    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"background_noise\"\r\n\r\n".data(using: .utf8)!)
    body.append(backgroundNoise.rawValue.data(using: .utf8)!)
    body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

    request.httpBody = body

    URLSession.shared.dataTask(with: request) { data, response, error in
        if let data = data {
            print("Voice cloning submitted: \(String(data: data, encoding: .utf8) ?? "")")
        }
    }.resume()
}

private func loadRecordedAudio() -> Data? {
    // Load from temp directory
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let audioURL = documentsPath.appendingPathComponent("voice_recording.m4a")
    return try? Data(contentsOf: audioURL)
}
```

TESTING:
```bash
# Full flow test
xcrun simctl io booted recordVideo task4-complete-flow.mp4

# Steps:
1. Select "Friendly Opener" script
2. Select "Coffee Shop" background
3. Start recording
4. Read script (simulate)
5. Stop recording
6. Submit to backend

# Check backend logs
tail -f ../../Backend/server.log | grep voice

# Final screenshot
xcrun simctl io booted screenshot task4-submission-complete.png
```

## VALIDATION REQUIREMENTS
1. ✅ All UI elements visible and interactive
2. ✅ Scripts load and display correctly
3. ✅ Background noise selection works
4. ✅ Recording animation smooth
5. ✅ Integration with backend verified

## COMMUNICATION PROTOCOL
```bash
git add -A
git commit -m "VoiceAgent: [Task X] completed - [description]"
echo "STATUS: Task X complete, screenshot: taskX.png" > .claude/status/voice.txt
```

## SUCCESS CRITERIA
- [ ] VoiceScript model created
- [ ] Script selection UI beautiful
- [ ] Background noise picker functional
- [ ] Recording flow integrated
- [ ] 5 screenshots captured
- [ ] 2 videos recorded
- [ ] Backend receives voice data