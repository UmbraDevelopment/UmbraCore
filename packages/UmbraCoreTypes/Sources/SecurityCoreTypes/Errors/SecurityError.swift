import Foundation
import SecurityTypes

/**
 # SecurityError

 Comprehensive error type for security operations, providing detailed
 information about failures in the security subsystem.

 This type follows the Alpha Dot Five architecture pattern for domain-specific
 errors with descriptive messages and categorisation.
 */
public enum SecurityError: Error, Equatable, Sendable {
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

  /// Network-related error during security operations
  case networkError(String)

  /// Operation not supported
  case unsupportedOperation(String)

  /// The algorithm provided is not supported
  case unsupportedAlgorithm(String)

  /// Authentication failure
  case authenticationFailed(String)

  /// Item not found in secure storage
  case itemNotFound(String)

  /// Item already exists in secure storage
  case duplicateItem(String)

  /// User interaction not allowed for secure operation
  case interactionNotAllowed(String)

  /// Verification of signature or data failed
  case verificationFailed(String)

  /// Service unavailable
  case serviceUnavailable(String)

  /// System-level error during security operations
  case systemError(String)

  /// Error domains for categorising security errors
  public enum Domain: String {
    case security="Security"
    case crypto="Crypto"
    case keyManagement="KeyManagement"
    case storage="Storage"
    case xpcService="XPCService"
    case application="Application"
    case network="Network"
  }

  /// Returns the domain for this error
  public var domain: Domain {
    switch self {
      case .cryptoError, .unsupportedAlgorithm:
        .crypto
      case .keyManagementError:
        .keyManagement
      case .storageError:
        .storage
      case .networkError:
        .network
      case .systemError, .serviceUnavailable:
        .application
      default:
        .security
    }
  }
}

// MARK: - CustomStringConvertible

extension SecurityError: CustomStringConvertible {
  /// Human-readable description of the error
  public var description: String {
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
      case let .networkError(message):
        "Network error: \(message)"
      case let .unsupportedOperation(message):
        "Unsupported operation: \(message)"
      case let .unsupportedAlgorithm(message):
        "Unsupported algorithm: \(message)"
      case let .authenticationFailed(message):
        "Authentication failed: \(message)"
      case let .itemNotFound(message):
        "Item not found: \(message)"
      case let .duplicateItem(message):
        "Duplicate item: \(message)"
      case let .interactionNotAllowed(message):
        "Interaction not allowed: \(message)"
      case let .verificationFailed(message):
        "Verification failed: \(message)"
      case let .serviceUnavailable(message):
        "Service unavailable: \(message)"
      case let .systemError(message):
        "System error: \(message)"
    }
  }
}

// MARK: - LocalizedError

extension SecurityError: LocalizedError {
  /// Localised description suitable for user display
  public var errorDescription: String? {
    description
  }

  /// Localised failure reason
  public var failureReason: String? {
    switch self {
      case let .invalidInput(message),
           let .invalidKey(message),
           let .unknownError(message),
           let .cryptoError(message),
           let .keyManagementError(message),
           let .storageError(message),
           let .networkError(message),
           let .unsupportedOperation(message),
           let .unsupportedAlgorithm(message),
           let .authenticationFailed(message),
           let .itemNotFound(message),
           let .duplicateItem(message),
           let .interactionNotAllowed(message),
           let .verificationFailed(message),
           let .serviceUnavailable(message),
           let .systemError(message):
        message
    }
  }
}
