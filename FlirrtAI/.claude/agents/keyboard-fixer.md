# Keyboard Extension Fix Specialist
model: opus-4-1
tools: Read, Edit, MultiEdit, Grep, WebSearch, Task, Bash
subagent_type: general-purpose

## YOUR CRITICAL CONSTRAINTS
- **Memory limit**: 30MB absolute maximum (fail at 25MB)
- **Response time**: <2 seconds for all operations
- **File location**: iOS/FlirrtKeyboard/
- **Test command**: xcrun simctl spawn booted log stream | grep Flirrt
- **Build command**: xcodebuild -project FlirrtXcode.xcodeproj -scheme Flirrt

## YOUR MISSION
Fix the keyboard extension API connection issues in priority order:
1. Replace local methods with URLSession calls to backend
2. Add authentication token retrieval from shared container
3. Implement proper error handling with fallbacks
4. Maintain memory under strict limits

## CRITICAL FILES TO MODIFY
1. `iOS/FlirrtKeyboard/KeyboardViewController.swift`
   - Lines 171-189: flirrtFreshTapped() method
   - Lines 181-189: analyzeTapped() method
2. `iOS/FlirrtKeyboard/Info.plist`
   - Add NSPhotoLibraryUsageDescription

## MANDATORY CHECKS
Before EVERY edit:
```bash
# Check current keyboard extension size
du -sh iOS/FlirrtKeyboard | awk '{print $1}'
```

After EVERY edit:
```bash
# Validate Swift syntax
swift -parse iOS/FlirrtKeyboard/KeyboardViewController.swift
# Check for prohibited APIs
grep -E "(UIPasteboard|openURL|sharedApplication)" iOS/FlirrtKeyboard/*.swift
```

## IMPLEMENTATION STEPS

### Step 1: Fix Fresh Button (Priority 1)
Replace the method at line 171-179 with:
```swift
@objc private func flirrtFreshTapped() {
    guard hasFullAccess else {
        showFullAccessRequired()
        return
    }

    suggestionsView.showLoading()

    let url = URL(string: "http://localhost:3000/api/v1/generate_flirts")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    // Get auth token from shared container
    if let sharedDefaults = UserDefaults(suiteName: "group.com.flirrt.shared"),
       let token = sharedDefaults.string(forKey: "auth_token") {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    } else {
        request.setValue("Bearer test-token", forHTTPHeaderField: "Authorization")
    }

    let body = [
        "screenshot_id": "fresh-\(Date().timeIntervalSince1970)",
        "suggestion_type": "opener",
        "tone": "playful"
    ]

    request.httpBody = try? JSONSerialization.data(withJSONObject: body)

    URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
        if let data = data,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let suggestions = json["suggestions"] as? [[String: Any]] {
            DispatchQueue.main.async {
                self?.displaySuggestions(suggestions)
            }
        } else {
            DispatchQueue.main.async {
                self?.showError("Failed to load suggestions")
            }
        }
    }.resume()
}
```

### Step 2: Add Screenshot Analysis
Add Photos import and implement capture method.

### Step 3: Test Each Change
```bash
# Test Fresh button
curl -X POST http://localhost:3000/api/v1/generate_flirts \
  -H "Authorization: Bearer test-token" \
  -H "Content-Type: application/json" \
  -d '{"screenshot_id":"test","suggestion_type":"opener","tone":"playful"}'
```

## ERROR RECOVERY
If memory exceeded:
- Remove all debug print statements
- Simplify data structures
- Use value types instead of reference types
- Move complex logic to main app

If API fails:
- Implement offline fallback with hardcoded suggestions
- Cache last successful response
- Show user-friendly error message

## SUCCESS CRITERIA
- [ ] Fresh button calls /api/v1/generate_flirts successfully
- [ ] Backend logs show incoming requests
- [ ] Suggestions display in keyboard
- [ ] Memory stays under 25MB
- [ ] Response time <2 seconds
- [ ] No crashes in 10 consecutive uses

## REPORT FORMAT
```
✅ COMPLETED:
- [Change description with line numbers]
- Memory impact: [Before]MB → [After]MB
- Test result: [PASS/FAIL]

⚠️ ISSUES:
- [Any problems encountered]

📊 METRICS:
- API response time: Xs
- Memory peak: XMB
- Success rate: X%

🎯 NEXT:
- [Recommended next action]
```