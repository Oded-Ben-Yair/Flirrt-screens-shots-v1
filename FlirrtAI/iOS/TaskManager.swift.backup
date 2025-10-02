import Foundation
import OSLog

/// Centralized task management for the Flirrt app
@MainActor
final class TaskManager: ObservableObject {
    static let shared = TaskManager()

    private let logger = Logger(subsystem: "com.flirrt.app", category: "TaskManager")

    // Task tracking
    @Published private(set) var activeTasks: Set<TaskInfo> = []
    private var taskStorage: [UUID: Task<Void, Never>] = [:]

    private init() {
        logger.info("TaskManager initialized")
    }

    deinit {
        cancelAllTasks()
        logger.info("TaskManager deinitialized")
    }

    /// Add a task to the manager for tracking and cancellation
    func addTask<T: Sendable>(
        _ task: Task<T, Error>,
        name: String,
        priority: TaskPriority = .medium,
        category: TaskCategory = .general
    ) -> TaskInfo {
        let taskInfo = TaskInfo(
            name: name,
            category: category,
            priority: priority,
            startTime: Date()
        )

        activeTasks.insert(taskInfo)

        let wrappedTask = Task<Void, Never> {
            do {
                _ = try await task.value
                await removeTask(taskInfo)
            } catch is CancellationError {
                await removeTask(taskInfo)
                logger.info("Task cancelled: \(name)")
            } catch {
                await removeTask(taskInfo)
                logger.error("Task failed: \(name) - \(error.localizedDescription)")
            }
        }

        taskStorage[taskInfo.id] = wrappedTask

        logger.info("Added task: \(name) (\(taskInfo.id))")
        return taskInfo
    }

    /// Add a never-failing task
    func addTask(
        _ task: Task<Void, Never>,
        name: String,
        priority: TaskPriority = .medium,
        category: TaskCategory = .general
    ) -> TaskInfo {
        let taskInfo = TaskInfo(
            name: name,
            category: category,
            priority: priority,
            startTime: Date()
        )

        activeTasks.insert(taskInfo)

        let wrappedTask = Task<Void, Never> {
            await task.value
            await removeTask(taskInfo)
        }

        taskStorage[taskInfo.id] = wrappedTask

        logger.info("Added never-failing task: \(name) (\(taskInfo.id))")
        return taskInfo
    }

    /// Cancel a specific task
    func cancelTask(_ taskInfo: TaskInfo) {
        taskStorage[taskInfo.id]?.cancel()
        taskStorage.removeValue(forKey: taskInfo.id)
        activeTasks.remove(taskInfo)
        logger.info("Cancelled task: \(taskInfo.name) (\(taskInfo.id))")
    }

    /// Cancel all tasks in a specific category
    func cancelTasks(in category: TaskCategory) {
        let tasksToCancel = activeTasks.filter { $0.category == category }
        for task in tasksToCancel {
            cancelTask(task)
        }
        logger.info("Cancelled \(tasksToCancel.count) tasks in category: \(category)")
    }

    /// Cancel all active tasks
    func cancelAllTasks() {
        let taskCount = activeTasks.count
        for task in activeTasks {
            taskStorage[task.id]?.cancel()
        }
        taskStorage.removeAll()
        activeTasks.removeAll()
        logger.info("Cancelled all tasks (\(taskCount) total)")
    }

    /// Remove completed task from tracking
    private func removeTask(_ taskInfo: TaskInfo) async {
        await MainActor.run {
            taskStorage.removeValue(forKey: taskInfo.id)
            activeTasks.remove(taskInfo)
            logger.debug("Removed completed task: \(taskInfo.name) (\(taskInfo.id))")
        }
    }

    /// Get tasks by category
    func tasks(in category: TaskCategory) -> [TaskInfo] {
        return Array(activeTasks.filter { $0.category == category })
    }

    /// Check if any tasks are running in a category
    func hasActiveTasks(in category: TaskCategory) -> Bool {
        return activeTasks.contains { $0.category == category }
    }

    /// Get total task count
    var taskCount: Int {
        return activeTasks.count
    }
}

// MARK: - TaskInfo

struct TaskInfo: Identifiable, Hashable, Sendable {
    let id = UUID()
    let name: String
    let category: TaskCategory
    let priority: TaskPriority
    let startTime: Date

    var duration: TimeInterval {
        Date().timeIntervalSince(startTime)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: TaskInfo, rhs: TaskInfo) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - TaskCategory

enum TaskCategory: String, CaseIterable, Sendable {
    case general = "General"
    case networking = "Networking"
    case audioProcessing = "Audio Processing"
    case imageProcessing = "Image Processing"
    case voiceSynthesis = "Voice Synthesis"
    case screenshot = "Screenshot"
    case userInterface = "User Interface"
    case backgroundTask = "Background Task"
    case fileOperation = "File Operation"
}

// MARK: - TaskPriority Extension

extension TaskPriority {
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .userInitiated: return "User Initiated"
        case .utility: return "Utility"
        case .background: return "Background"
        @unknown default: return "Unknown"
        }
    }
}

// MARK: - Convenience Extensions

extension Task where Success: Sendable, Failure == Error {
    /// Create a managed task that automatically registers with TaskManager
    static func managed<T: Sendable>(
        priority: TaskPriority? = nil,
        name: String,
        category: TaskCategory = .general,
        operation: @escaping @Sendable () async throws -> T
    ) -> (task: Task<T, Error>, taskInfo: TaskInfo) {
        let task = Task(priority: priority, operation: operation)
        let taskInfo = TaskManager.shared.addTask(task, name: name, priority: priority ?? .medium, category: category)
        return (task, taskInfo)
    }
}

extension Task where Success == Void, Failure == Never {
    /// Create a managed never-failing task
    static func managed(
        priority: TaskPriority? = nil,
        name: String,
        category: TaskCategory = .general,
        operation: @escaping @Sendable () async -> Void
    ) -> (task: Task<Void, Never>, taskInfo: TaskInfo) {
        let task = Task(priority: priority, operation: operation)
        let taskInfo = TaskManager.shared.addTask(task, name: name, priority: priority ?? .medium, category: category)
        return (task, taskInfo)
    }
}