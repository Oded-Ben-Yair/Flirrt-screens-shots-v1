import UIKit

class KeyboardViewController: UIInputViewController {

    private var heightConstraint: NSLayoutConstraint?
    private let memoryLimit: Int = 60 * 1024 * 1024 // 60MB limit

    private lazy var flirrtFreshButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Flirrt Fresh 💫", for: .normal)
        button.backgroundColor = .systemPink
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(flirrtFreshTapped), for: .touchUpInside)
        return button
    }()

    private lazy var analyzeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Let's Analyze It! 📸", for: .normal)
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

        setupUI()
        checkMemoryUsage()
        loadSharedData()
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

    private func checkMemoryUsage() {
        let memoryUsage = getMemoryUsage()
        if memoryUsage > memoryLimit {
            // Memory optimization needed
            clearCache()
            reduceFunctionality()
        }
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

        // Load from App Groups
        if let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt.ai.shared") {
            let userAuthenticated = sharedDefaults.bool(forKey: "user_authenticated")
            let voiceEnabled = sharedDefaults.bool(forKey: "voice_enabled")

            if !userAuthenticated {
                showAuthenticationRequired()
            }
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
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.flirrt.ai.shared") {
            let suggestionsURL = containerURL.appendingPathComponent("suggestions.json")

            if let data = try? Data(contentsOf: suggestionsURL),
               let suggestions = try? JSONDecoder().decode([Suggestion].self, from: data) {
                suggestionsView.setSuggestions(suggestions)
            }
        }
    }

    private func requestScreenshotAnalysis() {
        // Notify main app to process screenshot
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName("com.flirrt.analyze.request" as CFString),
            nil, nil, true
        )

        suggestionsView.showLoading()
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
    }

    private func reduceFunctionality() {
        // Reduce features to save memory
        suggestionsView.reduceQuality()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Release memory
        clearCache()
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