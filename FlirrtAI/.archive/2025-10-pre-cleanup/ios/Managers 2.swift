import SwiftUI
import Combine

// API Client for handling network requests
class APIClient: ObservableObject {
    @Published var isLoading = false
    @Published var error: String?
    
    private let baseURL = "https://api.flirrt.com" // Replace with your actual API URL
    
    // Example API method - you can expand this
    func makeRequest<T: Codable>(endpoint: String, type: T.Type) async throws -> T {
        isLoading = true
        defer { isLoading = false }
        
        guard let url = URL(string: baseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let result = try JSONDecoder().decode(T.self, from: data)
        return result
    }
    
    // Placeholder methods for your app's functionality
    func analyzeScreenshot(_ image: UIImage) async throws {
        // Implement screenshot analysis API call
        isLoading = true
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 second delay for demo
        isLoading = false
    }
    
    func generateFlirt(context: String) async throws -> String {
        // Implement flirt generation API call
        isLoading = true
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 second delay for demo
        isLoading = false
        return "Hey! Are you a magician? Because every time I look at you, everyone else disappears! ✨"
    }
}

// Shared Data Manager for app-wide state
class SharedDataManager: ObservableObject {
    @Published var currentVoiceId: String?
    @Published var userPreferences: [String: Any] = [:]
    @Published var recentActivity: [ActivityItem] = []
    
    init() {
        loadPersistedData()
    }
    
    func setVoiceId(_ id: String) {
        currentVoiceId = id
        UserDefaults.standard.set(id, forKey: "currentVoiceId")
    }
    
    func clearVoiceData() {
        currentVoiceId = nil
        UserDefaults.standard.removeObject(forKey: "currentVoiceId")
    }
    
    func addActivity(_ activity: ActivityItem) {
        recentActivity.insert(activity, at: 0)
        if recentActivity.count > 20 {
            recentActivity.removeLast()
        }
    }
    
    private func loadPersistedData() {
        currentVoiceId = UserDefaults.standard.string(forKey: "currentVoiceId")
        
        // Load some mock recent activity for demo
        recentActivity = [
            ActivityItem(
                type: .screenshot,
                title: "Screenshot Analysis",
                description: "Dating app conversation",
                timestamp: Date().addingTimeInterval(-3600)
            ),
            ActivityItem(
                type: .flirt,
                title: "Generated Flirt",
                description: "\"Are you a magician?...\"",
                timestamp: Date().addingTimeInterval(-7200)
            )
        ]
    }
}

// Supporting types
enum APIError: Error, LocalizedError {
    case invalidURL
    case noData
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .decodingError:
            return "Failed to decode response"
        }
    }
}

struct ActivityItem: Identifiable {
    let id = UUID()
    let type: ActivityType
    let title: String
    let description: String
    let timestamp: Date
    
    enum ActivityType {
        case screenshot, flirt, voice, analysis
        
        var icon: String {
            switch self {
            case .screenshot: return "camera.fill"
            case .flirt: return "heart.fill"
            case .voice: return "waveform"
            case .analysis: return "brain.head.profile"
            }
        }
        
        var color: Color {
            switch self {
            case .screenshot: return .blue
            case .flirt: return .pink
            case .voice: return .purple
            case .analysis: return .green
            }
        }
    }
}