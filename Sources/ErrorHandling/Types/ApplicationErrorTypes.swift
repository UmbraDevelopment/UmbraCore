import Foundation

// Local type declarations to replace imports
// These replace the removed ErrorHandling and ErrorHandlingDomains imports

/// Error domain namespace
public enum ErrorDomain {
  /// Security domain
  public static let security="Security"
  /// Crypto domain
  public static let crypto="Crypto"
  /// Application domain
  public static let application="Application"
}

/// Error context protocol
public protocol ErrorContext {
  /// Domain of the error
  var domain: String { get }
  /// Code of the error
  var code: Int { get }
  /// Description of the error
  var description: String { get }
}

/// Base error context implementation
public struct BaseErrorContext: ErrorContext {
  /// Domain of the error
  public let domain: String
  /// Code of the error
  public let code: Int
  /// Description of the error
  public let description: String

  /// Initialise with domain, code and description
  public init(domain: String, code: Int, description: String) {
    self.domain=domain
    self.code=code
    self.description=description
  }
}

/// Core application error types used throughout the UmbraCore framework
///
/// This enum defines all application-related errors in a single, flat structure
/// rather than nested within multiple levels. This approach simplifies
/// error handling and promotes a more maintainable codebase.
public enum ApplicationError: Error, Equatable, Sendable {
  // MARK: - Configuration Errors

  /// Configuration is invalid
  case invalidConfiguration(reason: String)

  /// Required configuration is missing
  case missingConfiguration(key: String)

  /// Configuration is incompatible with current environment
  case incompatibleConfiguration(reason: String)

  // MARK: - Resource Errors

  /// Required resource is missing
  case resourceMissing(resource: String)

  /// Resource is in an invalid format
  case resourceInvalidFormat(resource: String, reason: String)

  /// Failed to load resource
  case resourceLoadFailed(resource: String, reason: String)

  // MARK: - Lifecycle Errors

  /// Application failed to initialise
  case initialisationFailed(reason: String)

  /// Feature is not initialised
  case notInitialised(feature: String)

  /// Application is in incorrect state for operation
  case invalidState(current: String, expected: String)

  /// Operation timeout
  case operationTimeout(operation: String, durationMs: Int)

  // MARK: - UI Errors

  /// View controller is missing
  case viewControllerMissing(name: String)

  /// Invalid UI state
  case invalidUIState(reason: String)

  /// UI update failed
  case uiUpdateFailed(reason: String)

  // MARK: - Input Validation

  /// Input validation failed
  case validationFailed(field: String, reason: String)

  /// Required input is missing
  case missingInput(field: String)

  /// Input format is invalid
  case invalidInputFormat(field: String, expected: String)

  // MARK: - Dependency Errors

  /// Required dependency is missing
  case dependencyMissing(dependency: String)

  /// Dependency version is incompatible
  case incompatibleDependency(dependency: String, version: String, required: String)

  // MARK: - General Errors

  /// Feature is not implemented
  case notImplemented(feature: String)

  /// Internal application error
  case internalError(reason: String)

  /// Unknown application error
  case unknown(reason: String)
}

// MARK: - CustomStringConvertible

extension ApplicationError: CustomStringConvertible {
  public var description: String {
    switch self {
      case let .invalidConfiguration(reason):
        "Invalid configuration: \(reason)"
      case let .missingConfiguration(key):
        "Missing configuration: \(key)"
      case let .incompatibleConfiguration(reason):
        "Incompatible configuration: \(reason)"
      case let .resourceMissing(resource):
        "Resource missing: \(resource)"
      case let .resourceInvalidFormat(resource, reason):
        "Resource \(resource) has invalid format: \(reason)"
      case let .resourceLoadFailed(resource, reason):
        "Failed to load resource \(resource): \(reason)"
      case let .initialisationFailed(reason):
        "Initialisation failed: \(reason)"
      case let .notInitialised(feature):
        "Not initialised: \(feature)"
      case let .invalidState(current, expected):
        "Invalid state: current '\(current)', expected '\(expected)'"
      case let .operationTimeout(operation, durationMs):
        "Operation timeout: \(operation) after \(durationMs)ms"
      case let .viewControllerMissing(name):
        "View controller missing: \(name)"
      case let .invalidUIState(reason):
        "Invalid UI state: \(reason)"
      case let .uiUpdateFailed(reason):
        "UI update failed: \(reason)"
      case let .validationFailed(field, reason):
        "Validation failed for \(field): \(reason)"
      case let .missingInput(field):
        "Missing input: \(field)"
      case let .invalidInputFormat(field, expected):
        "Invalid input format for \(field): expected \(expected)"
      case let .dependencyMissing(dependency):
        "Dependency missing: \(dependency)"
      case let .incompatibleDependency(dependency, version, required):
        "Incompatible dependency: \(dependency) version \(version), required \(required)"
      case let .notImplemented(feature):
        "Not implemented: \(feature)"
      case let .internalError(reason):
        "Internal error: \(reason)"
      case let .unknown(reason):
        "Unknown application error: \(reason)"
    }
  }
}

// MARK: - LocalizedError

extension ApplicationError: LocalizedError {
  public var errorDescription: String? {
    description
  }
}
