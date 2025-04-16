import CoreDTOs
import Foundation
import LoggingInterfaces
import LoggingTypes
import TaskSchedulingInterfaces

/**
 Command for scheduling a task for future execution.

 This command encapsulates the logic for scheduling a task with the system,
 following the command pattern architecture.
 */
public class ScheduleTaskCommand: BaseTaskCommand, TaskCommand {
  /// The result type for this command
  public typealias ResultType=ScheduledTaskDTO

  /// The task to schedule
  private let task: ScheduledTaskDTO

  /// Options for scheduling the task
  private let options: TaskSchedulingOptions

  /**
   Initializes a new schedule task command.

   - Parameters:
      - task: The task to schedule
      - options: Options for scheduling the task
      - logger: Logger instance for task operations
   */
  public init(
    task: ScheduledTaskDTO,
    options: TaskSchedulingOptions,
    logger: PrivacyAwareLoggingProtocol
  ) {
    self.task=task
    self.options=options

    super.init(logger: logger)
  }

  /**
   Executes the schedule task command.

   - Parameters:
      - context: The logging context for the operation
   - Returns: The scheduled task with updated information
   - Throws: TaskSchedulingError if the task couldn't be scheduled
   */
  public func execute(context _: LogContextDTO) async throws -> ScheduledTaskDTO {
    // Create a log context for this specific operation
    let operationContext=createLogContext(
      operation: "scheduleTask",
      taskID: task.id,
      additionalMetadata: [
        "taskType": (value: task.type.rawValue, privacyLevel: .public),
        "taskName": (value: task.name, privacyLevel: .public),
        "scheduledTime": (value: task.scheduledTime.description, privacyLevel: .public),
        "priority": (value: options.priority.rawValue, privacyLevel: .public),
        "isPersistent": (value: String(options.isPersistent), privacyLevel: .public)
      ]
    )

    // Log operation start
    await logger.log(.info, "Scheduling task for execution", context: operationContext)

    do {
      // Validate task data
      if task.name.isEmpty {
        throw TaskSchedulingError.invalidTaskData("Task name cannot be empty")
      }

      if taskExists(taskID: task.id) {
        throw TaskSchedulingError.invalidTaskData("Task with ID \(task.id) already exists")
      }

      // Create an updated task with pending status
      let updatedTask=ScheduledTaskDTO(
        id: task.id,
        scheduleID: task.scheduleID,
        name: task.name,
        description: task.description,
        type: task.type,
        status: .pending,
        createdTime: Date(),
        scheduledTime: task.scheduledTime,
        lastUpdatedTime: Date(),
        completedTime: nil,
        data: task.data,
        tags: task.tags,
        errorMessage: nil
      )

      // Simulate task scheduling with the system
      // In a real implementation, this would interact with the OS scheduler or a background task
      // API
      try await simulateTaskScheduling(updatedTask, options: options, context: operationContext)

      // Store the task
      updateTask(updatedTask)

      // Log success
      await logger.log(
        .info,
        "Task scheduled successfully",
        context: operationContext.withMetadata(
          LogMetadataDTOCollection()
            .withPublic(key: "taskID", value: updatedTask.id)
            .withPublic(key: "scheduledTime", value: updatedTask.scheduledTime.description)
        )
      )

      return updatedTask

    } catch let error as TaskSchedulingError {
      // Log failure with task scheduling error
      await logger.log(
        .error,
        "Failed to schedule task: \(error.localizedDescription)",
        context: operationContext
      )

      throw error

    } catch {
      // Map unknown error to TaskSchedulingError
      let taskError=TaskSchedulingError.unknown(error.localizedDescription)

      // Log failure with unknown error
      await logger.log(
        .error,
        "Failed to schedule task with unexpected error: \(error.localizedDescription)",
        context: operationContext
      )

      throw taskError
    }
  }

  /**
   Simulates scheduling a task with the system.

   - Parameters:
      - task: The task to schedule
      - options: Options for scheduling the task
      - context: The logging context for the operation
   - Throws: TaskSchedulingError if the task couldn't be scheduled
   */
  private func simulateTaskScheduling(
    _: ScheduledTaskDTO,
    options: TaskSchedulingOptions,
    context: LogContextDTO
  ) async throws {
    // Simulate validation of system requirements
    if options.requiresNetwork {
      // Check if network is available
      let networkAvailable=Bool.random() // Simulate network check
      if !networkAvailable {
        await logger.log(
          .warning,
          "Task requires network but network is unavailable",
          context: context
        )
        // Still continue with scheduling in this simulation
      }
    }

    if options.requiresCharging {
      // Check if device is charging
      let isCharging=Bool.random() // Simulate charging check
      if !isCharging {
        await logger.log(
          .warning,
          "Task requires charging but device is not charging",
          context: context
        )
        // Still continue with scheduling in this simulation
      }
    }

    // Simulate scheduling work
    let workTime=UInt64(0.5 * 1_000_000_000) // 0.5 seconds
    try await Task.sleep(nanoseconds: workTime)

    // Simulate random failure (10% chance)
    if Double.random(in: 0...1) < 0.1 {
      throw TaskSchedulingError.insufficientResources("Simulated scheduling failure")
    }

    // Log scheduling details
    await logger.log(
      .debug,
      "Task scheduled with the system",
      context: context.withMetadata(
        LogMetadataDTOCollection()
          .withPublic(key: "priority", value: options.priority.rawValue)
          .withPublic(key: "isPersistent", value: String(options.isPersistent))
          .withPublic(key: "requiresNetwork", value: String(options.requiresNetwork))
          .withPublic(key: "maxRetryCount", value: String(options.maxRetryCount))
      )
    )
  }
}
