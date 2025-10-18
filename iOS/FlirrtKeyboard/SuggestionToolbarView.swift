import UIKit

/// Suggestion Toolbar - Shows up to 3 suggestion chips above keyboard
/// iOS 26 Liquid Glass design
protocol SuggestionToolbarDelegate: AnyObject {
    func suggestionToolbarDidSelectSuggestion(_ suggestion: FlirtSuggestion)
    func suggestionToolbarDidRequestRefresh()
}

class SuggestionToolbarView: UIView {

    // MARK: - Properties

    weak var delegate: SuggestionToolbarDelegate?

    private var suggestions: [FlirtSuggestion] = []

    private lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        return scroll
    }()

    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .fillProportionally
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.text = "📸 Take a screenshot in Vibe8 app"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var refreshButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "arrow.clockwise"), for: .normal)
        button.tintColor = .systemPink
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(refreshTapped), for: .touchUpInside)
        button.isHidden = true
        return button
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.frame = frame
        setupUI()
        applyLiquidGlassDesign()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(scrollView)
        addSubview(placeholderLabel)
        addSubview(refreshButton)

        scrollView.addSubview(stackView)

        NSLayoutConstraint.activate([
            // Scroll View
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: refreshButton.leadingAnchor, constant: -8),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            // Stack View
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),

            // Placeholder
            placeholderLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            placeholderLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            placeholderLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 16),
            placeholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),

            // Refresh Button
            refreshButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            refreshButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            refreshButton.widthAnchor.constraint(equalToConstant: 32),
            refreshButton.heightAnchor.constraint(equalToConstant: 32),
        ])
    }

    private func applyLiquidGlassDesign() {
        backgroundColor = .clear
        layer.cornerRadius = 12
        layer.cornerCurve = .continuous
    }

    // MARK: - Public Methods

    func updateSuggestions(_ newSuggestions: [FlirtSuggestion]) {
        suggestions = Array(newSuggestions.prefix(3)) // Max 3

        // Clear existing chips
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Hide placeholder, show chips
        placeholderLabel.isHidden = true
        scrollView.isHidden = false
        refreshButton.isHidden = false

        // Create suggestion chips
        for (index, suggestion) in suggestions.enumerated() {
            let chip = createSuggestionChip(suggestion: suggestion, index: index)
            stackView.addArrangedSubview(chip)
        }

        // Add refresh button to stack
        let spacer = UIView()
        spacer.translatesAutoresizingMaskIntoConstraints = false
        spacer.widthAnchor.constraint(equalToConstant: 8).isActive = true
        stackView.addArrangedSubview(spacer)
    }

    func showPlaceholder() {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        placeholderLabel.isHidden = false
        scrollView.isHidden = true
        refreshButton.isHidden = true
    }

    // MARK: - Private Methods

    private func createSuggestionChip(suggestion: FlirtSuggestion, index: Int) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false

        // Truncate long suggestions
        let displayText = suggestion.text.count > 50
            ? String(suggestion.text.prefix(47)) + "..."
            : suggestion.text

        button.setTitle("\(index + 1). \(displayText)", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        button.titleLabel?.numberOfLines = 1
        button.titleLabel?.lineBreakMode = .byTruncatingTail

        // iOS 26 Liquid Glass styling
        button.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.95)
        button.setTitleColor(.label, for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        button.layer.cornerRadius = 8
        button.layer.cornerCurve = .continuous

        // Shadow for depth
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowOpacity = 0.1
        button.layer.shadowRadius = 2

        // Border
        button.layer.borderWidth = 0.5
        button.layer.borderColor = UIColor.separator.cgColor

        button.tag = index
        button.addTarget(self, action: #selector(suggestionTapped(_:)), for: .touchUpInside)

        // Minimum width
        button.widthAnchor.constraint(greaterThanOrEqualToConstant: 120).isActive = true

        return button
    }

    // MARK: - Actions

    @objc private func suggestionTapped(_ sender: UIButton) {
        let index = sender.tag
        guard index < suggestions.count else { return }

        let suggestion = suggestions[index]

        // Visual feedback
        UIView.animate(withDuration: 0.1, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                sender.transform = .identity
            }
        }

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        delegate?.suggestionToolbarDidSelectSuggestion(suggestion)
    }

    @objc private func refreshTapped() {
        // Visual feedback
        refreshButton.transform = CGAffineTransform(rotationAngle: .pi)
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 5, options: []) {
            self.refreshButton.transform = CGAffineTransform(rotationAngle: .pi * 2)
        } completion: { _ in
            self.refreshButton.transform = .identity
        }

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        delegate?.suggestionToolbarDidRequestRefresh()
    }
}
