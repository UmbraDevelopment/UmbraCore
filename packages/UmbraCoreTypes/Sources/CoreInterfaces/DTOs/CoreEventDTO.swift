/// CoreEventDTO
///
/// Represents events occurring within the UmbraCore framework.
/// This DTO captures event information in a Foundation-independent way,
/// preserving event context and details for monitoring and diagnostics.
///
/// All properties are immutable to ensure thread safety when
/// passing instances between actors or across module boundaries.
public struct CoreEventDTO: Sendable, Equatable {
    /// Unique identifier for the event
    public let identifier: String
    
    /// Type of the core event
    public let eventType: CoreEventType
    
    /// Timestamp when the event occurred
    public let timestamp: TimePointDTO
    
    /// The status of the operation that generated this event
    public let status: CoreEventStatus
    
    /// The component that generated this event
    public let component: String
    
    /// Optional context information for the event
    public let context: String?
    
    /// Creates a new CoreEventDTO instance
    /// - Parameters:
    ///   - identifier: Unique identifier for the event
    ///   - eventType: Type of the core event
    ///   - timestamp: Timestamp when the event occurred
    ///   - status: The status of the operation
    ///   - component: The component name
    ///   - context: Optional context information
    public init(
        identifier: String,
        eventType: CoreEventType,
        timestamp: TimePointDTO,
        status: CoreEventStatus,
        component: String,
        context: String? = nil
    ) {
        self.identifier = identifier
        self.eventType = eventType
        self.timestamp = timestamp
        self.status = status
        self.component = component
        self.context = context
    }
}

/// Represents the types of events that can occur in the framework
public enum CoreEventType: String, Sendable, Equatable, CaseIterable {
    case initialisation
    case service
    case configuration
    case shutdown
    case error
    case warning
    case info
}

/// Represents the status of core operations
public enum CoreEventStatus: String, Sendable, Equatable, CaseIterable {
    case started
    case inProgress
    case completed
    case failed
    case cancelled
}
