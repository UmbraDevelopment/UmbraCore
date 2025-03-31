import Foundation
import UmbraErrors

/// Core errors representing issues with fundamental services and operations
public enum CoreError: Error, Sendable, Equatable {
  /// Service was not found or could not be resolved
  case serviceNotFound(name: String)

  /// Service initialisation failed
  case initialisationFailed(details: String)

  /// Operation is not supported
  case operationNotSupported(details: String)

  /// Configuration error
  case configurationError(details: String)

  /// Invalid parameter provided
  case invalidParameter(name: String, details: String)

  /// Required dependency is missing
  case missingDependency(name: String)

  /// External system integration error
  case systemIntegrationError(details: String)
}

extension CoreError: LocalizedError {
  public var errorDescription: String? {
    switch self {
      case let .serviceNotFound(name):
        "Service not found: \(name)"
      case let .initialisationFailed(details):
        "Service initialisation failed: \(details)"
      case let .operationNotSupported(details):
        "Operation not supported: \(details)"
      case let .configurationError(details):
        "Configuration error: \(details)"
      case let .invalidParameter(name, details):
        "Invalid parameter '\(name)': \(details)"
      case let .missingDependency(name):
        "Missing dependency: \(name)"
      case let .systemIntegrationError(details):
        "System integration error: \(details)"
    }
  }
}
