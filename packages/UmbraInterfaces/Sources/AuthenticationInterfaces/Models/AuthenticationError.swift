import Foundation

/**
 Errors that can occur during authentication operations.
 
 This comprehensive set of errors provides detailed information about
 authentication failures to facilitate proper handling and logging.
 */
public enum AuthenticationError: Error, Equatable {
    /// The provided credentials are invalid
    case invalidCredentials(String)
    
    /// The token has expired and cannot be used
    case tokenExpired(String)
    
    /// The token is invalid (malformed, tampered with, etc.)
    case invalidToken(String)
    
    /// Biometric authentication is not available on this device
    case biometricUnavailable(String)
    
    /// Biometric authentication failed (e.g., no match, too many attempts)
    case biometricFailed(String)
    
    /// A network failure occurred during authentication
    case networkFailure(String)
    
    /// The authentication server returned an error
    case serverError(String)
    
    /// The user is not authenticated when an authenticated operation was attempted
    case notAuthenticated
    
    /// The requested authentication method is not supported
    case methodNotSupported(String)
    
    /// The authentication operation was cancelled by the user
    case cancelled
    
    /// Insecure password or credentials provided
    case insecureCredentials(String)
    
    /// The system lacks the required entropy for secure random generation
    case insufficientEntropy(String)
    
    /// The configuration for the authentication provider is invalid
    case invalidConfiguration(String)
    
    /// An unexpected error occurred during authentication
    case unexpected(String)
    
    /// A general authentication error with a custom message
    case general(String)
}

// MARK: - LocalizedError Conformance

extension AuthenticationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidCredentials(let message):
            return "Invalid credentials: \(message)"
        case .tokenExpired(let message):
            return "Token expired: \(message)"
        case .invalidToken(let message):
            return "Invalid token: \(message)"
        case .biometricUnavailable(let message):
            return "Biometric authentication unavailable: \(message)"
        case .biometricFailed(let message):
            return "Biometric authentication failed: \(message)"
        case .networkFailure(let message):
            return "Network failure during authentication: \(message)"
        case .serverError(let message):
            return "Authentication server error: \(message)"
        case .notAuthenticated:
            return "Not authenticated"
        case .methodNotSupported(let message):
            return "Authentication method not supported: \(message)"
        case .cancelled:
            return "Authentication was cancelled"
        case .insecureCredentials(let message):
            return "Insecure credentials: \(message)"
        case .insufficientEntropy(let message):
            return "Insufficient entropy for secure operation: \(message)"
        case .invalidConfiguration(let message):
            return "Invalid authentication configuration: \(message)"
        case .unexpected(let message):
            return "Unexpected authentication error: \(message)"
        case .general(let message):
            return "Authentication error: \(message)"
        }
    }
}
