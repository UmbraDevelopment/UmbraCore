import Foundation

/**
 # File System Error Types

 Defines the domain-specific error types for the file system operations.

 ## Error Categories

 The errors are organised into categories that reflect the different types
 of failures that can occur during file system operations:

 - **Access Errors**: Permission and security-related issues
 - **Path Errors**: Problems with file paths or locations
 - **IO Errors**: Issues with reading or writing data
 - **Resource Errors**: Problems with system resources
 - **State Errors**: Unexpected file system states

 ## Usage

 FileSystemError is designed to be comprehensive, providing detailed information
 about what went wrong during a file system operation. Each error includes:

 - A specific error type for programmatic handling
 - A detailed description of the error
 - Contextual information (such as file paths) where relevant
 */
public enum FileSystemError: Error, Equatable, Sendable {
  // MARK: - Access Errors

  /// The operation failed because permission was denied
  case permissionDenied(path: String, message: String)

  /// The operation failed because the file is locked or in use
  case fileLocked(path: String)

  /// The operation failed because a security constraint was violated
  case securityViolation(path: String, constraint: String)

  // MARK: - Path Errors

  /// The specified path does not exist
  case pathNotFound(path: String)

  /// The specified path already exists (when creating a new item)
  case pathAlreadyExists(path: String)

  /// The path couldn't be accessed (e.g., network path unavailable)
  case pathUnavailable(path: String, reason: String)

  /// The path is invalid or improperly formatted
  case invalidPath(path: String, reason: String)

  // MARK: - IO Errors

  /// Error occurred while reading from a file
  case readError(path: String, reason: String)

  /// Error occurred while writing to a file
  case writeError(path: String, reason: String)

  /// Error occurred while attempting to delete a file or directory
  case deleteError(path: String, reason: String)

  /// Error occurred during a copy operation
  case copyError(source: String, destination: String, reason: String)

  /// Error occurred during a move operation
  case moveError(source: String, destination: String, reason: String)

  // MARK: - Resource Errors

  /// Not enough disk space to complete the operation
  case insufficientDiskSpace(path: String, required: UInt64, available: UInt64)

  /// Too many file descriptors in use by the process
  case tooManyOpenFiles

  /// Device or resource busy
  case deviceBusy(path: String)

  // MARK: - State Errors

  /// The item exists but isn't the expected type (e.g., directory when expecting file)
  case unexpectedItemType(path: String, expected: String, actual: String)

  /// The operation requires a non-empty directory, but the directory is empty
  case directoryEmpty(path: String)

  /// The directory isn't empty (e.g., when trying to delete a non-empty directory)
  case directoryNotEmpty(path: String)

  /// The file system object is in an inconsistent state
  case inconsistentState(path: String, details: String)

  // MARK: - Other Errors

  /// Extended attribute error
  case extendedAttributeError(path: String, attribute: String, operation: String, reason: String)

  /// Unknown or unexpected error
  case unknown(message: String)
}

// MARK: - Error Descriptions

extension FileSystemError: LocalizedError {
  public var errorDescription: String? {
    switch self {
      case let .permissionDenied(path, message):
        "Permission denied for path: \(path). \(message)"

      case let .fileLocked(path):
        "File is locked or in use: \(path)"

      case let .securityViolation(path, constraint):
        "Security violation for path: \(path). Constraint: \(constraint)"

      case let .pathNotFound(path):
        "Path not found: \(path)"

      case let .pathAlreadyExists(path):
        "Path already exists: \(path)"

      case let .pathUnavailable(path, reason):
        "Path unavailable: \(path). Reason: \(reason)"

      case let .invalidPath(path, reason):
        "Invalid path: \(path). Reason: \(reason)"

      case let .readError(path, reason):
        "Error reading from file: \(path). Reason: \(reason)"

      case let .writeError(path, reason):
        "Error writing to file: \(path). Reason: \(reason)"

      case let .deleteError(path, reason):
        "Error deleting item at path: \(path). Reason: \(reason)"

      case let .copyError(source, destination, reason):
        "Error copying from \(source) to \(destination). Reason: \(reason)"

      case let .moveError(source, destination, reason):
        "Error moving from \(source) to \(destination). Reason: \(reason)"

      case let .insufficientDiskSpace(path, required, available):
        "Insufficient disk space for operation on \(path). Required: \(required) bytes, Available: \(available) bytes"

      case .tooManyOpenFiles:
        "Too many open files. The system limit for file descriptors has been reached"

      case let .deviceBusy(path):
        "Device is busy: \(path)"

      case let .unexpectedItemType(path, expected, actual):
        "Unexpected item type at \(path). Expected: \(expected), Actual: \(actual)"

      case let .directoryEmpty(path):
        "Directory is empty: \(path)"

      case let .directoryNotEmpty(path):
        "Directory is not empty: \(path)"

      case let .inconsistentState(path, details):
        "File system object in inconsistent state at \(path): \(details)"

      case let .extendedAttributeError(path, attribute, operation, reason):
        "Extended attribute error for attribute '\(attribute)' on \(path) during \(operation): \(reason)"

      case let .unknown(message):
        "Unknown file system error: \(message)"
    }
  }
}
