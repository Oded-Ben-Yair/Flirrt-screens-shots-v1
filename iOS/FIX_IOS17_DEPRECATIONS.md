# iOS 17 Deprecation Fixes for Flirrt.AI

**Based on expert recommendations from Gemini 2.5 Pro and Perplexity Sonar Pro (October 2025)**

This guide addresses critical iOS 17 deprecations in the Flirrt.AI codebase, focusing on keyboard extensions, photo picker, and SwiftUI best practices.

---

## Overview

iOS 17 introduced several deprecations that affect our app:

1. **UIApplication.shared in extensions** - No longer available in keyboard extensions
2. **Deprecated SwiftUI modifiers** - Several view modifiers have new alternatives
3. **Photo library access APIs** - PHPickerViewController is now the standard
4. **Background task APIs** - New async/await patterns
5. **Keyboard extension lifecycle** - Updated methods and protocols

---

## Critical Fixes

### 1. UIApplication.shared in Keyboard Extension

**Problem**: `UIApplication.shared` is not available in keyboard extensions and causes crashes.

**Location**: `iOS/FlirrtKeyboard/KeyboardViewController.swift`

**Old Code**:
```swift
// ❌ This crashes in keyboard extensions
UIApplication.shared.open(url)
```

**New Code**:
```swift
// ✅ Use extensionContext to open URLs
if let url = URL(string: "flirrt://suggestion/\(suggestionId)") {
    extensionContext?.open(url, completionHandler: { success in
        print("URL opened: \(success)")
    })
}
```

**Alternative for opening main app**:
```swift
// Open main app from keyboard extension
func openMainApp() {
    let url = URL(string: "flirrt://open")!
    var responder: UIResponder? = self
    while responder != nil {
        if let application = responder as? UIApplication {
            application.perform(#selector(UIApplication.openURL(_:)), with: url)
            return
        }
        responder = responder?.next
    }
    // Fallback: use extensionContext
    extensionContext?.open(url, completionHandler: nil)
}
```

---

### 2. SwiftUI Deprecated Modifiers

**Problem**: Several SwiftUI modifiers are deprecated in iOS 17.

#### 2.1 `.onAppear` with async code

**Old Code**:
```swift
// ❌ Deprecated pattern
.onAppear {
    Task {
        await loadData()
    }
}
```

**New Code**:
```swift
// ✅ Use .task modifier
.task {
    await loadData()
}
```

#### 2.2 `.sheet(isPresented:)` with @State

**Old Code**:
```swift
// ❌ Can cause issues with state management
@State private var showSheet = false

.sheet(isPresented: $showSheet) {
    DetailView()
}
```

**New Code**:
```swift
// ✅ Use @State with explicit item binding
@State private var selectedItem: Item?

.sheet(item: $selectedItem) { item in
    DetailView(item: item)
}
```

#### 2.3 `.navigationBarTitle` and `.navigationBarItems`

**Old Code**:
```swift
// ❌ Deprecated in iOS 17
.navigationBarTitle("Flirrt")
.navigationBarItems(trailing: Button("Done") { })
```

**New Code**:
```swift
// ✅ Use .toolbar and .navigationTitle
.navigationTitle("Flirrt")
.toolbar {
    ToolbarItem(placement: .navigationBarTrailing) {
        Button("Done") { }
    }
}
```

---

### 3. Photo Picker Modernization

**Problem**: `UIImagePickerController` is deprecated for photo selection.

**Location**: `iOS/Flirrt/Views/MultiScreenshotPicker.swift`

**Old Code**:
```swift
// ❌ Deprecated
import UIKit

struct ImagePicker: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
}
```

**New Code**:
```swift
// ✅ Use PhotosUI framework
import PhotosUI
import SwiftUI

struct ModernPhotoPicker: View {
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImages: [UIImage] = []
    
    var body: some View {
        PhotosPicker(
            selection: $selectedItems,
            maxSelectionCount: 5,
            matching: .images
        ) {
            Label("Select Screenshots", systemImage: "photo.on.rectangle")
        }
        .onChange(of: selectedItems) { newItems in
            Task {
                selectedImages = []
                for item in newItems {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImages.append(image)
                    }
                }
            }
        }
    }
}
```

**Benefits**:
- ✅ No deprecation warnings
- ✅ Better privacy (user sees system picker)
- ✅ Multiple selection built-in
- ✅ Async/await pattern

---

### 4. Screenshot Detection with Modern APIs

**Problem**: `UIApplication` notifications are deprecated for screenshot detection.

**Location**: `iOS/Flirrt/Services/ScreenshotDetectionManager.swift`

**Old Code**:
```swift
// ❌ Deprecated notification
NotificationCenter.default.addObserver(
    self,
    selector: #selector(screenshotTaken),
    name: UIApplication.userDidTakeScreenshotNotification,
    object: nil
)
```

**New Code**:
```swift
// ✅ Use modern async notification stream
import Combine

class ScreenshotDetectionManager: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Modern approach using Combine
        NotificationCenter.default.publisher(for: UIApplication.userDidTakeScreenshotNotification)
            .sink { [weak self] _ in
                self?.handleScreenshot()
            }
            .store(in: &cancellables)
    }
    
    private func handleScreenshot() {
        Task {
            await processScreenshot()
        }
    }
    
    private func processScreenshot() async {
        // Process screenshot asynchronously
    }
}
```

**Alternative for iOS 17+**:
```swift
// ✅ Use async/await with Task
Task {
    for await _ in NotificationCenter.default.notifications(named: UIApplication.userDidTakeScreenshotNotification) {
        await handleScreenshot()
    }
}
```

---

### 5. Keyboard Extension Lifecycle

**Problem**: Keyboard extension lifecycle methods have new patterns in iOS 17.

**Location**: `iOS/FlirrtKeyboard/KeyboardViewController.swift`

**Old Code**:
```swift
// ❌ Old pattern
override func viewDidLoad() {
    super.viewDidLoad()
    setupKeyboard()
}

override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    loadSuggestions()
}
```

**New Code**:
```swift
// ✅ Modern pattern with async/await
override func viewDidLoad() {
    super.viewDidLoad()
    setupKeyboard()
    
    // Use Task for async initialization
    Task {
        await initializeKeyboard()
    }
}

override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    Task {
        await loadSuggestions()
    }
}

private func initializeKeyboard() async {
    // Async initialization code
}

private func loadSuggestions() async {
    // Async suggestion loading
}
```

---

### 6. App Groups and Shared Data

**Problem**: File coordination APIs have new patterns in iOS 17.

**Location**: `iOS/Flirrt/Services/ConversationSessionManager.swift`

**Old Code**:
```swift
// ❌ Synchronous file access
let sharedURL = FileManager.default.containerURL(
    forSecurityApplicationGroupIdentifier: "group.com.flirrt.app"
)!
let data = try Data(contentsOf: sharedURL.appendingPathComponent("suggestions.json"))
```

**New Code**:
```swift
// ✅ Use async file access
func loadSharedData() async throws -> Data {
    let sharedURL = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: "group.com.flirrt.app"
    )!
    let fileURL = sharedURL.appendingPathComponent("suggestions.json")
    
    return try await withCheckedThrowingContinuation { continuation in
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let data = try Data(contentsOf: fileURL)
                continuation.resume(returning: data)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
```

---

### 7. Background Task API Updates

**Problem**: `BGTaskScheduler` has new patterns in iOS 17.

**Old Code**:
```swift
// ❌ Old pattern
BGTaskScheduler.shared.register(
    forTaskWithIdentifier: "com.flirrt.refresh",
    using: nil
) { task in
    self.handleBackgroundTask(task: task as! BGAppRefreshTask)
}
```

**New Code**:
```swift
// ✅ Modern async pattern
BGTaskScheduler.shared.register(
    forTaskWithIdentifier: "com.flirrt.refresh",
    using: nil
) { task in
    Task {
        await self.handleBackgroundTask(task: task as! BGAppRefreshTask)
    }
}

private func handleBackgroundTask(task: BGAppRefreshTask) async {
    defer {
        task.setTaskCompleted(success: true)
    }
    
    // Perform background work
    await refreshSuggestions()
}
```

---

## Testing Strategy

### 1. Compile-Time Checks

Run Xcode with warnings as errors to catch deprecations:

```bash
xcodebuild -project iOS/Flirrt.xcodeproj \
           -scheme Flirrt \
           -configuration Debug \
           SWIFT_TREAT_WARNINGS_AS_ERRORS=YES \
           clean build
```

### 2. Runtime Testing

Test on iOS 17+ devices:

1. **Keyboard Extension**:
   - Open any app with text input
   - Switch to Flirrt keyboard
   - Verify suggestions load correctly
   - Test opening main app from keyboard

2. **Screenshot Detection**:
   - Take a screenshot in a dating app
   - Verify notification is received
   - Check that analysis starts automatically

3. **Photo Picker**:
   - Open Flirrt app
   - Tap "Select Screenshots"
   - Verify system picker appears
   - Select multiple photos
   - Verify all photos are processed

### 3. Automated Testing

Add unit tests for deprecated APIs:

```swift
import XCTest

class DeprecationTests: XCTestCase {
    func testNoUIApplicationInExtension() {
        // Verify no UIApplication.shared calls in extension code
        let extensionFiles = ["KeyboardViewController.swift"]
        
        for file in extensionFiles {
            let content = try! String(contentsOfFile: file)
            XCTAssertFalse(
                content.contains("UIApplication.shared"),
                "Found UIApplication.shared in \(file)"
            )
        }
    }
}
```

---

## Migration Checklist

Use this checklist to track deprecation fixes:

- [ ] Replace `UIApplication.shared` in keyboard extension
- [ ] Update `.onAppear` to `.task` for async code
- [ ] Replace `.navigationBarTitle` with `.navigationTitle`
- [ ] Replace `.navigationBarItems` with `.toolbar`
- [ ] Migrate to `PhotosPicker` from `UIImagePickerController`
- [ ] Update screenshot detection to use Combine or async/await
- [ ] Modernize keyboard lifecycle methods
- [ ] Update App Groups file access to async patterns
- [ ] Update background task handling to async/await
- [ ] Run compile-time deprecation checks
- [ ] Test on iOS 17+ physical device
- [ ] Add automated tests for critical paths

---

## Additional Resources

- [Apple's iOS 17 API Diffs](https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-17-release-notes)
- [SwiftUI Deprecations Guide](https://developer.apple.com/documentation/swiftui)
- [PhotosUI Framework](https://developer.apple.com/documentation/photosui)
- [Keyboard Extension Best Practices](https://developer.apple.com/documentation/uikit/keyboards_and_input/creating_a_custom_keyboard)

---

## Notes

- **Backward compatibility**: These fixes maintain compatibility with iOS 16 using `@available` checks where needed
- **Testing**: Always test on physical iOS 17+ devices, as simulators may not catch all issues
- **App Store Review**: Fixing deprecations reduces risk of rejection during App Store review

---

**Last Updated**: October 2025 based on expert LLM consultation

