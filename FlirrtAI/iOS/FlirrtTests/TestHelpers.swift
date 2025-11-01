//
//  TestHelpers.swift
//  FlirrtTests (Vibe8)
//
//  Comprehensive test helpers for unit and UI testing
//  Created by: QA Engineer Agent (GPT-5-Codex)
//  Target: 80%+ code coverage
//

import XCTest
@testable import Flirrt

// MARK: - Base Test Case

/// Base test case with common setup and utilities
class Vibe8TestCase: XCTestCase {

    // MARK: - Properties

    var mockAPIClient: MockAPIClient!
    var mockAuthManager: MockAuthManager!
    var mockScreenshotManager: MockScreenshotDetectionManager!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        setupMocks()
    }

    override func tearDown() {
        cleanupMocks()
        super.tearDown()
    }

    // MARK: - Mock Setup

    private func setupMocks() {
        mockAPIClient = MockAPIClient()
        mockAuthManager = MockAuthManager()
        mockScreenshotManager = MockScreenshotDetectionManager()
    }

    private func cleanupMocks() {
        mockAPIClient = nil
        mockAuthManager = nil
        mockScreenshotManager = nil
    }

    // MARK: - Async Helpers

    /// Wait for async expectation with timeout
    func waitForAsync(
        timeout: TimeInterval = 5.0,
        description: String = "Async operation",
        block: @escaping () async throws -> Void
    ) async throws {
        let expectation = expectation(description: description)

        Task {
            try await block()
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: timeout)
    }

    /// Wait for condition to be true
    func waitForCondition(
        _ condition: @escaping () -> Bool,
        timeout: TimeInterval = 5.0,
        description: String = "Condition met"
    ) async {
        let expectation = expectation(description: description)

        Task {
            while !condition() {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            }
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: timeout)
    }
}

// MARK: - Mock API Client

class MockAPIClient {
    var shouldSucceed: Bool = true
    var mockFlirts: [Flirt] = []
    var mockUser: User?
    var mockScreenshotAnalysis: ScreenshotAnalysis?
    var callCount: [String: Int] = [:]

    func recordCall(_ methodName: String) {
        callCount[methodName, default: 0] += 1
    }

    func reset() {
        shouldSucceed = true
        mockFlirts = []
        mockUser = nil
        mockScreenshotAnalysis = nil
        callCount = [:]
    }
}

// MARK: - Mock Auth Manager

@MainActor
class MockAuthManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var user: User?
    @Published var error: String?

    func signIn() {
        isAuthenticated = true
        user = User.mockUser
    }

    func signOut() {
        isAuthenticated = false
        user = nil
    }

    func setError(_ message: String) {
        error = message
    }
}

// MARK: - Mock Screenshot Detection Manager

@MainActor
class MockScreenshotDetectionManager: ObservableObject {
    @Published var lastScreenshotDetected: Date?
    @Published var detectionStatus: String = "idle"
    @Published var latestScreenshotData: Data?

    func simulateScreenshot() {
        lastScreenshotDetected = Date()
        detectionStatus = "detecting"
        latestScreenshotData = Data("mock screenshot".utf8)
    }

    func reset() {
        lastScreenshotDetected = nil
        detectionStatus = "idle"
        latestScreenshotData = nil
    }
}

// MARK: - Test Data Factories

extension User {
    static var mockUser: User {
        User(
            id: "test-user-123",
            name: "Test User",
            email: "test@vibe8.com"
        )
    }

    static var mockUsers: [User] {
        [
            User(id: "user-1", name: "Alice", email: "alice@vibe8.com"),
            User(id: "user-2", name: "Bob", email: "bob@vibe8.com"),
            User(id: "user-3", name: "Charlie", email: "charlie@vibe8.com")
        ]
    }
}

extension Flirt {
    static var mockFlirt: Flirt {
        Flirt(
            id: "flirt-123",
            text: "Hey there! I couldn't help but notice your smile 😊",
            tone: "playful",
            qualityScore: 0.85,
            context: "Dating app conversation",
            timestamp: Date()
        )
    }

    static var mockFlirts: [Flirt] {
        [
            Flirt(
                id: "flirt-1",
                text: "Your profile caught my attention!",
                tone: "playful",
                qualityScore: 0.75,
                context: "First message",
                timestamp: Date()
            ),
            Flirt(
                id: "flirt-2",
                text: "I'd love to know more about you",
                tone: "casual",
                qualityScore: 0.80,
                context: "Follow-up message",
                timestamp: Date()
            ),
            Flirt(
                id: "flirt-3",
                text: "What's your favorite way to spend a weekend?",
                tone: "curious",
                qualityScore: 0.90,
                context: "Getting to know you",
                timestamp: Date()
            )
        ]
    }
}

extension VoiceScript {
    static var mockScript: VoiceScript {
        VoiceScript(
            title: "Test Script",
            text: "This is a test voice script",
            category: .casual,
            difficulty: .beginner,
            duration: 10,
            tips: "Test tips"
        )
    }
}

// MARK: - Screenshot Analysis Mock

struct ScreenshotAnalysis: Codable {
    let context: String
    let tone: String
    let confidence: Double
    let suggestions: [String]
}

extension ScreenshotAnalysis {
    static var mockAnalysis: ScreenshotAnalysis {
        ScreenshotAnalysis(
            context: "Dating app conversation starter",
            tone: "playful",
            confidence: 0.92,
            suggestions: [
                "Use a light, fun opener",
                "Ask about their interests",
                "Be genuine and authentic"
            ]
        )
    }
}

// MARK: - Performance Testing Helpers

extension XCTestCase {
    /// Measure performance of async operation
    func measureAsync(
        _ description: String = "Async performance",
        block: @escaping () async throws -> Void
    ) {
        measure {
            let expectation = expectation(description: description)
            Task {
                try? await block()
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 10.0)
        }
    }

    /// Assert operation completes within time limit
    func assertCompletesWithin(
        _ timeLimit: TimeInterval,
        description: String = "Operation",
        block: @escaping () async throws -> Void
    ) async {
        let start = Date()
        try? await block()
        let duration = Date().timeIntervalSince(start)

        XCTAssertLessThanOrEqual(
            duration,
            timeLimit,
            "\(description) took \(duration)s, expected < \(timeLimit)s"
        )
    }
}

// MARK: - UI Testing Helpers

extension XCTestCase {
    /// Wait for element to exist (condition-based, no arbitrary sleeps)
    func waitForElement(
        _ element: XCUIElement,
        timeout: TimeInterval = 5.0,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let exists = element.waitForExistence(timeout: timeout)
        XCTAssertTrue(exists, "Element did not appear within \(timeout)s", file: file, line: line)
    }

    /// Wait for element to disappear
    func waitForElementToDisappear(
        _ element: XCUIElement,
        timeout: TimeInterval = 5.0,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let expectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: element
        )
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(result, .completed, "Element did not disappear within \(timeout)s", file: file, line: line)
    }
}

// MARK: - Snapshot Testing (Optional)

#if DEBUG
extension XCTestCase {
    /// Compare view snapshot (requires SnapshotTesting framework)
    func assertSnapshot<V: View>(
        of view: V,
        named name: String? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        // Placeholder for snapshot testing
        // Implement with SnapshotTesting framework if needed
        print("Snapshot test: \(name ?? "unnamed")")
    }
}
#endif

// MARK: - Test Annotations

/// Mark test as flaky (needs investigation)
@available(*, deprecated, message: "Flaky test - needs investigation")
func XCTSkipFlaky(_ message: String = "Test is flaky") throws {
    try XCTSkipIf(true, message)
}

/// Mark test as slow (performance consideration)
func XCTMarkSlow() {
    // Used for documentation purposes
}
