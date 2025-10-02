import Foundation

// MARK: - Swift 6 Sendable Compatibility
// These extensions mark types as @unchecked Sendable for Swift 6 compatibility
// UserDefaults is thread-safe but not marked Sendable by Apple

extension UserDefaults: @unchecked Sendable {}
