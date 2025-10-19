import UIKit
import os.log
// CRITICAL FIX: Removed Photos import - keyboard extensions MUST NOT access Photo Library (App Store rejection risk)

/// Minimal Vibe8 Keyboard - October 2025
/// Auto-detects screenshots from Photos library and analyzes immediately
class KeyboardViewController: UIInputViewController {

    // MARK: - Properties
    private let logger = OSLog(subsystem: "com.vibe8.keyboard", category: "minimal")
    private let appGroupID = AppConstants.appGroupIdentifier

    private var isAnalyzing = false
    private var suggestions: [FlirtSuggestion] = []

    // CRITICAL FIX: Store notification name for cleanup
    private var darwinNotificationName: CFNotificationName?

    // MARK: - UI Components
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var logoLabel: UILabel = {
        let label = UILabel()
        label.text = "🎯 Vibe8"
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

    // MARK: - Phase 3: Progress Indicator UI
    private lazy var progressContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    private lazy var progressLabel: UILabel = {
        let label = UILabel()
        label.text = "Context: 1/3 screenshots"
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var progressBar: UIProgressView = {
        let progress = UIProgressView(progressViewStyle: .default)
        progress.progressTintColor = .systemPink
        progress.trackTintColor = .systemGray5
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.progress = 0.33
        return progress
    }()

    private lazy var contextMessageLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = .systemFont(ofSize: 11, weight: .regular)
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
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

    // ✅ ADDED: Keyboard toggle button (globe icon) to switch keyboards
    private lazy var nextKeyboardButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "globe"), for: .normal)
        button.tintColor = .label
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        button.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        return button
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDarwinNotifications()
        loadSuggestionsFromAppGroup()
        os_log("Minimal Vibe8 Keyboard loaded (App Group mode)", log: logger, type: .info)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Load latest suggestions from App Group
        loadSuggestionsFromAppGroup()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Keyboard is hidden
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
        // ✅ ADDED: Keyboard toggle button
        containerView.addSubview(nextKeyboardButton)

        // Phase 3: Progress indicator UI
        containerView.addSubview(progressContainerView)
        progressContainerView.addSubview(progressLabel)
        progressContainerView.addSubview(progressBar)
        containerView.addSubview(contextMessageLabel)

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
            suggestionsStack.bottomAnchor.constraint(lessThanOrEqualTo: containerView.bottomAnchor, constant: -12),

            // ✅ ADDED: Next keyboard button (bottom-left corner)
            nextKeyboardButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            nextKeyboardButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12),
            nextKeyboardButton.widthAnchor.constraint(equalToConstant: 44),
            nextKeyboardButton.heightAnchor.constraint(equalToConstant: 44),

            // Phase 3: Progress indicator constraints
            progressContainerView.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 12),
            progressContainerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            progressContainerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            progressContainerView.heightAnchor.constraint(equalToConstant: 60),

            progressLabel.topAnchor.constraint(equalTo: progressContainerView.topAnchor, constant: 8),
            progressLabel.leadingAnchor.constraint(equalTo: progressContainerView.leadingAnchor, constant: 12),
            progressLabel.trailingAnchor.constraint(equalTo: progressContainerView.trailingAnchor, constant: -12),

            progressBar.topAnchor.constraint(equalTo: progressLabel.bottomAnchor, constant: 8),
            progressBar.leadingAnchor.constraint(equalTo: progressContainerView.leadingAnchor, constant: 12),
            progressBar.trailingAnchor.constraint(equalTo: progressContainerView.trailingAnchor, constant: -12),
            progressBar.heightAnchor.constraint(equalToConstant: 4),

            contextMessageLabel.topAnchor.constraint(equalTo: progressContainerView.bottomAnchor, constant: 8),
            contextMessageLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            contextMessageLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20)
        ])
    }

    // MARK: - Darwin Notifications
    private func setupDarwinNotifications() {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let notificationName = CFNotificationName("com.vibe8.screenshot.detected" as CFString)

        // CRITICAL FIX: Store notification name for cleanup in deinit
        self.darwinNotificationName = notificationName

        CFNotificationCenterAddObserver(
            center,
            Unmanaged.passUnretained(self).toOpaque(),
            { (center, observer, name, object, userInfo) in
                guard let observer = observer else { return }
                let keyboard = Unmanaged<KeyboardViewController>.fromOpaque(observer).takeUnretainedValue()
                keyboard.handleScreenshotDetected()
            },
            notificationName.rawValue,
            nil,
            .deliverImmediately
        )

        os_log("Darwin notification listener active", log: logger, type: .info)
    }

    // MARK: - Screenshot Detection (via Darwin Notifications from Main App)
    private func handleScreenshotDetected() {
        os_log("📸 Screenshot detected via Darwin notification!", log: logger, type: .info)
        DispatchQueue.main.async { [weak self] in
            self?.loadSuggestionsFromAppGroup()
        }
    }

    // MARK: - App Groups Communication
    /// Load suggestions from App Groups (shared by main app after screenshot analysis)
    private func loadSuggestionsFromAppGroup() {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupID) else {
            showError("App Groups not configured")
            return
        }

        // Phase 3: Try to load full response with session metadata
        if let responseData = sharedDefaults.data(forKey: "latestResponse") {
            do {
                let decoder = JSONDecoder()
                let response = try decoder.decode(KeyboardResponseData.self, from: responseData)

                if !response.suggestions.isEmpty {
                    os_log("✅ Loaded %d suggestions with session metadata from App Group", log: logger, type: .info, response.suggestions.count)
                    showSuggestions(response.suggestions, sessionMetadata: response.session)
                    return
                }
            } catch {
                os_log("Failed to decode response with metadata: %@", log: logger, type: .error, error.localizedDescription)
            }
        }

        // Fallback: Check if suggestions are available (legacy format)
        guard let suggestionsData = sharedDefaults.data(forKey: "latestSuggestions") else {
            // No suggestions yet - show instruction
            instructionLabel.text = "📸 Open Vibe8 app and capture a screenshot"
            os_log("No suggestions available in App Group", log: logger, type: .info)
            return
        }

        // Decode suggestions (legacy)
        do {
            let decoder = JSONDecoder()
            let loadedSuggestions = try decoder.decode([FlirtSuggestion].self, from: suggestionsData)

            if !loadedSuggestions.isEmpty {
                os_log("✅ Loaded %d suggestions from App Group (legacy)", log: logger, type: .info, loadedSuggestions.count)
                showSuggestions(loadedSuggestions, sessionMetadata: nil)
            }
        } catch {
            os_log("Failed to decode suggestions: %@", log: logger, type: .error, error.localizedDescription)
        }
    }

    // MARK: - UI Refresh
    @objc private func refreshSuggestions() {
        // Trigger main app to re-analyze screenshot
        os_log("Refresh requested - opening main app", log: logger, type: .info)
        // Deep link to main app
        if let url = URL(string: "vibe8://analyze-screenshot") {
            openURL(url)
        }
    }

    private func openURL(_ url: URL) {
        var responder: UIResponder? = self
        while responder != nil {
            if let application = responder as? UIApplication {
                application.open(url)
                return
            }
            responder = responder?.next
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

    private func showSuggestions(_ newSuggestions: [FlirtSuggestion], sessionMetadata: SessionMetadata?) {
        suggestions = newSuggestions

        instructionLabel.isHidden = true
        statusLabel.isHidden = false
        statusLabel.text = "Tap a suggestion to use it:"
        statusLabel.textColor = .systemGreen
        activityIndicator.stopAnimating()

        // Phase 3: Display progress indicator if session metadata available
        if let session = sessionMetadata {
            updateProgressIndicator(session: session)
        } else {
            progressContainerView.isHidden = true
            contextMessageLabel.isHidden = true
        }

        // Clear existing suggestions
        suggestionsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Add up to 5 suggestions
        for (index, suggestion) in newSuggestions.prefix(5).enumerated() {
            let button = createSuggestionButton(suggestion: suggestion, index: index)
            suggestionsStack.addArrangedSubview(button)
        }

        suggestionsStack.isHidden = false
    }

    // Phase 3: Update progress indicator based on session metadata
    private func updateProgressIndicator(session: SessionMetadata) {
        let count = session.screenshotCount
        let progress = Float(count) / 3.0

        progressLabel.text = "Context: \(count)/3 screenshots"
        progressBar.progress = min(progress, 1.0)

        // Color progression: pink -> green as context improves
        if count >= 3 {
            progressBar.progressTintColor = .systemGreen
            progressLabel.textColor = .systemGreen
        } else if count >= 2 {
            progressBar.progressTintColor = .systemOrange
            progressLabel.textColor = .systemOrange
        } else {
            progressBar.progressTintColor = .systemPink
            progressLabel.textColor = .secondaryLabel
        }

        progressContainerView.isHidden = false

        // Show context request message if more context needed
        if session.needsMoreContext, let message = session.contextMessage {
            contextMessageLabel.text = message
            contextMessageLabel.isHidden = false
        } else if let unlockMessage = session.unlockMessage {
            contextMessageLabel.text = unlockMessage
            contextMessageLabel.textColor = .systemGreen
            contextMessageLabel.isHidden = false
        } else {
            contextMessageLabel.isHidden = true
        }
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
        os_log("Action button tapped - opening main app", log: logger, type: .info)

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Open main app to capture screenshot
        if let url = URL(string: "vibe8://analyze-screenshot") {
            openURL(url)
        }

        // Update instruction
        instructionLabel.text = "📸 Take a screenshot in Vibe8 app"
    }

    // ✅ ADDED: Handler for keyboard toggle button
    @objc override func handleInputModeList(from view: UIView, with event: UIEvent) {
        advanceToNextInputMode()
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
        // CRITICAL FIX: Remove CFNotification observer to prevent memory leak
        if let notificationName = darwinNotificationName {
            CFNotificationCenterRemoveObserver(
                CFNotificationCenterGetDarwinNotifyCenter(),
                Unmanaged.passUnretained(self).toOpaque(),
                notificationName,
                nil
            )
        }

        os_log("KeyboardViewController deinitialized with proper cleanup", log: logger, type: .info)
    }
}

// MARK: - Data Models
struct FlirtSuggestion: Codable {
    let id: String
    let text: String
    let confidence: Double
    let reasoning: String?
    let references: [String]?
}

// Phase 3: Session metadata for progress tracking
struct SessionMetadata: Codable {
    let screenshotCount: Int
    let needsMoreContext: Bool
    let contextMessage: String?
    let contextScore: Double?
    let unlockMessage: String?
}

struct KeyboardResponseData: Codable {
    let suggestions: [FlirtSuggestion]
    let session: SessionMetadata?
}
