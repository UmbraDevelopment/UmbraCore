import BackupInterfaces
import Foundation

/**
 * Extension to BackupError to add API-specific error types
 * needed by the APIServices module.
 */
extension BackupError {
  /// Creates an invalid operation error with the given message
  public static func invalidOperation(message: String) -> BackupError {
    .operationFailed(message: message)
  }
}
