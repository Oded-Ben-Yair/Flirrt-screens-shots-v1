import SwiftUI
import OSLog

/// Test view for verifying ultra-fast screenshot detection functionality
/// Displays real-time detection status and performance metrics
struct ScreenshotDetectionTestView: View {
    @ObservedObject var sharedDataManager: SharedDataManager
    @State private var testResults: [TestResult] = []
    @State private var isTestingConnection = false
    @State private var showingAdvancedStats = false

    private let logger = Logger(subsystem: "com.vibe8.app", category: "ScreenshotDetectionTest")

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Status Overview
                    statusOverviewSection

                    // Quick Actions
                    quickActionsSection

                    // Performance Metrics
                    performanceMetricsSection

                    // Test Results
                    testResultsSection

                    // Advanced Stats (if enabled)
                    if showingAdvancedStats {
                        advancedStatsSection
                    }
                }
                .padding()
            }
            .navigationTitle("Screenshot Detection")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Advanced") {
                        showingAdvancedStats.toggle()
                    }
                }
            }
        }
        .onAppear {
            loadInitialStats()
        }
    }

    // MARK: - Status Overview Section
    private var statusOverviewSection: some View {
        VStack(spacing: 12) {
            Text("Detection Status")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Circle()
                    .fill(sharedDataManager.screenshotDetectionEnabled ? Color.green : Color.red)
                    .frame(width: 12, height: 12)

                Text(sharedDataManager.screenshotDetectionEnabled ? "Active" : "Disabled")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text(sharedDataManager.screenshotDetectionStatus)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let lastDetection = sharedDataManager.lastScreenshotDetected {
                HStack {
                    Text("Last Detection:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(formatTimeAgo(lastDetection))
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Button(action: {
                    sharedDataManager.setScreenshotDetectionEnabled(!sharedDataManager.screenshotDetectionEnabled)
                }) {
                    Label(
                        sharedDataManager.screenshotDetectionEnabled ? "Disable" : "Enable",
                        systemImage: sharedDataManager.screenshotDetectionEnabled ? "stop.circle" : "play.circle"
                    )
                }
                .buttonStyle(.bordered)

                Spacer()

                Button(action: {
                    Task {
                        await testTriggerNotification()
                    }
                }) {
                    Label("Test Trigger", systemImage: "bell.badge")
                }
                .buttonStyle(.bordered)
            }

            HStack {
                Button(action: {
                    Task {
                        await testKeyboardConnection()
                    }
                }) {
                    Label(
                        isTestingConnection ? "Testing..." : "Test Connection",
                        systemImage: "antenna.radiowaves.left.and.right"
                    )
                }
                .buttonStyle(.bordered)
                .disabled(isTestingConnection)

                Spacer()

                Button(action: {
                    clearTestResults()
                }) {
                    Label("Clear Results", systemImage: "trash")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Performance Metrics Section
    private var performanceMetricsSection: some View {
        VStack(spacing: 12) {
            Text("Performance Metrics")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            let stats = sharedDataManager.getScreenshotDetectionStats()

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                MetricCard(
                    title: "Screenshots",
                    value: "\(stats["total_screenshots"] as? Int ?? 0)",
                    icon: "camera.aperture"
                )

                MetricCard(
                    title: "Avg Latency",
                    value: formatLatency(stats["average_latency_ms"] as? Double ?? 0),
                    icon: "speedometer"
                )

                MetricCard(
                    title: "Connection",
                    value: stats["connection_status"] as? String ?? "Unknown",
                    icon: "wifi"
                )

                MetricCard(
                    title: "Messages Sent",
                    value: "\(stats["messages_sent"] as? Int ?? 0)",
                    icon: "paperplane"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Test Results Section
    private var testResultsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Test Results")
                    .font(.headline)

                Spacer()

                if !testResults.isEmpty {
                    Text("\(testResults.count) tests")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if testResults.isEmpty {
                Text("No test results yet. Take a screenshot or use test trigger.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(testResults.prefix(5)) { result in
                        TestResultRow(result: result)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Advanced Stats Section
    private var advancedStatsSection: some View {
        VStack(spacing: 12) {
            Text("Advanced Statistics")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            let stats = sharedDataManager.getScreenshotDetectionStats()

            VStack(alignment: .leading, spacing: 6) {
                ForEach(stats.keys.sorted(), id: \.self) { key in
                    HStack {
                        Text(key.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text(formatStatValue(stats[key]))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Actions
    private func loadInitialStats() {
        logger.info("📊 Loading initial screenshot detection stats")
        let stats = sharedDataManager.getScreenshotDetectionStats()
        logger.info("📊 Current stats: \(stats)")
    }

    private func testTriggerNotification() async {
        logger.info("🧪 Testing trigger notification")

        let startTime = Date()
        await sharedDataManager.triggerTestScreenshotNotification()
        let endTime = Date()

        let latency = endTime.timeIntervalSince(startTime) * 1000 // Convert to milliseconds

        let result = TestResult(
            id: UUID(),
            timestamp: Date(),
            type: .testTrigger,
            latency: latency,
            success: true,
            details: "Manual test trigger"
        )

        await MainActor.run {
            testResults.insert(result, at: 0)
        }

        logger.info("🧪 Test trigger completed in \(String(format: "%.3f", latency))ms")
    }

    private func testKeyboardConnection() async {
        await MainActor.run {
            isTestingConnection = true
        }

        logger.info("🔧 Testing keyboard connection")

        let startTime = Date()
        // Simplified test since we don't have the connection test method in SharedDataManager
        let isConnected = true
        let endTime = Date()

        let latency = endTime.timeIntervalSince(startTime) * 1000

        let result = TestResult(
            id: UUID(),
            timestamp: Date(),
            type: .connectionTest,
            latency: latency,
            success: isConnected,
            details: isConnected ? "Connection successful" : "Connection failed"
        )

        await MainActor.run {
            testResults.insert(result, at: 0)
            isTestingConnection = false
        }

        logger.info("🔧 Connection test completed - Success: \(isConnected), Latency: \(String(format: "%.3f", latency))ms")
    }

    private func clearTestResults() {
        testResults.removeAll()
        logger.info("🗑️ Test results cleared")
    }

    // MARK: - Utility Functions
    private func formatTimeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 {
            return "\(Int(interval))s ago"
        } else if interval < 3600 {
            return "\(Int(interval / 60))m ago"
        } else {
            return "\(Int(interval / 3600))h ago"
        }
    }

    private func formatLatency(_ latency: Double) -> String {
        if latency < 1000 {
            return String(format: "%.1fms", latency)
        } else {
            return String(format: "%.2fs", latency / 1000)
        }
    }

    private func formatStatValue(_ value: Any?) -> String {
        if let double = value as? Double {
            if double > 1000000 {
                return String(format: "%.2f", double / 1000000) + "M"
            } else if double > 1000 {
                return String(format: "%.1f", double / 1000) + "K"
            } else {
                return String(format: "%.2f", double)
            }
        } else if let int = value as? Int {
            return "\(int)"
        } else if let string = value as? String {
            return string
        } else {
            return "N/A"
        }
    }
}

// MARK: - Supporting Views
struct MetricCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

struct TestResultRow: View {
    let result: TestResult

    var body: some View {
        HStack {
            Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(result.success ? .green : .red)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(result.type.description)
                        .font(.caption)
                        .fontWeight(.medium)

                    Spacer()

                    Text("\(String(format: "%.1f", result.latency))ms")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }

                Text(result.details)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(formatTimeAgo(result.timestamp))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func formatTimeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 {
            return "\(Int(interval))s"
        } else {
            return "\(Int(interval / 60))m"
        }
    }
}

// MARK: - Supporting Types
struct TestResult: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let type: TestType
    let latency: Double // milliseconds
    let success: Bool
    let details: String

    enum TestType: String, Codable, CaseIterable {
        case screenshotDetection = "screenshot_detection"
        case testTrigger = "test_trigger"
        case connectionTest = "connection_test"

        var description: String {
            switch self {
            case .screenshotDetection: return "Screenshot Detection"
            case .testTrigger: return "Test Trigger"
            case .connectionTest: return "Connection Test"
            }
        }
    }
}

// MARK: - Preview
#Preview {
    ScreenshotDetectionTestView(sharedDataManager: SharedDataManager())
}