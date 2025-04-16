import CoreDTOs
import Foundation
import LoggingInterfaces
import LoggingTypes
import TaskSchedulingInterfaces

/**
 Command for cancelling a scheduled task.

 This command encapsulates the logic for cancelling a previously scheduled task,
 following the command pattern architecture.
 */
public class CancelTaskCommand: BaseTaskCommand, TaskCommand {
  /// The result type for this command
  public typealias ResultType=Bool

  /// The ID of the task to cancel
  private let taskID: String

  /**
   Initialises a new cancel task command.

   - Parameters:
      - taskID: The ID of the task to cancel
      - logger: Logger instance for task operations
   */
  public init(
    taskID: String,
    logger: PrivacyAwareLoggingProtocol
  ) {
    self.taskID=taskID

    super.init(logger: logger)
  }

  /**
   Executes the cancel task command.

   - Parameters:
      - context: The logging context for the operation
   - Returns: True if the task was found and cancelled, false otherwise
   */
  public func execute(context _: LogContextDTO) async throws -> Bool {
    // Create a log context for this specific operation
    let operationContext=createLogContext(
      operation: "cancelTask",
      taskID: taskID
    )

    // Log operation start
    await logger.log(.info, "Cancelling scheduled task", context: operationContext)

    // Check if task exists
    guard let task=getTask(taskID: taskID) else {
      // Log task not found
      await logger.log(
        .warning,
        "Cannot cancel task: task not found",
        context: operationContext
      )

      return false
    }

    // Check if task is already in a terminal state
    if task.status.isTerminal {
      // Log task already in terminal state
      await logger.log(
        .warning,
        "Cannot cancel task: task already in terminal state (\(task.status.rawValue))",
        context: operationContext
      )

      return false
    }

    do {
      // Simulate cancellation with the system
      try await simulateTaskCancellation(task, context: operationContext)

      // Create an updated task with cancelled status
      let updatedTask=ScheduledTaskDTO(
        id: task.id,
        scheduleID: task.scheduleID,
        name: task.name,
        description: task.description,
        type: task.type,
        status: .cancelled,
        createdTime: task.createdTime,
        scheduledTime: task.scheduledTime,
        lastUpdatedTime: Date(),
        completedTime: Date(),
        data: task.data,
        tags: task.tags,
        errorMessage: "Task cancelled by user"
      )

      // Update the task in the store
      updateTask(updatedTask)

      // Log success
      await logger.log(
        .info,
        "Task cancelled successfully",
        context: operationContext
      )

      return true

    } catch {
      // Log failure
      await logger.log(
        .error,
        "Failed to cancel task: \(error.localizedDescription)",
        context: operationContext
      )

      return false
    }
  }

  /**
   Simulates cancelling a task with the system.

   - Parameters:
      - task: The task to cancel
      - context: The logging context for the operation
   - Throws: Error if the cancellation fails
   */
  private func simulateTaskCancellation(
    _: ScheduledTaskDTO,
    context: LogContextDTO
  ) async throws {
    // Simulate work
    try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

    // Log system interaction
    await logger.log(
      .debug,
      "Cancelling task in the system",
      context: context
    )

    // Simulate random failure (5% chance)
    if Double.random(in: 0...1) < 0.05 {
      throw TaskSchedulingError.unknown("Simulated cancellation failure")
    }
  }
}
