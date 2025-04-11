import Foundation
import LoggingInterfaces
import LoggingTypes
import TaskSchedulingInterfaces
import CoreDTOs

/**
 Base protocol for all task scheduling operation commands.
 
 This protocol defines the contract that all task command implementations
 must fulfil, following the command pattern to encapsulate task operations in
 discrete command objects with a consistent interface.
 */
public protocol TaskCommand {
    /// The type of result returned by this command when executed
    associatedtype ResultType: Sendable
    
    /**
     Executes the task operation.
     
     - Parameters:
        - context: The logging context for the operation
     - Returns: The result of the operation
     - Throws: TaskSchedulingError if the operation fails
     */
    func execute(context: LogContextDTO) async throws -> ResultType
}

/**
 Base class for task commands providing common functionality.
 
 This abstract base class provides shared functionality for all task commands,
 including standardised logging and utility methods that are commonly needed across
 task scheduling operations.
 */
public class BaseTaskCommand {
    /// Logging instance for task operations
    protected let logger: PrivacyAwareLoggingProtocol
    
    /// In-memory store of scheduled tasks
    protected static var scheduledTasks: [String: ScheduledTaskDTO] = [:]
    
    /**
     Initializes a new base task command.
     
     - Parameters:
        - logger: Logger instance for task operations
     */
    public init(logger: PrivacyAwareLoggingProtocol) {
        self.logger = logger
    }
    
    /**
     Creates a logging context with standardised metadata.
     
     - Parameters:
        - operation: The name of the operation
        - taskID: The unique task identifier (if applicable)
        - additionalMetadata: Additional metadata for the log context
     - Returns: A configured log context
     */
    protected func createLogContext(
        operation: String,
        taskID: String? = nil,
        additionalMetadata: [String: (value: String, privacyLevel: PrivacyLevel)] = [:]
    ) -> LogContextDTO {
        // Create a base metadata collection
        var metadata = LogMetadataDTOCollection()
            .withPublic(key: "operation", value: operation)
            .withPublic(key: "source", value: "TaskSchedulingService")
        
        // Add task ID if provided
        if let taskID = taskID {
            metadata = metadata.withPublic(key: "taskID", value: taskID)
        }
        
        // Add additional metadata with specified privacy levels
        for (key, value) in additionalMetadata {
            switch value.privacyLevel {
            case .public:
                metadata = metadata.withPublic(key: key, value: value.value)
            case .protected:
                metadata = metadata.withProtected(key: key, value: value.value)
            case .private:
                metadata = metadata.withPrivate(key: key, value: value.value)
            }
        }
        
        // Create and return the log context
        return LogContextDTO(
            operationName: operation,
            sourceComponent: "TaskSchedulingService",
            metadata: metadata
        )
    }
    
    /**
     Updates a task in the shared task store.
     
     - Parameters:
        - task: The task to update
     */
    protected func updateTask(_ task: ScheduledTaskDTO) {
        Self.scheduledTasks[task.id] = task
    }
    
    /**
     Removes a task from the shared task store.
     
     - Parameters:
        - taskID: The ID of the task to remove
     */
    protected func removeTask(taskID: String) {
        Self.scheduledTasks.removeValue(forKey: taskID)
    }
    
    /**
     Checks if a task with the given ID exists.
     
     - Parameter taskID: The task ID to check
     - Returns: True if the task exists, false otherwise
     */
    protected func taskExists(taskID: String) -> Bool {
        return Self.scheduledTasks[taskID] != nil
    }
    
    /**
     Gets a task by its ID.
     
     - Parameter taskID: The task ID to retrieve
     - Returns: The task if found, nil otherwise
     */
    protected func getTask(taskID: String) -> ScheduledTaskDTO? {
        return Self.scheduledTasks[taskID]
    }
    
    /**
     Validates that a task exists and throws an error if it doesn't.
     
     - Parameter taskID: The task ID to validate
     - Throws: TaskSchedulingError.taskNotFound if the task doesn't exist
     - Returns: The task if found
     */
    protected func validateTaskExists(taskID: String) throws -> ScheduledTaskDTO {
        guard let task = getTask(taskID) else {
            throw TaskSchedulingError.taskNotFound(taskID)
        }
        return task
    }
}
