import Foundation
import CoreDTOs

/**
 Data Transfer Object for persistence operation context.
 
 This DTO provides contextual information for persistence operations,
 including metadata about the operation being performed.
 */
public struct PersistenceContextDTO {
    /// The operation being performed (e.g., "create", "read", "update", "delete")
    public let operation: String
    
    /// The category or domain of the operation
    public let category: String
    
    /// Metadata associated with the operation
    public let metadata: MetadataDTOCollection
    
    /// Optional correlation ID for tracking related operations
    public let correlationId: String?
    
    /**
     Initialises a new persistence context.
     
     - Parameters:
        - operation: The operation being performed
        - category: The category or domain of the operation
        - metadata: Metadata associated with the operation
        - correlationId: Optional correlation ID for tracking related operations
     */
    public init(
        operation: String,
        category: String,
        metadata: MetadataDTOCollection = MetadataDTOCollection(),
        correlationId: String? = nil
    ) {
        self.operation = operation
        self.category = category
        self.metadata = metadata
        self.correlationId = correlationId ?? UUID().uuidString
    }
    
    /**
     Creates a new context with additional metadata.
     
     - Parameter metadata: The metadata to add to the context
     - Returns: A new context with the combined metadata
     */
    public func withMetadata(_ additionalMetadata: MetadataDTOCollection) -> PersistenceContextDTO {
        var combinedMetadata = self.metadata
        for (key, value) in additionalMetadata.items {
            combinedMetadata.add(key: key, value: value)
        }
        
        return PersistenceContextDTO(
            operation: self.operation,
            category: self.category,
            metadata: combinedMetadata,
            correlationId: self.correlationId
        )
    }
    
    /**
     Creates a new context with a different operation.
     
     - Parameter operation: The new operation name
     - Returns: A new context with the updated operation
     */
    public func withOperation(_ operation: String) -> PersistenceContextDTO {
        return PersistenceContextDTO(
            operation: operation,
            category: self.category,
            metadata: self.metadata,
            correlationId: self.correlationId
        )
    }
}
