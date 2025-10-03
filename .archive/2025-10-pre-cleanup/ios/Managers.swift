import SwiftUI

// Basic APIClient - expand this based on your API needs
class APIClient: ObservableObject {
    @Published var isLoading = false
    @Published var error: String?
    
    // Add your API methods here
    func makeRequest() {
        // Placeholder for API calls
    }
}

// Basic SharedDataManager for app state
class SharedDataManager: ObservableObject {
    @Published var currentVoiceId: String?
    @Published var userPreferences: [String: Any] = [:]
    
    func setVoiceId(_ id: String) {
        currentVoiceId = id
    }
    
    func clearVoiceData() {
        currentVoiceId = nil
    }
}