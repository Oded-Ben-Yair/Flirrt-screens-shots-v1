import UIKit

/// Custom QWERTY Keyboard Implementation for Vibe8
/// iOS 26 Liquid Glass Design
/// Production-ready custom keyboard without external dependencies
class Vibe8QWERTYKeyboardView: UIView {

    // MARK: - Properties

    weak var delegate: Vibe8KeyboardDelegate?

    private var keyRows: [[KeyButton]] = []

    private let keyboardHeight: CGFloat = 260
    private let keySpacing: CGFloat = 6
    private let rowSpacing: CGFloat = 10

    // Liquid Glass design colors (iOS 26)
    private let keyBackgroundColor = UIColor(white: 1.0, alpha: 0.85)
    private let keyPressedColor = UIColor(white: 0.9, alpha: 0.95)
    private let keyTextColor = UIColor.label
    private let keyCornerRadius: CGFloat = 8

    // MARK: - Keyboard Layout

    private let keyboardLayout: [[String]] = [
        ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
        ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
        ["⇧", "Z", "X", "C", "V", "B", "N", "M", "⌫"],
        ["123", "🌐", "space", "return"]
    ]

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.frame = frame
        setupKeyboard()
        applyLiquidGlassDesign()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupKeyboard() {
        backgroundColor = UIColor.systemBackground.withAlphaComponent(0.95)

        // Create key rows
        var yOffset: CGFloat = 10

        for (rowIndex, row) in keyboardLayout.enumerated() {
            let rowView = createKeyRow(keys: row, rowIndex: rowIndex, yOffset: yOffset)
            addSubview(rowView)
            yOffset += rowView.frame.height + rowSpacing
        }
    }

    private func createKeyRow(keys: [String], rowIndex: Int, yOffset: CGFloat) -> UIView {
        let rowView = UIView()
        let rowWidth = frame.width - 20

        // Calculate key width
        let totalSpacing = CGFloat(keys.count - 1) * keySpacing
        var keyWidth = (rowWidth - totalSpacing) / CGFloat(keys.count)

        // Adjust for special keys
        if rowIndex == 2 { // Row with shift and delete
            keyWidth = (rowWidth - totalSpacing - 30) / CGFloat(keys.count - 2) // Smaller width for letters
        } else if rowIndex == 3 { // Bottom row
            keyWidth = 60 // Fixed width for special keys
        }

        let keyHeight: CGFloat = 42

        var xOffset: CGFloat = 10
        var rowButtons: [KeyButton] = []

        for key in keys {
            let button = KeyButton(key: key)
            button.frame = CGRect(x: xOffset, y: 0, width: getKeyWidth(for: key, baseWidth: keyWidth), height: keyHeight)
            button.addTarget(self, action: #selector(keyPressed(_:)), for: .touchUpInside)
            button.addTarget(self, action: #selector(keyTouchDown(_:)), for: .touchDown)
            button.addTarget(self, action: #selector(keyTouchUp(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])

            styleKey(button, for: key)

            rowView.addSubview(button)
            rowButtons.append(button)

            xOffset += button.frame.width + keySpacing
        }

        keyRows.append(rowButtons)
        rowView.frame = CGRect(x: 0, y: yOffset, width: frame.width, height: keyHeight)

        return rowView
    }

    private func getKeyWidth(for key: String, baseWidth: CGFloat) -> CGFloat {
        switch key {
        case "space":
            return baseWidth * 4 // Wide space bar
        case "return":
            return baseWidth * 1.5
        case "⇧", "⌫":
            return baseWidth * 1.3
        case "123", "🌐":
            return baseWidth
        default:
            return baseWidth
        }
    }

    private func styleKey(_ button: KeyButton, for key: String) {
        button.backgroundColor = keyBackgroundColor
        button.setTitleColor(keyTextColor, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .regular)
        button.layer.cornerRadius = keyCornerRadius
        button.layer.cornerCurve = .continuous // iOS 26 Liquid Glass effect

        // Add shadow for depth
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 1)
        button.layer.shadowOpacity = 0.1
        button.layer.shadowRadius = 2

        // Special styling for action keys
        switch key {
        case "return":
            button.backgroundColor = UIColor.systemBlue
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        case "⇧", "⌫", "123", "🌐":
            button.backgroundColor = UIColor.secondarySystemFill
            button.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        case "space":
            button.setTitle("", for: .normal) // Empty title, will show "space" hint
        default:
            break
        }
    }

    private func applyLiquidGlassDesign() {
        // iOS 26 Liquid Glass background effect
        let blurEffect = UIBlurEffect(style: .systemMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(blurView, at: 0)
    }

    // MARK: - Actions

    @objc private func keyPressed(_ sender: KeyButton) {
        guard let key = sender.key else { return }

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        switch key {
        case "⌫":
            delegate?.keyboardDidPressDelete()
        case "return":
            delegate?.keyboardDidPressReturn()
        case "space":
            delegate?.keyboardDidPressSpace()
        case "⇧":
            delegate?.keyboardDidPressShift()
        case "123":
            delegate?.keyboardDidPressNumberToggle()
        case "🌐":
            delegate?.keyboardDidPressGlobe()
        default:
            delegate?.keyboardDidPressKey(key)
        }
    }

    @objc private func keyTouchDown(_ sender: KeyButton) {
        UIView.animate(withDuration: 0.1) {
            sender.backgroundColor = self.keyPressedColor
            sender.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }

    @objc private func keyTouchUp(_ sender: KeyButton) {
        UIView.animate(withDuration: 0.1) {
            sender.backgroundColor = self.keyBackgroundColor
            sender.transform = .identity
        }
    }

    // MARK: - Layout

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: keyboardHeight)
    }
}

// MARK: - KeyButton

class KeyButton: UIButton {
    var key: String?

    convenience init(key: String) {
        self.init(type: .system)
        self.key = key
        setTitle(key, for: .normal)
    }
}

// MARK: - Vibe8KeyboardDelegate

protocol Vibe8KeyboardDelegate: AnyObject {
    func keyboardDidPressKey(_ key: String)
    func keyboardDidPressDelete()
    func keyboardDidPressReturn()
    func keyboardDidPressSpace()
    func keyboardDidPressShift()
    func keyboardDidPressNumberToggle()
    func keyboardDidPressGlobe()
}
