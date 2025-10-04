import Foundation
import OSLog
import UIKit

/// Specialized Darwin notification manager for ultra-fast IPC with keyboard extension
/// Handles bi-directional communication for screenshot detection and status updates
@MainActor
final class DarwinNotificationManager: ObservableObject {

    // MARK: - Published Properties
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var lastNotificationSent: Date?
    @Published var lastNotificationReceived: Date?
    @Published var messageCount: Int = 0

    // MARK: - Private Properties
    private let logger = Logger(subsystem: "com.flirrt.app", category: "DarwinNotifications")
    private let sharedDefaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
    private var isObservingNotifications = false

    // Performance tracking
    private var notificationLatencies: [TimeInterval] = []
    private let maxLatencyHistory = 10

    // MARK: - Connection Status
    enum ConnectionStatus: Equatable {
        case disconnected
        case connecting
        case connected
        case error(String)

        var description: String {
            switch self {
            case .disconnected: return "Disconnected"
            case .connecting: return "Connecting"
            case .connected: return "Connected"
            case .error(let message): return "Error: \(message)"
            }
        }
    }

    // MARK: - Notification Types
    struct NotificationNames {
        // Outgoing (Main App → Keyboard)
        static let screenshotDetected = "com.flirrt.screenshot.detected"
        static let screenshotConfirmed = "com.flirrt.screenshot.confirmed"
        static let appStatusChanged = "com.flirrt.app.status.changed"
        static let detectionEnabled = "com.flirrt.detection.enabled"
        static let detectionDisabled = "com.flirrt.detection.disabled"

        // Incoming (Keyboard → Main App)
        static let keyboardReady = "com.flirrt.keyboard.ready"
        static let keyboardHeartbeat = "com.flirrt.keyboard.heartbeat"
        static let analysisRequested = "com.flirrt.analyze.request"
        static let statusRequest = "com.flirrt.status.request"

        // Bi-directional
        static let ping = "com.flirrt.ping"
        static let pong = "com.flirrt.pong"
    }

    // MARK: - Initialization
    init() {
        setupNotificationObservers()
        connectionStatus = .connecting
        logger.info("🔗 DarwinNotificationManager initialized")
    }

    // MARK: - Setup and Configuration
    private func setupNotificationObservers() {
        guard !isObservingNotifications else {
            logger.warning("⚠️ Darwin notification observers already set up")
            return
        }

        let center = CFNotificationCenterGetDarwinNotifyCenter()

        // Keyboard Ready Notification
        CFNotificationCenterAddObserver(
            center,
            Unmanaged.passUnretained(self).toOpaque(),
            { (center, observer, name, object, userInfo) in
                guard let observer = observer else { return }
                let manager = Unmanaged<DarwinNotificationManager>.fromOpaque(observer).takeUnretainedValue()
                Task { @MainActor in
                    await manager.handleKeyboardReady()
                }
            },
            NotificationNames.keyboardReady as CFString,
            nil,
            .deliverImmediately
        )

        // Keyboard Heartbeat
        CFNotificationCenterAddObserver(
            center,
            Unmanaged.passUnretained(self).toOpaque(),
            { (center, observer, name, object, userInfo) in
                guard let observer = observer else { return }
                let manager = Unmanaged<DarwinNotificationManager>.fromOpaque(observer).takeUnretainedValue()
                Task { @MainActor in
                    await manager.handleKeyboardHeartbeat()
                }
            },
            NotificationNames.keyboardHeartbeat as CFString,
            nil,
            .deliverImmediately
        )

        // Analysis Request
        CFNotificationCenterAddObserver(
            center,
            Unmanaged.passUnretained(self).toOpaque(),
            { (center, observer, name, object, userInfo) in
                guard let observer = observer else { return }
                let manager = Unmanaged<DarwinNotificationManager>.fromOpaque(observer).takeUnretainedValue()
                Task { @MainActor in
                    await manager.handleAnalysisRequest()
                }
            },
            NotificationNames.analysisRequested as CFString,
            nil,
            .deliverImmediately
        )

        // Status Request
        CFNotificationCenterAddObserver(
            center,
            Unmanaged.passUnretained(self).toOpaque(),
            { (center, observer, name, object, userInfo) in
                guard let observer = observer else { return }
                let manager = Unmanaged<DarwinNotificationManager>.fromOpaque(observer).takeUnretainedValue()
                Task { @MainActor in
                    await manager.handleStatusRequest()
                }
            },
            NotificationNames.statusRequest as CFString,
            nil,
            .deliverImmediately
        )

        // Ping-Pong for latency testing
        CFNotificationCenterAddObserver(
            center,
            Unmanaged.passUnretained(self).toOpaque(),
            { (center, observer, name, object, userInfo) in
                guard let observer = observer else { return }
                let manager = Unmanaged<DarwinNotificationManager>.fromOpaque(observer).takeUnretainedValue()
                Task { @MainActor in
                    await manager.handlePing()
                }
            },
            NotificationNames.ping as CFString,
            nil,
            .deliverImmediately
        )

        isObservingNotifications = true
        connectionStatus = .connected
        logger.info("✅ Darwin notification observers set up successfully")
    }

    // MARK: - Incoming Notification Handlers
    private func handleKeyboardReady() async {
        logger.info("🔗 Keyboard extension ready signal received")
        lastNotificationReceived = Date()
        connectionStatus = .connected

        // Send app status to keyboard
        await sendAppStatusUpdate()

        // Send acknowledgment
        await sendNotification(NotificationNames.pong, withPayload: [
            "source": "main_app",
            "timestamp": Date().timeIntervalSince1970,
            "message": "app_ready"
        ])
    }

    private func handleKeyboardHeartbeat() async {
        logger.debug("💓 Keyboard heartbeat received")
        lastNotificationReceived = Date()

        // Update connection status
        if connectionStatus != .connected {
            connectionStatus = .connected
        }

        // Update shared state
        sharedDefaults?.set(Date().timeIntervalSince1970, forKey: AppConstants.UserDefaultsKeys.lastKeyboardHeartbeat)
        sharedDefaults?.synchronize()
    }

    private func handleAnalysisRequest() async {
        logger.info("📸 Analysis request received from keyboard")
        lastNotificationReceived = Date()

        // Forward to screenshot detection manager
        NotificationCenter.default.post(name: .analysisRequestedFromKeyboard, object: nil)

        // Send acknowledgment
        await sendNotification(NotificationNames.pong, withPayload: [
            "source": "main_app",
            "message": "analysis_request_received"
        ])
    }

    private func handleStatusRequest() async {
        logger.info("📊 Status request received from keyboard")
        lastNotificationReceived = Date()

        await sendAppStatusUpdate()
    }

    private func handlePing() async {
        logger.debug("🏓 Ping received, sending pong")

        // Measure round-trip time
        let timestamp = Date().timeIntervalSince1970

        await sendNotification(NotificationNames.pong, withPayload: [
            "source": "main_app",
            "timestamp": timestamp,
            "ping_received": timestamp
        ])
    }

    // MARK: - Outgoing Notifications

    /// Sends screenshot detection notification to keyboard extension
    func sendScreenshotDetected(screenshotId: String, metadata: [String: Any] = [:]) async {
        let startTime = CFAbsoluteTimeGetCurrent()

        var payload = metadata
        payload["screenshot_id"] = screenshotId
        payload["timestamp"] = Date().timeIntervalSince1970
        payload["source"] = "main_app"
        payload["type"] = "screenshot_detected"

        await sendNotification(NotificationNames.screenshotDetected, withPayload: payload)

        let latency = CFAbsoluteTimeGetCurrent() - startTime
        recordNotificationLatency(latency)

        logger.info("📸 Screenshot detection sent - ID: \(screenshotId), Latency: \(String(format: "%.3f", latency * 1000))ms")
    }

    /// Sends screenshot confirmation to keyboard extension
    func sendScreenshotConfirmed(screenshotId: String) async {
        await sendNotification(NotificationNames.screenshotConfirmed, withPayload: [
            "screenshot_id": screenshotId,
            "timestamp": Date().timeIntervalSince1970,
            "source": "main_app",
            "confirmed": true
        ])

        logger.info("✅ Screenshot confirmation sent - ID: \(screenshotId)")
    }

    /// Sends app status update to keyboard
    func sendAppStatusUpdate() async {
        let appState = UIApplication.shared.applicationState
        let isActive = appState == .active

        let statusPayload: [String: Any] = [
            "app_state": appState.rawValue,
            "is_active": isActive,
            "timestamp": Date().timeIntervalSince1970,
            "detection_enabled": true, // This should come from screenshot manager
            "connection_status": connectionStatus.description,
            "message_count": messageCount
        ]

        await sendNotification(NotificationNames.appStatusChanged, withPayload: statusPayload)
        logger.info("📊 App status update sent - Active: \(isActive)")
    }

    /// Sends detection enabled notification
    func sendDetectionEnabled() async {
        await sendNotification(NotificationNames.detectionEnabled, withPayload: [
            "timestamp": Date().timeIntervalSince1970,
            "source": "main_app",
            "enabled": true
        ])

        logger.info("🔍 Detection enabled notification sent")
    }

    /// Sends detection disabled notification
    func sendDetectionDisabled() async {
        await sendNotification(NotificationNames.detectionDisabled, withPayload: [
            "timestamp": Date().timeIntervalSince1970,
            "source": "main_app",
            "enabled": false
        ])

        logger.info("🔍 Detection disabled notification sent")
    }

    /// Sends ping for latency testing
    func sendPing() async {
        let timestamp = Date().timeIntervalSince1970

        await sendNotification(NotificationNames.ping, withPayload: [
            "source": "main_app",
            "timestamp": timestamp,
            "ping_id": UUID().uuidString
        ])

        logger.debug("🏓 Ping sent for latency test")
    }

    // MARK: - Core Notification Sending
    private func sendNotification(_ notificationName: String, withPayload payload: [String: Any] = [:]) async {
        do {
            // Store payload in shared container for keyboard access
            if !payload.isEmpty {
                await storeNotificationPayload(payload, for: notificationName)
            }

            // Send Darwin notification
            let center = CFNotificationCenterGetDarwinNotifyCenter()
            CFNotificationCenterPostNotification(
                center,
                CFNotificationName(notificationName as CFString),
                nil,
                nil,
                true // Deliver immediately
            )

            lastNotificationSent = Date()
            messageCount += 1

            logger.debug("📤 Darwin notification sent: \(notificationName)")

        } catch {
            logger.error("❌ Failed to send notification \(notificationName): \(error.localizedDescription)")
            connectionStatus = .error("Send failed: \(error.localizedDescription)")
        }
    }

    private func storeNotificationPayload(_ payload: [String: Any], for notificationName: String) async {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppConstants.appGroupIdentifier
        ) else {
            logger.warning("⚠️ Failed to get container URL for notification payload")
            return
        }

        do {
            let notificationsDir = containerURL.appendingPathComponent("notification_payloads")
            try FileManager.default.createDirectory(at: notificationsDir, withIntermediateDirectories: true)

            let timestamp = Int(Date().timeIntervalSince1970 * 1000)
            let payloadFile = notificationsDir.appendingPathComponent("\(notificationName)_\(timestamp).json")

            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: .prettyPrinted)
            try jsonData.write(to: payloadFile)

            // Update shared defaults with latest payload info
            sharedDefaults?.set(payloadFile.path, forKey: AppConstants.UserDefaultsKeys.lastNotificationPayloadPath)
            sharedDefaults?.set(notificationName, forKey: AppConstants.UserDefaultsKeys.lastNotificationName)
            sharedDefaults?.synchronize()

            logger.debug("💾 Notification payload stored: \(notificationName)")

            // Clean up old payloads
            await cleanupOldPayloads(in: notificationsDir)

        } catch {
            logger.warning("⚠️ Failed to store notification payload: \(error.localizedDescription)")
        }
    }

    private func cleanupOldPayloads(in directory: URL) async {
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.creationDateKey],
                options: []
            )

            // Keep only the last 20 payload files
            let sortedFiles = files.sorted { file1, file2 in
                guard let date1 = try? file1.resourceValues(forKeys: [.creationDateKey]).creationDate,
                      let date2 = try? file2.resourceValues(forKeys: [.creationDateKey]).creationDate else {
                    return false
                }
                return date1 > date2
            }

            if sortedFiles.count > 20 {
                let filesToDelete = Array(sortedFiles.dropFirst(20))
                for file in filesToDelete {
                    try FileManager.default.removeItem(at: file)
                }
                logger.debug("🗑️ Cleaned up \(filesToDelete.count) old payload files")
            }

        } catch {
            logger.warning("⚠️ Failed to cleanup old payloads: \(error.localizedDescription)")
        }
    }

    // MARK: - Performance Monitoring
    private func recordNotificationLatency(_ latency: TimeInterval) {
        notificationLatencies.append(latency)
        if notificationLatencies.count > maxLatencyHistory {
            notificationLatencies.removeFirst()
        }
    }

    /// Gets current performance statistics
    func getPerformanceStats() -> [String: Any] {
        let avgLatency = notificationLatencies.isEmpty ? 0 : notificationLatencies.reduce(0, +) / Double(notificationLatencies.count)
        let maxLatency = notificationLatencies.max() ?? 0
        let minLatency = notificationLatencies.min() ?? 0

        return [
            "connection_status": connectionStatus.description,
            "messages_sent": messageCount,
            "average_latency_ms": avgLatency * 1000,
            "max_latency_ms": maxLatency * 1000,
            "min_latency_ms": minLatency * 1000,
            "last_notification_sent": lastNotificationSent?.timeIntervalSince1970 ?? 0,
            "last_notification_received": lastNotificationReceived?.timeIntervalSince1970 ?? 0
        ]
    }

    /// Tests connection with keyboard extension
    func testConnection() async -> Bool {
        logger.info("🔧 Testing connection with keyboard extension")

        await sendPing()

        // Wait briefly to see if we get a response
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

        let isConnected = connectionStatus == .connected
        logger.info("🔧 Connection test result: \(isConnected ? "✅ Connected" : "❌ Disconnected")")

        return isConnected
    }

    // MARK: - Cleanup
    deinit {
        if isObservingNotifications {
            let center = CFNotificationCenterGetDarwinNotifyCenter()
            CFNotificationCenterRemoveEveryObserver(center, Unmanaged.passUnretained(self).toOpaque())
        }
        logger.info("🔗 DarwinNotificationManager deinitialized")
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let analysisRequestedFromKeyboard = Notification.Name("analysisRequestedFromKeyboard")
    static let keyboardConnectionStatusChanged = Notification.Name("keyboardConnectionStatusChanged")
}