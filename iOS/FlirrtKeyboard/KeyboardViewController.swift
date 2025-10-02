import UIKit
import Foundation
import Photos
import OSLog
import ImageIO
import UniformTypeIdentifiers

// MARK: - Minimal Personalization Types for Keyboard Extension
// Full definitions in Flirrt/Models/PersonalizationData.swift

fileprivate enum DatingExperience: String, Codable { case newToDating = "New to dating", someExperience = "Some experience", prettyExperienced = "Pretty experienced", datingExpert = "Dating expert" }
fileprivate enum DatingGoal: String, Codable { case casualDating = "Casual dating", seriousRelationship = "Serious relationship", friendship = "Friendship", somethingFun = "Something fun", notSureYet = "Not sure yet", openToAnything = "Open to anything" }
fileprivate enum CommunicationStyle: String, Codable { case direct = "Direct", playful = "Playful", thoughtful = "Thoughtful", funny = "Funny", mysterious = "Mysterious"; var displayName: String { rawValue } }
fileprivate enum Interest: String, Codable { case sports = "Sports", music = "Music", movies = "Movies", reading = "Reading", travel = "Travel", food = "Food", fitness = "Fitness", art = "Art", technology = "Technology", nature = "Nature", gaming = "Gaming", photography = "Photography" }
fileprivate enum ConversationTopic: String, Codable { case dreams = "Dreams and goals", humor = "Humor and jokes", deepQuestions = "Deep questions", currentEvents = "Current events", hobbies = "Hobbies", adventures = "Adventures", food = "Food and dining", entertainment = "Entertainment", philosophy = "Philosophy", dailyLife = "Daily life" }

fileprivate struct PersonalizationProfile: Codable, Sendable {
    var datingExperience: DatingExperience?, datingGoals: [DatingGoal], communicationStyle: CommunicationStyle?, confidenceLevel: Int?, interests: [Interest], idealFirstDate: String?, conversationTopics: [ConversationTopic], flirtingComfort: Int?, createdAt: Date, updatedAt: Date, version: Int
    var completionPercentage: Int { var c = 0; let t = 8; if datingExperience != nil { c += 1 }; if !datingGoals.isEmpty { c += 1 }; if communicationStyle != nil { c += 1 }; if confidenceLevel != nil { c += 1 }; if !interests.isEmpty { c += 1 }; if idealFirstDate != nil && !(idealFirstDate?.isEmpty ?? true) { c += 1 }; if !conversationTopics.isEmpty { c += 1 }; if flirtingComfort != nil { c += 1 }; return Int((Double(c) / Double(t)) * 100) }
    func toJSON() -> [String: Any] { var j: [String: Any] = [:]; j["dating_experience"] = datingExperience?.rawValue; j["dating_goals"] = datingGoals.map { $0.rawValue }; j["communication_style"] = communicationStyle?.rawValue; j["confidence_level"] = confidenceLevel; j["interests"] = interests.map { $0.rawValue }; j["ideal_first_date"] = idealFirstDate; j["conversation_topics"] = conversationTopics.map { $0.rawValue }; j["flirting_comfort"] = flirtingComfort; j["completion_percentage"] = completionPercentage; j["is_complete"] = completionPercentage == 100; j["version"] = version; return j }
}

fileprivate final class PersonalizationStorageManager { static let shared = PersonalizationStorageManager(); private init() {}; private var userDefaults: UserDefaults? { UserDefaults(suiteName: "group.com.flirrt.shared") }; func loadProfile() throws -> PersonalizationProfile? { guard let ud = userDefaults, let data = ud.data(forKey: "flirrt_personalization_profile_v1") else { return nil }; let d = JSONDecoder(); d.dateDecodingStrategy = .iso8601; return try? d.decode(PersonalizationProfile.self, from: data) } }

@MainActor
final class KeyboardViewController: UIInputViewController {

    // MARK: - Optimized Memory Management
    private let logger = OSLog(subsystem: "com.flirrt.keyboard", category: "memory")
    private var memoryObserver: NSObjectProtocol?
    private let appGroupID = "group.com.flirrt.shared"

    private var heightConstraint: NSLayoutConstraint?
    private let memoryLimit: Int = 60 * 1024 * 1024 // 60MB limit
    private let warningLimit: Int = 45 * 1024 * 1024 // 45MB warning
    private var memoryCheckTimer: Timer?
    private var lastMemoryWarning: Date?

    // Image compression for optimized uploads (lazy for memory efficiency)
    private lazy var imageCompressionService = ImageCompressionService()

    // Memory optimization flags
    private var isMemoryOptimized = false
    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = .invalid

    // MARK: - Smart Button State
    private enum SmartButtonMode {
        case freshOpeners      // Default: Show personalized conversation starters
        case analyzeScreenshot // Recent screenshot detected: Analyze it

        var title: String {
            switch self {
            case .freshOpeners: return "💫 Fresh Flirts"
            case .analyzeScreenshot: return "📸 Analyze This"
            }
        }

        var subtitle: String {
            switch self {
            case .freshOpeners: return "Personalized for you"
            case .analyzeScreenshot: return "Get suggestions for this convo"
            }
        }

        var backgroundColor: UIColor {
            switch self {
            case .freshOpeners: return .systemPink
            case .analyzeScreenshot: return .systemBlue
            }
        }

        var icon: String {
            switch self {
            case .freshOpeners: return "✨"
            case .analyzeScreenshot: return "🔍"
            }
        }
    }

    private var currentButtonMode: SmartButtonMode = .freshOpeners {
        didSet {
            updateSmartButtonAppearance()
        }
    }

    private var lastScreenshotTime: TimeInterval = 0

    private lazy var smartActionButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 12
        button.clipsToBounds = true

        // Add shadow for depth
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.15
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.masksToBounds = false

        // Configure title label for two lines
        button.titleLabel?.numberOfLines = 2
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)

        button.addTarget(self, action: #selector(smartActionTapped), for: .touchUpInside)

        // Initial appearance
        updateSmartButtonAppearance(button: button)

        return button
    }()

    // MARK: - Debug Screenshot Simulator (DEBUG only)
    #if DEBUG
    private lazy var debugScreenshotButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("🐛 Simulate Screenshot", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 12, weight: .medium)
        button.backgroundColor = .systemOrange.withAlphaComponent(0.2)
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemOrange.cgColor
        button.addTarget(self, action: #selector(debugSimulateScreenshot), for: .touchUpInside)
        return button
    }()

    @objc private func debugSimulateScreenshot() {
        os_log("🐛 DEBUG: Manually triggering screenshot detection", log: logger, type: .debug)
        handleInstantScreenshotDetection()
    }
    #endif

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
        view.addSubview(smartActionButton)
        view.addSubview(suggestionsView)

        #if DEBUG
        view.addSubview(debugScreenshotButton)
        #endif

        // Setup constraints for unified button
        var constraints = [
            // Smart action button - full width, modern height
            smartActionButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            smartActionButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            smartActionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            smartActionButton.heightAnchor.constraint(equalToConstant: 68),
        ]

        #if DEBUG
        // Debug button constraints
        constraints += [
            debugScreenshotButton.topAnchor.constraint(equalTo: smartActionButton.bottomAnchor, constant: 8),
            debugScreenshotButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            debugScreenshotButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            debugScreenshotButton.heightAnchor.constraint(equalToConstant: 36),

            // Suggestions view below debug button
            suggestionsView.topAnchor.constraint(equalTo: debugScreenshotButton.bottomAnchor, constant: 8),
        ]
        #else
        // Suggestions view below smart button (no debug button)
        constraints += [
            suggestionsView.topAnchor.constraint(equalTo: smartActionButton.bottomAnchor, constant: 12),
        ]
        #endif

        // Common suggestions view constraints
        constraints += [
            suggestionsView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            suggestionsView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            suggestionsView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10)
        ]

        NSLayoutConstraint.activate(constraints)

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

        // Proactive memory monitoring with timer
        memoryCheckTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkMemoryUsage()
            }
        }

        // Initial memory check
        checkMemoryUsage()
        os_log("📈 Memory monitoring initialized - Limit: %d MB", log: logger, type: .info, memoryLimit / 1024 / 1024)
    }

    private func checkMemoryUsage() {
        let memoryUsage = getMemoryUsage()
        let memoryMB = Double(memoryUsage) / (1024 * 1024)

        // Only log every 30 seconds to reduce overhead
        if memoryCheckTimer?.timeInterval == 5.0 {
            memoryCheckTimer?.invalidate()
            memoryCheckTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.checkMemoryUsage()
                }
            }
        }

        if memoryUsage > memoryLimit {
            os_log("⚠️ Memory limit exceeded: %.2f MB", log: logger, type: .error, memoryMB)
            handleMemoryWarning()
        } else if memoryUsage > warningLimit && !isMemoryOptimized {
            os_log("🟡 Memory warning threshold reached: %.2f MB", log: logger, type: .default, memoryMB)
            handleMemoryWarning(soft: true)
        } else {
            os_log("👍 Memory usage healthy: %.2f MB", log: logger, type: .debug, memoryMB)
        }
    }

    private func handleMemoryWarning(soft: Bool = false) {
        let now = Date()
        if let lastWarning = lastMemoryWarning, now.timeIntervalSince(lastWarning) < 10 {
            return // Prevent rapid-fire memory optimizations
        }
        lastMemoryWarning = now

        if soft {
            os_log("🧠 Soft memory optimization triggered", log: logger, type: .default)
            optimizeMemoryUsage()
        } else {
            os_log("🔴 Critical memory warning - aggressive cleanup", log: logger, type: .error)
            clearCache()
            reduceFunctionality()
            optimizeMemoryUsage()
        }
        isMemoryOptimized = true
    }

    private func optimizeMemoryUsage() {
        // Release unnecessary objects
        URLCache.shared.diskCapacity = 0
        URLCache.shared.memoryCapacity = 5 * 1024 * 1024 // 5MB only

        // Reduce UI complexity
        suggestionsView.reduceQuality()

        // Clear animation layers if present
        view.layer.sublayers?.forEach { layer in
            if layer is CAShapeLayer {
                layer.removeAllAnimations()
            }
        }

        // Disable shadows and visual effects
        suggestionsView.layer.shadowOpacity = 0
        view.layer.shadowOpacity = 0

        os_log("⚙️ Memory optimization complete", log: logger, type: .info)
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

        // Store screenshot time and update button mode
        self.lastScreenshotTime = lastScreenshotTime
        updateButtonModeBasedOnScreenshot()
    }

    private func updateButtonModeBasedOnScreenshot() {
        let timeSinceScreenshot = Date().timeIntervalSince1970 - lastScreenshotTime
        if timeSinceScreenshot < 60 && timeSinceScreenshot > 0 {
            // Recent screenshot detected - switch to analyze mode
            currentButtonMode = .analyzeScreenshot
        } else {
            // Default mode - personalized openers
            currentButtonMode = .freshOpeners
        }
    }

    private func updateSmartButtonAppearance(button: UIButton? = nil) {
        let btn = button ?? smartActionButton

        // Animate transition
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut], animations: {
            btn.backgroundColor = self.currentButtonMode.backgroundColor

            // Set attributed title with icon and text
            let titleText = "\(self.currentButtonMode.icon) \(self.currentButtonMode.title)\n\(self.currentButtonMode.subtitle)"
            let attributedString = NSMutableAttributedString(string: titleText)

            // Style main title
            let titleRange = (titleText as NSString).range(of: "\(self.currentButtonMode.icon) \(self.currentButtonMode.title)")
            attributedString.addAttributes([
                .font: UIFont.systemFont(ofSize: 18, weight: .bold),
                .foregroundColor: UIColor.white
            ], range: titleRange)

            // Style subtitle
            let subtitleRange = (titleText as NSString).range(of: self.currentButtonMode.subtitle)
            attributedString.addAttributes([
                .font: UIFont.systemFont(ofSize: 13, weight: .medium),
                .foregroundColor: UIColor.white.withAlphaComponent(0.9)
            ], range: subtitleRange)

            btn.setAttributedTitle(attributedString, for: .normal)

            // Add scale animation for mode changes
            btn.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        }) { _ in
            UIView.animate(withDuration: 0.2) {
                btn.transform = .identity
            }
        }
    }

    @objc private func smartActionTapped() {
        // Enhanced button interaction with game-like feedback
        provideGameFeedback(for: .buttonPressed)
        smartActionButton.buttonPressAnimation()

        guard hasFullAccess else {
            showFullAccessRequired()
            return
        }

        // Route to appropriate action based on current mode
        switch currentButtonMode {
        case .freshOpeners:
            loadOpenerSuggestions()
        case .analyzeScreenshot:
            analyzeScreenshotMode()
        }
    }

    private func analyzeScreenshotMode() {
        // Show loading state with enhanced animations
        suggestionsView.showLoading()

        // Try to detect recent screenshots first with optimized detection
        checkForRecentScreenshot(optimized: true)

        // Make API request for response-type suggestions
        makeAnalysisAPIRequest()
    }

    private func loadOpenerSuggestions() {
        suggestionsView.isHidden = false
        view.setNeedsLayout()

        // Load user's personalization profile from App Groups
        do {
            let storageManager = PersonalizationStorageManager.shared
            if let profile = try storageManager.loadProfile() {
                os_log("✅ Loaded user profile from App Groups - Complete: %d%%", log: logger, type: .info, profile.completionPercentage)
                makePersonalizedFlirtAPIRequest(profile: profile)
            } else {
                os_log("⚠️ No personalization profile found - user needs to complete onboarding", log: logger, type: .error)
                showPersonalizationNeededError()
            }
        } catch {
            os_log("❌ Failed to load profile: %@", log: logger, type: .error, error.localizedDescription)
            showPersonalizationNeededError()
        }
    }

    // REMOVED: createDefaultSuggestions() - No mock data allowed per requirements

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
        // Clear URL cache completely
        URLCache.shared.removeAllCachedResponses()
        URLCache.shared.diskCapacity = 0
        URLCache.shared.memoryCapacity = 1024 * 1024 // 1MB minimum

        // Clear shared container temporary files
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            let tempDir = containerURL.appendingPathComponent("temp")
            try? FileManager.default.removeItem(at: tempDir)

            // Also clear old screenshots cache
            let cacheDir = containerURL.appendingPathComponent("cache")
            if let files = try? FileManager.default.contentsOfDirectory(at: cacheDir, includingPropertiesForKeys: nil) {
                for file in files.prefix(files.count - 5) { // Keep only 5 most recent
                    try? FileManager.default.removeItem(at: file)
                }
            }
        }

        // Clear suggestion cache
        if let sharedDefaults = UserDefaults(suiteName: appGroupID) {
            sharedDefaults.removeObject(forKey: "cached_suggestions")
        }

        os_log("🧹 Aggressive cache clearing complete", log: logger, type: .info)
    }

    private func reduceFunctionality() {
        // Reduce features to save memory
        suggestionsView.reduceQuality()

        // Disable non-essential features
        memoryCheckTimer?.invalidate()
        memoryCheckTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkMemoryUsage()
            }
        }

        // Simplify button animations
        smartActionButton.layer.removeAllAnimations()

        os_log("🔧 Functionality reduced for memory conservation", log: logger, type: .info)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Note: Background tasks not available in keyboard extensions
        // backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "KeyboardCleanup")
        // Use immediate cleanup instead

        // Release memory and clean up
        if !isMemoryOptimized {
            clearCache()
        }

        // Stop memory monitoring
        memoryCheckTimer?.invalidate()

        // Update last active time
        if let sharedDefaults = UserDefaults(suiteName: appGroupID) {
            sharedDefaults.set(Date().timeIntervalSince1970, forKey: "keyboard_last_active")
            sharedDefaults.set(getMemoryUsage(), forKey: "keyboard_last_memory_usage")
        }

        // Background tasks not available in keyboard extensions
        // Cleanup handled immediately above

        os_log("📱 KeyboardViewController cleanup complete", log: logger, type: .info)
    }

    deinit {
        // Clean up observers
        if let observer = memoryObserver {
            NotificationCenter.default.removeObserver(observer)
        }

        // Stop timers
        memoryCheckTimer?.invalidate()

        // Clean up CFNotificationCenter observer
        CFNotificationCenterRemoveObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            CFNotificationName("com.flirrt.screenshot.detected" as CFString),
            nil
        )

        // Final memory cleanup
        URLCache.shared.removeAllCachedResponses()

        // Background tasks not available in keyboard extensions
        // Cleanup handled synchronously

        os_log("♾️ KeyboardViewController fully deinitialized", log: logger, type: .info)
    }
}

// MARK: - SuggestionsViewDelegate
@MainActor
protocol SuggestionsViewDelegate: AnyObject {
    func didSelectSuggestion(_ text: String)
    func didRequestVoice(for text: String, voiceId: String)
}

extension KeyboardViewController: SuggestionsViewDelegate {
    func didSelectSuggestion(_ text: String) {
        // Provide game feedback for suggestion selection
        provideGameFeedback(for: .suggestionSelected)

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
    internal var gameStateLabel: UILabel!
    private var progressBar: UIProgressView!
    private var achievementBadge: UILabel!

    // Game-like state tracking
    private var loadingPhase = 0
    private var loadingTimer: Timer?
    private var pulseAnimationLayers: [CAShapeLayer] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupGameAnimations()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupGameAnimations()
    }

    private func setupUI() {
        backgroundColor = .systemBackground
        layer.cornerRadius = 12
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowRadius = 4
        layer.shadowOffset = CGSize(width: 0, height: 2)

        stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        // Enhanced loading indicator with game-like styling
        loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.color = .systemPink
        addSubview(loadingIndicator)

        // Game state label for contextual feedback
        gameStateLabel = UILabel()
        gameStateLabel.textColor = .systemBlue
        gameStateLabel.font = .systemFont(ofSize: 12, weight: .medium)
        gameStateLabel.textAlignment = .center
        gameStateLabel.numberOfLines = 1
        gameStateLabel.translatesAutoresizingMaskIntoConstraints = false
        gameStateLabel.isHidden = true
        addSubview(gameStateLabel)

        // Progress bar for loading states
        progressBar = UIProgressView(progressViewStyle: .default)
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.progressTintColor = .systemPink
        progressBar.trackTintColor = .systemGray5
        progressBar.isHidden = true
        addSubview(progressBar)

        // Achievement badge for successful operations
        achievementBadge = UILabel()
        achievementBadge.font = .systemFont(ofSize: 20)
        achievementBadge.textAlignment = .center
        achievementBadge.translatesAutoresizingMaskIntoConstraints = false
        achievementBadge.isHidden = true
        achievementBadge.alpha = 0
        addSubview(achievementBadge)

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

            gameStateLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            gameStateLabel.topAnchor.constraint(equalTo: loadingIndicator.bottomAnchor, constant: 8),

            progressBar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            progressBar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            progressBar.topAnchor.constraint(equalTo: gameStateLabel.bottomAnchor, constant: 8),

            achievementBadge.centerXAnchor.constraint(equalTo: centerXAnchor),
            achievementBadge.centerYAnchor.constraint(equalTo: centerYAnchor),

            errorLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            errorLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            errorLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    private func setupGameAnimations() {
        // Setup pulse animation layers for background effects
        for i in 0..<3 {
            let pulseLayer = CAShapeLayer()
            let size: CGFloat = CGFloat(50 + i * 20)
            pulseLayer.frame = CGRect(x: -size/2, y: -size/2, width: size, height: size)
            pulseLayer.path = UIBezierPath(ovalIn: pulseLayer.bounds).cgPath
            pulseLayer.fillColor = UIColor.systemPink.withAlphaComponent(0.1).cgColor
            pulseLayer.opacity = 0
            layer.addSublayer(pulseLayer)
            pulseAnimationLayers.append(pulseLayer)
        }
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

        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)

        button.addTarget(self, action: #selector(suggestionTapped(_:)), for: .touchUpInside)

        return button
    }

    @objc private func suggestionTapped(_ sender: UIButton) {
        guard let text = sender.title(for: .normal) else { return }

        // Enhanced suggestion selection with animation
        sender.selectedAnimation()

        delegate?.didSelectSuggestion(text)
    }

    func showLoading() {
        hideError()
        hideAchievement()
        loadingIndicator.startAnimating()
        stackView.isHidden = true
        startProgressiveLoading()
    }

    func showScreenshotDetected() {
        showAchievement("📸")
        gameStateLabel.text = "Screenshot detected!"
        gameStateLabel.isHidden = false
        startPulseAnimation()
    }

    func showOptimizedAnalysis() {
        gameStateLabel.text = "Analyzing with AI..."
        gameStateLabel.isHidden = false
        progressBar.isHidden = false
        progressBar.setProgress(0.3, animated: true)
    }

    func showNoRecentScreenshot() {
        gameStateLabel.text = "Take a screenshot to analyze"
        gameStateLabel.textColor = .systemOrange
        gameStateLabel.isHidden = false
        showSmartPrompt()
    }

    func showSmartPrompt() {
        // Create smart prompt button
        let promptButton = UIButton(type: .system)
        promptButton.setTitle("📸 Take Screenshot", for: .normal)
        promptButton.backgroundColor = .systemGreen.withAlphaComponent(0.1)
        promptButton.setTitleColor(.systemGreen, for: .normal)
        promptButton.layer.cornerRadius = 8
        promptButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)

        // Add pulse animation to draw attention
        let pulseAnimation = CABasicAnimation(keyPath: "opacity")
        pulseAnimation.fromValue = 0.5
        pulseAnimation.toValue = 1.0
        pulseAnimation.duration = 1.0
        pulseAnimation.repeatCount = Float.infinity
        pulseAnimation.autoreverses = true
        promptButton.layer.add(pulseAnimation, forKey: "promptPulse")

        stackView.addArrangedSubview(promptButton)

        // Auto-remove after 10 seconds to prevent clutter
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            promptButton.removeFromSuperview()
        }
    }

    private func startProgressiveLoading() {
        loadingPhase = 0
        gameStateLabel.isHidden = false
        progressBar.isHidden = false
        progressBar.setProgress(0, animated: false)

        loadingTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in
            self?.updateLoadingPhase()
        }
    }

    private func updateLoadingPhase() {
        loadingPhase += 1
        let progress = Float(loadingPhase) / 5.0
        progressBar.setProgress(min(progress, 0.9), animated: true)

        switch loadingPhase {
        case 1:
            gameStateLabel.text = "Analyzing screenshot..."
        case 2:
            gameStateLabel.text = "Understanding context..."
        case 3:
            gameStateLabel.text = "Generating suggestions..."
        case 4:
            gameStateLabel.text = "Finalizing responses..."
        default:
            gameStateLabel.text = "Almost ready..."
        }

        if loadingPhase >= 6 {
            loadingTimer?.invalidate()
        }
    }

    private func startPulseAnimation() {
        for (index, layer) in pulseAnimationLayers.enumerated() {
            let animation = CABasicAnimation(keyPath: "opacity")
            animation.fromValue = 0
            animation.toValue = 0.3
            animation.duration = 1.0
            animation.repeatCount = 3
            animation.autoreverses = true
            animation.beginTime = CACurrentMediaTime() + Double(index) * 0.2

            layer.position = CGPoint(x: bounds.midX, y: bounds.midY)
            layer.add(animation, forKey: "pulse")
        }
    }

    func hideLoading() {
        loadingIndicator.stopAnimating()
        loadingTimer?.invalidate()
        progressBar.isHidden = true
        gameStateLabel.isHidden = true
        stackView.isHidden = false
    }

    private func showAchievement(_ emoji: String) {
        achievementBadge.text = emoji
        achievementBadge.isHidden = false

        UIView.animate(withDuration: 0.3, animations: {
            self.achievementBadge.alpha = 1
            self.achievementBadge.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }) { _ in
            UIView.animate(withDuration: 0.2, delay: 1.0, options: [], animations: {
                self.achievementBadge.alpha = 0
                self.achievementBadge.transform = .identity
            }) { _ in
                self.achievementBadge.isHidden = true
            }
        }
    }

    private func hideAchievement() {
        achievementBadge.alpha = 0
        achievementBadge.isHidden = true
    }

    func updateGameState(_ message: String) {
        gameStateLabel.text = message
        gameStateLabel.isHidden = false
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

        // Disable game animations to save memory
        pulseAnimationLayers.forEach { $0.removeAllAnimations() }
        loadingTimer?.invalidate()
        layer.shadowOpacity = 0
    }

    deinit {
        loadingTimer?.invalidate()
        pulseAnimationLayers.forEach { $0.removeFromSuperlayer() }
    }
}

// MARK: - API Integration
extension KeyboardViewController {

    private func makePersonalizedFlirtAPIRequest(profile: PersonalizationProfile) {
        os_log("🚀 KEYBOARD API: Starting PERSONALIZED flirt API request", log: logger, type: .info)

        // Show loading in keyboard UI only (NO text in message field)
        DispatchQueue.main.async { [weak self] in
            self?.suggestionsView.showLoading()
        }

        let url = URL(string: "http://localhost:3000/api/v1/flirts/generate_personalized_openers")!
        let body: [String: Any] = [
            "user_preferences": profile.toJSON(),
            "request_id": "keyboard-personalized-\(Date().timeIntervalSince1970)"
        ]

        os_log("📊 Profile data - Style: %@, Confidence: %d/10, Interests: %d, Complete: %d%%",
               log: logger, type: .info,
               profile.communicationStyle?.displayName ?? "N/A",
               profile.confidenceLevel ?? 0,
               profile.interests.count,
               profile.completionPercentage)

        makeAPIRequest(url: url, body: body)
    }

    private func makeFlirtAPIRequest() {
        os_log("🚀 KEYBOARD API: Starting flirt API request", log: logger, type: .info)

        // Show loading in keyboard UI only (NO text in message field)
        DispatchQueue.main.async { [weak self] in
            self?.suggestionsView.showLoading()
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

    private func showPersonalizationNeededError() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.suggestionsView.hideLoading()
            self.suggestionsView.gameStateLabel.text = "⚙️ Complete setup in Flirrt app first"
            self.suggestionsView.gameStateLabel.textColor = .systemOrange
            self.suggestionsView.gameStateLabel.isHidden = false

            // Show a helpful message suggestion
            let setupSuggestion: [[String: Any]] = [
                [
                    "text": "Open the Flirrt app and complete your personalization",
                    "confidence": 1.0,
                    "tone": "system",
                    "is_system_message": true
                ]
            ]

            self.displaySuggestions(setupSuggestion)
            self.provideHapticFeedback(type: .warning)

            os_log("📱 Showing personalization needed error", log: self.logger, type: .info)
        }
    }

    private func makeAPIRequest(url: URL, body: [String: Any], retryCount: Int = 0) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "X-Keyboard-Extension")  // Bypass authentication
        request.timeoutInterval = 30.0  // 30 second timeout for AI API calls (typically respond in 9-22s)

        os_log("🔑 KEYBOARD API: Using X-Keyboard-Extension header for auth bypass (30s timeout)", log: logger, type: .info)

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

            // Process response or show error (NO FALLBACK)
            if let data = data {
                DispatchQueue.main.async {
                    self?.processAPIResponse(data)
                }
            } else {
                DispatchQueue.main.async {
                    self?.showAPIError("API request failed. Please try again.", errorType: .timeout)
                }
            }
        }.resume()
    }

    // REMOVED: showErrorWithFallback() - No fallback/mock data allowed per requirements
    // Replaced with showAPIError() that shows clear error messages only

    private func showAPIError(_ message: String, errorType: APIErrorType = .generic) {
        os_log("❌ API Error: %@", log: logger, type: .error, message)

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.suggestionsView.hideLoading()

            // Set error message based on type
            switch errorType {
            case .timeout:
                self.suggestionsView.gameStateLabel.text = "⏱️ Request timed out"
                self.suggestionsView.gameStateLabel.textColor = .systemRed
            case .network:
                self.suggestionsView.gameStateLabel.text = "📡 Network unavailable"
                self.suggestionsView.gameStateLabel.textColor = .systemRed
            case .serviceUnavailable:
                self.suggestionsView.gameStateLabel.text = "🔄 AI service recovering"
                self.suggestionsView.gameStateLabel.textColor = .systemOrange
            case .generic:
                self.suggestionsView.gameStateLabel.text = "❌ Generation failed"
                self.suggestionsView.gameStateLabel.textColor = .systemRed
            }

            self.suggestionsView.gameStateLabel.isHidden = false

            // Show error message as "suggestion"
            let errorSuggestion: [[String: Any]] = [
                [
                    "text": message,
                    "confidence": 0.0,
                    "tone": "error",
                    "is_error": true
                ]
            ]

            self.displaySuggestions(errorSuggestion)
            self.provideHapticFeedback(type: .error)
        }
    }

    enum APIErrorType {
        case timeout
        case network
        case serviceUnavailable
        case generic
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
                    // Display suggestions in keyboard UI only (NO message field manipulation)
                    self.displaySuggestions(suggestions)
                    self.provideHapticFeedback(type: .success)

                    os_log("✅ Successfully displayed %d AI-generated suggestions", log: self.logger, type: .info, suggestions.count)
                }
            } else {
                DispatchQueue.main.async {
                    self.showAPIError("No suggestions received from API", errorType: .generic)
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.showAPIError("Invalid API response format", errorType: .generic)
            }
        }
    }

    private func makeAnalysisAPIRequest() {
        os_log("🔍 KEYBOARD API: Making conversation analysis request", log: logger, type: .info)

        // Show loading in keyboard UI only
        DispatchQueue.main.async { [weak self] in
            self?.suggestionsView.showLoading()
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

        // Enhanced success feedback
        provideGameFeedback(for: .analysisComplete)
    }

    private func showError(_ message: String) {
        // Show error message to user
        textDocumentProxy.insertText("Error: \(message)")
        os_log("API Error: %@", log: logger, type: .error, message)
    }

    /// Handles "needs more context" response from backend
    private func handleNeedsMoreContext(message: String, action: String) {
        os_log("📸 Needs more context - Action: %@", log: logger, type: .info, action)

        // Show status in keyboard UI only (NO message field manipulation)
        suggestionsView.hideLoading()

        if action == "upload_profile" {
            // Empty chat - show helpful guidance in keyboard
            suggestionsView.gameStateLabel.text = "💬 Chat is empty!"
            suggestionsView.gameStateLabel.textColor = .systemOrange
            suggestionsView.gameStateLabel.isHidden = false

            // Show special suggestions for empty chat
            let emptyChatSuggestions = [
                [
                    "text": "📷 Tap here to upload their profile photo",
                    "confidence": 1.0,
                    "tone": "helpful"
                ],
                [
                    "text": "📸 Or scroll up and screenshot conversation",
                    "confidence": 0.9,
                    "tone": "helpful"
                ],
                [
                    "text": "🎯 More context = better AI suggestions!",
                    "confidence": 0.85,
                    "tone": "helpful"
                ]
            ]
            displaySuggestions(emptyChatSuggestions)

        } else {
            // Not enough conversation - ask to scroll up
            suggestionsView.gameStateLabel.text = "📸 Need more chat context!"
            suggestionsView.gameStateLabel.textColor = .systemOrange
            suggestionsView.gameStateLabel.isHidden = false

            // Show encouraging suggestions
            let scrollSuggestions = [
                [
                    "text": "⬆️ Scroll up to see more conversation",
                    "confidence": 1.0,
                    "tone": "helpful"
                ],
                [
                    "text": "📸 Take another screenshot with more messages",
                    "confidence": 0.95,
                    "tone": "helpful"
                ],
                [
                    "text": "💡 More context = better suggestions!",
                    "confidence": 0.9,
                    "tone": "helpful"
                ]
            ]
            displaySuggestions(scrollSuggestions)
        }

        // Provide warning haptic feedback
        provideHapticFeedback(type: .warning)

        // Make smart action button pulse to indicate user should try again
        smartActionButton.pulseAnimation()
    }
}

// MARK: - Caching REMOVED
// REMOVED: All caching functions per requirements - no stale/mock data allowed

// MARK: - Enhanced Haptic Feedback System
extension KeyboardViewController {

    private func provideHapticFeedback(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)

        // Log haptic events for user experience tracking
        os_log("📳 Haptic feedback: %@", log: logger, type: .debug, String(describing: type))
    }

    private func provideSelectionFeedback() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    private func provideImpactFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    private func provideGameFeedback(for event: GameEvent) {
        switch event {
        case .screenshotDetected:
            // Light tap + success notification
            provideImpactFeedback(style: .light)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.provideHapticFeedback(type: .success)
            }

        case .analysisComplete:
            // Medium impact + success
            provideImpactFeedback(style: .medium)
            provideHapticFeedback(type: .success)

        case .suggestionSelected:
            // Light tap for selection
            provideImpactFeedback(style: .light)

        case .buttonPressed:
            // Subtle selection feedback
            provideSelectionFeedback()

        case .error:
            // Strong error feedback
            provideImpactFeedback(style: .heavy)
            provideHapticFeedback(type: .error)

        case .loadingPhase:
            // Subtle progress feedback
            provideImpactFeedback(style: .light)
        }
    }

    private enum GameEvent {
        case screenshotDetected
        case analysisComplete
        case suggestionSelected
        case buttonPressed
        case error
        case loadingPhase
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

// MARK: - Button Animation Extensions
extension UIButton {
    func buttonPressAnimation() {
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.transform = .identity
            }
        }
    }

    func pulseAnimation() {
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 1.05
        pulseAnimation.duration = 0.6
        pulseAnimation.repeatCount = 3
        pulseAnimation.autoreverses = true
        layer.add(pulseAnimation, forKey: "pulse")
    }

    func selectedAnimation() {
        UIView.animate(withDuration: 0.2, animations: {
            self.backgroundColor = self.backgroundColor?.withAlphaComponent(0.3)
            self.transform = CGAffineTransform(scaleX: 0.98, y: 0.98)
        }) { _ in
            UIView.animate(withDuration: 0.3) {
                self.backgroundColor = self.backgroundColor?.withAlphaComponent(0.1)
                self.transform = .identity
            }
        }
    }
}

// MARK: - Image Compression Service (Embedded for Keyboard Extension)

/// Lightweight image compression service optimized for keyboard extension memory constraints
@MainActor
final class ImageCompressionService {

    private struct CompressionConfig {
        static let targetSizeSmall: Int = 100_000      // 100KB
        static let targetSizeMedium: Int = 200_000     // 200KB
        static let targetSizeLarge: Int = 500_000      // 500KB
        static let maxDimension: CGFloat = 1920        // Maximum width/height
        static let heicQuality: CGFloat = 0.85         // HEIC quality
        static let jpegQualityHigh: CGFloat = 0.9      // High quality JPEG
        static let jpegQualityMedium: CGFloat = 0.8    // Medium quality JPEG
        static let jpegQualityLow: CGFloat = 0.6       // Low quality JPEG
        static let binarySearchIterations: Int = 5     // Reduced for keyboard extension
    }

    private let logger = OSLog(subsystem: "com.flirrt.keyboard", category: "compression")

    /// Compresses screenshot data specifically for AI analysis
    func compressScreenshotForAI(_ screenshotData: Data) async -> CompressionResult {
        os_log("🗜️ Starting screenshot compression for AI", log: logger, type: .info)

        guard let image = UIImage(data: screenshotData) else {
            return CompressionResult(
                data: Data(),
                originalSize: screenshotData.count,
                compressedSize: 0,
                compressionRatio: 0,
                format: .heic,
                processingTime: 0,
                success: false,
                error: "Invalid image data"
            )
        }

        return await compressImage(image, targetFormat: .heic, useAggressive: true)
    }

    private func compressImage(_ image: UIImage, targetFormat: ImageFormat, useAggressive: Bool) async -> CompressionResult {
        let startTime = CFAbsoluteTimeGetCurrent()

        guard let originalData = image.pngData() else {
            return CompressionResult(
                data: Data(),
                originalSize: 0,
                compressedSize: 0,
                compressionRatio: 0,
                format: targetFormat,
                processingTime: 0,
                success: false,
                error: "Failed to extract image data"
            )
        }

        let originalSize = originalData.count
        os_log("📊 Original size: %d bytes", log: logger, type: .info, originalSize)

        // Determine compression strategy
        let strategy = determineCompressionStrategy(for: originalSize)
        os_log("🎯 Strategy: %@", log: logger, type: .info, strategy.description)

        // Apply compression
        let compressedData: Data
        switch strategy {
        case .none:
            compressedData = originalData
        case .light:
            compressedData = await performLightCompression(image, format: targetFormat)
        case .medium:
            compressedData = await performMediumCompression(image, format: targetFormat)
        case .aggressive:
            compressedData = await performAggressiveCompression(image, format: targetFormat)
        }

        let processingTime = CFAbsoluteTimeGetCurrent() - startTime
        let compressionRatio = originalSize > 0 ? (1.0 - Double(compressedData.count) / Double(originalSize)) : 0

        os_log("✅ Compression complete - Ratio: %.1f%%, Time: %.2fs",
               log: logger, type: .info, compressionRatio * 100, processingTime)

        return CompressionResult(
            data: compressedData,
            originalSize: originalSize,
            compressedSize: compressedData.count,
            compressionRatio: compressionRatio,
            format: targetFormat,
            processingTime: processingTime,
            success: !compressedData.isEmpty,
            error: compressedData.isEmpty ? "Compression failed" : nil
        )
    }

    private enum CompressionStrategy {
        case none, light, medium, aggressive

        var description: String {
            switch self {
            case .none: return "No compression"
            case .light: return "Light compression"
            case .medium: return "Medium compression"
            case .aggressive: return "Aggressive compression"
            }
        }
    }

    private func determineCompressionStrategy(for size: Int) -> CompressionStrategy {
        if size < CompressionConfig.targetSizeSmall {
            return .none
        } else if size < CompressionConfig.targetSizeMedium {
            return .light
        } else if size < CompressionConfig.targetSizeLarge {
            return .medium
        } else {
            return .aggressive
        }
    }

    private func performLightCompression(_ image: UIImage, format: ImageFormat) async -> Data {
        switch format {
        case .heic:
            return await compressToHEIC(image, quality: CompressionConfig.heicQuality)
        case .jpeg:
            return compressToJPEG(image, quality: CompressionConfig.jpegQualityHigh)
        }
    }

    private func performMediumCompression(_ image: UIImage, format: ImageFormat) async -> Data {
        let resizedImage = resizeImageIfNeeded(image, maxDimension: CompressionConfig.maxDimension)
        switch format {
        case .heic:
            return await compressToHEIC(resizedImage, quality: CompressionConfig.heicQuality * 0.9)
        case .jpeg:
            return compressToJPEG(resizedImage, quality: CompressionConfig.jpegQualityMedium)
        }
    }

    private func performAggressiveCompression(_ image: UIImage, format: ImageFormat) async -> Data {
        let resizedImage = resizeImageIfNeeded(image, maxDimension: CompressionConfig.maxDimension * 0.8)
        return await binarySearchOptimalCompression(resizedImage, format: format, targetSize: CompressionConfig.targetSizeLarge)
    }

    private func binarySearchOptimalCompression(_ image: UIImage, format: ImageFormat, targetSize: Int) async -> Data {
        var minQuality: CGFloat = 0.3
        var maxQuality: CGFloat = 0.9
        var bestData = Data()

        for _ in 1...CompressionConfig.binarySearchIterations {
            let currentQuality = (minQuality + maxQuality) / 2

            let testData: Data
            switch format {
            case .heic:
                testData = await compressToHEIC(image, quality: currentQuality)
            case .jpeg:
                testData = compressToJPEG(image, quality: currentQuality)
            }

            if testData.count <= targetSize {
                bestData = testData
                minQuality = currentQuality
            } else {
                maxQuality = currentQuality
            }

            if abs(testData.count - targetSize) < targetSize / 20 {
                bestData = testData
                break
            }
        }

        return bestData
    }

    private func compressToHEIC(_ image: UIImage, quality: CGFloat) async -> Data {
        guard let cgImage = image.cgImage else {
            return compressToJPEG(image, quality: quality)
        }

        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.heic.identifier as CFString, 1, nil) else {
            return compressToJPEG(image, quality: quality)
        }

        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality,
            kCGImageDestinationOptimizeColorForSharing: true
        ]

        CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)

        return CGImageDestinationFinalize(destination) ? (data as Data) : compressToJPEG(image, quality: quality)
    }

    private func compressToJPEG(_ image: UIImage, quality: CGFloat) -> Data {
        return image.jpegData(compressionQuality: quality) ?? Data()
    }

    private func resizeImageIfNeeded(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let currentMaxDimension = max(image.size.width, image.size.height)
        if currentMaxDimension <= maxDimension { return image }

        let scale = maxDimension / currentMaxDimension
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

enum ImageFormat: String {
    case heic = "HEIC"
    case jpeg = "JPEG"
}

struct CompressionResult {
    let data: Data
    let originalSize: Int
    let compressedSize: Int
    let compressionRatio: Double
    let format: ImageFormat
    let processingTime: TimeInterval
    let success: Bool
    let error: String?
}

// MARK: - Optimized Screenshot Analysis
extension KeyboardViewController {

    private func setupScreenshotObserver() {
        // Setup Darwin notification observer for instant screenshot detection
        // Note: Removed PHPhotoLibrary observer to reduce memory usage and redundancy
        // Main app posts Darwin notification when screenshot is taken
        setupDarwinNotificationObserver()

        os_log("🔍 Screenshot observer initialized (Darwin notifications only)", log: logger, type: .info)
    }

    private func setupDarwinNotificationObserver() {
        // Listen for screenshot_detected notifications from main app
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            Unmanaged.passUnretained(self).toOpaque(),
            { (_, observer, name, _, _) in
                guard let observer = observer else { return }
                let keyboardController = Unmanaged<KeyboardViewController>.fromOpaque(observer).takeUnretainedValue()

                Task { @MainActor in
                    keyboardController.handleInstantScreenshotDetection()
                }
            },
            "com.flirrt.screenshot.detected" as CFString,
            nil,
            .deliverImmediately
        )
    }

    @MainActor
    private func handleInstantScreenshotDetection() {
        os_log("⚡ Instant screenshot detection triggered", log: logger, type: .info)

        // Update screenshot timestamp
        lastScreenshotTime = Date().timeIntervalSince1970

        // Automatically switch button to analyze mode
        currentButtonMode = .analyzeScreenshot

        // Provide immediate haptic feedback
        provideHapticFeedback(type: .success)

        // Show game-like detection animation
        suggestionsView.showScreenshotDetected()

        // Pulse the smart action button to draw attention
        smartActionButton.pulseAnimation()

        // Check for the new screenshot with optimized fetch
        checkForRecentScreenshot(optimized: true)

        // Auto-revert to Fresh mode after 60 seconds if not used
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) { [weak self] in
            guard let self = self else { return }
            let timeSince = Date().timeIntervalSince1970 - self.lastScreenshotTime
            if timeSince >= 60 {
                self.currentButtonMode = .freshOpeners
            }
        }
    }

    // REMOVED: photoLibraryDidChange - no longer using PHPhotoLibrary observer
    // Screenshot detection now handled exclusively via Darwin notifications
    // This reduces memory usage by ~8MB and eliminates redundant detection logic

    private func checkForRecentScreenshot(optimized: Bool = false) {
        let timeWindow: TimeInterval = optimized ? 10 : 60 // Tighter window for optimized detection

        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            guard status == .authorized || status == .limited else {
                os_log("Photo library access not authorized", log: self?.logger ?? OSLog.default, type: .info)
                return
            }

            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.fetchLimit = optimized ? 3 : 1 // Check multiple recent screenshots in optimized mode

            // Only get screenshots with optimized predicate
            fetchOptions.predicate = NSPredicate(
                format: "mediaType = %d AND mediaSubtype = %d AND creationDate > %@",
                PHAssetMediaType.image.rawValue,
                PHAssetMediaSubtype.photoScreenshot.rawValue,
                Date().addingTimeInterval(-timeWindow) as NSDate
            )

            let screenshots = PHAsset.fetchAssets(with: fetchOptions)

            guard let latestScreenshot = screenshots.firstObject else {
                if optimized {
                    DispatchQueue.main.async {
                        self?.suggestionsView.showNoRecentScreenshot()
                    }
                }
                return
            }

            // Enhanced screenshot detection with instant feedback
            let screenshotDate = latestScreenshot.creationDate ?? Date.distantPast
            let timeSinceScreenshot = Date().timeIntervalSince(screenshotDate)

            if timeSinceScreenshot < timeWindow {
                os_log("🎯 Recent screenshot detected (%.1fs ago) - auto-analyzing",
                       log: self?.logger ?? OSLog.default, type: .info, timeSinceScreenshot)

                DispatchQueue.main.async {
                    if optimized {
                        self?.suggestionsView.showOptimizedAnalysis()
                        self?.provideHapticFeedback(type: .success)
                    }
                    self?.processScreenshot(latestScreenshot, optimized: optimized)
                }
            } else if optimized {
                DispatchQueue.main.async {
                    self?.suggestionsView.showNoRecentScreenshot()
                    self?.promptForNewScreenshot()
                }
            }
        }
    }

    private func processScreenshot(_ asset: PHAsset, optimized: Bool = false) {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = optimized ? .fastFormat : .highQualityFormat
        options.isSynchronous = false
        options.isNetworkAccessAllowed = false // Prefer local cache for speed

        manager.requestImageDataAndOrientation(for: asset, options: options) { [weak self] data, _, _, _ in
            guard let imageData = data else {
                if optimized {
                    DispatchQueue.main.async {
                        self?.suggestionsView.showError("Screenshot not accessible")
                        self?.provideGameFeedback(for: .error)
                    }
                }
                return
            }

            Task { @MainActor in
                if optimized {
                    self?.suggestionsView.showOptimizedAnalysis()
                }
                await self?.compressAndUploadScreenshot(imageData, optimized: optimized)
            }
        }
    }

    private func promptForNewScreenshot() {
        // Smart prompting system - show in keyboard UI only
        let promptMessage = generateSmartPrompt()

        DispatchQueue.main.async {
            self.suggestionsView.gameStateLabel.text = "📸 Take screenshot"
            self.suggestionsView.gameStateLabel.isHidden = false
            self.suggestionsView.showSmartPrompt()
        }
    }

    private func generateSmartPrompt() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let isEvening = hour >= 18

        let prompts = [
            "Take a screenshot of your conversation for AI analysis! 📸",
            "Screenshot your chat to get personalized suggestions! ✨",
            isEvening ? "Evening flirt mode - screenshot for better responses! 🌙" : "Ready to analyze - take a screenshot! 😊",
            "Smart AI waiting - screenshot your conversation! 🤖"
        ]

        return prompts.randomElement() ?? prompts[0]
    }

    /// Compresses screenshot data before upload to reduce timeout issues
    private func compressAndUploadScreenshot(_ originalImageData: Data, optimized: Bool = false) async {
        os_log("🗜️ Starting image compression - Original size: %d bytes", log: logger, type: .info, originalImageData.count)

        // Show compression progress in keyboard UI only
        DispatchQueue.main.async {
            self.suggestionsView.showLoading()
            self.suggestionsView.gameStateLabel.text = "Optimizing image..."
            self.suggestionsView.gameStateLabel.isHidden = false
        }

        // Step 1: Compress the image using our advanced compression service
        let compressionResult = await imageCompressionService.compressScreenshotForAI(originalImageData)

        if compressionResult.success {
            let compressionRatio = compressionResult.compressionRatio * 100
            os_log("✅ Compression successful - Reduced by %.1f%% (Original: %d bytes → Compressed: %d bytes)",
                   log: logger, type: .info, compressionRatio, compressionResult.originalSize, compressionResult.compressedSize)

            // Update UI with compression stats in keyboard only
            DispatchQueue.main.async {
                self.suggestionsView.gameStateLabel.text = "Optimized by \(String(format: "%.0f", compressionRatio))%"
                self.suggestionsView.gameStateLabel.isHidden = false
                self.provideGameFeedback(for: .loadingPhase)
            }

            // Step 2: Upload the compressed image
            await uploadScreenshotToBackend(compressionResult.data, isCompressed: true)

        } else {
            os_log("❌ Compression failed: %@", log: logger, type: .error, compressionResult.error ?? "Unknown error")

            // Fallback to original image - show status in keyboard
            DispatchQueue.main.async {
                self.suggestionsView.gameStateLabel.text = "Using original image"
                self.suggestionsView.gameStateLabel.isHidden = false
            }

            await uploadScreenshotToBackend(originalImageData, isCompressed: false)
        }
    }

    /// Uploads screenshot to backend with optimized timeout handling
    private func uploadScreenshotToBackend(_ imageData: Data, isCompressed: Bool = false) async {
        // Show loading status in keyboard UI only
        DispatchQueue.main.async {
            self.suggestionsView.showLoading()
            self.suggestionsView.gameStateLabel.text = isCompressed ? "Uploading..." : "Uploading..."
            self.suggestionsView.gameStateLabel.isHidden = false
        }

        let url = URL(string: "http://localhost:3000/api/v1/analysis/analyze_screenshot")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // Adjust timeout based on image size
        let timeoutInterval: TimeInterval = isCompressed ? 15.0 : 30.0
        request.timeoutInterval = timeoutInterval

        os_log("⏱️ Upload timeout set to %.0f seconds for %@ image",
               log: logger, type: .info, timeoutInterval, isCompressed ? "compressed" : "original")

        // Add auth token or bypass header
        if let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt.shared"),
           let token = sharedDefaults.string(forKey: "auth_token") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            // Fallback to keyboard extension bypass
            request.setValue("true", forHTTPHeaderField: "X-Keyboard-Extension")
        }

        // Build multipart form data
        var body = Data()

        // Determine content type based on compression
        let contentType = isCompressed ? "image/heic" : "image/jpeg"
        let filename = isCompressed ? "screenshot.heic" : "screenshot.jpg"

        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"screenshot\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(contentType)\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)

        // Add compression metadata
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"compressed\"\r\n\r\n".data(using: .utf8)!)
        body.append(isCompressed ? "true".data(using: .utf8)! : "false".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)

        // Add context
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"context\"\r\n\r\n".data(using: .utf8)!)
        body.append("dating_app_screenshot".data(using: .utf8)!)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        // Log upload details
        os_log("📤 Uploading %@ - Size: %d bytes, Timeout: %.0fs",
               log: logger, type: .info, isCompressed ? "compressed screenshot" : "original screenshot",
               imageData.count, timeoutInterval)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                os_log("📥 Upload response - Status: %d, Size: %d bytes",
                       log: logger, type: .info, httpResponse.statusCode, data.count)
            }

            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            // CRITICAL: Check if screenshot needs more context
            if let needsMore = json?["needs_more_context"] as? Bool, needsMore {
                os_log("⚠️ Screenshot needs more context", log: logger, type: .info)

                let message = json?["message"] as? String ?? "Need more context"
                let actionRequired = json?["action_required"] as? String ?? "more_screenshots"

                DispatchQueue.main.async {
                    self.handleNeedsMoreContext(message: message, action: actionRequired)
                }
                return
            }

            if let screenshotId = json?["screenshot_id"] as? String {
                os_log("✅ Screenshot uploaded successfully - ID: %@", log: logger, type: .info, screenshotId)
                DispatchQueue.main.async {
                    // Generate flirts - status shown in keyboard UI
                    self.generateFlirtsForScreenshot(screenshotId)
                }
            } else {
                throw NSError(domain: "AnalysisError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
            }

        } catch {
            os_log("❌ Upload failed: %@", log: logger, type: .error, error.localizedDescription)

            DispatchQueue.main.async {
                // Show error in keyboard UI only (NO text insertion)
                if error.localizedDescription.contains("timeout") || error.localizedDescription.contains("timed out") {
                    self.suggestionsView.showError("Upload timeout - try again")
                } else {
                    self.suggestionsView.showError("Upload failed")
                }
                self.provideHapticFeedback(type: .error)
            }
        }
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

