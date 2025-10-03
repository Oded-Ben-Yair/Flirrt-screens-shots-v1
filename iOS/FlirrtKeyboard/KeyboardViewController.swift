import UIKit
import os.log

class KeyboardViewController: UIInputViewController {

    // MARK: - Memory Management
    private let logger = OSLog(subsystem: "com.flirrt.keyboard", category: "memory")
    private var memoryObserver: NSObjectProtocol?
    private let appGroupID = "group.com.flirrt.shared"

    private var heightConstraint: NSLayoutConstraint?
    private let memoryLimit: Int = 60 * 1024 * 1024 // 60MB limit

    // MARK: - API State
    private var isLoading = false
    private var currentSuggestions: [Suggestion] = []
    private var errorMessage: String?

    // MARK: - Computed Properties
    private var authToken: String? {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupID) else { return nil }
        return sharedDefaults.string(forKey: "auth_token")
    }

    private lazy var flirrtFreshButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("💫 Fresh", for: .normal) // Shorter title to save memory
        button.backgroundColor = .systemPink
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(flirrtFreshTapped), for: .touchUpInside)
        return button
    }()

    private lazy var analyzeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("📸 Analyze", for: .normal) // Shorter title to save memory
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(analyzeTapped), for: .touchUpInside)
        return button
    }()

    private lazy var suggestionsView: SuggestionsView = {
        let view = SuggestionsView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        view.delegate = self
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupMemoryMonitoring()
        setupUI()
        setupDarwinNotifications()  // NEW: Listen for screenshot notifications from main app
        loadSharedData()

        os_log("KeyboardViewController loaded", log: logger, type: .info)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        // Set keyboard height
        let height: CGFloat = suggestionsView.isHidden ? 250 : 350
        heightConstraint?.constant = height
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground

        // Add subviews
        view.addSubview(flirrtFreshButton)
        view.addSubview(analyzeButton)
        view.addSubview(suggestionsView)

        // Setup constraints
        NSLayoutConstraint.activate([
            flirrtFreshButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            flirrtFreshButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            flirrtFreshButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.45, constant: -15),
            flirrtFreshButton.heightAnchor.constraint(equalToConstant: 50),

            analyzeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            analyzeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            analyzeButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.45, constant: -15),
            analyzeButton.heightAnchor.constraint(equalToConstant: 50),

            suggestionsView.topAnchor.constraint(equalTo: flirrtFreshButton.bottomAnchor, constant: 10),
            suggestionsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            suggestionsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            suggestionsView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10)
        ])

        // Set height constraint
        heightConstraint = view.heightAnchor.constraint(equalToConstant: 250)
        heightConstraint?.priority = .defaultHigh
        heightConstraint?.isActive = true
    }

    private func setupMemoryMonitoring() {
        // Monitor memory warnings
        memoryObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleMemoryWarning()
        }

        // Initial memory check
        checkMemoryUsage()
    }

    // NEW: Setup Darwin notifications to receive screenshot events from main app
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

        os_log("Darwin notification listener registered for screenshot detection", log: logger, type: .info)
    }

    // NEW: Handle screenshot detection notification
    private func handleScreenshotDetected() {
        os_log("📸 Screenshot detected via Darwin notification!", log: logger, type: .info)

        // Load screenshot data from App Groups
        DispatchQueue.main.async { [weak self] in
            self?.loadLatestScreenshot()
        }
    }

    // NEW: Load latest screenshot from App Groups shared storage
    private func loadLatestScreenshot() {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt.shared") else {
            os_log("Failed to access App Groups shared storage", log: logger, type: .error)
            return
        }

        // Check for latest screenshot metadata
        if let screenshotId = sharedDefaults.string(forKey: "latest_screenshot_id"),
           let screenshotData = sharedDefaults.data(forKey: "screenshot_\(screenshotId)") {

            os_log("Loading screenshot: %@", log: logger, type: .info, screenshotId)

            // TODO: Compress and send to backend for analysis
            // For now, just trigger analysis with the screenshot ID
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.analyzeTapped()  // Triggers the existing analysis flow
            }
        } else {
            os_log("No screenshot data found in App Groups", log: logger, type: .info)
        }
    }

    private func checkMemoryUsage() {
        let memoryUsage = getMemoryUsage()
        let memoryMB = Double(memoryUsage) / (1024 * 1024)

        os_log("Current memory usage: %.2f MB", log: logger, type: .info, memoryMB)

        if memoryUsage > memoryLimit {
            os_log("Memory limit exceeded: %.2f MB", log: logger, type: .error, memoryMB)
            handleMemoryWarning()
        }
    }

    private func handleMemoryWarning() {
        os_log("Handling memory warning", log: logger, type: .error)
        clearCache()
        reduceFunctionality()
    }

    private func getMemoryUsage() -> Int {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        return result == KERN_SUCCESS ? Int(info.resident_size) : 0
    }

    private func loadSharedData() {
        guard hasFullAccess else {
            showFullAccessRequired()
            return
        }

        // Load from App Groups with correct suite name
        guard let sharedDefaults = UserDefaults(suiteName: appGroupID) else {
            os_log("Failed to access App Group: %@", log: logger, type: .error, appGroupID)
            return
        }

        let userAuthenticated = sharedDefaults.bool(forKey: "user_authenticated")
        let voiceEnabled = sharedDefaults.bool(forKey: "voice_enabled")
        let lastScreenshotTime = sharedDefaults.double(forKey: "last_screenshot_time")

        os_log("Loaded shared data - auth: %d, voice: %d, last_screenshot: %.0f",
               log: logger, type: .info, userAuthenticated, voiceEnabled, lastScreenshotTime)

        if !userAuthenticated {
            showAuthenticationRequired()
        }

        // Update UI based on recent screenshot activity
        if Date().timeIntervalSince1970 - lastScreenshotTime < 60 {
            // Recent screenshot detected - show analyze button prominently
            analyzeButton.alpha = 1.0
            flirrtFreshButton.alpha = 0.7
        } else {
            analyzeButton.alpha = 0.7
            flirrtFreshButton.alpha = 1.0
        }
    }

    @objc private func flirrtFreshTapped() {
        guard hasFullAccess else {
            showFullAccessRequired()
            return
        }

        // Make API call to generate fresh flirts
        generateFlirts()
    }

    private func generateFlirts() {
        // Show loading state
        isLoading = true
        suggestionsView.showLoading()
        suggestionsView.isHidden = false
        view.setNeedsLayout()

        // Build API request for flirts endpoint with Grok-4-latest vision
        guard let url = URL(string: "http://localhost:3000/api/v1/flirts/generate_flirts") else {
            showError("Invalid API URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add auth token if available
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Placeholder test image (1x1 pink pixel) - TODO: Replace with actual screenshot from Darwin notifications
        let testImageBase64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg=="

        // Request body for Grok-4-latest vision + flirt generation
        let body: [String: Any] = [
            "screenshot_id": "test-123",  // Will be replaced with real screenshot ID
            "image_data": testImageBase64,  // Base64 image without data:image prefix
            "suggestion_type": "opener",
            "tone": "playful"
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            showError("Failed to create request: \(error.localizedDescription)")
            return
        }

        // Make API call
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    self?.showError("Network error: \(error.localizedDescription)")
                    return
                }

                guard let data = data else {
                    self?.showError("No data received from server")
                    return
                }

                // Parse response
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let success = json["success"] as? Bool, success {
                            // Parse suggestions from orchestrated response (nested under "data")
                            var suggestionsArray: [[String: Any]]?
                            if let dataDict = json["data"] as? [String: Any] {
                                suggestionsArray = dataDict["suggestions"] as? [[String: Any]]
                            } else {
                                // Fallback for legacy response format
                                suggestionsArray = json["suggestions"] as? [[String: Any]]
                            }

                            if let suggestionsArray = suggestionsArray {
                                let suggestions = suggestionsArray.compactMap { dict -> Suggestion? in
                                    guard let id = dict["id"] as? String,
                                          let text = dict["text"] as? String,
                                          let tone = dict["tone"] as? String,
                                          let confidence = dict["confidence"] as? Double else {
                                        return nil
                                    }
                                    return Suggestion(
                                        id: id,
                                        text: text,
                                        tone: tone,
                                        confidence: confidence,
                                        voiceAvailable: false
                                    )
                                }

                                self?.currentSuggestions = suggestions
                                self?.suggestionsView.setSuggestions(suggestions)
                                self?.errorMessage = nil

                                if let self = self {
                                    os_log("Received %d suggestions from API", log: self.logger, type: .info, suggestions.count)
                                }
                            } else {
                                self?.showError("Invalid suggestions format")
                            }
                        } else {
                            // API returned error
                            let errorMsg = json["error"] as? String ?? "Unknown error"
                            self?.showError("API Error: \(errorMsg)")
                        }
                    } else {
                        self?.showError("Invalid JSON response")
                    }
                } catch {
                    self?.showError("Parse error: \(error.localizedDescription)")
                }
            }
        }.resume()
    }

    private func showError(_ message: String) {
        errorMessage = message
        os_log("Error: %@", log: logger, type: .error, message)

        // Show error in suggestions view
        let errorSuggestion = Suggestion(
            id: "error",
            text: "⚠️ \(message)\n\nTap Fresh to try again",
            tone: "error",
            confidence: 0.0,
            voiceAvailable: false
        )
        suggestionsView.setSuggestions([errorSuggestion])
        suggestionsView.isHidden = false
        view.setNeedsLayout()
    }

    @objc private func analyzeTapped() {
        guard hasFullAccess else {
            showFullAccessRequired()
            return
        }

        // For now, Analyze button does the same as Fresh button
        // TODO: In production, this should upload a screenshot first, then analyze
        generateFlirts()
    }

    private func loadOpenerSuggestions() {
        suggestionsView.isHidden = false
        view.setNeedsLayout()

        // Load from shared container
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            os_log("Failed to access App Group container", log: logger, type: .error)
            return
        }

        let suggestionsURL = containerURL.appendingPathComponent("suggestions.json")

        do {
            let data = try Data(contentsOf: suggestionsURL)
            let suggestions = try JSONDecoder().decode([Suggestion].self, from: data)
            suggestionsView.setSuggestions(suggestions)
            os_log("Loaded %d suggestions", log: logger, type: .info, suggestions.count)
        } catch {
            os_log("Failed to load suggestions: %@", log: logger, type: .error, error.localizedDescription)

            // Fallback: Load default suggestions
            let defaultSuggestions = createDefaultSuggestions()
            suggestionsView.setSuggestions(defaultSuggestions)
        }
    }

    private func createDefaultSuggestions() -> [Suggestion] {
        return [
            Suggestion(id: "1", text: "Hey! How's your day going?", tone: "casual", confidence: 0.8, voiceAvailable: false),
            Suggestion(id: "2", text: "That's such an interesting photo!", tone: "friendly", confidence: 0.9, voiceAvailable: false),
            Suggestion(id: "3", text: "I'd love to know more about that!", tone: "curious", confidence: 0.85, voiceAvailable: false)
        ]
    }

    private func requestScreenshotAnalysis() {
        // Update shared data to indicate analysis request
        if let sharedDefaults = UserDefaults(suiteName: appGroupID) {
            sharedDefaults.set(Date().timeIntervalSince1970, forKey: "analysis_request_time")
            sharedDefaults.set(true, forKey: "analysis_requested")
            sharedDefaults.synchronize()
        }

        // Notify main app to process screenshot
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName("com.flirrt.analyze.request" as CFString),
            nil, nil, true
        )

        os_log("Screenshot analysis requested", log: logger, type: .info)
        suggestionsView.showLoading()

        // Auto-refresh after a delay to check for results
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.checkForAnalysisResults()
        }
    }

    private func checkForAnalysisResults() {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupID) else { return }

        let analysisCompleted = sharedDefaults.bool(forKey: "analysis_completed")
        let resultTime = sharedDefaults.double(forKey: "analysis_result_time")
        let requestTime = sharedDefaults.double(forKey: "analysis_request_time")

        if analysisCompleted && resultTime > requestTime {
            os_log("Analysis results available, reloading suggestions", log: logger, type: .info)
            loadOpenerSuggestions()
        }
    }

    private func showFullAccessRequired() {
        let alert = UIAlertController(title: "Full Access Required",
                                     message: "Please enable Full Access in Settings to use Flirrt features",
                                     preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func showAuthenticationRequired() {
        textDocumentProxy.insertText("Please open Flirrt app to sign in first")
    }

    private func clearCache() {
        // Clear any cached images or data
        URLCache.shared.removeAllCachedResponses()

        // Clear any temporary files in shared container
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            let tempDir = containerURL.appendingPathComponent("temp")
            try? FileManager.default.removeItem(at: tempDir)
        }

        os_log("Cache cleared", log: logger, type: .info)
    }

    private func reduceFunctionality() {
        // Reduce features to save memory
        suggestionsView.reduceQuality()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Release memory and clean up
        clearCache()

        // Update last active time
        if let sharedDefaults = UserDefaults(suiteName: appGroupID) {
            sharedDefaults.set(Date().timeIntervalSince1970, forKey: "keyboard_last_active")
            sharedDefaults.synchronize()
        }

        os_log("KeyboardViewController will disappear", log: logger, type: .info)
    }

    deinit {
        if let observer = memoryObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        os_log("KeyboardViewController deinitialized", log: logger, type: .info)
    }
}

// MARK: - SuggestionsViewDelegate
extension KeyboardViewController: SuggestionsViewDelegate {
    func didSelectSuggestion(_ text: String) {
        textDocumentProxy.insertText(text)
        suggestionsView.isHidden = true
        view.setNeedsLayout()
    }

    func didRequestVoice(for text: String, voiceId: String) {
        // Request voice synthesis
        requestVoiceSynthesis(text: text, voiceId: voiceId)
    }
}

// MARK: - Supporting Types
struct Suggestion: Codable {
    let id: String
    let text: String
    let tone: String
    let confidence: Double
    let voiceAvailable: Bool
}

protocol SuggestionsViewDelegate: AnyObject {
    func didSelectSuggestion(_ text: String)
    func didRequestVoice(for text: String, voiceId: String)
}

class SuggestionsView: UIView {
    weak var delegate: SuggestionsViewDelegate?
    private var currentSuggestions: [Suggestion] = []
    private var stackView: UIStackView?
    private var loadingView: UIView?

    func setSuggestions(_ suggestions: [Suggestion]) {
        // Clear existing UI
        subviews.forEach { $0.removeFromSuperview() }
        currentSuggestions = suggestions

        // Create container stack
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false

        // Add up to 3 suggestion cards
        for (index, suggestion) in suggestions.prefix(3).enumerated() {
            let card = createSuggestionCard(suggestion: suggestion, index: index)
            stack.addArrangedSubview(card)
        }

        // Add refresh button if we have suggestions
        if !suggestions.isEmpty {
            let refreshButton = UIButton(type: .system)
            refreshButton.setTitle("🔄 More", for: .normal)
            refreshButton.setTitleColor(.systemPink, for: .normal)
            refreshButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
            refreshButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
            stack.addArrangedSubview(refreshButton)
        }

        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -8)
        ])

        stackView = stack
    }

    private func createSuggestionCard(suggestion: Suggestion, index: Int) -> UIButton {
        let button = UIButton(type: .system)

        // Configure text
        button.setTitle("\(index + 1). \(suggestion.text)", for: .normal)
        button.setTitleColor(.label, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15)
        button.titleLabel?.numberOfLines = 0
        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.contentHorizontalAlignment = .left
        button.contentEdgeInsets = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)

        // Style
        button.backgroundColor = .systemBackground
        button.layer.cornerRadius = 12
        button.layer.borderWidth = 1.5
        button.layer.borderColor = UIColor.systemGray4.cgColor

        // Interaction
        button.tag = index
        button.addTarget(self, action: #selector(suggestionTapped(_:)), for: .touchUpInside)

        // Height constraint
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 50).isActive = true

        return button
    }

    @objc private func suggestionTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index < currentSuggestions.count else { return }

        // Add haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Notify delegate
        delegate?.didSelectSuggestion(currentSuggestions[index].text)
    }

    func showLoading() {
        // Clear existing UI
        subviews.forEach { $0.removeFromSuperview() }

        // Create loading container
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        // Spinner
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = .systemPink
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()

        // Label
        let label = UILabel()
        label.text = "Generating flirts..."
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(spinner)
        container.addSubview(label)
        addSubview(container)

        // Constraints
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            spinner.topAnchor.constraint(equalTo: container.topAnchor),

            label.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            label.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 12),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            container.centerXAnchor.constraint(equalTo: centerXAnchor),
            container.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        loadingView = container
    }

    func reduceQuality() {
        // Reduce visual effects to save memory
        stackView?.subviews.forEach { view in
            view.layer.shadowOpacity = 0
            view.layer.shadowRadius = 0
        }
    }
}

// Voice synthesis request
extension KeyboardViewController {
    private func requestVoiceSynthesis(text: String, voiceId: String) {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.flirrt.ai.shared") else { return }

        let request = VoiceRequest(text: text, voiceId: voiceId)
        let requestURL = containerURL.appendingPathComponent("voice_request.json")

        if let data = try? JSONEncoder().encode(request) {
            try? data.write(to: requestURL)

            CFNotificationCenterPostNotification(
                CFNotificationCenterGetDarwinNotifyCenter(),
                CFNotificationName("com.flirrt.voice.request" as CFString),
                nil, nil, true
            )
        }
    }
}

struct VoiceRequest: Codable {
    let text: String
    let voiceId: String
}