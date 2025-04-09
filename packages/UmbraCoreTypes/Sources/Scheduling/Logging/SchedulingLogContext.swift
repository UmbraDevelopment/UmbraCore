import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 # Scheduling Log Context
 
 Provides structured logging context for scheduling operations with privacy controls.
 This context implements the LogContextDTO protocol to ensure proper handling of
 privacy-sensitive information in scheduling operations.
 
 ## Privacy Considerations
 
 - Schedule IDs are considered public information
 - Task details may contain sensitive information and are treated with appropriate privacy levels
 - Timestamps and frequency information are considered public
 - User-specific scheduling information is treated as private
 */
public struct SchedulingLogContext: LogContextDTO {
    /// The domain name for this context
    public let domainName: String
    
    /// The operation being performed
    public let operation: String
    
    /// The source of the log entry (optional as per protocol)
    public let source: String?
    
    /// Optional correlation ID for tracing related log events
    public let correlationID: String?
    
    /// The metadata collection with privacy annotations
    public let metadata: LogMetadataDTOCollection
    
    /**
     Initialises a new SchedulingLogContext.
     
     - Parameters:
        - operation: The scheduling operation being performed
        - source: The source component (defaults to "SchedulingService")
        - metadata: Privacy-aware metadata collection
        - correlationID: Optional correlation ID for tracing related log events
     */
    public init(
        operation: String,
        source: String? = "SchedulingService",
        metadata: LogMetadataDTOCollection = LogMetadataDTOCollection(),
        correlationID: String? = nil
    ) {
        self.domainName = "Scheduling"
        self.operation = operation
        self.source = source
        self.correlationID = correlationID
        self.metadata = metadata
    }
    
    /**
     Adds a schedule ID to the context.
     
     - Parameter scheduleID: The schedule ID to add
     - Returns: A new context with the schedule ID added
     */
    public func withScheduleID(_ scheduleID: String) -> SchedulingLogContext {
        return SchedulingLogContext(
            operation: operation,
            source: source,
            metadata: metadata.withPublic(key: "scheduleID", value: scheduleID),
            correlationID: correlationID
        )
    }
    
    /**
     Adds a task ID to the context.
     
     - Parameter taskID: The task ID to add
     - Returns: A new context with the task ID added
     */
    public func withTaskID(_ taskID: String) -> SchedulingLogContext {
        return SchedulingLogContext(
            operation: operation,
            source: source,
            metadata: metadata.withPublic(key: "taskID", value: taskID),
            correlationID: correlationID
        )
    }
    
    /**
     Adds task details to the context with appropriate privacy controls.
     
     - Parameter task: The task details to add
     - Returns: A new context with the task details added
     */
    public func withTaskDetails(_ task: ScheduledTaskDTO) -> SchedulingLogContext {
        return SchedulingLogContext(
            operation: operation,
            source: source,
            metadata: metadata
                .withPublic(key: "taskID", value: task.id)
                .withPublic(key: "taskStatus", value: task.status.rawValue)
                .withPrivate(key: "taskName", value: task.name)
                .withPublic(key: "scheduleID", value: task.scheduleID),
            correlationID: correlationID
        )
    }
    
    /**
     Adds schedule details to the context with appropriate privacy controls.
     
     - Parameter schedule: The schedule details to add
     - Returns: A new context with the schedule details added
     */
    public func withScheduleDetails(_ schedule: ScheduleDTO) -> SchedulingLogContext {
        return SchedulingLogContext(
            operation: operation,
            source: source,
            metadata: metadata
                .withPublic(key: "scheduleID", value: schedule.id)
                .withPublic(key: "scheduleFrequency", value: schedule.frequency.rawValue)
                .withPublic(key: "scheduleEnabled", value: "\(schedule.isEnabled)")
                .withPrivate(key: "scheduleName", value: schedule.name),
            correlationID: correlationID
        )
    }
    
    /**
     Adds an error to the context with appropriate privacy controls.
     
     - Parameter error: The error to add
     - Returns: A new context with the error added
     */
    public func withError(_ error: Error) -> SchedulingLogContext {
        return SchedulingLogContext(
            operation: operation,
            source: source,
            metadata: metadata
                .withPublic(key: "errorType", value: "\(type(of: error))")
                .withPrivate(key: "errorMessage", value: error.localizedDescription),
            correlationID: correlationID
        )
    }
    
    /**
     Adds a date to the context.
     
     - Parameter date: The date to add
     - Parameter key: The key to use for the date
     - Returns: A new context with the date added
     */
    public func withDate(_ date: Date, key: String) -> SchedulingLogContext {
        return SchedulingLogContext(
            operation: operation,
            source: source,
            metadata: metadata.withPublic(key: key, value: "\(date)"),
            correlationID: correlationID
        )
    }
    
    /**
     Adds a result status to the context.
     
     - Parameter success: Whether the operation succeeded
     - Returns: A new context with the result status added
     */
    public func withResult(success: Bool) -> SchedulingLogContext {
        return SchedulingLogContext(
            operation: operation,
            source: source,
            metadata: metadata.withPublic(key: "success", value: "\(success)"),
            correlationID: correlationID
        )
    }
}
