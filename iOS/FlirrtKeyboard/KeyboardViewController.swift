import UIKit
import Foundation
import Photos
import OSLog

@MainActor
final class KeyboardViewController: UIInputViewController {

    // MARK: - Memory Management
    private let logger = OSLog(subsystem: "com.flirrt.keyboard", category: "memory")
    private var memoryObserver: NSObjectProtocol?
    private let appGroupID = "group.com.flirrt.shared"

    private var heightConstraint: NSLayoutConstraint?
    private let memoryLimit: Int = 60 * 1024 * 1024 // 60MB limit

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
        loadSharedData()
        setupScreenshotObserver()

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
            Task { @MainActor in
                self?.handleMemoryWarning()
            }
        }

        // Initial memory check
        checkMemoryUsage()
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
        provideSelectionFeedback()
        guard hasFullAccess else {
            showFullAccessRequired()
            return
        }

        // Provide haptic feedback
        provideSelectionFeedback()

        // Load opener suggestions from shared data OR make API call
        loadOpenerSuggestions()
    }

    @objc private func analyzeTapped() {
        provideSelectionFeedback()
        guard hasFullAccess else {
            showFullAccessRequired()
            return
        }

        // Provide haptic feedback
        provideSelectionFeedback()

        // Show loading state
        suggestionsView.showLoading()

        // Try to detect recent screenshots first
        checkForRecentScreenshot()

        // Make API request for response-type suggestions
        makeAnalysisAPIRequest()
    }

    private func loadOpenerSuggestions() {
        suggestionsView.isHidden = false
        view.setNeedsLayout()

        // First check for cached suggestions
        if let cachedSuggestions = loadCachedSuggestions() {
            os_log("Using cached suggestions", log: logger, type: .info)
            displaySuggestions(cachedSuggestions)
            return
        }

        // Make API call to generate fresh suggestions
        makeFlirtAPIRequest()
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
        // Removed sharedDefaults.synchronize() as per instructions
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
            // Removed sharedDefaults.synchronize() as per instructions
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
@MainActor
@MainActor
protocol SuggestionsViewDelegate: AnyObject {
    func didSelectSuggestion(_ text: String)
    func didRequestVoice(for text: String, voiceId: String)
}

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

struct SuggestionItem {
    let text: String
    let confidence: Double
    let tone: String
}

class SuggestionsView: UIView {
    weak var delegate: SuggestionsViewDelegate?

    private var stackView: UIStackView!
    private var loadingIndicator: UIActivityIndicatorView!
    private var errorLabel: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        backgroundColor = .systemBackground
        layer.cornerRadius = 12

        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true
        addSubview(loadingIndicator)

        errorLabel = UILabel()
        errorLabel.textColor = .systemRed
        errorLabel.font = .systemFont(ofSize: 14)
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 2
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.isHidden = true
        addSubview(errorLabel)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),

            loadingIndicator.centerXAnchor.constraint(equalTo: centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: centerYAnchor),

            errorLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            errorLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            errorLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    func setSuggestions(_ suggestions: [Suggestion]) {
        let items = suggestions.map { suggestion in
            SuggestionItem(text: suggestion.text, confidence: suggestion.confidence, tone: suggestion.tone)
        }
        updateSuggestions(items)
    }

    func updateSuggestions(_ suggestions: [SuggestionItem]) {
        // Clear existing suggestions
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        hideLoading()
        hideError()

        // Add new suggestion buttons
        for suggestion in suggestions.prefix(3) { // Limit to 3 suggestions to save space
            let button = createSuggestionButton(for: suggestion)
            stackView.addArrangedSubview(button)
        }
    }

    private func createSuggestionButton(for suggestion: SuggestionItem) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(suggestion.text, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.titleLabel?.numberOfLines = 2
        button.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        button.setTitleColor(.systemBlue, for: .normal)
        button.layer.cornerRadius = 8

        if #available(iOS 15.0, *) {
            var config = button.configuration ?? .plain()
            config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
            button.configuration = config
        } else {
            if #available(iOS 15.0, *) {
                var config = button.configuration ?? .plain()
                config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
                button.configuration = config
            } else {
                button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
            }
        }

        button.addTarget(self, action: #selector(suggestionTapped(_:)), for: .touchUpInside)

        return button
    }

    @objc private func suggestionTapped(_ sender: UIButton) {
        guard let text = sender.title(for: .normal) else { return }
        delegate?.didSelectSuggestion(text)

        // Provide haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

    func showLoading() {
        hideError()
        loadingIndicator.startAnimating()
        stackView.isHidden = true
    }

    private func hideLoading() {
        loadingIndicator.stopAnimating()
        stackView.isHidden = false
    }

    func showError(_ message: String) {
        hideLoading()
        errorLabel.text = message
        errorLabel.isHidden = false
        stackView.isHidden = true
    }

    private func hideError() {
        errorLabel.isHidden = true
        stackView.isHidden = false
    }

    func reduceQuality() {
        // Reduce visual quality to save memory
        stackView.arrangedSubviews.forEach { view in
            view.layer.shouldRasterize = false
            view.layer.contentsScale = 1.0
        }
    }
}

// MARK: - API Integration
extension KeyboardViewController {

    private func makeFlirtAPIRequest() {
        os_log("🚀 KEYBOARD API: Starting flirt API request", log: logger, type: .info)

        // Visual indicator that API is being called
        DispatchQueue.main.async { [weak self] in
            self?.textDocumentProxy.insertText("[Loading fresh suggestions...] ")
        }

        let url = URL(string: "http://localhost:3000/api/v1/flirts/generate_flirts")!
        let body: [String: Any] = [
            "screenshot_id": "keyboard-test-\(Date().timeIntervalSince1970)",
            "suggestion_type": "opener",
            "tone": "playful",
            "context": "Generate fresh conversation starters"
        ]

        makeAPIRequest(url: url, body: body)
    }

    private func makeAPIRequest(url: URL, body: [String: Any], retryCount: Int = 0) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "X-Keyboard-Extension")  // Bypass authentication
        request.timeoutInterval = 2.0  // 2 second timeout

        os_log("🔑 KEYBOARD API: Using X-Keyboard-Extension header for auth bypass", log: logger, type: .info)

        // No need for auth token with keyboard extension header
        // if let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt.shared"),
        //    let token = sharedDefaults.string(forKey: "auth_token") {
        //     request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        // }

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if error != nil && retryCount < 3 {
                // Retry with exponential backoff
                let delay = Double(retryCount + 1) * 0.5
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    self?.makeAPIRequest(url: url, body: body, retryCount: retryCount + 1)
                }
                return
            }

            // Process response or show error
            if let data = data {
                DispatchQueue.main.async {
                    self?.processAPIResponse(data)
                }
            } else {
                DispatchQueue.main.async {
                    self?.showError("Network unavailable. Please try again.")
                }
            }
        }.resume()
    }

    private func processAPIResponse(_ data: Data) {
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            os_log("API Response: %@", log: logger, type: .debug, String(data: data, encoding: .utf8) ?? "Unable to parse")

            // Handle both old and new API response formats
            var suggestions: [[String: Any]] = []

            if let success = json?["success"] as? Bool, success {
                // New API format with nested data
                if let responseData = json?["data"] as? [String: Any],
                   let dataSuggestions = responseData["suggestions"] as? [[String: Any]] {
                    suggestions = dataSuggestions
                }
                // Fallback format with direct suggestions array
                else if let directSuggestions = json?["suggestions"] as? [[String: Any]] {
                    suggestions = directSuggestions
                }
            }
            // Handle direct suggestions format (for fallback responses)
            else if let directSuggestions = json?["suggestions"] as? [[String: Any]] {
                suggestions = directSuggestions
            }

            if !suggestions.isEmpty {
                DispatchQueue.main.async {
                    self.displaySuggestions(suggestions)
                    self.cacheSuggestions(suggestions)
                    self.provideHapticFeedback(type: .success)
                }
            } else {
                DispatchQueue.main.async {
                    self.showError("No suggestions received")
                    self.provideHapticFeedback(type: .error)
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.showError("Invalid response format: \(error.localizedDescription)")
                self.provideHapticFeedback(type: .error)
            }
        }
    }

    private func makeAnalysisAPIRequest() {
        os_log("🔍 KEYBOARD API: Making conversation analysis request", log: logger, type: .info)

        // Visual indicator
        DispatchQueue.main.async { [weak self] in
            self?.textDocumentProxy.insertText("[Analyzing conversation...] ")
        }

        let url = URL(string: "http://localhost:3000/api/v1/flirts/generate_flirts")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "X-Keyboard-Extension")  // Bypass authentication

        os_log("🔑 KEYBOARD API: Using X-Keyboard-Extension header for auth bypass", log: logger, type: .info)

        // No auth needed with keyboard extension header

        let body: [String: Any] = [
            "screenshot_id": "analyze-test-\(Date().timeIntervalSince1970)",
            "tone": "analytical",
            "context": "conversation analysis",
            "suggestion_type": "response"
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            os_log("Failed to serialize request body: %@", log: logger, type: .error, error.localizedDescription)
            DispatchQueue.main.async {
                self.showError("Failed to prepare request")
                self.provideHapticFeedback(type: .error)
            }
            return
        }

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                os_log("API error: %@", log: logger, type: .error, error.localizedDescription)
                DispatchQueue.main.async {
                    self.showError("Network error: \(error.localizedDescription)")
                    self.provideHapticFeedback(type: .error)
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    self.showError("No data received")
                    self.provideHapticFeedback(type: .error)
                }
                return
            }

            DispatchQueue.main.async {
                self.processAPIResponse(data)
            }
        }

        task.resume()
    }

    private func displaySuggestions(_ suggestions: [[String: Any]]) {
        suggestionsView.isHidden = false
        view.setNeedsLayout()

        var displayItems: [SuggestionItem] = []
        for suggestion in suggestions {
            if let text = suggestion["text"] as? String,
               let confidence = suggestion["confidence"] as? Double {
                let item = SuggestionItem(
                    text: text,
                    confidence: confidence,
                    tone: suggestion["tone"] as? String ?? "casual"
                )
                displayItems.append(item)
            }
        }

        suggestionsView.updateSuggestions(displayItems)

        // Haptic feedback on success
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    private func showError(_ message: String) {
        // Show error message to user
        textDocumentProxy.insertText("Error: \(message)")
        os_log("API Error: %@", log: logger, type: .error, message)
    }
}

// MARK: - Caching
extension KeyboardViewController {

    private func cacheSuggestions(_ suggestions: [[String: Any]]) {
        if let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt.shared") {
            // Keep only last 10 suggestions
            var cache = sharedDefaults.array(forKey: "cached_suggestions") as? [[String: Any]] ?? []
            cache.append(contentsOf: suggestions)
            if cache.count > 10 {
                cache = Array(cache.suffix(10))
            }
            sharedDefaults.set(cache, forKey: "cached_suggestions")
            sharedDefaults.set(Date(), forKey: "cache_timestamp")
        }
    }

    private func loadCachedSuggestions() -> [[String: Any]]? {
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt.shared"),
              let cache = sharedDefaults.array(forKey: "cached_suggestions") as? [[String: Any]],
              let timestamp = sharedDefaults.object(forKey: "cache_timestamp") as? Date,
              Date().timeIntervalSince(timestamp) < 3600 else { // 1 hour cache
            return nil
        }
        return cache
    }
}

// MARK: - Haptic Feedback
extension KeyboardViewController {

    private func provideHapticFeedback(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    private func provideSelectionFeedback() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    private func provideSelectionFeedback() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}

// Voice synthesis request
extension KeyboardViewController {
    private func requestVoiceSynthesis(text: String, voiceId: String) {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.flirrt.shared") else { return }

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

// MARK: - Screenshot Analysis
extension KeyboardViewController: PHPhotoLibraryChangeObserver {

    private func setupScreenshotObserver() {
        PHPhotoLibrary.shared().register(self)
        checkForRecentScreenshot()
    }

    nonisolated func photoLibraryDidChange(_ changeInstance: PHChange) {
        // Check for new screenshots when library changes
        Task { @MainActor [weak self] in
            self?.checkForRecentScreenshot()
        }
    }

    private func checkForRecentScreenshot() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            guard status == .authorized || status == .limited else {
                os_log("Photo library access not authorized", log: self?.logger ?? OSLog.default, type: .info)
                return
            }

            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.fetchLimit = 1

            // Only get screenshots
            fetchOptions.predicate = NSPredicate(
                format: "mediaType = %d AND mediaSubtype = %d",
                PHAssetMediaType.image.rawValue,
                PHAssetMediaSubtype.photoScreenshot.rawValue
            )

            let screenshots = PHAsset.fetchAssets(with: fetchOptions)

            guard let latestScreenshot = screenshots.firstObject else { return }

            // Check if screenshot is recent (within last 60 seconds)
            let screenshotDate = latestScreenshot.creationDate ?? Date.distantPast
            let timeSinceScreenshot = Date().timeIntervalSince(screenshotDate)

            if timeSinceScreenshot < 60 {
                os_log("Recent screenshot detected, auto-analyzing", log: self?.logger ?? OSLog.default, type: .info)
                DispatchQueue.main.async {
                    self?.processScreenshot(latestScreenshot)
                }
            }
        }
    }

    private func processScreenshot(_ asset: PHAsset) {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = false

        manager.requestImageDataAndOrientation(for: asset, options: options) { [weak self] data, _, _, _ in
            guard let imageData = data else { return }
            self?.uploadScreenshotToBackend(imageData)
        }
    }

    private func uploadScreenshotToBackend(_ imageData: Data) {
        // Show loading
        DispatchQueue.main.async {
            self.suggestionsView.showLoading()
        }

        let url = URL(string: "http://localhost:3000/api/v1/analysis/analyze_screenshot")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10.0

        // Add auth token
        if let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt.shared"),
           let token = sharedDefaults.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Build multipart form data
        var body = Data()

        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"screenshot\"; filename=\"screenshot.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)

        // Add context
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"context\"\r\n\r\n".data(using: .utf8)!)
        body.append("dating_app_screenshot".data(using: .utf8)!)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                os_log("Screenshot upload error: %@", log: self.logger, type: .error, error.localizedDescription)
                DispatchQueue.main.async {
                    self.suggestionsView.showError("Upload failed: \(error.localizedDescription)")
                    self.provideHapticFeedback(type: .error)
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    self.suggestionsView.showError("No response received")
                    self.provideHapticFeedback(type: .error)
                }
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                if let screenshotId = json?["screenshot_id"] as? String {
                    os_log("Screenshot uploaded, ID: %@", log: self.logger, type: .info, screenshotId)
                    DispatchQueue.main.async {
                        self.generateFlirtsForScreenshot(screenshotId)
                    }
                } else {
                    throw NSError(domain: "AnalysisError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
                }
            } catch {
                os_log("Screenshot analysis parsing error: %@", log: self.logger, type: .error, error.localizedDescription)
                DispatchQueue.main.async {
                    self.suggestionsView.showError("Analysis failed")
                    self.provideHapticFeedback(type: .error)
                }
            }
        }.resume()
    }

    private func uploadScreenshotToBackendOriginal(_ imageData: Data) {
        // This is the original implementation that will be used once backend has screenshot endpoint
        let url = URL(string: "http://localhost:3000/api/v1/analyze_screenshot")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // Add auth token
        if let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt.shared"),
           let token = sharedDefaults.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            request.setValue("Bearer test-token", forHTTPHeaderField: "Authorization")
        }

        // Build multipart form data
        var body = Data()

        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"screenshot\"; filename=\"screenshot.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)

        // Add context
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"context\"\r\n\r\n".data(using: .utf8)!)
        body.append("dating_app_screenshot".data(using: .utf8)!)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let screenshotId = json["screenshot_id"] as? String {

                os_log("Screenshot uploaded, ID: %@", log: self.logger, type: .info, screenshotId)

                // Now generate flirts for this screenshot
                DispatchQueue.main.async {
                    self.generateFlirtsForScreenshot(screenshotId)
                }
            } else {
                os_log("Screenshot upload failed", log: self.logger, type: .error)
                DispatchQueue.main.async {
                    self.suggestionsView.showError("Analysis failed")
                }
            }
        }.resume()
    }

    private func generateFlirtsForScreenshot(_ screenshotId: String) {
        let url = URL(string: "http://localhost:3000/api/v1/flirts/generate_flirts")!

        let body: [String: Any] = [
            "screenshot_id": screenshotId,
            "suggestion_type": "response",
            "tone": "witty",
            "context": "Analyzed screenshot conversation"
        ]

        os_log("Generating flirts for screenshot: %@", log: logger, type: .info, screenshotId)
        makeAPIRequest(url: url, body: body)
    }
}

