import Foundation
import Photos
import UIKit

/// Screenshot Capture Service - Main App Only
/// CRITICAL: Photo Library access is ONLY allowed in the main app, NOT in keyboard extension
/// This service handles screenshot detection, processing, and sharing with keyboard via App Groups
class ScreenshotCaptureService {
    static let shared = ScreenshotCaptureService()

    private let appGroupID = "group.com.vibe8" // Must match AppConstants.appGroupIdentifier
    private let darwinNotificationName = "com.vibe8.screenshot.detected"

    private var lastProcessedAssetIdentifier: String?

    // NEW: Multi-Screenshot Context - Session Management
    private let sessionTimeout: TimeInterval = 30 * 60 // 30 minutes
    private var currentSessionID: String?

    private init() {
        // Load existing session if still active
        loadActiveSession()
    }

    // MARK: - Public API

    /// Request Photo Library permission and capture latest screenshot
    func captureAndAnalyzeScreenshot(completion: @escaping (Result<Void, Error>) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            guard let self = self else { return }

            switch status {
            case .authorized, .limited:
                self.fetchLatestScreenshot(completion: completion)
            case .denied, .restricted:
                DispatchQueue.main.async {
                    completion(.failure(ScreenshotError.photoLibraryAccessDenied))
                }
            case .notDetermined:
                DispatchQueue.main.async {
                    completion(.failure(ScreenshotError.photoLibraryAccessNotDetermined))
                }
            @unknown default:
                DispatchQueue.main.async {
                    completion(.failure(ScreenshotError.unknownAuthorizationStatus))
                }
            }
        }
    }

    // MARK: - Private Methods

    private func fetchLatestScreenshot(completion: @escaping (Result<Void, Error>) -> Void) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaSubtype = %d", PHAssetMediaSubtype.photoScreenshot.rawValue)
        fetchOptions.fetchLimit = 1

        let screenshots = PHAsset.fetchAssets(with: .image, options: fetchOptions)

        guard let latestScreenshot = screenshots.firstObject else {
            DispatchQueue.main.async {
                completion(.failure(ScreenshotError.noScreenshotFound))
            }
            return
        }

        // Skip if we've already processed this screenshot
        if latestScreenshot.localIdentifier == lastProcessedAssetIdentifier {
            DispatchQueue.main.async {
                completion(.failure(ScreenshotError.screenshotAlreadyProcessed))
            }
            return
        }

        // Check if screenshot is recent (within last 30 seconds)
        if let creationDate = latestScreenshot.creationDate {
            let timeSinceCreation = Date().timeIntervalSince(creationDate)
            if timeSinceCreation > 30 {
                DispatchQueue.main.async {
                    completion(.failure(ScreenshotError.screenshotTooOld(seconds: timeSinceCreation)))
                }
                return
            }
        }

        // Mark as processed
        lastProcessedAssetIdentifier = latestScreenshot.localIdentifier

        // Load and process image
        loadAndProcessImage(asset: latestScreenshot, completion: completion)
    }

    private func loadAndProcessImage(asset: PHAsset, completion: @escaping (Result<Void, Error>) -> Void) {
        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = false
        requestOptions.deliveryMode = .highQualityFormat
        requestOptions.isNetworkAccessAllowed = true

        // Request full resolution image
        imageManager.requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: requestOptions
        ) { [weak self] image, info in
            guard let self = self, let image = image else {
                DispatchQueue.main.async {
                    completion(.failure(ScreenshotError.failedToLoadImage))
                }
                return
            }

            // Check for errors
            if let error = info?[PHImageErrorKey] as? Error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }

            // Process screenshot
            self.processScreenshot(image, completion: completion)
        }
    }

    private func processScreenshot(_ image: UIImage, completion: @escaping (Result<Void, Error>) -> Void) {
        // CRITICAL: Resize image to prevent memory bloat
        // Max width: 800px, maintains aspect ratio
        guard let resizedImage = image.resized(toWidth: 800) else {
            DispatchQueue.main.async {
                completion(.failure(ScreenshotError.failedToResizeImage))
            }
            return
        }

        // CRITICAL: Compress to JPEG with 70% quality
        // This significantly reduces file size while maintaining readability
        guard let jpegData = resizedImage.jpegData(compressionQuality: 0.7) else {
            DispatchQueue.main.async {
                completion(.failure(ScreenshotError.failedToCompressImage))
            }
            return
        }

        print("📸 Screenshot processed: \(jpegData.count) bytes (compressed from ~\(image.jpegData(compressionQuality: 1.0)?.count ?? 0) bytes)")

        // Upload to backend
        uploadToBackend(imageData: jpegData, completion: completion)
    }

    private func uploadToBackend(imageData: Data, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                // NEW: Get or create conversation session
                let sessionID = getOrCreateSession()

                // Upload and analyze screenshot with conversation context
                let result = try await APIClient.shared.generateFlirtsFromImage(
                    imageData: imageData,
                    conversationID: sessionID,
                    suggestionType: .opener,
                    tone: "playful"
                )

                // Extract suggestions
                let suggestions = result.flirts.map { flirt in
                    FlirtSuggestion(
                        id: flirt.id,
                        text: flirt.text,
                        confidence: flirt.confidence,
                        reasoning: flirt.reasoning,
                        references: flirt.references
                    )
                }

                // Share with keyboard via App Groups
                self.shareSuggestionsWithKeyboard(suggestions)

                // Notify keyboard to refresh
                self.notifyKeyboard()

                DispatchQueue.main.async {
                    completion(.success(()))
                }

            } catch {
                print("❌ Backend upload failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    private func shareSuggestionsWithKeyboard(_ suggestions: [FlirtSuggestion]) {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupID) else {
            print("❌ Failed to access App Group")
            return
        }

        do {
            // Encode suggestions
            let encoder = JSONEncoder()
            let data = try encoder.encode(suggestions)

            // Save to App Group
            sharedDefaults.set(data, forKey: "latestSuggestions")
            sharedDefaults.set(Date(), forKey: "lastUpdate")
            sharedDefaults.synchronize()

            print("✅ Shared \(suggestions.count) suggestions with keyboard via App Group")

        } catch {
            print("❌ Failed to encode suggestions: \(error.localizedDescription)")
        }
    }

    private func notifyKeyboard() {
        // Post Darwin notification to keyboard extension
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let name = CFNotificationName(darwinNotificationName as CFString)

        CFNotificationCenterPostNotification(
            center,
            name,
            nil,
            nil,
            true
        )

        print("📢 Posted Darwin notification to keyboard")
    }

    // MARK: - Session Management

    /// Load active session from App Group (if within timeout)
    private func loadActiveSession() {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupID) else { return }

        guard let sessionID = sharedDefaults.string(forKey: "conversationSessionID"),
              let lastActivityDate = sharedDefaults.object(forKey: "sessionLastActivity") as? Date else {
            return
        }

        // Check if session is still active (within 30 minutes)
        let timeSinceActivity = Date().timeIntervalSince(lastActivityDate)
        if timeSinceActivity < sessionTimeout {
            currentSessionID = sessionID
            print("📝 Loaded active session: \(sessionID)")
        } else {
            print("⏰ Session expired (\(Int(timeSinceActivity/60)) minutes ago)")
            clearSession()
        }
    }

    /// Get current session or create new one
    private func getOrCreateSession() -> String {
        if let sessionID = currentSessionID {
            // Update activity timestamp
            saveSession(sessionID)
            return sessionID
        }

        // Create new session
        let sessionID = "session_\(UUID().uuidString)"
        currentSessionID = sessionID
        saveSession(sessionID)

        print("✨ Created new conversation session: \(sessionID)")
        return sessionID
    }

    /// Save session to App Group
    private func saveSession(_ sessionID: String) {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupID) else { return }

        sharedDefaults.set(sessionID, forKey: "conversationSessionID")
        sharedDefaults.set(Date(), forKey: "sessionLastActivity")
        sharedDefaults.synchronize()
    }

    /// Clear current session
    private func clearSession() {
        currentSessionID = nil

        guard let sharedDefaults = UserDefaults(suiteName: appGroupID) else { return }
        sharedDefaults.removeObject(forKey: "conversationSessionID")
        sharedDefaults.removeObject(forKey: "sessionLastActivity")
        sharedDefaults.synchronize()
    }

    /// Public: Start new conversation (reset session)
    func newConversation() {
        clearSession()
        print("🔄 Started new conversation")
    }

    /// Get current session info
    func getCurrentSessionInfo() -> (id: String?, isActive: Bool) {
        guard let sessionID = currentSessionID else {
            return (nil, false)
        }

        guard let sharedDefaults = UserDefaults(suiteName: appGroupID),
              let lastActivityDate = sharedDefaults.object(forKey: "sessionLastActivity") as? Date else {
            return (sessionID, false)
        }

        let timeSinceActivity = Date().timeIntervalSince(lastActivityDate)
        let isActive = timeSinceActivity < sessionTimeout

        return (sessionID, isActive)
    }

    // MARK: - Permission Check

    func checkPhotoLibraryPermission() -> PHAuthorizationStatus {
        return PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }

    func requestPhotoLibraryPermission(completion: @escaping (PHAuthorizationStatus) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                completion(status)
            }
        }
    }
}

// MARK: - Error Types

enum ScreenshotError: Error, LocalizedError {
    case photoLibraryAccessDenied
    case photoLibraryAccessNotDetermined
    case unknownAuthorizationStatus
    case noScreenshotFound
    case screenshotAlreadyProcessed
    case screenshotTooOld(seconds: TimeInterval)
    case failedToLoadImage
    case failedToResizeImage
    case failedToCompressImage

    var errorDescription: String? {
        switch self {
        case .photoLibraryAccessDenied:
            return "Photo library access denied. Please grant permission in Settings."
        case .photoLibraryAccessNotDetermined:
            return "Photo library permission not determined."
        case .unknownAuthorizationStatus:
            return "Unknown photo library authorization status."
        case .noScreenshotFound:
            return "No screenshots found in photo library."
        case .screenshotAlreadyProcessed:
            return "This screenshot has already been processed."
        case .screenshotTooOld(let seconds):
            return "Screenshot is too old (\(Int(seconds)) seconds). Please take a new screenshot."
        case .failedToLoadImage:
            return "Failed to load screenshot image."
        case .failedToResizeImage:
            return "Failed to resize screenshot."
        case .failedToCompressImage:
            return "Failed to compress screenshot."
        }
    }
}

// MARK: - UIImage Extension

extension UIImage {
    /// Resize image to specified width while maintaining aspect ratio
    /// CRITICAL: Prevents memory bloat from large images
    func resized(toWidth width: CGFloat) -> UIImage? {
        let scale = width / size.width
        let newHeight = size.height * scale
        let newSize = CGSize(width: width, height: newHeight)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

// MARK: - FlirtSuggestion Model (matching keyboard extension)

struct FlirtSuggestion: Codable {
    let id: String
    let text: String
    let confidence: Double
    let reasoning: String?
    let references: [String]?
}
