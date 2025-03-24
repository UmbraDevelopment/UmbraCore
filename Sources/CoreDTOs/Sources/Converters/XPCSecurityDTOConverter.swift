

import UmbraErrors
import UmbraErrorsCore
import SecurityBridgeTypes
import UmbraCoreTypes

/// Converts between UmbraErrors.Security.Core and
/// UmbraErrors.Security.Protocols
public enum XPCSecurityDTOConverter {
  // MARK: - Convert to Protocols

  /// Convert a UmbraErrors.Security.Core to UmbraErrors.Security.Protocols
  /// - Parameter error: The error to convert
  /// - Returns: A Foundation-independent UmbraErrors.Security.Protocols error
  public static func toDTO(_ error: UmbraErrors.Security.Core) -> UmbraErrors.Security.Protocols {
    switch error {
      case let .internalError(description: description):
        return .notImplemented(description)

      case let .invalidKey(reason: reason):
        return .invalidInput("Invalid key: \(reason)")

      case let .invalidParameter(name: name, reason: reason):
        return .invalidInput("Invalid parameter \(name): \(reason)")

      case let .operationFailed(reason: reason):
        return .operationFailed(reason)

      case let .missingEntitlement(reason: reason):
        return .operationFailed("Missing entitlement: \(reason)")

      case let .notAuthorized(reason: reason):
        return .operationFailed("Not authorized: \(reason)")

      case let .authenticationFailed(reason: reason):
        return .operationFailed("Authentication failed: \(reason)")

      case let .invalidToken(reason: reason):
        return .invalidInput("Invalid token: \(reason)")

      case let .accessDenied(reason: reason):
        return .operationFailed("Access denied: \(reason)")

      case let .missingImplementation(component: component):
        return .notImplemented("Missing implementation: \(component)")

      case let .invalidCertificate(reason: reason):
        return .invalidInput("Invalid certificate: \(reason)")

      case let .invalidSignature(reason: reason):
        return .invalidInput("Invalid signature: \(reason)")

      case let .invalidContext(reason: reason):
        return .invalidInput("Invalid context: \(reason)")

      @unknown default:
        return .notImplemented("Unknown security error")
    }
  }

  // MARK: - Convert from Protocols

  /// Convert an UmbraErrors.Security.Protocols to UmbraErrors.Security.Core
  /// - Parameter protocols: The protocols error to convert
  /// - Returns: A Foundation-dependent UmbraErrors.Security.Core
  public static func fromDTO(
    _ protocols: UmbraErrors.Security.Protocols
  ) -> UmbraErrors.Security.Core {
    switch protocols {
      case let .invalidInput(message):
        return .invalidParameter(name: "input", reason: message)
      case let .operationFailed(message):
        return .operationFailed(reason: message)
      case let .timeout(message):
        return .operationFailed(reason: "Timeout: \(message)")
      case let .notFound(message):
        return .operationFailed(reason: "Not found: \(message)")
      case let .notAvailable(message):
        return .operationFailed(reason: "Not available: \(message)")
      case let .invalidState(message):
        return .operationFailed(reason: "Invalid state: \(message)")
      case let .randomGenerationFailed(message):
        return .operationFailed(reason: "Random generation failed: \(message)")
      case let .notImplemented(message):
        return .internalError(description: message)
      @unknown default:
        return .internalError(description: "Unknown error")
    }
  }
}
