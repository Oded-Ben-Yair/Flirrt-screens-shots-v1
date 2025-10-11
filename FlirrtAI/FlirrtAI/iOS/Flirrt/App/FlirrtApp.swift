import SwiftUI
import UserNotifications

@main
struct FlirrtApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var apiClient = APIClient()
    @StateObject private var sharedDataManager = SharedDataManager()
    // NOTE: ScreenshotDetectionManager needs to be added to Xcode Flirrt target before build
    @StateObject private var screenshotManager = ScreenshotDetectionManager()

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
                .environmentObject(screenshotManager)
                .onAppear {
                    // ✅ REMOVED: Don't request permissions on app launch
                    // Let keyboard request Photos access when first needed
                    // requestNotificationPermissions()

                    // ✅ REMOVED: Don't auto-start screenshot detection in main app
                    // Detection happens in keyboard extension only
                    // screenshotManager.setDetectionEnabled(true)
                }
        }
    }

    private func setupAppGroups() {
        if let sharedDefaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier) {
            sharedDefaults.set(true, forKey: AppConstants.UserDefaultsKeys.appLaunched)
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