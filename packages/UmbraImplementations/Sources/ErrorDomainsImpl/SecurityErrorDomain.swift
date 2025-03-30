import Foundation
import ErrorCoreTypes
import ErrorHandlingInterfaces

/**
 # SecurityErrorDomain
 
 Domain-specific error type for security-related errors.
 
 This implementation follows the Alpha Dot Five architecture by providing
 a concrete implementation of the ErrorDomainProtocol for security-related
 errors, with proper British spelling in documentation.
 */
public enum SecurityErrorDomain: ErrorDomainProtocol {
    // MARK: - Error Cases
    
    /// Authentication failed (incorrect credentials, etc.)
    case authenticationFailed(reason: String, context: ErrorContext? = nil)
    
    /// Authorisation failed (insufficient permissions, etc.)
    case authorisationFailed(reason: String, context: ErrorContext? = nil)
    
    /// Encryption operation failed
    case encryptionFailed(reason: String, context: ErrorContext? = nil)
    
    /// Decryption operation failed
    case decryptionFailed(reason: String, context: ErrorContext? = nil)
    
    /// Key management operation failed
    case keyManagementFailed(reason: String, context: ErrorContext? = nil)
    
    /// Invalid input provided to security operation
    case invalidInput(reason: String, context: ErrorContext? = nil)
    
    /// Security operation not supported
    case unsupportedOperation(name: String, context: ErrorContext? = nil)
    
    /// General security error that doesn't fit other categories
    case generalSecurityError(reason: String, context: ErrorContext? = nil)
    
    // MARK: - ErrorDomainProtocol Implementation
    
    /// The error domain identifier
    public static var domain: ErrorDomainType {
        return .security
    }
    
    /// The error code within this domain
    public var code: Int {
        switch self {
        case .authenticationFailed: return 1001
        case .authorisationFailed: return 1002
        case .encryptionFailed: return 1003
        case .decryptionFailed: return 1004
        case .keyManagementFailed: return 1005
        case .invalidInput: return 1006
        case .unsupportedOperation: return 1007
        case .generalSecurityError: return 1099
        }
    }
    
    /// Human-readable description of the error
    public var localizedDescription: String {
        switch self {
        case .authenticationFailed(let reason, _):
            return "Authentication failed: \(reason)"
        case .authorisationFailed(let reason, _):
            return "Authorisation failed: \(reason)"
        case .encryptionFailed(let reason, _):
            return "Encryption failed: \(reason)"
        case .decryptionFailed(let reason, _):
            return "Decryption failed: \(reason)"
        case .keyManagementFailed(let reason, _):
            return "Key management failed: \(reason)"
        case .invalidInput(let reason, _):
            return "Invalid input: \(reason)"
        case .unsupportedOperation(let name, _):
            return "Unsupported operation: \(name)"
        case .generalSecurityError(let reason, _):
            return "Security error: \(reason)"
        }
    }
    
    /// Optional context providing additional information about the error
    public var context: ErrorContext? {
        switch self {
        case .authenticationFailed(_, let context),
             .authorisationFailed(_, let context),
             .encryptionFailed(_, let context),
             .decryptionFailed(_, let context),
             .keyManagementFailed(_, let context),
             .invalidInput(_, let context),
             .unsupportedOperation(_, let context),
             .generalSecurityError(_, let context):
            return context
        }
    }
    
    /**
     Creates an error with additional context information.
     
     - Parameter context: The context to associate with this error
     - Returns: A new error instance with the provided context
     */
    public func withContext(_ context: ErrorContext) -> SecurityErrorDomain {
        switch self {
        case .authenticationFailed(let reason, _):
            return .authenticationFailed(reason: reason, context: context)
        case .authorisationFailed(let reason, _):
            return .authorisationFailed(reason: reason, context: context)
        case .encryptionFailed(let reason, _):
            return .encryptionFailed(reason: reason, context: context)
        case .decryptionFailed(let reason, _):
            return .decryptionFailed(reason: reason, context: context)
        case .keyManagementFailed(let reason, _):
            return .keyManagementFailed(reason: reason, context: context)
        case .invalidInput(let reason, _):
            return .invalidInput(reason: reason, context: context)
        case .unsupportedOperation(let name, _):
            return .unsupportedOperation(name: name, context: context)
        case .generalSecurityError(let reason, _):
            return .generalSecurityError(reason: reason, context: context)
        }
    }
}
