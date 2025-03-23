import Foundation

// Local type declarations to replace imports
// These replace the removed ErrorHandling and ErrorHandlingDomains imports

/// Error domain namespace
public enum ErrorDomain {
  /// Security domain
  public static let security = "Security"
  /// Crypto domain
  public static let crypto = "Crypto"
  /// Application domain
  public static let application = "Application"
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
    self.domain = domain
    self.code = code
    self.description = description
  }
}

extension UmbraErrors.Application {
  /// Core application errors relating to configuration, resources, and operations
  public enum Core: Error, UmbraError, Sendable, CustomStringConvertible {
    // Configuration errors
    /// The application configuration is invalid or missing
    case configurationError(String)

    // Resource errors
    /// A required resource could not be found
    case resourceNotFound(String)

    /// A resource already exists when attempting to create it
    case resourceAlreadyExists(String)

    /// Error loading or accessing a resource
    case resourceLoadingError(String)

    // Operation errors
    /// An operation timed out
    case operationTimeout(String)

    /// An operation was cancelled
    case operationCancelled(String)

    // State errors
    /// The application is in an invalid state for the requested operation
    case invalidState(String)

    // Dependency errors
    /// A required dependency encountered an error or is unavailable
    case dependencyError(String)

    /// An external service encountered an error
    case externalServiceError(String)

    /// Initialisation of a component failed
    case initialisationError(String)

    /// Unknown application error
    case unknown(String)

    // MARK: - UmbraError Protocol

    /// The domain identifier for application core errors
    public var domain: String {
      "Application.Core"
    }

    /// Error code that uniquely identifies the error type
    public var code: String {
      switch self {
        case .configurationError:
          "configuration_error"
        case .resourceNotFound:
          "resource_not_found"
        case .resourceAlreadyExists:
          "resource_already_exists"
        case .resourceLoadingError:
          "resource_loading_error"
        case .operationTimeout:
          "operation_timeout"
        case .operationCancelled:
          "operation_cancelled"
        case .invalidState:
          "invalid_state"
        case .dependencyError:
          "dependency_error"
        case .externalServiceError:
          "external_service_error"
        case .initialisationError:
          "initialisation_error"
        case .unknown:
          "unknown"
      }
    }

    /// Human-readable description of the error
    public var errorDescription: String {
      switch self {
        case let .configurationError(msg):
          "Configuration error: \(msg)"
        case let .resourceNotFound(msg):
          "Resource not found: \(msg)"
        case let .resourceAlreadyExists(msg):
          "Resource already exists: \(msg)"
        case let .resourceLoadingError(msg):
          "Resource loading error: \(msg)"
        case let .operationTimeout(msg):
          "Operation timed out: \(msg)"
        case let .operationCancelled(msg):
          "Operation cancelled: \(msg)"
        case let .invalidState(msg):
          "Invalid application state: \(msg)"
        case let .dependencyError(msg):
          "Dependency error: \(msg)"
        case let .externalServiceError(msg):
          "External service error: \(msg)"
        case let .initialisationError(msg):
          "Initialisation error: \(msg)"
        case let .unknown(msg):
          "Unknown application error: \(msg)"
      }
    }

    /// A user-readable description of the error
    public var description: String {
      "[\(domain).\(code)] \(errorDescription)"
    }

    /// Source information about where the error occurred
    public var source: ErrorHandlingInterfaces.ErrorSource? {
      nil // Source is typically set when the error is created with context
    }

    /// The underlying error, if any
    public var underlyingError: Error? {
      nil // Underlying error is typically set when the error is created with context
    }

    /// Additional context for the error
    public var context: ErrorHandlingInterfaces.ErrorContext {
      ErrorHandlingInterfaces.ErrorContext(
        source: domain,
        operation: "application_operation",
        details: errorDescription
      )
    }

    /// Creates a new instance of the error with additional context
    public func with(context _: ErrorHandlingInterfaces.ErrorContext) -> Self {
      // Since these are enum cases, we need to return a new instance with the same value
      switch self {
        case let .configurationError(msg):
          .configurationError(msg)
        case let .resourceNotFound(msg):
          .resourceNotFound(msg)
        case let .resourceAlreadyExists(msg):
          .resourceAlreadyExists(msg)
        case let .resourceLoadingError(msg):
          .resourceLoadingError(msg)
        case let .operationTimeout(msg):
          .operationTimeout(msg)
        case let .operationCancelled(msg):
          .operationCancelled(msg)
        case let .invalidState(msg):
          .invalidState(msg)
        case let .dependencyError(msg):
          .dependencyError(msg)
        case let .externalServiceError(msg):
          .externalServiceError(msg)
        case let .initialisationError(msg):
          .initialisationError(msg)
        case let .unknown(msg):
          .unknown(msg)
      }
      // In a real implementation, we would attach the context
    }

    /// Creates a new instance of the error with a specified underlying error
    public func with(underlyingError _: Error) -> Self {
      // Similar to above, return a new instance with the same value
      self // In a real implementation, we would attach the underlying error
    }

    /// Creates a new instance of the error with source information
    public func with(source _: ErrorHandlingInterfaces.ErrorSource) -> Self {
      // Similar to above, return a new instance with the same value
      self // In a real implementation, we would attach the source information
    }
  }
}

// MARK: - Factory Methods

extension UmbraErrors.Application.Core {
  /// Create an application error with the specified type and message
  public static func create(
    _ message: String,
    file _: String = #file,
    line _: Int = #line,
    function _: String = #function
  ) -> UmbraErrors.Application.Core {
    .unknown(message)
  }

  /// Create a configuration error with the specified message
  public static func makeConfiguration(
    _ message: String,
    file _: String = #file,
    line _: Int = #line,
    function _: String = #function
  ) -> UmbraErrors.Application.Core {
    .configurationError(message)
  }

  /// Create a resource not found error with the specified message
  public static func makeResourceNotFound(
    _ message: String,
    file _: String = #file,
    line _: Int = #line,
    function _: String = #function
  ) -> UmbraErrors.Application.Core {
    .resourceNotFound(message)
  }
}
