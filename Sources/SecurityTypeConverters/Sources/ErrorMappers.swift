
import UmbraErrorsCore
import SecurityProtocolsCore
import UmbraErrors
import XPCProtocolsCore

/// Provides standardised error mapping between different security error types
public enum SecurityErrorMapper {
  /// Map any error to Security.Protocols error type
  /// - Parameter error: The error to map
  /// - Returns: A Security.Protocols representation of the error
  public static func toSecurityError(_ error: Error) -> UmbraErrors.Security.Protocols {
    // Check if it's already the correct type
    if let protocolError=error as? UmbraErrors.Security.Protocols {
      return protocolError
    }

    // Convert any UmbraErrors.Security.Core to Protocols
    if let securityError=error as? UmbraErrors.Security.Core {
      // Map based on the case
      switch securityError {
        case let .invalidParameter(name, reason):
          return .invalidParameter(name: name, reason: reason)
        case let .internalError(description):
          return .internalError(description)
        case let .operationFailed(operation, reason):
          return .operationFailed(reason)
        case let .invalidKey(reason):
          return .invalidKey(reason: reason)
        case let .invalidContext(reason):
          return .invalidContext(reason: reason)
      }
    }

    // Default case for other error types
    return .internalError(error.localizedDescription)
  }

  /// Map any error to UmbraErrors.Security.Core
  /// - Parameter error: The error to map
  /// - Returns: A UmbraErrors.Security.Core representation of the error
  public static func toCoreError(_ error: Error) -> UmbraErrors.Security.Core {
    // Check if it's already the correct type
    if let coreError=error as? UmbraErrors.Security.Core {
      return coreError
    }

    // Convert UmbraErrors.Security.Protocols to Core
    if let protocolError=error as? UmbraErrors.Security.Protocols {
      // Map based on the case
      switch protocolError {
        case let .invalidParameter(name, reason):
          return .invalidParameter(name: name, reason: reason)
        case let .internalError(description):
          return .internalError(description: description)
        case let .operationFailed(reason):
          return .operationFailed(operation: "unknown", reason: reason)
        case let .invalidKey(reason):
          return .invalidKey(reason: reason)
        case let .invalidContext(reason):
          return .invalidContext(reason: reason)
      }
    }

    // Default case for other error types
    return .internalError(description: error.localizedDescription)
  }

  /// Map any error to XPC security error type
  /// - Parameter error: The error to map
  /// - Returns: An UmbraErrors.Security.XPC representation
  public static func toXPCError(_ error: Error) -> UmbraErrors.Security.XPC {
    // Check if it's already the correct type
    if let xpcError=error as? UmbraErrors.Security.XPC {
      return xpcError
    }

    // Convert UmbraErrors.Security.Core to XPC
    if let coreError=error as? UmbraErrors.Security.Core {
      // Map based on the case
      switch coreError {
        case let .invalidParameter(name, reason):
          return .invalidParameter(name: name, reason: reason)
        case let .internalError(description):
          return .internalError(description)
        case let .operationFailed(operation, reason):
          return .operationFailed(operation: operation, reason: reason)
        case let .invalidKey(reason):
          return .invalidKey(reason: reason)
        case let .invalidContext(reason):
          return .invalidContext(reason: reason)
      }
    }

    // Default case for other error types
    return .internalError(error.localizedDescription)
  }
}
