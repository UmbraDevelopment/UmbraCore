import Foundation
import LoggingTypes

/**
 # Restic Log Context

 A structured context object for privacy-aware logging of Restic operations.
 This follows the Alpha Dot Five architecture principles for privacy-enhanced
 logging with appropriate data classification.

 The context uses builder pattern methods that return a new instance,
 allowing for immutable context objects and thread safety.
 */
public struct ResticLogContext: LogContextDTO, Sendable {
  /// The domain name for this context
  public let domainName: String="ResticServices"

  /// The operation being performed (required by protocol)
  public let operation: String

  /// The category for the log entry (required by protocol)
  public let category: String

  /// Optional source information (class, file, etc.)
  public let source: String?

  /// Correlation identifier for tracing related logs
  public let correlationID: String?

  /// Privacy-aware metadata for this log context
  public let metadata: LogMetadataDTOCollection

  /**
   Creates a new Restic log context.

   - Parameters:
     - operation: The operation being performed
     - category: The category for grouping logs
     - source: Optional source information
     - correlationID: Optional correlation ID
     - metadata: Optional initial metadata
   */
  public init(
    operation: String,
    category: String,
    source: String?=nil,
    correlationID: String?=nil,
    metadata: LogMetadataDTOCollection=LogMetadataDTOCollection()
  ) {
    self.operation=operation
    self.category=category
    self.source=source
    self.correlationID=correlationID
    self.metadata=metadata
  }

  /// Gets the source of this log context
  /// - Returns: The source identifier for logging
  public func getSource() -> String {
    if let source {
      return source
    }
    return "ResticService.\(operation)"
  }

  /// Creates a metadata collection from this context
  /// - Returns: A LogMetadataDTOCollection with appropriate privacy annotations
  public func createMetadataCollection() -> LogMetadataDTOCollection {
    var collection=metadata
    collection=collection.withPublic(key: "operation", value: operation)
    if let correlationID {
      collection=collection.withPublic(key: "correlationId", value: correlationID)
    }
    collection=collection.withPublic(key: "domain", value: domainName)
    return collection
  }

  /// Updates the context with new metadata
  /// - Parameter metadata: The new metadata to use
  /// - Returns: A new context with the updated metadata
  public func withUpdatedMetadata(_ metadata: LogMetadataDTOCollection) -> ResticLogContext {
    ResticLogContext(
      operation: operation,
      category: category,
      source: source,
      correlationID: correlationID,
      metadata: metadata
    )
  }

  /// Adds a public metadata entry to this context
  /// - Parameters:
  ///   - key: The metadata key
  ///   - value: The metadata value
  /// - Returns: A new context with the added public metadata
  public func withPublic(key: String, value: String) -> ResticLogContext {
    let updatedMetadata=metadata.withPublic(key: key, value: value)
    return ResticLogContext(
      operation: operation,
      category: category,
      source: source,
      correlationID: correlationID,
      metadata: updatedMetadata
    )
  }

  /// Adds a private metadata entry to this context
  /// - Parameters:
  ///   - key: The metadata key
  ///   - value: The metadata value
  /// - Returns: A new context with the added private metadata
  public func withPrivate(key: String, value: String) -> ResticLogContext {
    let updatedMetadata=metadata.withPrivate(key: key, value: value)
    return ResticLogContext(
      operation: operation,
      category: category,
      source: source,
      correlationID: correlationID,
      metadata: updatedMetadata
    )
  }

  /// Adds a sensitive metadata entry to this context
  /// - Parameters:
  ///   - key: The metadata key
  ///   - value: The metadata value
  /// - Returns: A new context with the added sensitive metadata
  public func withSensitive(key: String, value: String) -> ResticLogContext {
    let updatedMetadata=metadata.withSensitive(key: key, value: value)
    return ResticLogContext(
      operation: operation,
      category: category,
      source: source,
      correlationID: correlationID,
      metadata: updatedMetadata
    )
  }

  /// Adds additional metadata to this context
  /// - Parameter additionalMetadata: The additional metadata to include
  /// - Returns: A new context with the merged metadata
  public func withAdditionalMetadata(_ additionalMetadata: LogMetadataDTOCollection)
  -> ResticLogContext {
    let mergedMetadata=metadata.merging(with: additionalMetadata)
    return ResticLogContext(
      operation: operation,
      category: category,
      source: source,
      correlationID: correlationID,
      metadata: mergedMetadata
    )
  }

  /**
   Creates a new context with additional metadata merged with the existing metadata.

   - Parameter additionalMetadata: Additional metadata to include
   - Returns: New context with merged metadata
   */
  public func withMetadata(_ additionalMetadata: LogMetadataDTOCollection) -> Self {
    var newMetadata=metadata

    for entry in additionalMetadata.entries {
      switch entry.privacyLevel {
        case .public:
          newMetadata=newMetadata.withPublic(key: entry.key, value: entry.value)
        case .private:
          newMetadata=newMetadata.withPrivate(key: entry.key, value: entry.value)
        case .sensitive:
          newMetadata=newMetadata.withSensitive(key: entry.key, value: entry.value)
        case .hash:
          newMetadata=newMetadata.withHashed(key: entry.key, value: entry.value)
        default:
          // Default to private for any other privacy level
          newMetadata=newMetadata.withPrivate(key: entry.key, value: entry.value)
      }
    }

    return ResticLogContext(
      operation: operation,
      category: category,
      source: source,
      correlationID: correlationID,
      metadata: newMetadata
    )
  }
}
