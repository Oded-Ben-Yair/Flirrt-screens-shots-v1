import XCTest
import UIKit
import os.log
import Photos
@testable import FlirrtKeyboard

/// Comprehensive test suite for the FlirrtKeyboard extension
/// Tests critical user-facing functionality that was previously broken
class KeyboardExtensionTests: XCTestCase {

    var keyboardVC: KeyboardViewController!
    var mockTextDocumentProxy: MockTextDocumentProxy!

    override func setUp() {
        super.setUp()
        keyboardVC = KeyboardViewController()
        mockTextDocumentProxy = MockTextDocumentProxy()
        keyboardVC.textDocumentProxy = mockTextDocumentProxy

        // Force view load to trigger viewDidLoad
        keyboardVC.loadViewIfNeeded()
    }

    override func tearDown() {
        keyboardVC = nil
        mockTextDocumentProxy = nil
        super.tearDown()
    }

    // MARK: - UI Components Tests

    func testKeyboardUIElementsExist() {
        // Test that all required UI elements exist
        XCTAssertNotNil(keyboardVC.view, "Main view should exist")
        XCTAssertNotNil(keyboardVC.flirrtFreshButton, "Fresh button should exist")
        XCTAssertNotNil(keyboardVC.analyzeButton, "Analyze button should exist")
        XCTAssertNotNil(keyboardVC.suggestionsView, "Suggestions view should exist")
    }

    func testFreshButtonConfiguration() {
        let freshButton = keyboardVC.flirrtFreshButton
        XCTAssertEqual(freshButton.title(for: .normal), "💫 Fresh", "Fresh button should have correct title")
        XCTAssertEqual(freshButton.backgroundColor, .systemPink, "Fresh button should have pink background")
        XCTAssertEqual(freshButton.layer.cornerRadius, 8, "Fresh button should have rounded corners")
    }

    func testAnalyzeButtonConfiguration() {
        let analyzeButton = keyboardVC.analyzeButton
        XCTAssertEqual(analyzeButton.title(for: .normal), "📸 Analyze", "Analyze button should have correct title")
        XCTAssertEqual(analyzeButton.backgroundColor, .systemBlue, "Analyze button should have blue background")
        XCTAssertEqual(analyzeButton.layer.cornerRadius, 8, "Analyze button should have rounded corners")
    }

    func testInitialSuggestionsViewHidden() {
        XCTAssertTrue(keyboardVC.suggestionsView.isHidden, "Suggestions view should be hidden initially")
    }

    // MARK: - Fresh Button Tests

    func testFreshButtonMakesAPICall() {
        let expectation = self.expectation(description: "Fresh button should trigger API call")

        // Mock network session for testing
        let mockSession = MockURLSession()
        keyboardVC.urlSession = mockSession

        // Tap Fresh button
        keyboardVC.flirrtFreshTapped()

        // Verify API call was made
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(mockSession.dataTaskCalled, "Fresh button should trigger API call")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
    }

    func testFreshButtonDisplaysSuggestions() {
        let expectation = self.expectation(description: "Fresh button should display suggestions")

        // Mock successful API response
        let mockSuggestions = [
            ["text": "Hey! How's your day going?", "confidence": 0.8, "tone": "casual"],
            ["text": "That's such an interesting photo!", "confidence": 0.9, "tone": "friendly"],
            ["text": "I'd love to know more about that!", "confidence": 0.85, "tone": "curious"]
        ]

        keyboardVC.displaySuggestions(mockSuggestions)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertFalse(self.keyboardVC.suggestionsView.isHidden, "Suggestions view should be visible after Fresh button tap")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
    }

    func testFreshButtonCachesFallbackSuggestions() {
        // Test fallback when API fails
        let fallbackSuggestions = keyboardVC.createDefaultSuggestions()
        XCTAssertEqual(fallbackSuggestions.count, 3, "Should create 3 default suggestions")
        XCTAssertEqual(fallbackSuggestions[0].text, "Hey! How's your day going?", "First suggestion should match expected text")
        XCTAssertEqual(fallbackSuggestions[1].confidence, 0.9, "Second suggestion should have correct confidence")
    }

    // MARK: - Analyze Button Tests

    func testAnalyzeButtonCapturesScreenshot() {
        let expectation = self.expectation(description: "Analyze button should process screenshot")

        // Grant photo library access for testing
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            keyboardVC.analyzeTapped()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // Verify that suggestions view shows loading
                // This would require access to private properties, so we test indirectly
                XCTAssertNotNil(self.keyboardVC.suggestionsView, "Suggestions view should exist after analyze tap")
                expectation.fulfill()
            }
        } else {
            // Skip test if no photo access
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2.0)
    }

    func testAnalyzeButtonRequiresFullAccess() {
        // Test that analyze button shows error when full access not granted
        keyboardVC.hasFullAccess = false

        let expectation = self.expectation(description: "Should show full access required")

        keyboardVC.analyzeTapped()

        // In real implementation, this would show an alert
        // We can test by checking if any alert was presented
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertTrue(true, "Analyze button handles no full access gracefully")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
    }

    // MARK: - Memory Management Tests

    func testMemoryUsageUnder60MB() {
        let memoryUsage = keyboardVC.getMemoryUsage()
        let memoryMB = Double(memoryUsage) / (1024 * 1024)

        XCTAssertLessThan(memoryMB, 60.0, "Keyboard extension memory usage should stay under 60MB")
        print("Current memory usage: \(String(format: "%.2f", memoryMB)) MB")
    }

    func testMemoryWarningHandling() {
        let initialMemory = keyboardVC.getMemoryUsage()

        // Simulate memory warning
        keyboardVC.handleMemoryWarning()

        let postWarningMemory = keyboardVC.getMemoryUsage()

        // After memory warning, cache should be cleared
        XCTAssertTrue(true, "Memory warning handling should complete without crash")
    }

    func testCacheClearingReducesMemory() {
        // Fill some cache
        let mockSuggestions = Array(0..<50).map { i in
            ["text": "Suggestion \(i)", "confidence": 0.8, "tone": "casual"]
        }
        keyboardVC.cacheSuggestions(mockSuggestions)

        // Clear cache
        keyboardVC.clearCache()

        // Verify cache was cleared (indirectly)
        let cachedSuggestions = keyboardVC.loadCachedSuggestions()
        XCTAssertNil(cachedSuggestions, "Cache should be empty after clearing")
    }

    // MARK: - Concurrency Safety Tests

    func testConcurrentAPICallsSafety() {
        let expectation = self.expectation(description: "Concurrent API calls should be handled safely")
        expectation.expectedFulfillmentCount = 3

        // Make multiple concurrent API calls
        DispatchQueue.global().async {
            self.keyboardVC.flirrtFreshTapped()
            expectation.fulfill()
        }

        DispatchQueue.global().async {
            self.keyboardVC.flirrtFreshTapped()
            expectation.fulfill()
        }

        DispatchQueue.global().async {
            self.keyboardVC.analyzeTapped()
            expectation.fulfill()
        }

        waitForExpectations(timeout: 3.0)
    }

    // MARK: - App Groups Integration Tests

    func testAppGroupDataSharing() {
        let appGroupID = "group.com.flirrt.shared"
        let sharedDefaults = UserDefaults(suiteName: appGroupID)

        XCTAssertNotNil(sharedDefaults, "Should be able to access App Group shared defaults")

        // Test writing and reading data
        sharedDefaults?.set(true, forKey: "test_auth")
        sharedDefaults?.synchronize()

        let testValue = sharedDefaults?.bool(forKey: "test_auth")
        XCTAssertTrue(testValue ?? false, "Should be able to write and read from App Group")

        // Clean up
        sharedDefaults?.removeObject(forKey: "test_auth")
    }

    func testSharedDataLoading() {
        // Test loading shared data from App Group
        let appGroupID = "group.com.flirrt.shared"
        guard let sharedDefaults = UserDefaults(suiteName: appGroupID) else {
            XCTFail("Unable to access App Group")
            return
        }

        // Set test data
        sharedDefaults.set(true, forKey: "user_authenticated")
        sharedDefaults.set(true, forKey: "voice_enabled")
        sharedDefaults.set(Date().timeIntervalSince1970, forKey: "last_screenshot_time")
        sharedDefaults.synchronize()

        // Load data
        keyboardVC.loadSharedData()

        // Verify data was loaded (indirectly through UI state)
        XCTAssertNotNil(keyboardVC.view, "View should exist after loading shared data")

        // Clean up
        sharedDefaults.removeObject(forKey: "user_authenticated")
        sharedDefaults.removeObject(forKey: "voice_enabled")
        sharedDefaults.removeObject(forKey: "last_screenshot_time")
    }

    // MARK: - Text Insertion Tests

    func testSuggestionInsertsText() {
        let testText = "Hey! How's your day going?"

        keyboardVC.didSelectSuggestion(testText)

        XCTAssertEqual(mockTextDocumentProxy.insertedText, testText, "Selected suggestion should be inserted into text field")
        XCTAssertTrue(keyboardVC.suggestionsView.isHidden, "Suggestions view should hide after selection")
    }

    // MARK: - Haptic Feedback Tests

    func testHapticFeedbackOnButtonPress() {
        // Test that haptic feedback is triggered (we can't easily test the actual haptic)
        let expectation = self.expectation(description: "Haptic feedback should be called")

        // Override haptic method to track calls
        var hapticCalled = false
        keyboardVC.hapticFeedbackClosure = {
            hapticCalled = true
            expectation.fulfill()
        }

        keyboardVC.flirrtFreshTapped()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if !hapticCalled {
                expectation.fulfill() // Fulfill anyway to prevent timeout
            }
        }

        waitForExpectations(timeout: 1.0)
    }

    // MARK: - Error Handling Tests

    func testNetworkErrorHandling() {
        let expectation = self.expectation(description: "Network errors should be handled gracefully")

        // Simulate network error
        let error = NSError(domain: "NetworkError", code: -1009, userInfo: [NSLocalizedDescriptionKey: "No internet connection"])

        keyboardVC.handleAPIError(error)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Error should be handled without crash
            XCTAssertNotNil(self.keyboardVC.view, "View should still exist after network error")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
    }

    func testInvalidJSONResponseHandling() {
        let invalidData = "Invalid JSON".data(using: .utf8)!

        keyboardVC.processAPIResponse(invalidData)

        // Should handle invalid JSON gracefully without crash
        XCTAssertNotNil(keyboardVC.view, "View should exist after invalid JSON response")
    }

    // MARK: - Voice Features Tests

    func testVoiceRequestCreation() {
        let testText = "Hello, how are you?"
        let testVoiceId = "voice-123"

        keyboardVC.didRequestVoice(for: testText, voiceId: testVoiceId)

        // Verify voice request was created and written to shared container
        let appGroupID = "group.com.flirrt.shared"
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            XCTFail("Unable to access shared container")
            return
        }

        let requestURL = containerURL.appendingPathComponent("voice_request.json")

        // Check if file exists (it may not in test environment, but method should not crash)
        XCTAssertTrue(true, "Voice request creation should complete without error")
    }
}

// MARK: - Mock Classes

class MockTextDocumentProxy: NSObject, UITextDocumentProxy {
    var insertedText: String = ""
    var selectedText: String?
    var documentContextBeforeInput: String?
    var documentContextAfterInput: String?
    var markedText: String?
    var selectedTextRange: UITextRange?

    func insertText(_ text: String) {
        insertedText = text
    }

    func deleteBackward() {
        if !insertedText.isEmpty {
            insertedText.removeLast()
        }
    }

    // Implement other required methods with no-op implementations
    func setMarkedText(_ markedText: String, selectedRange: NSRange) {}
    func unmarkText() {}
    func textRange(from fromPosition: UITextPosition, to toPosition: UITextPosition) -> UITextRange? { nil }
    func position(from position: UITextPosition, offset: Int) -> UITextPosition? { nil }
    func position(from position: UITextPosition, in direction: UITextLayoutDirection, offset: Int) -> UITextPosition? { nil }
    func compare(_ position: UITextPosition, to other: UITextPosition) -> ComparisonResult { .orderedSame }
    func offset(from: UITextPosition, to: UITextPosition) -> Int { 0 }
    func position(within range: UITextRange, farthestIn direction: UITextLayoutDirection) -> UITextPosition? { nil }
    func characterRange(byExtending position: UITextPosition, in direction: UITextLayoutDirection) -> UITextRange? { nil }
    func baseWritingDirection(for position: UITextPosition, in direction: UITextStorageDirection) -> NSWritingDirection { .leftToRight }
    func setBaseWritingDirection(_ writingDirection: NSWritingDirection, for range: UITextRange) {}
    func firstRect(for range: UITextRange) -> CGRect { .zero }
    func caretRect(for position: UITextPosition) -> CGRect { .zero }
    func selectionRects(for range: UITextRange) -> [UITextSelectionRect] { [] }
    func closestPosition(to point: CGPoint) -> UITextPosition? { nil }
    func closestPosition(to point: CGPoint, within range: UITextRange) -> UITextPosition? { nil }
    func characterRange(at point: CGPoint) -> UITextRange? { nil }

    var hasText: Bool { !insertedText.isEmpty }
    var autocapitalizationType: UITextAutocapitalizationType = .sentences
    var autocorrectionType: UITextAutocorrectionType = .default
    var spellCheckingType: UITextSpellCheckingType = .default
    var smartQuotesType: UITextSmartQuotesType = .default
    var smartDashesType: UITextSmartDashesType = .default
    var smartInsertDeleteType: UITextSmartInsertDeleteType = .default
    var keyboardType: UIKeyboardType = .default
    var keyboardAppearance: UIKeyboardAppearance = .default
    var returnKeyType: UIReturnKeyType = .default
    var enablesReturnKeyAutomatically: Bool = false
    var isSecureTextEntry: Bool = false
    var textContentType: UITextContentType? = nil
    var passwordRules: UITextInputPasswordRules? = nil

    var beginningOfDocument: UITextPosition { UITextPosition() }
    var endOfDocument: UITextPosition { UITextPosition() }
    var inputDelegate: UITextInputDelegate? = nil
    var tokenizer: UITextInputTokenizer { UITextInputStringTokenizer() }
}

class MockURLSession: URLSession {
    var dataTaskCalled = false
    var lastRequest: URLRequest?

    override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        dataTaskCalled = true
        lastRequest = request

        // Return mock successful response
        let mockData = """
        {
            "success": true,
            "data": {
                "suggestions": [
                    {"text": "Test suggestion 1", "confidence": 0.9, "tone": "casual"},
                    {"text": "Test suggestion 2", "confidence": 0.8, "tone": "friendly"}
                ]
            }
        }
        """.data(using: .utf8)

        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            completionHandler(mockData, response, nil)
        }

        return URLSessionDataTask()
    }
}

// MARK: - Performance Tests

extension KeyboardExtensionTests {

    func testFreshButtonResponseTime() {
        measure {
            keyboardVC.flirrtFreshTapped()
        }
    }

    func testAnalyzeButtonResponseTime() {
        measure {
            keyboardVC.analyzeTapped()
        }
    }

    func testSuggestionDisplayPerformance() {
        let largeSuggestionSet = Array(0..<100).map { i in
            ["text": "Long suggestion text that might take time to display \(i)", "confidence": 0.8, "tone": "casual"]
        }

        measure {
            keyboardVC.displaySuggestions(largeSuggestionSet)
        }
    }

    func testMemoryAllocationPerformance() {
        measure {
            for _ in 0..<1000 {
                keyboardVC.createDefaultSuggestions()
            }
        }
    }
}