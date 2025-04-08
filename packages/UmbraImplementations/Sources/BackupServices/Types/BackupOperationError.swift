import Foundation

/**
 * Errors that can occur during backup operations.
 *
 * This enum provides a comprehensive set of error types that can occur
 * during backup operations, with descriptive messages for each.
 */
public enum BackupOperationError: Error, Equatable {
  /// The operation was cancelled by the user
  case operationCancelled(String)

  /// A network error occurred during the operation
  case networkError(String)

  /// A file system error occurred during the operation
  case fileSystemError(String)

  /// The requested snapshot was not found
  case snapshotNotFound(String)

  /// An error occurred during repository operations
  case repositoryError(String)

  /// An error occurred while parsing operation results
  case parsingFailure(String)

  /// An error occurred due to invalid parameters
  case invalidParameters(String)

  /// An unknown error occurred
  case unknownError(String)

  /// The operation timed out
  case timeout(String)

  /// The operation failed due to authentication issues
  case authenticationFailure(String)

  /// The operation failed due to permission issues
  case permissionDenied(String)

  /// The operation failed due to insufficient storage
  case insufficientStorage(String)

  /// The operation failed due to a configuration issue
  case configurationError(String)

  /// The requested file was not found
  case fileNotFound(String)

  /// An unexpected error occurred
  case unexpected(String)

  /// Invalid input was provided
  case invalidInput(String)

  /// Insufficient space on the device
  case insufficientSpace(String)

  /// Returns a descriptive message for the error
  public var message: String {
    switch self {
      case let .operationCancelled(message),
           let .networkError(message),
           let .fileSystemError(message),
           let .snapshotNotFound(message),
           let .repositoryError(message),
           let .parsingFailure(message),
           let .invalidParameters(message),
           let .unknownError(message),
           let .timeout(message),
           let .authenticationFailure(message),
           let .permissionDenied(message),
           let .insufficientStorage(message),
           let .configurationError(message),
           let .fileNotFound(message),
           let .unexpected(message),
           let .invalidInput(message),
           let .insufficientSpace(message):
        message
    }
  }
}
