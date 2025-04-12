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
public struct ResticLogContext: LogContextDTO {
  /// The domain name for this context
  public let domainName: String="ResticServices"

  /// The operation being performed (required by protocol)
  public let operation: String

  /// The category for the log entry (required by protocol)
  public let category: String

  /// Correlation identifier for tracing related logs
  public let correlationID: String?

  /// Source information for logging
  public let source: String?

  /// Privacy-aware metadata for this log context
  public let metadata: LogMetadataDTOCollection

  /// Initialises a Restic log context
  public init(
    operation: String,
    category: String = "ResticBackup",
    metadata: LogMetadataDTOCollection = LogMetadataDTOCollection(),
    correlationID: String? = nil,
    source: String? = nil
  ) {
    self.operation = operation
    self.category = category
    self.correlationID = correlationID
    self.source = source
    self.metadata = metadata
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
    return ResticLogContext(
      operation: self.operation,
      category: self.category,
      metadata: metadata,
      correlationID: self.correlationID,
      source: self.source
    )
  }

  /// Adds a public metadata entry to this context
  /// - Parameters:
  ///   - key: The metadata key
  ///   - value: The metadata value
  /// - Returns: A new context with the added public metadata
  public func withPublic(key: String, value: String) -> ResticLogContext {
    let updatedMetadata = self.metadata.withPublic(key: key, value: value)
    return ResticLogContext(
      operation: self.operation,
      category: self.category,
      metadata: updatedMetadata,
      correlationID: self.correlationID,
      source: self.source
    )
  }

  /// Adds a private metadata entry to this context
  /// - Parameters:
  ///   - key: The metadata key
  ///   - value: The metadata value
  /// - Returns: A new context with the added private metadata
  public func withPrivate(key: String, value: String) -> ResticLogContext {
    let updatedMetadata = self.metadata.withPrivate(key: key, value: value)
    return ResticLogContext(
      operation: self.operation,
      category: self.category,
      metadata: updatedMetadata,
      correlationID: self.correlationID,
      source: self.source
    )
  }

  /// Adds a sensitive metadata entry to this context
  /// - Parameters:
  ///   - key: The metadata key
  ///   - value: The metadata value
  /// - Returns: A new context with the added sensitive metadata
  public func withSensitive(key: String, value: String) -> ResticLogContext {
    let updatedMetadata = self.metadata.withSensitive(key: key, value: value)
    return ResticLogContext(
      operation: self.operation,
      category: self.category,
      metadata: updatedMetadata,
      correlationID: self.correlationID,
      source: self.source
    )
  }

  /// Adds additional metadata to this context
  /// - Parameter additionalMetadata: The additional metadata to include
  /// - Returns: A new context with the merged metadata
  public func withAdditionalMetadata(_ additionalMetadata: LogMetadataDTOCollection)
  -> ResticLogContext {
    let mergedMetadata = self.metadata.merging(with: additionalMetadata)
    return ResticLogContext(
      operation: self.operation,
      category: self.category,
      metadata: mergedMetadata,
      correlationID: self.correlationID,
      source: self.source
    )
  }

  /**
   Creates a new context with additional metadata merged with the existing metadata.
   
   - Parameter additionalMetadata: Additional metadata to include
   - Returns: New context with merged metadata
   */
  public func withMetadata(_ additionalMetadata: LogMetadataDTOCollection) -> Self {
    var newMetadata = self.metadata
    
    for entry in additionalMetadata.entries {
      newMetadata = newMetadata.with(
        key: entry.key,
        value: entry.value,
        privacyLevel: entry.privacyLevel
      )
    }
    
    return ResticLogContext(
      operation: self.operation,
      category: self.category,
      metadata: newMetadata,
      correlationID: self.correlationID,
      source: self.source
    )
  }
}
