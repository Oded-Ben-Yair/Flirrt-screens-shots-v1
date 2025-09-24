import Foundation
import Combine

class SharedDataManager: ObservableObject {
    @Published var currentVoiceId: String?
    @Published var voiceClones: [VoiceClone] = []
    @Published var recentRecordings: [VoiceRecording] = []
    @Published var onboardingRequested: Bool = false
    @Published var analysisRequested = false
    @Published var voiceRequest: VoiceRequest? = nil

    private let userDefaults = UserDefaults.standard
    private let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt.shared")

    init() {
        loadStoredData()
        setupNotificationObservers()
        setupDarwinNotifications()
    }

    private func loadStoredData() {
        // Load current voice ID
        currentVoiceId = userDefaults.string(forKey: "user_voice_id")

        // Load voice clones
        if let data = userDefaults.data(forKey: "voice_clones"),
           let clones = try? JSONDecoder().decode([VoiceClone].self, from: data) {
            voiceClones = clones
        }

        // Load recent recordings
        if let data = userDefaults.data(forKey: "recent_recordings"),
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

    private func setupDarwinNotifications() {
        let center = CFNotificationCenterGetDarwinNotifyCenter()

        // Onboarding Request Observer
        CFNotificationCenterAddObserver(
            center,
            Unmanaged.passUnretained(self).toOpaque(),
            { (center, observer, name, object, userInfo) in
                guard let observer = observer else { return }
                let sharedDataManager = Unmanaged<SharedDataManager>.fromOpaque(observer).takeUnretainedValue()
                sharedDataManager.handleOnboardingRequest()
            },
            "com.flirrt.onboarding.request" as CFString,
            nil,
            .deliverImmediately
        )

        // Screenshot Analysis Request Observer
        CFNotificationCenterAddObserver(
            center,
            Unmanaged.passUnretained(self).toOpaque(),
            { (center, observer, name, object, userInfo) in
                guard let observer = observer else { return }
                let manager = Unmanaged<SharedDataManager>.fromOpaque(observer).takeUnretainedValue()
                DispatchQueue.main.async {
                    manager.analysisRequested = true
                }
            },
            "com.flirrt.analyze.request" as CFString,
            nil,
            .deliverImmediately
        )

        // Voice Synthesis Request Observer
        CFNotificationCenterAddObserver(
            center,
            Unmanaged.passUnretained(self).toOpaque(),
            { (center, observer, name, object, userInfo) in
                guard let observer = observer else { return }
                let manager = Unmanaged<SharedDataManager>.fromOpaque(observer).takeUnretainedValue()
                manager.handleVoiceRequest()
            },
            "com.flirrt.voice.request" as CFString,
            nil,
            .deliverImmediately
        )
    }

    private func handleOnboardingRequest() {
        DispatchQueue.main.async { [weak self] in
            print("Darwin notification received: Onboarding requested from keyboard extension")
            self?.onboardingRequested = true

            // Update shared state
            self?.sharedDefaults?.set(true, forKey: "onboarding_triggered_from_main")
            self?.sharedDefaults?.set(Date().timeIntervalSince1970, forKey: "onboarding_trigger_time")
            self?.sharedDefaults?.synchronize()
        }
    }

    @objc private func handleVoiceCloneCreated(_ notification: Notification) {
        if let voiceClone = notification.object as? VoiceClone {
            addVoiceClone(voiceClone)
        }
    }

    private func handleVoiceRequest() {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.flirrt.shared") else { return }
        let requestURL = containerURL.appendingPathComponent("voice_request.json")

        if let data = try? Data(contentsOf: requestURL) {
            if let request = try? JSONDecoder().decode(VoiceRequest.self, from: data) {
                DispatchQueue.main.async {
                    self.voiceRequest = request
                }
            }
        }
    }

    func setCurrentVoiceId(_ voiceId: String) {
        currentVoiceId = voiceId
        userDefaults.set(voiceId, forKey: "user_voice_id")
        sharedDefaults?.set(voiceId, forKey: "user_voice_id")
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
            userDefaults.set(data, forKey: "voice_clones")
        }
    }

    private func saveRecentRecordings() {
        if let data = try? JSONEncoder().encode(recentRecordings) {
            userDefaults.set(data, forKey: "recent_recordings")
        }
    }

    func clearAllData() {
        currentVoiceId = nil
        voiceClones = []
        recentRecordings = []
        onboardingRequested = false

        userDefaults.removeObject(forKey: "user_voice_id")
        userDefaults.removeObject(forKey: "voice_clones")
        userDefaults.removeObject(forKey: "recent_recordings")

        sharedDefaults?.removeObject(forKey: "user_voice_id")
        sharedDefaults?.removeObject(forKey: "onboarding_triggered_from_main")
        sharedDefaults?.removeObject(forKey: "onboarding_trigger_time")
    }

    func resetOnboardingRequest() {
        onboardingRequested = false
        sharedDefaults?.removeObject(forKey: "onboarding_requested")
        sharedDefaults?.removeObject(forKey: "onboarding_request_time")
        sharedDefaults?.synchronize()
    }

    func completeOnboarding() {
        onboardingRequested = false
        sharedDefaults?.set(true, forKey: "onboarding_complete")
        sharedDefaults?.synchronize()
    }

    deinit {
        // Remove Darwin notification observer
        let notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterRemoveEveryObserver(notificationCenter, Unmanaged.passUnretained(self).toOpaque())
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let voiceCloneCreated = Notification.Name("voiceCloneCreated")
}