import SecurityBridgeTypes
import SecurityInterfacesProtocols
import UmbraCoreTypes
import UmbraErrors
import UmbraErrorsCore
import XPCProtocolsCore

/**
 * This file was previously defining a duplicated SecurityError enum.
 * It now uses the canonical UmbraErrors.Security.Core type directly
 * and provides mapping functions to/from ErrorHandlingDomains.UmbraErrors.XPC.SecurityError
 * for compatibility during migration.
 *
 * Note: These mappings are provided for backwards compatibility and will be
 * phased out when the migration is complete.
 */

/// Mapping functions for converting between UmbraErrors.Security.Core and
/// UmbraErrors.XPC.SecurityError
extension UmbraErrors.Security.Core {
  /// Initialise from a protocol error
  public init(from protocolError: UmbraErrors.XPC.SecurityError) {
    // Map from XPC error to core error
    switch protocolError {
      case let .serverUnavailable(serviceName):
        self = .secureConnectionFailed(reason: "XPC service unavailable: \(serviceName)")
      case let .connectionFailed(reason):
        self = .internalError(reason: "XPC connection failed: \(reason)")
      case let .messagingError(description):
        self = .internalError(reason: "XPC messaging error: \(description)")
      case let .authenticationFailed(reason):
        self = .authenticationFailed(reason: reason)
      case let .permissionDenied(operation):
        self = .authorizationFailed(reason: "XPC authorisation denied for operation: \(operation)")
      case let .invalidRequest(reason):
        self = .internalError(reason: "XPC invalid request: \(reason)")
      case let .incompatibleProtocolVersion(clientVersion, serverVersion):
        self =
          .internalError(
            reason: "XPC incompatible protocol version: client \(clientVersion), server \(serverVersion)"
          )
      case let .internalError(description):
        self = .internalError(reason: description)
      @unknown default:
        self = .internalError(reason: "Unknown XPC security error: \(protocolError)")
    }
  }

  /// Convert to a protocol error
  /// - Returns: A protocol error representation of this error, or nil if no good match
  public func toProtocolError() -> UmbraErrors.XPC.SecurityError? {
    // Map from core error to XPC error
    switch self {
      case let .authenticationFailed(reason):
        .authenticationFailed(reason: reason)
      case let .authorizationFailed(reason):
        .permissionDenied(operation: reason)
      case let .secureConnectionFailed(reason):
        .connectionFailed(reason: reason)
      case let .internalError(reason):
        .internalError(description: reason)
      default:
        // Default to internal error with description
        .internalError(description: localizedDescription)
    }
  }
}
