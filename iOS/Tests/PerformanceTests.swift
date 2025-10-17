import XCTest
import UIKit
import Foundation
import AVFoundation
import os.log
@testable import Flirrt

/// Comprehensive Performance Tests for Flirrt.ai
/// Benchmarks critical user-facing functionality for keyboard extension memory limits
/// Tests response times, memory usage, and performance under load
class PerformanceTests: XCTestCase {

    var keyboardVC: KeyboardViewController!
    var voiceManager: VoiceRecordingManager!
    var apiClient: APIClient!
    var sharedDataManager: SharedDataManager!
    var mockSession: MockURLSession!

    override func setUp() {
        super.setUp()
        keyboardVC = KeyboardViewController()
        keyboardVC.loadViewIfNeeded()

        voiceManager = VoiceRecordingManager()
        apiClient = APIClient(baseURL: "http://localhost:3000")
        sharedDataManager = SharedDataManager.shared
        mockSession = MockURLSession()
        apiClient.urlSession = mockSession

        // Setup mock successful responses
        mockSession.mockResponse = """
        {
            "success": true,
            "data": {
                "suggestions": [
                    {"id": "perf-1", "text": "Performance test suggestion 1", "confidence": 0.9},
                    {"id": "perf-2", "text": "Performance test suggestion 2", "confidence": 0.8},
                    {"id": "perf-3", "text": "Performance test suggestion 3", "confidence": 0.85}
                ]
            }
        }
        """.data(using: .utf8)
    }

    override func tearDown() {
        keyboardVC = nil
        voiceManager = nil
        apiClient = nil
        sharedDataManager = nil
        mockSession = nil
        super.tearDown()
    }

    // MARK: - Keyboard Extension Performance Tests

    func testKeyboardLaunchPerformance() {
        measure {
            let newKeyboard = KeyboardViewController()
            newKeyboard.loadViewIfNeeded()
            newKeyboard.viewDidLoad()
        }
    }

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
        let largeSuggestionSet = Array(0..<50).map { i in
            [
                "text": "Performance test suggestion \(i) with longer text to simulate real suggestions",
                "confidence": Double.random(in: 0.7...0.95),
                "tone": ["casual", "witty", "playful", "romantic"].randomElement()!
            ]
        }

        measure {
            keyboardVC.displaySuggestions(largeSuggestionSet)
        }
    }

    func testSuggestionSelectionPerformance() {
        // Setup suggestions first
        let testSuggestions = Array(0..<20).map { i in
            ["text": "Test suggestion \(i)", "confidence": 0.8, "tone": "casual"]
        }
        keyboardVC.displaySuggestions(testSuggestions)

        measure {
            keyboardVC.didSelectSuggestion("Test suggestion selected for performance")
        }
    }

    func testMemoryUsageDuringIntensiveOperations() {
        let initialMemory = getMemoryUsage()

        measure {
            // Perform intensive operations
            for i in 0..<100 {
                keyboardVC.flirrtFreshTapped()
                keyboardVC.analyzeTapped()

                let suggestions = [
                    ["text": "Memory test suggestion \(i)", "confidence": 0.8, "tone": "casual"]
                ]
                keyboardVC.displaySuggestions(suggestions)
                keyboardVC.didSelectSuggestion("Selected suggestion \(i)")
            }
        }

        let finalMemory = getMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        let memoryIncreaseMB = Double(memoryIncrease) / (1024 * 1024)

        XCTAssertLessThan(memoryIncreaseMB, 60.0, "Memory usage should stay under 60MB for keyboard extension")
        print("Memory increase during intensive operations: \(String(format: "%.2f", memoryIncreaseMB)) MB")
    }

    func testKeyboardConstraintCalculationPerformance() {
        measure {
            keyboardVC.view.setNeedsLayout()
            keyboardVC.view.layoutIfNeeded()
        }
    }

    func testCacheOperationPerformance() {
        let testSuggestions = Array(0..<50).map { i in
            ["text": "Cache test suggestion \(i)", "confidence": 0.8, "tone": "casual"]
        }

        measure {
            keyboardVC.cacheSuggestions(testSuggestions)
            let _ = keyboardVC.loadCachedSuggestions()
        }
    }

    // MARK: - API Performance Tests

    func testAPIRequestPerformance() {
        let expectation = self.expectation(description: "API request performance")

        measure {
            apiClient.generateFlirts(screenshotId: "perf-test", context: "performance testing") { result in
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 2.0)
        }
    }

    func testConcurrentAPIRequestsPerformance() {
        let expectation = self.expectation(description: "Concurrent API requests performance")
        expectation.expectedFulfillmentCount = 10

        measure {
            for i in 0..<10 {
                apiClient.generateFlirts(screenshotId: "concurrent-\(i)", context: "concurrent test") { result in
                    expectation.fulfill()
                }
            }
            wait(for: [expectation], timeout: 5.0)
        }
    }

    func testAPIResponseParsingPerformance() {
        let largeResponseData = createLargeAPIResponse()

        measure {
            do {
                let _ = try JSONSerialization.jsonObject(with: largeResponseData, options: [])
            } catch {
                XCTFail("JSON parsing should not fail: \(error)")
            }
        }
    }

    func testNetworkErrorRecoveryPerformance() {
        mockSession.shouldReturnError = true
        mockSession.mockError = NSError(domain: "TestError", code: -1009, userInfo: nil)

        measure {
            let expectation = self.expectation(description: "Error recovery performance")

            apiClient.generateFlirts(screenshotId: "error-test", context: "error recovery") { result in
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 1.0)
        }
    }

    // MARK: - Voice Recording Performance Tests

    func testVoiceRecordingStartupPerformance() {
        measure {
            let expectation = self.expectation(description: "Voice recording startup")

            Task {
                await voiceManager.startRecording()
                voiceManager.stopRecording()
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 3.0)
        }
    }

    func testAudioLevelCalculationPerformance() {
        let expectation = self.expectation(description: "Audio level calculation performance")

        Task {
            await voiceManager.startRecording()

            measure {
                // Simulate audio level calculations
                let levels = Array(0..<60).map { _ in Float.random(in: 0...1) }
                voiceManager.audioLevels = levels
            }

            voiceManager.stopRecording()
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 3.0)
    }

    func testVoicePlaybackPerformance() {
        let expectation = self.expectation(description: "Voice playback performance")

        Task {
            // Create a recording first
            await voiceManager.startRecording()
            try? await Task.sleep(nanoseconds: 6_000_000_000) // 6 seconds
            voiceManager.stopRecording()

            measure {
                voiceManager.startPlayback()
                voiceManager.stopPlayback()
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

    func testVoiceFileOperationsPerformance() {
        let expectation = self.expectation(description: "Voice file operations performance")

        Task {
            await voiceManager.startRecording()
            try? await Task.sleep(nanoseconds: 6_000_000_000) // 6 seconds
            voiceManager.stopRecording()

            measure {
                let _ = voiceManager.getRecordingData()
                let _ = voiceManager.getRecordingFileSize()
            }

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10.0)
    }

    // MARK: - Shared Data Management Performance Tests

    func testSharedDataReadPerformance() {
        measure {
            for _ in 0..<1000 {
                let _ = sharedDataManager.isUserAuthenticated()
                let _ = sharedDataManager.isVoiceEnabled()
                let _ = sharedDataManager.getLastScreenshotTime()
            }
        }
    }

    func testSharedDataWritePerformance() {
        measure {
            for i in 0..<1000 {
                sharedDataManager.setUserAuthenticated(i % 2 == 0)
                sharedDataManager.setVoiceEnabled(i % 3 == 0)
                sharedDataManager.setLastScreenshotTime(Date().timeIntervalSince1970)
            }
        }
    }

    func testNotificationSendingPerformance() {
        measure {
            for i in 0..<100 {
                if i % 2 == 0 {
                    sharedDataManager.requestScreenshotAnalysis()
                } else {
                    sharedDataManager.requestVoiceSynthesis(text: "Test \(i)", voiceId: "voice-\(i)")
                }
            }
        }
    }

    // MARK: - Memory Performance Tests

    func testMemoryAllocationPerformance() {
        measure {
            var objects: [Any] = []
            for i in 0..<10000 {
                let suggestion = ["text": "Memory test \(i)", "confidence": 0.8]
                objects.append(suggestion)
            }
            // Objects will be deallocated when this block ends
        }
    }

    func testMemoryDeallocationPerformance() {
        // Pre-allocate objects
        var objects: [Any] = []
        for i in 0..<10000 {
            let suggestion = ["text": "Deallocation test \(i)", "confidence": 0.8]
            objects.append(suggestion)
        }

        measure {
            objects.removeAll()
        }
    }

    func testLargeDataSetProcessingPerformance() {
        let largeDataSet = Array(0..<1000).map { i in
            [
                "id": "suggestion-\(i)",
                "text": "This is a performance test suggestion number \(i) with longer text content",
                "confidence": Double.random(in: 0.5...0.99),
                "tone": ["casual", "witty", "playful", "romantic", "bold"].randomElement()!,
                "reasoning": "This suggestion works because it demonstrates performance characteristics under load with suggestion \(i)",
                "metadata": [
                    "generated_at": Date().timeIntervalSince1970,
                    "algorithm_version": "v2.1",
                    "confidence_factors": ["profile_match", "conversation_flow", "tone_alignment"]
                ]
            ]
        }

        measure {
            keyboardVC.displaySuggestions(largeDataSet)
        }
    }

    // MARK: - Concurrency Performance Tests

    func testConcurrentOperationsPerformance() {
        measure {
            let group = DispatchGroup()

            // Simulate concurrent keyboard operations
            for i in 0..<20 {
                group.enter()
                DispatchQueue.global().async {
                    // Simulate user interactions
                    DispatchQueue.main.async {
                        self.keyboardVC.flirrtFreshTapped()
                        group.leave()
                    }
                }

                group.enter()
                DispatchQueue.global().async {
                    let _ = self.sharedDataManager.isUserAuthenticated()
                    group.leave()
                }
            }

            group.wait()
        }
    }

    func testHighContentionScenario() {
        let contentionQueue = DispatchQueue(label: "test.contention", attributes: .concurrent)
        let sharedResource = NSMutableArray()

        measure {
            let group = DispatchGroup()

            for i in 0..<100 {
                group.enter()
                contentionQueue.async {
                    sharedResource.add("Item \(i)")
                    group.leave()
                }

                group.enter()
                contentionQueue.async {
                    let _ = sharedResource.count
                    group.leave()
                }
            }

            group.wait()
        }
    }

    // MARK: - UI Performance Tests

    func testUIUpdatePerformance() {
        measure {
            for i in 0..<100 {
                DispatchQueue.main.async {
                    self.keyboardVC.view.backgroundColor = i % 2 == 0 ? .systemBackground : .secondarySystemBackground
                    self.keyboardVC.view.setNeedsDisplay()
                }
            }

            // Wait for UI updates to complete
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        }
    }

    func testComplexLayoutPerformance() {
        // Add many subviews to test layout performance
        let testViews = Array(0..<50).map { i in
            let view = UIView()
            view.backgroundColor = .systemGray
            view.translatesAutoresizingMaskIntoConstraints = false
            return view
        }

        for view in testViews {
            keyboardVC.view.addSubview(view)
        }

        measure {
            keyboardVC.view.setNeedsLayout()
            keyboardVC.view.layoutIfNeeded()
        }

        // Clean up
        testViews.forEach { $0.removeFromSuperview() }
    }

    // MARK: - Data Processing Performance Tests

    func testJSONSerializationPerformance() {
        let complexObject = createComplexDataStructure()

        measure {
            do {
                let _ = try JSONSerialization.data(withJSONObject: complexObject, options: [])
            } catch {
                XCTFail("JSON serialization should not fail: \(error)")
            }
        }
    }

    func testStringProcessingPerformance() {
        let longString = String(repeating: "Performance test string with emoji 😀 and unicode characters. ", count: 1000)

        measure {
            let _ = longString.count
            let _ = longString.uppercased()
            let _ = longString.components(separatedBy: " ")
        }
    }

    // MARK: - Network Performance Tests

    func testLargeResponseHandlingPerformance() {
        let largeResponse = createLargeAPIResponse(suggestionCount: 100)
        mockSession.mockResponseData = largeResponse

        measure {
            let expectation = self.expectation(description: "Large response handling")

            apiClient.generateFlirts(screenshotId: "large-response", context: "performance test") { result in
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 3.0)
        }
    }

    func testNetworkTimeoutHandlingPerformance() {
        mockSession.shouldReturnError = true
        mockSession.mockError = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil)

        measure {
            let expectation = self.expectation(description: "Timeout handling performance")

            apiClient.generateFlirts(screenshotId: "timeout-test", context: "timeout test") { result in
                expectation.fulfill()
            }

            wait(for: [expectation], timeout: 2.0)
        }
    }

    // MARK: - Stress Tests

    func testMemoryPressureRecovery() {
        let initialMemory = getMemoryUsage()

        measure {
            // Create memory pressure
            var largeObjects: [Data] = []
            for _ in 0..<100 {
                largeObjects.append(Data(count: 1024 * 1024)) // 1MB each
            }

            // Trigger memory warning simulation
            keyboardVC.handleMemoryWarning()

            // Release memory
            largeObjects.removeAll()

            // Force garbage collection
            autoreleasepool {
                // Empty pool to trigger cleanup
            }
        }

        let finalMemory = getMemoryUsage()
        let memoryDifference = abs(finalMemory - initialMemory)
        let memoryDifferenceMB = Double(memoryDifference) / (1024 * 1024)

        print("Memory difference after pressure test: \(String(format: "%.2f", memoryDifferenceMB)) MB")
    }

    func testRapidUserInteractionSimulation() {
        measure {
            // Simulate rapid user taps
            for _ in 0..<50 {
                keyboardVC.flirrtFreshTapped()
                keyboardVC.analyzeTapped()

                let suggestions = [
                    ["text": "Rapid interaction test", "confidence": 0.8, "tone": "casual"]
                ]
                keyboardVC.displaySuggestions(suggestions)
                keyboardVC.didSelectSuggestion("Rapid selection")
            }
        }
    }

    // MARK: - Helper Methods

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

    private func createLargeAPIResponse(suggestionCount: Int = 50) -> Data {
        let suggestions = Array(0..<suggestionCount).map { i in
            [
                "id": "large-response-\(i)",
                "text": "This is a large response suggestion \(i) with extended content to test performance under load",
                "confidence": Double.random(in: 0.7...0.95),
                "reasoning": "Extended reasoning for suggestion \(i) to increase response size and test parsing performance",
                "metadata": [
                    "generated_at": Date().timeIntervalSince1970,
                    "version": "v2.1.0",
                    "factors": ["profile_analysis", "conversation_context", "user_preferences"]
                ]
            ]
        }

        let responseObject = [
            "success": true,
            "data": [
                "suggestions": suggestions,
                "metadata": [
                    "total_suggestions": suggestionCount,
                    "generated_at": Date().timeIntervalSince1970,
                    "performance_test": true
                ]
            ]
        ] as [String: Any]

        return try! JSONSerialization.data(withJSONObject: responseObject, options: [])
    }

    private func createComplexDataStructure() -> [String: Any] {
        return [
            "users": Array(0..<100).map { i in
                [
                    "id": i,
                    "name": "User \(i)",
                    "preferences": [
                        "tone": ["casual", "witty", "playful"].randomElement()!,
                        "style": ["direct", "flirty", "romantic"].randomElement()!,
                        "topics": ["travel", "food", "movies", "music", "books"].shuffled().prefix(3)
                    ],
                    "history": Array(0..<10).map { j in
                        [
                            "suggestion_id": "hist-\(i)-\(j)",
                            "text": "Historical suggestion \(j) for user \(i)",
                            "rating": Double.random(in: 1...5),
                            "used": Bool.random()
                        ]
                    }
                ]
            },
            "metadata": [
                "generated_at": Date().timeIntervalSince1970,
                "version": "performance-test-v1.0",
                "test_parameters": [
                    "user_count": 100,
                    "history_per_user": 10,
                    "complexity_level": "high"
                ]
            ]
        ]
    }
}

// MARK: - Performance Benchmark Results

extension PerformanceTests {

    func testBenchmarkSummary() {
        print("\n=== PERFORMANCE BENCHMARK RESULTS ===")

        measureMetrics([
            XCTPerformanceMetric.wallClockTime,
            XCTMemoryMetric.physicalMemory
        ], automaticallyStartMeasuring: false) {

            // Keyboard operations
            startMeasuring()
            keyboardVC.flirrtFreshTapped()
            keyboardVC.analyzeTapped()

            let suggestions = [
                ["text": "Benchmark test suggestion", "confidence": 0.9, "tone": "casual"]
            ]
            keyboardVC.displaySuggestions(suggestions)
            keyboardVC.didSelectSuggestion("Benchmark selection")
            stopMeasuring()
        }

        let memoryUsage = getMemoryUsage()
        let memoryMB = Double(memoryUsage) / (1024 * 1024)

        print("Current memory usage: \(String(format: "%.2f", memoryMB)) MB")
        print("=== END BENCHMARK RESULTS ===\n")

        // Assert performance requirements
        XCTAssertLessThan(memoryMB, 60.0, "Memory usage should stay under 60MB for keyboard extension")
    }
}