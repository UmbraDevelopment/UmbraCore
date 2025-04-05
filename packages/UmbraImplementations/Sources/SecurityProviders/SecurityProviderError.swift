import Foundation

/**
 # SecurityProviderError

 Error types for security provider operations.

 This enum defines the possible error conditions that can occur during
 security provider operations, providing structured error handling.
 */
public enum SecurityProviderError: Error, Sendable {
  /// Service has not been properly initialized
  case notInitialized

  /// Initialization failed with a specific reason
  case initializationFailed(reason: String)

  /// The operation requested is not supported
  case operationNotSupported

  /// Input validation failed with a specific reason
  case invalidInput(_ reason: String)

  /// Invalid parameters provided for the operation
  case invalidParameters(_ reason: String)

  /// Operation failed with specific operation name and reason
  case operationFailed(operation: String, reason: String)

  /// Storage-related error with specific reason
  case storageError(_ reason: String)

  /// Configuration error with a specific reason
  case configurationError(_ reason: String)

  /// Invalid key format or missing key data
  case invalidKeyFormat(_ reason: String)

  /// Key not found with given identifier
  case keyNotFound(_ identifier: String, _ reason: String)

  /// Key generation failed with specific reason
  case keyGenerationFailed(_ reason: String)

  /// Access denied to requested resource
  case accessDenied(_ reason: String)

  /// Provider-specific internal error
  case internalError(_ reason: String)
}

extension SecurityProviderError: LocalizedError {
  public var errorDescription: String? {
    switch self {
      case .notInitialized:
        "Security provider is not initialized"
      case let .initializationFailed(reason):
        "Security provider initialization failed: \(reason)"
      case .operationNotSupported:
        "Operation is not supported by this security provider"
      case let .invalidInput(reason):
        "Invalid input provided: \(reason)"
      case let .invalidParameters(reason):
        "Invalid parameters provided: \(reason)"
      case let .operationFailed(operation, reason):
        "Security operation '\(operation)' failed: \(reason)"
      case let .storageError(reason):
        "Security storage error: \(reason)"
      case let .configurationError(reason):
        "Security configuration error: \(reason)"
      case let .invalidKeyFormat(reason):
        "Invalid key format: \(reason)"
      case let .keyNotFound(identifier, reason):
        "Key with identifier '\(identifier)' not found: \(reason)"
      case let .keyGenerationFailed(reason):
        "Key generation failed: \(reason)"
      case let .accessDenied(reason):
        "Access denied: \(reason)"
      case let .internalError(reason):
        "Internal security provider error: \(reason)"
    }
  }
}
