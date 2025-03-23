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

/// A generic implementation of UmbraError that can be used for any error domain
public struct GenericUmbraError: ErrorHandlingInterfaces.UmbraError, CustomStringConvertible {
  /// The error domain
  public let domain: String

  /// The error code
  public let code: String

  /// Human-readable description of the error
  public let errorDescription: String

  /// A user-readable description of the error required for CustomStringConvertible
  public var description: String {
    "[\(domain).\(code)] \(errorDescription)"
  }

  /// The underlying error, if any
  public let underlyingError: Error?

  /// Source information about where the error occurred
  public let source: ErrorHandlingInterfaces.ErrorSource?

  /// Additional context for the error
  public let context: ErrorHandlingInterfaces.ErrorContext

  /// Creates a new GenericUmbraError instance
  /// - Parameters:
  ///   - domain: The error domain
  ///   - code: The error code
  ///   - errorDescription: Human-readable description of the error
  ///   - underlyingError: The underlying error, if any
  ///   - source: Source information about where the error occurred
  ///   - context: Additional context for the error
  public init(
    domain: String,
    code: String,
    errorDescription: String,
    underlyingError: Error? = nil,
    source: ErrorHandlingInterfaces.ErrorSource? = nil,
    context: ErrorHandlingInterfaces.ErrorContext? = nil
  ) {
    self.domain = domain
    self.code = code
    self.errorDescription = errorDescription
    self.underlyingError = underlyingError
    self.source = source
    self.context = context ?? ErrorHandlingInterfaces.ErrorContext(
      source: domain,
      operation: "unknown",
      details: errorDescription
    )
  }

  /// Creates a new instance of the error with additional context
  public func with(context: ErrorHandlingInterfaces.ErrorContext) -> Self {
    GenericUmbraError(
      domain: domain,
      code: code,
      errorDescription: errorDescription,
      underlyingError: underlyingError,
      source: source,
      context: context
    )
  }

  /// Creates a new instance of the error with a specified underlying error
  public func with(underlyingError: Error) -> Self {
    GenericUmbraError(
      domain: domain,
      code: code,
      errorDescription: errorDescription,
      underlyingError: underlyingError,
      source: source,
      context: context
    )
  }

  /// Creates a new instance of the error with source information
  public func with(source: ErrorHandlingInterfaces.ErrorSource) -> Self {
    GenericUmbraError(
      domain: domain,
      code: code,
      errorDescription: errorDescription,
      underlyingError: underlyingError,
      source: source,
      context: context
    )
  }
}

// MARK: - Convenience Initializers

extension GenericUmbraError {
  /// Creates a new error with the given domain, code, and description
  /// - Parameters:
  ///   - domain: The error domain
  ///   - code: The error code
  ///   - description: Human-readable description of the error
  ///   - file: The file where the error occurred (defaults to current file)
  ///   - function: The function where the error occurred (defaults to current function)
  ///   - line: The line where the error occurred (defaults to current line)
  /// - Returns: A new GenericUmbraError instance
  public static func create(
    domain: String,
    code: String,
    description: String,
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) -> GenericUmbraError {
    GenericUmbraError(
      domain: domain,
      code: code,
      errorDescription: description,
      source: ErrorHandlingInterfaces.ErrorSource(
        file: file,
        line: line,
        function: function
      )
    )
  }

  /// Creates a generic error for validation failures
  /// - Parameters:
  ///   - message: The validation error message
  ///   - code: A specific validation error code
  /// - Returns: A new GenericUmbraError
  public static func validationError(
    message: String,
    code: String = "validation_error"
  ) -> GenericUmbraError {
    GenericUmbraError(
      domain: "Validation",
      code: code,
      errorDescription: message
    )
  }

  /// Creates a generic error for internal errors
  /// - Parameters:
  ///   - message: The error message
  ///   - code: A specific error code
  /// - Returns: A new GenericUmbraError
  public static func internalError(
    message: String,
    code: String = "internal_error"
  ) -> GenericUmbraError {
    GenericUmbraError(
      domain: "Internal",
      code: code,
      errorDescription: message
    )
  }

  /// Creates a generic error that wraps another error
  /// - Parameters:
  ///   - error: The error to wrap
  ///   - errorDescription: Optional custom error description
  /// - Returns: A new GenericUmbraError
  public static func wrapped(
    _ error: Error,
    errorDescription: String = "Wrapped error"
  ) -> GenericUmbraError {
    GenericUmbraError(
      domain: "Wrapped",
      code: "wrapped_error",
      errorDescription: errorDescription,
      underlyingError: error
    )
  }
}
