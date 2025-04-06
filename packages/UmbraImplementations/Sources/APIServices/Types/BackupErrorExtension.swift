import Foundation
import BackupInterfaces

/**
 * Extension to BackupError to add API-specific error types
 * needed by the APIServices module.
 */
public extension BackupError {
    /// Creates an invalid operation error with the given message
    static func invalidOperation(message: String) -> BackupError {
        return .operationFailed(message: message)
    }
}
