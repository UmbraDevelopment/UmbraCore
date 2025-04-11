import Foundation
import LoggingInterfaces
import LoggingTypes
import TaskSchedulingInterfaces
import CoreDTOs

/**
 Command for retrieving a task by its ID.
 
 This command encapsulates the logic for retrieving task information,
 following the command pattern architecture.
 */
public class GetTaskCommand: BaseTaskCommand, TaskCommand {
    /// The result type for this command
    public typealias ResultType = ScheduledTaskDTO
    
    /// The ID of the task to retrieve
    private let taskID: String
    
    /**
     Initialises a new get task command.
     
     - Parameters:
        - taskID: The ID of the task to retrieve
        - logger: Logger instance for task operations
     */
    public init(
        taskID: String,
        logger: PrivacyAwareLoggingProtocol
    ) {
        self.taskID = taskID
        
        super.init(logger: logger)
    }
    
    /**
     Executes the get task command.
     
     - Parameters:
        - context: The logging context for the operation
     - Returns: The task if found
     - Throws: TaskSchedulingError.taskNotFound if the task doesn't exist
     */
    public func execute(context: LogContextDTO) async throws -> ScheduledTaskDTO {
        // Create a log context for this specific operation
        let operationContext = createLogContext(
            operation: "getTask",
            taskID: taskID
        )
        
        // Log operation start
        await logger.log(.debug, "Retrieving task information", context: operationContext)
        
        do {
            // Validate task exists and retrieve it
            let task = try validateTaskExists(taskID: taskID)
            
            // Log success
            await logger.log(
                .debug,
                "Retrieved task information successfully",
                context: operationContext.withMetadata(
                    LogMetadataDTOCollection()
                        .withPublic(key: "taskType", value: task.type.rawValue)
                        .withPublic(key: "taskStatus", value: task.status.rawValue)
                        .withPublic(key: "taskName", value: task.name)
                )
            )
            
            return task
            
        } catch let error as TaskSchedulingError {
            // Log failure
            await logger.log(
                .error,
                "Failed to retrieve task: \(error.localizedDescription)",
                context: operationContext
            )
            
            throw error
            
        } catch {
            // Map unknown error to TaskSchedulingError
            let taskError = TaskSchedulingError.unknown(error.localizedDescription)
            
            // Log failure
            await logger.log(
                .error,
                "Failed to retrieve task with unexpected error: \(error.localizedDescription)",
                context: operationContext
            )
            
            throw taskError
        }
    }
}
