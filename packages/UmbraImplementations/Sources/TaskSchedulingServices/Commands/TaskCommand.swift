import CoreDTOs
import Foundation
import LoggingInterfaces
import LoggingTypes
import TaskSchedulingInterfaces

/**
 Protocol for all task scheduling commands.

 This protocol defines the contract that all task scheduling commands must adhere to,
 following the command pattern architecture.
 */
public protocol TaskCommand {
  /// The type of result that the command produces
  associatedtype ResultType

  /**
   Executes the command.

   - Parameters:
      - context: The logging context for the operation
   - Returns: The result of the command execution
   - Throws: Error if the command execution fails
   */
  func execute(context: LogContextDTO) async throws -> ResultType
}

/**
 Base class for task scheduling commands.

 This class provides common functionality for all task scheduling commands,
 such as accessing the in-memory task store and creating log contexts.
 */
public class BaseTaskCommand {
  /// In-memory storage for scheduled tasks (shared across all command instances)
  static var scheduledTasks: [String: ScheduledTaskDTO]=[:]

  /// Logger instance for task operations
  let logger: PrivacyAwareLoggingProtocol

  /**
   Initialises a new base task command.

   - Parameters:
      - logger: Logger instance for task operations
   */
  init(logger: PrivacyAwareLoggingProtocol) {
    self.logger=logger
  }

  /**
   Creates a log context for a task operation.

   - Parameters:
      - operation: The operation being performed
      - taskID: The ID of the task being operated on (optional)
      - additionalMetadata: Additional metadata to include in the context
   - Returns: A log context for the operation
   */
  func createLogContext(
    operation: String,
    taskID: String?=nil,
    additionalMetadata: [String: (value: String, privacyLevel: PrivacyLevel)]=[:]
  ) -> LogContextDTO {
    var metadata=LogMetadataDTOCollection.empty

    if let taskID {
      metadata=metadata.withPublic(key: "taskID", value: taskID)
    }

    for (key, value) in additionalMetadata {
      metadata=metadata.with(
        key: key,
        value: value.value,
        privacyLevel: value.privacyLevel
      )
    }

    return LogContextDTO(
      operation: operation,
      category: "TaskScheduling",
      metadata: metadata
    )
  }

  /**
   Checks if a task with the given ID exists.

   - Parameters:
      - taskID: The ID of the task to check
   - Returns: True if the task exists, false otherwise
   */
  func taskExists(taskID: String) -> Bool {
    Self.scheduledTasks[taskID] != nil
  }

  /**
   Gets a task by its ID.

   - Parameters:
      - taskID: The ID of the task to retrieve
   - Returns: The task if found, nil otherwise
   */
  func getTask(taskID: String) -> ScheduledTaskDTO? {
    Self.scheduledTasks[taskID]
  }

  /**
   Updates a task in the store.

   - Parameters:
      - task: The task to update
   */
  func updateTask(_ task: ScheduledTaskDTO) {
    Self.scheduledTasks[task.id]=task
  }

  /**
   Validates that a task with the given ID exists.

   - Parameters:
      - taskID: The ID of the task to validate
   - Returns: The task if found
   - Throws: TaskSchedulingError.taskNotFound if the task doesn't exist
   */
  func validateTaskExists(taskID: String) throws -> ScheduledTaskDTO {
    guard let task=Self.scheduledTasks[taskID] else {
      throw TaskSchedulingError.taskNotFound("Task with ID \(taskID) not found")
    }

    return task
  }
}
