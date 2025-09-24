import XCTest
import Foundation
import UIKit
import os.log
@testable import Flirrt

/// Comprehensive Concurrency and Actor Safety Tests
/// Tests thread safety, actor patterns, data races, and concurrent operations
/// Critical for keyboard extension which has strict memory/performance requirements
@available(iOS 15.0, *)
class ConcurrencyTests: XCTestCase {

    var testActor: TestSafeActor!
    var sharedDataManager: SharedDataManager!
    var apiClient: APIClient!

    override func setUp() {
        super.setUp()
        testActor = TestSafeActor()
        sharedDataManager = SharedDataManager.shared
        apiClient = APIClient(baseURL: "http://localhost:3000")
    }

    override func tearDown() {
        testActor = nil
        sharedDataManager = nil
        apiClient = nil
        super.tearDown()
    }

    // MARK: - Actor Safety Tests

    func testActorIsolation() async {
        let expectation = self.expectation(description: "Actor isolation should prevent data races")
        expectation.expectedFulfillmentCount = 100

        // Perform 100 concurrent operations on actor
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<100 {
                group.addTask { [weak self] in
                    await self?.testActor.incrementCounter()
                    expectation.fulfill()
                }
            }
        }

        // Verify final count is exactly 100 (no race conditions)
        let finalCount = await testActor.getCounter()
        XCTAssertEqual(finalCount, 100, "Actor should prevent race conditions, expected 100 but got \(finalCount)")

        waitForExpectations(timeout: 5.0)
    }

    func testActorStateConsistency() async {
        let expectation = self.expectation(description: "Actor state should remain consistent")

        // Perform complex state modifications concurrently
        await withTaskGroup(of: Void.self) { group in
            // Add multiple values concurrently
            for i in 1...50 {
                group.addTask { [weak self] in
                    await self?.testActor.addValue(i)
                }
            }

            // Remove values concurrently
            for i in 1...25 {
                group.addTask { [weak self] in
                    await self?.testActor.removeValue(i)
                }
            }
        }

        // Verify state consistency
        let values = await testActor.getValues()
        let counter = await testActor.getCounter()

        XCTAssertEqual(values.count, 25, "Should have 25 remaining values after concurrent add/remove operations")
        XCTAssertEqual(counter, 50, "Counter should reflect all add operations")

        expectation.fulfill()
        waitForExpectations(timeout: 3.0)
    }

    // MARK: - SharedDataManager Concurrency Tests

    func testSharedDataManagerThreadSafety() {
        let expectation = self.expectation(description: "SharedDataManager should be thread-safe")
        expectation.expectedFulfillmentCount = 50

        let concurrentQueue = DispatchQueue(label: "test.concurrent", attributes: .concurrent)

        // Perform concurrent read/write operations
        for i in 0..<50 {
            concurrentQueue.async { [weak self] in
                // Write operation
                self?.sharedDataManager.setUserAuthenticated(i % 2 == 0)
                self?.sharedDataManager.setVoiceEnabled(i % 3 == 0)
                self?.sharedDataManager.setLastScreenshotTime(Date().timeIntervalSince1970)

                // Read operations
                let _ = self?.sharedDataManager.isUserAuthenticated()
                let _ = self?.sharedDataManager.isVoiceEnabled()
                let _ = self?.sharedDataManager.getLastScreenshotTime()

                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 5.0)
    }

    func testSharedDataManagerNotificationsSafety() {
        let expectation = self.expectation(description: "Notifications should be thread-safe")
        expectation.expectedFulfillmentCount = 20

        let notificationQueue = DispatchQueue(label: "test.notifications", attributes: .concurrent)

        // Send multiple notifications concurrently
        for i in 0..<20 {
            notificationQueue.async { [weak self] in
                if i % 2 == 0 {
                    self?.sharedDataManager.requestScreenshotAnalysis()
                } else {
                    self?.sharedDataManager.requestVoiceSynthesis(text: "Test \(i)", voiceId: "voice-\(i)")
                }
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 3.0)
    }

    // MARK: - API Client Concurrency Tests

    func testAPIClientConcurrentRequests() {
        let expectation = self.expectation(description: "API client should handle concurrent requests safely")
        expectation.expectedFulfillmentCount = 10

        let mockSession = MockURLSession()
        mockSession.mockResponse = """
        {
            "success": true,
            "data": {
                "suggestions": [{"id": "test", "text": "Test suggestion", "confidence": 0.8}]
            }
        }
        """.data(using: .utf8)

        apiClient.urlSession = mockSession

        // Make multiple concurrent API requests
        let concurrentQueue = DispatchQueue(label: "test.api", attributes: .concurrent)
        for i in 0..<10 {
            concurrentQueue.async { [weak self] in
                self?.apiClient.generateFlirts(screenshotId: "test-\(i)", context: "concurrent test") { result in
                    // Verify each request completes without interfering with others
                    switch result {
                    case .success:
                        expectation.fulfill()
                    case .failure(let error):
                        XCTFail("Concurrent API request failed: \(error)")
                        expectation.fulfill()
                    }
                }
            }
        }

        waitForExpectations(timeout: 10.0)
    }

    func testAPIClientRequestCancellation() {
        let expectation = self.expectation(description: "Should handle concurrent request cancellations")

        let tasks = NSMutableArray() // Thread-safe collection

        // Start multiple requests and cancel them concurrently
        for i in 0..<5 {
            let task = apiClient.generateFlirts(screenshotId: "cancel-\(i)", context: "test") { result in
                // Some requests may complete before cancellation
            }

            if let task = task {
                tasks.add(task)
            }
        }

        // Cancel all tasks concurrently
        let cancelQueue = DispatchQueue(label: "test.cancel", attributes: .concurrent)
        for i in 0..<tasks.count {
            cancelQueue.async {
                if let task = tasks[i] as? URLSessionDataTask {
                    task.cancel()
                }
            }
        }

        // Wait briefly and verify no crashes occurred
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2.0)
    }

    // MARK: - Memory Access Patterns Tests

    func testConcurrentMemoryAccess() {
        let expectation = self.expectation(description: "Concurrent memory access should be safe")
        expectation.expectedFulfillmentCount = 100

        let sharedArray = NSMutableArray()
        let concurrent = DispatchQueue(label: "test.memory", attributes: .concurrent)
        let barrier = DispatchQueue(label: "test.barrier")

        // Perform concurrent reads and writes
        for i in 0..<50 {
            concurrent.async {
                // Read operations
                let _ = sharedArray.count
                expectation.fulfill()
            }

            barrier.async(flags: .barrier) {
                // Write operations with barrier
                sharedArray.add("Item \(i)")
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 5.0)
    }

    // MARK: - Keyboard Extension Concurrency Tests

    func testKeyboardExtensionConcurrentOperations() {
        let expectation = self.expectation(description: "Keyboard extension operations should be thread-safe")
        expectation.expectedFulfillmentCount = 20

        // Simulate keyboard extension environment
        let keyboardVC = KeyboardViewController()
        keyboardVC.loadViewIfNeeded()

        let operationQueue = DispatchQueue(label: "test.keyboard", attributes: .concurrent)

        // Perform concurrent operations that might happen in keyboard
        for i in 0..<10 {
            operationQueue.async {
                // Simulate button taps
                DispatchQueue.main.async {
                    keyboardVC.flirrtFreshTapped()
                    expectation.fulfill()
                }
            }

            operationQueue.async {
                // Simulate memory checks
                let _ = keyboardVC.getMemoryUsage()
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 5.0)
    }

    // MARK: - Data Race Detection Tests

    func testDataRaceDetection() {
        let expectation = self.expectation(description: "Should detect and prevent data races")

        var sharedCounter = 0
        let lock = NSLock()
        let concurrentQueue = DispatchQueue(label: "test.race", attributes: .concurrent)

        // Perform operations that could cause data races
        for _ in 0..<1000 {
            concurrentQueue.async {
                // Thread-safe increment
                lock.lock()
                sharedCounter += 1
                lock.unlock()
            }
        }

        // Wait for all operations to complete
        concurrentQueue.sync(flags: .barrier) {
            XCTAssertEqual(sharedCounter, 1000, "Thread-safe operations should prevent data races")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 3.0)
    }

    // MARK: - Task Cancellation Tests

    func testTaskCancellationSafety() async {
        let expectation = self.expectation(description: "Task cancellation should be safe")

        // Create multiple tasks that can be cancelled
        let tasks = (0..<10).map { i in
            Task {
                try? await Task.sleep(nanoseconds: UInt64(i) * 100_000_000) // Variable delays
                await self.testActor.incrementCounter()
            }
        }

        // Cancel half the tasks
        for i in stride(from: 0, to: 10, by: 2) {
            tasks[i].cancel()
        }

        // Wait for remaining tasks
        for task in tasks {
            await task.value
        }

        // Verify state is still consistent
        let counter = await testActor.getCounter()
        XCTAssertLessThanOrEqual(counter, 10, "Counter should not exceed number of tasks")

        expectation.fulfill()
        waitForExpectations(timeout: 2.0)
    }

    // MARK: - Performance Under Load Tests

    func testHighConcurrencyPerformance() {
        measure {
            let expectation = self.expectation(description: "High concurrency performance test")
            expectation.expectedFulfillmentCount = 1000

            let highConcurrencyQueue = DispatchQueue(label: "test.performance", attributes: .concurrent)

            for i in 0..<1000 {
                highConcurrencyQueue.async {
                    // Simulate typical operations
                    let _ = String("Test \(i)")
                    let _ = Data(count: 100)
                    expectation.fulfill()
                }
            }

            waitForExpectations(timeout: 10.0)
        }
    }

    // MARK: - Thread Pool Management Tests

    func testThreadPoolExhaustion() {
        let expectation = self.expectation(description: "Should handle thread pool exhaustion gracefully")

        // Create many long-running tasks
        let semaphore = DispatchSemaphore(value: 0)
        let taskCount = 100

        for i in 0..<taskCount {
            DispatchQueue.global().async {
                // Simulate work
                Thread.sleep(forTimeInterval: 0.01)

                if i == taskCount - 1 {
                    semaphore.signal()
                }
            }
        }

        // Wait for all tasks to complete
        let timeout = DispatchTime.now() + .seconds(5)
        let result = semaphore.wait(timeout: timeout)

        XCTAssertEqual(result, .success, "All tasks should complete without thread pool exhaustion")
        expectation.fulfill()
        waitForExpectations(timeout: 1.0)
    }

    // MARK: - State Machine Concurrency Tests

    func testStateMachineConcurrency() async {
        let stateMachine = ConcurrentStateMachine()

        // Perform concurrent state transitions
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<50 {
                group.addTask {
                    if i % 2 == 0 {
                        await stateMachine.transitionToActive()
                    } else {
                        await stateMachine.transitionToInactive()
                    }
                }
            }
        }

        // Verify state machine is in a valid state
        let finalState = await stateMachine.getCurrentState()
        XCTAssertTrue(finalState == .active || finalState == .inactive, "State machine should be in a valid final state")
    }
}

// MARK: - Test Helper Classes

@available(iOS 15.0, *)
actor TestSafeActor {
    private var counter = 0
    private var values: Set<Int> = []

    func incrementCounter() {
        counter += 1
    }

    func getCounter() -> Int {
        return counter
    }

    func addValue(_ value: Int) {
        values.insert(value)
    }

    func removeValue(_ value: Int) {
        values.remove(value)
    }

    func getValues() -> Set<Int> {
        return values
    }
}

@available(iOS 15.0, *)
actor ConcurrentStateMachine {
    enum State {
        case inactive, active, transitioning
    }

    private var currentState: State = .inactive

    func getCurrentState() -> State {
        return currentState
    }

    func transitionToActive() {
        guard currentState != .transitioning else { return }
        currentState = .transitioning
        // Simulate transition work
        currentState = .active
    }

    func transitionToInactive() {
        guard currentState != .transitioning else { return }
        currentState = .transitioning
        // Simulate transition work
        currentState = .inactive
    }
}

// MARK: - Thread Safety Utilities

class ThreadSafeCounter {
    private var _value = 0
    private let queue = DispatchQueue(label: "counter.queue")

    var value: Int {
        return queue.sync { _value }
    }

    func increment() {
        queue.async(flags: .barrier) {
            self._value += 1
        }
    }

    func decrement() {
        queue.async(flags: .barrier) {
            self._value -= 1
        }
    }
}

// MARK: - Concurrent Collection Tests

extension ConcurrencyTests {
    func testConcurrentCollectionAccess() {
        let expectation = self.expectation(description: "Concurrent collection access should be safe")
        expectation.expectedFulfillmentCount = 100

        let threadSafeArray = NSMutableArray()
        let concurrentQueue = DispatchQueue(label: "test.collection", attributes: .concurrent)
        let serialQueue = DispatchQueue(label: "test.collection.serial")

        for i in 0..<50 {
            concurrentQueue.async {
                // Read operations
                let _ = threadSafeArray.count
                expectation.fulfill()
            }

            serialQueue.async {
                // Write operations on serial queue
                threadSafeArray.add("Item \(i)")
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: 5.0)
    }

    func testConcurrentDictionaryAccess() {
        let expectation = self.expectation(description: "Concurrent dictionary access should be safe")

        let threadSafeDictionary = NSMutableDictionary()
        let concurrentQueue = DispatchQueue(label: "test.dict", attributes: .concurrent)
        let lock = NSLock()

        for i in 0..<100 {
            concurrentQueue.async {
                lock.lock()
                threadSafeDictionary["key\(i)"] = "value\(i)"
                lock.unlock()
            }
        }

        concurrentQueue.sync(flags: .barrier) {
            XCTAssertEqual(threadSafeDictionary.count, 100, "All dictionary entries should be present")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 3.0)
    }
}

// MARK: - Memory Barrier Tests

extension ConcurrencyTests {
    func testMemoryBarriers() {
        let expectation = self.expectation(description: "Memory barriers should ensure ordering")

        var flag = false
        var data = 0
        let barrierQueue = DispatchQueue(label: "test.barrier")

        barrierQueue.async {
            data = 42
            flag = true // This write should be visible after data write
        }

        barrierQueue.async(flags: .barrier) {
            if flag {
                XCTAssertEqual(data, 42, "Data should be visible when flag is true")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 2.0)
    }
}

// MARK: - Lock Contention Tests

extension ConcurrencyTests {
    func testLockContention() {
        let expectation = self.expectation(description: "Should handle lock contention gracefully")

        let lock = NSLock()
        var sharedResource = 0
        let contentionQueue = DispatchQueue(label: "test.contention", attributes: .concurrent)

        let group = DispatchGroup()

        // Create high lock contention
        for i in 0..<100 {
            group.enter()
            contentionQueue.async {
                lock.lock()
                sharedResource += 1
                // Simulate some work while holding lock
                usleep(1000) // 1ms
                lock.unlock()
                group.leave()
            }
        }

        group.notify(queue: .main) {
            XCTAssertEqual(sharedResource, 100, "Shared resource should be correctly updated despite lock contention")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 10.0)
    }
}

// MARK: - Async/Await Integration Tests

@available(iOS 15.0, *)
extension ConcurrencyTests {
    func testAsyncAwaitWithCallbacks() async {
        let expectation = self.expectation(description: "Async/await should integrate safely with callbacks")

        // Mix async/await with traditional callbacks
        await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                // Simulate async callback operation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    continuation.resume()
                }
            }
        }

        // Verify we can safely continue
        expectation.fulfill()
        waitForExpectations(timeout: 2.0)
    }

    func testTaskCancellationPropagation() async {
        let expectation = self.expectation(description: "Task cancellation should propagate correctly")

        let parentTask = Task {
            let childTask = Task {
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                return "completed"
            }

            // Cancel parent task
            Task {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                parentTask.cancel()
            }

            do {
                let result = try await childTask.value
                XCTFail("Child task should be cancelled")
            } catch {
                XCTAssertTrue(error is CancellationError, "Should receive cancellation error")
            }
        }

        await parentTask.value
        expectation.fulfill()
        waitForExpectations(timeout: 3.0)
    }
}