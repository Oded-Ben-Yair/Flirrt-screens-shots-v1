import SwiftUI
import UserNotifications

@main
struct FlirrtApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var apiClient = APIClient()
    @StateObject private var sharedDataManager = SharedDataManager()
    // TODO: Add ScreenshotDetectionManager to Xcode target first
    // @StateObject private var screenshotManager = ScreenshotDetectionManager()

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
                // .environmentObject(screenshotManager)
                .onAppear {
                    requestNotificationPermissions()
                    // screenshotManager.startMonitoring()
                }
        }
    }

    private func setupAppGroups() {
        if let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt.ai.shared") {
            sharedDefaults.set(true, forKey: "appLaunched")
            sharedDefaults.synchronize()
        }
    }

    private func configureAppearance() {
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .foregroundColor: UIColor.label
        ]
        UITabBar.appearance().tintColor = UIColor.systemPink
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