import Foundation
import LoggingInterfaces
import LoggingTypes
import TaskSchedulingInterfaces
import CoreDTOs

/**
 Command for listing tasks that match a given filter.
 
 This command encapsulates the logic for retrieving and filtering task lists,
 following the command pattern architecture.
 */
public class ListTasksCommand: BaseTaskCommand, TaskCommand {
    /// The result type for this command
    public typealias ResultType = [ScheduledTaskDTO]
    
    /// Filter to apply to the task list
    private let filter: TaskFilter?
    
    /**
     Initialises a new list tasks command.
     
     - Parameters:
        - filter: Filter to apply to the task list
        - logger: Logger instance for task operations
     */
    public init(
        filter: TaskFilter? = nil,
        logger: PrivacyAwareLoggingProtocol
    ) {
        self.filter = filter
        
        super.init(logger: logger)
    }
    
    /**
     Executes the list tasks command.
     
     - Parameters:
        - context: The logging context for the operation
     - Returns: A list of tasks that match the filter
     */
    public func execute(context: LogContextDTO) async throws -> [ScheduledTaskDTO] {
        // Create a log context for this specific operation
        let operationContext = createLogContext(
            operation: "listTasks",
            additionalMetadata: [
                "hasFilter": (value: String(filter != nil), privacyLevel: .public)
            ]
        )
        
        // Log operation start
        await logger.log(.debug, "Listing tasks", context: operationContext)
        
        // Get all tasks
        let allTasks = Array(Self.scheduledTasks.values)
        
        // Apply filtering if filter is provided
        let filteredTasks = filter != nil ? applyFilter(to: allTasks, filter: filter!) : allTasks
        
        // Sort tasks by scheduled time (ascending)
        let sortedTasks = filteredTasks.sorted { $0.scheduledTime < $1.scheduledTime }
        
        // Log result
        await logger.log(
            .debug,
            "Retrieved \(sortedTasks.count) tasks (filtered from \(allTasks.count) total)",
            context: operationContext
        )
        
        return sortedTasks
    }
    
    /**
     Applies a filter to a list of tasks.
     
     - Parameters:
        - tasks: The tasks to filter
        - filter: The filter to apply
     - Returns: Filtered list of tasks
     */
    private func applyFilter(to tasks: [ScheduledTaskDTO], filter: TaskFilter) -> [ScheduledTaskDTO] {
        return tasks.filter { task in
            // Filter by task type
            if let type = filter.type, task.type != type {
                return false
            }
            
            // Filter by task status
            if let status = filter.status, task.status != status {
                return false
            }
            
            // Filter by priority (would need to retrieve from options in a real implementation)
            // In this simplified version, we'll skip priority filtering
            
            // Filter by scheduled time (after)
            if let scheduledAfter = filter.scheduledAfter, task.scheduledTime < scheduledAfter {
                return false
            }
            
            // Filter by scheduled time (before)
            if let scheduledBefore = filter.scheduledBefore, task.scheduledTime > scheduledBefore {
                return false
            }
            
            // Filter by tag
            if let tag = filter.tag, !task.tags.contains(tag) {
                return false
            }
            
            // Task passed all filters
            return true
        }
    }
}
