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
  /// The domain name for this context
  public let domainName: String="BackupServices"

  /// Correlation identifier for tracing related logs
  public let correlationID: String?

  /// Source information for the log
  public let source: String?

  /// Privacy-aware metadata for this log context
  public var metadata: LogMetadataDTOCollection

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
   *   - correlationID: Optional correlation ID for tracing
   */
  public init(
    snapshotID: String?=nil,
    operation: String,
    correlationID: String?=nil
  ) {
    self.snapshotID=snapshotID
    self.operation=operation
    self.correlationID=correlationID
    source="BackupServices.\(operation)"

    // Initialize the metadata collection
    var metadataCollection=LogMetadataDTOCollection()

    // Add basic context
    metadataCollection=metadataCollection.withPublic(key: "operation", value: operation)

    // Add snapshot ID if available
    if let id=snapshotID {
      metadataCollection=metadataCollection.withPublic(key: "snapshotID", value: id)
    }

    metadata=metadataCollection
  }

  /// Get the source of the log context
  public func getSource() -> String {
    source ?? "BackupServices.\(operation)"
  }

  /// Convert the context to privacy-aware metadata
  public func toPrivacyMetadata() -> PrivacyMetadata {
    metadata.toPrivacyMetadata()
  }

  /// Get the metadata for this context
  /// - Returns: The metadata collection for this context
  public func toMetadata() -> LogMetadataDTOCollection {
    metadata
  }

  /// Creates a new instance with updated metadata
  /// - Parameter metadata: The new metadata collection
  /// - Returns: A new context with updated metadata
  public func withUpdatedMetadata(_ metadata: LogMetadataDTOCollection) -> BackupLogContextAdapter {
    var newContext=self
    newContext.metadata=metadata
    return newContext
  }

  /// Add a context value with specified privacy
  /// - Parameters:
  ///   - key: The metadata key
  ///   - value: The metadata value
  ///   - privacy: The privacy level
  /// - Returns: A new context with the added information
  public func with(
    key: String,
    value: String,
    privacy: LogPrivacyLevel
  ) -> BackupLogContextAdapter {
    var newContext=self
    newContext.additionalContext.append((key: key, value: value, privacy: privacy))

    // Also update the metadata collection
    switch privacy {
      case .public:
        newContext.metadata=newContext.metadata.withPublic(key: key, value: value)
      case .private:
        newContext.metadata=newContext.metadata.withPrivate(key: key, value: value)
      case .sensitive:
        newContext.metadata=newContext.metadata.withSensitive(key: key, value: value)
      default:
        // Default to private for other levels
        newContext.metadata=newContext.metadata.withPrivate(key: key, value: value)
    }

    return newContext
  }
}
