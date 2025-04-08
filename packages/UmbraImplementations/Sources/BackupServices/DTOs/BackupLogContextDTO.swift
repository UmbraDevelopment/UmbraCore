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
   * Converts this DTO to a LogContext for use with the privacy-aware logging system.
   */
  public func toLogContext() -> LogContext {
    var context=LogContext()

    context.add("operation_id", operationID, privacy: .public)
    context.add("operation_type", operationType.rawValue, privacy: .public)

    if let paths=sourcePaths {
      context.add("source_paths", paths, privacy: .private)
    }

    if let id=snapshotID {
      context.add("snapshot_id", id, privacy: .public)
    }

    if let id=repositoryID {
      context.add("repository_id", id, privacy: .public)
    }

    if let additional=additionalContext {
      for (key, value) in additional {
        context.add(key, value, privacy: .auto)
      }
    }

    return context
  }
}
