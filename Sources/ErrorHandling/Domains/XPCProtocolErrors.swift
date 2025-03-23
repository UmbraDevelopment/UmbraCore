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

extension ErrorHandlingDomains.UmbraErrors.XPC {
  /// XPC protocol-specific errors related to service protocols and interfaces
  public enum Protocols: Error, UmbraError, StandardErrorCapabilities {
    // Protocol implementation errors
    /// Missing implementation for required protocol
    case missingProtocolImplementation(protocolName: String)

    /// Protocol data has invalid format
    case invalidFormat(reason: String)

    /// Operation is not supported by this protocol
    case unsupportedOperation(name: String)

    /// Protocol version is incompatible
    case incompatibleVersion(version: String)

    /// Protocol is in an invalid state for the requested operation
    case invalidState(state: String, expectedState: String)

    // Message handling errors
    /// Failed to encode message for protocol
    case messageEncodingFailed(protocolName: String, reason: String)

    /// Failed to decode message from protocol
    case messageDecodingFailed(protocolName: String, reason: String)

    /// Message type is not supported by this protocol version
    case unsupportedMessageType(type: String, protocolName: String, supportedVersion: String?)

    // Protocol security errors
    /// Protocol security verification failed
    case securityVerificationFailed(protocolName: String, reason: String)

    /// Protocol authentication failed
    case authenticationFailed(protocolName: String, reason: String)

    /// Missing required entitlement for protocol
    case entitlementMissing(protocolName: String, entitlement: String)

    // Internal error
    /// Internal protocol error
    case internalError(String)

    // MARK: - UmbraError Protocol

    /// Domain identifier for XPC protocol errors
    public var domain: String {
      "XPC.Protocols"
    }

    /// Error code uniquely identifying the error type
    public var code: String {
      switch self {
        case .missingProtocolImplementation:
          "missing_protocol_implementation"
        case .invalidFormat:
          "invalid_format"
        case .unsupportedOperation:
          "unsupported_operation"
        case .incompatibleVersion:
          "incompatible_version"
        case .invalidState:
          "invalid_state"
        case .messageEncodingFailed:
          "message_encoding_failed"
        case .messageDecodingFailed:
          "message_decoding_failed"
        case .unsupportedMessageType:
          "unsupported_message_type"
        case .securityVerificationFailed:
          "security_verification_failed"
        case .authenticationFailed:
          "authentication_failed"
        case .entitlementMissing:
          "entitlement_missing"
        case .internalError:
          "internal_error"
      }
    }

    /// Human-readable description of the error
    public var errorDescription: String {
      switch self {
        case let .missingProtocolImplementation(protocolName):
          return "Missing implementation for required protocol '\(protocolName)'"
        case let .invalidFormat(reason):
          return "Protocol data has invalid format: \(reason)"
        case let .unsupportedOperation(name):
          return "Operation '\(name)' is not supported by this protocol"
        case let .incompatibleVersion(version):
          return "Protocol version '\(version)' is incompatible"
        case let .invalidState(state, expectedState):
          return "Protocol is in invalid state: current '\(state)', expected '\(expectedState)'"
        case let .messageEncodingFailed(protocolName, reason):
          return "Failed to encode message for protocol '\(protocolName)': \(reason)"
        case let .messageDecodingFailed(protocolName, reason):
          return "Failed to decode message from protocol '\(protocolName)': \(reason)"
        case let .unsupportedMessageType(type, protocolName, supportedVersion):
          var message="Message type '\(type)' is not supported by protocol '\(protocolName)'"
          if let version=supportedVersion {
            message += " (supported in version: \(version))"
          }
          return message
        case let .securityVerificationFailed(protocolName, reason):
          return "Security verification failed for protocol '\(protocolName)': \(reason)"
        case let .authenticationFailed(protocolName, reason):
          return "Authentication failed for protocol '\(protocolName)': \(reason)"
        case let .entitlementMissing(protocolName, entitlement):
          return "Missing required entitlement '\(entitlement)' for protocol '\(protocolName)'"
        case let .internalError(message):
          return "Internal protocol error: \(message)"
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
        operation: "protocol_operation",
        details: errorDescription
      )
    }

    /// Creates a new instance of the error with additional context
    public func with(context _: ErrorHandlingInterfaces.ErrorContext) -> Self {
      // Since these are enum cases, we need to return a new instance with the same value
      switch self {
        case let .missingProtocolImplementation(protocolName):
          .missingProtocolImplementation(protocolName: protocolName)
        case let .invalidFormat(reason):
          .invalidFormat(reason: reason)
        case let .unsupportedOperation(name):
          .unsupportedOperation(name: name)
        case let .incompatibleVersion(version):
          .incompatibleVersion(version: version)
        case let .invalidState(state, expectedState):
          .invalidState(state: state, expectedState: expectedState)
        case let .messageEncodingFailed(protocolName, reason):
          .messageEncodingFailed(protocolName: protocolName, reason: reason)
        case let .messageDecodingFailed(protocolName, reason):
          .messageDecodingFailed(protocolName: protocolName, reason: reason)
        case let .unsupportedMessageType(type, protocolName, supportedVersion):
          .unsupportedMessageType(
            type: type,
            protocolName: protocolName,
            supportedVersion: supportedVersion
          )
        case let .securityVerificationFailed(protocolName, reason):
          .securityVerificationFailed(protocolName: protocolName, reason: reason)
        case let .authenticationFailed(protocolName, reason):
          .authenticationFailed(protocolName: protocolName, reason: reason)
        case let .entitlementMissing(protocolName, entitlement):
          .entitlementMissing(protocolName: protocolName, entitlement: entitlement)
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

extension ErrorHandlingDomains.UmbraErrors.XPC.Protocols {
  /// Create an error for a missing protocol implementation
  public static func makeMissingImplementation(
    protocolName: String,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> Self {
    .missingProtocolImplementation(protocolName: protocolName)
  }

  /// Create an error for an invalid format
  public static func makeInvalidFormat(
    reason: String,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> Self {
    .invalidFormat(reason: reason)
  }

  /// Create an error for an unsupported operation
  public static func makeUnsupportedOperation(
    name: String,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> Self {
    .unsupportedOperation(name: name)
  }

  /// Create an error for an incompatible version
  public static func makeIncompatibleVersion(
    version: String,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> Self {
    .incompatibleVersion(version: version)
  }

  /// Create an error for an invalid state
  public static func makeInvalidState(
    state: String,
    expectedState: String,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> Self {
    .invalidState(state: state, expectedState: expectedState)
  }

  /// Create an error for an internal error
  public static func makeInternalError(
    _ message: String,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> Self {
    .internalError(message)
  }
}
