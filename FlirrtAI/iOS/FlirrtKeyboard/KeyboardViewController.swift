import UIKit
import os.log
import Photos

/// Minimal Flirrt Keyboard - October 2025
/// Auto-detects screenshots from Photos library and analyzes immediately
class KeyboardViewController: UIInputViewController {

    // MARK: - Properties
    private let logger = OSLog(subsystem: "com.flirrt.keyboard", category: "minimal")
    private let appGroupID = AppConstants.appGroupIdentifier

    private var isAnalyzing = false
    private var suggestions: [FlirtSuggestion] = []
    private var lastCheckedAssetIdentifier: String?
    private var screenshotPollingTimer: Timer?

    // MARK: - UI Components
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var logoLabel: UILabel = {
        let label = UILabel()
        label.text = "🎯 Flirrt"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var instructionLabel: UILabel = {
        let label = UILabel()
        label.text = "📸 Screenshot to start"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textAlignment = .center
        label.textColor = .systemPink
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()

    private lazy var suggestionsStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isHidden = true
        return stack
    }()

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .systemPink
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private lazy var actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemPink
        button.layer.cornerRadius = 12
        button.contentEdgeInsets = UIEdgeInsets(top: 14, left: 20, bottom: 14, right: 20)
        button.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        button.isHidden = true
        return button
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDarwinNotifications()
        checkForRecentScreenshot()
        os_log("Minimal Flirrt Keyboard loaded", log: logger, type: .info)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Check immediately when keyboard appears (user might have just taken screenshot)
        checkForRecentScreenshot()
        // Start continuous polling for screenshots taken while keyboard is visible
        startScreenshotPolling()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Stop polling to save battery when keyboard is not visible
        stopScreenshotPolling()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(containerView)
        containerView.addSubview(logoLabel)
        containerView.addSubview(instructionLabel)
        containerView.addSubview(statusLabel)
        containerView.addSubview(activityIndicator)
        containerView.addSubview(actionButton)
        containerView.addSubview(suggestionsStack)

        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 280),

            // Logo
            logoLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            logoLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),

            // Instruction
            instructionLabel.topAnchor.constraint(equalTo: logoLabel.bottomAnchor, constant: 12),
            instructionLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),

            // Status
            statusLabel.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 16),
            statusLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            // Activity Indicator
            activityIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 24),

            // Action Button
            actionButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            actionButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 20),

            // Suggestions
            suggestionsStack.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 12),
            suggestionsStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            suggestionsStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            suggestionsStack.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -12)
        ])
    }

    // MARK: - Darwin Notifications
    private func setupDarwinNotifications() {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let notificationName = "com.flirrt.screenshot.detected" as CFString

        CFNotificationCenterAddObserver(
            center,
            Unmanaged.passUnretained(self).toOpaque(),
            { (center, observer, name, object, userInfo) in
                guard let observer = observer else { return }
                let keyboard = Unmanaged<KeyboardViewController>.fromOpaque(observer).takeUnretainedValue()
                keyboard.handleScreenshotDetected()
            },
            notificationName,
            nil,
            .deliverImmediately
        )

        os_log("Darwin notification listener active", log: logger, type: .info)
    }

    // MARK: - Screenshot Detection
    private func handleScreenshotDetected() {
        os_log("📸 Screenshot detected!", log: logger, type: .info)
        DispatchQueue.main.async { [weak self] in
            self?.loadAndAnalyzeScreenshot()
        }
    }

    // MARK: - Photo Library Screenshot Detection
    private func checkForRecentScreenshot() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        switch status {
        case .authorized, .limited:
            fetchRecentScreenshots()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] newStatus in
                if newStatus == .authorized || newStatus == .limited {
                    DispatchQueue.main.async {
                        self?.fetchRecentScreenshots()
                    }
                }
            }
        case .denied, .restricted:
            os_log("Photo library access denied", log: logger, type: .info)
            updateInstructionLabel(text: "📸 Grant Photos access in Settings\nto auto-analyze screenshots")
        @unknown default:
            break
        }
    }

    private func fetchRecentScreenshots() {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaSubtype = %d", PHAssetMediaSubtype.photoScreenshot.rawValue)
        fetchOptions.fetchLimit = 5

        // Fetch only screenshots
        let screenshots = PHAsset.fetchAssets(with: .image, options: fetchOptions)

        guard screenshots.count > 0 else {
            os_log("No screenshots found in library", log: logger, type: .info)
            return
        }

        // Check the most recent image
        let mostRecent = screenshots.firstObject!

        // Skip if we've already processed this screenshot
        if mostRecent.localIdentifier == lastCheckedAssetIdentifier {
            return
        }

        // Check if it was created within the last 10 seconds
        guard let creationDate = mostRecent.creationDate else { return }
        let timeSinceCreation = Date().timeIntervalSince(creationDate)

        if timeSinceCreation <= 10 {
            os_log("📸 Recent screenshot detected! Created %.1f seconds ago", log: logger, type: .info, timeSinceCreation)
            lastCheckedAssetIdentifier = mostRecent.localIdentifier
            loadAndAnalyzeAsset(mostRecent)
        } else {
            os_log("Most recent photo is %.0f seconds old (not recent)", log: logger, type: .info, timeSinceCreation)
        }
    }

    // MARK: - Screenshot Polling
    private func startScreenshotPolling() {
        // Invalidate existing timer if any
        screenshotPollingTimer?.invalidate()

        // Create timer that checks for screenshots every 2 seconds
        screenshotPollingTimer = Timer.scheduledTimer(
            withTimeInterval: 2.0,
            repeats: true
        ) { [weak self] _ in
            self?.checkForRecentScreenshot()
        }

        os_log("🔄 Screenshot polling started (every 2 seconds)", log: logger, type: .info)
    }

    private func stopScreenshotPolling() {
        screenshotPollingTimer?.invalidate()
        screenshotPollingTimer = nil
        os_log("⏸️ Screenshot polling stopped", log: logger, type: .info)
    }

    private func loadAndAnalyzeAsset(_ asset: PHAsset) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true

        PHImageManager.default().requestImage(
            for: asset,
            targetSize: CGSize(width: 1024, height: 1024),
            contentMode: .aspectFit,
            options: options
        ) { [weak self] image, info in
            guard let self = self, let image = image else {
                os_log("Failed to load screenshot image", log: self?.logger ?? OSLog.default, type: .error)
                return
            }

            DispatchQueue.main.async {
                self.analyzeScreenshotImage(image)
            }
        }
    }

    private func analyzeScreenshotImage(_ image: UIImage) {
        // Convert to JPEG data with compression
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            showError("Failed to process screenshot")
            return
        }

        os_log("Screenshot loaded: %d bytes", log: logger, type: .info, imageData.count)

        // Show analyzing state
        showAnalyzing()

        // Convert to base64 and send to backend
        let base64Image = imageData.base64EncodedString()
        analyzeWithBackend(base64Image: base64Image, screenshotId: "photo-\(Date().timeIntervalSince1970)")
    }

    private func updateInstructionLabel(text: String) {
        DispatchQueue.main.async { [weak self] in
            self?.instructionLabel.text = text
        }
    }

    private func loadAndAnalyzeScreenshot() {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupID) else {
            showError("App Groups not configured")
            return
        }

        // Get latest screenshot
        guard let screenshotId = sharedDefaults.string(forKey: AppConstants.UserDefaultsKeys.latestScreenshotId),
              let screenshotData = sharedDefaults.data(forKey: AppConstants.UserDefaultsKeys.screenshotDataKey(screenshotId)) else {
            showError("No screenshot found. Please take a screenshot first.")
            return
        }

        os_log("Loading screenshot: %@, size: %d bytes", log: logger, type: .info, screenshotId, screenshotData.count)

        // Show analyzing state
        showAnalyzing()

        // Convert to base64 and send to backend
        let base64Image = screenshotData.base64EncodedString()
        analyzeWithBackend(base64Image: base64Image, screenshotId: screenshotId)
    }

    // MARK: - Backend API
    private func analyzeWithBackend(base64Image: String, screenshotId: String) {
        let apiURL = "\(AppConstants.apiBaseURL)/flirts/generate_flirts"
        os_log("🌐 API URL: %@", log: logger, type: .info, apiURL)

        guard let url = URL(string: apiURL) else {
            os_log("❌ Invalid API URL: %@", log: logger, type: .error, apiURL)
            showError("Invalid API URL: \(apiURL)")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60

        let requestBody: [String: Any] = [
            "image_data": base64Image,
            "suggestion_type": "opener",
            "tone": "playful"
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            os_log("📤 Sending request to backend...", log: logger, type: .info)
        } catch {
            os_log("❌ Failed to create request: %@", log: logger, type: .error, error.localizedDescription)
            showError("Failed to create request")
            return
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                self.isAnalyzing = false
                self.activityIndicator.stopAnimating()

                if let error = error {
                    let nsError = error as NSError
                    os_log("❌ Network error: %@ (code: %d, domain: %@)", log: self.logger, type: .error,
                           error.localizedDescription, nsError.code, nsError.domain)
                    self.showError("Network error: \(error.localizedDescription)")
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    os_log("📥 Response status: %d", log: self.logger, type: .info, httpResponse.statusCode)
                }

                guard let data = data else {
                    os_log("❌ No response data from server", log: self.logger, type: .error)
                    self.showError("No response from server")
                    return
                }

                os_log("✅ Received %d bytes of data", log: self.logger, type: .info, data.count)

                // Parse response
                self.parseAPIResponse(data)
            }
        }.resume()
    }

    private func parseAPIResponse(_ data: Data) {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                showError("Invalid response format")
                return
            }

            // Check for success
            guard let success = json["success"] as? Bool, success else {
                let errorMsg = json["error"] as? String ?? "Unknown error"
                showError(errorMsg)
                return
            }

            // Check for intelligent response fields (new format)
            let needsMoreScrolling = json["needs_more_scrolling"] as? Bool ?? false
            let hasConversation = json["has_conversation"] as? Bool ?? false
            let screenshotType = json["screenshot_type"] as? String
            let profileScore = json["profile_score"] as? Int
            let messageToUser = json["message_to_user"] as? String

            // Handle "needs more info" case
            if needsMoreScrolling, let message = messageToUser {
                showNeedsMoreInfo(message: message, screenshotType: screenshotType, profileScore: profileScore)
                return
            }

            // Extract suggestions first (needed for chat continuation)
            var suggestionsArray: [[String: Any]]?
            if let dataDict = json["data"] as? [String: Any] {
                suggestionsArray = dataDict["suggestions"] as? [[String: Any]]
            } else {
                suggestionsArray = json["suggestions"] as? [[String: Any]]
            }

            // Handle chat detection
            if screenshotType == "chat" {
                // If active conversation with suggestions, show continuation
                if hasConversation, let suggestions = suggestionsArray, !suggestions.isEmpty {
                    // Parse suggestions and show chat continuation
                    let parsedSuggestions = suggestions.compactMap { dict -> FlirtSuggestion? in
                        guard let id = dict["id"] as? String,
                              let text = dict["text"] as? String,
                              let confidence = dict["confidence"] as? Double else {
                            return nil
                        }
                        let reasoning = dict["reasoning"] as? String
                        let references = dict["references"] as? [String]
                        return FlirtSuggestion(
                            id: id,
                            text: text,
                            confidence: confidence,
                            reasoning: reasoning,
                            references: references
                        )
                    }

                    if !parsedSuggestions.isEmpty {
                        os_log("Active chat conversation - showing continuation", log: logger, type: .info)
                        showChatContinuation(parsedSuggestions)
                        return
                    }
                }

                // Empty chat or no suggestions - ask for profile screenshot
                if let message = messageToUser {
                    showNeedsMoreInfo(message: message, screenshotType: screenshotType, profileScore: nil)
                    return
                }
            }

            guard let suggestionsArray = suggestionsArray, !suggestionsArray.isEmpty else {
                // No suggestions but not an error - might be incomplete profile
                if let message = messageToUser {
                    showNeedsMoreInfo(message: message, screenshotType: screenshotType, profileScore: profileScore)
                } else {
                    showError("No suggestions available")
                }
                return
            }

            // Parse suggestions with new fields
            let parsedSuggestions = suggestionsArray.compactMap { dict -> FlirtSuggestion? in
                guard let id = dict["id"] as? String,
                      let text = dict["text"] as? String,
                      let confidence = dict["confidence"] as? Double else {
                    return nil
                }

                let reasoning = dict["reasoning"] as? String
                let references = dict["references"] as? [String]

                return FlirtSuggestion(
                    id: id,
                    text: text,
                    confidence: confidence,
                    reasoning: reasoning,
                    references: references
                )
            }

            if parsedSuggestions.isEmpty {
                showError("No valid suggestions")
                return
            }

            os_log("Received %d suggestions (score: %d/10)", log: logger, type: .info,
                   parsedSuggestions.count, profileScore ?? 0)
            showSuggestions(parsedSuggestions)

        } catch {
            showError("Parse error: \(error.localizedDescription)")
        }
    }

    // MARK: - UI States
    private func showAnalyzing() {
        isAnalyzing = true
        instructionLabel.isHidden = true
        statusLabel.isHidden = false
        statusLabel.text = "Analyzing screenshot..."
        statusLabel.textColor = .systemPink
        activityIndicator.startAnimating()
        suggestionsStack.isHidden = true
    }

    private func showSuggestions(_ newSuggestions: [FlirtSuggestion]) {
        suggestions = newSuggestions

        instructionLabel.isHidden = true
        statusLabel.isHidden = false
        statusLabel.text = "Tap a suggestion to use it:"
        statusLabel.textColor = .systemGreen
        activityIndicator.stopAnimating()

        // Clear existing suggestions
        suggestionsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Add up to 5 suggestions
        for (index, suggestion) in newSuggestions.prefix(5).enumerated() {
            let button = createSuggestionButton(suggestion: suggestion, index: index)
            suggestionsStack.addArrangedSubview(button)
        }

        suggestionsStack.isHidden = false
    }

    private func createSuggestionButton(suggestion: FlirtSuggestion, index: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("\(index + 1). \(suggestion.text)", for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        button.backgroundColor = .secondarySystemBackground
        button.layer.cornerRadius = 8
        button.tag = index
        button.addTarget(self, action: #selector(suggestionTapped(_:)), for: .touchUpInside)
        return button
    }

    @objc private func suggestionTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index < suggestions.count else { return }

        let suggestion = suggestions[index]
        textDocumentProxy.insertText(suggestion.text)

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        os_log("Inserted suggestion: %@", log: logger, type: .info, suggestion.text)

        // Reset to initial state
        resetToInitialState()
    }

    @objc private func actionButtonTapped() {
        os_log("Action button tapped - triggering screenshot check", log: logger, type: .info)

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Hide button and show loading
        actionButton.isHidden = true
        statusLabel.text = "Looking for screenshot..."
        activityIndicator.startAnimating()

        // Immediately check for new screenshot
        checkForRecentScreenshot()
    }

    private func showNeedsMoreInfo(message: String, screenshotType: String?, profileScore: Int?) {
        os_log("Needs more info: %@", log: logger, type: .info, message)

        instructionLabel.isHidden = true
        statusLabel.isHidden = false
        activityIndicator.stopAnimating()
        suggestionsStack.isHidden = true

        var displayMessage = "💬 \(message)"
        var buttonTitle = ""

        if screenshotType == "chat" {
            statusLabel.textColor = .systemOrange
            buttonTitle = "📸 Screenshot Their Profile"
        } else if let score = profileScore, score < 6 {
            statusLabel.textColor = .systemBlue
            displayMessage += "\n\n📊 Profile completeness: \(score)/10"
            buttonTitle = "🔄 Scroll & Screenshot Again"
        } else {
            statusLabel.textColor = .systemBlue
            buttonTitle = "🔄 Try Again"
        }

        statusLabel.text = displayMessage

        // Show action button
        actionButton.setTitle(buttonTitle, for: .normal)
        actionButton.isHidden = false
    }

    private func showChatContinuation(_ newSuggestions: [FlirtSuggestion]) {
        os_log("Showing chat continuation with %d suggestions", log: logger, type: .info, newSuggestions.count)

        suggestions = newSuggestions

        instructionLabel.isHidden = true
        statusLabel.isHidden = false
        statusLabel.text = "💬 Continue the conversation:"
        statusLabel.textColor = .systemGreen
        activityIndicator.stopAnimating()
        actionButton.isHidden = true

        // Clear existing suggestions
        suggestionsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Add up to 5 suggestions
        for (index, suggestion) in newSuggestions.prefix(5).enumerated() {
            let button = createSuggestionButton(suggestion: suggestion, index: index)
            suggestionsStack.addArrangedSubview(button)
        }

        suggestionsStack.isHidden = false
    }

    private func showError(_ message: String) {
        os_log("Error: %@", log: logger, type: .error, message)

        instructionLabel.isHidden = true
        statusLabel.isHidden = false
        statusLabel.text = "⚠️ \(message)\n\nTap Fresh to try again"
        statusLabel.textColor = .systemRed
        activityIndicator.stopAnimating()
        suggestionsStack.isHidden = true
    }

    private func resetToInitialState() {
        instructionLabel.isHidden = false
        statusLabel.isHidden = true
        statusLabel.text = ""
        suggestionsStack.isHidden = true
        suggestions = []
    }

    deinit {
        os_log("KeyboardViewController deinitialized", log: logger, type: .info)
    }
}

// MARK: - Data Models
struct FlirtSuggestion {
    let id: String
    let text: String
    let confidence: Double
    let reasoning: String?
    let references: [String]?
}
