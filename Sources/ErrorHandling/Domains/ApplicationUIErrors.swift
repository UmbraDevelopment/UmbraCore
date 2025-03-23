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

extension UmbraErrors.Application {
  /// User interface related application errors
  public enum UI: Error, UmbraError, Sendable, CustomStringConvertible {
    /// Error rendering a view or component
    case renderingError(String)

    /// Error with user input validation
    case inputValidationError(String)

    /// Error loading UI resources (images, fonts, etc.)
    case resourceLoadingError(String)

    /// Error with view presentation or management
    case viewError(String)

    /// Error with UI state management
    case stateError(String)

    /// Error with animations or transitions
    case animationError(String)

    /// Error with layout calculations or constraints
    case layoutError(String)

    // MARK: - UmbraError Protocol

    /// The domain identifier for application UI errors
    public var domain: String {
      "Application.UI"
    }

    /// Error code that uniquely identifies the error type
    public var code: String {
      switch self {
        case .renderingError:
          "rendering_error"
        case .inputValidationError:
          "input_validation_error"
        case .resourceLoadingError:
          "resource_loading_error"
        case .viewError:
          "view_error"
        case .stateError:
          "state_error"
        case .animationError:
          "animation_error"
        case .layoutError:
          "layout_error"
      }
    }

    /// Human-readable description of the error
    public var errorDescription: String {
      switch self {
        case let .renderingError(msg):
          "UI rendering error: \(msg)"
        case let .inputValidationError(msg):
          "Input validation error: \(msg)"
        case let .resourceLoadingError(msg):
          "UI resource loading error: \(msg)"
        case let .viewError(msg):
          "View error: \(msg)"
        case let .stateError(msg):
          "UI state error: \(msg)"
        case let .animationError(msg):
          "Animation error: \(msg)"
        case let .layoutError(msg):
          "Layout error: \(msg)"
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
        operation: "ui_operation",
        details: errorDescription
      )
    }

    /// Creates a new instance of the error with additional context
    public func with(context _: ErrorHandlingInterfaces.ErrorContext) -> Self {
      // Since these are enum cases, we need to return a new instance with the same value
      switch self {
        case let .renderingError(msg):
          .renderingError(msg)
        case let .inputValidationError(msg):
          .inputValidationError(msg)
        case let .resourceLoadingError(msg):
          .resourceLoadingError(msg)
        case let .viewError(msg):
          .viewError(msg)
        case let .stateError(msg):
          .stateError(msg)
        case let .animationError(msg):
          .animationError(msg)
        case let .layoutError(msg):
          .layoutError(msg)
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

extension UmbraErrors.Application.UI {
  /// Create a rendering error with the specified message
  public static func rendering(
    _ message: String,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> UmbraErrors.Application.UI {
    .renderingError(message)
  }

  /// Create an input validation error with the specified message
  public static func inputValidation(
    _ message: String,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> UmbraErrors.Application.UI {
    .inputValidationError(message)
  }

  /// Create a view error with the specified message
  public static func view(
    _ message: String,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> UmbraErrors.Application.UI {
    .viewError(message)
  }
}
