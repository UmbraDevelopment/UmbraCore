import UmbraCoreTypes
import UmbraErrors

/// Protocol error type for XPC service operations
public enum SecurityProtocolError: Error, Equatable, Sendable {
  /// Internal error within the security system
  case internalError(String)

  /// Operation is not supported
  case unsupportedOperation(name: String)

  /// Service error with code
  case serviceError(code: Int, message: String)
}
