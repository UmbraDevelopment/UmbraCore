import Foundation

/**
 # SecurityServiceError

 Error types for security service operations in UmbraCore.
 */
public enum SecurityServiceError: Error, LocalizedError {
  /// Provider-related error with description
  case providerError(String)

  /// Operation is not supported by this provider
  case operationNotSupported(String)

  /// Configuration error with description
  case configurationError(String)

  /// Invalid or malformed data was provided
  case invalidInputData(String)

  /// Error in key management
  case keyManagementError(String)
  
  /// Cryptographic operation failed
  case cryptographicError(String)

  public var errorDescription: String? {
    switch self {
      case let .providerError(message):
        "Security provider error: \(message)"
      case let .operationNotSupported(message):
        "Operation not supported: \(message)"
      case let .configurationError(message):
        "Configuration error: \(message)"
      case let .invalidInputData(message):
        "Invalid input data: \(message)"
      case let .keyManagementError(message):
        "Key management error: \(message)"
      case let .cryptographicError(message):
        "Cryptographic error: \(message)"
    }
  }
}
