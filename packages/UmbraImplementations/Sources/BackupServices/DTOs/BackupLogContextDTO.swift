import Foundation
import LoggingTypes

/**
 * Data Transfer Object for backup operation logging context.
 * Provides structured context information for privacy-aware logging.
 */
public struct BackupLogContextDTO: Sendable, Equatable {
  /// The ID of the backup operation
  public let operationID: String

  /// The type of backup operation being performed
  public let operationType: OperationType

  /// The source paths involved in the operation
  public let sourcePaths: [String]?

  /// The snapshot ID if applicable
  public let snapshotID: String?

  /// The repository ID
  public let repositoryID: String?

  /// Additional context information
  public let additionalContext: [String: String]?

  /// Operation types for backup operations
  public enum OperationType: String, Sendable, Equatable {
    case create
    case restore
    case verify
    case compare
    case maintenance
    case list
    case delete
    case search
  }

  /**
   * Creates a new backup log context.
   *
   * - Parameters:
   *   - operationID: The ID of the backup operation
   *   - operationType: The type of backup operation being performed
   *   - sourcePaths: The source paths involved in the operation
   *   - snapshotID: The snapshot ID if applicable
   *   - repositoryID: The repository ID
   *   - additionalContext: Additional context information
   */
  public init(
    operationID: String=UUID().uuidString,
    operationType: OperationType,
    sourcePaths: [String]?=nil,
    snapshotID: String?=nil,
    repositoryID: String?=nil,
    additionalContext: [String: String]?=nil
  ) {
    self.operationID=operationID
    self.operationType=operationType
    self.sourcePaths=sourcePaths
    self.snapshotID=snapshotID
    self.repositoryID=repositoryID
    self.additionalContext=additionalContext
  }

  /**
   * Creates a new backup log context with default values.
   */
  public init() {
    operationID=UUID().uuidString
    operationType = .create
    sourcePaths=nil
    snapshotID=nil
    repositoryID=nil
    additionalContext=nil
  }

  /**
   * Converts this DTO to a metadata collection for use with the privacy-aware logging system.
   *
   * @returns A LogMetadataDTOCollection with appropriate privacy annotations
   */
  public func toMetadataCollection() -> LogMetadataDTOCollection {
    var collection=LogMetadataDTOCollection()
      .withPublic(key: "operation_id", value: operationID)
      .withPublic(key: "operation_type", value: operationType.rawValue)

    if let paths=sourcePaths {
      // Paths may contain sensitive information, so mark as private
      for (index, path) in paths.enumerated() {
        collection=collection.withPrivate(key: "source_path_\(index)", value: path)
      }
    }

    if let id=snapshotID {
      collection=collection.withPublic(key: "snapshot_id", value: id)
    }

    if let id=repositoryID {
      collection=collection.withPublic(key: "repository_id", value: id)
    }

    if let additional=additionalContext {
      for (key, value) in additional {
        // Apply appropriate privacy level based on the key
        if key.contains("path") || key.contains("file") || key.contains("directory") {
          // Paths may contain sensitive information
          collection=collection.withPrivate(key: key, value: value)
        } else if
          key.contains("password") || key.contains("key") || key.contains("secret") || key
            .contains("token")
        {
          // Credentials are sensitive
          collection=collection.withSensitive(key: key, value: value)
        } else if
          key.contains("id") || key.contains("type") || key.contains("count") || key
            .contains("size")
        {
          // IDs, types, and metrics are generally public
          collection=collection.withPublic(key: key, value: value)
        } else {
          // Default to private for unknown keys
          collection=collection.withPrivate(key: key, value: value)
        }
      }
    }

    return collection
  }

  /**
   * Creates a LogContextDTO for use with the privacy-aware logging system.
   *
   * @returns A LogContextDTO with appropriate privacy annotations
   */
  public func toLogContextDTO() -> LogContextDTO {
    BackupLogContext(
      operation: operationType.rawValue,
      source: "BackupService",
      metadata: toMetadataCollection()
    )
  }
}
