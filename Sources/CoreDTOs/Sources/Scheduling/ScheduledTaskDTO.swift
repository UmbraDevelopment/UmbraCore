import UmbraCoreTypes

/// FoundationIndependent representation of a scheduled task.
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

  /// Full initializer with all task properties
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
    startedAt: UInt64?=nil,
    completedAt: UInt64?=nil,
    duration: UInt64?=nil,
    errorMessage: String?=nil,
    resultData: String?=nil,
    metadata: [String: String]=[:]
  ) {
    self.id=id
    self.scheduleID=scheduleID
    self.name=name
    self.taskType=taskType
    self.status=status
    self.configData=configData
    self.createdAt=createdAt
    self.startedAt=startedAt
    self.completedAt=completedAt
    self.duration=duration
    self.errorMessage=errorMessage
    self.resultData=resultData
    self.metadata=metadata
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

  // MARK: - Computed Properties

  /// Whether the task is currently in progress
  public var isInProgress: Bool {
    status == .running
  }

  /// Whether the task has completed (success or failure)
  public var isComplete: Bool {
    status.isTerminal
  }

  /// Whether the task was successful
  public var isSuccessful: Bool {
    status.isSuccess
  }

  // MARK: - Utility Methods

  /// Create a copy of this task marked as started
  /// - Parameter startTime: Start time as Unix timestamp
  /// - Returns: A new ScheduledTaskDTO marked as started
  public func markAsStarted(at startTime: UInt64) -> ScheduledTaskDTO {
    ScheduledTaskDTO(
      id: id,
      scheduleID: scheduleID,
      name: name,
      taskType: taskType,
      status: .running,
      configData: configData,
      createdAt: createdAt,
      startedAt: startTime,
      completedAt: completedAt,
      duration: duration,
      errorMessage: errorMessage,
      resultData: resultData,
      metadata: metadata
    )
  }

  /// Create a copy of this task marked as completed
  /// - Parameters:
  ///   - endTime: Completion time as Unix timestamp
  ///   - result: Task result data
  /// - Returns: A new ScheduledTaskDTO marked as completed
  public func markAsCompleted(
    at endTime: UInt64,
    result: String?=nil
  ) -> ScheduledTaskDTO {
    let calculatedDuration: UInt64=if let startedAt {
      endTime > startedAt ? endTime - startedAt : 0
    } else {
      0
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
      completedAt: endTime,
      duration: calculatedDuration,
      errorMessage: errorMessage,
      resultData: result,
      metadata: metadata
    )
  }

  /// Create a copy of this task marked as failed
  /// - Parameters:
  ///   - endTime: Failure time as Unix timestamp
  ///   - error: Error message
  /// - Returns: A new ScheduledTaskDTO marked as failed
  public func markAsFailed(
    at endTime: UInt64,
    error: String
  ) -> ScheduledTaskDTO {
    let calculatedDuration: UInt64=if let startedAt {
      endTime > startedAt ? endTime - startedAt : 0
    } else {
      0
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
      completedAt: endTime,
      duration: calculatedDuration,
      errorMessage: error,
      resultData: resultData,
      metadata: metadata
    )
  }

  /// Create a copy of this task marked as cancelled
  /// - Parameter endTime: Cancellation time as Unix timestamp
  /// - Returns: A new ScheduledTaskDTO marked as cancelled
  public func markAsCancelled(at endTime: UInt64) -> ScheduledTaskDTO {
    let calculatedDuration: UInt64=if let startedAt {
      endTime > startedAt ? endTime - startedAt : 0
    } else {
      0
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
      completedAt: endTime,
      duration: calculatedDuration,
      errorMessage: "Task cancelled by user or system",
      resultData: resultData,
      metadata: metadata
    )
  }

  /// Create a copy of this task with updated metadata
  /// - Parameter additionalMetadata: The metadata to add or update
  /// - Returns: A new ScheduledTaskDTO with updated metadata
  public func withUpdatedMetadata(_ additionalMetadata: [String: String]) -> ScheduledTaskDTO {
    var newMetadata=metadata
    for (key, value) in additionalMetadata {
      newMetadata[key]=value
    }

    return ScheduledTaskDTO(
      id: id,
      scheduleID: scheduleID,
      name: name,
      taskType: taskType,
      status: status,
      configData: configData,
      createdAt: createdAt,
      startedAt: startedAt,
      completedAt: completedAt,
      duration: duration,
      errorMessage: errorMessage,
      resultData: resultData,
      metadata: newMetadata
    )
  }
}
