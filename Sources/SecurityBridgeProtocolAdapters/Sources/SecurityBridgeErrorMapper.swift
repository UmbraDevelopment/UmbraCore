import SecurityInterfacesProtocols
import SecurityProtocolsCore
import SecurityTypeConverters
import XPCProtocolsCore

/// Error type specific to the security bridge layer
public enum SecurityBridgeError: Error {
  case invalidInputType
  case mappingFailed
  case unsupportedErrorType
  case invalidConfiguration
}

/// Maps between different security error types to provide
/// a consistent error handling interface across security modules
public enum SecurityBridgeErrorMapper {
  /// Maps any error to a SecurityError
  /// - Parameter error: The error to map
  /// - Returns: A UmbraErrors.Security.Protocols representation of the error
  public static func mapToSecurityError(_ error: Error) -> UmbraErrors.Security.Protocols {
    // Direct error mapping without using CoreErrors
    if let securityError=error as? UmbraErrors.Security.Protocols {
      return securityError
    }

    // For bridge-specific errors, provide detailed mapping
    if let bridgeError=error as? SecurityBridgeError {
      switch bridgeError {
        case .invalidInputType:
          return UmbraErrors.Security.Protocols
            .invalidInput(description: "Invalid input type provided to security bridge")
        case .mappingFailed:
          return UmbraErrors.Security.Protocols
            .operationFailed(reason: "Security error mapping failed")
        case .unsupportedErrorType:
          return UmbraErrors.Security.Protocols
            .unsupportedOperation(feature: "Error mapping for unsupported type")
        case .invalidConfiguration:
          return UmbraErrors.Security.Protocols
            .invalidConfiguration(description: "Security bridge configuration invalid")
      }
    }

    // Default fallback
    return UmbraErrors.Security.Protocols
      .operationFailed(reason: "Security operation failed: \(error.localizedDescription)")
  }

  /// Maps a security error to an XPC error type for transmission over XPC
  /// - Parameter error: The error to map
  /// - Returns: An UmbraErrors.Security.XPC representation of the error
  public static func mapToXPCError(_ error: Error) -> UmbraErrors.Security.XPC {
    // Direct mapping without using CoreErrors
    if let xpcError=error as? UmbraErrors.Security.XPC {
      return xpcError
    }

    // Map from security domain to XPC domain
    let description="XPC security operation failed: \(error.localizedDescription)"
    return UmbraErrors.Security.XPC.connectionError(description: description)
  }
}
