import UIKit
import os.log

class KeyboardViewController: UIInputViewController {

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

        // Load opener suggestions from shared data
        loadOpenerSuggestions()
    }

    @objc private func analyzeTapped() {
        guard hasFullAccess else {
            showFullAccessRequired()
            return
        }

        // Trigger screenshot analysis
        requestScreenshotAnalysis()
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

    func setSuggestions(_ suggestions: [Suggestion]) {
        // Implementation
    }

    func showLoading() {
        // Show loading state
    }

    func reduceQuality() {
        // Reduce visual quality to save memory
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