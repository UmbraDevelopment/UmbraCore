import CoreDTOs
import Foundation
import LoggingTypes

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
  public let metadata: LogMetadataDTOCollection

  /// Optional correlation ID for tracking related operations
  public let correlationID: String?

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
    metadata: LogMetadataDTOCollection=LogMetadataDTOCollection(),
    correlationID: String?=nil
  ) {
    self.operation=operation
    self.category=category
    self.metadata=metadata
    self.correlationID=correlationID ?? UUID().uuidString
  }

  /**
   Creates a new context with additional metadata.

   - Parameter metadata: The metadata to add to the context
   - Returns: A new context with the combined metadata
   */
  public func withMetadata(_ additionalMetadata: LogMetadataDTOCollection)
  -> PersistenceContextDTO {
    var combinedMetadata=metadata
    for entry in additionalMetadata.entries {
      combinedMetadata=combinedMetadata.with(
        key: entry.key,
        value: entry.value,
        privacyLevel: entry.privacyLevel
      )
    }

    return PersistenceContextDTO(
      operation: operation,
      category: category,
      metadata: combinedMetadata,
      correlationID: correlationID
    )
  }

  /**
   Creates a new context with a different operation.

   - Parameter operation: The new operation name
   - Returns: A new context with the updated operation
   */
  public func withOperation(_ operation: String) -> PersistenceContextDTO {
    PersistenceContextDTO(
      operation: operation,
      category: category,
      metadata: metadata,
      correlationID: correlationID
    )
  }
}
