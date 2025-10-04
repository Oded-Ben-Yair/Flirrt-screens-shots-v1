import SwiftUI

// Placeholder for VoiceRecordingView
struct VoiceRecordingView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var sharedDataManager: SharedDataManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.pink)
                
                Text("Voice Recording")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("This feature is coming soon!")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                Button("Set Mock Voice ID") {
                    // For testing - set a mock voice ID
                    sharedDataManager.setVoiceId("mock_voice_id")
                    presentationMode.wrappedValue.dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.pink)
                .cornerRadius(12)
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
    }
}

// Placeholder for SettingsView
struct SettingsView: View {
    @EnvironmentObject private var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Settings")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                
                Text("Settings and preferences will be here")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                
                Button("Logout") {
                    authManager.logout()
                }
                .font(.headline)
                .foregroundColor(.red)
                .padding()
                .background(Color.black.opacity(0.3))
                .cornerRadius(12)
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
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}