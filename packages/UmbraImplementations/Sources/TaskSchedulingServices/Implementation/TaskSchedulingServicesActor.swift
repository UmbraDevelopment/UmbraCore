import Foundation
import TaskSchedulingInterfaces
import LoggingInterfaces
import LoggingTypes
import CoreDTOs

/**
 Actor implementation of the TaskSchedulingServiceProtocol.
 
 This actor provides thread-safe task scheduling functionality using the command pattern,
 providing operations to schedule, cancel, retrieve, update, and execute tasks.
 */
public actor TaskSchedulingServicesActor: TaskSchedulingServiceProtocol {
    
    /// Command factory for creating task scheduling commands
    private let commandFactory: TaskCommandFactory
    
    /// Logger instance for task operations
    private let logger: PrivacyAwareLoggingProtocol
    
    /**
     Initialises a new task scheduling services actor.
     
     - Parameters:
        - logger: Logger instance for task operations
     */
    public init(logger: PrivacyAwareLoggingProtocol) {
        self.logger = logger
        self.commandFactory = TaskCommandFactory(logger: logger)
        
        // Add initial log entry
        Task {
            await self.logger.log(
                .info,
                "TaskSchedulingServicesActor initialised",
                context: LogContextDTO(
                    operation: "initialisation",
                    category: "TaskScheduling",
                    metadata: LogMetadataDTOCollection.empty
                )
            )
        }
    }
    
    /**
     Schedules a task for future execution.
     
     - Parameters:
        - task: The task to schedule
        - options: Options for scheduling the task
     - Returns: The scheduled task with updated information
     - Throws: TaskSchedulingError if the task couldn't be scheduled
     */
    public func scheduleTask(
        task: ScheduledTaskDTO,
        options: TaskSchedulingOptions = TaskSchedulingOptions()
    ) async throws -> ScheduledTaskDTO {
        let baseContext = LogContextDTO(
            operation: "scheduleTask",
            category: "TaskScheduling",
            metadata: LogMetadataDTOCollection.empty
        )
        
        let command = commandFactory.createScheduleTaskCommand(task: task, options: options)
        return try await command.execute(context: baseContext)
    }
    
    /**
     Retrieves a scheduled task by its ID.
     
     - Parameters:
        - taskID: The ID of the task to retrieve
     - Returns: The task if found
     - Throws: TaskSchedulingError.taskNotFound if the task doesn't exist
     */
    public func getTask(taskID: String) async throws -> ScheduledTaskDTO {
        let baseContext = LogContextDTO(
            operation: "getTask",
            category: "TaskScheduling",
            metadata: LogMetadataDTOCollection.empty
        )
        
        let command = commandFactory.createGetTaskCommand(taskID: taskID)
        return try await command.execute(context: baseContext)
    }
    
    /**
     Lists tasks that match an optional filter.
     
     - Parameters:
        - filter: Filter to apply to the task list
     - Returns: A list of tasks that match the filter
     */
    public func listTasks(filter: TaskFilter? = nil) async throws -> [ScheduledTaskDTO] {
        let baseContext = LogContextDTO(
            operation: "listTasks",
            category: "TaskScheduling",
            metadata: LogMetadataDTOCollection.empty
        )
        
        let command = commandFactory.createListTasksCommand(filter: filter)
        return try await command.execute(context: baseContext)
    }
    
    /**
     Cancels a scheduled task.
     
     - Parameters:
        - taskID: The ID of the task to cancel
     - Returns: True if the task was found and cancelled, false otherwise
     */
    public func cancelTask(taskID: String) async throws -> Bool {
        let baseContext = LogContextDTO(
            operation: "cancelTask",
            category: "TaskScheduling",
            metadata: LogMetadataDTOCollection.empty
        )
        
        let command = commandFactory.createCancelTaskCommand(taskID: taskID)
        return try await command.execute(context: baseContext)
    }
    
    /**
     Updates a scheduled task with new information.
     
     - Parameters:
        - taskID: The ID of the task to update
        - updates: The properties to update
     - Returns: The updated task
     - Throws: TaskSchedulingError if the task couldn't be updated
     */
    public func updateTask(
        taskID: String,
        updates: TaskUpdateDTO
    ) async throws -> ScheduledTaskDTO {
        let baseContext = LogContextDTO(
            operation: "updateTask",
            category: "TaskScheduling",
            metadata: LogMetadataDTOCollection.empty
        )
        
        let command = commandFactory.createUpdateTaskCommand(taskID: taskID, updates: updates)
        return try await command.execute(context: baseContext)
    }
    
    /**
     Executes a task immediately, regardless of its scheduled time.
     
     - Parameters:
        - taskID: The ID of the task to execute
     - Returns: The result of the task execution
     - Throws: TaskSchedulingError if the task couldn't be executed
     */
    public func executeTaskNow(taskID: String) async throws -> TaskExecutionResult {
        let baseContext = LogContextDTO(
            operation: "executeTaskNow",
            category: "TaskScheduling",
            metadata: LogMetadataDTOCollection.empty
        )
        
        let command = commandFactory.createExecuteTaskNowCommand(taskID: taskID)
        return try await command.execute(context: baseContext)
    }
}
