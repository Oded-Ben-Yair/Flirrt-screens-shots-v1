import SwiftUI
import AVFoundation

@MainActor
struct VoiceRecordingFlowView: View {
    @StateObject private var recordingManager = VoiceRecordingManager()
    @EnvironmentObject private var apiClient: APIClient
    @EnvironmentObject private var authManager: AuthManager

    @State private var currentStep: RecordingStep = .scriptSelection
    @State private var selectedScript: VoiceScript?
    @State private var selectedBackgroundNoise: BackgroundNoise?
    @State private var backgroundVolume: Double = 0.3
    @State private var isUploading = false
    @State private var uploadSuccess = false
    @State private var voiceCloneResponse: VoiceCloneResponse?
    @State private var showingPermissionAlert = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.black, Color.gray.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // Main content
                VStack(spacing: 0) {
                    // Progress indicator
                    RecordingProgressIndicator(currentStep: currentStep)
                        .padding(.horizontal)
                        .padding(.top)

                    // Step content
                    TabView(selection: $currentStep) {
                        // Step 1: Script Selection
                        ScriptSelectionStep(
                            selectedScript: $selectedScript,
                            onNext: {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    currentStep = .backgroundNoise
                                }
                            }
                        )
                        .tag(RecordingStep.scriptSelection)

                        // Step 2: Background Noise
                        BackgroundNoiseStep(
                            selectedNoise: $selectedBackgroundNoise,
                            volume: $backgroundVolume,
                            onNext: {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    currentStep = .recording
                                }
                            },
                            onBack: {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    currentStep = .scriptSelection
                                }
                            }
                        )
                        .tag(RecordingStep.backgroundNoise)

                        // Step 3: Recording
                        RecordingStepView(
                            selectedScript: selectedScript,
                            selectedNoise: selectedBackgroundNoise,
                            backgroundVolume: backgroundVolume,
                            recordingManager: recordingManager,
                            onNext: {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    currentStep = .processing
                                }
                                Task {
                                    await uploadVoiceClone()
                                }
                            },
                            onBack: {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    currentStep = .backgroundNoise
                                }
                            }
                        )
                        .tag(RecordingStep.recording)

                        // Step 4: Processing
                        ProcessingStep(
                            isUploading: isUploading,
                            uploadSuccess: uploadSuccess,
                            voiceCloneResponse: voiceCloneResponse,
                            onComplete: {
                                // Handle completion
                            }
                        )
                        .tag(RecordingStep.processing)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.5), value: currentStep)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(currentStep == .recording)
            .alert("Microphone Permission Required", isPresented: $showingPermissionAlert) {
                Button("Settings") {
                    openAppSettings()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Please enable microphone access in Settings to record your voice.")
            }
        }
    }

    private func uploadVoiceClone() async {
        guard let userId = authManager.currentUser?.id else { return }

        isUploading = true

        do {
            let response = try await recordingManager.uploadVoiceClone(userId: userId)
            voiceCloneResponse = response
            uploadSuccess = true

            // Store voice ID securely
            UserDefaults.standard.set(response.voiceId, forKey: "user_voice_id")
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
}

// MARK: - Recording Steps
enum RecordingStep: CaseIterable {
    case scriptSelection
    case backgroundNoise
    case recording
    case processing

    var title: String {
        switch self {
        case .scriptSelection:
            return "Choose Script"
        case .backgroundNoise:
            return "Background Audio"
        case .recording:
            return "Record Voice"
        case .processing:
            return "Processing"
        }
    }

    var icon: String {
        switch self {
        case .scriptSelection:
            return "doc.text"
        case .backgroundNoise:
            return "speaker.wave.2"
        case .recording:
            return "mic"
        case .processing:
            return "gear"
        }
    }
}

// MARK: - Progress Indicator
@MainActor
struct RecordingProgressIndicator: View {
    let currentStep: RecordingStep

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(RecordingStep.allCases.enumerated()), id: \.element) { index, step in
                HStack(spacing: 0) {
                    // Step circle
                    ZStack {
                        Circle()
                            .fill(stepColor(for: step))
                            .frame(width: 32, height: 32)

                        if isCompleted(step) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: step.icon)
                                .font(.system(size: 12))
                                .foregroundColor(step == currentStep ? .white : .gray)
                        }
                    }

                    // Connector line
                    if index < RecordingStep.allCases.count - 1 {
                        Rectangle()
                            .fill(isCompleted(step) ? Color.pink : Color.gray.opacity(0.3))
                            .frame(height: 2)
                            .animation(.easeInOut(duration: 0.3), value: currentStep)
                    }
                }
            }
        }
    }

    private func stepColor(for step: RecordingStep) -> Color {
        if isCompleted(step) {
            return .pink
        } else if step == currentStep {
            return .pink
        } else {
            return .gray.opacity(0.3)
        }
    }

    private func isCompleted(_ step: RecordingStep) -> Bool {
        let currentIndex = RecordingStep.allCases.firstIndex(of: currentStep) ?? 0
        let stepIndex = RecordingStep.allCases.firstIndex(of: step) ?? 0
        return stepIndex < currentIndex
    }
}

// MARK: - Step 1: Script Selection
@MainActor
struct ScriptSelectionStep: View {
    @Binding var selectedScript: VoiceScript?
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.pink)

                Text("Choose Your Script")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Select a script to read during recording for better voice quality")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }

            // Script options
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(VoiceScript.predefinedScripts.prefix(3)) { script in
                        ScriptSelectionCard(
                            script: script,
                            isSelected: selectedScript?.id == script.id
                        ) {
                            selectedScript = script
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Next button
            Button(action: onNext) {
                HStack {
                    Text("Continue")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Image(systemName: "arrow.right")
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(selectedScript != nil ? Color.pink : Color.gray)
                .cornerRadius(12)
            }
            .disabled(selectedScript == nil)
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}

@MainActor
struct ScriptSelectionCard: View {
    let script: VoiceScript
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: script.icon)
                        .font(.title2)
                        .foregroundColor(Color(script.category.color))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(script.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)

                        Text(script.formattedDuration)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.pink)
                    }
                }

                Text(script.content)
                    .font(.body)
                    .foregroundColor(.gray)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.pink : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Step 2: Background Noise
@MainActor
struct BackgroundNoiseStep: View {
    @Binding var selectedNoise: BackgroundNoise?
    @Binding var volume: Double
    let onNext: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.pink)

                Text("Background Audio")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Choose ambient sounds to enhance your recording environment")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }

            // Noise options
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 120), spacing: 16)
                ], spacing: 16) {
                    // None option
                    NoiseSelectionCard(
                        noise: nil,
                        isSelected: selectedNoise == nil,
                        onTap: { selectedNoise = nil }
                    )

                    // Predefined noises
                    ForEach(BackgroundNoise.predefinedNoises.prefix(5)) { noise in
                        NoiseSelectionCard(
                            noise: noise,
                            isSelected: selectedNoise?.id == noise.id,
                            onTap: { selectedNoise = noise }
                        )
                    }
                }
                .padding(.horizontal)
            }

            // Volume control
            if selectedNoise != nil {
                VStack(spacing: 12) {
                    Text("Volume: \(Int(volume * 100))%")
                        .font(.headline)
                        .foregroundColor(.white)

                    Slider(value: $volume, in: 0...1)
                        .accentColor(.pink)
                        .padding(.horizontal)
                }
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(12)
                .padding(.horizontal)
                .transition(.scale.combined(with: .opacity))
            }

            // Navigation buttons
            HStack(spacing: 16) {
                Button(action: onBack) {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("Back")
                    }
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.black.opacity(0.3))
                    .cornerRadius(12)
                }

                Button(action: onNext) {
                    HStack {
                        Text("Start Recording")
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.pink)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}

@MainActor
struct NoiseSelectionCard: View {
    let noise: BackgroundNoise?
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: 50, height: 50)

                    Image(systemName: iconName)
                        .font(.title3)
                        .foregroundColor(iconColor)
                }

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? iconColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var title: String {
        noise?.name ?? "Silence"
    }

    private var iconName: String {
        noise?.icon ?? "speaker.slash"
    }

    private var iconColor: Color {
        if let noise = noise {
            return Color(noise.category.color)
        }
        return .gray
    }

    private var backgroundColor: Color {
        if let noise = noise {
            return Color(noise.category.color).opacity(0.2)
        }
        return Color.gray.opacity(0.2)
    }
}

// MARK: - Step 3: Recording
@MainActor
struct RecordingStepView: View {
    let selectedScript: VoiceScript?
    let selectedNoise: BackgroundNoise?
    let backgroundVolume: Double
    @ObservedObject var recordingManager: VoiceRecordingManager
    let onNext: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Script display
            if let script = selectedScript {
                ScriptDisplayCard(script: script)
                    .padding(.horizontal)
            }

            // Waveform
            WaveformView(
                levels: recordingManager.audioLevels,
                isRecording: recordingManager.isRecording,
                playbackProgress: recordingManager.playbackProgress,
                isPlaying: recordingManager.isPlaying
            )
            .frame(height: 100)
            .background(Color.black.opacity(0.3))
            .cornerRadius(12)
            .padding(.horizontal)

            // Timer
            VStack(spacing: 8) {
                Text(recordingManager.formatDuration(recordingManager.recordingDuration))
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)

                ProgressView(value: recordingManager.recordingDuration, total: 180)
                    .progressViewStyle(LinearProgressViewStyle(tint: .pink))
                    .scaleEffect(x: 1, y: 3, anchor: .center)
                    .padding(.horizontal, 40)
            }

            // Record button
            Button(action: handleRecordButtonTap) {
                ZStack {
                    Circle()
                        .fill(recordingManager.isRecording ? Color.red : Color.pink)
                        .frame(width: 100, height: 100)
                        .scaleEffect(recordingManager.isRecording ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: recordingManager.isRecording)

                    Image(systemName: recordingManager.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
            }

            // Navigation
            if recordingManager.hasValidRecording() {
                HStack(spacing: 16) {
                    Button(action: onBack) {
                        Text("Back")
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(12)
                    }

                    Button(action: onNext) {
                        Text("Create Voice Clone")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.pink)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }

    private func handleRecordButtonTap() {
        if recordingManager.isRecording {
            Task {
                await recordingManager.stopRecording()
            }
        } else {
            Task {
                await recordingManager.startRecording()
            }
        }
    }
}

@MainActor
struct ScriptDisplayCard: View {
    let script: VoiceScript

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: script.icon)
                    .foregroundColor(Color(script.category.color))

                Text(script.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Spacer()
            }

            ScrollView {
                Text(script.content)
                    .font(.body)
                    .foregroundColor(.white)
                    .lineSpacing(4)
            }
            .frame(maxHeight: 120)
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
    }
}

// MARK: - Step 4: Processing
@MainActor
struct ProcessingStep: View {
    let isUploading: Bool
    let uploadSuccess: Bool
    let voiceCloneResponse: VoiceCloneResponse?
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            if !uploadSuccess {
                // Processing
                VStack(spacing: 20) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .pink))
                        .scaleEffect(2.0)

                    Text("Creating Your Voice Clone...")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    Text("This may take a few moments")
                        .font(.body)
                        .foregroundColor(.gray)
                }
            } else {
                // Success
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)

                    Text("Voice Clone Created!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    if let response = voiceCloneResponse {
                        Text("Voice ID: \(response.voiceId)")
                            .font(.body)
                            .foregroundColor(.gray)
                    }

                    Button(action: onComplete) {
                        Text("Continue")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.pink)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Voice Clone Response Model
// Using VoiceCloneResponse from APIClient.swift

// MARK: - Voice Recording Error
// Using VoiceRecordingError from VoiceRecordingManager.swift

// MARK: - Preview
struct VoiceRecordingFlowView_Previews: PreviewProvider {
    static var previews: some View {
        VoiceRecordingFlowView()
            .environmentObject(APIClient())
            .environmentObject(AuthManager())
    }
}