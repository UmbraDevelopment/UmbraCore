import CoreDTOs
import Foundation
import LoggingInterfaces
import LoggingTypes
import TaskSchedulingInterfaces

/**
 Command for executing a task immediately, regardless of its scheduled time.

 This command encapsulates the logic for immediate task execution,
 following the command pattern architecture.
 */
public class ExecuteTaskNowCommand: BaseTaskCommand, TaskCommand {
  /// The result type for this command
  public typealias ResultType=TaskExecutionResult

  /// The ID of the task to execute
  private let taskID: String

  /**
   Initialises a new execute task now command.

   - Parameters:
      - taskID: The ID of the task to execute
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
   Executes the execute task now command.

   - Parameters:
      - context: The logging context for the operation
   - Returns: The result of the task execution
   - Throws: TaskSchedulingError if the task couldn't be executed
   */
  public func execute(context _: LogContextDTO) async throws -> TaskExecutionResult {
    // Create a log context for this specific operation
    let operationContext=createLogContext(
      operation: "executeTaskNow",
      taskID: taskID
    )

    // Log operation start
    await logger.log(.info, "Executing task immediately", context: operationContext)

    do {
      // Validate task exists and retrieve it
      let task=try validateTaskExists(taskID: taskID)

      // Check if task is already running or in a terminal state
      if task.status == .running {
        throw TaskSchedulingError.invalidTaskState("Task is already running")
      }

      if task.status.isTerminal && task.status != .cancelled {
        throw TaskSchedulingError.invalidTaskState(
          "Cannot execute task in terminal state (\(task.status.rawValue))"
        )
      }

      // Update task status to running
      let runningTask=ScheduledTaskDTO(
        id: task.id,
        scheduleID: task.scheduleID,
        name: task.name,
        description: task.description,
        type: task.type,
        status: .running,
        createdTime: task.createdTime,
        scheduledTime: task.scheduledTime,
        lastUpdatedTime: Date(),
        completedTime: nil,
        data: task.data,
        tags: task.tags,
        errorMessage: nil
      )

      // Update the task in the store
      updateTask(runningTask)

      // Record execution start time
      let startTime=Date()

      // Log execution start
      await logger.log(
        .info,
        "Task execution started",
        context: operationContext.withMetadata(
          LogMetadataDTOCollection()
            .withPublic(key: "taskType", value: task.type.rawValue)
            .withPublic(key: "startTime", value: startTime.description)
        )
      )

      // Perform the actual task execution
      let executionResult=try await performTaskExecution(runningTask, context: operationContext)

      // Record execution end time
      let endTime=Date()

      // Update task based on execution result
      let completedTask=if executionResult.success {
        ScheduledTaskDTO(
          id: task.id,
          scheduleID: task.scheduleID,
          name: task.name,
          description: task.description,
          type: task.type,
          status: .completed,
          createdTime: task.createdTime,
          scheduledTime: task.scheduledTime,
          lastUpdatedTime: Date(),
          completedTime: endTime,
          data: task.data,
          tags: task.tags,
          errorMessage: nil
        )
      } else {
        ScheduledTaskDTO(
          id: task.id,
          scheduleID: task.scheduleID,
          name: task.name,
          description: task.description,
          type: task.type,
          status: .failed,
          createdTime: task.createdTime,
          scheduledTime: task.scheduledTime,
          lastUpdatedTime: Date(),
          completedTime: endTime,
          data: task.data,
          tags: task.tags,
          errorMessage: executionResult.errorMessage
        )
      }

      // Update the task in the store
      updateTask(completedTask)

      // Log execution result
      await logger.log(
        .info,
        "Task execution \(executionResult.success ? "completed successfully" : "failed")",
        context: operationContext.withMetadata(
          LogMetadataDTOCollection()
            .withPublic(key: "success", value: String(executionResult.success))
            .withPublic(
              key: "durationSeconds",
              value: String(format: "%.2f", endTime.timeIntervalSince(startTime))
            )
            .withPublic(key: "errorMessage", value: executionResult.errorMessage ?? "none")
        )
      )

      // Create and return the execution result
      return TaskExecutionResult(
        success: executionResult.success,
        task: completedTask,
        outputData: executionResult.outputData,
        error: executionResult.success ? nil : TaskSchedulingError
          .executionFailed(executionResult.errorMessage ?? "Unknown error"),
        startTime: startTime,
        endTime: endTime
      )

    } catch let error as TaskSchedulingError {
      // Log failure
      await logger.log(
        .error,
        "Failed to execute task: \(error.localizedDescription)",
        context: operationContext
      )

      throw error

    } catch {
      // Map unknown error to TaskSchedulingError
      let taskError=TaskSchedulingError.unknown(error.localizedDescription)

      // Log failure
      await logger.log(
        .error,
        "Failed to execute task with unexpected error: \(error.localizedDescription)",
        context: operationContext
      )

      throw taskError
    }
  }

  // MARK: - Private Methods

  /**
   Internal struct to hold the execution result before converting to the public result type.
   */
  private struct InternalExecutionResult {
    let success: Bool
    let outputData: [String: String]
    let errorMessage: String?
  }

  /**
   Performs the actual task execution based on task type.

   - Parameters:
      - task: The task to execute
      - context: The logging context for the operation
   - Returns: The execution result
   - Throws: Error if the execution fails
   */
  private func performTaskExecution(
    _ task: ScheduledTaskDTO,
    context: LogContextDTO
  ) async throws -> InternalExecutionResult {
    // Log the task type
    await logger.log(
      .debug,
      "Executing task of type: \(task.type.rawValue)",
      context: context
    )

    // Simulate different execution behavior based on task type
    switch task.type {
      case .backup:
        return try await simulateBackupTask(task, context: context)
      case .restore:
        return try await simulateRestoreTask(task, context: context)
      case .check:
        return try await simulateCheckTask(task, context: context)
      case .prune:
        return try await simulatePruneTask(task, context: context)
      case .security:
        return try await simulateSecurityTask(task, context: context)
      case .custom:
        return try await simulateCustomTask(task, context: context)
    }
  }

  // MARK: - Task Simulation Methods

  /**
   Simulates executing a backup task.

   - Parameters:
      - task: The backup task to execute
      - context: The logging context for the operation
   - Returns: The execution result
   - Throws: Error if the execution fails
   */
  private func simulateBackupTask(
    _: ScheduledTaskDTO,
    context: LogContextDTO
  ) async throws -> InternalExecutionResult {
    // Simulate work
    for i in 1...5 {
      // Simulate backing up data
      try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

      // Log progress
      await logger.log(
        .debug,
        "Backup progress: \(i * 20)%",
        context: context
      )
    }

    // Simulate success (90% chance)
    let success=Double.random(in: 0...1) < 0.9

    if success {
      return InternalExecutionResult(
        success: true,
        outputData: [
          "backupSize": "\(Int.random(in: 10000...1_000_000)) bytes",
          "filesBackedUp": "\(Int.random(in: 10...1000))",
          "backupLocation": "/backups/\(UUID().uuidString)"
        ],
        errorMessage: nil
      )
    } else {
      return InternalExecutionResult(
        success: false,
        outputData: [:],
        errorMessage: "Simulated backup failure: insufficient disk space"
      )
    }
  }

  /**
   Simulates executing a restore task.

   - Parameters:
      - task: The restore task to execute
      - context: The logging context for the operation
   - Returns: The execution result
   - Throws: Error if the execution fails
   */
  private func simulateRestoreTask(
    _: ScheduledTaskDTO,
    context: LogContextDTO
  ) async throws -> InternalExecutionResult {
    // Simulate work
    for i in 1...5 {
      // Simulate restoring data
      try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

      // Log progress
      await logger.log(
        .debug,
        "Restore progress: \(i * 20)%",
        context: context
      )
    }

    // Simulate success (85% chance)
    let success=Double.random(in: 0...1) < 0.85

    if success {
      return InternalExecutionResult(
        success: true,
        outputData: [
          "restoredSize": "\(Int.random(in: 10000...1_000_000)) bytes",
          "filesRestored": "\(Int.random(in: 10...1000))",
          "restoreTime": "\(Double.random(in: 1...60)) seconds"
        ],
        errorMessage: nil
      )
    } else {
      return InternalExecutionResult(
        success: false,
        outputData: [:],
        errorMessage: "Simulated restore failure: backup data corrupted"
      )
    }
  }

  /**
   Simulates executing a check task.

   - Parameters:
      - task: The check task to execute
      - context: The logging context for the operation
   - Returns: The execution result
   - Throws: Error if the execution fails
   */
  private func simulateCheckTask(
    _: ScheduledTaskDTO,
    context: LogContextDTO
  ) async throws -> InternalExecutionResult {
    // Simulate work
    try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

    // Log activity
    await logger.log(
      .debug,
      "Checking integrity of data",
      context: context
    )

    // Simulate findings
    let issuesFound=Int.random(in: 0...3)

    return InternalExecutionResult(
      success: true,
      outputData: [
        "issuesFound": "\(issuesFound)",
        "checkedItems": "\(Int.random(in: 100...5000))",
        "integrityStatus": issuesFound == 0 ? "pass" : "warning"
      ],
      errorMessage: issuesFound > 0 ? "Found \(issuesFound) integrity issues" : nil
    )
  }

  /**
   Simulates executing a prune task.

   - Parameters:
      - task: The prune task to execute
      - context: The logging context for the operation
   - Returns: The execution result
   - Throws: Error if the execution fails
   */
  private func simulatePruneTask(
    _: ScheduledTaskDTO,
    context: LogContextDTO
  ) async throws -> InternalExecutionResult {
    // Simulate work
    try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds

    // Log activity
    await logger.log(
      .debug,
      "Pruning old data",
      context: context
    )

    // Simulate success (95% chance)
    let success=Double.random(in: 0...1) < 0.95

    if success {
      let itemsPruned=Int.random(in: 0...50)
      let spaceFreed=Int.random(in: 10000...10_000_000)

      return InternalExecutionResult(
        success: true,
        outputData: [
          "itemsPruned": "\(itemsPruned)",
          "spaceFreed": "\(spaceFreed) bytes",
          "remainingItems": "\(Int.random(in: 50...500))"
        ],
        errorMessage: nil
      )
    } else {
      return InternalExecutionResult(
        success: false,
        outputData: [:],
        errorMessage: "Simulated prune failure: locked files could not be removed"
      )
    }
  }

  /**
   Simulates executing a security task.

   - Parameters:
      - task: The security task to execute
      - context: The logging context for the operation
   - Returns: The execution result
   - Throws: Error if the execution fails
   */
  private func simulateSecurityTask(
    _: ScheduledTaskDTO,
    context: LogContextDTO
  ) async throws -> InternalExecutionResult {
    // Simulate work
    try await Task.sleep(nanoseconds: 400_000_000) // 0.4 seconds

    // Log activity
    await logger.log(
      .debug,
      "Performing security operations",
      context: context
    )

    // Simulate security checks
    let vulnerabilitiesFound=Int.random(in: 0...2)

    return InternalExecutionResult(
      success: true,
      outputData: [
        "vulnerabilitiesFound": "\(vulnerabilitiesFound)",
        "securityStatus": vulnerabilitiesFound == 0 ? "secure" : "vulnerable",
        "recommendedActions": vulnerabilitiesFound > 0 ? "update_credentials" : "none"
      ],
      errorMessage: vulnerabilitiesFound > 0 ? "Security vulnerabilities detected" : nil
    )
  }

  /**
   Simulates executing a custom task.

   - Parameters:
      - task: The custom task to execute
      - context: The logging context for the operation
   - Returns: The execution result
   - Throws: Error if the execution fails
   */
  private func simulateCustomTask(
    _ task: ScheduledTaskDTO,
    context: LogContextDTO
  ) async throws -> InternalExecutionResult {
    // Log the custom task
    await logger.log(
      .debug,
      "Executing custom task: \(task.name)",
      context: context
    )

    // Get the operation type from task data
    let operation=task.data["operation"] ?? "unknown"

    // Simulate different operations
    switch operation {
      case "data_sync":
        // Simulate data synchronisation
        try await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds

        return InternalExecutionResult(
          success: true,
          outputData: [
            "syncedItems": "\(Int.random(in: 5...100))",
            "bytesTransferred": "\(Int.random(in: 1000...1_000_000))",
            "conflicts": "\(Int.random(in: 0...3))"
          ],
          errorMessage: nil
        )

      case "notification":
        // Simulate sending a notification
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        return InternalExecutionResult(
          success: true,
          outputData: [
            "notificationSent": "true",
            "recipients": "\(Int.random(in: 1...10))",
            "deliveryStatus": "delivered"
          ],
          errorMessage: nil
        )

      default:
        // Simulate generic custom task
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        // Simulate random success (80% chance)
        let success=Double.random(in: 0...1) < 0.8

        if success {
          return InternalExecutionResult(
            success: true,
            outputData: [
              "operationType": operation,
              "executionTime": "\(Double.random(in: 0.1...2.0)) seconds"
            ],
            errorMessage: nil
          )
        } else {
          return InternalExecutionResult(
            success: false,
            outputData: [:],
            errorMessage: "Simulated failure in custom operation: \(operation)"
          )
        }
    }
  }
}
