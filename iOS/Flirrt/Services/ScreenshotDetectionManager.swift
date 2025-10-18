import Foundation
import UIKit
import OSLog
import Photos
import Combine

/// Ultra-fast screenshot detection manager with <0.1s detection time
/// Implements instant notification bridge to keyboard extension via Darwin notifications
@MainActor
final class ScreenshotDetectionManager: ObservableObject {

    // MARK: - Published Properties
    @Published var lastScreenshotDetected: Date?
    @Published var screenhotDetectionEnabled: Bool = true
    @Published var detectionStatus: DetectionStatus = .idle
    @Published var latestScreenshotData: Data?  // Latest screenshot image data for UI preview

    // MARK: - Private Properties
    private let logger = Logger(subsystem: "com.vibe8.app", category: "ScreenshotDetection")
    private var cancellables = Set<AnyCancellable>()
    private let sharedDefaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
    private var screenshotCounter: Int = 0
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = .invalid
    private let darwinNotificationManager = DarwinNotificationManager()

    // Performance tracking
    private var detectionStartTime: CFAbsoluteTime = 0
    private var lastNotificationTime: Date = Date()

    // MARK: - Detection Status
    enum DetectionStatus {
        case idle
        case detecting
        case processing
        case notified
        case error(String)

        var description: String {
            switch self {
            case .idle: return "Ready for detection"
            case .detecting: return "Screenshot detected"
            case .processing: return "Processing screenshot"
            case .notified: return "Keyboard notified"
            case .error(let message): return "Error: \(message)"
            }
        }
    }

    // MARK: - Initialization
    init() {
        setupScreenshotDetection()
        setupBackgroundHandling()
        logger.info("🔍 ScreenshotDetectionManager initialized - Detection enabled: \(self.screenhotDetectionEnabled)")
    }

    // MARK: - Screenshot Detection Setup
    private func setupScreenshotDetection() {
        // Primary detection: UIApplication screenshot notification (fastest method)
        NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.handleScreenshotDetected()
                }
            }
            .store(in: &cancellables)

        // Secondary detection: App state changes for background processing
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.prepareForBackgroundDetection()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.handleAppBecameActive()
            }
            .store(in: &cancellables)
    }

    private func setupBackgroundHandling() {
        // Background task management for processing screenshots
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.startBackgroundTask()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.endBackgroundTask()
            }
            .store(in: &cancellables)
    }

    // MARK: - Core Detection Logic
    private func handleScreenshotDetected() async {
        guard screenhotDetectionEnabled else {
            logger.debug("📱 Screenshot detection disabled, ignoring notification")
            return
        }

        detectionStartTime = CFAbsoluteTimeGetCurrent()
        detectionStatus = .detecting
        lastScreenshotDetected = Date()
        screenshotCounter += 1

        let screenshotId = generateScreenshotId()
        logger.info("📸 INSTANT SCREENSHOT DETECTED - ID: \(screenshotId), Count: \(self.screenshotCounter)")

        // Immediate Darwin notification (fastest path)
        await sendInstantNotificationToKeyboard(screenshotId: screenshotId)

        // Process screenshot metadata in background
        Task.detached(priority: .userInitiated) {
            await self.processScreenshotMetadata(screenshotId: screenshotId)
        }

        let detectionTime = CFAbsoluteTimeGetCurrent() - detectionStartTime
        logger.info("⚡ Screenshot detection complete in \(String(format: "%.3f", detectionTime * 1000))ms")
    }

    private func sendInstantNotificationToKeyboard(screenshotId: String) async {
        detectionStatus = .processing

        let notificationData: [String: Any] = [
            "screenshot_id": screenshotId,
            "timestamp": Date().timeIntervalSince1970,
            "detection_time": CFAbsoluteTimeGetCurrent() - detectionStartTime,
            "counter": screenshotCounter,
            "confidence": 1.0, // Immediate detection = highest confidence
            "device_state": getDeviceState(),
            "app_state": UIApplication.shared.applicationState.rawValue
        ]

        // Store notification data in App Groups for keyboard access
        await storeNotificationData(notificationData, screenshotId: screenshotId)

        // Send via Darwin notification manager for enhanced performance tracking
        await darwinNotificationManager.sendScreenshotDetected(
            screenshotId: screenshotId,
            metadata: notificationData
        )

        detectionStatus = .notified
        lastNotificationTime = Date()

        let notificationTime = CFAbsoluteTimeGetCurrent() - detectionStartTime
        logger.info("🚀 Darwin notification sent to keyboard in \(String(format: "%.3f", notificationTime * 1000))ms")

        // Reset status after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.detectionStatus = .idle
        }
    }

    private func processScreenshotMetadata(screenshotId: String) async {
        logger.info("📊 Processing screenshot metadata for ID: \(screenshotId)")

        let metadata: [String: Any] = [
            "screenshot_id": screenshotId,
            "app_state": UIApplication.shared.applicationState.rawValue,
            "timestamp": Date().timeIntervalSince1970,
            "device_orientation": UIDevice.current.orientation.rawValue,
            "screen_brightness": UIScreen.main.brightness,
            "battery_level": UIDevice.current.batteryLevel,
            "low_power_mode": ProcessInfo.processInfo.isLowPowerModeEnabled,
            "detection_method": "UIApplication.userDidTakeScreenshotNotification",
            "processing_priority": "userInitiated"
        ]

        await storeScreenshotMetadata(metadata, screenshotId: screenshotId)

        // Optional: Trigger Photos library analysis if needed
        if await shouldAnalyzePhotos() {
            await analyzeRecentPhotos(screenshotId: screenshotId)
        }
    }

    // MARK: - App Groups Communication
    private func storeNotificationData(_ data: [String: Any], screenshotId: String) async {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppConstants.appGroupIdentifier
        ) else {
            logger.error("❌ Failed to get container URL for app group")
            detectionStatus = .error("App Groups access failed")
            return
        }

        do {
            let notificationsDir = containerURL.appendingPathComponent("screenshot_notifications")
            try FileManager.default.createDirectory(at: notificationsDir, withIntermediateDirectories: true)

            let notificationFile = notificationsDir.appendingPathComponent("\(screenshotId).json")
            let jsonData = try JSONSerialization.data(withJSONObject: data)
            try jsonData.write(to: notificationFile)

            // Update shared preferences with latest notification
            sharedDefaults?.set(screenshotId, forKey: AppConstants.UserDefaultsKeys.lastScreenshotId)
            sharedDefaults?.set(Date().timeIntervalSince1970, forKey: AppConstants.UserDefaultsKeys.lastScreenshotTime)
            sharedDefaults?.set(screenshotCounter, forKey: AppConstants.UserDefaultsKeys.screenshotCounter)
            sharedDefaults?.synchronize()

            logger.info("✅ Notification data stored for keyboard - ID: \(screenshotId)")
        } catch {
            logger.error("❌ Failed to store notification data: \(error.localizedDescription)")
            detectionStatus = .error("Storage failed")
        }
    }

    private func storeScreenshotMetadata(_ metadata: [String: Any], screenshotId: String) async {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppConstants.appGroupIdentifier
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

    // MARK: - Background Processing
    private func prepareForBackgroundDetection() {
        logger.info("🔄 Preparing for background detection")

        // Store current state for background processing
        sharedDefaults?.set(true, forKey: AppConstants.UserDefaultsKeys.appWasActiveDuringScreenshot)
        sharedDefaults?.set(Date().timeIntervalSince1970, forKey: AppConstants.UserDefaultsKeys.lastActiveTime)
        sharedDefaults?.synchronize()
    }

    private func handleAppBecameActive() {
        logger.info("🔆 App became active - Checking for background screenshots")

        // Check if screenshots were taken while app was backgrounded
        Task {
            await checkForBackgroundScreenshots()
        }
    }

    private func startBackgroundTask() {
        endBackgroundTask() // Clean up any existing task

        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "ScreenshotDetection") {
            self.endBackgroundTask()
        }

        logger.info("🔧 Background task started for screenshot detection")
    }

    private func endBackgroundTask() {
        if backgroundTaskIdentifier != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
            backgroundTaskIdentifier = .invalid
            logger.debug("🔧 Background task ended")
        }
    }

    private func checkForBackgroundScreenshots() async {
        // This method can be used to detect screenshots taken while app was backgrounded
        // Implementation would involve checking Photos library for recent images
        logger.debug("🔍 Checking for background screenshots")

        guard await requestPhotosPermissionIfNeeded() else {
            logger.info("📷 Photos permission not available for background check")
            return
        }

        // Implementation for background screenshot detection would go here
        // This is optional and depends on specific requirements
    }

    // MARK: - Photos Library Analysis
    private func shouldAnalyzePhotos() async -> Bool {
        // Only analyze if we have permission and it's been requested
        return await requestPhotosPermissionIfNeeded()
    }

    private func requestPhotosPermissionIfNeeded() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        switch status {
        case .authorized, .limited:
            return true
        case .notDetermined:
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            return newStatus == .authorized || newStatus == .limited
        case .denied, .restricted:
            logger.info("📷 Photos access denied - Screenshot analysis limited")
            return false
        @unknown default:
            return false
        }
    }

    private func analyzeRecentPhotos(screenshotId: String) async {
        logger.info("📷 Analyzing recent photos for screenshot: \(screenshotId)")

        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = 5 // Check last 5 photos

        let recentAssets = PHAsset.fetchAssets(with: .image, options: fetchOptions)

        var foundScreenshot = false
        recentAssets.enumerateObjects { asset, index, stop in
            // Check if this asset was created very recently (within last 5 seconds)
            if let creationDate = asset.creationDate,
               Date().timeIntervalSince(creationDate) < 5.0 {

                // This is likely our screenshot
                foundScreenshot = true
                self.logger.info("📸 Found recent photo asset - Created: \(creationDate)")

                // Extract and compress the screenshot for keyboard access
                Task { @MainActor in
                    await self.extractAndCompressScreenshot(asset: asset, screenshotId: screenshotId)
                }
                stop.pointee = true
            }
        }

        if foundScreenshot {
            await updateScreenshotConfirmation(screenshotId: screenshotId)
        }
    }

    private func updateScreenshotConfirmation(screenshotId: String) async {
        logger.info("✅ Screenshot confirmed in Photos library - ID: \(screenshotId)")

        // Update shared data with confirmation
        sharedDefaults?.set(true, forKey: AppConstants.UserDefaultsKeys.lastScreenshotConfirmed)
        sharedDefaults?.set(Date().timeIntervalSince1970, forKey: AppConstants.UserDefaultsKeys.lastScreenshotConfirmedTime)
        sharedDefaults?.synchronize()

        // Send confirmation via Darwin notification manager
        await darwinNotificationManager.sendScreenshotConfirmed(screenshotId: screenshotId)
    }

    private func extractAndCompressScreenshot(asset: PHAsset, screenshotId: String) async {
        logger.info("🖼️  Extracting screenshot image from Photos asset - ID: \(screenshotId)")

        let imageManager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = false // Only local assets

        // Request full-size image
        return await withCheckedContinuation { continuation in
            imageManager.requestImage(
                for: asset,
                targetSize: PHImageManagerMaximumSize,
                contentMode: .aspectFit,
                options: options
            ) { [weak self] image, info in
                guard let self = self, let image = image else {
                    self?.logger.error("❌ Failed to extract image from asset")
                    continuation.resume()
                    return
                }

                self.logger.info("📐 Extracted image size: \(image.size.width)x\(image.size.height)")

                // Compress image for keyboard memory constraints (< 200KB target)
                Task { @MainActor in
                    await self.compressAndStoreScreenshot(image: image, screenshotId: screenshotId)
                    continuation.resume()
                }
            }
        }
    }

    private func compressAndStoreScreenshot(image: UIImage, screenshotId: String) async {
        logger.info("🗜️  Compressing screenshot for keyboard access - ID: \(screenshotId)")

        // Start with 0.7 quality, reduce if needed
        var compressionQuality: CGFloat = 0.7
        var imageData: Data?
        let maxSize = 200_000 // 200KB max for keyboard extension

        // Progressive compression to meet size constraint
        for _ in 0..<5 {
            guard let data = image.jpegData(compressionQuality: compressionQuality) else {
                logger.error("❌ Failed to compress image")
                return
            }

            imageData = data
            let sizeKB = Double(data.count) / 1000.0
            logger.debug("📊 Compressed size: \(String(format: "%.1f", sizeKB))KB at quality \(compressionQuality)")

            if data.count <= maxSize {
                break
            }

            // Reduce quality for next iteration
            compressionQuality -= 0.15

            if compressionQuality < 0.1 {
                // If still too large, resize image
                let scaleFactor = sqrt(Double(maxSize) / Double(data.count))
                let newSize = CGSize(
                    width: image.size.width * scaleFactor,
                    height: image.size.height * scaleFactor
                )

                if let resized = resizeImage(image, to: newSize) {
                    imageData = resized.jpegData(compressionQuality: 0.7)
                }
                break
            }
        }

        guard let finalData = imageData else {
            logger.error("❌ Failed to compress screenshot")
            return
        }

        let finalSizeKB = Double(finalData.count) / 1000.0
        logger.info("✅ Screenshot compressed to \(String(format: "%.1f", finalSizeKB))KB")

        // Store in App Groups for keyboard access
        await storeCompressedScreenshot(imageData: finalData, screenshotId: screenshotId)
    }

    private func storeCompressedScreenshot(imageData: Data, screenshotId: String) async {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppConstants.appGroupIdentifier
        ) else {
            logger.error("❌ Failed to get App Groups container")
            return
        }

        do {
            let screenshotsDir = containerURL.appendingPathComponent("screenshots")
            try FileManager.default.createDirectory(at: screenshotsDir, withIntermediateDirectories: true)

            let screenshotFile = screenshotsDir.appendingPathComponent("\(screenshotId).jpg")
            try imageData.write(to: screenshotFile)

            // Store latest screenshot data for UI preview
            self.latestScreenshotData = imageData

            // Update shared defaults with screenshot info
            sharedDefaults?.set(screenshotId, forKey: AppConstants.UserDefaultsKeys.latestScreenshotId)
            sharedDefaults?.set(screenshotFile.path, forKey: AppConstants.UserDefaultsKeys.latestScreenshotPath)
            sharedDefaults?.set(imageData.count, forKey: AppConstants.UserDefaultsKeys.latestScreenshotSize)
            sharedDefaults?.set(imageData.base64EncodedString(), forKey: AppConstants.UserDefaultsKeys.screenshotDataKey(screenshotId))
            sharedDefaults?.synchronize()

            let sizeKB = Double(imageData.count) / 1000.0
            logger.info("✅ Screenshot stored for keyboard - Size: \(String(format: "%.1f", sizeKB))KB, Path: \(screenshotFile.lastPathComponent)")

        } catch {
            logger.error("❌ Failed to store screenshot: \(error.localizedDescription)")
        }
    }

    private func resizeImage(_ image: UIImage, to newSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }

        image.draw(in: CGRect(origin: .zero, size: newSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    private func getDeviceState() -> [String: Any] {
        // Get interface orientation from window scene (modern API)
        let interfaceOrientation: Int = {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                return windowScene.interfaceOrientation.rawValue
            }
            return 0 // Unknown
        }()

        return [
            "battery_level": UIDevice.current.batteryLevel,
            "low_power_mode": ProcessInfo.processInfo.isLowPowerModeEnabled,
            "screen_brightness": UIScreen.main.brightness,
            "device_orientation": UIDevice.current.orientation.rawValue,
            "interface_orientation": interfaceOrientation,
            "thermal_state": ProcessInfo.processInfo.thermalState.rawValue,
            "memory_pressure": getMemoryPressure()
        ]
    }

    private func getMemoryPressure() -> String {
        // Simple memory pressure detection
        let physicalMemory = ProcessInfo.processInfo.physicalMemory
        let usedMemory = getUsedMemory()
        let memoryRatio = Double(usedMemory) / Double(physicalMemory)

        if memoryRatio > 0.8 {
            return "high"
        } else if memoryRatio > 0.6 {
            return "medium"
        } else {
            return "low"
        }
    }

    private func getUsedMemory() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if kerr == KERN_SUCCESS {
            return info.resident_size
        } else {
            return 0
        }
    }

    // MARK: - Public Interface

    /// Enables or disables screenshot detection
    func setDetectionEnabled(_ enabled: Bool) {
        screenhotDetectionEnabled = enabled
        logger.info("🔧 Screenshot detection \(enabled ? "enabled" : "disabled")")

        sharedDefaults?.set(enabled, forKey: AppConstants.UserDefaultsKeys.screenshotDetectionEnabled)
        sharedDefaults?.synchronize()

        // Notify keyboard of detection status change
        Task {
            if enabled {
                await darwinNotificationManager.sendDetectionEnabled()
            } else {
                await darwinNotificationManager.sendDetectionDisabled()
            }
        }
    }

    /// Gets current detection statistics
    func getDetectionStats() -> [String: Any] {
        var stats: [String: Any] = [
            "total_screenshots": screenshotCounter,
            "detection_enabled": screenhotDetectionEnabled,
            "last_detection": lastScreenshotDetected?.timeIntervalSince1970 ?? 0,
            "last_notification": lastNotificationTime.timeIntervalSince1970,
            "current_status": detectionStatus.description
        ]

        // Add Darwin notification manager stats
        let darwinStats = darwinNotificationManager.getPerformanceStats()
        stats.merge(darwinStats) { (current, _) in current }

        return stats
    }

    /// Manually triggers a test notification (for debugging)
    func triggerTestNotification() async {
        logger.info("🧪 Triggering test notification")
        let testId = "test_\(Int(Date().timeIntervalSince1970))"
        await sendInstantNotificationToKeyboard(screenshotId: testId)
    }

    /// Tests connection with keyboard extension
    func testKeyboardConnection() async -> Bool {
        logger.info("🔧 Testing keyboard connection")
        return await darwinNotificationManager.testConnection()
    }

    /// Gets the Darwin notification manager for advanced usage
    var notificationManager: DarwinNotificationManager {
        return darwinNotificationManager
    }

    // MARK: - Utility Methods
    private func generateScreenshotId() -> String {
        let timestamp = Int(Date().timeIntervalSince1970 * 1000) // Milliseconds
        let random = Int.random(in: 1000...9999)
        return "screenshot_\(timestamp)_\(random)"
    }

    // MARK: - Cleanup
    deinit {
        // End background task on main actor
        if backgroundTaskIdentifier != .invalid {
            Task { @MainActor in
                UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier)
            }
        }
        cancellables.removeAll()
        logger.info("🔍 ScreenshotDetectionManager deinitialized")
    }
}

// MARK: - Darwin Notification Constants
extension ScreenshotDetectionManager {
    struct DarwinNotifications {
        static let screenshotDetected = "com.vibe8.screenshot.detected"
        static let screenshotConfirmed = "com.vibe8.screenshot.confirmed"
        static let detectionStatusChanged = "com.vibe8.detection.status.changed"
    }
}

// MARK: - App Groups Constants
extension ScreenshotDetectionManager {
    struct AppGroupsKeys {
        static let lastScreenshotId = "last_screenshot_id"
        static let lastScreenshotTime = "last_screenshot_time"
        static let screenshotCounter = "screenshot_counter"
        static let detectionEnabled = "screenshot_detection_enabled"
        static let lastScreenshotConfirmed = "last_screenshot_confirmed"
        static let lastScreenshotConfirmedTime = "last_screenshot_confirmed_time"
        static let appWasActiveDuringScreenshot = "app_was_active_during_screenshot"
        static let lastActiveTime = "last_active_time"
    }
}