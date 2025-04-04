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
  public let domainName: String = "BackupServices.Snapshot"
  
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

  /// Private metadata collection for backwards compatibility
  private var privacyMetadata: PrivacyMetadata

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
    errorMessage: String? = nil,
    correlationID: String? = nil
  ) {
    self.operation = operation
    self.snapshotID = snapshotID
    self.errorMessage = errorMessage
    self.correlationID = correlationID
    self.source = "BackupServices.Snapshot.\(operation)"

    // Initialize metadata collection
    var metadataCollection = LogMetadataDTOCollection()
    metadataCollection = metadataCollection.withPublic(key: "operation", value: operation)
    metadataCollection = metadataCollection.withPublic(key: "snapshotId", value: snapshotID)

    if let errorMessage {
      metadataCollection = metadataCollection.withPrivate(key: "error", value: errorMessage)
    }
    
    self.metadata = metadataCollection

    // Initialize legacy metadata for backwards compatibility
    privacyMetadata = PrivacyMetadata()
    privacyMetadata["operation"] = PrivacyMetadataValue(value: operation, privacy: .public)
    privacyMetadata["snapshotId"] = PrivacyMetadataValue(value: snapshotID, privacy: .public)

    if let errorMessage {
      privacyMetadata["error"] = PrivacyMetadataValue(value: errorMessage, privacy: .private)
    }
  }

  /**
   * Get the source identifier for this log context.
   *
   * - Returns: A formatted source string
   */
  public func getSource() -> String {
    return source ?? "BackupServices.Snapshot.\(operation)"
  }

  /**
   * Convert to privacy metadata for logging.
   *
   * - Returns: Privacy metadata with appropriate annotations
   */
  public func toPrivacyMetadata() -> PrivacyMetadata {
    return metadata.toPrivacyMetadata()
  }
  
  /**
   * Get the metadata collection for this context.
   *
   * - Returns: The metadata collection
   */
  public func toMetadata() -> LogMetadataDTOCollection {
    return metadata
  }
  
  /**
   * Creates a new instance of this context with updated metadata.
   *
   * - Parameter metadata: The new metadata collection
   * - Returns: A new context instance with updated metadata
   */
  public func withUpdatedMetadata(_ metadata: LogMetadataDTOCollection) -> SnapshotLogContext {
    var newContext = self
    newContext.metadata = metadata
    return newContext
  }
}
