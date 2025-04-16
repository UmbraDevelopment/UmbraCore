import CoreDTOs
import Foundation
import LoggingInterfaces
import TaskSchedulingInterfaces

/**
 Factory for creating task scheduling command instances.

 This factory centralises the creation of all task scheduling commands,
 ensuring consistent initialisation and parameter passing.
 */
public class TaskCommandFactory {
  /// Logger instance for task operations
  private let logger: PrivacyAwareLoggingProtocol

  /**
   Initialises a new task command factory.

   - Parameters:
      - logger: Logger instance for task operations
   */
  public init(logger: PrivacyAwareLoggingProtocol) {
    self.logger=logger
  }

  /**
   Creates a command for scheduling a task.

   - Parameters:
      - task: The task to schedule
      - options: Options for scheduling the task
   - Returns: A command for scheduling the task
   */
  public func createScheduleTaskCommand(
    task: ScheduledTaskDTO,
    options: TaskSchedulingOptions
  ) -> ScheduleTaskCommand {
    ScheduleTaskCommand(
      task: task,
      options: options,
      logger: logger
    )
  }

  /**
   Creates a command for getting a task by ID.

   - Parameters:
      - taskID: The ID of the task to retrieve
   - Returns: A command for retrieving the task
   */
  public func createGetTaskCommand(taskID: String) -> GetTaskCommand {
    GetTaskCommand(
      taskID: taskID,
      logger: logger
    )
  }

  /**
   Creates a command for listing tasks with optional filtering.

   - Parameters:
      - filter: Filter to apply to the task list (optional)
   - Returns: A command for listing tasks
   */
  public func createListTasksCommand(filter: TaskFilter?=nil) -> ListTasksCommand {
    ListTasksCommand(
      filter: filter,
      logger: logger
    )
  }

  /**
   Creates a command for cancelling a task.

   - Parameters:
      - taskID: The ID of the task to cancel
   - Returns: A command for cancelling the task
   */
  public func createCancelTaskCommand(taskID: String) -> CancelTaskCommand {
    CancelTaskCommand(
      taskID: taskID,
      logger: logger
    )
  }

  /**
   Creates a command for updating a task.

   - Parameters:
      - taskID: The ID of the task to update
      - updates: The properties to update
   - Returns: A command for updating the task
   */
  public func createUpdateTaskCommand(
    taskID: String,
    updates: TaskUpdateDTO
  ) -> UpdateTaskCommand {
    UpdateTaskCommand(
      taskID: taskID,
      updates: updates,
      logger: logger
    )
  }

  /**
   Creates a command for executing a task immediately.

   - Parameters:
      - taskID: The ID of the task to execute
   - Returns: A command for executing the task immediately
   */
  public func createExecuteTaskNowCommand(taskID: String) -> ExecuteTaskNowCommand {
    ExecuteTaskNowCommand(
      taskID: taskID,
      logger: logger
    )
  }
}
