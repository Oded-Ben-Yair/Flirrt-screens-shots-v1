import Foundation
import Combine
import OSLog
import UIKit
import ImageIO
import UniformTypeIdentifiers
import Photos

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

    // Screenshot Detection Properties
    @Published var lastScreenshotDetected: Date?
    @Published var screenshotDetectionEnabled: Bool = true
    @Published var screenshotDetectionStatus: String = "Ready"
    @Published var screenshotCounter: Int = 0

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

    // Image compression service - initialized lazily
    private lazy var imageCompressionService = ImageCompressionService()

    init() {
        loadStoredData()
        setupNotificationObservers()
        setupDarwinNotifications()
        setupScreenshotDetection()
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

    private func setupScreenshotDetection() {
        logger.info("🔍 Setting up ultra-fast screenshot detection")

        // Primary detection: UIApplication screenshot notification (fastest method)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScreenshotDetected),
            name: UIApplication.userDidTakeScreenshotNotification,
            object: nil
        )

        // Load saved detection state
        if let sharedDefaults = sharedDefaults {
            screenshotDetectionEnabled = sharedDefaults.bool(forKey: "screenshot_detection_enabled")
            screenshotCounter = sharedDefaults.integer(forKey: "screenshot_counter")
        }

        logger.info("📸 Screenshot detection initialized - Enabled: \(self.screenshotDetectionEnabled)")
    }

    @objc private func handleScreenshotDetected() {
        guard screenshotDetectionEnabled else {
            logger.debug("📱 Screenshot detection disabled, ignoring notification")
            return
        }

        let startTime = CFAbsoluteTimeGetCurrent()
        screenshotDetectionStatus = "Detecting..."
        lastScreenshotDetected = Date()
        screenshotCounter += 1

        let screenshotId = generateScreenshotId()
        logger.info("📸 INSTANT SCREENSHOT DETECTED - ID: \(screenshotId), Count: \(self.screenshotCounter)")

        Task { @MainActor in
            await self.processScreenshotDetection(screenshotId: screenshotId, startTime: startTime)
        }
    }

    private func processScreenshotDetection(screenshotId: String, startTime: CFAbsoluteTime) async {
        screenshotDetectionStatus = "Processing..."

        // Send instant Darwin notification to keyboard
        await sendScreenshotNotificationToKeyboard(screenshotId: screenshotId)

        // Store detection metadata
        await storeScreenshotMetadata(screenshotId: screenshotId)

        // Update shared state
        sharedDefaults?.set(screenshotCounter, forKey: "screenshot_counter")
        sharedDefaults?.set(Date().timeIntervalSince1970, forKey: "last_screenshot_time")
        sharedDefaults?.synchronize()

        let totalTime = CFAbsoluteTimeGetCurrent() - startTime
        logger.info("⚡ Screenshot detection complete in \(String(format: "%.3f", totalTime * 1000))ms")

        screenshotDetectionStatus = "Ready"
    }

    private func sendScreenshotNotificationToKeyboard(screenshotId: String) async {
        let notificationData: [String: Any] = [
            "screenshot_id": screenshotId,
            "timestamp": Date().timeIntervalSince1970,
            "counter": screenshotCounter,
            "confidence": 1.0, // Immediate detection = highest confidence
            "app_state": UIApplication.shared.applicationState.rawValue
        ]

        // Store notification data in App Groups for keyboard access
        await storeScreenshotNotificationData(notificationData, screenshotId: screenshotId)

        // Send Darwin notification (ultra-fast IPC)
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(
            center,
            CFNotificationName("com.flirrt.screenshot.detected" as CFString),
            nil,
            nil,
            true // Deliver immediately
        )

        logger.info("🚀 Darwin notification sent to keyboard for screenshot: \(screenshotId)")
    }

    private func storeScreenshotNotificationData(_ data: [String: Any], screenshotId: String) async {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.flirrt.shared"
        ) else {
            logger.error("❌ Failed to get container URL for screenshot notification")
            return
        }

        do {
            let notificationsDir = containerURL.appendingPathComponent("screenshot_notifications")
            try FileManager.default.createDirectory(at: notificationsDir, withIntermediateDirectories: true)

            let notificationFile = notificationsDir.appendingPathComponent("\(screenshotId).json")
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            try jsonData.write(to: notificationFile)

            // Update shared preferences with latest notification
            sharedDefaults?.set(screenshotId, forKey: "last_screenshot_id")
            sharedDefaults?.synchronize()

            logger.info("✅ Screenshot notification data stored for keyboard - ID: \(screenshotId)")
        } catch {
            logger.error("❌ Failed to store screenshot notification data: \(error.localizedDescription)")
        }
    }

    private func storeScreenshotMetadata(screenshotId: String) async {
        let metadata: [String: Any] = [
            "screenshot_id": screenshotId,
            "app_state": UIApplication.shared.applicationState.rawValue,
            "timestamp": Date().timeIntervalSince1970,
            "device_orientation": UIDevice.current.orientation.rawValue,
            "screen_brightness": UIScreen.main.brightness,
            "battery_level": UIDevice.current.batteryLevel,
            "low_power_mode": ProcessInfo.processInfo.isLowPowerModeEnabled,
            "detection_method": "UIApplication.userDidTakeScreenshotNotification"
        ]

        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.flirrt.shared"
        ) else {
            logger.warning("⚠️ Failed to get container URL for metadata storage")
            return
        }

        do {
            let metadataDir = containerURL.appendingPathComponent("screenshot_metadata")
            try FileManager.default.createDirectory(at: metadataDir, withIntermediateDirectories: true)

            let metadataFile = metadataDir.appendingPathComponent("\(screenshotId)_metadata.json")
            let jsonData = try JSONSerialization.data(withJSONObject: metadata)
            try jsonData.write(to: metadataFile)

            logger.debug("📋 Metadata stored for screenshot ID: \(screenshotId)")
        } catch {
            logger.warning("⚠️ Failed to store metadata: \(error.localizedDescription)")
        }
    }

    private func generateScreenshotId() -> String {
        let timestamp = Int(Date().timeIntervalSince1970 * 1000) // Milliseconds
        let random = Int.random(in: 1000...9999)
        return "screenshot_\(timestamp)_\(random)"
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

    // MARK: - Screenshot Detection Public Methods

    /// Enables or disables screenshot detection
    func setScreenshotDetectionEnabled(_ enabled: Bool) {
        screenshotDetectionEnabled = enabled
        logger.info("🔧 Screenshot detection \(enabled ? "enabled" : "disabled")")

        sharedDefaults?.set(enabled, forKey: "screenshot_detection_enabled")
        sharedDefaults?.synchronize()

        // Notify keyboard of detection status change
        Task {
            await sendDetectionStatusToKeyboard(enabled: enabled)
        }
    }

    /// Gets current screenshot detection statistics
    func getScreenshotDetectionStats() -> [String: Any] {
        return [
            "total_screenshots": screenshotCounter,
            "detection_enabled": screenshotDetectionEnabled,
            "last_detection": lastScreenshotDetected?.timeIntervalSince1970 ?? 0,
            "current_status": screenshotDetectionStatus
        ]
    }

    /// Manually triggers a test notification (for debugging)
    func triggerTestScreenshotNotification() async {
        logger.info("🧪 Triggering test screenshot notification")
        let testId = "test_\(Int(Date().timeIntervalSince1970))"
        await sendScreenshotNotificationToKeyboard(screenshotId: testId)
    }

    private func sendDetectionStatusToKeyboard(enabled: Bool) async {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let notificationName = enabled ? "com.flirrt.detection.enabled" : "com.flirrt.detection.disabled"

        CFNotificationCenterPostNotification(
            center,
            CFNotificationName(notificationName as CFString),
            nil,
            nil,
            true
        )

        logger.info("📡 Detection status notification sent to keyboard: \(enabled ? "enabled" : "disabled")")
    }

    // MARK: - Image Compression Methods

    /// Compresses an image with intelligent optimization for AI analysis
    /// - Parameters:
    ///   - image: The UIImage to compress
    ///   - targetFormat: Preferred output format (.heic for best compression)
    /// - Returns: Compressed image data and compression statistics
    func compressImageForAI(_ image: UIImage, targetFormat: ImageFormat = .heic) async -> CompressionResult {
        logger.info("📸 Compressing image for AI analysis - Size: \(String(describing: image.size))")
        return await imageCompressionService.compressImage(image, targetFormat: targetFormat, useAggressive: true)
    }

    /// Compresses screenshot data specifically optimized for backend upload
    /// - Parameter screenshotData: Raw screenshot data from Photos library
    /// - Returns: Optimized image data ready for upload
    func compressScreenshotForUpload(_ screenshotData: Data) async -> CompressionResult {
        logger.info("📤 Compressing screenshot for backend upload")
        return await imageCompressionService.compressScreenshotForAI(screenshotData)
    }

    /// Stores compressed image data in shared container for keyboard extension access
    /// - Parameters:
    ///   - compressedData: The compressed image data
    ///   - screenshotId: Unique identifier for the screenshot
    /// - Returns: Success status of storage operation
    @discardableResult
    func storeCompressedImageForKeyboard(_ compressedData: Data, screenshotId: String) async -> Bool {
        do {
            guard let containerURL = FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: "group.com.flirrt.shared"
            ) else {
                logger.error("Failed to get container URL for app group")
                return false
            }

            let imageURL = containerURL.appendingPathComponent("compressed_screenshots").appendingPathComponent("\(screenshotId).heic")

            // Create directory if it doesn't exist
            try FileManager.default.createDirectory(
                at: imageURL.deletingLastPathComponent(),
                withIntermediateDirectories: true,
                attributes: nil
            )

            // Write compressed image data
            try compressedData.write(to: imageURL)

            // Update shared preferences with image info
            await Task.detached(priority: .userInitiated) { [weak self] in
                self?.sharedDefaults?.set(imageURL.path, forKey: "last_compressed_screenshot_path")
                self?.sharedDefaults?.set(compressedData.count, forKey: "last_compressed_screenshot_size")
                self?.sharedDefaults?.set(Date().timeIntervalSince1970, forKey: "last_compressed_screenshot_time")
                self?.sharedDefaults?.synchronize()
            }.value

            logger.info("✅ Stored compressed image - ID: \(screenshotId), Size: \(self.formatBytes(compressedData.count))")
            return true
        } catch {
            logger.error("❌ Failed to store compressed image: \(error.localizedDescription)")
            return false
        }
    }

    /// Retrieves the most recently compressed screenshot for keyboard extension
    /// - Returns: Compressed image data if available
    func getLastCompressedScreenshot() async -> Data? {
        guard let _ = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.flirrt.shared"
        ),
        let sharedDefaults = sharedDefaults,
        let imagePath = sharedDefaults.string(forKey: "last_compressed_screenshot_path") else {
            logger.debug("No compressed screenshot path found")
            return nil
        }

        let imageURL = URL(fileURLWithPath: imagePath)

        do {
            let data = try Data(contentsOf: imageURL)
            logger.info("📱 Retrieved compressed screenshot - Size: \(self.formatBytes(data.count))")
            return data
        } catch {
            logger.error("❌ Failed to read compressed screenshot: \(error.localizedDescription)")
            return nil
        }
    }

    /// Cleans up old compressed screenshots to save storage space
    func cleanupOldCompressedImages() async {
        await Task.detached(priority: .utility) { [weak self] in
            guard let self = self,
                  let containerURL = FileManager.default.containerURL(
                      forSecurityApplicationGroupIdentifier: "group.com.flirrt.shared"
                  ) else { return }

            let screenshotsDir = containerURL.appendingPathComponent("compressed_screenshots")

            do {
                let files = try FileManager.default.contentsOfDirectory(at: screenshotsDir, includingPropertiesForKeys: [.creationDateKey], options: [])

                // Delete files older than 24 hours
                let cutoffDate = Date().addingTimeInterval(-24 * 60 * 60)

                for fileURL in files {
                    let resourceValues = try fileURL.resourceValues(forKeys: [.creationDateKey])
                    if let creationDate = resourceValues.creationDate, creationDate < cutoffDate {
                        try FileManager.default.removeItem(at: fileURL)
                        self.logger.debug("🗑️ Cleaned up old compressed image: \(fileURL.lastPathComponent)")
                    }
                }
            } catch {
                self.logger.warning("⚠️ Failed to cleanup old compressed images: \(error.localizedDescription)")
            }
        }.value
    }

    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Supporting Types for Image Compression

/// Supported image formats for compression
enum ImageFormat: String, CaseIterable {
    case heic = "HEIC"
    case jpeg = "JPEG"

    var fileExtension: String {
        switch self {
        case .heic: return "heic"
        case .jpeg: return "jpg"
        }
    }

    var mimeType: String {
        switch self {
        case .heic: return "image/heic"
        case .jpeg: return "image/jpeg"
        }
    }
}

/// Result of image compression operation
struct CompressionResult {
    let data: Data
    let originalSize: Int
    let compressedSize: Int
    let compressionRatio: Double // 0.0 to 1.0 (0 = no compression, 1 = 100% compression)
    let format: ImageFormat
    let processingTime: TimeInterval
    let success: Bool
    let error: String?

    /// Human-readable compression summary
    var summary: String {
        if !success {
            return "Compression failed: \(error ?? "Unknown error")"
        }

        let originalMB = Double(originalSize) / (1024 * 1024)
        let compressedMB = Double(compressedSize) / (1024 * 1024)
        let ratioPercent = compressionRatio * 100

        return String(format: "Compressed from %.2f MB to %.2f MB (%.1f%% reduction) in %.2fs",
                     originalMB, compressedMB, ratioPercent, processingTime)
    }

    /// Whether the compression achieved significant size reduction
    var isEffective: Bool {
        return success && compressionRatio > 0.3 // At least 30% reduction
    }
}

// MARK: - Image Compression Service

/// Advanced image compression service optimized for the main app
@MainActor
final class ImageCompressionService {

    private struct CompressionConfig {
        static let targetSizeSmall: Int = 100_000      // 100KB
        static let targetSizeMedium: Int = 200_000     // 200KB
        static let targetSizeLarge: Int = 500_000      // 500KB
        static let maxDimension: CGFloat = 1920        // Maximum width/height
        static let heicQuality: CGFloat = 0.85         // HEIC quality
        static let jpegQualityHigh: CGFloat = 0.9      // High quality JPEG
        static let jpegQualityMedium: CGFloat = 0.8    // Medium quality JPEG
        static let jpegQualityLow: CGFloat = 0.6       // Low quality JPEG
        static let binarySearchIterations: Int = 7     // Binary search attempts
    }

    private let logger = Logger(subsystem: "com.flirrt.app", category: "ImageCompression")

    /// Compresses an image with intelligent optimization based on size and content
    func compressImage(
        _ image: UIImage,
        targetFormat: ImageFormat = .heic,
        useAggressive: Bool = true
    ) async -> CompressionResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        logger.info("🗜️ Starting image compression")

        guard let originalData = image.pngData() else {
            logger.error("❌ Failed to get PNG data from image")
            return CompressionResult(
                data: Data(),
                originalSize: 0,
                compressedSize: 0,
                compressionRatio: 0,
                format: targetFormat,
                processingTime: 0,
                success: false,
                error: "Failed to extract image data"
            )
        }

        let originalSize = originalData.count
        logger.info("📊 Original image size: \(self.formatBytes(originalSize))")

        // Determine compression strategy
        let strategy = determineCompressionStrategy(for: originalSize, image: image)
        logger.info("🎯 Compression strategy: \(strategy.description)")

        // Apply compression based on strategy
        let compressedData: Data
        switch strategy {
        case .none:
            compressedData = originalData
        case .light:
            compressedData = await performLightCompression(image, format: targetFormat)
        case .medium:
            compressedData = await performMediumCompression(image, format: targetFormat)
        case .aggressive:
            compressedData = await performAggressiveCompression(image, format: targetFormat, useAggressive: useAggressive)
        }

        let processingTime = CFAbsoluteTimeGetCurrent() - startTime
        let compressionRatio = originalSize > 0 ? (1.0 - Double(compressedData.count) / Double(originalSize)) : 0

        logger.info("✅ Compression complete - Original: \(self.formatBytes(originalSize)), Compressed: \(self.formatBytes(compressedData.count)), Ratio: \(String(format: "%.1f", compressionRatio * 100))%")

        return CompressionResult(
            data: compressedData,
            originalSize: originalSize,
            compressedSize: compressedData.count,
            compressionRatio: compressionRatio,
            format: targetFormat,
            processingTime: processingTime,
            success: !compressedData.isEmpty,
            error: compressedData.isEmpty ? "Compression failed" : nil
        )
    }

    /// Compresses screenshot data specifically optimized for AI analysis
    func compressScreenshotForAI(_ screenshotData: Data) async -> CompressionResult {
        logger.info("📸 Compressing screenshot for AI analysis")

        guard let image = UIImage(data: screenshotData) else {
            logger.error("❌ Failed to create UIImage from screenshot data")
            return CompressionResult(
                data: Data(),
                originalSize: screenshotData.count,
                compressedSize: 0,
                compressionRatio: 0,
                format: .heic,
                processingTime: 0,
                success: false,
                error: "Invalid image data"
            )
        }

        return await compressImage(image, targetFormat: .heic, useAggressive: true)
    }

    // MARK: - Private Methods

    private enum CompressionStrategy {
        case none, light, medium, aggressive

        var description: String {
            switch self {
            case .none: return "No compression (small size)"
            case .light: return "Light compression (0.8 quality)"
            case .medium: return "Medium compression (0.7 quality + resize)"
            case .aggressive: return "Aggressive compression (0.6 quality + resize + HEIC)"
            }
        }
    }

    private func determineCompressionStrategy(for size: Int, image: UIImage) -> CompressionStrategy {
        if size < CompressionConfig.targetSizeSmall {
            return .none
        } else if size < CompressionConfig.targetSizeMedium {
            return .light
        } else if size < CompressionConfig.targetSizeLarge {
            return .medium
        } else {
            return .aggressive
        }
    }

    private func performLightCompression(_ image: UIImage, format: ImageFormat) async -> Data {
        logger.debug("🔹 Applying light compression")
        switch format {
        case .heic:
            return await compressToHEIC(image, quality: CompressionConfig.heicQuality)
        case .jpeg:
            return compressToJPEG(image, quality: CompressionConfig.jpegQualityHigh)
        }
    }

    private func performMediumCompression(_ image: UIImage, format: ImageFormat) async -> Data {
        logger.debug("🔸 Applying medium compression")
        let resizedImage = resizeImageIfNeeded(image, maxDimension: CompressionConfig.maxDimension)
        switch format {
        case .heic:
            return await compressToHEIC(resizedImage, quality: CompressionConfig.heicQuality * 0.9)
        case .jpeg:
            return compressToJPEG(resizedImage, quality: CompressionConfig.jpegQualityMedium)
        }
    }

    private func performAggressiveCompression(_ image: UIImage, format: ImageFormat, useAggressive: Bool) async -> Data {
        logger.debug("🔺 Applying aggressive compression")
        let maxDim: CGFloat = useAggressive ? CompressionConfig.maxDimension * 0.8 : CompressionConfig.maxDimension
        let resizedImage = resizeImageIfNeeded(image, maxDimension: maxDim)
        return await binarySearchOptimalCompression(resizedImage, format: format, targetSize: CompressionConfig.targetSizeLarge)
    }

    private func binarySearchOptimalCompression(_ image: UIImage, format: ImageFormat, targetSize: Int) async -> Data {
        logger.debug("🔍 Binary search for optimal compression quality")

        var minQuality: CGFloat = 0.3
        var maxQuality: CGFloat = 0.9
        var bestData = Data()
        var bestQuality: CGFloat = minQuality

        for iteration in 1...CompressionConfig.binarySearchIterations {
            let currentQuality = (minQuality + maxQuality) / 2
            logger.debug("  Iteration \(iteration): Testing quality \(String(format: "%.3f", currentQuality))")

            let testData: Data
            switch format {
            case .heic:
                testData = await compressToHEIC(image, quality: currentQuality)
            case .jpeg:
                testData = compressToJPEG(image, quality: currentQuality)
            }

            let testSize = testData.count

            if testSize <= targetSize {
                bestData = testData
                bestQuality = currentQuality
                minQuality = currentQuality
            } else {
                maxQuality = currentQuality
            }

            if abs(testSize - targetSize) < targetSize / 20 {
                logger.debug("  🎯 Found optimal quality \(String(format: "%.3f", currentQuality)) in \(iteration) iterations")
                bestData = testData
                break
            }
        }

        logger.info("🔍 Binary search complete - Quality: \(String(format: "%.3f", bestQuality)), Size: \(self.formatBytes(bestData.count))")
        return bestData
    }

    private func compressToHEIC(_ image: UIImage, quality: CGFloat) async -> Data {
        guard let cgImage = image.cgImage else {
            logger.warning("⚠️ Failed to get CGImage for HEIC compression, falling back to JPEG")
            return compressToJPEG(image, quality: quality)
        }

        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.heic.identifier as CFString, 1, nil) else {
            logger.warning("⚠️ HEIC format not available, falling back to JPEG")
            return compressToJPEG(image, quality: quality)
        }

        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality,
            kCGImageDestinationOptimizeColorForSharing: true
        ]

        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)

        let success = CGImageDestinationFinalize(destination)
        if success {
            logger.debug("✅ HEIC compression successful - Quality: \(String(format: "%.3f", quality))")
            return data as Data
        } else {
            logger.warning("⚠️ HEIC compression failed, falling back to JPEG")
            return compressToJPEG(image, quality: quality)
        }
    }

    private func compressToJPEG(_ image: UIImage, quality: CGFloat) -> Data {
        guard let jpegData = image.jpegData(compressionQuality: quality) else {
            logger.error("❌ JPEG compression failed")
            return Data()
        }

        logger.debug("✅ JPEG compression successful - Quality: \(String(format: "%.3f", quality))")
        return jpegData
    }

    private func resizeImageIfNeeded(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let currentMaxDimension = max(image.size.width, image.size.height)

        if currentMaxDimension <= maxDimension {
            logger.debug("📐 No resizing needed - Current: \(Int(currentMaxDimension))px, Max: \(Int(maxDimension))px")
            return image
        }

        let scale = maxDimension / currentMaxDimension
        let newSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )

        logger.info("📐 Resizing image - From: \(Int(image.size.width))x\(Int(image.size.height)) To: \(Int(newSize.width))x\(Int(newSize.height))")

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let voiceCloneCreated = Notification.Name("voiceCloneCreated")
}