import Foundation
import LoggingTypes
import UmbraErrors

/// Errors that can occur during Restic operations.
public enum ResticError: Error, Sendable, LoggableErrorProtocol {
  /// A required parameter was missing or invalid
  case missingParameter(String)

  /// A parameter has an invalid value
  case invalidParameter(String)

  /// The command failed to execute
  case executionFailed(String)

  /// The command failed to execute with exit code and error output
  case executionFailure(Int, String)

  /// Invalid command format or structure
  case invalidCommand(String)

  /// Command execution timed out
  case executionTimeout

  /// The repository is invalid or inaccessible
  case repositoryNotFound(path: String)

  /// Authentication failed
  case invalidPassword

  /// Permission denied for a path
  case permissionDenied(path: String)

  /// Executable not found at specified path
  case executableNotFound(String)

  /// Command failed with specific exit code and output
  case commandFailed(exitCode: Int, output: String)

  /// Credential error occurred during secure storage operations
  case credentialError(String)

  /// Repository already exists
  case repositoryExists(String)

  /// Invalid configuration provided
  case invalidConfiguration(String)

  /// Invalid data format or content
  case invalidData(String)

  /// An error occurred during backup
  case backupFailed(String)

  /// An error occurred during restore
  case restoreFailed(String)

  /// An error occurred during repository check
  case checkFailed(String)

  /// An error occurred during repository maintenance
  case maintenanceFailed(String)

  /// A general error occurred
  case generalError(String)
}

/// Extension to provide LocalizedError conformance for user-friendly error messages
extension ResticError: LocalizedError {
  public var errorDescription: String? {
    switch self {
      case let .missingParameter(message):
        "Missing parameter: \(message)"
      case let .invalidParameter(message):
        "Invalid parameter: \(message)"
      case let .executionFailed(message):
        "Execution failed: \(message)"
      case let .executionFailure(exitCode, errorOutput):
        "Command failed with exit code \(exitCode): \(errorOutput)"
      case let .invalidCommand(reason):
        "Invalid command: \(reason)"
      case .executionTimeout:
        "Command execution timed out"
      case let .repositoryNotFound(path):
        "Repository not found at path: \(path)"
      case .invalidPassword:
        "Invalid repository password"
      case let .permissionDenied(path):
        "Permission denied for path: \(path)"
      case let .executableNotFound(path):
        "Executable not found at path: \(path)"
      case let .commandFailed(exitCode, output):
        "Command failed with exit code \(exitCode): \(output)"
      case let .credentialError(message):
        "Credential error: \(message)"
      case let .repositoryExists(path):
        "Repository already exists at path: \(path)"
      case let .invalidConfiguration(message):
        "Invalid configuration: \(message)"
      case let .invalidData(message):
        "Invalid data: \(message)"
      case let .backupFailed(message):
        "Backup failed: \(message)"
      case let .restoreFailed(message):
        "Restore failed: \(message)"
      case let .checkFailed(message):
        "Repository check failed: \(message)"
      case let .maintenanceFailed(message):
        "Repository maintenance failed: \(message)"
      case let .generalError(message):
        "Error: \(message)"
    }
  }

  public var failureReason: String? {
    switch self {
      case let .missingParameter(message):
        "A required parameter was missing: \(message)"
      case let .invalidParameter(message):
        "A parameter had an invalid value: \(message)"
      case let .executionFailed(message):
        "The command failed to execute properly: \(message)"
      case let .executionFailure(exitCode, _):
        "The command exited with non-zero exit code: \(exitCode)"
      case let .invalidCommand(reason):
        "The command format or structure was invalid: \(reason)"
      case .executionTimeout:
        "The command execution exceeded the allowed time limit"
      case let .repositoryNotFound(path):
        "Could not find a valid Restic repository at \(path)"
      case .invalidPassword:
        "The provided password was incorrect for this repository"
      case let .permissionDenied(path):
        "The application does not have sufficient permissions to access \(path)"
      case let .executableNotFound(path):
        "Could not find the executable at \(path)"
      case let .commandFailed(exitCode, _):
        "The command exited with non-zero exit code: \(exitCode)"
      case let .credentialError(message):
        "A credential error occurred: \(message)"
      case let .repositoryExists(path):
        "A repository already exists at \(path)"
      case let .invalidConfiguration(message):
        "The provided configuration is invalid: \(message)"
      case let .invalidData(message):
        "The data format or content is invalid: \(message)"
      case let .backupFailed(message):
        "The backup operation failed: \(message)"
      case let .restoreFailed(message):
        "The restore operation failed: \(message)"
      case let .checkFailed(message):
        "The repository check operation failed: \(message)"
      case let .maintenanceFailed(message):
        "The repository maintenance operation failed: \(message)"
      case let .generalError(message):
        message
    }
  }

  public var recoverySuggestion: String? {
    switch self {
      case .missingParameter:
        "Please provide all required parameters for the operation."
      case .invalidParameter:
        "Check the parameter values and ensure they are in the correct format."
      case .executionFailed, .executionFailure:
        "Check that Restic is properly installed and your system has sufficient resources."
      case .invalidCommand:
        "Verify the command structure and arguments."
      case .executionTimeout:
        "Try increasing the timeout duration or reducing the operation scope."
      case .repositoryNotFound:
        "Verify the repository path and ensure it exists and is accessible."
      case .invalidPassword:
        "Check the repository password and try again."
      case .permissionDenied:
        "Adjust file system permissions or run with elevated privileges."
      case .executableNotFound:
        "Verify the executable path and ensure it exists and is accessible."
      case .commandFailed:
        "Check the command output and adjust the command or parameters as needed."
      case .credentialError:
        "Check your credentials and try again."
      case .repositoryExists:
        "Choose a different path for the repository."
      case .invalidConfiguration:
        "Review your configuration settings and correct any errors."
      case .invalidData:
        "Check that the data is in the expected format."
      case .backupFailed:
        "Check source paths, disk space, and repository access."
      case .restoreFailed:
        "Verify the snapshot exists and the destination has sufficient permissions."
      case .checkFailed:
        "Try running a repair operation or restore from a known good backup."
      case .maintenanceFailed:
        "Ensure no other processes are using the repository and try again."
      case .generalError:
        "Try the operation again. If it persists, check logs for more details."
    }
  }
}

// MARK: - LoggableErrorProtocol Conformance

extension ResticError {
  /// Create a metadata collection for this error with appropriate privacy levels
  /// - Returns: A metadata collection with privacy classifications
  public func createMetadataCollection() -> LogMetadataDTOCollection {
    var metadata=LogMetadataDTOCollection()

    // Add standard error metadata with appropriate privacy level
    metadata=metadata.withPublic(key: "error_type", value: "restic_error")

    // Add case-specific details with appropriate privacy controls
    switch self {
      case let .missingParameter(message):
        metadata=metadata.withPublic(key: "error_category", value: "parameter_error")
        metadata=metadata.withPrivate(key: "message", value: message)

      case let .invalidParameter(message):
        metadata=metadata.withPublic(key: "error_category", value: "parameter_error")
        metadata=metadata.withPrivate(key: "message", value: message)

      case let .executionFailed(message):
        metadata=metadata.withPublic(key: "error_category", value: "execution_error")
        metadata=metadata.withPrivate(key: "message", value: message)

      case let .executionFailure(exitCode, output):
        metadata=metadata.withPublic(key: "error_category", value: "execution_error")
        metadata=metadata.withPublic(key: "exit_code", value: String(exitCode))
        metadata=metadata.withPrivate(key: "output", value: output)

      case let .invalidCommand(message):
        metadata=metadata.withPublic(key: "error_category", value: "command_error")
        metadata=metadata.withPrivate(key: "message", value: message)

      case .executionTimeout:
        metadata=metadata.withPublic(key: "error_category", value: "timeout_error")

      case let .repositoryNotFound(path):
        metadata=metadata.withPublic(key: "error_category", value: "repository_error")
        metadata=metadata.withPrivate(key: "path", value: path)

      case .invalidPassword:
        metadata=metadata.withPublic(key: "error_category", value: "authentication_error")

      case let .permissionDenied(path):
        metadata=metadata.withPublic(key: "error_category", value: "permission_error")
        metadata=metadata.withPrivate(key: "path", value: path)

      case let .executableNotFound(path):
        metadata=metadata.withPublic(key: "error_category", value: "executable_error")
        metadata=metadata.withPrivate(key: "path", value: path)

      case let .commandFailed(exitCode, output):
        metadata=metadata.withPublic(key: "error_category", value: "command_error")
        metadata=metadata.withPublic(key: "exit_code", value: String(exitCode))
        metadata=metadata.withPrivate(key: "output", value: output)

      case let .credentialError(message):
        metadata=metadata.withPublic(key: "error_category", value: "credential_error")
        metadata=metadata.withPrivate(key: "message", value: message)

      case let .repositoryExists(path):
        metadata=metadata.withPublic(key: "error_category", value: "repository_error")
        metadata=metadata.withPrivate(key: "path", value: path)

      case let .invalidConfiguration(message):
        metadata=metadata.withPublic(key: "error_category", value: "configuration_error")
        metadata=metadata.withPrivate(key: "message", value: message)

      case let .invalidData(message):
        metadata=metadata.withPublic(key: "error_category", value: "data_error")
        metadata=metadata.withPrivate(key: "message", value: message)

      case let .backupFailed(message):
        metadata=metadata.withPublic(key: "error_category", value: "backup_error")
        metadata=metadata.withPrivate(key: "message", value: message)

      case let .restoreFailed(message):
        metadata=metadata.withPublic(key: "error_category", value: "restore_error")
        metadata=metadata.withPrivate(key: "message", value: message)

      case let .checkFailed(message):
        metadata=metadata.withPublic(key: "error_category", value: "check_error")
        metadata=metadata.withPrivate(key: "message", value: message)

      case let .maintenanceFailed(message):
        metadata=metadata.withPublic(key: "error_category", value: "maintenance_error")
        metadata=metadata.withPrivate(key: "message", value: message)

      case let .generalError(message):
        metadata=metadata.withPublic(key: "error_category", value: "general_error")
        metadata=metadata.withPrivate(key: "message", value: message)
    }

    return metadata
  }

  /// Get the source information for this error
  /// - Returns: Source information
  public func getSource() -> String {
    "ResticService"
  }

  /// Get the log message for this error
  /// - Returns: A descriptive message appropriate for logging
  public func getLogMessage() -> String {
    switch self {
      case let .missingParameter(message):
        "Missing parameter: \(message)"
      case let .invalidParameter(message):
        "Invalid parameter: \(message)"
      case let .executionFailed(message):
        "Execution failed: \(message)"
      case let .executionFailure(exitCode, output):
        "Execution failure with exit code \(exitCode): \(output)"
      case let .invalidCommand(message):
        "Invalid command: \(message)"
      case .executionTimeout:
        "Command execution timed out"
      case let .repositoryNotFound(path):
        "Repository not found at path: \(path)"
      case .invalidPassword:
        "Invalid password provided"
      case let .permissionDenied(path):
        "Permission denied for path: \(path)"
      case let .executableNotFound(path):
        "Executable not found at: \(path)"
      case let .commandFailed(exitCode, output):
        "Command failed with exit code \(exitCode): \(output)"
      case let .credentialError(message):
        "Credential error: \(message)"
      case let .repositoryExists(path):
        "Repository already exists at: \(path)"
      case let .invalidConfiguration(message):
        "Invalid configuration: \(message)"
      case let .invalidData(message):
        "Invalid data: \(message)"
      case let .backupFailed(message):
        "Backup failed: \(message)"
      case let .restoreFailed(message):
        "Restore failed: \(message)"
      case let .checkFailed(message):
        "Repository check failed: \(message)"
      case let .maintenanceFailed(message):
        "Repository maintenance failed: \(message)"
      case let .generalError(message):
        "General error: \(message)"
    }
  }
}
