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

/// Enum representing specific security error types
public enum SecurityErrorType: Error {
  /// Authentication failure (invalid credentials, expired token, etc.)
  case authenticationFailed(String)

  /// Authorization failure (insufficient permissions)
  case authorizationFailed(String)

  /// Cryptographic operation failure
  case cryptoOperationFailed(String)

  /// Invalid certificate or certificate chain
  case invalidCertificate(String)

  /// Security policy violation
  case policyViolation(String)

  /// Secure connection failure
  case connectionFailed(String)

  /// Secure storage failure
  case storageFailed(String)

  /// Tampered data detected
  case tamperedData(String)

  /// Generic security error
  case generalError(String)

  /// Get a code string for this error type
  var code: String {
    switch self {
      case .authenticationFailed: "auth_failed"
      case .authorizationFailed: "authorization_failed"
      case .cryptoOperationFailed: "crypto_failed"
      case .invalidCertificate: "invalid_certificate"
      case .policyViolation: "policy_violation"
      case .connectionFailed: "connection_failed"
      case .storageFailed: "storage_failed"
      case .tamperedData: "tampered_data"
      case .generalError: "general_error"
    }
  }

  /// Get a descriptive message for this error type
  var message: String {
    switch self {
      case let .authenticationFailed(message): "Authentication failed: \(message)"
      case let .authorizationFailed(message): "Authorization failed: \(message)"
      case let .cryptoOperationFailed(message): "Cryptographic operation failed: \(message)"
      case let .invalidCertificate(message): "Invalid certificate: \(message)"
      case let .policyViolation(message): "Security policy violation: \(message)"
      case let .connectionFailed(message): "Secure connection failed: \(message)"
      case let .storageFailed(message): "Secure storage failed: \(message)"
      case let .tamperedData(message): "Tampered data detected: \(message)"
      case let .generalError(message): "Security error: \(message)"
    }
  }
}

/// Protocol for domain-specific error types
public protocol DomainError: Error {
  /// The error domain
  static var domain: String { get }
}

/// Struct wrapper for security errors that conforms to UmbraError
public struct UmbraSecurityError: Error, UmbraError, Sendable, CustomStringConvertible {
  /// The specific security error type
  public let errorType: SecurityErrorType

  /// The domain for security errors
  public let domain: String = "Security"

  /// The error code
  public var code: String {
    errorType.code
  }

  /// Human-readable description of the error
  public var errorDescription: String {
    errorType.message
  }

  /// A user-readable description of the error
  public var description: String {
    "[\(domain).\(code)] \(errorDescription)"
  }

  /// Source information about where the error occurred
  public let source: ErrorHandlingInterfaces.ErrorSource?

  /// The underlying error, if any
  public let underlyingError: Error?

  /// Additional context for the error
  public let context: ErrorHandlingInterfaces.ErrorContext

  /// Initialize a new security error
  public init(
    errorType: SecurityErrorType,
    source: ErrorHandlingInterfaces.ErrorSource? = nil,
    underlyingError: Error? = nil,
    context: ErrorHandlingInterfaces.ErrorContext? = nil
  ) {
    self.errorType = errorType
    self.source = source
    self.underlyingError = underlyingError
    self.context = context ?? ErrorHandlingInterfaces.ErrorContext(
      source: "Security",
      operation: "securityOperation",
      details: errorType.message
    )
  }

  /// Creates a new instance of the error with additional context
  public func with(context: ErrorHandlingInterfaces.ErrorContext) -> Self {
    UmbraSecurityError(
      errorType: errorType,
      source: source,
      underlyingError: underlyingError,
      context: context
    )
  }

  /// Creates a new instance of the error with a specified underlying error
  public func with(underlyingError: Error) -> Self {
    UmbraSecurityError(
      errorType: errorType,
      source: source,
      underlyingError: underlyingError,
      context: context
    )
  }

  /// Creates a new instance of the error with source information
  public func with(source: ErrorHandlingInterfaces.ErrorSource) -> Self {
    UmbraSecurityError(
      errorType: errorType,
      source: source,
      underlyingError: underlyingError,
      context: context
    )
  }

  /// Create a security error with the specified type and message
  public static func create(
    _ type: SecurityErrorType,
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) -> UmbraSecurityError {
    UmbraSecurityError(
      errorType: type,
      source: ErrorHandlingInterfaces.ErrorSource(
        file: file,
        line: line,
        function: function
      )
    )
  }

  // MARK: - Convenience Initializers

  /// Convenience function to create an authentication failed error
  /// - Parameters:
  ///   - message: Error message
  ///   - file: Source file (auto-filled by the compiler)
  ///   - function: Function name (auto-filled by the compiler)
  ///   - line: Line number (auto-filled by the compiler)
  /// - Returns: A UmbraSecurityError with authenticationFailed type
  public static func authenticationFailed(
    _ message: String,
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) -> UmbraSecurityError {
    create(.authenticationFailed(message), file: file, function: function, line: line)
  }

  /// Convenience function to create an authorization failed error
  /// - Parameters:
  ///   - message: Error message
  ///   - file: Source file (auto-filled by the compiler)
  ///   - function: Function name (auto-filled by the compiler)
  ///   - line: Line number (auto-filled by the compiler)
  /// - Returns: A UmbraSecurityError with authorizationFailed type
  public static func authorizationFailed(
    _ message: String,
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) -> UmbraSecurityError {
    create(.authorizationFailed(message), file: file, function: function, line: line)
  }

  // Add more convenience methods as needed
}
