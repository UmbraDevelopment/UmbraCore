import Foundation

/**
 * Enum representing possible errors that can occur during backup operations.
 *
 * This follows the Alpha Dot Five architecture principles of using
 * structured error types rather than general exceptions.
 */
public enum BackupOperationError: Error, Sendable, Equatable {
  /// Invalid input was provided
  case invalidInput(String)

  /// The source or destination file or directory does not exist
  case fileNotFound(String)

  /// The user does not have permission to access the resource
  case permissionDenied(String)

  /// There is not enough disk space to complete the operation
  case insufficientSpace(String)

  /// The operation was cancelled by the user
  case operationCancelled(String)

  /// A network error occurred during the operation
  case networkError(String)

  /// An error occurred with the backup repository
  case repositoryError(Error)

  /// The operation timed out
  case timeout(String)

  /// An internal error occurred in the backup system
  case internalError(String)

  /// A fatal error occurred that prevents the backup system from functioning
  case fatalError(String)

  /// An error occurred while processing/parsing data
  case parsingFailure(String)

  /// An error with an unexpected cause
  case unexpected(String)

  /// An unknown error occurred (for future compatibility)
  case unknown(String)

  /**
   * Compares two BackupOperationError instances for equality.
   *
   * - Parameters:
   *   - lhs: The first error to compare
   *   - rhs: The second error to compare
   * - Returns: True if the errors are equal, false otherwise
   */
  public static func == (lhs: BackupOperationError, rhs: BackupOperationError) -> Bool {
    switch (lhs, rhs) {
      case let (.invalidInput(lhsMsg), .invalidInput(rhsMsg)):
        lhsMsg == rhsMsg
      case let (.fileNotFound(lhsMsg), .fileNotFound(rhsMsg)):
        lhsMsg == rhsMsg
      case let (.permissionDenied(lhsMsg), .permissionDenied(rhsMsg)):
        lhsMsg == rhsMsg
      case let (.insufficientSpace(lhsMsg), .insufficientSpace(rhsMsg)):
        lhsMsg == rhsMsg
      case let (.operationCancelled(lhsMsg), .operationCancelled(rhsMsg)):
        lhsMsg == rhsMsg
      case let (.networkError(lhsMsg), .networkError(rhsMsg)):
        lhsMsg == rhsMsg
      case let (.repositoryError(lhsErr), .repositoryError(rhsErr)):
        String(describing: lhsErr) == String(describing: rhsErr)
      case let (.timeout(lhsMsg), .timeout(rhsMsg)):
        lhsMsg == rhsMsg
      case let (.internalError(lhsMsg), .internalError(rhsMsg)):
        lhsMsg == rhsMsg
      case let (.fatalError(lhsMsg), .fatalError(rhsMsg)):
        lhsMsg == rhsMsg
      case let (.parsingFailure(lhsMsg), .parsingFailure(rhsMsg)):
        lhsMsg == rhsMsg
      case let (.unexpected(lhsMsg), .unexpected(rhsMsg)):
        lhsMsg == rhsMsg
      case let (.unknown(lhsMsg), .unknown(rhsMsg)):
        lhsMsg == rhsMsg
      default:
        false
    }
  }
}
