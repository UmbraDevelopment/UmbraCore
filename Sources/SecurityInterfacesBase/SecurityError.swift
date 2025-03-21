import CoreErrors
import ErrorHandlingDomains
import SecurityBridgeTypes
import SecurityInterfacesProtocols
import UmbraCoreTypes
import XPCProtocolsCore

/// This file was previously defining a duplicated SecurityError enum
/// It now uses the canonical UmbraErrors.Security.Core type directly
/// and provides mapping functions to/from CoreErrors.XPCErrors.SecurityError for compatibility

/// Mapping functions for converting between UmbraErrors.Security.Core and
/// CoreErrors.XPCErrors.SecurityError
extension UmbraErrors.Security.Core {
  /// Initialize from a protocol error
  public init(from protocolError: CoreErrors.XPCErrors.SecurityError) {
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
        self = .authorizationFailed(reason: "XPC authorization denied for operation: \(operation)")
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
  public func toProtocolError() -> CoreErrors.XPCErrors.SecurityError? {
    // Map from core error to XPC error
    switch self {
      case let .authenticationFailed(reason):
        .authenticationFailed(reason: reason)
      case let .authorizationFailed(reason):
        .permissionDenied(operation: reason)
      case .secureConnectionFailed:
        .serverUnavailable(serviceName: "unknown")
      case let .internalError(reason) where reason.contains("timed out"):
        .internalError(description: "Operation timed out")
      case let .internalError(reason):
        .internalError(description: reason)
      default:
        .internalError(description: localizedDescription)
    }
  }
}

/// Extension on CoreErrors.XPCErrors.SecurityError to provide mapping back to
/// UmbraErrors.Security.Core
extension CoreErrors.XPCErrors.SecurityError {
  /// Convert to a core error
  /// - Returns: A core error representation of this protocol error
  public func toCoreError() -> UmbraErrors.Security.Core {
    UmbraErrors.Security.Core(from: self)
  }
}
