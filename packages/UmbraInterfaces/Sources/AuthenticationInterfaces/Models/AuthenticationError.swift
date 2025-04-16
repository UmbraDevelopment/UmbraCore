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
      case let .invalidCredentials(message):
        "Invalid credentials: \(message)"
      case let .tokenExpired(message):
        "Token expired: \(message)"
      case let .invalidToken(message):
        "Invalid token: \(message)"
      case let .biometricUnavailable(message):
        "Biometric authentication unavailable: \(message)"
      case let .biometricFailed(message):
        "Biometric authentication failed: \(message)"
      case let .networkFailure(message):
        "Network failure during authentication: \(message)"
      case let .serverError(message):
        "Authentication server error: \(message)"
      case .notAuthenticated:
        "Not authenticated"
      case let .methodNotSupported(message):
        "Authentication method not supported: \(message)"
      case .cancelled:
        "Authentication was cancelled"
      case let .insecureCredentials(message):
        "Insecure credentials: \(message)"
      case let .insufficientEntropy(message):
        "Insufficient entropy for secure operation: \(message)"
      case let .invalidConfiguration(message):
        "Invalid authentication configuration: \(message)"
      case let .unexpected(message):
        "Unexpected authentication error: \(message)"
      case let .general(message):
        "Authentication error: \(message)"
    }
  }
}
