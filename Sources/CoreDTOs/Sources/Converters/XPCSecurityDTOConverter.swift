import CoreErrors
import SecurityBridgeTypes
import UmbraCoreTypes

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

/// Converts between CoreErrors.SecurityError and
/// ErrorHandlingDomains.UmbraErrors.Security.Protocols
public enum XPCSecurityDTOConverter {
  // MARK: - Convert to Protocols

  /// Convert a CoreErrors.SecurityError to ErrorHandlingDomains.UmbraErrors.Security.Protocols
  /// - Parameter error: The error to convert
  /// - Returns: A Foundation-independent ErrorHandlingDomains.UmbraErrors.Security.Protocols error
  public static func toDTO(_ error: CoreErrors.SecurityError) -> ErrorHandlingDomains.UmbraErrors
  .Security.Protocols {
    switch error {
      case let .invalidKey(reason):
        return ErrorHandlingDomains.UmbraErrors.Security.Protocols
          .invalidInput("Invalid key: \(reason)")

      case let .invalidContext(reason):
        return ErrorHandlingDomains.UmbraErrors.Security.Protocols
          .invalidInput("Invalid context: \(reason)")

      case let .invalidParameter(name, reason):
        return ErrorHandlingDomains.UmbraErrors.Security.Protocols
          .invalidInput("Invalid parameter \(name): \(reason)")

      case let .operationFailed(operation, reason):
        return ErrorHandlingDomains.UmbraErrors.Security.Protocols
          .serviceError("Operation failed: \(operation) - \(reason)")

      case let .unsupportedAlgorithm(name):
        return ErrorHandlingDomains.UmbraErrors.Security.Protocols
          .unsupportedOperation(name: "Algorithm: \(name)")

      case let .missingImplementation(component):
        return ErrorHandlingDomains.UmbraErrors.Security.Protocols
          .missingProtocolImplementation(protocolName: component)

      case let .internalError(description):
        return ErrorHandlingDomains.UmbraErrors.Security.Protocols.internalError(description)

      @unknown default:
        return ErrorHandlingDomains.UmbraErrors.Security.Protocols
          .internalError("Unknown security error")
    }
  }

  // MARK: - Convert from Protocols

  /// Convert an ErrorHandlingDomains.UmbraErrors.Security.Protocols to CoreErrors.SecurityError
  /// - Parameter protocols: The protocols error to convert
  /// - Returns: A Foundation-dependent CoreErrors.SecurityError
  public static func fromDTO(
    _ protocols: ErrorHandlingDomains.UmbraErrors.Security
      .Protocols
  ) -> CoreErrors.SecurityError {
    switch protocols {
      case let .invalidInput(message):
        return .invalidParameter(
          name: "input",
          reason: message
        )

      case let .encryptionFailed(message), let .decryptionFailed(message):
        return .operationFailed(operation: "cryptographic operation", reason: message)

      case let .serviceError(message):
        return .operationFailed(
          operation: "service",
          reason: message
        )

      case let .unsupportedOperation(name):
        return .missingImplementation(component: name)

      case let .invalidFormat(reason):
        return .invalidContext(reason: reason)

      case let .missingProtocolImplementation(protocolName):
        return .missingImplementation(component: protocolName)

      case let .incompatibleVersion(version):
        return .operationFailed(
          operation: "version check",
          reason: "Incompatible version: \(version)"
        )

      case let .invalidState(state, expectedState):
        return .invalidContext(reason: "Invalid state: \(state), expected: \(expectedState)")

      case let .internalError(message):
        return .internalError(description: message)

      case let .storageOperationFailed(message):
        return .operationFailed(operation: "storage", reason: message)

      case let .randomGenerationFailed(message):
        return .operationFailed(operation: "random generation", reason: message)

      case let .notImplemented(message):
        return .missingImplementation(component: message)

      @unknown default:
        return .internalError(description: "Unknown error")
    }
  }

  // MARK: - Convert to UmbraErrors

  /// Convert ErrorHandlingDomains.UmbraErrors.Security.Protocols to canonical
  /// UmbraErrors.GeneralSecurity.Core error
  /// - Parameter protocols: The protocols error to convert
  /// - Returns: A canonical UmbraErrors.GeneralSecurity.Core error
  public static func toCanonicalError(
    _ protocols: ErrorHandlingDomains.UmbraErrors.Security
      .Protocols
  ) -> UmbraErrors.GeneralSecurity.Core {
    switch protocols {
      case let .invalidInput(message):
        return .internalError("Invalid input: \(message)")

      case let .encryptionFailed(message):
        return .encryptionFailed(reason: message)

      case let .decryptionFailed(message):
        return .decryptionFailed(reason: message)

      case let .serviceError(message):
        return .internalError("Service error: \(message)")

      case let .unsupportedOperation(name):
        return .internalError("Unsupported operation: \(name)")

      case let .invalidFormat(reason):
        return .internalError("Invalid format: \(reason)")

      case let .missingProtocolImplementation(protocolName):
        return .internalError("Missing protocol: \(protocolName)")

      case let .incompatibleVersion(version):
        return .internalError("Incompatible version: \(version)")

      case let .invalidState(state, expectedState):
        return .internalError("Invalid state: \(state), expected: \(expectedState)")

      case let .internalError(message):
        return .internalError(message)

      case let .storageOperationFailed(message):
        return .internalError("Storage operation failed: \(message)")

      case let .randomGenerationFailed(message):
        return .internalError("Random generation failed: \(message)")

      case let .notImplemented(message):
        return .internalError("Not implemented: \(message)")

      @unknown default:
        return .internalError("Unknown error")
    }
  }
}
