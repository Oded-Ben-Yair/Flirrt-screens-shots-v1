import XCTest
import UIKit
import Foundation
import os.log
@testable import Flirrt

/// Comprehensive Performance Validation and Benchmarking Suite
/// Validates system performance against production requirements
/// Generates detailed performance reports with baseline comparisons
class PerformanceValidationSuite: XCTestCase {

    // MARK: - Performance Requirements

    struct PerformanceRequirements {
        // App Launch Performance
        static let maxAppLaunchTime: Double = 3.0 // seconds
        static let maxKeyboardLaunchTime: Double = 1.5 // seconds

        // Memory Requirements (iOS Keyboard Extension Limits)
        static let maxKeyboardMemoryUsage: Double = 50.0 // MB
        static let maxAppMemoryUsage: Double = 200.0 // MB
        static let maxMemoryLeakage: Double = 5.0 // MB per operation

        // Response Time Requirements
        static let maxAPIResponseTime: Double = 15.0 // seconds
        static let maxWebSocketResponseTime: Double = 0.2 // seconds
        static let maxUIResponseTime: Double = 0.1 // seconds

        // Network Performance
        static let maxImageUploadTime: Double = 10.0 // seconds
        static let maxImageCompressionTime: Double = 2.0 // seconds

        // Voice Performance
        static let maxVoiceRecordingStartup: Double = 1.0 // seconds
        static let maxVoiceProcessingTime: Double = 5.0 // seconds

        // Concurrency Performance
        static let maxConcurrentRequestTime: Double = 20.0 // seconds
        static let minConcurrentThroughput: Double = 5.0 // requests per second
    }

    // MARK: - Test Infrastructure

    var performanceReporter: PerformanceReporter!
    var benchmarkRunner: BenchmarkRunner!
    var memoryProfiler: MemoryProfiler!
    var networkProfiler: NetworkProfiler!

    var keyboardViewController: KeyboardViewController!
    var apiClient: APIClient!
    var voiceManager: VoiceRecordingManager!
    var sharedDataManager: SharedDataManager!

    override func setUp() {
        super.setUp()

        // Initialize performance monitoring
        performanceReporter = PerformanceReporter()
        benchmarkRunner = BenchmarkRunner()
        memoryProfiler = MemoryProfiler()
        networkProfiler = NetworkProfiler()

        // Initialize components under test
        keyboardViewController = KeyboardViewController()
        apiClient = APIClient(baseURL: "http://localhost:3000")
        voiceManager = VoiceRecordingManager()
        sharedDataManager = SharedDataManager.shared

        // Setup test environment
        setupPerformanceTestEnvironment()

        print("🚀 Performance Validation Suite Initialized")
    }

    override func tearDown() {
        generateComprehensivePerformanceReport()
        super.tearDown()
    }

    // MARK: - App Launch Performance Tests

    func testAppLaunchPerformance() {
        let testName = "AppLaunchPerformance"
        performanceReporter.startTest(testName)

        measure(metrics: [XCTCPUMetric(), XCTMemoryMetric()]) {
            let startTime = CFAbsoluteTimeGetCurrent()

            // Simulate app launch sequence
            let testApp = UIApplication.shared
            keyboardViewController.loadViewIfNeeded()
            keyboardViewController.viewDidLoad()
            keyboardViewController.viewWillAppear(false)
            keyboardViewController.viewDidAppear(false)

            let launchTime = CFAbsoluteTimeGetCurrent() - startTime
            performanceReporter.recordMetric("App Launch Time", value: launchTime, requirement: PerformanceRequirements.maxAppLaunchTime)
        }

        performanceReporter.endTest(testName)
        print("✅ App launch performance test completed")
    }

    func testKeyboardExtensionLaunchPerformance() {
        let testName = "KeyboardLaunchPerformance"
        performanceReporter.startTest(testName)

        measureMetrics([XCTPerformanceMetric.wallClockTime], automaticallyStartMeasuring: false) {
            startMeasuring()

            // Simulate keyboard extension launch
            let keyboard = KeyboardViewController()
            keyboard.loadViewIfNeeded()
            keyboard.viewDidLoad()

            // Simulate text document proxy setup
            keyboard.setupKeyboardInterface()

            stopMeasuring()

            let memoryUsage = memoryProfiler.getCurrentMemoryUsage()
            performanceReporter.recordMetric("Keyboard Memory Usage", value: memoryUsage, requirement: PerformanceRequirements.maxKeyboardMemoryUsage)
        }

        performanceReporter.endTest(testName)
        print("✅ Keyboard extension launch performance test completed")
    }

    // MARK: - Memory Performance Tests

    func testMemoryUsageUnderLoad() {
        let testName = "MemoryUsageUnderLoad"
        performanceReporter.startTest(testName)
        memoryProfiler.startProfiling()

        let initialMemory = memoryProfiler.getCurrentMemoryUsage()

        // Simulate intensive operations
        for i in 0..<100 {
            autoreleasepool {
                // Create and process suggestions
                let suggestions = generateTestSuggestions(count: 10)
                keyboardViewController.displaySuggestions(suggestions)

                // Simulate image processing
                let testImage = createTestImage(size: CGSize(width: 1920, height: 1080))
                let _ = testImage.jpegData(compressionQuality: 0.8)

                // Simulate network requests
                apiClient.generateFlirts(screenshotId: "test-\(i)", context: "memory test") { _ in }

                if i % 10 == 0 {
                    let currentMemory = memoryProfiler.getCurrentMemoryUsage()
                    performanceReporter.recordMetric("Memory Usage at \(i)", value: currentMemory)
                }
            }
        }

        let finalMemory = memoryProfiler.getCurrentMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory

        performanceReporter.recordMetric("Memory Increase", value: memoryIncrease, requirement: PerformanceRequirements.maxMemoryLeakage * 100)
        performanceReporter.recordMetric("Final Memory Usage", value: finalMemory, requirement: PerformanceRequirements.maxAppMemoryUsage)

        memoryProfiler.stopProfiling()
        performanceReporter.endTest(testName)

        XCTAssertLessThan(memoryIncrease, PerformanceRequirements.maxMemoryLeakage * 100, "Memory leakage should be minimal")
        print("✅ Memory usage under load test completed")
    }

    func testMemoryPressureRecovery() {
        let testName = "MemoryPressureRecovery"
        performanceReporter.startTest(testName)

        let initialMemory = memoryProfiler.getCurrentMemoryUsage()

        // Create memory pressure
        var largeObjects: [Data] = []
        for _ in 0..<50 {
            largeObjects.append(Data(count: 2 * 1024 * 1024)) // 2MB each
        }

        let peakMemory = memoryProfiler.getCurrentMemoryUsage()

        // Trigger memory warning
        keyboardViewController.handleMemoryWarning()

        // Release memory
        largeObjects.removeAll()

        // Force garbage collection
        autoreleasepool {}

        // Wait for memory to stabilize
        Thread.sleep(forTimeInterval: 2.0)

        let recoveredMemory = memoryProfiler.getCurrentMemoryUsage()
        let recoveryRatio = (peakMemory - recoveredMemory) / (peakMemory - initialMemory)

        performanceReporter.recordMetric("Memory Recovery Ratio", value: recoveryRatio)
        performanceReporter.recordMetric("Final Memory After Recovery", value: recoveredMemory)

        performanceReporter.endTest(testName)

        XCTAssertGreaterThan(recoveryRatio, 0.8, "Should recover at least 80% of allocated memory")
        print("✅ Memory pressure recovery test completed")
    }

    // MARK: - Network Performance Tests

    func testAPIResponsePerformance() {
        let testName = "APIResponsePerformance"
        performanceReporter.startTest(testName)
        networkProfiler.startProfiling()

        let expectation = self.expectation(description: "API response performance")
        expectation.expectedFulfillmentCount = 5

        var responseTimes: [Double] = []

        for i in 0..<5 {
            let startTime = CFAbsoluteTimeGetCurrent()

            apiClient.generateFlirts(screenshotId: "performance-test-\(i)", context: "performance testing") { result in
                let responseTime = CFAbsoluteTimeGetCurrent() - startTime
                responseTimes.append(responseTime)

                self.performanceReporter.recordMetric("API Response \(i)", value: responseTime, requirement: PerformanceRequirements.maxAPIResponseTime)

                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 30.0)

        let averageResponseTime = responseTimes.reduce(0, +) / Double(responseTimes.count)
        let maxResponseTime = responseTimes.max() ?? 0
        let minResponseTime = responseTimes.min() ?? 0

        performanceReporter.recordMetric("Average API Response Time", value: averageResponseTime, requirement: PerformanceRequirements.maxAPIResponseTime)
        performanceReporter.recordMetric("Max API Response Time", value: maxResponseTime, requirement: PerformanceRequirements.maxAPIResponseTime)
        performanceReporter.recordMetric("Min API Response Time", value: minResponseTime)

        networkProfiler.stopProfiling()
        performanceReporter.endTest(testName)

        XCTAssertLessThan(averageResponseTime, PerformanceRequirements.maxAPIResponseTime, "Average API response time should meet requirements")
        print("✅ API response performance test completed")
    }

    func testImageUploadPerformance() {
        let testName = "ImageUploadPerformance"
        performanceReporter.startTest(testName)

        let imageSizes = [
            ("Small", CGSize(width: 375, height: 812)),
            ("Medium", CGSize(width: 750, height: 1624)),
            ("Large", CGSize(width: 1125, height: 2436)),
            ("XLarge", CGSize(width: 1500, height: 3248))
        ]

        for (sizeLabel, size) in imageSizes {
            let testImage = createTestImage(size: size)

            measure {
                let startTime = CFAbsoluteTimeGetCurrent()

                let imageData = testImage.jpegData(compressionQuality: 0.8)!

                let compressionTime = CFAbsoluteTimeGetCurrent() - startTime
                performanceReporter.recordMetric("\(sizeLabel) Image Compression Time", value: compressionTime, requirement: PerformanceRequirements.maxImageCompressionTime)

                // Simulate upload
                let uploadStartTime = CFAbsoluteTimeGetCurrent()
                apiClient.uploadScreenshot(imageData: imageData, context: "performance test") { result in
                    let uploadTime = CFAbsoluteTimeGetCurrent() - uploadStartTime
                    self.performanceReporter.recordMetric("\(sizeLabel) Image Upload Time", value: uploadTime, requirement: PerformanceRequirements.maxImageUploadTime)
                }
            }
        }

        performanceReporter.endTest(testName)
        print("✅ Image upload performance test completed")
    }

    func testConcurrentRequestPerformance() {
        let testName = "ConcurrentRequestPerformance"
        performanceReporter.startTest(testName)

        let concurrentRequestCount = 10
        let expectation = self.expectation(description: "Concurrent requests")
        expectation.expectedFulfillmentCount = concurrentRequestCount

        let startTime = CFAbsoluteTimeGetCurrent()
        var completedRequests = 0
        let completedRequestsLock = NSLock()

        for i in 0..<concurrentRequestCount {
            DispatchQueue.global().async {
                let requestStartTime = CFAbsoluteTimeGetCurrent()

                self.apiClient.generateFlirts(screenshotId: "concurrent-\(i)", context: "concurrent test") { result in
                    let requestTime = CFAbsoluteTimeGetCurrent() - requestStartTime

                    completedRequestsLock.lock()
                    completedRequests += 1
                    let currentCount = completedRequests
                    completedRequestsLock.unlock()

                    self.performanceReporter.recordMetric("Concurrent Request \(i) Time", value: requestTime)

                    expectation.fulfill()
                }
            }
        }

        waitForExpectations(timeout: 40.0)

        let totalTime = CFAbsoluteTimeGetCurrent() - startTime
        let throughput = Double(concurrentRequestCount) / totalTime

        performanceReporter.recordMetric("Concurrent Request Total Time", value: totalTime, requirement: PerformanceRequirements.maxConcurrentRequestTime)
        performanceReporter.recordMetric("Request Throughput", value: throughput, requirement: PerformanceRequirements.minConcurrentThroughput)

        performanceReporter.endTest(testName)

        XCTAssertLessThan(totalTime, PerformanceRequirements.maxConcurrentRequestTime, "Concurrent requests should complete within time limit")
        XCTAssertGreaterThan(throughput, PerformanceRequirements.minConcurrentThroughput, "Should maintain minimum throughput")

        print("✅ Concurrent request performance test completed")
    }

    // MARK: - Voice Performance Tests

    func testVoiceRecordingPerformance() {
        let testName = "VoiceRecordingPerformance"
        performanceReporter.startTest(testName)

        let expectation = self.expectation(description: "Voice recording performance")

        measure {
            let startTime = CFAbsoluteTimeGetCurrent()

            Task {
                await self.voiceManager.startRecording()

                let startupTime = CFAbsoluteTimeGetCurrent() - startTime
                self.performanceReporter.recordMetric("Voice Recording Startup", value: startupTime, requirement: PerformanceRequirements.maxVoiceRecordingStartup)

                // Record for 5 seconds
                try? await Task.sleep(nanoseconds: 5_000_000_000)

                let processingStartTime = CFAbsoluteTimeGetCurrent()
                self.voiceManager.stopRecording()

                let audioData = self.voiceManager.getRecordingData()
                let processingTime = CFAbsoluteTimeGetCurrent() - processingStartTime

                self.performanceReporter.recordMetric("Voice Processing Time", value: processingTime, requirement: PerformanceRequirements.maxVoiceProcessingTime)
                self.performanceReporter.recordMetric("Audio Data Size", value: Double(audioData.count))

                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 15.0)
        performanceReporter.endTest(testName)
        print("✅ Voice recording performance test completed")
    }

    // MARK: - UI Performance Tests

    func testUIResponsePerformance() {
        let testName = "UIResponsePerformance"
        performanceReporter.startTest(testName)

        keyboardViewController.loadViewIfNeeded()

        // Test button response times
        let buttons = ["Fresh", "Analyze", "Settings"]
        for buttonName in buttons {
            measure {
                let startTime = CFAbsoluteTimeGetCurrent()

                switch buttonName {
                case "Fresh":
                    keyboardViewController.flirrtFreshTapped()
                case "Analyze":
                    keyboardViewController.analyzeTapped()
                case "Settings":
                    keyboardViewController.settingsTapped()
                default:
                    break
                }

                let responseTime = CFAbsoluteTimeGetCurrent() - startTime
                performanceReporter.recordMetric("\(buttonName) Button Response", value: responseTime, requirement: PerformanceRequirements.maxUIResponseTime)
            }
        }

        // Test suggestion display performance
        let largeSuggestionSet = generateTestSuggestions(count: 50)

        measure {
            let startTime = CFAbsoluteTimeGetCurrent()

            keyboardViewController.displaySuggestions(largeSuggestionSet)

            let displayTime = CFAbsoluteTimeGetCurrent() - startTime
            performanceReporter.recordMetric("Large Suggestion Display", value: displayTime, requirement: PerformanceRequirements.maxUIResponseTime * 10) // Allow more time for large sets
        }

        performanceReporter.endTest(testName)
        print("✅ UI response performance test completed")
    }

    func testScrollPerformance() {
        let testName = "ScrollPerformance"
        performanceReporter.startTest(testName)

        // Create a large number of suggestions to test scrolling
        let suggestions = generateTestSuggestions(count: 100)
        keyboardViewController.displaySuggestions(suggestions)

        measure {
            // Simulate scrolling through suggestions
            for i in 0..<20 {
                keyboardViewController.scrollToSuggestion(at: i)
            }
        }

        performanceReporter.endTest(testName)
        print("✅ Scroll performance test completed")
    }

    // MARK: - Data Processing Performance Tests

    func testJSONProcessingPerformance() {
        let testName = "JSONProcessingPerformance"
        performanceReporter.startTest(testName)

        let largeJSONData = createLargeJSONResponse(suggestionCount: 1000)

        measure {
            do {
                let startTime = CFAbsoluteTimeGetCurrent()

                let jsonObject = try JSONSerialization.jsonObject(with: largeJSONData, options: [])

                let parseTime = CFAbsoluteTimeGetCurrent() - startTime
                performanceReporter.recordMetric("Large JSON Parse Time", value: parseTime)

                // Test serialization back
                let serializeStartTime = CFAbsoluteTimeGetCurrent()
                let _ = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
                let serializeTime = CFAbsoluteTimeGetCurrent() - serializeStartTime

                performanceReporter.recordMetric("Large JSON Serialize Time", value: serializeTime)
            } catch {
                XCTFail("JSON processing should not fail: \(error)")
            }
        }

        performanceReporter.endTest(testName)
        print("✅ JSON processing performance test completed")
    }

    func testImageCompressionPerformance() {
        let testName = "ImageCompressionPerformance"
        performanceReporter.startTest(testName)

        let compressionQualities: [CGFloat] = [1.0, 0.8, 0.6, 0.4, 0.2]
        let testImage = createTestImage(size: CGSize(width: 2000, height: 2000))

        for quality in compressionQualities {
            measure {
                let startTime = CFAbsoluteTimeGetCurrent()

                let compressedData = testImage.jpegData(compressionQuality: quality)!

                let compressionTime = CFAbsoluteTimeGetCurrent() - startTime
                let compressionRatio = Double(compressedData.count) / Double(testImage.pngData()?.count ?? 1)

                performanceReporter.recordMetric("Compression Time Q\(quality)", value: compressionTime)
                performanceReporter.recordMetric("Compression Ratio Q\(quality)", value: compressionRatio)
            }
        }

        performanceReporter.endTest(testName)
        print("✅ Image compression performance test completed")
    }

    // MARK: - Stress Tests

    func testSystemStressTest() {
        let testName = "SystemStressTest"
        performanceReporter.startTest(testName)

        let initialMemory = memoryProfiler.getCurrentMemoryUsage()
        let stressTestDuration: TimeInterval = 30.0 // 30 seconds
        let startTime = CFAbsoluteTimeGetCurrent()

        var operationCount = 0

        while CFAbsoluteTimeGetCurrent() - startTime < stressTestDuration {
            autoreleasepool {
                // Simulate various operations
                operationCount += 1

                // UI operations
                let suggestions = generateTestSuggestions(count: 5)
                keyboardViewController.displaySuggestions(suggestions)

                // Memory operations
                let testImage = createTestImage(size: CGSize(width: 500, height: 500))
                let _ = testImage.jpegData(compressionQuality: 0.8)

                // Network simulation
                apiClient.generateFlirts(screenshotId: "stress-\(operationCount)", context: "stress test") { _ in }

                if operationCount % 10 == 0 {
                    let currentMemory = memoryProfiler.getCurrentMemoryUsage()
                    performanceReporter.recordMetric("Stress Test Memory \(operationCount)", value: currentMemory)
                }
            }
        }

        let finalMemory = memoryProfiler.getCurrentMemoryUsage()
        let memoryGrowth = finalMemory - initialMemory
        let operationsPerSecond = Double(operationCount) / stressTestDuration

        performanceReporter.recordMetric("Stress Test Operations", value: Double(operationCount))
        performanceReporter.recordMetric("Operations Per Second", value: operationsPerSecond)
        performanceReporter.recordMetric("Memory Growth Under Stress", value: memoryGrowth)

        performanceReporter.endTest(testName)

        XCTAssertLessThan(memoryGrowth, 50.0, "Memory growth should be reasonable under stress")
        print("✅ System stress test completed - \(operationCount) operations in \(stressTestDuration)s")
    }

    // MARK: - Benchmark Comparison Tests

    func testPerformanceBaselines() {
        let testName = "PerformanceBaselines"
        performanceReporter.startTest(testName)

        // Establish baselines for core operations
        let baselineTests = [
            ("Basic UI Operation", { self.keyboardViewController.flirrtFreshTapped() }),
            ("Memory Allocation", { let _ = Data(count: 1024 * 1024) }),
            ("Image Creation", { let _ = self.createTestImage(size: CGSize(width: 100, height: 100)) }),
            ("JSON Parsing", {
                let data = "{\"test\": \"value\"}".data(using: .utf8)!
                let _ = try? JSONSerialization.jsonObject(with: data)
            }),
            ("String Processing", {
                let string = "Performance baseline test string"
                let _ = string.uppercased()
                let _ = string.components(separatedBy: " ")
            })
        ]

        for (testName, operation) in baselineTests {
            let times = benchmarkRunner.runBenchmark(testName, iterations: 100, operation: operation)
            let averageTime = times.reduce(0, +) / Double(times.count)
            let maxTime = times.max() ?? 0
            let minTime = times.min() ?? 0

            performanceReporter.recordMetric("\(testName) Average", value: averageTime)
            performanceReporter.recordMetric("\(testName) Max", value: maxTime)
            performanceReporter.recordMetric("\(testName) Min", value: minTime)
        }

        performanceReporter.endTest(testName)
        print("✅ Performance baselines established")
    }

    // MARK: - Helper Methods

    private func setupPerformanceTestEnvironment() {
        // Configure for optimal performance testing
        performanceReporter.setBaselineFile("/Users/macbookairm1/Flirrt-screens-shots-v1/FlirrtAI/TestResults/performance_baselines.json")
        memoryProfiler.setReportingInterval(0.1)
        networkProfiler.setTimeoutThreshold(30.0)
    }

    private func generateTestSuggestions(count: Int) -> [[String: Any]] {
        return Array(0..<count).map { i in
            [
                "id": "perf-suggestion-\(i)",
                "text": "Performance test suggestion \(i) with sample content",
                "confidence": Double.random(in: 0.7...0.95),
                "tone": ["casual", "witty", "playful", "romantic"].randomElement()!
            ]
        }
    }

    private func createTestImage(size: CGSize) -> UIImage {
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(UIColor.systemBlue.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }

    private func createLargeJSONResponse(suggestionCount: Int) -> Data {
        let suggestions = Array(0..<suggestionCount).map { i in
            [
                "id": "large-response-\(i)",
                "text": "Large response suggestion \(i) with extended content",
                "confidence": Double.random(in: 0.7...0.95),
                "reasoning": "Extended reasoning for suggestion \(i)",
                "metadata": [
                    "generated_at": Date().timeIntervalSince1970,
                    "version": "performance-test-v1.0"
                ]
            ]
        }

        let responseObject = [
            "success": true,
            "data": [
                "suggestions": suggestions,
                "metadata": [
                    "total_suggestions": suggestionCount,
                    "performance_test": true
                ]
            ]
        ] as [String: Any]

        return try! JSONSerialization.data(withJSONObject: responseObject, options: [])
    }

    private func generateComprehensivePerformanceReport() {
        performanceReporter.generateComprehensiveReport()
        memoryProfiler.generateMemoryReport()
        networkProfiler.generateNetworkReport()
        benchmarkRunner.generateBenchmarkReport()

        print("📊 Comprehensive performance report generated")
    }
}

// MARK: - Performance Monitoring Classes

class PerformanceReporter {
    private var testResults: [String: [PerformanceMetric]] = [:]
    private var currentTest: String?
    private var baselineFile: String?

    struct PerformanceMetric {
        let name: String
        let value: Double
        let unit: String
        let timestamp: Date
        let requirement: Double?
        let passed: Bool

        init(name: String, value: Double, unit: String = "seconds", requirement: Double? = nil) {
            self.name = name
            self.value = value
            self.unit = unit
            self.timestamp = Date()
            self.requirement = requirement
            self.passed = requirement == nil || value <= requirement
        }
    }

    func startTest(_ testName: String) {
        currentTest = testName
        testResults[testName] = []
        print("📊 Started performance test: \(testName)")
    }

    func recordMetric(_ name: String, value: Double, unit: String = "seconds", requirement: Double? = nil) {
        let metric = PerformanceMetric(name: name, value: value, unit: unit, requirement: requirement)

        if let test = currentTest {
            testResults[test, default: []].append(metric)
        }

        let status = metric.passed ? "✅" : "❌"
        let requirementText = requirement.map { " (req: \($0) \(unit))" } ?? ""
        print("📈 \(status) \(name): \(String(format: "%.3f", value)) \(unit)\(requirementText)")
    }

    func endTest(_ testName: String) {
        if let metrics = testResults[testName] {
            let passedCount = metrics.filter { $0.passed }.count
            let totalCount = metrics.count
            let passRate = Double(passedCount) / Double(totalCount) * 100

            print("📊 Completed performance test: \(testName) - \(passedCount)/\(totalCount) passed (\(String(format: "%.1f", passRate))%)")
        }
        currentTest = nil
    }

    func setBaselineFile(_ path: String) {
        baselineFile = path
    }

    func generateComprehensiveReport() {
        let timestamp = DateFormatter.full.string(from: Date())
        let reportPath = "/Users/macbookairm1/Flirrt-screens-shots-v1/FlirrtAI/TestResults/performance_validation_report.md"

        var report = """
        # Performance Validation Report

        **Generated**: \(timestamp)
        **Test Suite**: Comprehensive Performance Validation

        ## Executive Summary

        """

        var totalTests = 0
        var passedTests = 0
        var totalMetrics = 0
        var passedMetrics = 0

        for (testName, metrics) in testResults {
            totalTests += 1
            let testPassed = metrics.allSatisfy { $0.passed }
            if testPassed { passedTests += 1 }

            totalMetrics += metrics.count
            passedMetrics += metrics.filter { $0.passed }.count
        }

        let testPassRate = Double(passedTests) / Double(totalTests) * 100
        let metricPassRate = Double(passedMetrics) / Double(totalMetrics) * 100

        report += """
        - **Total Test Categories**: \(totalTests)
        - **Passed Test Categories**: \(passedTests)
        - **Test Pass Rate**: \(String(format: "%.1f", testPassRate))%
        - **Total Metrics**: \(totalMetrics)
        - **Passed Metrics**: \(passedMetrics)
        - **Metric Pass Rate**: \(String(format: "%.1f", metricPassRate))%

        ## Performance Requirements Compliance

        """

        // Add requirements table
        report += generateRequirementsTable()

        report += "\n## Detailed Test Results\n\n"

        for (testName, metrics) in testResults.sorted(by: { $0.key < $1.key }) {
            report += "### \(testName)\n\n"

            for metric in metrics {
                let status = metric.passed ? "✅" : "❌"
                let requirementText = metric.requirement.map { " / \($0)" } ?? ""
                report += "- \(status) **\(metric.name)**: \(String(format: "%.3f", metric.value))\(requirementText) \(metric.unit)\n"
            }

            report += "\n"
        }

        try? report.write(to: URL(fileURLWithPath: reportPath), atomically: true, encoding: .utf8)
        print("📊 Performance validation report saved to: \(reportPath)")
    }

    private func generateRequirementsTable() -> String {
        var table = """
        | Requirement | Target | Status |
        |-------------|--------|--------|
        | App Launch Time | ≤ \(PerformanceRequirements.maxAppLaunchTime)s | \(getRequirementStatus("App Launch Time")) |
        | Keyboard Memory Usage | ≤ \(PerformanceRequirements.maxKeyboardMemoryUsage)MB | \(getRequirementStatus("Keyboard Memory Usage")) |
        | API Response Time | ≤ \(PerformanceRequirements.maxAPIResponseTime)s | \(getRequirementStatus("Average API Response Time")) |
        | UI Response Time | ≤ \(PerformanceRequirements.maxUIResponseTime)s | \(getRequirementStatus("Fresh Button Response")) |
        | Voice Recording Startup | ≤ \(PerformanceRequirements.maxVoiceRecordingStartup)s | \(getRequirementStatus("Voice Recording Startup")) |

        """
        return table
    }

    private func getRequirementStatus(_ metricName: String) -> String {
        for metrics in testResults.values {
            if let metric = metrics.first(where: { $0.name.contains(metricName) }) {
                return metric.passed ? "✅ PASS" : "❌ FAIL"
            }
        }
        return "❓ N/A"
    }
}

class BenchmarkRunner {
    private var benchmarkResults: [String: [Double]] = [:]

    func runBenchmark(_ name: String, iterations: Int, operation: () -> Void) -> [Double] {
        var times: [Double] = []

        for _ in 0..<iterations {
            let startTime = CFAbsoluteTimeGetCurrent()
            operation()
            let endTime = CFAbsoluteTimeGetCurrent()
            times.append(endTime - startTime)
        }

        benchmarkResults[name] = times
        return times
    }

    func generateBenchmarkReport() {
        let reportPath = "/Users/macbookairm1/Flirrt-screens-shots-v1/FlirrtAI/TestResults/benchmark_report.md"

        var report = """
        # Benchmark Report

        **Generated**: \(DateFormatter.full.string(from: Date()))

        ## Benchmark Results

        """

        for (name, times) in benchmarkResults.sorted(by: { $0.key < $1.key }) {
            let average = times.reduce(0, +) / Double(times.count)
            let min = times.min() ?? 0
            let max = times.max() ?? 0
            let median = times.sorted()[times.count / 2]

            report += """
            ### \(name)

            - **Iterations**: \(times.count)
            - **Average**: \(String(format: "%.6f", average))s
            - **Median**: \(String(format: "%.6f", median))s
            - **Min**: \(String(format: "%.6f", min))s
            - **Max**: \(String(format: "%.6f", max))s

            """
        }

        try? report.write(to: URL(fileURLWithPath: reportPath), atomically: true, encoding: .utf8)
    }
}

class MemoryProfiler {
    private var memorySnapshots: [(timestamp: Date, usage: Double)] = []
    private var reportingInterval: TimeInterval = 1.0
    private var profilingTimer: Timer?

    func startProfiling() {
        memorySnapshots.removeAll()
        profilingTimer = Timer.scheduledTimer(withTimeInterval: reportingInterval, repeats: true) { _ in
            let usage = self.getCurrentMemoryUsage()
            self.memorySnapshots.append((timestamp: Date(), usage: usage))
        }
    }

    func stopProfiling() {
        profilingTimer?.invalidate()
        profilingTimer = nil
    }

    func getCurrentMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        return result == KERN_SUCCESS ? Double(info.resident_size) / (1024 * 1024) : 0
    }

    func setReportingInterval(_ interval: TimeInterval) {
        reportingInterval = interval
    }

    func generateMemoryReport() {
        guard !memorySnapshots.isEmpty else { return }

        let reportPath = "/Users/macbookairm1/Flirrt-screens-shots-v1/FlirrtAI/TestResults/memory_profile_report.md"

        let maxUsage = memorySnapshots.map { $0.usage }.max() ?? 0
        let minUsage = memorySnapshots.map { $0.usage }.min() ?? 0
        let avgUsage = memorySnapshots.map { $0.usage }.reduce(0, +) / Double(memorySnapshots.count)

        var report = """
        # Memory Profile Report

        **Generated**: \(DateFormatter.full.string(from: Date()))
        **Profiling Duration**: \(memorySnapshots.count * Int(reportingInterval)) seconds
        **Sample Count**: \(memorySnapshots.count)

        ## Memory Usage Statistics

        - **Peak Usage**: \(String(format: "%.2f", maxUsage)) MB
        - **Minimum Usage**: \(String(format: "%.2f", minUsage)) MB
        - **Average Usage**: \(String(format: "%.2f", avgUsage)) MB
        - **Memory Range**: \(String(format: "%.2f", maxUsage - minUsage)) MB

        ## Memory Timeline

        | Timestamp | Usage (MB) |
        |-----------|------------|
        """

        for snapshot in memorySnapshots.prefix(20) { // Show first 20 samples
            let timeString = DateFormatter.timestamp.string(from: snapshot.timestamp)
            report += "\n| \(timeString) | \(String(format: "%.2f", snapshot.usage)) |"
        }

        if memorySnapshots.count > 20 {
            report += "\n| ... | ... |"
        }

        try? report.write(to: URL(fileURLWithPath: reportPath), atomically: true, encoding: .utf8)
    }
}

class NetworkProfiler {
    private var networkEvents: [NetworkEvent] = []
    private var timeoutThreshold: TimeInterval = 30.0

    struct NetworkEvent {
        let timestamp: Date
        let url: String
        let method: String
        let responseTime: TimeInterval
        let success: Bool
        let dataSize: Int
    }

    func startProfiling() {
        networkEvents.removeAll()
    }

    func stopProfiling() {
        // Profiling stopped
    }

    func recordNetworkEvent(url: String, method: String, responseTime: TimeInterval, success: Bool, dataSize: Int) {
        let event = NetworkEvent(
            timestamp: Date(),
            url: url,
            method: method,
            responseTime: responseTime,
            success: success,
            dataSize: dataSize
        )
        networkEvents.append(event)
    }

    func setTimeoutThreshold(_ threshold: TimeInterval) {
        timeoutThreshold = threshold
    }

    func generateNetworkReport() {
        let reportPath = "/Users/macbookairm1/Flirrt-screens-shots-v1/FlirrtAI/TestResults/network_profile_report.md"

        let successfulRequests = networkEvents.filter { $0.success }
        let averageResponseTime = successfulRequests.isEmpty ? 0 : successfulRequests.map { $0.responseTime }.reduce(0, +) / Double(successfulRequests.count)
        let totalDataTransferred = networkEvents.map { $0.dataSize }.reduce(0, +)

        var report = """
        # Network Profile Report

        **Generated**: \(DateFormatter.full.string(from: Date()))

        ## Network Statistics

        - **Total Requests**: \(networkEvents.count)
        - **Successful Requests**: \(successfulRequests.count)
        - **Failed Requests**: \(networkEvents.count - successfulRequests.count)
        - **Success Rate**: \(String(format: "%.1f", Double(successfulRequests.count) / Double(networkEvents.count) * 100))%
        - **Average Response Time**: \(String(format: "%.3f", averageResponseTime))s
        - **Total Data Transferred**: \(totalDataTransferred) bytes

        """

        try? report.write(to: URL(fileURLWithPath: reportPath), atomically: true, encoding: .utf8)
    }
}