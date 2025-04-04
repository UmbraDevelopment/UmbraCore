import Foundation

/**
 # CoreSecurityError

 Comprehensive error type for security operations, providing detailed
 information about failures in the security subsystem.

 This type follows the architecture pattern for domain-specific
 errors with descriptive messages and categorisation.
 */
public enum CoreSecurityError: Error, Equatable, Sendable {
  /// Invalid input provided to a security operation
  case invalidInput(String)

  /// Invalid or missing cryptographic key
  case invalidKey(String)

  /// Unknown or unspecified error
  case unknownError(String)

  /// Error during cryptographic operations
  case cryptoError(String)

  /// Error during key management operations
  case keyManagementError(String)

  /// Error during storage operations
  case storageError(String)

  /// Permission denied for a security operation
  case permissionDenied(String)

  /// Configuration error in security subsystem
  case configurationError(String)

  /// Hardware security module error
  case hardwareError(String)

  /// Algorithm not supported
  case algorithmNotSupported(String)
  
  /// Authentication failure during cryptographic operation
  case authenticationFailed(String)
  
  /// Unsupported operation for this platform
  case unsupportedOperation(String)

  /// Creates a human-readable description of the error
  public var localizedDescription: String {
    switch self {
      case let .invalidInput(message):
        "Invalid input: \(message)"
      case let .invalidKey(message):
        "Invalid key: \(message)"
      case let .unknownError(message):
        "Unknown error: \(message)"
      case let .cryptoError(message):
        "Cryptographic error: \(message)"
      case let .keyManagementError(message):
        "Key management error: \(message)"
      case let .storageError(message):
        "Storage error: \(message)"
      case let .permissionDenied(message):
        "Permission denied: \(message)"
      case let .configurationError(message):
        "Configuration error: \(message)"
      case let .hardwareError(message):
        "Hardware security error: \(message)"
      case let .algorithmNotSupported(message):
        "Algorithm not supported: \(message)"
      case let .authenticationFailed(message):
        "Authentication failed: \(message)"
      case let .unsupportedOperation(message):
        "Unsupported operation: \(message)"
    }
  }
}
