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

/// Domain-specific error type for application operations
public enum ApplicationError: Error, UmbraError, CustomStringConvertible {
  // Core errors
  case configurationError(String)
  case initializationError(String)
  case resourceNotFound(String)
  case resourceAlreadyExists(String)
  case operationTimeout(String)
  case operationCancelled(String)
  case invalidState(String)
  case dependencyError(String)
  case externalServiceError(String)

  // UI errors
  case viewError(String)
  case renderingError(String)
  case inputValidationError(String)
  case resourceLoadingError(String)

  // Lifecycle errors
  case lifecycleError(String)
  case stateError(String)

  // Settings errors
  case settingsError(String)

  // Other application errors
  case unknown(String)

  // MARK: - DomainError Protocol

  /// Domain identifier for ApplicationError
  public static var domain: String {
    "Application"
  }

  // MARK: - UmbraError Protocol

  /// Domain identifier for this error
  public var domain: String {
    ApplicationError.domain
  }

  /// Error code for this error
  public var code: String {
    switch self {
      case .configurationError:
        "config_error"
      case .initializationError:
        "init_error"
      case .resourceNotFound:
        "resource_not_found"
      case .resourceAlreadyExists:
        "resource_exists"
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
      case .viewError:
        "view_error"
      case .renderingError:
        "rendering_error"
      case .inputValidationError:
        "input_validation_error"
      case .resourceLoadingError:
        "resource_loading_error"
      case .lifecycleError:
        "lifecycle_error"
      case .stateError:
        "state_error"
      case .settingsError:
        "settings_error"
      case .unknown:
        "unknown"
    }
  }

  /// Human-readable description of the error
  public var errorDescription: String {
    switch self {
      case let .configurationError(msg),
           let .initializationError(msg),
           let .resourceNotFound(msg),
           let .resourceAlreadyExists(msg),
           let .operationTimeout(msg),
           let .operationCancelled(msg),
           let .invalidState(msg),
           let .dependencyError(msg),
           let .externalServiceError(msg),
           let .viewError(msg),
           let .renderingError(msg),
           let .inputValidationError(msg),
           let .resourceLoadingError(msg),
           let .lifecycleError(msg),
           let .stateError(msg),
           let .settingsError(msg),
           let .unknown(msg):
        msg
    }
  }

  /// Source information for the error (optional)
  public var source: ErrorHandlingInterfaces.ErrorSource? {
    switch self {
      case .configurationError, .initializationError, .resourceNotFound, .resourceAlreadyExists,
           .operationTimeout, .operationCancelled, .invalidState, .dependencyError,
           .externalServiceError, .viewError, .renderingError, .inputValidationError,
           .resourceLoadingError, .lifecycleError, .stateError, .settingsError, .unknown:
        nil
    }
  }

  /// Context information about the error
  public var context: ErrorHandlingInterfaces.ErrorContext {
    switch self {
      case .configurationError, .initializationError, .resourceNotFound, .resourceAlreadyExists,
           .operationTimeout, .operationCancelled, .invalidState, .dependencyError,
           .externalServiceError, .viewError, .renderingError, .inputValidationError,
           .resourceLoadingError, .lifecycleError, .stateError, .settingsError, .unknown:
        ErrorHandlingInterfaces.ErrorContext(
          source: "ApplicationError",
          operation: "application_operation"
        )
    }
  }

  /// Failure reason for the error
  public var failureReason: String? {
    switch self {
      case .configurationError:
        "The application configuration is invalid or missing."
      case .initializationError:
        "The application failed to initialize properly."
      case .resourceNotFound:
        "The requested resource could not be found."
      case .resourceAlreadyExists:
        "The resource already exists."
      case .operationTimeout:
        "The operation took too long to complete."
      case .operationCancelled:
        "The operation was cancelled."
      case .invalidState:
        "The application is in an invalid state for this operation."
      case .dependencyError:
        "A required dependency is missing or invalid."
      case .externalServiceError:
        "An external service reported an error."
      case .viewError:
        "A UI view error occurred."
      case .renderingError:
        "A rendering error occurred."
      case .inputValidationError:
        "Input validation failed."
      case .resourceLoadingError:
        "Failed to load a resource."
      case .lifecycleError:
        "An application lifecycle error occurred."
      case .stateError:
        "An application state error occurred."
      case .settingsError:
        "A settings-related error occurred."
      case .unknown:
        "An unknown application error occurred."
    }
  }

  /// Recovery suggestion for the error
  public var recoverySuggestion: String? {
    switch self {
      case .configurationError:
        "Check the application configuration and ensure all required settings are provided."
      case .initializationError:
        "Restart the application or check log files for more details."
      case .resourceNotFound:
        "Check that the resource identifier is correct and that the resource exists."
      case .resourceAlreadyExists:
        "Use a different identifier or update the existing resource."
      case .operationTimeout:
        "Try again or check your network connection."
      case .operationCancelled:
        "No action needed."
      case .invalidState:
        "Return to a previous screen or restart the application."
      case .dependencyError:
        "Install or update the required dependency."
      case .externalServiceError:
        "Check the external service status or try again later."
      case .viewError, .renderingError:
        "Refresh the screen or navigate to a different view."
      case .inputValidationError:
        "Check your input and ensure it meets the requirements."
      case .resourceLoadingError:
        "Check your network connection or try again later."
      case .lifecycleError, .stateError:
        "Restart the application."
      case .settingsError:
        "Reset the application settings or check permissions."
      case .unknown:
        "Restart the application or contact support."
    }
  }

  /// Whether this error is expected to be handled
  public var isExpected: Bool {
    switch self {
      case .operationCancelled, .inputValidationError:
        true
      default:
        false
    }
  }

  /// The underlying error, if any
  public var underlyingError: Error? {
    switch self {
      case .configurationError, .initializationError, .resourceNotFound, .resourceAlreadyExists,
           .operationTimeout, .operationCancelled, .invalidState, .dependencyError,
           .externalServiceError, .viewError, .renderingError, .inputValidationError,
           .resourceLoadingError, .lifecycleError, .stateError, .settingsError, .unknown:
        nil
    }
  }

  /// Human-readable description of the error
  public var description: String {
    "[\(domain).\(code)] \(errorDescription)"
  }

  /// Create a new instance with updated context
  public func with(context _: ErrorHandlingInterfaces.ErrorContext) -> ApplicationError {
    switch self {
      case let .configurationError(msg):
        .configurationError(msg)
      case let .initializationError(msg):
        .initializationError(msg)
      case let .resourceNotFound(msg):
        .resourceNotFound(msg)
      case let .resourceAlreadyExists(msg):
        .resourceAlreadyExists(msg)
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
      case let .viewError(msg):
        .viewError(msg)
      case let .renderingError(msg):
        .renderingError(msg)
      case let .inputValidationError(msg):
        .inputValidationError(msg)
      case let .resourceLoadingError(msg):
        .resourceLoadingError(msg)
      case let .lifecycleError(msg):
        .lifecycleError(msg)
      case let .stateError(msg):
        .stateError(msg)
      case let .settingsError(msg):
        .settingsError(msg)
      case let .unknown(msg):
        .unknown(msg)
    }
  }

  /// Create a new instance with an underlying error
  public func with(underlyingError _: Error) -> ApplicationError {
    switch self {
      case let .configurationError(msg):
        .configurationError(msg)
      case let .initializationError(msg):
        .initializationError(msg)
      case let .resourceNotFound(msg):
        .resourceNotFound(msg)
      case let .resourceAlreadyExists(msg):
        .resourceAlreadyExists(msg)
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
      case let .viewError(msg):
        .viewError(msg)
      case let .renderingError(msg):
        .renderingError(msg)
      case let .inputValidationError(msg):
        .inputValidationError(msg)
      case let .resourceLoadingError(msg):
        .resourceLoadingError(msg)
      case let .lifecycleError(msg):
        .lifecycleError(msg)
      case let .stateError(msg):
        .stateError(msg)
      case let .settingsError(msg):
        .settingsError(msg)
      case let .unknown(msg):
        .unknown(msg)
    }
  }

  /// Create a new instance with source information
  public func with(source _: ErrorHandlingInterfaces.ErrorSource) -> ApplicationError {
    switch self {
      case let .configurationError(msg):
        .configurationError(msg)
      case let .initializationError(msg):
        .initializationError(msg)
      case let .resourceNotFound(msg):
        .resourceNotFound(msg)
      case let .resourceAlreadyExists(msg):
        .resourceAlreadyExists(msg)
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
      case let .viewError(msg):
        .viewError(msg)
      case let .renderingError(msg):
        .renderingError(msg)
      case let .inputValidationError(msg):
        .inputValidationError(msg)
      case let .resourceLoadingError(msg):
        .resourceLoadingError(msg)
      case let .lifecycleError(msg):
        .lifecycleError(msg)
      case let .stateError(msg):
        .stateError(msg)
      case let .settingsError(msg):
        .settingsError(msg)
      case let .unknown(msg):
        .unknown(msg)
    }
  }
}
