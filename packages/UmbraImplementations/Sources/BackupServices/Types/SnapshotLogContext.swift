import Foundation
import LoggingTypes

/**
 * Context for snapshot-related logging.
 *
 * This structure provides a standardised way to include relevant snapshot
 * operation details in log messages while maintaining privacy awareness.
 */
public struct SnapshotLogContext: LogContextDTO {
  /// The domain name for this context
  public let domainName: String="BackupServices.Snapshot"

  /// Correlation identifier for tracing related logs
  public let correlationID: String?

  /// Source information for logging
  public let source: String?

  /// Privacy-aware metadata collection
  public var metadata: LogMetadataDTOCollection

  /// The operation being performed
  public let operation: String

  /// The snapshot ID (if applicable)
  public let snapshotID: String

  /// Optional error message if operation failed
  public let errorMessage: String?

  /**
   * Creates a new snapshot log context.
   *
   * - Parameters:
   *   - operation: The operation being performed
   *   - snapshotId: The snapshot ID (if applicable)
   *   - errorMessage: Optional error message if operation failed
   *   - correlationID: Optional correlation ID for tracing
   */
  public init(
    operation: String,
    snapshotID: String,
    errorMessage: String?=nil,
    correlationID: String?=nil
  ) {
    self.operation=operation
    self.snapshotID=snapshotID
    self.errorMessage=errorMessage
    self.correlationID=correlationID
    source="BackupServices.Snapshot.\(operation)"

    // Initialize metadata collection
    var metadataCollection=LogMetadataDTOCollection()
    metadataCollection=metadataCollection.withPublic(key: "operation", value: operation)
    metadataCollection=metadataCollection.withPublic(key: "snapshotId", value: snapshotID)

    if let errorMessage {
      metadataCollection=metadataCollection.withPrivate(key: "error", value: errorMessage)
    }

    metadata=metadataCollection
  }

  /**
   * Get the source identifier for this log context.
   *
   * - Returns: A formatted source string
   */
  public func getSource() -> String {
    source ?? "BackupServices.Snapshot.\(operation)"
  }

  /**
   * Creates a metadata collection for privacy-aware logging.
   *
   * - Returns: A LogMetadataDTOCollection with appropriate privacy annotations
   */
  public func createMetadataCollection() -> LogMetadataDTOCollection {
    metadata
  }

  /**
   * Get the metadata collection for this context.
   *
   * - Returns: The metadata collection
   */
  public func toMetadata() -> LogMetadataDTOCollection {
    metadata
  }

  /**
   * Creates a new instance of this context with updated metadata.
   *
   * - Parameter metadata: The new metadata collection
   * - Returns: A new context instance with updated metadata
   */
  public func withUpdatedMetadata(_ metadata: LogMetadataDTOCollection) -> SnapshotLogContext {
    var newContext=self
    newContext.metadata=metadata
    return newContext
  }
}
