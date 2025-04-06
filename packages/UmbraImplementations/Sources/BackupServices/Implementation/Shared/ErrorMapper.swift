import BackupInterfaces
import Foundation
import ResticInterfaces
import UmbraErrors

/// Provides error mapping functionality for backup operations
///
/// This utility converts low-level Restic errors into domain-specific
/// BackupError types that are more meaningful to clients of the backup services.
public struct ErrorMapper {

  /// Converts a ResticError to a BackupError
  /// - Parameter error: The original Restic error
  /// - Returns: An appropriate BackupError
  public func convertResticError(_ error: ResticError) -> BackupError {
    switch error {
      case let .repositoryNotFound(path):
        BackupError.repositoryAccessFailure(
          path: path,
          reason: "Repository not found"
        )

      case let .permissionDenied(path):
        BackupError.repositoryAccessFailure(
          path: path,
          reason: "Access denied"
        )

      case .invalidPassword:
        BackupError.authenticationFailure(
          reason: "Invalid repository password"
        )

      case let .executableNotFound(path):
        BackupError.configurationError(
          details: "Restic executable not found at path: \(path)"
        )

      case let .commandFailed(exitCode: exitCode, output: output):
        BackupError.operationFailed(
          details: "Command failed with exit code \(exitCode): \(output)"
        )

      case let .credentialError(reason):
        BackupError.authenticationFailure(
          reason: reason
        )

      case let .repositoryExists(path):
        BackupError.repositoryError(
          path: path,
          reason: "Repository already exists"
        )

      case let .other(message):
        BackupError.unknownError(
          details: message
        )

      case let .missingParameter(param):
        BackupError.invalidConfiguration(
          details: "Missing parameter: \(param)"
        )

      case let .invalidParameter(param):
        BackupError.invalidConfiguration(
          details: "Invalid parameter: \(param)"
        )

      case let .executionFailure(exitCode, message):
        BackupError.commandExecutionFailure(
          command: "restic",
          exitCode: exitCode,
          errorOutput: message
        )

      case let .executionFailed(message):
        BackupError.commandExecutionFailure(
          command: "restic",
          exitCode: -1,
          errorOutput: message
        )

      case .executionTimeout:
        BackupError.commandExecutionFailure(
          command: "restic",
          exitCode: -1,
          errorOutput: "Command execution timed out"
        )

      case let .invalidCommand(message):
        BackupError.invalidConfiguration(
          details: "Invalid command: \(message)"
        )

      case let .invalidConfiguration(message):
        BackupError.invalidConfiguration(
          details: message
        )

      case let .invalidData(message):
        BackupError.parsingError(
          details: "Invalid data: \(message)"
        )

      case let .backupFailed(message):
        BackupError.genericError(
          reason: "Backup failed: \(message)"
        )

      case let .restoreFailed(message):
        BackupError.genericError(
          reason: "Restore failed: \(message)"
        )

      case let .checkFailed(message):
        BackupError.genericError(
          reason: "Repository check failed: \(message)"
        )

      case let .maintenanceFailed(message):
        BackupError.genericError(
          reason: "Maintenance failed: \(message)"
        )

      case let .generalError(message):
        BackupError.genericError(
          reason: message
        )
    }
  }

  /// Maps an exit code to a BackupError if it represents a failure
  /// - Parameters:
  ///   - exitCode: The command exit code
  ///   - errorOutput: Error output from the command
  /// - Returns: An appropriate BackupError
  public func mapExitCodeToError(
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
