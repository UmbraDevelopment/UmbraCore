import BackupInterfaces
import Foundation

/**
 * Extension to BackupOperationError to add API-specific error types
 * needed by the APIServices module.
 */
extension BackupOperationError {
  /// Define and match the extension methods being used in the error handler
  /// Error when a repository with the specified ID is not found
  public static func repositoryNotFound(id: String) -> BackupOperationError {
    .custom(code: "REPOSITORY_NOT_FOUND", message: "Repository not found: \(id)")
  }

  /// Error when a snapshot with the specified ID is not found
  public static func snapshotNotFound(id: String) -> BackupOperationError {
    .custom(code: "SNAPSHOT_NOT_FOUND", message: "Snapshot not found: \(id)")
  }

  /// Error when a backup operation fails
  public static func backupFailed(message: String) -> BackupOperationError {
    .custom(code: "BACKUP_FAILED", message: message)
  }

  /// Error when a specified path is not found
  public static func pathNotFound(path: String) -> BackupOperationError {
    .custom(code: "PATH_NOT_FOUND", message: "Path not found: \(path)")
  }

  /// Error when permission is denied for an operation
  public static func permissionDenied(message: String) -> BackupOperationError {
    .custom(code: "PERMISSION_DENIED", message: message)
  }

  /// Error when an invalid operation is attempted
  public static func invalidOperation(message: String) -> BackupOperationError {
    .custom(code: "INVALID_OPERATION", message: message)
  }

  /// Error when a restore operation fails
  public static func operationFailed(message: String) -> BackupOperationError {
    .custom(code: "OPERATION_FAILED", message: message)
  }

  /**
   Error thrown when a snapshot with the specified ID cannot be found.

   - Parameter id: The ID of the snapshot that couldn't be found
   - Returns: A BackupOperationError with the snapshotNotFound case
   */
  public static func snapshotNotFound(id: String) -> BackupOperationError {
    .custom(code: "snapshot_not_found", message: "Snapshot not found with ID: \(id)")
  }

  /**
   Error thrown when a backup operation fails due to any reason.

   - Parameter message: A descriptive message explaining why the backup failed
   - Returns: A BackupOperationError with the backupFailed case
   */
  public static func backupFailed(message: String) -> BackupOperationError {
    .custom(code: "backup_failed", message: message)
  }

  /**
   Error thrown when a path specified in a backup operation cannot be found.

   - Parameter path: The path that couldn't be found
   - Returns: A BackupOperationError with the pathNotFound case
   */
  public static func pathNotFound(path: String) -> BackupOperationError {
    .custom(code: "path_not_found", message: "Path not found: \(path)")
  }

  /**
   Error thrown when a backup operation fails due to permission issues.

   - Parameter message: A descriptive message explaining the permission issue
   - Returns: A BackupOperationError with the permissionDenied case
   */
  public static func permissionDenied(message: String) -> BackupOperationError {
    .custom(code: "permission_denied", message: message)
  }

  /**
   Error thrown when a backup operation is invalid or cannot be performed.

   - Parameter message: A descriptive message explaining why the operation is invalid
   - Returns: A BackupOperationError with the invalidOperation case
   */
  public static func invalidOperation(message: String) -> BackupOperationError {
    .custom(code: "invalid_operation", message: message)
  }

  /**
   Error thrown when a repository cannot be found.

   - Parameter id: The ID of the repository that couldn't be found
   - Returns: A BackupOperationError with the repositoryNotFound case
   */
  public static func repositoryNotFound(id: String) -> BackupOperationError {
    .custom(code: "repository_not_found", message: "Repository not found with ID: \(id)")
  }
}
