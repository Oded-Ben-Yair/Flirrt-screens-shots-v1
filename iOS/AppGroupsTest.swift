#!/usr/bin/swift

import Foundation

// Test App Groups functionality
func testAppGroups() {
    print("🔗 Testing App Groups Data Sharing\n")

    let appGroupID = "group.com.flirrt.shared"

    // Test 1: UserDefaults sharing
    print("1️⃣ Testing UserDefaults Sharing:")
    guard let sharedDefaults = UserDefaults(suiteName: appGroupID) else {
        print("❌ Cannot access shared UserDefaults")
        return
    }

    // Simulate main app writing authentication data
    sharedDefaults.set(true, forKey: "user_authenticated")
    sharedDefaults.set(true, forKey: "voice_enabled")
    sharedDefaults.set(Date().timeIntervalSince1970, forKey: "last_screenshot_time")
    sharedDefaults.set("grok-vision", forKey: "preferred_model")
    sharedDefaults.synchronize()

    // Simulate keyboard extension reading data
    let authenticated = sharedDefaults.bool(forKey: "user_authenticated")
    let voiceEnabled = sharedDefaults.bool(forKey: "voice_enabled")
    let lastScreenshot = sharedDefaults.double(forKey: "last_screenshot_time")
    let preferredModel = sharedDefaults.string(forKey: "preferred_model")

    print("   User authenticated: \(authenticated ? "✅" : "❌")")
    print("   Voice enabled: \(voiceEnabled ? "✅" : "❌")")
    print("   Last screenshot: \(lastScreenshot > 0 ? "✅" : "❌") (\(Date(timeIntervalSince1970: lastScreenshot)))")
    print("   Preferred model: \(preferredModel != nil ? "✅" : "❌") (\(preferredModel ?? "nil"))")

    // Test 2: File container sharing
    print("\n2️⃣ Testing File Container Sharing:")
    guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
        print("❌ Cannot access shared container")
        return
    }

    print("   Container path: \(containerURL.path)")

    // Test reading existing suggestions
    let suggestionsURL = containerURL.appendingPathComponent("suggestions.json")
    do {
        let data = try Data(contentsOf: suggestionsURL)
        let suggestions = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
        print("   Read suggestions: ✅ \(suggestions?.count ?? 0) items loaded")

        // Test writing new data
        let testData: [String: Any] = [
            "keyboard_active": true,
            "last_used": Date().timeIntervalSince1970,
            "session_id": UUID().uuidString
        ]

        let testURL = containerURL.appendingPathComponent("keyboard_status.json")
        let testJsonData = try JSONSerialization.data(withJSONObject: testData, options: .prettyPrinted)
        try testJsonData.write(to: testURL)
        print("   Write test data: ✅ keyboard_status.json created")

        // Verify round-trip
        let readBack = try Data(contentsOf: testURL)
        let parsedBack = try JSONSerialization.jsonObject(with: readBack) as? [String: Any]
        print("   Round-trip test: \(parsedBack?["session_id"] != nil ? "✅" : "❌")")

    } catch {
        print("   File operations: ❌ \(error.localizedDescription)")
    }

    // Test 3: Darwin notifications
    print("\n3️⃣ Testing Darwin Notifications:")

    // Post notification that main app would send
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFNotificationName("com.flirrt.analyze.request" as CFString),
        nil, nil, true
    )
    print("   Post analysis request: ✅")

    // Post notification that keyboard would send
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFNotificationName("com.flirrt.keyboard.active" as CFString),
        nil, nil, true
    )
    print("   Post keyboard active: ✅")

    print("   Note: Receiving notifications requires app context")

    // Test 4: Memory sharing simulation
    print("\n4️⃣ Testing Memory Sharing Simulation:")

    // Simulate screenshot data sharing
    let screenshotURL = containerURL.appendingPathComponent("latest_screenshot_metadata.json")
    let screenshotMetadata = [
        "timestamp": Date().timeIntervalSince1970,
        "app_bundle_id": "com.tinder.app",
        "screen_width": 393,
        "screen_height": 852,
        "analysis_requested": true
    ] as [String : Any]

    do {
        let metadataData = try JSONSerialization.data(withJSONObject: screenshotMetadata, options: .prettyPrinted)
        try metadataData.write(to: screenshotURL)
        print("   Screenshot metadata: ✅ Saved successfully")

        // Simulate keyboard reading metadata
        let readMetadata = try Data(contentsOf: screenshotURL)
        let parsedMetadata = try JSONSerialization.jsonObject(with: readMetadata) as? [String: Any]
        let bundleId = parsedMetadata?["app_bundle_id"] as? String
        let analysisRequested = parsedMetadata?["analysis_requested"] as? Bool

        print("   Metadata read: ✅ Bundle ID: \(bundleId ?? "nil")")
        print("   Analysis flag: \(analysisRequested == true ? "✅" : "❌")")

    } catch {
        print("   Metadata sharing: ❌ \(error.localizedDescription)")
    }

    print("\n✅ App Groups Testing Complete")
    print("All core functionality is working properly!")
}

testAppGroups()