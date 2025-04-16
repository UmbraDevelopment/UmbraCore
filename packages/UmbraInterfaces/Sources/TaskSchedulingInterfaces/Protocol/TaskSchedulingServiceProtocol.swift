import CoreDTOs
import Foundation

/**
 Protocol defining the requirements for a task scheduling service.

 This protocol defines the contract that all task scheduling service implementations
 must fulfil, providing a clean interface for background task scheduling operations.
 */
public protocol TaskSchedulingServiceProtocol: Sendable {
  /**
   Schedules a new task for execution.

   - Parameters:
      - task: The task to schedule
      - options: Options for scheduling the task
   - Returns: The scheduled task with updated information
   - Throws: TaskSchedulingError if the task couldn't be scheduled
   */
  func scheduleTask(_ task: ScheduledTaskDTO, options: TaskSchedulingOptions) async throws
    -> ScheduledTaskDTO

  /**
   Cancels a scheduled task.

   - Parameter taskID: The ID of the task to cancel
   - Returns: True if the task was found and cancelled, false otherwise
   */
  func cancelTask(taskID: String) async -> Bool

  /**
   Retrieves a task by its ID.

   - Parameter taskID: The ID of the task to retrieve
   - Returns: The task if found
   - Throws: TaskSchedulingError.taskNotFound if the task doesn't exist
   */
  func getTask(taskID: String) async throws -> ScheduledTaskDTO

  /**
   Lists all scheduled tasks that match the given filter.

   - Parameter filter: Filter to apply to the task list
   - Returns: A list of tasks that match the filter
   */
  func listTasks(filter: TaskFilter?) async -> [ScheduledTaskDTO]

  /**
   Updates an existing task with new information.

   - Parameters:
      - taskID: The ID of the task to update
      - updates: The properties to update
   - Returns: The updated task
   - Throws: TaskSchedulingError if the task couldn't be updated
   */
  func updateTask(taskID: String, updates: TaskUpdateDTO) async throws -> ScheduledTaskDTO

  /**
   Executes a task immediately, regardless of its scheduled time.

   - Parameter taskID: The ID of the task to execute
   - Returns: The result of the task execution
   - Throws: TaskSchedulingError if the task couldn't be executed
   */
  func executeTaskNow(taskID: String) async throws -> TaskExecutionResult

  /**
   Pauses a scheduled task.

   - Parameter taskID: The ID of the task to pause
   - Returns: True if the task was found and paused, false otherwise
   */
  func pauseTask(taskID: String) async -> Bool

  /**
   Resumes a paused task.

   - Parameter taskID: The ID of the task to resume
   - Returns: True if the task was found and resumed, false otherwise
   */
  func resumeTask(taskID: String) async -> Bool
}

/**
 Options for scheduling a task.
 */
public struct TaskSchedulingOptions: Sendable, Equatable {
  /// Priority of the task
  public let priority: TaskPriority

  /// Whether the task should persist between app restarts
  public let isPersistent: Bool

  /// Whether the task requires network connectivity
  public let requiresNetwork: Bool

  /// Whether the task requires the device to be charging
  public let requiresCharging: Bool

  /// Maximum number of retry attempts if the task fails
  public let maxRetryCount: Int

  /// Delay between retry attempts (in seconds)
  public let retryDelay: Double

  /// Custom options for the task
  public let customOptions: [String: String]

  /**
   Initializes new task scheduling options.

   - Parameters:
      - priority: Priority of the task
      - isPersistent: Whether the task should persist between app restarts
      - requiresNetwork: Whether the task requires network connectivity
      - requiresCharging: Whether the task requires the device to be charging
      - maxRetryCount: Maximum number of retry attempts if the task fails
      - retryDelay: Delay between retry attempts (in seconds)
      - customOptions: Custom options for the task
   */
  public init(
    priority: TaskPriority = .normal,
    isPersistent: Bool=true,
    requiresNetwork: Bool=false,
    requiresCharging: Bool=false,
    maxRetryCount: Int=3,
    retryDelay: Double=60.0,
    customOptions: [String: String]=[:]
  ) {
    self.priority=priority
    self.isPersistent=isPersistent
    self.requiresNetwork=requiresNetwork
    self.requiresCharging=requiresCharging
    self.maxRetryCount=maxRetryCount
    self.retryDelay=retryDelay
    self.customOptions=customOptions
  }

  /**
   Priority levels for scheduled tasks.
   */
  public enum TaskPriority: String, Sendable, Equatable, CaseIterable, Comparable {
    /// Low priority task
    case low
    /// Normal priority task
    case normal
    /// High priority task
    case high
    /// Critical priority task
    case critical

    public static func < (lhs: TaskPriority, rhs: TaskPriority) -> Bool {
      let order: [TaskPriority]=[.low, .normal, .high, .critical]
      guard
        let lhsIndex=order.firstIndex(of: lhs),
        let rhsIndex=order.firstIndex(of: rhs)
      else {
        return false
      }
      return lhsIndex < rhsIndex
    }
  }
}

/**
 Filter for listing tasks.
 */
public struct TaskFilter: Sendable, Equatable {
  /// Filter by task type
  public let type: ScheduledTaskDTO.TaskType?

  /// Filter by task status
  public let status: ScheduledTaskDTO.TaskStatus?

  /// Filter by priority
  public let priority: TaskSchedulingOptions.TaskPriority?

  /// Filter by task scheduling time range (start)
  public let scheduledAfter: Date?

  /// Filter by task scheduling time range (end)
  public let scheduledBefore: Date?

  /// Filter by task tag
  public let tag: String?

  /**
   Initializes a new task filter.

   - Parameters:
      - type: Filter by task type
      - status: Filter by task status
      - priority: Filter by priority
      - scheduledAfter: Filter by task scheduling time range (start)
      - scheduledBefore: Filter by task scheduling time range (end)
      - tag: Filter by task tag
   */
  public init(
    type: ScheduledTaskDTO.TaskType?=nil,
    status: ScheduledTaskDTO.TaskStatus?=nil,
    priority: TaskSchedulingOptions.TaskPriority?=nil,
    scheduledAfter: Date?=nil,
    scheduledBefore: Date?=nil,
    tag: String?=nil
  ) {
    self.type=type
    self.status=status
    self.priority=priority
    self.scheduledAfter=scheduledAfter
    self.scheduledBefore=scheduledBefore
    self.tag=tag
  }
}

/**
 Data transfer object for updating a task.
 */
public struct TaskUpdateDTO: Sendable, Equatable {
  /// Updated name for the task
  public let name: String?

  /// Updated description for the task
  public let description: String?

  /// Updated scheduled time for the task
  public let scheduledTime: Date?

  /// Updated task data
  public let data: [String: String]?

  /// Updated tags for the task
  public let tags: [String]?

  /// Updated task options
  public let options: TaskSchedulingOptions?

  /**
   Initializes a new task update DTO.

   - Parameters:
      - name: Updated name for the task
      - description: Updated description for the task
      - scheduledTime: Updated scheduled time for the task
      - data: Updated task data
      - tags: Updated tags for the task
      - options: Updated task options
   */
  public init(
    name: String?=nil,
    description: String?=nil,
    scheduledTime: Date?=nil,
    data: [String: String]?=nil,
    tags: [String]?=nil,
    options: TaskSchedulingOptions?=nil
  ) {
    self.name=name
    self.description=description
    self.scheduledTime=scheduledTime
    self.data=data
    self.tags=tags
    self.options=options
  }
}

/**
 Result of a task execution.
 */
public struct TaskExecutionResult: Sendable, Equatable {
  /// Whether the task executed successfully
  public let success: Bool

  /// The updated task
  public let task: ScheduledTaskDTO

  /// Output data from the task execution
  public let outputData: [String: String]

  /// Error that occurred during execution (if any)
  public let error: TaskSchedulingError?

  /// Start time of the execution
  public let startTime: Date

  /// End time of the execution
  public let endTime: Date

  /// Duration of the execution in seconds
  public let durationSeconds: Double

  /**
   Initializes a new task execution result.

   - Parameters:
      - success: Whether the task executed successfully
      - task: The updated task
      - outputData: Output data from the task execution
      - error: Error that occurred during execution (if any)
      - startTime: Start time of the execution
      - endTime: End time of the execution
   */
  public init(
    success: Bool,
    task: ScheduledTaskDTO,
    outputData: [String: String]=[:],
    error: TaskSchedulingError?=nil,
    startTime: Date,
    endTime: Date
  ) {
    self.success=success
    self.task=task
    self.outputData=outputData
    self.error=error
    self.startTime=startTime
    self.endTime=endTime
    durationSeconds=endTime.timeIntervalSince(startTime)
  }
}

/**
 Errors that can occur during task scheduling operations.
 */
public enum TaskSchedulingError: Error, Sendable, Equatable {
  /// Task not found
  case taskNotFound(String)
  /// Invalid task data
  case invalidTaskData(String)
  /// Task execution failed
  case executionFailed(String)
  /// Task is in an invalid state for the requested operation
  case invalidTaskState(String)
  /// Task scheduling has been disabled
  case schedulingDisabled(String)
  /// System resources are insufficient
  case insufficientResources(String)
  /// Permissions are insufficient
  case insufficientPermissions(String)
  /// Task was cancelled
  case taskCancelled(String)
  /// Unknown error
  case unknown(String)

  /// A user-friendly description of the error
  public var localizedDescription: String {
    switch self {
      case let .taskNotFound(taskID):
        "Task not found: \(taskID)"
      case let .invalidTaskData(details):
        "Invalid task data: \(details)"
      case let .executionFailed(details):
        "Task execution failed: \(details)"
      case let .invalidTaskState(details):
        "Invalid task state: \(details)"
      case let .schedulingDisabled(details):
        "Task scheduling has been disabled: \(details)"
      case let .insufficientResources(details):
        "Insufficient system resources: \(details)"
      case let .insufficientPermissions(details):
        "Insufficient permissions: \(details)"
      case let .taskCancelled(taskID):
        "Task was cancelled: \(taskID)"
      case let .unknown(details):
        "Unknown error: \(details)"
    }
  }
}
