import Foundation
import LoggingInterfaces
import LoggingTypes
import TaskSchedulingInterfaces
import CoreDTOs

/**
 Command for updating an existing task with new information.
 
 This command encapsulates the logic for modifying task properties,
 following the command pattern architecture.
 */
public class UpdateTaskCommand: BaseTaskCommand, TaskCommand {
    /// The result type for this command
    public typealias ResultType = ScheduledTaskDTO
    
    /// The ID of the task to update
    private let taskID: String
    
    /// The properties to update
    private let updates: TaskUpdateDTO
    
    /**
     Initialises a new update task command.
     
     - Parameters:
        - taskID: The ID of the task to update
        - updates: The properties to update
        - logger: Logger instance for task operations
     */
    public init(
        taskID: String,
        updates: TaskUpdateDTO,
        logger: PrivacyAwareLoggingProtocol
    ) {
        self.taskID = taskID
        self.updates = updates
        
        super.init(logger: logger)
    }
    
    /**
     Executes the update task command.
     
     - Parameters:
        - context: The logging context for the operation
     - Returns: The updated task
     - Throws: TaskSchedulingError if the task couldn't be updated
     */
    public func execute(context: LogContextDTO) async throws -> ScheduledTaskDTO {
        // Create a log context for this specific operation
        let operationContext = createLogContext(
            operation: "updateTask",
            taskID: taskID,
            additionalMetadata: [
                "hasNameUpdate": (value: String(updates.name != nil), privacyLevel: .public),
                "hasScheduledTimeUpdate": (value: String(updates.scheduledTime != nil), privacyLevel: .public),
                "hasOptionsUpdate": (value: String(updates.options != nil), privacyLevel: .public)
            ]
        )
        
        // Log operation start
        await logger.log(.info, "Updating task properties", context: operationContext)
        
        do {
            // Validate task exists and retrieve it
            let existingTask = try validateTaskExists(taskID: taskID)
            
            // Check if task is in a terminal state
            if existingTask.status.isTerminal {
                throw TaskSchedulingError.invalidTaskState(
                    "Cannot update task in terminal state (\(existingTask.status.rawValue))"
                )
            }
            
            // Apply updates to create a new task object
            let updatedTask = applyUpdates(to: existingTask, updates: updates)
            
            // Simulate system update
            try await simulateTaskUpdate(updatedTask, context: operationContext)
            
            // Update the task in the store
            updateTask(updatedTask)
            
            // Log success
            await logger.log(
                .info,
                "Task updated successfully",
                context: operationContext.withMetadata(
                    LogMetadataDTOCollection()
                        .withPublic(key: "taskName", value: updatedTask.name)
                        .withPublic(key: "scheduledTime", value: updatedTask.scheduledTime.description)
                )
            )
            
            return updatedTask
            
        } catch let error as TaskSchedulingError {
            // Log failure
            await logger.log(
                .error,
                "Failed to update task: \(error.localizedDescription)",
                context: operationContext
            )
            
            throw error
            
        } catch {
            // Map unknown error to TaskSchedulingError
            let taskError = TaskSchedulingError.unknown(error.localizedDescription)
            
            // Log failure
            await logger.log(
                .error,
                "Failed to update task with unexpected error: \(error.localizedDescription)",
                context: operationContext
            )
            
            throw taskError
        }
    }
    
    /**
     Applies updates to an existing task.
     
     - Parameters:
        - task: The existing task
        - updates: The updates to apply
     - Returns: A new task with updates applied
     */
    private func applyUpdates(to task: ScheduledTaskDTO, updates: TaskUpdateDTO) -> ScheduledTaskDTO {
        return ScheduledTaskDTO(
            id: task.id,
            scheduleID: task.scheduleID,
            name: updates.name ?? task.name,
            description: updates.description ?? task.description,
            type: task.type,
            status: task.status,
            createdTime: task.createdTime,
            scheduledTime: updates.scheduledTime ?? task.scheduledTime,
            lastUpdatedTime: Date(),
            completedTime: task.completedTime,
            data: updates.data ?? task.data,
            tags: updates.tags ?? task.tags,
            errorMessage: task.errorMessage
        )
    }
    
    /**
     Simulates updating a task with the system.
     
     - Parameters:
        - task: The updated task
        - context: The logging context for the operation
     - Throws: Error if the update fails
     */
    private func simulateTaskUpdate(
        _ task: ScheduledTaskDTO,
        context: LogContextDTO
    ) async throws {
        // Simulate work
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Log system interaction
        await logger.log(
            .debug,
            "Updating task in the system",
            context: context
        )
        
        // Simulate random failure (5% chance)
        if Double.random(in: 0...1) < 0.05 {
            throw TaskSchedulingError.unknown("Simulated update failure")
        }
    }
}
