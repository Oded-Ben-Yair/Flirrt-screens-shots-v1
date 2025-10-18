import UIKit

class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up the view
        setupUI()

        // Process the shared content
        processSharedContent()
    }

    private func setupUI() {
        view.backgroundColor = UIColor.systemBackground

        // Add a simple loading indicator
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)

        let label = UILabel()
        label.text = "Analyzing screenshot with Vibe8 AI..."
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),

            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 20),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    private func processSharedContent() {
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProvider = extensionItem.attachments?.first else {
            completeRequest()
            return
        }

        if itemProvider.hasItemConformingToTypeIdentifier("public.image") {
            itemProvider.loadItem(forTypeIdentifier: "public.image", options: nil) { [weak self] item, error in
                DispatchQueue.main.async {
                    if let error = error {
                        print("Error loading image: \(error)")
                        self?.completeRequest()
                        return
                    }

                    self?.processScreenshot(item)
                }
            }
        } else {
            completeRequest()
        }
    }

    private func completeRequest() {
        self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }

    private func processScreenshot(_ item: NSSecureCoding?) {
        var image: UIImage?

        if let url = item as? URL {
            image = UIImage(contentsOfFile: url.path)
        } else if let data = item as? Data {
            image = UIImage(data: data)
        } else if let img = item as? UIImage {
            image = img
        }

        guard let screenshotImage = image else {
            DispatchQueue.main.async {
                self.completeRequest()
            }
            return
        }

        // Save to App Groups container
        saveScreenshotToSharedContainer(screenshotImage)

        // Notify main app
        notifyMainApp()

        // Complete the share action
        DispatchQueue.main.async {
            self.completeRequest()
        }
    }

    private func saveScreenshotToSharedContainer(_ image: UIImage) {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupIdentifier) else {
            print("Failed to get shared container")
            return
        }

        // Create screenshots directory if needed
        let screenshotsDir = containerURL.appendingPathComponent("Screenshots")
        try? FileManager.default.createDirectory(at: screenshotsDir, withIntermediateDirectories: true)

        // Compress and save image
        let fileName = "screenshot_\(Date().timeIntervalSince1970).jpg"
        let fileURL = screenshotsDir.appendingPathComponent(fileName)

        // Compress to reduce size (max 10MB per spec)
        var compressionQuality: CGFloat = 1.0
        var imageData = image.jpegData(compressionQuality: compressionQuality)

        while let data = imageData, data.count > 10 * 1024 * 1024, compressionQuality > 0.1 {
            compressionQuality -= 0.1
            imageData = image.jpegData(compressionQuality: compressionQuality)
        }

        if let data = imageData {
            try? data.write(to: fileURL)

            // Save metadata
            let metadata = ScreenshotMetadata(
                fileName: fileName,
                timestamp: Date(),
                size: data.count,
                source: "share_extension"
            )

            saveMetadata(metadata)
        }
    }

    private func saveMetadata(_ metadata: ScreenshotMetadata) {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupIdentifier) else { return }

        let metadataURL = containerURL.appendingPathComponent("screenshot_metadata.json")

        if let data = try? JSONEncoder().encode(metadata) {
            try? data.write(to: metadataURL)
        }

        // Also save to UserDefaults for quick access
        if let sharedDefaults = UserDefaults(suiteName: AppConstants.appGroupIdentifier) {
            sharedDefaults.set(metadata.fileName, forKey: AppConstants.UserDefaultsKeys.latestScreenshot)
            sharedDefaults.set(metadata.timestamp.timeIntervalSince1970, forKey: AppConstants.UserDefaultsKeys.latestScreenshotTimeShare)
            sharedDefaults.synchronize()
        }
    }

    private func notifyMainApp() {
        // Post Darwin notification to wake up main app
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName("com.vibe8.screenshot.ready" as CFString),
            nil,
            nil,
            true
        )
    }

    // configurationItems() is deprecated in modern iOS versions
    // Removed to eliminate build warnings
}

// MARK: - Supporting Types
struct ScreenshotMetadata: Codable {
    let fileName: String
    let timestamp: Date
    let size: Int
    let source: String
}