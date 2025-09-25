import Foundation
import Combine
import OSLog

@globalActor
actor SharedDataActor {
    static let shared = SharedDataActor()
}

@MainActor
final class SharedDataManager: ObservableObject {
    @Published var currentVoiceId: String?
    @Published var voiceClones: [VoiceClone] = []
    @Published var recentRecordings: [VoiceRecording] = []
    @Published var onboardingRequested: Bool = false
    @Published var analysisRequested = false
    @Published var voiceRequest: VoiceRequest? = nil

    // Concurrency management
    private var cancellables = Set<AnyCancellable>()
    private let logger = Logger(subsystem: "com.flirrt.app", category: "SharedDataManager")
    private actor DataStore {
        private var _currentVoiceId: String?
        private var _voiceClones: [VoiceClone] = []
        private var _recentRecordings: [VoiceRecording] = []

        func getCurrentVoiceId() -> String? { _currentVoiceId }
        func getVoiceClones() -> [VoiceClone] { _voiceClones }
        func getRecentRecordings() -> [VoiceRecording] { _recentRecordings }

        func setCurrentVoiceId(_ id: String?) { _currentVoiceId = id }
        func setVoiceClones(_ clones: [VoiceClone]) { _voiceClones = clones }
        func setRecentRecordings(_ recordings: [VoiceRecording]) { _recentRecordings = recordings }

        func addVoiceClone(_ clone: VoiceClone) {
            _voiceClones.append(clone)
        }

        func addRecording(_ recording: VoiceRecording) {
            _recentRecordings.insert(recording, at: 0)
            if _recentRecordings.count > 10 {
                _recentRecordings = Array(_recentRecordings.prefix(10))
            }
        }

        func removeRecording(withId id: String) {
            _recentRecordings.removeAll { $0.id == id }
        }
    }

    private let dataStore = DataStore()

    private let userDefaults = UserDefaults.standard
    private let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt.shared")

    init() {
        loadStoredData()
        setupNotificationObservers()
        setupDarwinNotifications()
    }

    private func loadStoredData() {
        Task { @MainActor in
            do {
                // Load current voice ID
                let voiceId = userDefaults.string(forKey: "user_voice_id")
                await dataStore.setCurrentVoiceId(voiceId)
                currentVoiceId = voiceId

                // Load voice clones
                if let data = userDefaults.data(forKey: "voice_clones"),
                   let clones = try? JSONDecoder().decode([VoiceClone].self, from: data) {
                    await dataStore.setVoiceClones(clones)
                    voiceClones = clones
                }

                // Load recent recordings
                if let data = userDefaults.data(forKey: "recent_recordings"),
                   let recordings = try? JSONDecoder().decode([VoiceRecording].self, from: data) {
                    await dataStore.setRecentRecordings(recordings)
                    recentRecordings = recordings
                }

                logger.info("Successfully loaded stored data with \(self.voiceClones.count) voice clones and \(self.recentRecordings.count) recordings")
            } catch {
                logger.error("Failed to load stored data: \(error.localizedDescription)")
            }
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
        Task { @MainActor [weak self] in
            guard let self = self else { return }

            logger.info("Darwin notification received: Onboarding requested from keyboard extension")
            self.onboardingRequested = true

            // Update shared state
            await Task.detached(priority: .userInitiated) {
                self.sharedDefaults?.set(true, forKey: "onboarding_triggered_from_main")
                self.sharedDefaults?.set(Date().timeIntervalSince1970, forKey: "onboarding_trigger_time")
                self.sharedDefaults?.synchronize()
            }.value
        }
    }

    @objc private func handleVoiceCloneCreated(_ notification: Notification) {
        if let voiceClone = notification.object as? VoiceClone {
            addVoiceClone(voiceClone)
        }
    }

    private func handleVoiceRequest() {
        Task { @MainActor [weak self] in
            guard let self = self else { return }

            do {
                guard let containerURL = FileManager.default.containerURL(
                    forSecurityApplicationGroupIdentifier: "group.com.flirrt.shared"
                ) else {
                    logger.error("Failed to get container URL for app group")
                    return
                }

                let requestURL = containerURL.appendingPathComponent("voice_request.json")

                let data = try Data(contentsOf: requestURL)
                let request = try JSONDecoder().decode(VoiceRequest.self, from: data)

                self.voiceRequest = request
                logger.info("Successfully loaded voice request for voice ID: \(request.voiceId)")
            } catch {
                logger.error("Failed to load voice request: \(error.localizedDescription)")
            }
        }
    }

    func setCurrentVoiceId(_ voiceId: String) {
        Task { @MainActor in
            await dataStore.setCurrentVoiceId(voiceId)
            currentVoiceId = voiceId

            await Task.detached(priority: .userInitiated) { [weak self] in
                self?.userDefaults.set(voiceId, forKey: "user_voice_id")
                self?.sharedDefaults?.set(voiceId, forKey: "user_voice_id")
                self?.sharedDefaults?.synchronize()
            }.value

            logger.info("Updated current voice ID to: \(voiceId)")
        }
    }

    func addVoiceClone(_ voiceClone: VoiceClone) {
        Task { @MainActor in
            await dataStore.addVoiceClone(voiceClone)
            voiceClones.append(voiceClone)
            await saveVoiceClones()

            // Set as current voice if it's the first one
            if currentVoiceId == nil {
                setCurrentVoiceId(voiceClone.id)
            }

            logger.info("Added voice clone: \(voiceClone.name) (ID: \(voiceClone.id))")
        }
    }

    func addRecording(_ recording: VoiceRecording) {
        Task { @MainActor in
            await dataStore.addRecording(recording)
            recentRecordings.insert(recording, at: 0)

            // Keep only the last 10 recordings
            if recentRecordings.count > 10 {
                recentRecordings = Array(recentRecordings.prefix(10))
            }

            await saveRecentRecordings()
            logger.info("Added recording: \(recording.fileName) (Duration: \(recording.formattedDuration))")
        }
    }

    func removeRecording(_ recording: VoiceRecording) {
        Task { @MainActor in
            await dataStore.removeRecording(withId: recording.id)
            recentRecordings.removeAll { $0.id == recording.id }
            await saveRecentRecordings()

            // Clean up file if it exists
            await Task.detached(priority: .utility) {
                if FileManager.default.fileExists(atPath: recording.fileURL.path) {
                    try? FileManager.default.removeItem(at: recording.fileURL)
                }
            }.value

            logger.info("Removed recording: \(recording.fileName)")
        }
    }

    private func saveVoiceClones() async {
        await Task.detached(priority: .utility) { [weak self] in
            guard let self = self else { return }

            do {
                let clones = await self.dataStore.getVoiceClones()
                let data = try JSONEncoder().encode(clones)
                self.userDefaults.set(data, forKey: "voice_clones")
                self.logger.debug("Successfully saved \(clones.count) voice clones")
            } catch {
                self.logger.error("Failed to save voice clones: \(error.localizedDescription)")
            }
        }.value
    }

    private func saveRecentRecordings() async {
        await Task.detached(priority: .utility) { [weak self] in
            guard let self = self else { return }

            do {
                let recordings = await self.dataStore.getRecentRecordings()
                let data = try JSONEncoder().encode(recordings)
                self.userDefaults.set(data, forKey: "recent_recordings")
                self.logger.debug("Successfully saved \(recordings.count) recent recordings")
            } catch {
                self.logger.error("Failed to save recent recordings: \(error.localizedDescription)")
            }
        }.value
    }

    func clearAllData() {
        Task { @MainActor in
            // Clear actor state
            await dataStore.setCurrentVoiceId(nil)
            await dataStore.setVoiceClones([])
            await dataStore.setRecentRecordings([])

            // Clear UI state
            currentVoiceId = nil
            voiceClones = []
            recentRecordings = []
            onboardingRequested = false

            // Clear persistent storage
            await Task.detached(priority: .userInitiated) { [weak self] in
                self?.userDefaults.removeObject(forKey: "user_voice_id")
                self?.userDefaults.removeObject(forKey: "voice_clones")
                self?.userDefaults.removeObject(forKey: "recent_recordings")

                self?.sharedDefaults?.removeObject(forKey: "user_voice_id")
                self?.sharedDefaults?.removeObject(forKey: "onboarding_triggered_from_main")
                self?.sharedDefaults?.removeObject(forKey: "onboarding_trigger_time")
                self?.sharedDefaults?.synchronize()
            }.value

            logger.info("Successfully cleared all data")
        }
    }

    func resetOnboardingRequest() {
        Task { @MainActor in
            onboardingRequested = false

            await Task.detached(priority: .userInitiated) { [weak self] in
                self?.sharedDefaults?.removeObject(forKey: "onboarding_requested")
                self?.sharedDefaults?.removeObject(forKey: "onboarding_request_time")
                self?.sharedDefaults?.synchronize()
            }.value

            logger.info("Reset onboarding request")
        }
    }

    func completeOnboarding() {
        Task { @MainActor in
            onboardingRequested = false

            await Task.detached(priority: .userInitiated) { [weak self] in
                self?.sharedDefaults?.set(true, forKey: "onboarding_complete")
                self?.sharedDefaults?.synchronize()
            }.value

            logger.info("Completed onboarding")
        }
    }

    deinit {
        // Cancel all tasks and subscriptions
        cancellables.removeAll()

        // Remove Darwin notification observer
        let notificationCenter = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterRemoveEveryObserver(notificationCenter, Unmanaged.passUnretained(self).toOpaque())

        logger.info("SharedDataManager deinitialized")
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let voiceCloneCreated = Notification.Name("voiceCloneCreated")
}