import CoreDTOs

/**
 # CryptoEventFilterDTO
 
 Filter criteria for crypto operation events.
 
 This DTO provides a Foundation-independent way to filter crypto events
 based on various criteria such as event type, operation, status, and time ranges.
 */
public struct CryptoEventFilterDTO: Sendable, Equatable {
    /// Filter by event types, empty means all types
    public let eventTypes: [CryptoEventType]
    
    /// Filter by operations, empty means all operations
    public let operations: [String]
    
    /// Filter by operation statuses, empty means all statuses
    public let statuses: [CryptoOperationStatus]
    
    /// Filter by key identifiers, empty means all keys
    public let keyIdentifiers: [String]
    
    /// Minimum timestamp for events (inclusive)
    public let fromTime: TimePointDTO?
    
    /// Maximum timestamp for events (inclusive)
    public let toTime: TimePointDTO?
    
    /// Additional metadata filters
    public let metadataFilters: [MetadataFilter]
    
    /**
     Creates a new CryptoEventFilterDTO.
     
     - Parameters:
        - eventTypes: Filter by event types, empty means all types
        - operations: Filter by operations, empty means all operations
        - statuses: Filter by operation statuses, empty means all statuses
        - keyIdentifiers: Filter by key identifiers, empty means all keys
        - fromTime: Minimum timestamp for events (inclusive)
        - toTime: Maximum timestamp for events (inclusive)
        - metadataFilters: Additional metadata filters
     */
    public init(
        eventTypes: [CryptoEventType] = [],
        operations: [String] = [],
        statuses: [CryptoOperationStatus] = [],
        keyIdentifiers: [String] = [],
        fromTime: TimePointDTO? = nil,
        toTime: TimePointDTO? = nil,
        metadataFilters: [MetadataFilter] = []
    ) {
        self.eventTypes = eventTypes
        self.operations = operations
        self.statuses = statuses
        self.keyIdentifiers = keyIdentifiers
        self.fromTime = fromTime
        self.toTime = toTime
        self.metadataFilters = metadataFilters
    }
    
    /**
     Checks if an event matches this filter.
     
     - Parameter event: The event to check
     
     - Returns: True if the event matches the filter criteria, false otherwise
     */
    public func matches(_ event: CryptoEventDTO) -> Bool {
        // Check event type
        if !eventTypes.isEmpty && !eventTypes.contains(event.eventType) {
            return false
        }
        
        // Check operation
        if !operations.isEmpty && !operations.contains(event.operation) {
            return false
        }
        
        // Check status
        if !statuses.isEmpty && !statuses.contains(event.status) {
            return false
        }
        
        // Check key identifier
        if !keyIdentifiers.isEmpty {
            if let keyId = event.keyIdentifier {
                if !keyIdentifiers.contains(keyId) {
                    return false
                }
            } else {
                return false  // Event has no key identifier
            }
        }
        
        // Check time range
        if let fromTime = fromTime, event.timestamp < fromTime {
            return false
        }
        
        if let toTime = toTime, event.timestamp > toTime {
            return false
        }
        
        // Check metadata filters
        for filter in metadataFilters {
            if !filter.matches(event.metadata) {
                return false
            }
        }
        
        return true
    }
    
    /**
     Creates a filter for encryption/decryption operations.
     
     - Parameters:
        - keyIdentifier: Optional key identifier to filter by
        - status: Optional status to filter by
     
     - Returns: A filter for encryption/decryption operations
     */
    public static func cryptoOperations(
        keyIdentifier: String? = nil,
        status: CryptoOperationStatus? = nil
    ) -> CryptoEventFilterDTO {
        var filter = CryptoEventFilterDTO(
            eventTypes: [.operation],
            operations: ["encrypt", "decrypt"]
        )
        
        if let keyId = keyIdentifier {
            filter = CryptoEventFilterDTO(
                eventTypes: filter.eventTypes,
                operations: filter.operations,
                statuses: filter.statuses,
                keyIdentifiers: [keyId],
                fromTime: filter.fromTime,
                toTime: filter.toTime,
                metadataFilters: filter.metadataFilters
            )
        }
        
        if let status = status {
            filter = CryptoEventFilterDTO(
                eventTypes: filter.eventTypes,
                operations: filter.operations,
                statuses: [status],
                keyIdentifiers: filter.keyIdentifiers,
                fromTime: filter.fromTime,
                toTime: filter.toTime,
                metadataFilters: filter.metadataFilters
            )
        }
        
        return filter
    }
    
    /**
     Creates a filter for key management operations.
     
     - Parameters:
        - keyIdentifier: Optional key identifier to filter by
        - status: Optional status to filter by
     
     - Returns: A filter for key management operations
     */
    public static func keyManagement(
        keyIdentifier: String? = nil,
        status: CryptoOperationStatus? = nil
    ) -> CryptoEventFilterDTO {
        var filter = CryptoEventFilterDTO(
            eventTypes: [.keyManagement]
        )
        
        if let keyId = keyIdentifier {
            filter = CryptoEventFilterDTO(
                eventTypes: filter.eventTypes,
                operations: filter.operations,
                statuses: filter.statuses,
                keyIdentifiers: [keyId],
                fromTime: filter.fromTime,
                toTime: filter.toTime,
                metadataFilters: filter.metadataFilters
            )
        }
        
        if let status = status {
            filter = CryptoEventFilterDTO(
                eventTypes: filter.eventTypes,
                operations: filter.operations,
                statuses: [status],
                keyIdentifiers: filter.keyIdentifiers,
                fromTime: filter.fromTime,
                toTime: filter.toTime,
                metadataFilters: filter.metadataFilters
            )
        }
        
        return filter
    }
    
    /**
     Creates a filter for events within a time range.
     
     - Parameters:
        - from: Start of the time range
        - to: End of the time range
     
     - Returns: A filter for events within the specified time range
     */
    public static func timeRange(
        from: TimePointDTO,
        to: TimePointDTO
    ) -> CryptoEventFilterDTO {
        CryptoEventFilterDTO(
            fromTime: from,
            toTime: to
        )
    }
}

/**
 # MetadataFilter
 
 Filter for event metadata.
 
 This struct provides criteria for filtering events based on
 their metadata keys and values.
 */
public struct MetadataFilter: Sendable, Equatable {
    /// The metadata key to filter on
    public let key: String
    
    /// The value to match, if exact matching is desired
    public let exactValue: String?
    
    /// The value to match against, if contains matching is desired
    public let containsValue: String?
    
    /**
     Creates a new MetadataFilter.
     
     - Parameters:
        - key: The metadata key to filter on
        - exactValue: The value to match exactly
     */
    public static func exact(key: String, value: String) -> MetadataFilter {
        MetadataFilter(key: key, exactValue: value, containsValue: nil)
    }
    
    /**
     Creates a new MetadataFilter.
     
     - Parameters:
        - key: The metadata key to filter on
        - containsValue: The value to check for containment
     */
    public static func contains(key: String, value: String) -> MetadataFilter {
        MetadataFilter(key: key, exactValue: nil, containsValue: value)
    }
    
    /**
     Checks if metadata matches this filter.
     
     - Parameter metadata: The metadata to check
     
     - Returns: True if the metadata matches the filter criteria, false otherwise
     */
    public func matches(_ metadata: LogMetadataDTOCollection) -> Bool {
        guard let entry = metadata.entries.first(where: { $0.key == key }) else {
            return false
        }
        
        if let exactValue = exactValue {
            return entry.value == exactValue
        }
        
        if let containsValue = containsValue {
            return entry.value.contains(containsValue)
        }
        
        return true  // No value criteria specified
    }
}
