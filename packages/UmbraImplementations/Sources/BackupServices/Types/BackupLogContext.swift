import Foundation
import LoggingTypes

/**
 # Backup Log Context

 A structured context object for privacy-aware logging of backup operations.
 This follows the Alpha Dot Five architecture principles for privacy-enhanced
 logging with appropriate data classification.

 The context uses builder pattern methods that return a new instance,
 allowing for immutable context objects and thread safety.
 */
public struct BackupLogContext: LogContextDTO {
  /// The domain name for this context
  public let domainName: String="BackupServices"

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

  /// Initialises an empty backup log context
  public init(correlationID: String?=nil, source: String?=nil) {
    self.correlationID=correlationID
    self.source=source
    metadata=LogMetadataDTOCollection()
  }

  /// Gets the source of this log context
  /// - Returns: The source identifier for logging
  public func getSource() -> String {
    if let source {
      return source
    }
    if let op=operation {
      return "BackupService.\(op)"
    }
    return "BackupService"
  }

  /// Converts the context to privacy metadata for logging
  /// - Returns: Privacy metadata with appropriate annotations
  @available(*, deprecated, message: "Use createMetadataCollection() instead for Swift 6 compatibility")
  public func toPrivacyMetadata() -> PrivacyMetadata {
    // Use the built-in conversion from LogMetadataDTOCollection
    metadata.toPrivacyMetadata()
  }

  /// Creates a metadata collection for privacy-aware logging
  /// - Returns: A LogMetadataDTOCollection with appropriate privacy annotations
  public func createMetadataCollection() -> LogMetadataDTOCollection {
    metadata
  }

  /// Gets the metadata for this log context
  /// - Returns: Log metadata with appropriate privacy annotations
  public func toMetadata() -> LogMetadataDTOCollection {
    metadata
  }

  /// Creates a new context with updated metadata
  /// - Parameter metadata: The new metadata collection
  /// - Returns: A new log context with updated metadata
  public func withUpdatedMetadata(_ metadata: LogMetadataDTOCollection) -> BackupLogContext {
    var newContext=self
    newContext.metadata=metadata
    return newContext
  }

  /// Adds a public metadata entry
  /// - Parameters:
  ///   - key: The metadata key
  ///   - value: The metadata value
  /// - Returns: A new context with the added metadata
  public func withPublic(key: String, value: String) -> BackupLogContext {
    var newContext=self
    newContext.metadata=newContext.metadata.withPublic(key: key, value: value)
    return newContext
  }

  /// Adds a private metadata entry
  /// - Parameters:
  ///   - key: The metadata key
  ///   - value: The metadata value
  /// - Returns: A new context with the added metadata
  public func withPrivate(key: String, value: String) -> BackupLogContext {
    var newContext=self
    newContext.metadata=newContext.metadata.withPrivate(key: key, value: value)
    return newContext
  }

  /// Adds a sensitive metadata entry
  /// - Parameters:
  ///   - key: The metadata key
  ///   - value: The metadata value
  /// - Returns: A new context with the added metadata
  public func withSensitive(key: String, value: String) -> BackupLogContext {
    var newContext=self
    newContext.metadata=newContext.metadata.withSensitive(key: key, value: value)
    return newContext
  }

  /// Adds an operation name to the context
  /// - Parameter operation: The operation name
  /// - Returns: A new context with the operation
  public func withOperation(_ operation: String) -> BackupLogContext {
    withPublic(key: "operation", value: operation)
  }
}
