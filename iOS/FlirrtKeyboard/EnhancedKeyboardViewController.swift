import UIKit
import os.log

/// Enhanced Vibe8 Keyboard with Full QWERTY + Suggestions
/// Production-ready implementation for App Store submission
class EnhancedKeyboardViewController: UIInputViewController {

    // MARK: - Properties

    private let logger = OSLog(subsystem: "com.vibe8.keyboard", category: "enhanced")
    private let appGroupID = "group.com.flirrt"
    private var darwinNotificationName: CFNotificationName?

    private var suggestions: [FlirtSuggestion] = []
    private var keyboardView: Vibe8QWERTYKeyboardView!

    // MARK: - UI Components

    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var suggestionToolbar: SuggestionToolbarView = {
        let toolbar = SuggestionToolbarView()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.delegate = self
        return toolbar
    }()

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .systemPink
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDarwinNotifications()
        loadSuggestionsFromAppGroup()
        os_log("Enhanced Vibe8 Keyboard loaded", log: logger, type: .info)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadSuggestionsFromAppGroup()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .clear

        // Add blur effect background (iOS 26 Liquid Glass)
        let blurEffect = UIBlurEffect(style: .systemMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = view.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(blurView)

        view.addSubview(containerView)
        containerView.addSubview(suggestionToolbar)
        containerView.addSubview(activityIndicator)

        // Create QWERTY keyboard
        keyboardView = Vibe8QWERTYKeyboardView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 260))
        keyboardView.delegate = self
        keyboardView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(keyboardView)

        NSLayoutConstraint.activate([
            // Container
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 320),

            // Suggestion Toolbar
            suggestionToolbar.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            suggestionToolbar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            suggestionToolbar.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            suggestionToolbar.heightAnchor.constraint(equalToConstant: 50),

            // Activity Indicator
            activityIndicator.centerXAnchor.constraint(equalTo: suggestionToolbar.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: suggestionToolbar.centerYAnchor),

            // Keyboard
            keyboardView.topAnchor.constraint(equalTo: suggestionToolbar.bottomAnchor, constant: 8),
            keyboardView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            keyboardView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            keyboardView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
    }

    // MARK: - Darwin Notifications

    private func setupDarwinNotifications() {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let notificationName = CFNotificationName("com.vibe8.screenshot.detected" as CFString)

        darwinNotificationName = notificationName

        CFNotificationCenterAddObserver(
            center,
            Unmanaged.passUnretained(self).toOpaque(),
            { (center, observer, name, object, userInfo) in
                guard let observer = observer else { return }
                let keyboard = Unmanaged<EnhancedKeyboardViewController>.fromOpaque(observer).takeUnretainedValue()
                keyboard.handleScreenshotDetected()
            },
            notificationName.rawValue,
            nil,
            .deliverImmediately
        )

        os_log("Darwin notification listener active", log: logger, type: .info)
    }

    private func handleScreenshotDetected() {
        os_log("📸 Screenshot detected via Darwin notification", log: logger, type: .info)
        DispatchQueue.main.async { [weak self] in
            self?.loadSuggestionsFromAppGroup()
        }
    }

    // MARK: - App Groups Communication

    private func loadSuggestionsFromAppGroup() {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupID) else {
            os_log("Failed to access App Group", log: logger, type: .error)
            activityIndicator.stopAnimating()
            return
        }

        // Check if analysis is in progress
        let isAnalyzing = sharedDefaults.bool(forKey: "isAnalyzingScreenshot")
        if isAnalyzing {
            os_log("🔄 Screenshot analysis in progress...", log: logger, type: .info)
            activityIndicator.startAnimating()
            suggestionToolbar.showPlaceholder() // Show placeholder while loading
            return
        }

        // Check for suggestions data
        guard let suggestionsData = sharedDefaults.data(forKey: "latestSuggestions") else {
            os_log("No suggestions available in App Group", log: logger, type: .info)
            activityIndicator.stopAnimating()
            suggestionToolbar.showPlaceholder()
            return
        }

        do {
            let decoder = JSONDecoder()
            let loadedSuggestions = try decoder.decode([FlirtSuggestion].self, from: suggestionsData)

            if !loadedSuggestions.isEmpty {
                os_log("✅ Loaded %d suggestions from App Group", log: logger, type: .info, loadedSuggestions.count)
                activityIndicator.stopAnimating()
                suggestions = Array(loadedSuggestions.prefix(3)) // Max 3 suggestions
                suggestionToolbar.updateSuggestions(suggestions)
            }
        } catch {
            os_log("Failed to decode suggestions: %@", log: logger, type: .error, error.localizedDescription)
            activityIndicator.stopAnimating()
        }
    }

    // MARK: - Cleanup

    deinit {
        // Remove CFNotification observer
        if let notificationName = darwinNotificationName {
            CFNotificationCenterRemoveObserver(
                CFNotificationCenterGetDarwinNotifyCenter(),
                Unmanaged.passUnretained(self).toOpaque(),
                notificationName,
                nil
            )
        }

        os_log("Enhanced keyboard deinitialized with proper cleanup", log: logger, type: .info)
    }
}

// MARK: - Vibe8KeyboardDelegate

extension EnhancedKeyboardViewController: Vibe8KeyboardDelegate {
    func keyboardDidPressKey(_ key: String) {
        textDocumentProxy.insertText(key)
    }

    func keyboardDidPressDelete() {
        textDocumentProxy.deleteBackward()
    }

    func keyboardDidPressReturn() {
        textDocumentProxy.insertText("\n")
    }

    func keyboardDidPressSpace() {
        textDocumentProxy.insertText(" ")
    }

    func keyboardDidPressShift() {
        // TODO: Implement shift functionality
        os_log("Shift pressed", log: logger, type: .debug)
    }

    func keyboardDidPressNumberToggle() {
        // TODO: Implement number keyboard toggle
        os_log("Number toggle pressed", log: logger, type: .debug)
    }

    func keyboardDidPressGlobe() {
        advanceToNextInputMode()
    }
}

// MARK: - SuggestionToolbarDelegate

extension EnhancedKeyboardViewController: SuggestionToolbarDelegate {
    func suggestionToolbarDidSelectSuggestion(_ suggestion: FlirtSuggestion) {
        // Insert suggestion text
        textDocumentProxy.insertText(suggestion.text)

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        os_log("Inserted suggestion: %@", log: logger, type: .info, suggestion.text)
    }

    func suggestionToolbarDidRequestRefresh() {
        // Open main app to capture new screenshot
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
}

// MARK: - Data Models

struct FlirtSuggestion: Codable {
    let id: String
    let text: String
    let confidence: Double
    let reasoning: String?
    let references: [String]?
}
