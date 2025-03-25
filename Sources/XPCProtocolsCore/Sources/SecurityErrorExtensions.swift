import Foundation
import UmbraErrors

/// Extensions to UmbraErrors.SecurityError to provide additional functionality
extension UmbraErrors.SecurityError {
    /// Create a "not implemented" error with the given message
    /// - Parameter message: Description of the unimplemented functionality
    /// - Returns: A SecurityError with the appropriate code and message
    public static func notImplemented(_ message: String) -> UmbraErrors.SecurityError {
        UmbraErrors.SecurityError(
            code: .accessError,
            description: "Not implemented: \(message)"
        )
    }
    
    /// Create an "operation failed" error with the given message
    /// - Parameter message: Description of the failure
    /// - Returns: A SecurityError with the appropriate code and message
    public static func operationFailed(_ message: String) -> UmbraErrors.SecurityError {
        UmbraErrors.SecurityError(
            code: .accessError,
            description: message
        )
    }
    
    /// Create a "security validation failed" error with the given message
    /// - Parameter message: Description of the validation failure
    /// - Returns: A SecurityError with the appropriate code and message
    public static func securityValidationFailed(_ message: String) -> UmbraErrors.SecurityError {
        UmbraErrors.SecurityError(
            code: .unauthorisedAccess,
            description: message
        )
    }
    
    /// Create a "connection failed" error with the given message
    /// - Parameter message: Description of the connection failure
    /// - Returns: A SecurityError with the appropriate code and message
    public static func connectionFailed(_ message: String) -> UmbraErrors.SecurityError {
        UmbraErrors.SecurityError(
            code: .accessError,
            description: message
        )
    }
    
    /// Create an "invalid input" error with the given message
    /// - Parameter message: Description of the invalid input
    /// - Returns: A SecurityError with the appropriate code and message
    public static func invalidInput(_ message: String) -> UmbraErrors.SecurityError {
        UmbraErrors.SecurityError(
            code: .invalidKey,
            description: message
        )
    }
}
