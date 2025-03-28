import Foundation
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
        case .repositoryAccessFailure: return 1001
        case .invalidConfiguration: return 1002
        case .snapshotFailure: return 1003
        case .restoreFailure: return 1004
        case .snapshotNotFound: return 1005
        case .invalidPaths: return 1006
        case .insufficientPermissions: return 1007
        case .repositoryCorruption: return 1008
        case .maintenanceFailure: return 1009
        case .insufficientDiskSpace: return 1010
        case .operationCancelled: return 1011
        case .lockingError: return 1012
        case .inconsistentState: return 1013
        case .parsingError: return 1014
        case .authenticationFailure: return 1015
        case .commandExecutionFailure: return 1016
        case .timeoutError: return 1017
        case .genericError: return 1099
        }
    }
    
    /// User-friendly error description
    public var errorDescription: String? {
        switch self {
        case .repositoryAccessFailure(let path, let reason):
            return "Cannot access backup repository at \(path): \(reason)"
        case .invalidConfiguration(let details):
            return "Invalid backup configuration: \(details)"
        case .snapshotFailure(let id, let reason):
            if let id = id {
                return "Failed to process snapshot \(id): \(reason)"
            } else {
                return "Failed to create snapshot: \(reason)"
            }
        case .restoreFailure(let reason):
            return "Failed to restore backup: \(reason)"
        case .snapshotNotFound(let id):
            return "Snapshot not found: \(id)"
        case .invalidPaths(let paths):
            let pathList = paths.joined(separator: ", ")
            return "Invalid or inaccessible paths: \(pathList)"
        case .insufficientPermissions(let path):
            return "Insufficient permissions to access: \(path)"
        case .repositoryCorruption(let details):
            return "Backup repository is corrupt: \(details)"
        case .maintenanceFailure(let reason):
            return "Repository maintenance failed: \(reason)"
        case .insufficientDiskSpace(let available, let required):
            let availableMB = Double(available) / 1_048_576.0
            let requiredMB = Double(required) / 1_048_576.0
            return "Insufficient disk space: \(String(format: "%.1f", availableMB)) MB available, \(String(format: "%.1f", requiredMB)) MB required"
        case .operationCancelled:
            return "Backup operation was cancelled"
        case .lockingError(let reason):
            return "Repository locking error: \(reason)"
        case .inconsistentState(let details):
            return "Backup repository is in an inconsistent state: \(details)"
        case .parsingError(let details):
            return "Failed to parse command output: \(details)"
        case .authenticationFailure(let reason):
            return "Authentication failed: \(reason)"
        case .commandExecutionFailure(let command, let exitCode, _):
            return "Command execution failed: '\(command)' exited with code \(exitCode)"
        case .timeoutError(let operation, _):
            return "Operation timed out: \(operation)"
        case .genericError(let reason):
            return "Backup error: \(reason)"
        }
    }
    
    /// Detailed explanation of the error
    public var failureReason: String? {
        switch self {
        case .repositoryAccessFailure(_, let reason):
            return "The backup repository could not be accessed due to: \(reason)"
        case .invalidConfiguration(let details):
            return "The backup configuration is invalid: \(details)"
        case .snapshotFailure(_, let reason):
            return "The snapshot operation failed: \(reason)"
        case .restoreFailure(let reason):
            return "The restore operation could not be completed: \(reason)"
        case .snapshotNotFound(let id):
            return "The requested snapshot (\(id)) does not exist or was deleted"
        case .invalidPaths:
            return "One or more paths in the operation are invalid or cannot be accessed"
        case .insufficientPermissions(let path):
            return "The application does not have sufficient permissions to access \(path)"
        case .repositoryCorruption(let details):
            return "The backup repository structure is damaged: \(details)"
        case .maintenanceFailure(let reason):
            return "Repository maintenance failed: \(reason)"
        case .insufficientDiskSpace:
            return "There is not enough free disk space to complete the operation"
        case .operationCancelled:
            return "The operation was cancelled by the user or system"
        case .lockingError(let reason):
            return "Could not acquire exclusive lock on repository: \(reason)"
        case .inconsistentState(let details):
            return "The repository data is inconsistent: \(details)"
        case .parsingError(let details):
            return "Failed to parse command output: \(details)"
        case .authenticationFailure(let reason):
            return "Authentication with the repository failed: \(reason)"
        case .commandExecutionFailure(_, _, let errorOutput):
            return "Command failed with error: \(errorOutput)"
        case .timeoutError(_, let details):
            return "The operation timed out: \(details)"
        case .genericError(let reason):
            return reason
        }
    }
    
    /// Suggested recovery options
    public var recoverySuggestion: String? {
        switch self {
        case .repositoryAccessFailure(let path, _):
            return "Check network connectivity if the repository is remote. Verify that the path '\(path)' exists and is accessible."
        case .invalidConfiguration:
            return "Review your backup configuration and correct any errors in paths, options, or settings."
        case .snapshotFailure:
            return "Check available disk space and repository health. Try running maintenance on the repository to fix any issues."
        case .restoreFailure:
            return "Verify that the source snapshot exists and is intact. Check if the destination has sufficient permissions and disk space."
        case .snapshotNotFound:
            return "List available snapshots to see which ones are accessible. The snapshot may have been deleted or pruned automatically."
        case .invalidPaths:
            return "Verify that all paths exist and are correctly formatted. Check file permissions to ensure they are accessible."
        case .insufficientPermissions(let path):
            return "Adjust file system permissions to allow access to \(path), or run the application with elevated privileges."
        case .repositoryCorruption:
            return "Run repository maintenance with the 'check' and 'repair' options. If issues persist, restore from a known good backup."
        case .maintenanceFailure:
            return "Try running maintenance with different options. Ensure the repository is not in use by another process."
        case .insufficientDiskSpace:
            return "Free up disk space by removing unnecessary files or select a different destination with more available space."
        case .operationCancelled:
            return "Restart the operation when ready. No changes were made to your repository."
        case .lockingError:
            return "Ensure no other backup processes are running. If necessary, manually release the lock using maintenance tools."
        case .inconsistentState:
            return "Run repository verification and repair operations. Consider restoring from a known good state if problems persist."
        case .parsingError:
            return "Check the command output for errors. Verify that the command was executed correctly and try again."
        case .authenticationFailure:
            return "Verify the repository password is correct. If using key-based authentication, ensure your keys are valid."
        case .commandExecutionFailure:
            return "Check system resources and permissions. Verify the command parameters are correct and try again."
        case .timeoutError:
            return "Consider increasing the timeout duration or check for system resource constraints that might be slowing down the operation."
        case .genericError:
            return "Retry the operation. If the problem persists, check logs for more details or contact support."
        }
    }
}
