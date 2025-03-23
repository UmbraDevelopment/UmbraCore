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
  /// Protocol implementation errors in the security domain
  public enum Protocols: Error, UmbraError, StandardErrorCapabilities, Equatable {
    /// A required protocol implementation is missing
    case missingProtocolImplementation(protocolName: String)

    /// Data is in an invalid format for the protocol
    case invalidFormat(reason: String)

    /// The requested operation is not supported by this protocol
    case unsupportedOperation(name: String)

    /// The protocol version is incompatible
    case incompatibleVersion(version: String)

    /// The protocol is in an invalid state for the requested operation
    case invalidState(state: String, expectedState: String)

    /// An unspecified internal error occurred within the protocol implementation
    case internalError(String)

    /// Invalid input was provided to the protocol
    case invalidInput(String)

    /// Encryption operation failed
    case encryptionFailed(String)

    /// Decryption operation failed
    case decryptionFailed(String)

    /// Random data generation failed
    case randomGenerationFailed(String)

    /// Storage operation failed
    case storageOperationFailed(String)

    /// Service error occurred
    case serviceError(String)

    /// Operation not implemented
    case notImplemented(String)

    // MARK: - UmbraError Protocol

    /// Domain identifier for security protocol errors
    public var domain: String {
      "Security.Protocols"
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
        case .internalError:
          "internal_error"
        case .invalidInput:
          "invalid_input"
        case .encryptionFailed:
          "encryption_failed"
        case .decryptionFailed:
          "decryption_failed"
        case .randomGenerationFailed:
          "random_generation_failed"
        case .storageOperationFailed:
          "storage_operation_failed"
        case .serviceError:
          "service_error"
        case .notImplemented:
          "not_implemented"
      }
    }

    /// Human-readable description of the error
    public var errorDescription: String {
      switch self {
        case let .missingProtocolImplementation(protocolName):
          "Missing protocol implementation: \(protocolName)"
        case let .invalidFormat(reason):
          "Invalid data format for protocol: \(reason)"
        case let .unsupportedOperation(name):
          "Operation not supported by protocol: \(name)"
        case let .incompatibleVersion(version):
          "Incompatible protocol version: \(version)"
        case let .invalidState(state, expectedState):
          "Invalid protocol state: current '\(state)', expected '\(expectedState)'"
        case let .internalError(message):
          "Internal protocol error: \(message)"
        case let .invalidInput(message):
          "Invalid input: \(message)"
        case let .encryptionFailed(message):
          "Encryption failed: \(message)"
        case let .decryptionFailed(message):
          "Decryption failed: \(message)"
        case let .randomGenerationFailed(message):
          "Random data generation failed: \(message)"
        case let .storageOperationFailed(message):
          "Storage operation failed: \(message)"
        case let .serviceError(message):
          "Service error: \(message)"
        case let .notImplemented(message):
          "Operation not implemented: \(message)"
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
        case let .internalError(message):
          .internalError(message)
        case let .invalidInput(message):
          .invalidInput(message)
        case let .encryptionFailed(message):
          .encryptionFailed(message)
        case let .decryptionFailed(message):
          .decryptionFailed(message)
        case let .randomGenerationFailed(message):
          .randomGenerationFailed(message)
        case let .storageOperationFailed(message):
          .storageOperationFailed(message)
        case let .serviceError(message):
          .serviceError(message)
        case let .notImplemented(message):
          .notImplemented(message)
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

extension UmbraErrors.Security.Protocols {
  /// Create a missing protocol implementation error
  public static func makeMissingImplementation(
    protocolName: String,
    file _: String = #file,
    line _: Int = #line,
    function _: String = #function
  ) -> Self {
    .missingProtocolImplementation(protocolName: protocolName)
  }

  /// Create an invalid format error
  public static func makeInvalidFormat(
    reason: String,
    file _: String = #file,
    line _: Int = #line,
    function _: String = #function
  ) -> Self {
    .invalidFormat(reason: reason)
  }

  /// Create an unsupported operation error
  public static func makeUnsupportedOperation(
    name: String,
    file _: String = #file,
    line _: Int = #line,
    function _: String = #function
  ) -> Self {
    .unsupportedOperation(name: name)
  }

  /// Create an invalid state error
  public static func makeInvalidState(
    state: String,
    expectedState: String,
    file _: String = #file,
    line _: Int = #line,
    function _: String = #function
  ) -> Self {
    .invalidState(state: state, expectedState: expectedState)
  }

  /// Create an incompatible version error
  public static func makeIncompatibleVersion(
    version: String,
    file _: String = #file,
    line _: Int = #line,
    function _: String = #function
  ) -> Self {
    .incompatibleVersion(version: version)
  }

  /// Create an internal error
  public static func makeInternalError(
    message: String,
    file _: String = #file,
    line _: Int = #line,
    function _: String = #function
  ) -> Self {
    .internalError(message)
  }

  /// Create an invalid input error
  public static func makeInvalidInput(
    message: String,
    file _: String = #file,
    line _: Int = #line,
    function _: String = #function
  ) -> Self {
    .invalidInput(message)
  }

  /// Create an encryption failed error
  public static func makeEncryptionFailed(
    message: String,
    file _: String = #file,
    line _: Int = #line,
    function _: String = #function
  ) -> Self {
    .encryptionFailed(message)
  }

  /// Create a decryption failed error
  public static func makeDecryptionFailed(
    message: String,
    file _: String = #file,
    line _: Int = #line,
    function _: String = #function
  ) -> Self {
    .decryptionFailed(message)
  }

  /// Create a random generation failed error
  public static func makeRandomGenerationFailed(
    message: String,
    file _: String = #file,
    line _: Int = #line,
    function _: String = #function
  ) -> Self {
    .randomGenerationFailed(message)
  }

  /// Create a storage operation failed error
  public static func makeStorageOperationFailed(
    message: String,
    file _: String = #file,
    line _: Int = #line,
    function _: String = #function
  ) -> Self {
    .storageOperationFailed(message)
  }

  /// Create a service error
  public static func makeServiceError(
    message: String,
    file _: String = #file,
    line _: Int = #line,
    function _: String = #function
  ) -> Self {
    .serviceError(message)
  }

  /// Create a not implemented error
  public static func makeNotImplemented(
    message: String,
    file _: String = #file,
    line _: Int = #line,
    function _: String = #function
  ) -> Self {
    .notImplemented(message)
  }
}

// MARK: - Equatable Implementation

extension UmbraErrors.Security.Protocols {
  /// Compares two UmbraErrors.Security.Protocols instances for equality
  /// - Parameters:
  ///   - lhs: Left-hand side instance
  ///   - rhs: Right-hand side instance
  /// - Returns: True if the instances are equal, false otherwise
  public static func == (
    lhs: UmbraErrors.Security.Protocols,
    rhs: UmbraErrors.Security.Protocols
  ) -> Bool {
    switch (lhs, rhs) {
      case let (.missingProtocolImplementation(lhsName), .missingProtocolImplementation(rhsName)):
        lhsName == rhsName
      case let (.invalidFormat(lhsReason), .invalidFormat(rhsReason)):
        lhsReason == rhsReason
      case let (.unsupportedOperation(lhsName), .unsupportedOperation(rhsName)):
        lhsName == rhsName
      case let (.incompatibleVersion(lhsVersion), .incompatibleVersion(rhsVersion)):
        lhsVersion == rhsVersion
      case let (.invalidState(lhsState, lhsExpected), .invalidState(rhsState, rhsExpected)):
        lhsState == rhsState && lhsExpected == rhsExpected
      case let (.internalError(lhsMessage), .internalError(rhsMessage)):
        lhsMessage == rhsMessage
      case let (.invalidInput(lhsMessage), .invalidInput(rhsMessage)):
        lhsMessage == rhsMessage
      case let (.encryptionFailed(lhsMessage), .encryptionFailed(rhsMessage)):
        lhsMessage == rhsMessage
      case let (.decryptionFailed(lhsMessage), .decryptionFailed(rhsMessage)):
        lhsMessage == rhsMessage
      case let (.randomGenerationFailed(lhsMessage), .randomGenerationFailed(rhsMessage)):
        lhsMessage == rhsMessage
      case let (.storageOperationFailed(lhsMessage), .storageOperationFailed(rhsMessage)):
        lhsMessage == rhsMessage
      case let (.serviceError(lhsMessage), .serviceError(rhsMessage)):
        lhsMessage == rhsMessage
      case let (.notImplemented(lhsMessage), .notImplemented(rhsMessage)):
        lhsMessage == rhsMessage
      default:
        false
    }
  }
}
