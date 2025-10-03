#!/usr/bin/swift

import Foundation

// Memory testing utility for KeyboardViewController
class MemoryTester {
    private let memoryLimit: Int = 60 * 1024 * 1024 // 60MB limit

    func getMemoryUsage() -> Int {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        return result == KERN_SUCCESS ? Int(info.resident_size) : 0
    }

    func testMemoryCompliance() -> Bool {
        let currentUsage = getMemoryUsage()
        let usageMB = Double(currentUsage) / (1024 * 1024)

        print("Current memory usage: \(String(format: "%.2f", usageMB)) MB")
        print("Memory limit: \(memoryLimit / (1024 * 1024)) MB")

        let isCompliant = currentUsage < memoryLimit
        print("Memory compliance: \(isCompliant ? "✅ PASS" : "❌ FAIL")")

        return isCompliant
    }

    func simulateKeyboardLoad() {
        print("\n🧪 Testing KeyboardViewController memory footprint...")

        // Simulate the memory that would be used by KeyboardViewController
        let baseMemory = getMemoryUsage()

        // Allocate memory similar to what the keyboard would use
        var testData: [Data] = []

        // Simulate UI components (buttons, views, etc.)
        for _ in 0..<10 {
            let componentMemory = Data(count: 1024 * 100) // 100KB per UI component
            testData.append(componentMemory)
        }

        // Simulate cached suggestions
        for _ in 0..<50 {
            let suggestionMemory = Data(count: 1024 * 10) // 10KB per suggestion
            testData.append(suggestionMemory)
        }

        let afterLoadMemory = getMemoryUsage()
        let allocatedMemory = afterLoadMemory - baseMemory
        let allocatedMB = Double(allocatedMemory) / (1024 * 1024)

        print("Base memory: \(String(format: "%.2f", Double(baseMemory) / (1024 * 1024))) MB")
        print("After keyboard load: \(String(format: "%.2f", Double(afterLoadMemory) / (1024 * 1024))) MB")
        print("Allocated by keyboard: \(String(format: "%.2f", allocatedMB)) MB")

        let isKeyboardCompliant = afterLoadMemory < memoryLimit
        print("Keyboard memory compliance: \(isKeyboardCompliant ? "✅ PASS" : "❌ FAIL")")

        // Clean up
        testData.removeAll()
    }

    func testAppGroupsAccess() {
        print("\n🔗 Testing App Groups access...")

        let appGroupID = "group.com.flirrt.shared"

        // Test UserDefaults access
        if let sharedDefaults = UserDefaults(suiteName: appGroupID) {
            // Write test data
            sharedDefaults.set("test_value", forKey: "test_key")
            sharedDefaults.set(Date().timeIntervalSince1970, forKey: "test_timestamp")
            sharedDefaults.synchronize()

            // Read test data
            let testValue = sharedDefaults.string(forKey: "test_key")
            let testTimestamp = sharedDefaults.double(forKey: "test_timestamp")

            print("UserDefaults access: \(testValue == "test_value" ? "✅ PASS" : "❌ FAIL")")
            print("Timestamp sync: \(testTimestamp > 0 ? "✅ PASS" : "❌ FAIL")")
        } else {
            print("UserDefaults access: ❌ FAIL - Cannot access shared suite")
        }

        // Test file container access
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
            print("Container access: ✅ PASS")
            print("Container path: \(containerURL.path)")

            // Test file operations
            let testFileURL = containerURL.appendingPathComponent("test.json")
            let testData = """
            {
                "test": true,
                "timestamp": \(Date().timeIntervalSince1970)
            }
            """.data(using: .utf8)!

            do {
                try testData.write(to: testFileURL)
                let readData = try Data(contentsOf: testFileURL)
                let fileAccess = readData.count == testData.count
                print("File operations: \(fileAccess ? "✅ PASS" : "❌ FAIL")")

                // Clean up test file
                try FileManager.default.removeItem(at: testFileURL)
            } catch {
                print("File operations: ❌ FAIL - \(error.localizedDescription)")
            }
        } else {
            print("Container access: ❌ FAIL - Cannot access container")
        }
    }
}

// Run tests
let tester = MemoryTester()
print("🧪 Keyboard Extension Memory & App Groups Test\n")

let memoryCompliant = tester.testMemoryCompliance()
tester.simulateKeyboardLoad()
tester.testAppGroupsAccess()

print("\n📊 Test Summary:")
print("Memory compliance: \(memoryCompliant ? "✅ PASS" : "❌ FAIL")")
print("App Groups: Testing completed - check logs above")
print("\n💡 Note: This test simulates keyboard extension behavior.")
print("   Actual memory usage may vary in real keyboard extension context.")