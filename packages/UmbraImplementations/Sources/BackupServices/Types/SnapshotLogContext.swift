import Foundation
import LoggingTypes

/**
 * Context for snapshot-related logging.
 *
 * This structure provides a standardised way to include relevant snapshot
 * operation details in log messages while maintaining privacy awareness.
 */
public struct SnapshotLogContext: LogContextDTO {
  /// The operation being performed
  public let operation: String

  /// The snapshot ID (if applicable)
  public let snapshotID: String

  /// Optional error message if operation failed
  public let errorMessage: String?

  /// Private metadata collection
  private var metadata: PrivacyMetadata

  /**
   * Creates a new snapshot log context.
   *
   * - Parameters:
   *   - operation: The operation being performed
   *   - snapshotId: The snapshot ID (if applicable)
   *   - errorMessage: Optional error message if operation failed
   */
  public init(
    operation: String,
    snapshotID: String,
    errorMessage: String?=nil
  ) {
    self.operation=operation
    self.snapshotID=snapshotID
    self.errorMessage=errorMessage

    // Initialize metadata
    metadata=PrivacyMetadata()
    metadata["operation"]=PrivacyMetadataValue(value: operation, privacy: .public)
    metadata["snapshotId"]=PrivacyMetadataValue(value: snapshotID, privacy: .public)

    if let errorMessage {
      metadata["error"]=PrivacyMetadataValue(value: errorMessage, privacy: .private)
    }
  }

  /**
   * Get the source identifier for this log context.
   *
   * - Returns: The source identifier
   */
  public func getSource() -> String {
    "BackupServices.Snapshot"
  }

  /**
   * Get the privacy metadata for this log context.
   *
   * - Returns: The privacy metadata
   */
  public func toPrivacyMetadata() -> PrivacyMetadata {
    metadata
  }
}
