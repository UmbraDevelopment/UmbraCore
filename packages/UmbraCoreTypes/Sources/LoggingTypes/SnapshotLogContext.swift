import Foundation

/// A specialised log context for snapshot operations
///
/// This structure provides contextual information specific to snapshot
/// operations, with enhanced privacy controls for snapshot identifiers.
public struct SnapshotLogContext: LogContextDTO, Sendable {
  /// The name of the domain this context belongs to
  public let domainName: String="Snapshot"

  /// Correlation identifier for tracing related logs
  public let correlationID: String?

  /// Source information for the log (e.g., file, function, line)
  public let source: String?

  /// Privacy-aware metadata for this log context
  public let metadata: LogMetadataDTOCollection

  /// The snapshot identifier
  public let snapshotID: String

  /// The operation being performed
  public let operation: String

  /// Creates a new snapshot log context
  ///
  /// - Parameters:
  ///   - snapshotID: The snapshot identifier
  ///   - operation: The operation being performed
  ///   - correlationId: Optional correlation identifier for tracing related logs
  ///   - source: Optional source information (e.g., file, function, line)
  ///   - additionalContext: Optional additional context with privacy annotations
  public init(
    snapshotID: String,
    operation: String,
    correlationID: String?=nil,
    source: String?=nil,
    additionalContext: LogMetadataDTOCollection=LogMetadataDTOCollection()
  ) {
    self.snapshotID=snapshotID
    self.operation=operation
    self.correlationID=correlationID
    self.source=source

    // Start with the additional context
    var contextMetadata=additionalContext

    // Add snapshot ID as private metadata (potentially sensitive)
    contextMetadata=contextMetadata.withPrivate(key: "snapshotID", value: snapshotID)

    // Add operation as public metadata
    contextMetadata=contextMetadata.withPublic(key: "operation", value: operation)

    metadata=contextMetadata
  }

  /// Creates a new instance of this context with updated metadata
  ///
  /// - Parameter metadata: The metadata to add to the context
  /// - Returns: A new log context with the updated metadata
  public func withUpdatedMetadata(_ metadata: LogMetadataDTOCollection) -> SnapshotLogContext {
    SnapshotLogContext(
      snapshotID: snapshotID,
      operation: operation,
      correlationID: correlationID,
      source: source,
      additionalContext: self.metadata.merging(with: metadata)
    )
  }

  /// Creates a new instance of this context with a correlation ID
  ///
  /// - Parameter correlationId: The correlation ID to add
  /// - Returns: A new log context with the specified correlation ID
  public func withCorrelationID(_ correlationID: String) -> SnapshotLogContext {
    SnapshotLogContext(
      snapshotID: snapshotID,
      operation: operation,
      correlationID: correlationID,
      source: source,
      additionalContext: metadata
    )
  }

  /// Creates a new instance of this context with source information
  ///
  /// - Parameter source: The source information to add
  /// - Returns: A new log context with the specified source
  public func withSource(_ source: String) -> SnapshotLogContext {
    SnapshotLogContext(
      snapshotID: snapshotID,
      operation: operation,
      correlationID: correlationID,
      source: source,
      additionalContext: metadata
    )
  }
}
