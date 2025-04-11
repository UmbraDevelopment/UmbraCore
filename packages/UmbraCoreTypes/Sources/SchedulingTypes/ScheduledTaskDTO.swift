import Foundation

/// Foundation-independent representation of a scheduled task.
/// This data transfer object encapsulates task information for scheduled operations
/// without using any Foundation types.
public struct ScheduledTaskDTO: Sendable, Equatable {
  // MARK: - Types

  /// The type of task to be scheduled
  public enum TaskType: String, Sendable, Equatable {
    /// Backup task
    case backup
    /// Restore task
    case restore
    /// Repository check task
    case check
    /// Repository prune task
    case prune
    /// Security task (key rotation, credential refresh, etc.)
    case security
    /// Custom task
    case custom
  }

  /// The current status of the task
  public enum TaskStatus: String, Sendable, Equatable {
    /// Task is waiting to be executed
    case pending
    /// Task is currently running
    case running
    /// Task has completed successfully
    case completed
    /// Task execution failed
    case failed
    /// Task was cancelled
    case cancelled
    /// Task execution was skipped
    case skipped
  }

  // MARK: - Properties

  /// Unique identifier for the task
  public let id: String

  /// The schedule that created this task
  public let scheduleID: String

  /// Human-readable name of the task
  public let name: String

  /// The type of task
  public let taskType: TaskType

  /// The current status of the task
  public let status: TaskStatus

  /// Unix timestamp when the task was created
  public let createdAt: UInt64

  /// Unix timestamp when the task execution started
  public let startedAt: UInt64?

  /// Unix timestamp when the task execution ended
  public let endedAt: UInt64?

  /// Time in seconds that the task took to execute
  public let executionTime: Double?

  /// Error message if the task failed
  public let errorMessage: String?

  /// Task-specific configuration data (serialised JSON, command parameters, etc.)
  public let configData: String

  /// Additional metadata for the task
  public let metadata: [String: String]

  // MARK: - Initializers

  /// Full initialiser with all task properties
  /// - Parameters:
  ///   - id: Unique identifier for the task
  ///   - scheduleID: The schedule that created this task
  ///   - name: Human-readable name of the task
  ///   - taskType: The type of task
  ///   - status: The current status of the task
  ///   - createdAt: Unix timestamp when the task was created
  ///   - startedAt: Unix timestamp when the task execution started
  ///   - endedAt: Unix timestamp when the task execution ended
  ///   - executionTime: Time in seconds that the task took to execute
  ///   - errorMessage: Error message if the task failed
  ///   - configData: Task-specific configuration data
  ///   - metadata: Additional metadata for the task
  public init(
    id: String,
    scheduleID: String,
    name: String,
    taskType: TaskType,
    status: TaskStatus = .pending,
    createdAt: UInt64,
    startedAt: UInt64? = nil,
    endedAt: UInt64? = nil,
    executionTime: Double? = nil,
    errorMessage: String? = nil,
    configData: String,
    metadata: [String: String] = [:]
  ) {
    self.id = id
    self.scheduleID = scheduleID
    self.name = name
    self.taskType = taskType
    self.status = status
    self.createdAt = createdAt
    self.startedAt = startedAt
    self.endedAt = endedAt
    self.executionTime = executionTime
    self.errorMessage = errorMessage
    self.configData = configData
    self.metadata = metadata
  }

  // MARK: - Factory Methods

  /// Create a backup task
  /// - Parameters:
  ///   - id: Unique identifier for the task
  ///   - scheduleID: The schedule that created this task
  ///   - name: Human-readable name of the task
  ///   - configData: Task-specific configuration data
  ///   - metadata: Additional metadata for the task
  /// - Returns: A new backup task
  public static func backupTask(
    id: String = UUID().uuidString,
    scheduleID: String,
    name: String,
    configData: String,
    metadata: [String: String] = [:]
  ) -> ScheduledTaskDTO {
    ScheduledTaskDTO(
      id: id,
      scheduleID: scheduleID,
      name: name,
      taskType: .backup,
      createdAt: UInt64(Date().timeIntervalSince1970),
      configData: configData,
      metadata: metadata
    )
  }

  /// Create a security task
  /// - Parameters:
  ///   - id: Unique identifier for the task
  ///   - scheduleID: The schedule that created this task
  ///   - name: Human-readable name of the task
  ///   - configData: Task-specific configuration data
  ///   - metadata: Additional metadata for the task
  /// - Returns: A new security task
  public static func securityTask(
    id: String = UUID().uuidString,
    scheduleID: String,
    name: String,
    configData: String,
    metadata: [String: String] = [:]
  ) -> ScheduledTaskDTO {
    ScheduledTaskDTO(
      id: id,
      scheduleID: scheduleID,
      name: name,
      taskType: .security,
      createdAt: UInt64(Date().timeIntervalSince1970),
      configData: configData,
      metadata: metadata
    )
  }

  // MARK: - Helper Methods

  /// Create a copy of this task with updated properties
  /// - Parameters:
  ///   - status: New status
  ///   - startedAt: New started timestamp
  ///   - endedAt: New ended timestamp
  ///   - executionTime: New execution time
  ///   - errorMessage: New error message
  /// - Returns: A new task with the updated properties
  public func with(
    status: TaskStatus? = nil,
    startedAt: UInt64? = nil,
    endedAt: UInt64? = nil,
    executionTime: Double? = nil,
    errorMessage: String? = nil,
    metadata: [String: String]? = nil
  ) -> ScheduledTaskDTO {
    ScheduledTaskDTO(
      id: id,
      scheduleID: scheduleID,
      name: name,
      taskType: taskType,
      status: status ?? self.status,
      createdAt: createdAt,
      startedAt: startedAt ?? self.startedAt,
      endedAt: endedAt ?? self.endedAt,
      executionTime: executionTime ?? self.executionTime,
      errorMessage: errorMessage ?? self.errorMessage,
      configData: configData,
      metadata: metadata ?? self.metadata
    )
  }

  /// Mark this task as started
  /// - Parameter timestamp: When the task started, defaults to now
  /// - Returns: A new task marked as running
  public func markStarted(at timestamp: UInt64 = UInt64(Date().timeIntervalSince1970)) -> ScheduledTaskDTO {
    with(status: .running, startedAt: timestamp)
  }

  /// Mark this task as completed
  /// - Parameter timestamp: When the task completed, defaults to now
  /// - Returns: A new task marked as completed
  public func markCompleted(at timestamp: UInt64 = UInt64(Date().timeIntervalSince1970)) -> ScheduledTaskDTO {
    let time = startedAt != nil ? Double(timestamp) - Double(startedAt!) : nil
    return with(status: .completed, endedAt: timestamp, executionTime: time)
  }

  /// Mark this task as failed
  /// - Parameters:
  ///   - error: The error message
  ///   - timestamp: When the task failed, defaults to now
  /// - Returns: A new task marked as failed
  public func markFailed(error: String, at timestamp: UInt64 = UInt64(Date().timeIntervalSince1970)) -> ScheduledTaskDTO {
    let time = startedAt != nil ? Double(timestamp) - Double(startedAt!) : nil
    return with(status: .failed, endedAt: timestamp, executionTime: time, errorMessage: error)
  }

  /// Mark this task as cancelled
  /// - Parameter timestamp: When the task was cancelled, defaults to now
  /// - Returns: A new task marked as cancelled
  public func markCancelled(at timestamp: UInt64 = UInt64(Date().timeIntervalSince1970)) -> ScheduledTaskDTO {
    let time = startedAt != nil ? Double(timestamp) - Double(startedAt!) : nil
    return with(status: .cancelled, endedAt: timestamp, executionTime: time)
  }
}
