import UIKit
import Social

class ShareViewController: SLComposeServiceViewController {

    override func isContentValid() -> Bool {
        // Validate we have an image
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProvider = extensionItem.attachments?.first else {
            return false
        }

        return itemProvider.hasItemConformingToTypeIdentifier("public.image")
    }

    override func didSelectPost() {
        // Get the screenshot from the share sheet
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProvider = extensionItem.attachments?.first else {
            self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            return
        }

        if itemProvider.hasItemConformingToTypeIdentifier("public.image") {
            itemProvider.loadItem(forTypeIdentifier: "public.image", options: nil) { [weak self] item, error in
                if let error = error {
                    print("Error loading image: \(error)")
                    self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
                    return
                }

                self?.processScreenshot(item)
            }
        }
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
            extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            return
        }

        // Save to App Groups container
        saveScreenshotToSharedContainer(screenshotImage)

        // Notify main app
        notifyMainApp()

        // Complete the share action
        self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }

    private func saveScreenshotToSharedContainer(_ image: UIImage) {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.flirrt.ai.shared") else {
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
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.flirrt.ai.shared") else { return }

        let metadataURL = containerURL.appendingPathComponent("screenshot_metadata.json")

        if let data = try? JSONEncoder().encode(metadata) {
            try? data.write(to: metadataURL)
        }

        // Also save to UserDefaults for quick access
        if let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt.ai.shared") {
            sharedDefaults.set(metadata.fileName, forKey: "latest_screenshot")
            sharedDefaults.set(metadata.timestamp.timeIntervalSince1970, forKey: "latest_screenshot_time")
            sharedDefaults.synchronize()
        }
    }

    private func notifyMainApp() {
        // Post Darwin notification to wake up main app
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName("com.flirrt.screenshot.ready" as CFString),
            nil,
            nil,
            true
        )
    }

    override func configurationItems() -> [Any]! {
        // Optional: Add configuration items
        let item = SLComposeSheetConfigurationItem()
        item?.title = "Analysis Type"
        item?.value = "Auto-detect"
        item?.tapHandler = {
            // Show options
        }

        return [item as Any]
    }
}

// MARK: - Supporting Types
struct ScreenshotMetadata: Codable {
    let fileName: String
    let timestamp: Date
    let size: Int
    let source: String
}