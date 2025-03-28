import Foundation
import UmbraErrors
import BackupInterfaces
import ResticInterfaces

/// Provides error mapping functionality for backup operations
///
/// This utility converts low-level Restic errors into domain-specific
/// BackupError types that are more meaningful to clients of the backup services.
struct ErrorMapper {
    
    /// Converts a ResticError to a BackupError
    /// - Parameter error: The original Restic error
    /// - Returns: An appropriate BackupError
    func convertResticError(_ error: ResticError) -> BackupError {
        switch error {
        case .repositoryNotFound(let path):
            return BackupError.repositoryAccessFailure(
                path: path,
                reason: "Repository not found"
            )
            
        case .permissionDenied(let path):
            return BackupError.repositoryAccessFailure(
                path: path,
                reason: "Access denied"
            )
            
        case .invalidPassword:
            return BackupError.authenticationFailure(
                reason: "Invalid repository password"
            )
            
        case .missingParameter(let param):
            return BackupError.invalidConfiguration(
                details: "Missing parameter: \(param)"
            )
            
        case .invalidParameter(let param):
            return BackupError.invalidConfiguration(
                details: "Invalid parameter: \(param)"
            )
            
        case .executionFailure(let exitCode, let message):
            return BackupError.commandExecutionFailure(
                command: "restic",
                exitCode: exitCode,
                errorOutput: message
            )
            
        case .executionFailed(let message):
            return BackupError.commandExecutionFailure(
                command: "restic",
                exitCode: -1,
                errorOutput: message
            )
            
        case .executionTimeout:
            return BackupError.commandExecutionFailure(
                command: "restic",
                exitCode: -1,
                errorOutput: "Command execution timed out"
            )
            
        case .invalidCommand(let message):
            return BackupError.invalidConfiguration(
                details: "Invalid command: \(message)"
            )
            
        case .invalidConfiguration(let message):
            return BackupError.invalidConfiguration(
                details: message
            )
            
        case .invalidData(let message):
            return BackupError.parsingError(
                details: "Invalid data: \(message)"
            )
            
        case .backupFailed(let message):
            return BackupError.genericError(
                reason: "Backup failed: \(message)"
            )
            
        case .restoreFailed(let message):
            return BackupError.genericError(
                reason: "Restore failed: \(message)"
            )
            
        case .checkFailed(let message):
            return BackupError.genericError(
                reason: "Repository check failed: \(message)"
            )
            
        case .maintenanceFailed(let message):
            return BackupError.genericError(
                reason: "Maintenance failed: \(message)"
            )
            
        case .generalError(let message):
            return BackupError.genericError(
                reason: message
            )
        }
    }
    
    /// Maps an exit code to a BackupError if it represents a failure
    /// - Parameters:
    ///   - exitCode: The command exit code
    ///   - errorOutput: Error output from the command
    /// - Returns: An appropriate BackupError
    func mapExitCodeToError(
        exitCode: Int,
        errorOutput: String
    ) -> BackupError {
        // Specific exit code handling
        if exitCode == 1 {
            if errorOutput.contains("no snapshot") || errorOutput.contains("not found") {
                return BackupError.snapshotNotFound(id: "unknown")
            } else {
                return BackupError.commandExecutionFailure(
                    command: "restic",
                    exitCode: exitCode,
                    errorOutput: errorOutput
                )
            }
        }
        
        // General error handling based on exit code ranges
        if exitCode == 0 {
            return BackupError.genericError(reason: "Unknown error (successful exit code)")
        } else if exitCode < 10 {
            return BackupError.commandExecutionFailure(
                command: "restic",
                exitCode: exitCode,
                errorOutput: errorOutput
            )
        } else if exitCode < 100 {
            return BackupError.repositoryAccessFailure(
                path: "unknown",
                reason: "Repository error (\(exitCode)): \(errorOutput)"
            )
        } else {
            return BackupError.genericError(
                reason: "Unknown error with exit code \(exitCode): \(errorOutput)"
            )
        }
    }
}
