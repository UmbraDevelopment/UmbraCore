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

extension UmbraErrors.Security {
  /// XPC communication errors in the security domain
  public enum XPC: Error, UmbraError, StandardErrorCapabilities {
    /// Connection to XPC service failed
    case connectionFailed(reason: String)

    /// XPC message format is invalid
    case invalidMessageFormat(reason: String)

    /// XPC service returned an error
    case serviceError(code: Int, reason: String)

    /// XPC communication timed out
    case timeout(operation: String, timeoutMs: Int)

    /// XPC service is unavailable
    case serviceUnavailable(serviceName: String)

    /// XPC operation was cancelled
    case operationCancelled(operation: String)

    /// XPC service has insufficient privileges
    case insufficientPrivileges(service: String, requiredPrivilege: String)

    /// XPC error with unspecified cause
    case internalError(String)

    // MARK: - UmbraError Protocol

    /// Domain identifier for security XPC errors
    public var domain: String {
      "Security.XPC"
    }

    /// Error code uniquely identifying the error type
    public var code: String {
      switch self {
        case .connectionFailed:
          "connection_failed"
        case .invalidMessageFormat:
          "invalid_message_format"
        case .serviceError:
          "service_error"
        case .timeout:
          "timeout"
        case .serviceUnavailable:
          "service_unavailable"
        case .operationCancelled:
          "operation_cancelled"
        case .insufficientPrivileges:
          "insufficient_privileges"
        case .internalError:
          "internal_error"
      }
    }

    /// Human-readable description of the error
    public var errorDescription: String {
      switch self {
        case let .connectionFailed(reason):
          "XPC connection failed: \(reason)"
        case let .invalidMessageFormat(reason):
          "Invalid XPC message format: \(reason)"
        case let .serviceError(code, reason):
          "XPC service error (\(code)): \(reason)"
        case let .timeout(operation, timeoutMs):
          "XPC operation '\(operation)' timed out after \(timeoutMs)ms"
        case let .serviceUnavailable(serviceName):
          "XPC service unavailable: \(serviceName)"
        case let .operationCancelled(operation):
          "XPC operation cancelled: \(operation)"
        case let .insufficientPrivileges(service, requiredPrivilege):
          "XPC service '\(service)' has insufficient privileges. Required: \(requiredPrivilege)"
        case let .internalError(message):
          "Internal XPC error: \(message)"
      }
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
        operation: "xpc_operation",
        details: errorDescription
      )
    }

    /// Creates a new instance of the error with additional context
    public func with(context _: ErrorHandlingInterfaces.ErrorContext) -> Self {
      // Since these are enum cases, we need to return a new instance with the same value
      switch self {
        case let .connectionFailed(reason):
          .connectionFailed(reason: reason)
        case let .invalidMessageFormat(reason):
          .invalidMessageFormat(reason: reason)
        case let .serviceError(code, reason):
          .serviceError(code: code, reason: reason)
        case let .timeout(operation, timeoutMs):
          .timeout(operation: operation, timeoutMs: timeoutMs)
        case let .serviceUnavailable(serviceName):
          .serviceUnavailable(serviceName: serviceName)
        case let .operationCancelled(operation):
          .operationCancelled(operation: operation)
        case let .insufficientPrivileges(service, requiredPrivilege):
          .insufficientPrivileges(service: service, requiredPrivilege: requiredPrivilege)
        case let .internalError(message):
          .internalError(message)
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

extension UmbraErrors.Security.XPC {
  /// Create a connection failed error
  public static func makeConnectionFailed(
    reason: String,
    file _: String = #file,
    line _: Int = #line,
    function _: String = #function
  ) -> Self {
    .connectionFailed(reason: reason)
  }

  /// Create a service error
  public static func makeServiceError(
    code: Int,
    reason: String,
    file _: String = #file,
    line _: Int = #line,
    function _: String = #function
  ) -> Self {
    .serviceError(code: code, reason: reason)
  }

  /// Create a timeout error
  public static func makeTimeout(
    operation: String,
    timeoutMs: Int = 30_000,
    file _: String = #file,
    line _: Int = #line,
    function _: String = #function
  ) -> Self {
    .timeout(operation: operation, timeoutMs: timeoutMs)
  }
}
