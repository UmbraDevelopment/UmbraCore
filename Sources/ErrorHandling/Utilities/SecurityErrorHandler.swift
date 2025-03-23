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

/// A generic error implementation that conforms to UmbraError
private struct GenericError: ErrorHandlingInterfaces.UmbraError {
  let domain: String
  let code: String
  let message: String
  let details: [String: String]
  let source: ErrorHandlingInterfaces.ErrorSource?
  var underlyingError: Error?
  var context: ErrorHandlingInterfaces.ErrorContext

  /// Initialiser with all properties
  init(
    domain: String,
    code: String,
    message: String,
    details: [String: String],
    source: ErrorHandlingInterfaces.ErrorSource?,
    underlyingError: Error?,
    context: ErrorHandlingInterfaces.ErrorContext
  ) {
    self.domain=domain
    self.code=code
    self.message=message
    self.details=details
    self.source=source
    self.underlyingError=underlyingError
    self.context=context
  }

  /// Conform to CustomStringConvertible
  var description: String {
    message
  }

  /// A user-friendly error message (required by UmbraError)
  var errorDescription: String {
    message
  }

  /// Create a new instance with additional context
  func with(context: ErrorHandlingInterfaces.ErrorContext) -> Self {
    var newError=self
    newError.context=context
    return newError
  }

  /// Create a new instance with an underlying error
  func with(underlyingError: Error) -> Self {
    var newError=self
    newError.underlyingError=underlyingError
    return newError
  }

  /// Create a new instance with source information
  func with(source: ErrorHandlingInterfaces.ErrorSource) -> Self {
    GenericError(
      domain: domain,
      code: code,
      message: message,
      details: details,
      source: source,
      underlyingError: underlyingError,
      context: context
    )
  }

  /// Create a new instance with additional user info
  func with(userInfo: [String: Any]) -> Self {
    var updatedDetails=details
    for (key, value) in userInfo {
      updatedDetails[key]=String(describing: value)
    }

    return GenericError(
      domain: domain,
      code: code,
      message: message,
      details: updatedDetails,
      source: source,
      underlyingError: underlyingError,
      context: context
    )
  }
}

/// A handler for security-related errors
@MainActor
public final class SecurityErrorHandler: @unchecked Sendable {
  /// The shared instance for the handler
  public static let shared=SecurityErrorHandler()

  /// The error mapper used to transform errors
  private let errorMapper=SecurityErrorMapper()

  /// Private initialiser to enforce singleton pattern
  private init() {}

  /// Handle a security error with the specified severity
  /// - Parameters:
  ///   - error: The error to handle
  ///   - severity: The severity of the error
  ///   - file: The file where the error occurred
  ///   - function: The function where the error occurred
  ///   - line: The line where the error occurred
  ///   - userInfo _: Additional information about the error
  public func handle(
    _ error: Error,
    severity: ErrorHandlingInterfaces.ErrorSeverity,
    file: String=#file,
    function: String=#function,
    line: Int=#line,
    userInfo _: [String: Any]?=nil
  ) {
    // Create error context
    let commonSource=ErrorHandlingCommon.ErrorSource(
      file: file,
      function: function,
      line: line
    )

    let commonContext=ErrorHandlingCommon.ErrorContext(
      source: "SecurityErrorHandler",
      operation: "handle",
      details: "Handling security error"
    )

    // Convert to interface types
    let interfaceSource=ErrorHandlingInterfaces.ErrorSource(
      file: commonSource.file,
      line: commonSource.line,
      function: commonSource.function
    )

    let interfaceContext=ErrorHandlingInterfaces.ErrorContext(
      source: commonContext.source,
      operation: commonContext.operation,
      details: commonContext.details ?? ""
    )

    // Map our severity to the core severity type
    let mappedSeverity: ErrorHandlingCommon.ErrorSeverity=switch severity {
      case .critical:
        .critical
      case .error:
        .error
      case .warning:
        .warning
      case .info:
        .info
      case .debug:
        .debug
      case .trace:
        .debug // Map trace to debug as it's the closest equivalent
      @unknown default:
        .error
    }

    // Create a generic error with our context
    let genericError=GenericError(
      domain: "Security",
      code: "SECURITY_ERROR",
      message: "An error occurred in the security module",
      details: [:],
      source: interfaceSource,
      underlyingError: error,
      context: interfaceContext
    )

    // Delegate to the core error handler
    ErrorHandlingCore.ErrorHandler.shared.handle(
      genericError,
      severity: mappedSeverity
    )

    // Also log the error directly
    log(error: error, severity: severity)
  }

  /// Log an error with the specified severity
  private func log(error: Error, severity: ErrorHandlingInterfaces.ErrorSeverity) {
    var code="UNKNOWN"
    var message="Unknown error"

    // Try to map the error using our error mapper
    if let securityError=error as? SecurityCoreErrorWrapper {
      // Extract code and message from the error
      let (errorCode, errorMessage)=getErrorCodeAndMessage(securityError.wrappedError)
      code=errorCode
      message=errorMessage
    } else if let securityCoreError=error as? UmbraErrors.Security.Core {
      // Direct mapping from core error
      let (errorCode, errorMessage)=getErrorCodeAndMessage(securityCoreError)
      code=errorCode
      message=errorMessage
    } else {
      // Generic fallback for unknown errors
      code="UNKNOWN_SECURITY_ERROR"
      message=String(describing: error)
    }

    // Log the error with the specified severity
    switch severity {
      case .critical:
        print("[CRITICAL] Security error \(code): \(message)")
      case .error:
        print("[ERROR] Security error \(code): \(message)")
      case .warning:
        print("[WARNING] Security error \(code): \(message)")
      case .info:
        print("[INFO] Security error \(code): \(message)")
      case .debug:
        print("[DEBUG] Security error \(code): \(message)")
      case .trace:
        print("[TRACE] Security error \(code): \(message)")
      @unknown default:
        print("[UNKNOWN] Security error \(code): \(message)")
    }
  }

  /// Extract error code and message from a security error
  private func getErrorCodeAndMessage(_ error: Error) -> (String, String) {
    // Default values
    var code="UNKNOWN"
    var message="Unknown error"

    // Try to extract from security core error
    if let securityError=error as? UmbraErrors.Security.Core {
      code=String(describing: securityError).components(separatedBy: "(").first ?? "UNKNOWN"
      message=String(describing: securityError)
    } else {
      // Generic fallback
      code="SECURITY_ERROR"
      message=String(describing: error)
    }

    return (code, message)
  }
}
