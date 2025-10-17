import SwiftUI
import AVFoundation

// Voice Recording View
struct VoiceRecordingView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var sharedDataManager: SharedDataManager
    
    @State private var isRecording = false
    @State private var recordingTime = 0
    @State private var showingSuccess = false
    @State private var recordingProgress: CGFloat = 0.0
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 40) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "waveform.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.pink)
                    
                    Text("Voice Clone Setup")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Record 30 seconds of your voice to create your AI clone")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Recording Progress
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                            .frame(width: 200, height: 200)
                        
                        Circle()
                            .trim(from: 0, to: recordingProgress)
                            .stroke(Color.pink, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 200, height: 200)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: recordingProgress)
                        
                        VStack {
                            if isRecording {
                                Text("\(recordingTime)")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text("seconds")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            } else {
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.pink)
                            }
                        }
                    }
                    
                    if !isRecording && recordingTime == 0 {
                        Text("Tap to start recording")
                            .font(.headline)
                            .foregroundColor(.white)
                    } else if isRecording {
                        Text("Recording... speak clearly")
                            .font(.headline)
                            .foregroundColor(.pink)
                    } else if recordingTime > 0 {
                        Text("Recording complete!")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                }
                
                // Recording Button
                Button(action: toggleRecording) {
                    ZStack {
                        Circle()
                            .fill(isRecording ? Color.red : Color.pink)
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                }
                .disabled(recordingTime >= 30)
                .scaleEffect(isRecording ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isRecording)
                
                // Action Buttons
                HStack(spacing: 20) {
                    if recordingTime >= 15 { // Minimum 15 seconds
                        Button("Save Voice Clone") {
                            saveVoiceClone()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(12)
                    }
                    
                    if recordingTime > 0 {
                        Button("Reset") {
                            resetRecording()
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.gray)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                LinearGradient(
                    colors: [Color.black, Color.gray.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("Voice Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onReceive(timer) { _ in
            if isRecording && recordingTime < 30 {
                recordingTime += 1
                recordingProgress = CGFloat(recordingTime) / 30.0
                
                if recordingTime >= 30 {
                    stopRecording()
                }
            }
        }
        .alert("Voice Clone Created!", isPresented: $showingSuccess) {
            Button("Great!") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Your AI voice clone has been successfully created and is ready to use!")
        }
    }
    
    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        isRecording = true
        recordingTime = 0
        recordingProgress = 0
        
        // In a real app, you'd start actual audio recording here
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func stopRecording() {
        isRecording = false
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func resetRecording() {
        isRecording = false
        recordingTime = 0
        recordingProgress = 0
    }
    
    private func saveVoiceClone() {
        // Generate a mock voice ID
        let voiceId = "voice_\(UUID().uuidString.prefix(8))"
        sharedDataManager.setVoiceId(voiceId)
        
        // Add to activity
        sharedDataManager.addActivity(
            ActivityItem(
                type: .voice,
                title: "Voice Clone Created",
                description: "AI voice ready to use",
                timestamp: Date()
            )
        )
        
        showingSuccess = true
    }
}

// Settings View
struct SettingsView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var sharedDataManager: SharedDataManager
    
    @State private var notificationsEnabled = true
    @State private var soundEnabled = true
    @State private var showingLogoutAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // Profile Section
                Section {
                    HStack {
                        Circle()
                            .fill(Color.pink.opacity(0.2))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.title2)
                                    .foregroundColor(.pink)
                            )
                        
                        VStack(alignment: .leading) {
                            Text(authManager.currentUser?.fullName ?? "User")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text(authManager.currentUser?.email ?? "")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.black.opacity(0.3))
                
                // Voice Settings
                Section("Voice Settings") {
                    HStack {
                        Image(systemName: "waveform")
                            .foregroundColor(.pink)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading) {
                            Text("Voice Clone Status")
                                .foregroundColor(.white)
                            
                            Text(sharedDataManager.currentVoiceId != nil ? "Active" : "Not Set")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        if sharedDataManager.currentVoiceId != nil {
                            Button("Reset") {
                                sharedDataManager.clearVoiceData()
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
                .listRowBackground(Color.black.opacity(0.3))
                
                // App Settings
                Section("Preferences") {
                    Toggle(isOn: $notificationsEnabled) {
                        HStack {
                            Image(systemName: "bell")
                                .foregroundColor(.pink)
                                .frame(width: 24)
                            Text("Notifications")
                                .foregroundColor(.white)
                        }
                    }
                    .tint(.pink)
                    
                    Toggle(isOn: $soundEnabled) {
                        HStack {
                            Image(systemName: "speaker.wave.2")
                                .foregroundColor(.pink)
                                .frame(width: 24)
                            Text("Sound Effects")
                                .foregroundColor(.white)
                        }
                    }
                    .tint(.pink)
                }
                .listRowBackground(Color.black.opacity(0.3))
                
                // About Section
                Section("About") {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.pink)
                            .frame(width: 24)
                        Text("App Version")
                            .foregroundColor(.white)
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.gray)
                    }
                    
                    HStack {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.pink)
                            .frame(width: 24)
                        Text("Help & Support")
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                    }
                }
                .listRowBackground(Color.black.opacity(0.3))
                
                // Logout Section
                Section {
                    Button(action: {
                        showingLogoutAlert = true
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                                .frame(width: 24)
                            Text("Logout")
                                .foregroundColor(.red)
                        }
                    }
                }
                .listRowBackground(Color.black.opacity(0.3))
            }
            .scrollContentBackground(.hidden)
            .background(
                LinearGradient(
                    colors: [Color.black, Color.gray.opacity(0.3)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .preferredColorScheme(.dark)
        }
        .alert("Logout", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                authManager.logout()
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
    }
}