// Memory-optimized KeyboardViewController
import UIKit
import os.log

class OptimizedKeyboardViewController: UIInputViewController {
    private let logger = OSLog(subsystem: "com.vibe8.keyboard", category: "memory")
    private let appGroupID = "group.com.vibe8.shared"
    private let memoryLimit = 60 * 1024 * 1024

    // Lazy loading for UI components
    private lazy var actionStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    // Lightweight buttons
    private func createButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 6
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMinimalUI()
        loadEssentialData()
        monitorMemory()
    }

    private func setupMinimalUI() {
        view.backgroundColor = .systemBackground

        let freshButton = createButton(title: "Fresh", action: #selector(freshTapped))
        let analyzeButton = createButton(title: "Analyze", action: #selector(analyzeTapped))

        actionStack.addArrangedSubview(freshButton)
        actionStack.addArrangedSubview(analyzeButton)
        view.addSubview(actionStack)

        NSLayoutConstraint.activate([
            actionStack.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            actionStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            actionStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            actionStack.heightAnchor.constraint(equalToConstant: 44),
            view.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    @objc private func freshTapped() {
        insertSuggestion("Hey! How's it going?")
    }

    @objc private func analyzeTapped() {
        requestAnalysis()
    }

    private func insertSuggestion(_ text: String) {
        textDocumentProxy.insertText(text)
    }

    private func requestAnalysis() {
        updateSharedData()
        postNotification()
    }

    private func updateSharedData() {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupID) else { return }
        sharedDefaults.set(Date().timeIntervalSince1970, forKey: "analysis_request_time")
        sharedDefaults.synchronize()
    }

    private func postNotification() {
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName("com.vibe8.analyze.request" as CFString),
            nil, nil, true
        )
    }

    private func loadEssentialData() {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupID) else { return }
        let authenticated = sharedDefaults.bool(forKey: "user_authenticated")
        if !authenticated {
            textDocumentProxy.insertText("Please open Vibe8 app first")
        }
    }

    private func monitorMemory() {
        let usage = getMemoryUsage()
        if usage > memoryLimit {
            os_log("Memory limit exceeded: %d bytes", log: logger, type: .error, usage)
            freeMemory()
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

    private func freeMemory() {
        // Clear caches and reduce functionality
        URLCache.shared.removeAllCachedResponses()
    }
}