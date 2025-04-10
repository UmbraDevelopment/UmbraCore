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

  /// Correlation identifier for tracing related logs
  public let correlationID: String?

  /// Source information for logging
  public let source: String?

  /// Privacy-aware metadata for this log context
  public var metadata: LogMetadataDTOCollection

  /// Current operation being performed
  public var operation: String? {
    // Find operation in the metadata entries
    for entry in metadata.entries where entry.key == "operation" {
      return entry.value
    }
    return nil
  }

  /// Initialises a Restic log context
  public init(
    metadata: LogMetadataDTOCollection=LogMetadataDTOCollection(),
    correlationID: String?=nil,
    source: String?=nil
  ) {
    self.correlationID=correlationID
    self.source=source
    self.metadata=metadata
  }

  /// Gets the source of this log context
  /// - Returns: The source identifier for logging
  public func getSource() -> String {
    if let source {
      return source
    }
    if let op=operation {
      return "ResticService.\(op)"
    }
    return domainName
  }

  /// Creates a metadata collection from this context
  /// - Returns: A LogMetadataDTOCollection with appropriate privacy annotations
  public func createMetadataCollection() -> LogMetadataDTOCollection {
    var collection=metadata
    if let operation {
      collection=collection.withPublic(key: "operation", value: operation)
    }
    if let correlationID {
      collection=collection.withPublic(key: "correlationId", value: correlationID)
    }
    collection=collection.withPublic(key: "domain", value: domainName)
    return collection
  }

  /// Creates a new context with updated metadata
  /// - Parameter metadata: The new metadata collection
  /// - Returns: A new log context with updated metadata
  public func withUpdatedMetadata(_ metadata: LogMetadataDTOCollection) -> ResticLogContext {
    var newContext=self
    newContext.metadata=metadata
    return newContext
  }

  /// Adds a public metadata entry
  /// - Parameters:
  ///   - key: The metadata key
  ///   - value: The metadata value
  /// - Returns: A new context with the added metadata
  public func withPublic(key: String, value: String) -> ResticLogContext {
    var newContext=self
    newContext.metadata=newContext.metadata.withPublic(key: key, value: value)
    return newContext
  }

  /// Adds a private metadata entry
  /// - Parameters:
  ///   - key: The metadata key
  ///   - value: The metadata value
  /// - Returns: A new context with the added metadata
  public func withPrivate(key: String, value: String) -> ResticLogContext {
    var newContext=self
    newContext.metadata=newContext.metadata.withPrivate(key: key, value: value)
    return newContext
  }

  /// Adds a sensitive metadata entry
  /// - Parameters:
  ///   - key: The metadata key
  ///   - value: The metadata value
  /// - Returns: A new context with the added metadata
  public func withSensitive(key: String, value: String) -> ResticLogContext {
    var newContext=self
    newContext.metadata=newContext.metadata.withSensitive(key: key, value: value)
    return newContext
  }

  /// Adds additional metadata to this context
  /// - Parameter additionalMetadata: The metadata to add
  /// - Returns: A new context with the added metadata
  public func withAdditionalMetadata(_ additionalMetadata: LogMetadataDTOCollection)
  -> ResticLogContext {
    var newContext=self
    newContext.metadata=newContext.metadata.merging(with: additionalMetadata)
    return newContext
  }
}
