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
    /// Task has failed
    case failed
    /// Task has been cancelled
    case cancelled
    /// Task has been skipped
    case skipped

    /// Whether this status represents a terminal state
    public var isTerminal: Bool {
      switch self {
        case .pending, .running:
          false
        case .completed, .failed, .cancelled, .skipped:
          true
      }
    }

    /// Whether this status represents a success
    public var isSuccess: Bool {
      self == .completed
    }

    /// Whether this status represents a failure
    public var isFailure: Bool {
      self == .failed || self == .cancelled
    }
  }

  // MARK: - Properties

  /// Unique identifier for the task
  public let id: String

  /// ID of the schedule that triggered this task
  public let scheduleID: String

  /// Human-readable name of the task
  public let name: String

  /// Type of the task
  public let taskType: TaskType

  /// Current status of the task
  public let status: TaskStatus

  /// Task-specific configuration data as JSON string
  public let configData: String

  /// Creation time as Unix timestamp in seconds
  public let createdAt: UInt64

  /// Start time as Unix timestamp in seconds
  public let startedAt: UInt64?

  /// Completion time as Unix timestamp in seconds
  public let completedAt: UInt64?

  /// Duration in seconds (if completed)
  public let duration: UInt64?

  /// Error message if the task failed
  public let errorMessage: String?

  /// Task result data as JSON string
  public let resultData: String?

  /// Additional metadata for the task
  public let metadata: [String: String]

  // MARK: - Initializers

  /// Full initialiser with all task properties
  /// - Parameters:
  ///   - id: Unique identifier for the task
  ///   - scheduleId: ID of the schedule that triggered this task
  ///   - name: Human-readable name of the task
  ///   - taskType: Type of the task
  ///   - status: Current status of the task
  ///   - configData: Task-specific configuration data
  ///   - createdAt: Creation time as Unix timestamp
  ///   - startedAt: Start time as Unix timestamp
  ///   - completedAt: Completion time as Unix timestamp
  ///   - duration: Duration in seconds
  ///   - errorMessage: Error message if the task failed
  ///   - resultData: Task result data
  ///   - metadata: Additional metadata
  public init(
    id: String,
    scheduleID: String,
    name: String,
    taskType: TaskType,
    status: TaskStatus = .pending,
    configData: String,
    createdAt: UInt64,
    startedAt: UInt64? = nil,
    completedAt: UInt64? = nil,
    duration: UInt64? = nil,
    errorMessage: String? = nil,
    resultData: String? = nil,
    metadata: [String: String] = [:]
  ) {
    self.id = id
    self.scheduleID = scheduleID
    self.name = name
    self.taskType = taskType
    self.status = status
    self.configData = configData
    self.createdAt = createdAt
    self.startedAt = startedAt
    self.completedAt = completedAt
    self.duration = duration
    self.errorMessage = errorMessage
    self.resultData = resultData
    self.metadata = metadata
  }

  // MARK: - Factory Methods

  /// Create a backup task
  /// - Parameters:
  ///   - id: Unique identifier for the task
  ///   - scheduleId: ID of the schedule that triggered this task
  ///   - name: Human-readable name of the task
  ///   - configData: Backup configuration data as JSON string
  ///   - createdAt: Creation time as Unix timestamp
  /// - Returns: A ScheduledTaskDTO configured for backup
  public static func backupTask(
    id: String,
    scheduleID: String,
    name: String,
    configData: String,
    createdAt: UInt64
  ) -> ScheduledTaskDTO {
    ScheduledTaskDTO(
      id: id,
      scheduleID: scheduleID,
      name: name,
      taskType: .backup,
      configData: configData,
      createdAt: createdAt
    )
  }

  /// Create a security task
  /// - Parameters:
  ///   - id: Unique identifier for the task
  ///   - scheduleId: ID of the schedule that triggered this task
  ///   - name: Human-readable name of the task
  ///   - configData: Security operation configuration data as JSON string
  ///   - createdAt: Creation time as Unix timestamp
  /// - Returns: A ScheduledTaskDTO configured for security operations
  public static func securityTask(
    id: String,
    scheduleID: String,
    name: String,
    configData: String,
    createdAt: UInt64
  ) -> ScheduledTaskDTO {
    ScheduledTaskDTO(
      id: id,
      scheduleID: scheduleID,
      name: name,
      taskType: .security,
      configData: configData,
      createdAt: createdAt
    )
  }

  // MARK: - State Transition Methods

  /// Create a copy of this task with updated status to 'running'
  /// - Parameter startedAt: Start time, defaults to current time
  /// - Returns: A new task with running status
  public func markAsRunning(startedAt: UInt64 = UInt64(Date().timeIntervalSince1970)) -> ScheduledTaskDTO {
    ScheduledTaskDTO(
      id: id,
      scheduleID: scheduleID,
      name: name,
      taskType: taskType,
      status: .running,
      configData: configData,
      createdAt: createdAt,
      startedAt: startedAt,
      metadata: metadata
    )
  }

  /// Create a copy of this task with updated status to 'completed'
  /// - Parameters:
  ///   - completedAt: Completion time, defaults to current time
  ///   - resultData: Result data as JSON string
  /// - Returns: A new task with completed status
  public func markAsCompleted(
    completedAt: UInt64 = UInt64(Date().timeIntervalSince1970),
    resultData: String? = nil
  ) -> ScheduledTaskDTO {
    let calculatedDuration: UInt64?
    if let startTime = startedAt {
      calculatedDuration = completedAt - startTime
    } else {
      calculatedDuration = nil
    }

    return ScheduledTaskDTO(
      id: id,
      scheduleID: scheduleID,
      name: name,
      taskType: taskType,
      status: .completed,
      configData: configData,
      createdAt: createdAt,
      startedAt: startedAt,
      completedAt: completedAt,
      duration: calculatedDuration,
      resultData: resultData,
      metadata: metadata
    )
  }

  /// Create a copy of this task with updated status to 'failed'
  /// - Parameters:
  ///   - completedAt: Completion time, defaults to current time
  ///   - errorMessage: Error message describing the failure
  ///   - resultData: Result data as JSON string
  /// - Returns: A new task with failed status
  public func markAsFailed(
    completedAt: UInt64 = UInt64(Date().timeIntervalSince1970),
    errorMessage: String,
    resultData: String? = nil
  ) -> ScheduledTaskDTO {
    let calculatedDuration: UInt64?
    if let startTime = startedAt {
      calculatedDuration = completedAt - startTime
    } else {
      calculatedDuration = nil
    }

    return ScheduledTaskDTO(
      id: id,
      scheduleID: scheduleID,
      name: name,
      taskType: taskType,
      status: .failed,
      configData: configData,
      createdAt: createdAt,
      startedAt: startedAt,
      completedAt: completedAt,
      duration: calculatedDuration,
      errorMessage: errorMessage,
      resultData: resultData,
      metadata: metadata
    )
  }

  /// Create a copy of this task with updated status to 'cancelled'
  /// - Parameter completedAt: Completion time, defaults to current time
  /// - Returns: A new task with cancelled status
  public func markAsCancelled(
    completedAt: UInt64 = UInt64(Date().timeIntervalSince1970)
  ) -> ScheduledTaskDTO {
    let calculatedDuration: UInt64?
    if let startTime = startedAt {
      calculatedDuration = completedAt - startTime
    } else {
      calculatedDuration = nil
    }

    return ScheduledTaskDTO(
      id: id,
      scheduleID: scheduleID,
      name: name,
      taskType: taskType,
      status: .cancelled,
      configData: configData,
      createdAt: createdAt,
      startedAt: startedAt,
      completedAt: completedAt,
      duration: calculatedDuration,
      metadata: metadata
    )
  }
}
