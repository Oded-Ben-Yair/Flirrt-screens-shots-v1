//
//  FlirtFlowUITests.swift
//  FlirrtUITests (Vibe8)
//
//  UI tests for main flirt generation flow
//  Created by: QA Engineer Agent
//  Uses condition-based waiting (no arbitrary sleeps)
//

import XCTest

final class FlirtFlowUITests: XCTestCase {

    var app: XCUIApplication!

    // MARK: - Setup

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI-Testing"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Happy Path Tests

    func testCompleteFlirtGenerationFlow() throws {
        // Step 1: Tap screenshot analysis button
        let analyzeButton = app.buttons["analyzeScreenshotButton"]
        waitForElement(analyzeButton)
        analyzeButton.tap()

        // Step 2: Select image (mocked in UI testing mode)
        let selectImageButton = app.buttons["selectImageButton"]
        waitForElement(selectImageButton)
        selectImageButton.tap()

        // Step 3: Wait for tone selection screen
        let toneSelector = app.buttons["toneSelector"]
        waitForElement(toneSelector, timeout: 3.0)

        // Step 4: Select playful tone
        let playfulToneButton = app.buttons["tone_playful"]
        waitForElement(playfulToneButton)
        playfulToneButton.tap()

        // Step 5: Wait for flirts to load (condition-based wait)
        let firstFlirt = app.staticTexts["flirtText_0"]
        waitForElement(firstFlirt, timeout: 5.0)

        // Assert: Flirts are displayed
        XCTAssertTrue(firstFlirt.exists)
        XCTAssertTrue(app.staticTexts["flirtTone_0"].exists)
    }

    func testCopyFlirtToClipboard() throws {
        // Navigate to flirt results (reuse navigation helper)
        navigateToFlirtResults()

        // Tap copy button on first flirt
        let copyButton = app.buttons["copyButton_0"]
        waitForElement(copyButton)
        copyButton.tap()

        // Assert: "Copied!" confirmation appears
        let copiedLabel = app.staticTexts["Copied!"]
        waitForElement(copiedLabel, timeout: 2.0)
        XCTAssertTrue(copiedLabel.exists)
    }

    // MARK: - Error Handling Tests

    func testScreenshotAnalysisFailure() throws {
        // Simulate network error (via launch argument)
        app.launchArguments.append("SimulateNetworkError")
        app.launch()

        // Attempt screenshot analysis
        let analyzeButton = app.buttons["analyzeScreenshotButton"]
        waitForElement(analyzeButton)
        analyzeButton.tap()

        // Select image
        let selectImageButton = app.buttons["selectImageButton"]
        waitForElement(selectImageButton)
        selectImageButton.tap()

        // Assert: Error message appears
        let errorAlert = app.alerts["Error"]
        waitForElement(errorAlert, timeout: 5.0)
        XCTAssertTrue(errorAlert.exists)

        // Dismiss error
        errorAlert.buttons["OK"].tap()
    }

    // MARK: - Performance Tests

    func testAppLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }

        // Performance target: < 2 seconds
    }

    func testFlirtGenerationPerformance() throws {
        // Navigate to flirt generation
        navigateToFlirtResults()

        // Measure time for flirts to appear
        measure {
            let firstFlirt = app.staticTexts["flirtText_0"]
            _ = firstFlirt.waitForExistence(timeout: 5.0)
        }

        // Performance target: < 2 seconds
    }

    // MARK: - Accessibility Tests

    func testAccessibilityLabels() throws {
        // Main screen
        XCTAssertTrue(app.buttons["analyzeScreenshotButton"].isAccessibilityElement)

        // Navigate to flirt results
        navigateToFlirtResults()

        // Check flirt cards have accessibility labels
        let firstFlirt = app.staticTexts["flirtText_0"]
        waitForElement(firstFlirt)
        XCTAssertTrue(firstFlirt.isAccessibilityElement)
    }

    func testAccessibilityTouchTargets() throws {
        // All interactive elements should be >= 44x44 points
        let buttons = app.buttons.allElementsBoundByIndex

        for button in buttons where button.exists {
            let frame = button.frame
            XCTAssertGreaterThanOrEqual(frame.width, 44, "Button \(button.label) too narrow")
            XCTAssertGreaterThanOrEqual(frame.height, 44, "Button \(button.label) too short")
        }
    }

    // MARK: - Navigation Tests

    func testBackNavigation() throws {
        // Navigate to flirt results
        navigateToFlirtResults()

        // Tap back button
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        XCTAssertTrue(backButton.exists)
        backButton.tap()

        // Assert: Returned to previous screen
        let analyzeButton = app.buttons["analyzeScreenshotButton"]
        waitForElement(analyzeButton, timeout: 2.0)
        XCTAssertTrue(analyzeButton.exists)
    }

    // MARK: - Helper Methods

    private func navigateToFlirtResults() {
        let analyzeButton = app.buttons["analyzeScreenshotButton"]
        waitForElement(analyzeButton)
        analyzeButton.tap()

        let selectImageButton = app.buttons["selectImageButton"]
        waitForElement(selectImageButton)
        selectImageButton.tap()

        let playfulToneButton = app.buttons["tone_playful"]
        waitForElement(playfulToneButton, timeout: 3.0)
        playfulToneButton.tap()

        let firstFlirt = app.staticTexts["flirtText_0"]
        waitForElement(firstFlirt, timeout: 5.0)
    }

    private func waitForElement(
        _ element: XCUIElement,
        timeout: TimeInterval = 5.0,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let exists = element.waitForExistence(timeout: timeout)
        XCTAssertTrue(exists, "Element did not appear within \(timeout)s", file: file, line: line)
    }
}
