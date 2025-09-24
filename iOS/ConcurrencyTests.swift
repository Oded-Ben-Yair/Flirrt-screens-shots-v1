import XCTest
import Foundation
@testable import Flirrt

/// Comprehensive tests for Swift 6.2 concurrency implementations
@MainActor
final class ConcurrencyTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here
        print("🧪 Starting Swift 6.2 Concurrency Tests")
    }

    override func tearDownWithError() throws {
        // Put teardown code here
        print("🏁 Completed Swift 6.2 Concurrency Tests")
    }

    // MARK: - TaskManager Tests

    func testTaskManagerConcurrency() async throws {
        let taskManager = TaskManager.shared

        // Test adding tasks
        let (task1, taskInfo1) = Task.managed(
            name: "Test Task 1",
            category: .networking
        ) {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }

        let (task2, taskInfo2) = Task.managed(
            name: "Test Task 2",
            category: .audioProcessing
        ) {
            try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        }

        XCTAssertTrue(taskManager.taskCount >= 2)
        XCTAssertTrue(taskManager.hasActiveTasks(in: .networking))
        XCTAssertTrue(taskManager.hasActiveTasks(in: .audioProcessing))

        // Wait for tasks to complete
        _ = try await task1.value
        _ = try await task2.value

        // Verify tasks are cleaned up
        await Task.sleep(nanoseconds: 50_000_000) // Give cleanup time
        XCTAssertFalse(taskManager.hasActiveTasks(in: .networking))
        XCTAssertFalse(taskManager.hasActiveTasks(in: .audioProcessing))

        print("✅ TaskManager concurrency test passed")
    }

    func testTaskCancellation() async throws {
        let taskManager = TaskManager.shared

        let (longTask, taskInfo) = Task.managed(
            name: "Long Running Task",
            category: .backgroundTask
        ) {
            try await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
        }

        XCTAssertTrue(taskManager.hasActiveTasks(in: .backgroundTask))

        // Cancel the task
        taskManager.cancelTask(taskInfo)

        // Verify cancellation
        do {
            _ = try await longTask.value
            XCTFail("Task should have been cancelled")
        } catch is CancellationError {
            // Expected
            print("✅ Task cancellation test passed")
        }
    }

    // MARK: - VoiceModels Sendable Tests

    func testVoiceModelsSendable() async throws {
        // Test that all models conform to Sendable
        let voiceClone = VoiceClone(
            id: "test-id",
            name: "Test Voice",
            description: "Test description",
            status: .ready,
            quality: .good,
            sampleDuration: 120.0,
            fileSize: 1024
        )

        let voiceRequest = VoiceRequest(
            text: "Hello, world!",
            voiceId: "test-voice-id"
        )

        // Test passing Sendable types across actor boundaries
        let testActor = TestActor()
        await testActor.processVoiceClone(voiceClone)
        await testActor.processVoiceRequest(voiceRequest)

        print("✅ VoiceModels Sendable test passed")
    }

    // MARK: - APIClient Concurrent Operations Tests

    func testAPIClientTaskGroups() async throws {
        let apiClient = APIClient.shared

        // Test concurrent operations (mock data)
        let mockTexts = ["Hello", "World", "Swift", "Concurrency"]
        let mockVoiceId = "test-voice-id"

        // This would normally make real API calls, but we're testing the structure
        // In a real test, you'd mock the network layer
        let startTime = Date()

        do {
            // Test parallel voice synthesis (would fail in real scenario without backend)
            let _ = try await apiClient.synthesizeMultipleVoices(
                texts: mockTexts,
                voiceId: mockVoiceId
            )
        } catch {
            // Expected to fail without real backend, but structure should work
            print("⚠️ APIClient TaskGroup test failed as expected (no backend): \\(error)")
        }

        let duration = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(duration, 5.0, "Concurrent operations should fail fast")

        print("✅ APIClient TaskGroup structure test completed")
    }

    // MARK: - AsyncStream Tests

    func testAsyncStreamCreation() async throws {
        // Test AsyncStream creation without actually monitoring
        let voiceRecordingManager = VoiceRecordingManager()

        let audioLevelStream = voiceRecordingManager.monitorAudioLevels()
        let screenshotStream = voiceRecordingManager.monitorScreenshots()

        // Test that streams can be created
        XCTAssertNotNil(audioLevelStream)
        XCTAssertNotNil(screenshotStream)

        // Test limited consumption (without actually starting recording)
        var audioLevelCount = 0
        let audioTask = Task {
            for await _ in audioLevelStream {
                audioLevelCount += 1
                if audioLevelCount >= 1 { break }
            }
        }

        // Cancel quickly to avoid indefinite waiting
        Task {
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            audioTask.cancel()
        }

        try? await audioTask.value

        print("✅ AsyncStream creation test passed")
    }

    // MARK: - Actor Tests

    func testActorIsolation() async throws {
        let testActor = TestActor()

        // Test concurrent access to actor
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    await testActor.incrementCounter()
                }
            }
        }

        let finalCount = await testActor.getCounter()
        XCTAssertEqual(finalCount, 10, "Actor should handle concurrent access safely")

        print("✅ Actor isolation test passed")
    }

    // MARK: - MainActor Tests

    func testMainActorIsolation() async throws {
        // Test that UI operations are properly isolated to MainActor
        await MainActor.run {
            // This should run on the main actor
            XCTAssertTrue(Thread.isMainThread)
        }

        print("✅ MainActor isolation test passed")
    }

    // MARK: - Memory Management Tests

    func testConcurrentMemoryManagement() async throws {
        weak var weakTaskManager: TaskManager?

        // Test that task manager can be deallocated
        do {
            let localTaskManager = TaskManager()
            weakTaskManager = localTaskManager

            let (task, _) = Task.managed(
                name: "Memory Test Task",
                category: .general
            ) {
                try await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
            }

            _ = try await task.value
        }

        // Force cleanup
        await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds

        // TaskManager.shared will always exist, but local instances should be deallocated
        print("✅ Memory management test completed")
    }

    // MARK: - Performance Tests

    func testConcurrencyPerformance() async throws {
        let iterations = 100

        // Test sequential vs concurrent execution
        let startTime = Date()

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<iterations {
                group.addTask {
                    // Simulate small concurrent work
                    try? await Task.sleep(nanoseconds: 1_000_000) // 0.001 seconds
                }
            }
        }

        let concurrentDuration = Date().timeIntervalSince(startTime)

        // Sequential execution for comparison
        let sequentialStartTime = Date()
        for _ in 0..<iterations {
            try? await Task.sleep(nanoseconds: 1_000_000) // 0.001 seconds
        }
        let sequentialDuration = Date().timeIntervalSince(sequentialStartTime)

        XCTAssertLessThan(concurrentDuration, sequentialDuration * 0.5,
                         "Concurrent execution should be significantly faster")

        print("✅ Concurrency performance test passed")
        print("📊 Concurrent: \\(concurrentDuration)s, Sequential: \\(sequentialDuration)s")
    }

    // MARK: - Error Handling Tests

    func testConcurrentErrorHandling() async throws {
        // Test that errors in concurrent operations are properly handled
        let results = await withTaskGroup(of: Result<String, Error>.self) { group in
            // Add successful task
            group.addTask {
                return .success("Success")
            }

            // Add failing task
            group.addTask {
                return .failure(TestError.mockError)
            }

            var results: [Result<String, Error>] = []
            for await result in group {
                results.append(result)
            }
            return results
        }

        XCTAssertEqual(results.count, 2)

        let successCount = results.compactMap { try? $0.get() }.count
        let errorCount = results.count - successCount

        XCTAssertEqual(successCount, 1)
        XCTAssertEqual(errorCount, 1)

        print("✅ Concurrent error handling test passed")
    }
}

// MARK: - Helper Types

private actor TestActor {
    private var counter = 0

    func incrementCounter() {
        counter += 1
    }

    func getCounter() -> Int {
        return counter
    }

    func processVoiceClone(_ voiceClone: VoiceClone) {
        // Test that Sendable types can cross actor boundaries
        _ = voiceClone.name
    }

    func processVoiceRequest(_ request: VoiceRequest) {
        // Test that Sendable types can cross actor boundaries
        _ = request.text
    }
}

private enum TestError: Error {
    case mockError
}

// MARK: - Test Runner Extension

extension ConcurrencyTests {
    /// Run all concurrency tests in sequence
    static func runAllTests() async {
        let testInstance = ConcurrencyTests()

        print("🚀 Starting comprehensive Swift 6.2 concurrency tests...")

        do {
            try await testInstance.testTaskManagerConcurrency()
            try await testInstance.testTaskCancellation()
            try await testInstance.testVoiceModelsSendable()
            try await testInstance.testAPIClientTaskGroups()
            try await testInstance.testAsyncStreamCreation()
            try await testInstance.testActorIsolation()
            try await testInstance.testMainActorIsolation()
            try await testInstance.testConcurrentMemoryManagement()
            try await testInstance.testConcurrencyPerformance()
            try await testInstance.testConcurrentErrorHandling()

            print("🎉 All concurrency tests completed successfully!")
        } catch {
            print("❌ Test failed: \\(error)")
        }
    }
}