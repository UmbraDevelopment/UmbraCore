import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 * A bookmark-specific log context for structured logging of security bookmark operations.
 *
 * This provides metadata tailored for bookmark operations including operation type,
 * bookmark identifiers, and status with appropriate privacy controls.
 */
public struct BookmarkLogContext: LogContextDTO {
  /// The domain name for the log
  public let domainName: String

  /// The category for the log entry
  public let category: String

  /// The source of the log entry
  public let source: String?

  /// Correlation ID for tracking related log entries
  public let correlationID: String?

  /// The metadata collection for this log entry
  public let metadata: LogMetadataDTOCollection

  /// The type of bookmark operation being performed
  public let operation: String

  /// The bookmark identifier (with privacy protection)
  public let identifier: String?

  /// The status of the operation
  public let status: String

  /**
   * Creates a new BookmarkLogContext instance.
   *
   * - Parameters:
   *   - domainName: Domain name for the log
   *   - source: Source of the log entry
   *   - correlationID: Correlation ID for related log entries
   *   - metadata: Initial metadata collection (defaults to empty)
   *   - operation: Bookmark operation being performed
   *   - identifier: Bookmark identifier
   *   - status: Operation status
   */
  public init(
    domainName: String,
    category: String="Bookmarks",
    source: String?=nil,
    correlationID: String?=nil,
    metadata: LogMetadataDTOCollection=LogMetadataDTOCollection(),
    operation: String,
    identifier: String?=nil,
    status: String
  ) {
    self.domainName=domainName
    self.category=category
    self.source=source
    self.correlationID=correlationID
    self.operation=operation
    self.identifier=identifier
    self.status=status

    // Create a new metadata collection with bookmark-specific fields
    var enhancedMetadata=metadata
    enhancedMetadata=enhancedMetadata.withPublic(key: "operation", value: operation)
    enhancedMetadata=enhancedMetadata.withPublic(key: "status", value: status)

    if let identifier {
      enhancedMetadata=enhancedMetadata.withPrivate(key: "identifier", value: identifier)
    }

    self.metadata=enhancedMetadata
  }

  /**
   * Creates an updated copy of this context with new metadata.
   *
   * - Parameter metadata: The new metadata collection
   * - Returns: A new context with updated metadata
   */
  public func withUpdatedMetadata(_ metadata: LogMetadataDTOCollection) -> BookmarkLogContext {
    BookmarkLogContext(
      domainName: domainName,
      category: category,
      source: source,
      correlationID: correlationID,
      metadata: metadata,
      operation: operation,
      identifier: identifier,
      status: status
    )
  }

  /**
   * Updates the context with additional metadata.
   *
   * - Parameter additionalMetadata: Additional metadata to include
   * - Returns: A new context with merged metadata
   */
  public func withMetadata(_ additionalMetadata: LogMetadataDTOCollection) -> Self {
    withUpdatedMetadata(metadata.merging(with: additionalMetadata))
  }

  /**
   * Gets the source of this log context.
   *
   * - Returns: The source identifier for logging
   */
  public func getSource() -> String {
    if let source {
      return source
    }
    return "\(domainName).\(operation)"
  }

  /**
   * Creates a metadata collection from this context.
   *
   * - Returns: A LogMetadataDTOCollection with appropriate privacy annotations
   */
  public func createMetadataCollection() -> LogMetadataDTOCollection {
    var collection=metadata

    // Add standard fields with appropriate privacy levels
    collection=collection.withPublic(key: "operation", value: operation)
    collection=collection.withPublic(key: "status", value: status)
    collection=collection.withPublic(key: "domain", value: domainName)

    if let identifier {
      collection=collection.withPrivate(key: "identifier", value: identifier)
    }

    if let correlationID {
      collection=collection.withPublic(key: "correlationId", value: correlationID)
    }

    return collection
  }

  /**
   * Adds additional metadata to this context.
   *
   * - Parameter additionalMetadata: The metadata to add
   * - Returns: A new context with the additional metadata
   */
  public func withAdditionalMetadata(_ additionalMetadata: LogMetadataDTOCollection)
  -> BookmarkLogContext {
    let combinedMetadata=metadata.merging(with: additionalMetadata)

    return BookmarkLogContext(
      domainName: domainName,
      category: category,
      source: source,
      correlationID: correlationID,
      metadata: combinedMetadata,
      operation: operation,
      identifier: identifier,
      status: status
    )
  }

  /**
   * Adds a public metadata entry to the context.
   *
   * - Parameters:
   *   - key: The metadata key
   *   - value: The metadata value
   * - Returns: A new context with the added metadata
   */
  public func withPublicMetadata(key: String, value: String) -> BookmarkLogContext {
    withUpdatedMetadata(metadata.withPublic(key: key, value: value))
  }

  /**
   * Adds a private metadata entry to the context.
   *
   * - Parameters:
   *   - key: The metadata key
   *   - value: The metadata value
   * - Returns: A new context with the added metadata
   */
  public func withPrivateMetadata(key: String, value: String) -> BookmarkLogContext {
    withUpdatedMetadata(metadata.withPrivate(key: key, value: value))
  }

  /**
   * Adds a sensitive metadata entry to the context.
   *
   * - Parameters:
   *   - key: The metadata key
   *   - value: The metadata value
   * - Returns: A new context with the added metadata
   */
  public func withSensitiveMetadata(key: String, value: String) -> BookmarkLogContext {
    withUpdatedMetadata(metadata.withSensitive(key: key, value: value))
  }
}
