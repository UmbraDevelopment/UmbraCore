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

extension UmbraErrors.XPC {
  /// Core XPC communication errors
  public enum Core: Error, UmbraError, StandardErrorCapabilities {
    // Connection errors
    /// Failed to establish XPC connection
    case connectionFailed(serviceName: String, reason: String)

    /// XPC connection interrupted
    case connectionInterrupted(serviceName: String)

    /// XPC connection invalid
    case invalidConnection(serviceName: String, reason: String)

    /// XPC service not available
    case serviceUnavailable(serviceName: String)

    // Message errors
    /// Failed to send XPC message
    case messageSendFailed(serviceName: String, reason: String)

    /// Failed to receive XPC message
    case messageReceiveFailed(serviceName: String, reason: String)

    /// XPC message timeout
    case messageTimeout(serviceName: String, timeoutMs: Int)

    /// Invalid XPC message format
    case invalidMessageFormat(serviceName: String, reason: String)

    // Serialisation errors
    /// Failed to serialise XPC object
    case serialisationFailed(typeName: String, reason: String)

    /// Failed to deserialise XPC object
    case deserialisationFailed(typeName: String, reason: String)

    // Security errors
    /// XPC security violation
    case securityViolation(serviceName: String, reason: String)

    /// Entitlement missing for XPC service
    case entitlementMissing(serviceName: String, entitlement: String)

    // Resource errors
    /// XPC service terminated unexpectedly
    case serviceTerminated(serviceName: String, reason: String?)

    /// XPC service crashed
    case serviceCrashed(serviceName: String, exitCode: Int?)

    /// Resource limits exceeded
    case resourceLimitsExceeded(serviceName: String, resource: String)

    // MARK: - UmbraError Protocol

    /// Domain identifier for XPC core errors
    public var domain: String {
      "XPC.Core"
    }

    /// Error code uniquely identifying the error type
    public var code: String {
      switch self {
        case .connectionFailed:
          "connection_failed"
        case .connectionInterrupted:
          "connection_interrupted"
        case .invalidConnection:
          "invalid_connection"
        case .serviceUnavailable:
          "service_unavailable"
        case .messageSendFailed:
          "message_send_failed"
        case .messageReceiveFailed:
          "message_receive_failed"
        case .messageTimeout:
          "message_timeout"
        case .invalidMessageFormat:
          "invalid_message_format"
        case .serialisationFailed:
          "serialisation_failed"
        case .deserialisationFailed:
          "deserialisation_failed"
        case .securityViolation:
          "security_violation"
        case .entitlementMissing:
          "entitlement_missing"
        case .serviceTerminated:
          "service_terminated"
        case .serviceCrashed:
          "service_crashed"
        case .resourceLimitsExceeded:
          "resource_limits_exceeded"
      }
    }

    /// Human-readable description of the error
    public var errorDescription: String {
      switch self {
        case let .connectionFailed(serviceName, reason):
          "Failed to establish XPC connection to service '\(serviceName)': \(reason)"
        case let .connectionInterrupted(serviceName):
          "XPC connection to service '\(serviceName)' was interrupted"
        case let .invalidConnection(serviceName, reason):
          "Invalid XPC connection to service '\(serviceName)': \(reason)"
        case let .serviceUnavailable(serviceName):
          "XPC service '\(serviceName)' is unavailable"
        case let .messageSendFailed(serviceName, reason):
          "Failed to send XPC message to service '\(serviceName)': \(reason)"
        case let .messageReceiveFailed(serviceName, reason):
          "Failed to receive XPC message from service '\(serviceName)': \(reason)"
        case let .messageTimeout(serviceName, timeoutMs):
          "XPC message timeout after \(timeoutMs)ms for service '\(serviceName)'"
        case let .invalidMessageFormat(serviceName, reason):
          "Invalid XPC message format for service '\(serviceName)': \(reason)"
        case let .serialisationFailed(typeName, reason):
          "Failed to serialise object of type '\(typeName)' for XPC transport: \(reason)"
        case let .deserialisationFailed(typeName, reason):
          "Failed to deserialise object of type '\(typeName)' from XPC transport: \(reason)"
        case let .securityViolation(serviceName, reason):
          "XPC security violation with service '\(serviceName)': \(reason)"
        case let .entitlementMissing(serviceName, entitlement):
          "Missing entitlement '\(entitlement)' required for XPC service '\(serviceName)'"
        case let .serviceTerminated(serviceName, reason):
          if let reason {
            "XPC service '\(serviceName)' terminated unexpectedly: \(reason)"
          } else {
            "XPC service '\(serviceName)' terminated unexpectedly"
          }
        case let .serviceCrashed(serviceName, exitCode):
          if let code=exitCode {
            "XPC service '\(serviceName)' crashed with exit code \(code)"
          } else {
            "XPC service '\(serviceName)' crashed"
          }
        case let .resourceLimitsExceeded(serviceName, resource):
          "Resource limits exceeded for XPC service '\(serviceName)': \(resource)"
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
        case let .connectionFailed(serviceName, reason):
          .connectionFailed(serviceName: serviceName, reason: reason)
        case let .connectionInterrupted(serviceName):
          .connectionInterrupted(serviceName: serviceName)
        case let .invalidConnection(serviceName, reason):
          .invalidConnection(serviceName: serviceName, reason: reason)
        case let .serviceUnavailable(serviceName):
          .serviceUnavailable(serviceName: serviceName)
        case let .messageSendFailed(serviceName, reason):
          .messageSendFailed(serviceName: serviceName, reason: reason)
        case let .messageReceiveFailed(serviceName, reason):
          .messageReceiveFailed(serviceName: serviceName, reason: reason)
        case let .messageTimeout(serviceName, timeoutMs):
          .messageTimeout(serviceName: serviceName, timeoutMs: timeoutMs)
        case let .invalidMessageFormat(serviceName, reason):
          .invalidMessageFormat(serviceName: serviceName, reason: reason)
        case let .serialisationFailed(typeName, reason):
          .serialisationFailed(typeName: typeName, reason: reason)
        case let .deserialisationFailed(typeName, reason):
          .deserialisationFailed(typeName: typeName, reason: reason)
        case let .securityViolation(serviceName, reason):
          .securityViolation(serviceName: serviceName, reason: reason)
        case let .entitlementMissing(serviceName, entitlement):
          .entitlementMissing(serviceName: serviceName, entitlement: entitlement)
        case let .serviceTerminated(serviceName, reason):
          .serviceTerminated(serviceName: serviceName, reason: reason)
        case let .serviceCrashed(serviceName, exitCode):
          .serviceCrashed(serviceName: serviceName, exitCode: exitCode)
        case let .resourceLimitsExceeded(serviceName, resource):
          .resourceLimitsExceeded(serviceName: serviceName, resource: resource)
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

extension UmbraErrors.XPC.Core {
  /// Create an error for a failed XPC connection
  public static func makeConnectionFailed(
    serviceName: String,
    reason: String,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> Self {
    .connectionFailed(serviceName: serviceName, reason: reason)
  }

  /// Create an error for an unavailable XPC service
  public static func makeServiceUnavailable(
    serviceName: String,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> Self {
    .serviceUnavailable(serviceName: serviceName)
  }

  /// Create an error for a failed XPC message send
  public static func makeMessageSendFailed(
    serviceName: String,
    reason: String,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> Self {
    .messageSendFailed(serviceName: serviceName, reason: reason)
  }

  /// Create an error for an XPC message timeout
  public static func makeTimeout(
    serviceName: String,
    timeoutMs: Int,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> Self {
    .messageTimeout(serviceName: serviceName, timeoutMs: timeoutMs)
  }

  /// Create an error for a security violation
  public static func makeSecurityViolation(
    serviceName: String,
    reason: String,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> Self {
    .securityViolation(serviceName: serviceName, reason: reason)
  }
}
