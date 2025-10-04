import Foundation
import Combine

class SharedDataManager: ObservableObject {
    @Published var currentVoiceId: String?
    @Published var voiceClones: [VoiceClone] = []
    @Published var recentRecordings: [VoiceRecording] = []

    private let userDefaults = UserDefaults.standard
    private let sharedDefaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)

    init() {
        loadStoredData()
        setupNotificationObservers()
    }

    private func loadStoredData() {
        // Load current voice ID
        currentVoiceId = userDefaults.string(forKey: AppConstants.UserDefaultsKeys.userVoiceId)

        // Load voice clones
        if let data = userDefaults.data(forKey: AppConstants.UserDefaultsKeys.voiceClones),
           let clones = try? JSONDecoder().decode([VoiceClone].self, from: data) {
            voiceClones = clones
        }

        // Load recent recordings
        if let data = userDefaults.data(forKey: AppConstants.UserDefaultsKeys.recentRecordings),
           let recordings = try? JSONDecoder().decode([VoiceRecording].self, from: data) {
            recentRecordings = recordings
        }
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleVoiceCloneCreated),
            name: .voiceCloneCreated,
            object: nil
        )
    }

    @objc private func handleVoiceCloneCreated(_ notification: Notification) {
        if let voiceClone = notification.object as? VoiceClone {
            addVoiceClone(voiceClone)
        }
    }

    func setCurrentVoiceId(_ voiceId: String) {
        currentVoiceId = voiceId
        userDefaults.set(voiceId, forKey: AppConstants.UserDefaultsKeys.userVoiceId)
        sharedDefaults?.set(voiceId, forKey: AppConstants.UserDefaultsKeys.userVoiceId)
    }

    func addVoiceClone(_ voiceClone: VoiceClone) {
        voiceClones.append(voiceClone)
        saveVoiceClones()

        // Set as current voice if it's the first one
        if currentVoiceId == nil {
            setCurrentVoiceId(voiceClone.id)
        }
    }

    func addRecording(_ recording: VoiceRecording) {
        recentRecordings.insert(recording, at: 0)

        // Keep only the last 10 recordings
        if recentRecordings.count > 10 {
            recentRecordings = Array(recentRecordings.prefix(10))
        }

        saveRecentRecordings()
    }

    func removeRecording(_ recording: VoiceRecording) {
        recentRecordings.removeAll { $0.id == recording.id }
        saveRecentRecordings()

        // Clean up file if it exists
        if FileManager.default.fileExists(atPath: recording.fileURL.path) {
            try? FileManager.default.removeItem(at: recording.fileURL)
        }
    }

    private func saveVoiceClones() {
        if let data = try? JSONEncoder().encode(voiceClones) {
            userDefaults.set(data, forKey: AppConstants.UserDefaultsKeys.voiceClones)
        }
    }

    private func saveRecentRecordings() {
        if let data = try? JSONEncoder().encode(recentRecordings) {
            userDefaults.set(data, forKey: AppConstants.UserDefaultsKeys.recentRecordings)
        }
    }

    func clearAllData() {
        currentVoiceId = nil
        voiceClones = []
        recentRecordings = []

        userDefaults.removeObject(forKey: AppConstants.UserDefaultsKeys.userVoiceId)
        userDefaults.removeObject(forKey: AppConstants.UserDefaultsKeys.voiceClones)
        userDefaults.removeObject(forKey: AppConstants.UserDefaultsKeys.recentRecordings)

        sharedDefaults?.removeObject(forKey: AppConstants.UserDefaultsKeys.userVoiceId)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let voiceCloneCreated = Notification.Name("voiceCloneCreated")
}