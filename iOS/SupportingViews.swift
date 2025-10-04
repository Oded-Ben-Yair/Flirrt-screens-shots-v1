import SwiftUI

// Voice Recording View
struct VoiceRecordingView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var sharedDataManager: SharedDataManager
    
    @State private var isRecording = false
    @State private var recordingTime = 0
    @State private var showingSuccess = false
    
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
                    
                    Text("Record your voice to create your AI clone")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Simple demo button
                Button("Create Mock Voice Clone") {
                    saveVoiceClone()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.pink)
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
            }
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
        .alert("Voice Clone Created!", isPresented: $showingSuccess) {
            Button("Great!") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Your AI voice clone has been successfully created and is ready to use!")
        }
    }
    
    private func saveVoiceClone() {
        // Generate a mock voice ID
        let voiceId = "voice_\(UUID().uuidString.prefix(8))"
        sharedDataManager.setVoiceId(voiceId)
        
        showingSuccess = true
    }
}

// Settings View
struct SettingsView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var sharedDataManager: SharedDataManager
    
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