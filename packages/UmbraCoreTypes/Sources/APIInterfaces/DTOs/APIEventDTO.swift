/// APIEventDTO
///
/// Represents events occurring within the UmbraCore API service.
/// This DTO captures event information in a Foundation-independent way,
/// preserving event context and details for monitoring and diagnostics.
///
/// All properties are immutable to ensure thread safety when
/// passing instances between actors or across module boundaries.
public struct APIEventDTO: Sendable, Equatable {
    /// Unique identifier for the event
    public let identifier: String
    
    /// Type of the API event
    public let eventType: APIEventType
    
    /// Timestamp when the event occurred
    public let timestamp: TimePointDTO
    
    /// The status of the operation that generated this event
    public let status: APIOperationStatus
    
    /// The operation name that generated this event
    public let operation: String
    
    /// Optional context information for the event
    public let context: String?
    
    /// Creates a new APIEventDTO instance
    /// - Parameters:
    ///   - identifier: Unique identifier for the event
    ///   - eventType: Type of the API event
    ///   - timestamp: Timestamp when the event occurred
    ///   - status: The status of the operation
    ///   - operation: The operation name
    ///   - context: Optional context information
    public init(
        identifier: String,
        eventType: APIEventType,
        timestamp: TimePointDTO,
        status: APIOperationStatus,
        operation: String,
        context: String? = nil
    ) {
        self.identifier = identifier
        self.eventType = eventType
        self.timestamp = timestamp
        self.status = status
        self.operation = operation
        self.context = context
    }
}

/// Represents the types of events that can occur in the API service
public enum APIEventType: String, Sendable, Equatable, CaseIterable {
    case initialisation
    case operation
    case configuration
    case error
    case warning
    case info
}

/// Represents the status of API operations
public enum APIOperationStatus: String, Sendable, Equatable, CaseIterable {
    case started
    case inProgress
    case completed
    case failed
    case cancelled
}
