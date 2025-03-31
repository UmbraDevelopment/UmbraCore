import BackupInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 * Adapter for creating structured log contexts from backup operations.
 *
 * This adapter provides a consistent way to create log contexts with
 * appropriate privacy controls for backup-related operations.
 */
public struct BackupLogContextAdapter: LogContextDTO {
  /// ID of the associated snapshot
  private let snapshotID: String?

  /// Operation being performed
  private let operation: String

  /// Additional context values with privacy annotations
  private var additionalContext: [(key: String, value: String, privacy: LogPrivacyLevel)]=[]

  /**
   * Creates a new backup log context.
   *
   * - Parameters:
   *   - snapshotID: Optional ID of the snapshot
   *   - operation: Name of the operation being performed
   */
  public init(snapshotID: String?=nil, operation: String) {
    self.snapshotID=snapshotID
    self.operation=operation
  }

  /// Get the source of the log context
  public func getSource() -> String {
    "BackupServices.\(operation)"
  }

  /// Convert the context to privacy-aware metadata
  public func toPrivacyMetadata() -> PrivacyMetadata {
    var metadata=PrivacyMetadata()

    // Add basic context
    metadata["operation"]=PrivacyMetadataValue(value: operation, privacy: .public)

    // Add snapshot ID if available
    if let id=snapshotID {
      metadata["snapshotID"]=PrivacyMetadataValue(value: id, privacy: .public)
    }

    // Add additional context values
    for (key, value, privacy) in additionalContext {
      metadata[key]=PrivacyMetadataValue(value: value, privacy: privacy)
    }

    return metadata
  }

  /**
   * Adds a new context value with privacy annotation.
   *
   * - Parameters:
   *   - key: The context key
   *   - value: The context value
   *   - privacy: Privacy level for the value
   * - Returns: A new context with the additional value
   */
  public func with(
    key: String,
    value: String,
    privacy: LogPrivacyLevel
  ) -> BackupLogContextAdapter {
    var newContext=self
    newContext.additionalContext.append((key: key, value: value, privacy: privacy))
    return newContext
  }
}
