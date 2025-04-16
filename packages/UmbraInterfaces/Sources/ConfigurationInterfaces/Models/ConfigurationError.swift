import Foundation

/**
 Errors that can occur during configuration operations.

 This comprehensive set of errors provides detailed information about
 configuration failures to facilitate proper handling and logging.
 */
public enum ConfigurationError: Error, Equatable {
  /// Failed to load configuration from source
  case loadFailed(String)

  /// Configuration validation failed
  case validationFailed(String)

  /// Failed to save configuration
  case saveFailed(String)

  /// Configuration key not found
  case keyNotFound(String)

  /// Type mismatch when accessing configuration value
  case typeMismatch(String)

  /// Invalid configuration format
  case invalidFormat(String)

  /// Failed to parse configuration data
  case parseFailed(String)

  /// Schema validation failed
  case schemaValidationFailed(String)

  /// Operation timed out
  case timeout(String)

  /// No active configuration
  case noActiveConfiguration

  /// Source not found
  case sourceNotFound(String)

  /// Dependency missing
  case dependencyMissing(String)

  /// Configuration version mismatch
  case versionMismatch(String)

  /// Permission denied for operation
  case permissionDenied(String)

  /// Encryption or decryption failed
  case cryptoFailed(String)

  /// General configuration error
  case general(String)
}

// MARK: - LocalizedError Conformance

extension ConfigurationError: LocalizedError {
  public var errorDescription: String? {
    switch self {
      case let .loadFailed(message):
        "Failed to load configuration: \(message)"
      case let .validationFailed(message):
        "Configuration validation failed: \(message)"
      case let .saveFailed(message):
        "Failed to save configuration: \(message)"
      case let .keyNotFound(message):
        "Configuration key not found: \(message)"
      case let .typeMismatch(message):
        "Type mismatch when accessing configuration value: \(message)"
      case let .invalidFormat(message):
        "Invalid configuration format: \(message)"
      case let .parseFailed(message):
        "Failed to parse configuration data: \(message)"
      case let .schemaValidationFailed(message):
        "Schema validation failed: \(message)"
      case let .timeout(message):
        "Configuration operation timed out: \(message)"
      case .noActiveConfiguration:
        "No active configuration"
      case let .sourceNotFound(message):
        "Configuration source not found: \(message)"
      case let .dependencyMissing(message):
        "Configuration dependency missing: \(message)"
      case let .versionMismatch(message):
        "Configuration version mismatch: \(message)"
      case let .permissionDenied(message):
        "Permission denied for configuration operation: \(message)"
      case let .cryptoFailed(message):
        "Configuration encryption or decryption failed: \(message)"
      case let .general(message):
        "Configuration error: \(message)"
    }
  }
}
