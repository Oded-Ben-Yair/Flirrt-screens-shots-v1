import SwiftUI
import UserNotifications
import OSLog

@main
@MainActor
struct FlirrtApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var apiClient = APIClient()
    @StateObject private var sharedDataManager = SharedDataManager()
    private let logger = Logger(subsystem: "com.flirrt.app", category: "FlirrtApp")

    init() {
        setupAppGroups()
        configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            AppCoordinator()
                .environmentObject(authManager)
                .environmentObject(apiClient)
                .environmentObject(sharedDataManager)
                .onAppear {
                    requestNotificationPermissions()
                    initializeScreenshotDetection()
                }
        }
    }

    private func setupAppGroups() {
        if let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt.shared") {
            logger.info("✅ App Groups container accessible: group.com.flirrt.shared")
            sharedDefaults.set(true, forKey: "appLaunched")
            sharedDefaults.synchronize()
        } else {
            logger.error("❌ Failed to access App Groups container: group.com.flirrt.shared")
        }
    }

    private func configureAppearance() {
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .foregroundColor: UIColor.label
        ]
        UITabBar.appearance().tintColor = UIColor.systemPink
    }

    private func initializeScreenshotDetection() {
        Task { @MainActor in
            logger.info("⚡ Initializing ultra-fast screenshot detection")
            sharedDataManager.setScreenshotDetectionEnabled(true)

            // Log detection capabilities
            let stats = sharedDataManager.getScreenshotDetectionStats()
            logger.info("📊 Screenshot detection initialized - Stats: \(stats)")
        }
    }

    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
}