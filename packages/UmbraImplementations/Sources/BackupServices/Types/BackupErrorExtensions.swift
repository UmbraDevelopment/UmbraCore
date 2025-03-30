import BackupInterfaces
import Foundation
import LoggingTypes

/**
 * Provides utility extensions for creating and working with BackupError types.
 *
 * These extensions implement the error handling pattern from Alpha Dot Five,
 * prioritising clarity, privacy, and proper error categorisation.
 */
extension BackupError {
    /**
     * Creates an error for unexpected conditions.
     *
     * This is used when an unexpected error occurs that doesn't fit into
     * other more specific categories.
     *
     * - Parameter message: Detailed message about the unexpected condition
     * - Returns: A BackupError representing the unexpected condition
     */
    public static func unexpectedError(_ message: String) -> BackupError {
        return BackupError.snapshotFailure(id: nil, reason: message)
    }
    
    /**
     * Creates an error for permission issues.
     *
     * - Parameter detail: Description of the permission issue
     * - Returns: A BackupError representing the permission issue
     */
    public static func permissionError(_ detail: String) -> BackupError {
        return .insufficientPermissions(path: detail)
    }
    
    /**
     * Creates an error for network-related issues.
     *
     * - Parameters:
     *   - detail: Details about the network issue
     *   - context: Optional logging context
     * - Returns: A BackupError representing the network issue
     */
    public static func networkError(_ detail: String, context: LoggingTypes.LogContextDTO? = nil) -> BackupError {
        return .repositoryAccessFailure(path: "network", reason: detail)
    }
    
    /**
     * Creates an error for invalid input parameters.
     *
     * - Parameter detail: Details about what made the input invalid
     * - Returns: A BackupError representing the invalid input
     */
    public static func invalidInputError(_ detail: String) -> BackupError {
        return .invalidConfiguration(details: detail)
    }
    
    /**
     * Creates an error for snapshot-related issues.
     *
     * - Parameters:
     *   - id: Optional snapshot ID
     *   - detail: Details about the issue
     * - Returns: A BackupError representing the issue
     */
    public static func snapshotError(id: String?, detail: String) -> BackupError {
        return .snapshotFailure(id: id, reason: detail)
    }
}
