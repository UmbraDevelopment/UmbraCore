/// ConfigChangeEventDTO
///
/// Represents a configuration change event in the UmbraCore framework.
/// This DTO captures details about configuration changes including
/// what was modified, when, and from which source.
///
/// All properties are immutable to ensure thread safety when
/// passing instances between actors or across module boundaries.
import DateTimeTypes

public struct ConfigChangeEventDTO: Sendable, Equatable {
    /// Unique identifier for the event
    public let identifier: String
    
    /// The key that was changed
    public let key: String
    
    /// The type of change that occurred
    public let changeType: ConfigChangeType
    
    /// The source identifier where the change originated
    public let sourceIdentifier: String
    
    /// The timestamp when the change occurred
    public let timestamp: TimePointDTO
    
    /// Optional old value before the change
    public let oldValue: ConfigValueDTO?
    
    /// Optional new value after the change
    public let newValue: ConfigValueDTO?
    
    /// Optional user or process that made the change
    public let origin: String?
    
    /// Creates a new ConfigChangeEventDTO instance
    /// - Parameters:
    ///   - identifier: Unique identifier for the event
    ///   - key: The key that was changed
    ///   - changeType: The type of change
    ///   - sourceIdentifier: The source identifier
    ///   - timestamp: The timestamp when the change occurred
    ///   - oldValue: Optional old value before the change
    ///   - newValue: Optional new value after the change
    ///   - origin: Optional user or process that made the change
    public init(
        identifier: String,
        key: String,
        changeType: ConfigChangeType,
        sourceIdentifier: String,
        timestamp: TimePointDTO,
        oldValue: ConfigValueDTO? = nil,
        newValue: ConfigValueDTO? = nil,
        origin: String? = nil
    ) {
        self.identifier = identifier
        self.key = key
        self.changeType = changeType
        self.sourceIdentifier = sourceIdentifier
        self.timestamp = timestamp
        self.oldValue = oldValue
        self.newValue = newValue
        self.origin = origin
    }
}

/// Represents the types of configuration changes that can occur
public enum ConfigChangeType: String, Sendable, Equatable, CaseIterable {
    case added
    case modified
    case removed
    case sourceAdded
    case sourceRemoved
    case sourceModified
    case initialised
}
