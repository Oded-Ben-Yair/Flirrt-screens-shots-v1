#!/usr/bin/env swift

import Foundation

// Test script to demonstrate onboarding flow
// This script will:
// 1. Clear onboarding state
// 2. Set up shared container data
// 3. Test Darwin notification communication
// 4. Verify state transitions

print("🎯 Testing Flirrt.ai Onboarding Flow")
print("====================================")

// Step 1: Clear onboarding state to simulate fresh install
print("\n1️⃣ Clearing onboarding state...")
if let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt.shared") {
    sharedDefaults.removeObject(forKey: "onboarding_complete")
    sharedDefaults.removeObject(forKey: "onboarding_requested")
    sharedDefaults.removeObject(forKey: "onboarding_request_time")
    sharedDefaults.removeObject(forKey: "onboarding_triggered_from_main")
    sharedDefaults.removeObject(forKey: "onboarding_trigger_time")
    sharedDefaults.synchronize()
    print("✅ Onboarding state cleared")
} else {
    print("❌ Failed to access shared container")
}

// Step 2: Set authentication state (so user can access onboarding)
print("\n2️⃣ Setting up test authentication...")
if let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt.shared") {
    sharedDefaults.set(true, forKey: "user_authenticated")
    sharedDefaults.set("test-user-id", forKey: "user_id")
    sharedDefaults.set("test-auth-token", forKey: "auth_token")
    sharedDefaults.synchronize()
    print("✅ Test authentication set")
}

// Step 3: Simulate keyboard extension onboarding request
print("\n3️⃣ Simulating keyboard extension onboarding request...")
if let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt.shared") {
    sharedDefaults.set(true, forKey: "onboarding_requested")
    sharedDefaults.set(Date().timeIntervalSince1970, forKey: "onboarding_request_time")
    sharedDefaults.synchronize()

    // Send Darwin notification
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFNotificationName("com.flirrt.onboarding.request" as CFString),
        nil, nil, true
    )
    print("✅ Darwin notification sent")
}

// Step 4: Verify state after onboarding request
print("\n4️⃣ Verifying state transitions...")
sleep(1) // Allow time for notification processing

if let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt.shared") {
    let onboardingRequested = sharedDefaults.bool(forKey: "onboarding_requested")
    let requestTime = sharedDefaults.double(forKey: "onboarding_request_time")
    let triggeredFromMain = sharedDefaults.bool(forKey: "onboarding_triggered_from_main")

    print("• Onboarding requested: \(onboardingRequested)")
    print("• Request time: \(Date(timeIntervalSince1970: requestTime))")
    print("• Triggered from main: \(triggeredFromMain)")
}

// Step 5: Test state verification methods
print("\n5️⃣ Testing state verification...")

func checkOnboardingState() -> String {
    guard let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt.shared") else {
        return "❌ Cannot access shared container"
    }

    let isComplete = sharedDefaults.bool(forKey: "onboarding_complete")
    let isRequested = sharedDefaults.bool(forKey: "onboarding_requested")
    let isAuthenticated = sharedDefaults.bool(forKey: "user_authenticated")

    if !isAuthenticated {
        return "🔒 Authentication required"
    } else if !isComplete && !isRequested {
        return "🆕 Fresh install - onboarding not started"
    } else if !isComplete && isRequested {
        return "🚀 Onboarding requested - should show flow"
    } else if isComplete {
        return "✅ Onboarding completed"
    } else {
        return "❓ Unknown state"
    }
}

print("Current state: \(checkOnboardingState())")

print("\n🎬 Onboarding Flow Test Steps Complete!")
print("=========================================")
print("Next steps:")
print("1. Launch the main app to see onboarding triggered by Darwin notification")
print("2. Go through the 5-step onboarding process")
print("3. Test keyboard extension - should work after onboarding")
print("4. Test Fresh button triggering - should show onboarding if not complete")
print("5. Verify round-trip communication between extensions")