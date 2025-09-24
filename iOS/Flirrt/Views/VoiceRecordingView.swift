import SwiftUI
import AVFoundation

@MainActor
struct VoiceRecordingView: View {
    @StateObject private var recordingManager = VoiceRecordingManager()
    @EnvironmentObject private var apiClient: APIClient
    @EnvironmentObject private var authManager: AuthManager

    @State private var showingPermissionAlert = false
    @State private var isUploading = false
    @State private var uploadSuccess = false
    @State private var voiceCloneResponse: VoiceCloneResponse?
    @State private var selectedScript = 0
    @State private var showingScriptSheet = false
    @State private var backgroundNoiseSuppression = true
    @State private var selectedVoiceStyle = "natural"

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                headerSection

                Spacer()

                waveformSection

                Spacer()

                timerSection

                controlButtonsSection

                if recordingManager.hasValidRecording() {
                    uploadSection
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .background(
                LinearGradient(
                    colors: [Color.black, Color.gray.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("Voice Recording")
            .navigationBarTitleDisplayMode(.large)
            .alert("Microphone Permission Required", isPresented: $showingPermissionAlert) {
                Button("Settings") {
                    openAppSettings()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Please enable microphone access in Settings to record your voice.")
            }
            .alert("Error", isPresented: .constant(recordingManager.error != nil)) {
                Button("OK") {
                    recordingManager.error = nil
                }
            } message: {
                if let error = recordingManager.error {
                    Text(error.localizedDescription)
                }
            }
        }
        .onAppear {
            recordingManager.checkPermissions()
        }
        .sheet(isPresented: $showingScriptSheet) {
            ScriptSelectionView(selectedScript: $selectedScript)
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.pink)
                .scaleEffect(recordingManager.isRecording ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: recordingManager.isRecording)

            VStack(spacing: 8) {
                Text("Voice Clone Setup")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Record 2-3 minutes of clear speech to create your personalized voice clone")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Waveform Section
    private var waveformSection: some View {
        VStack(spacing: 16) {
            // Waveform Visualization
            WaveformView(
                levels: recordingManager.audioLevels,
                isRecording: recordingManager.isRecording,
                playbackProgress: recordingManager.playbackProgress,
                isPlaying: recordingManager.isPlaying
            )
            .frame(height: 100)
            .background(Color.black.opacity(0.3))
            .cornerRadius(12)

            // Recording Quality Indicator
            if recordingManager.isRecording {
                RecordingQualityIndicator(levels: recordingManager.audioLevels)
            }
        }
    }

    // MARK: - Timer Section
    private var timerSection: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Duration")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(recordingManager.formatDuration(recordingManager.recordingDuration))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Remaining")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(recordingManager.formatDuration(recordingManager.getRemainingTime()))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.pink)
                }
            }

            // Progress Bar
            ProgressView(value: recordingManager.recordingDuration, total: 180)
                .progressViewStyle(LinearProgressViewStyle(tint: .pink))
                .scaleEffect(x: 1, y: 2, anchor: .center)
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }

    // MARK: - Control Buttons Section
    private var controlButtonsSection: some View {
        VStack(spacing: 20) {
            // Main Record Button
            Button(action: {
                handleRecordButtonTap()
            }) {
                ZStack {
                    Circle()
                        .fill(recordingManager.isRecording ? Color.red : Color.pink)
                        .frame(width: 80, height: 80)
                        .scaleEffect(recordingManager.isRecording ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: recordingManager.isRecording)

                    Image(systemName: recordingManager.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }
            }
            .disabled(recordingManager.permissionStatus == .denied)

            // Playback Controls
            if recordingManager.hasValidRecording() {
                HStack(spacing: 30) {
                    Button(action: {
                        if recordingManager.isPlaying {
                            recordingManager.pausePlayback()
                        } else {
                            recordingManager.startPlayback()
                        }
                    }) {
                        Image(systemName: recordingManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.pink)
                    }

                    Button(action: {
                        recordingManager.stopPlayback()
                    }) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                    }

                    Button(action: {
                        recordingManager.deleteCurrentRecording()
                    }) {
                        Image(systemName: "trash.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                    }
                }
            }

            // Recording Instructions and Script Selection
            if !recordingManager.isRecording && !recordingManager.hasValidRecording() {
                VStack(spacing: 16) {
                    // Script Selection Button
                    Button(action: { showingScriptSheet = true }) {
                        HStack {
                            Image(systemName: "doc.text")
                            Text("Select Reading Script")
                            Spacer()
                            Text(getScriptTitle(selectedScript))
                                .foregroundColor(.gray)
                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.pink.opacity(0.2))
                        .cornerRadius(10)
                    }

                    // Background Noise Toggle
                    HStack {
                        Label("Background Noise Suppression", systemImage: "waveform.badge.minus")
                            .foregroundColor(.white)
                        Spacer()
                        Toggle("", isOn: $backgroundNoiseSuppression)
                            .labelsHidden()
                    }
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(10)

                    // Voice Style Selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Voice Style")
                            .font(.caption)
                            .foregroundColor(.gray)

                        HStack(spacing: 12) {
                            ForEach(["natural", "energetic", "calm"], id: \.self) { style in
                                Button(action: { selectedVoiceStyle = style }) {
                                    Text(style.capitalized)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(selectedVoiceStyle == style ? Color.pink : Color.gray.opacity(0.3))
                                        .foregroundColor(.white)
                                        .cornerRadius(15)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(10)

                    VStack(spacing: 8) {
                        Text("Recording Tips:")
                            .font(.headline)
                            .foregroundColor(.white)

                        VStack(alignment: .leading, spacing: 4) {
                            TipRow(icon: "mic", text: "Speak clearly and naturally")
                            TipRow(icon: "speaker.wave.2", text: "Find a quiet environment")
                            TipRow(icon: "clock", text: "Record for 2-3 minutes")
                            TipRow(icon: "textformat", text: "Use varied vocabulary and emotions")
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - Upload Section
    private var uploadSection: some View {
        VStack(spacing: 16) {
            if !uploadSuccess {
                Button(action: {
                    Task {
                        await uploadVoiceClone()
                    }
                }) {
                    HStack {
                        if isUploading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "icloud.and.arrow.up")
                                .font(.title2)
                        }

                        Text(isUploading ? "Creating Voice Clone..." : "Create Voice Clone")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.pink, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .disabled(isUploading || !recordingManager.hasValidRecording())

                if let fileSize = recordingManager.getRecordingFileSize() {
                    Text("File size: \(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file))")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)

                    Text("Voice Clone Created Successfully!")
                        .font(.headline)
                        .foregroundColor(.white)

                    if let response = voiceCloneResponse {
                        Text("Voice ID: \(response.voiceId)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.green.opacity(0.2))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Helper Methods
    private func handleRecordButtonTap() {
        if recordingManager.permissionStatus == .denied {
            showingPermissionAlert = true
            return
        }

        if recordingManager.isRecording {
            recordingManager.stopRecording()
        } else {
            Task {
                if recordingManager.permissionStatus == .undetermined {
                    let granted = await recordingManager.requestPermissions()
                    if !granted {
                        showingPermissionAlert = true
                        return
                    }
                }
                await recordingManager.startRecording()
            }
        }
    }

    private func uploadVoiceClone() async {
        guard let userId = authManager.currentUser?.id else { return }

        isUploading = true

        do {
            // Apply background noise suppression if enabled
            if backgroundNoiseSuppression {
                await recordingManager.applyNoiseSuppression()
            }

            // Add metadata for voice style
            let metadata = [
                "style": selectedVoiceStyle,
                "script": getScriptTitle(selectedScript),
                "noiseSuppression": String(backgroundNoiseSuppression)
            ]

            let response = try await recordingManager.uploadVoiceClone(userId: userId)
            voiceCloneResponse = response
            uploadSuccess = true

            // Store voice ID securely
            UserDefaults.standard.set(response.voiceId, forKey: "user_voice_id")

            // Update shared data manager
            if let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt.shared") {
                sharedDefaults.set(response.voiceId, forKey: "user_voice_id")
                sharedDefaults.synchronize()
            }

            // Post notification for successful voice clone
            NotificationCenter.default.post(
                name: .voiceCloneCreated,
                object: VoiceClone(
                    id: response.voiceId,
                    name: selectedVoiceStyle.capitalized,
                    description: "Created on \(Date())",
                    createdAt: Date()
                )
            )
        } catch {
            recordingManager.error = VoiceRecordingError.uploadFailed(error.localizedDescription)
        }

        isUploading = false
    }

    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }

    private func getScriptTitle(_ index: Int) -> String {
        let scripts = [
            "Rainbow Passage",
            "Custom Text",
            "Conversational Phrases",
            "Emotional Range"
        ]
        return scripts[safe: index] ?? "Rainbow Passage"
    }
}

// MARK: - Script Selection View
@MainActor
struct ScriptSelectionView: View {
    @Binding var selectedScript: Int
    @Environment(\.dismiss) private var dismiss

    let scripts = [
        (
            title: "Rainbow Passage",
            description: "Standard phonetically balanced passage",
            text: "When the sunlight strikes raindrops in the air, they act as a prism and form a rainbow. The rainbow is a division of white light into many beautiful colors. These take the shape of a long round arch, with its path high above, and its two ends apparently beyond the horizon."
        ),
        (
            title: "Custom Text",
            description: "Read your own prepared text",
            text: "Prepare your own 2-3 minute script covering various topics and emotions. Include questions, statements, and exclamations for best results."
        ),
        (
            title: "Conversational Phrases",
            description: "Natural conversation examples",
            text: "Hey there! How's it going? I was just thinking about that amazing coffee place we went to last week. Remember how they made that perfect cappuccino? We should definitely go back there soon. What do you think?"
        ),
        (
            title: "Emotional Range",
            description: "Express different emotions",
            text: "I'm so excited about this opportunity! (Happy) Oh no, I can't believe that happened. (Concerned) That's absolutely incredible! (Amazed) I'm not sure about that. (Uncertain) This is perfect! (Satisfied)"
        )
    ]

    var body: some View {
        NavigationView {
            List(scripts.indices, id: \.self) { index in
                Button(action: {
                    selectedScript = index
                    dismiss()
                }) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(scripts[index].title)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedScript == index {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.pink)
                            }
                        }

                        Text(scripts[index].description)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(scripts[index].text)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                            .padding(.top, 4)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Select Reading Script")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Safe Array Extension
extension Array {
    subscript(safe index: Int) -> Element? {
        guard index >= 0 && index < count else { return nil }
        return self[index]
    }
}

// MARK: - Supporting Views

@MainActor
struct WaveformView: View {
    let levels: [Float]
    let isRecording: Bool
    let playbackProgress: Double
    let isPlaying: Bool

    private let barWidth: CGFloat = 3
    private let barSpacing: CGFloat = 2

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .center, spacing: barSpacing) {
                ForEach(Array(levels.enumerated()), id: \.offset) { index, level in
                    WaveformBar(
                        level: level,
                        isActive: isActive(for: index, geometry: geometry),
                        maxHeight: geometry.size.height
                    )
                }

                // Fill remaining space with inactive bars if needed
                let remainingBars = max(0, Int(geometry.size.width / (barWidth + barSpacing)) - levels.count)
                ForEach(0..<remainingBars, id: \.self) { _ in
                    WaveformBar(level: 0, isActive: false, maxHeight: geometry.size.height)
                }
            }
        }
    }

    private func isActive(for index: Int, geometry: GeometryProxy) -> Bool {
        if isRecording {
            // Show recent bars as active during recording
            return index >= max(0, levels.count - 10)
        } else if isPlaying {
            // Show progress during playback
            let progressIndex = Int(Double(levels.count) * playbackProgress)
            return index <= progressIndex
        }
        return false
    }
}

@MainActor
struct WaveformBar: View {
    let level: Float
    let isActive: Bool
    let maxHeight: CGFloat

    private let minHeight: CGFloat = 4

    var body: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(barColor)
            .frame(width: 3, height: barHeight)
            .animation(.easeInOut(duration: 0.1), value: level)
    }

    private var barHeight: CGFloat {
        let normalizedLevel = max(0, min(1, level))
        return max(minHeight, CGFloat(normalizedLevel) * maxHeight)
    }

    private var barColor: Color {
        if isActive {
            return level > 0.7 ? .pink : (level > 0.3 ? .white : .gray)
        } else {
            return .gray.opacity(0.3)
        }
    }
}

@MainActor
struct RecordingQualityIndicator: View {
    let levels: [Float]

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: qualityIcon)
                .foregroundColor(qualityColor)

            Text(qualityText)
                .font(.caption)
                .foregroundColor(qualityColor)
        }
    }

    private var averageLevel: Float {
        guard !levels.isEmpty else { return 0 }
        return levels.reduce(0, +) / Float(levels.count)
    }

    private var qualityIcon: String {
        switch averageLevel {
        case 0.6...:
            return "checkmark.circle.fill"
        case 0.3..<0.6:
            return "exclamationmark.triangle.fill"
        default:
            return "xmark.circle.fill"
        }
    }

    private var qualityColor: Color {
        switch averageLevel {
        case 0.6...:
            return .green
        case 0.3..<0.6:
            return .orange
        default:
            return .red
        }
    }

    private var qualityText: String {
        switch averageLevel {
        case 0.6...:
            return "Excellent quality"
        case 0.3..<0.6:
            return "Speak louder"
        default:
            return "Too quiet"
        }
    }
}

@MainActor
struct TipRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.pink)
                .frame(width: 16)

            Text(text)
                .font(.caption)
                .foregroundColor(.gray)

            Spacer()
        }
    }
}

// MARK: - Preview
struct VoiceRecordingView_Previews: PreviewProvider {
    static var previews: some View {
        VoiceRecordingView()
            .environmentObject(APIClient())
            .environmentObject(AuthManager())
    }
}