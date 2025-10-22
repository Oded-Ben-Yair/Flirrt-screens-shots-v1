import SwiftUI
import UserNotifications

@main
struct Vibe8App: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var apiClient = APIClient()
    @StateObject private var sharedDataManager = SharedDataManager()
    // NOTE: ScreenshotDetectionManager needs to be added to Xcode Vibe8 target before build
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
                    // ✅ Enable screenshot detection in main app
                    // (Keyboard extensions CANNOT access Photos - Apple restriction)
                    screenshotManager.setDetectionEnabled(true)
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