import Foundation
import LoggingInterfaces
import UmbraErrors

/// Comprehensive error type for backup operations
///
/// Provides detailed context, localised descriptions, and
/// recovery suggestions for backup-related errors.
public enum BackupError: Error, CustomNSError, LocalizedError {
  /// Error when backup repository cannot be accessed
  case repositoryAccessFailure(path: String, reason: String)

  /// Error when backup configuration is invalid
  case invalidConfiguration(details: String)

  /// Error when snapshot operation fails
  case snapshotFailure(id: String?, reason: String)

  /// Error when restore operation fails
  case restoreFailure(reason: String)

  /// Error when snapshot not found
  case snapshotNotFound(id: String)

  /// Error when paths are invalid or inaccessible
  case invalidPaths(paths: [String])

  /// Error when operation failed with specific details
  case operationFailed(path: String, reason: String, code: String)

  /// Error with insufficient permissions for operation
  case insufficientPermissions(path: String)

  /// Error when repository is corrupt or damaged
  case repositoryCorruption(details: String)

  /// Error when maintenance operation fails
  case maintenanceFailure(reason: String)

  /// Error caused by low disk space
  case insufficientDiskSpace(available: UInt64, required: UInt64)

  /// Error when operation is cancelled
  case operationCancelled

  /// Error related to repository locking
  case lockingError(reason: String)

  /// Error when backup repository has inconsistent data
  case inconsistentState(details: String)

  /// Error parsing command outputs from Restic
  case parsingError(details: String)

  /// Error when authentication fails (e.g., wrong password)
  case authenticationFailure(reason: String)

  /// Error when a command execution fails
  case commandExecutionFailure(command: String, exitCode: Int, errorOutput: String)

  /// Error when an operation times out
  case timeoutError(operation: String, details: String)

  /// Generic backup error with reason
  case genericError(reason: String)

  /// NSError domain for backup errors
  public static var errorDomain: String {
    "com.umbra.backup.error"
  }

  /// NSError code for backup errors
  public var errorCode: Int {
    switch self {
      case .repositoryAccessFailure: 1001
      case .invalidConfiguration: 1002
      case .snapshotFailure: 1003
      case .restoreFailure: 1004
      case .snapshotNotFound: 1005
      case .invalidPaths: 1006
      case .insufficientPermissions: 1007
      case .repositoryCorruption: 1008
      case .maintenanceFailure: 1009
      case .insufficientDiskSpace: 1010
      case .operationCancelled: 1011
      case .lockingError: 1012
      case .inconsistentState: 1013
      case .parsingError: 1014
      case .authenticationFailure: 1015
      case .commandExecutionFailure: 1016
      case .timeoutError: 1017
      case .operationFailed: 1018
      case .genericError: 1099
    }
  }

  /// User-friendly error description
  public var errorDescription: String? {
    switch self {
      case let .repositoryAccessFailure(path, reason):
        return "Cannot access backup repository at \(path.asBackupPath()): \(reason.asErrorDetail())"
      case let .invalidConfiguration(details):
        return "Invalid backup configuration: \(details.asErrorDetail())"
      case let .snapshotFailure(id, reason):
        if let id {
          return "Failed to process snapshot \(id.asBackupID()): \(reason.asErrorDetail())"
        } else {
          return "Failed to create snapshot: \(reason.asErrorDetail())"
        }
      case let .restoreFailure(reason):
        return "Failed to restore backup: \(reason.asErrorDetail())"
      case let .snapshotNotFound(id):
        return "Snapshot not found: \(id.asBackupID())"
      case let .invalidPaths(paths):
        return "Invalid or inaccessible paths: \(paths.asPrivatePaths())"
      case let .insufficientPermissions(path):
        return "Insufficient permissions to access: \(path.asBackupPath())"
      case let .repositoryCorruption(details):
        return "Backup repository is corrupt: \(details.asErrorDetail())"
      case let .maintenanceFailure(reason):
        return "Repository maintenance failed: \(reason.asErrorDetail())"
      case let .insufficientDiskSpace(available, required):
        let availableMB=Double(available) / 1_048_576.0
        let requiredMB=Double(required) / 1_048_576.0
        let availableFormatted=String(format: "%.1f", availableMB).asPublicInfo()
        let requiredFormatted=String(format: "%.1f", requiredMB).asPublicInfo()
        return "Insufficient disk space: \(availableFormatted) MB available, \(requiredFormatted) MB required"
      case .operationCancelled:
        return "Backup operation was cancelled"
      case let .lockingError(reason):
        return "Repository locking error: \(reason.asErrorDetail())"
      case let .inconsistentState(details):
        return "Backup repository is in an inconsistent state: \(details.asErrorDetail())"
      case let .parsingError(details):
        return "Failed to parse command output: \(details.asErrorDetail())"
      case let .authenticationFailure(reason):
        return "Authentication failed: \(reason.asErrorDetail())"
      case let .commandExecutionFailure(command, exitCode, _):
        return "Command execution failed: '\(command.asCommandOutput())' exited with code \(String(exitCode).asErrorCode())"
      case let .timeoutError(operation, _):
        return "Operation timed out: \(operation.asPublicInfo())"
      case let .operationFailed(path, reason, _):
        return "Operation failed at \(path.asBackupPath()): \(reason.asErrorDetail())"
      case let .genericError(reason):
        return "Backup error: \(reason.asErrorDetail().content)"
    }
  }

  /// Detailed explanation of the error
  public var failureReason: String? {
    switch self {
      case let .repositoryAccessFailure(_, reason):
        "The backup repository could not be accessed due to: \(reason.asErrorDetail())"
      case let .invalidConfiguration(details):
        "The backup configuration is invalid: \(details.asErrorDetail())"
      case let .snapshotFailure(_, reason):
        "The snapshot operation failed: \(reason.asErrorDetail())"
      case let .restoreFailure(reason):
        "The restore operation could not be completed: \(reason.asErrorDetail())"
      case let .snapshotNotFound(id):
        "The requested snapshot (\(id.asBackupID())) does not exist or was deleted"
      case .invalidPaths:
        "One or more paths in the operation are invalid or cannot be accessed"
      case let .insufficientPermissions(path):
        "The application does not have sufficient permissions to access \(path.asBackupPath())"
      case let .repositoryCorruption(details):
        "The backup repository structure is damaged: \(details.asErrorDetail())"
      case let .maintenanceFailure(reason):
        "Repository maintenance failed: \(reason.asErrorDetail())"
      case .insufficientDiskSpace:
        "There is not enough free disk space to complete the operation"
      case .operationCancelled:
        "The operation was cancelled by the user or system"
      case let .lockingError(reason):
        "Could not acquire exclusive lock on repository: \(reason.asErrorDetail())"
      case let .inconsistentState(details):
        "The repository data is inconsistent: \(details.asErrorDetail())"
      case let .parsingError(details):
        "Failed to parse command output: \(details.asErrorDetail())"
      case let .authenticationFailure(reason):
        "Authentication with the repository failed: \(reason.asErrorDetail())"
      case let .commandExecutionFailure(_, _, errorOutput):
        "Command failed with error: \(errorOutput.asErrorDetail())"
      case let .timeoutError(_, details):
        "The operation timed out: \(details.asErrorDetail())"
      case let .operationFailed(_, reason, _):
        "The operation failed due to: \(reason.asErrorDetail())"
      case let .genericError(reason):
        reason.asErrorDetail().content
    }
  }

  /// Suggested recovery options
  public var recoverySuggestion: String? {
    switch self {
      case let .repositoryAccessFailure(path, _):
        "Check network connectivity if the repository is remote. Verify that the path '\(path.asBackupPath())' exists and is accessible."
      case .invalidConfiguration:
        "Review your backup configuration and correct any errors in paths, options, or settings."
      case .snapshotFailure:
        "Check available disk space and repository health. Try running maintenance on the repository to fix any issues."
      case .restoreFailure:
        "Verify that the source snapshot exists and is intact. Check if the destination has sufficient permissions and disk space."
      case .snapshotNotFound:
        "List available snapshots to see which ones are accessible. The snapshot may have been deleted or pruned automatically."
      case .invalidPaths:
        "Verify that all paths exist and are correctly formatted. Check file permissions to ensure they are accessible."
      case let .insufficientPermissions(path):
        "Adjust file system permissions to allow access to \(path.asBackupPath()), or run the application with elevated privileges."
      case .repositoryCorruption:
        "Run repository maintenance with the 'check' and 'repair' options. If issues persist, restore from a known good backup."
      case .maintenanceFailure:
        "Try running maintenance with different options. Ensure the repository is not in use by another process."
      case .insufficientDiskSpace:
        "Free up disk space by removing unnecessary files or select a different destination with more available space."
      case .operationCancelled:
        "Restart the operation when ready. No changes were made to your repository."
      case .lockingError:
        "Ensure no other backup processes are running. If necessary, manually release the lock using maintenance tools."
      case .inconsistentState:
        "Run repository verification and repair operations. Consider restoring from a known good state if problems persist."
      case .parsingError:
        "Check the command output for errors. Verify that the command was executed correctly and try again."
      case .authenticationFailure:
        "Verify the repository password is correct. If using key-based authentication, ensure your keys are valid."
      case .commandExecutionFailure:
        "Check system resources and permissions. Verify the command parameters are correct and try again."
      case .timeoutError:
        "Consider increasing the timeout duration or check for system resource constraints that might be slowing down the operation."
      case .operationFailed:
        "Retry the operation. If the problem persists, check logs for more details or contact support."
      case .genericError:
        "Retry the operation. If the problem persists, check logs for more details or contact support."
    }
  }
}
