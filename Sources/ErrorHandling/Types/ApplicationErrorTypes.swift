import Foundation
import Interfaces

/// Core application error types used throughout the UmbraCore framework
///
/// This enum defines all application-related errors in a single, flat structure
/// rather than nested within multiple levels. This approach simplifies
/// error handling and promotes a more maintainable codebase.
public enum ApplicationError: Error, Equatable, Sendable {
  // MARK: - Configuration Errors

  /// Configuration is invalid
  case invalidConfiguration(String)

  /// Required configuration is missing
  case missingConfiguration(String)

  /// Configuration was provided but not valid for the context
  case configurationMismatch(provided: String, required: String)

  // MARK: - Lifecycle Errors

  /// Component failed to initialise
  case initialisation(component: String, reason: String)

  /// Component failed to start
  case startFailure(component: String, reason: String)

  /// Component failed to stop cleanly
  case stopFailure(component: String, reason: String)

  // MARK: - External Dependencies

  /// Required external dependency is missing
  case missingDependency(name: String, context: String)

  /// External dependency failed
  case dependencyFailure(name: String, reason: String)

  // MARK: - Resource Access

  /// Resource not found
  case resourceNotFound(type: String, identifier: String)

  /// Not authorised to access resource
  case resourceAccessDenied(type: String, identifier: String, reason: String)

  /// Resource is unavailable
  case resourceUnavailable(type: String, reason: String)

  // MARK: - Data Processing

  /// Failed to process data
  case dataProcessingFailed(type: String, reason: String)

  /// Data validation failed
  case validationFailed(type: String, reason: String)

  /// Data encoding failed
  case encodingFailed(type: String, reason: String)

  /// Data decoding failed
  case decodingFailed(type: String, reason: String)

  // MARK: - Generic Application Errors

  /// Timeout occurred
  case timeout(operation: String, durationMs: Int)

  /// Rate limit exceeded
  case rateLimitExceeded(operation: String, limit: Int, period: String)

  /// Operation cancelled
  case operationCancelled(String)

  /// General application error with custom domain and code
  case general(domain: String, code: String, message: String)
}

extension ApplicationError: CustomStringConvertible {
  public var description: String {
    switch self {
      case let .invalidConfiguration(reason):
        "Invalid configuration: \(reason)"
      case let .missingConfiguration(name):
        "Missing configuration: \(name)"
      case let .configurationMismatch(provided, required):
        "Configuration mismatch: provided \(provided) but required \(required)"
      case let .initialisation(component, reason):
        "Failed to initialise component \(component): \(reason)"
      case let .startFailure(component, reason):
        "Failed to start component \(component): \(reason)"
      case let .stopFailure(component, reason):
        "Failed to stop component \(component): \(reason)"
      case let .missingDependency(name, context):
        "Missing dependency \(name) in context \(context)"
      case let .dependencyFailure(name, reason):
        "Dependency \(name) failed: \(reason)"
      case let .resourceNotFound(type, identifier):
        "Resource of type \(type) not found with identifier \(identifier)"
      case let .resourceAccessDenied(type, identifier, reason):
        "Access denied to \(type) with identifier \(identifier): \(reason)"
      case let .resourceUnavailable(type, reason):
        "Resource of type \(type) unavailable: \(reason)"
      case let .dataProcessingFailed(type, reason):
        "Failed to process \(type) data: \(reason)"
      case let .validationFailed(type, reason):
        "Validation failed for \(type): \(reason)"
      case let .encodingFailed(type, reason):
        "Failed to encode \(type): \(reason)"
      case let .decodingFailed(type, reason):
        "Failed to decode \(type): \(reason)"
      case let .timeout(operation, durationMs):
        "Timeout occurred for operation \(operation) after \(durationMs)ms"
      case let .rateLimitExceeded(operation, limit, period):
        "Rate limit exceeded for \(operation): \(limit) per \(period)"
      case let .operationCancelled(operation):
        "Operation cancelled: \(operation)"
      case let .general(domain, code, message):
        "[\(domain).\(code)] \(message)"
    }
  }
}
