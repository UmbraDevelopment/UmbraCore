import Foundation
import UmbraErrorsCore

/// Domain for SecureBytes-related errors
public enum SecureBytesErrorDomain: String, CaseIterable, Sendable {
    /// Domain identifier
    public static let domain = "UmbraErrors.SecureBytes"
    
    /// Hexadecimal string is invalid
    case invalidHexString = "INVALID_HEX_STRING"
    
    /// Operation attempted outside valid bounds
    case outOfBounds = "OUT_OF_BOUNDS"
    
    /// Memory allocation failed
    case allocationFailed = "ALLOCATION_FAILED"
}

/// Error types specific to UmbraCore SecureBytes operations
public enum SecureBytesError: Error, Equatable, Sendable {
    /// The provided hexadecimal string is invalid or malformed
    case invalidHexString
    
    /// The operation attempted to access memory outside the valid bounds
    case outOfBounds
    
    /// Memory allocation failed for secure bytes storage
    case allocationFailed
    
    /// Get the equivalent UmbraError for this error type
    public func toUmbraError() -> UmbraError {
        switch self {
        case .invalidHexString:
            return SecureBytesErrorDomain.makeInvalidHexStringError()
        case .outOfBounds:
            return SecureBytesErrorDomain.makeOutOfBoundsError()
        case .allocationFailed:
            return SecureBytesErrorDomain.makeAllocationFailedError()
        }
    }
}

/// Factory methods for SecureBytes-related errors
extension SecureBytesErrorDomain {
    /// Creates an error for invalid hexadecimal string
    ///
    /// - Parameters:
    ///   - description: Optional custom description
    ///   - source: Optional source of the error
    ///   - underlyingError: Optional underlying error
    ///   - context: Optional error context
    /// - Returns: A fully configured UmbraError
    public static func makeInvalidHexStringError(
        description: String = "The provided hexadecimal string is invalid or malformed",
        source: ErrorSource? = nil,
        underlyingError: Error? = nil,
        context: ErrorContext = ErrorContext()
    ) -> UmbraError {
        ResourceError(
            type: .invalidResource,
            code: SecureBytesErrorDomain.invalidHexString.rawValue,
            description: description,
            context: context,
            underlyingError: underlyingError,
            source: source
        )
    }
    
    /// Creates an error for out-of-bounds operations
    ///
    /// - Parameters:
    ///   - description: Optional custom description
    ///   - source: Optional source of the error
    ///   - underlyingError: Optional underlying error
    ///   - context: Optional error context
    /// - Returns: A fully configured UmbraError
    public static func makeOutOfBoundsError(
        description: String = "The operation attempted to access memory outside the valid bounds",
        source: ErrorSource? = nil,
        underlyingError: Error? = nil,
        context: ErrorContext = ErrorContext()
    ) -> UmbraError {
        ResourceError(
            type: .invalidResource,
            code: SecureBytesErrorDomain.outOfBounds.rawValue,
            description: description,
            context: context,
            underlyingError: underlyingError,
            source: source
        )
    }
    
    /// Creates an error for memory allocation failures
    ///
    /// - Parameters:
    ///   - description: Optional custom description
    ///   - source: Optional source of the error
    ///   - underlyingError: Optional underlying error
    ///   - context: Optional error context
    /// - Returns: A fully configured UmbraError
    public static func makeAllocationFailedError(
        description: String = "Memory allocation failed for secure bytes storage",
        source: ErrorSource? = nil,
        underlyingError: Error? = nil,
        context: ErrorContext = ErrorContext()
    ) -> UmbraError {
        ResourceError(
            type: .general,
            code: SecureBytesErrorDomain.allocationFailed.rawValue,
            description: description,
            context: context,
            underlyingError: underlyingError,
            source: source
        )
    }
}
