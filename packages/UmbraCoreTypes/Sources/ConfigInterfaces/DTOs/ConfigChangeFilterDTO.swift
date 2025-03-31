/// ConfigChangeFilterDTO
///
/// Provides filtering criteria for configuration change events.
/// This DTO is used when subscribing to configuration changes to limit 
/// which events are delivered to the subscriber.
///
/// All properties are immutable to ensure thread safety when
/// passing instances between actors or across module boundaries.
public struct ConfigChangeFilterDTO: Sendable, Equatable {
    /// Optional keys to include in the filter
    public let keys: [String]?
    
    /// Optional change types to include in the filter
    public let changeTypes: [ConfigChangeType]?
    
    /// Optional source identifiers to include in the filter
    public let sourceIdentifiers: [String]?
    
    /// Optional key prefix filter for matching keys that start with the prefix
    public let keyPrefix: String?
    
    /// Determines if the filter should match any criteria (OR) or all criteria (AND)
    public let matchAny: Bool
    
    /// Creates a new ConfigChangeFilterDTO instance
    /// - Parameters:
    ///   - keys: Optional keys to include
    ///   - changeTypes: Optional change types to include
    ///   - sourceIdentifiers: Optional source identifiers to include
    ///   - keyPrefix: Optional key prefix filter
    ///   - matchAny: Whether to match any criteria (true) or all criteria (false)
    public init(
        keys: [String]? = nil,
        changeTypes: [ConfigChangeType]? = nil,
        sourceIdentifiers: [String]? = nil,
        keyPrefix: String? = nil,
        matchAny: Bool = false
    ) {
        self.keys = keys
        self.changeTypes = changeTypes
        self.sourceIdentifiers = sourceIdentifiers
        self.keyPrefix = keyPrefix
        self.matchAny = matchAny
    }
    
    /// Predefined filter for value changes (added, modified, removed)
    public static var valueChangesOnly: ConfigChangeFilterDTO {
        ConfigChangeFilterDTO(
            changeTypes: [.added, .modified, .removed]
        )
    }
    
    /// Predefined filter for source changes (sourceAdded, sourceRemoved, sourceModified)
    public static var sourceChangesOnly: ConfigChangeFilterDTO {
        ConfigChangeFilterDTO(
            changeTypes: [.sourceAdded, .sourceRemoved, .sourceModified]
        )
    }
    
    /// Creates a filter for a specific configuration section using key prefix
    /// - Parameter sectionPrefix: The section prefix to filter for
    /// - Returns: A configured ConfigChangeFilterDTO
    public static func forSection(_ sectionPrefix: String) -> ConfigChangeFilterDTO {
        ConfigChangeFilterDTO(keyPrefix: sectionPrefix)
    }
}
