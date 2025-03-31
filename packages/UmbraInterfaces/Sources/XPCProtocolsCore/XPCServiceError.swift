import UmbraErrors

/**
 # XPC Service Errors

 Comprehensive error types for XPC service operations, providing
 structured error reporting for inter-process communication failures.

 These errors follow the Alpha Dot Five architecture principle of
 domain-specific error hierarchies and rich context information.
 */
public enum XPCServiceError: Error, Sendable {
  /// The service connection has failed or timed out
  case connectionFailed(String)

  /// The service is not running
  case serviceNotRunning(String)

  /// The requested endpoint does not exist
  case endpointNotFound(String)

  /// The message could not be encoded
  case messageEncodingFailed(String)

  /// The response could not be decoded
  case responseDecodingFailed(String)

  /// Authentication for the XPC connection failed
  case authenticationFailed(String)

  /// The handler for an endpoint threw an error
  case handlerError(String, Error)

  /// The message type is not compatible with the endpoint
  case incompatibleMessageType(String)

  /// The operation was cancelled
  case cancelled(String)

  /// An unexpected error occurred
  case unexpected(String)
}

/// Extension to provide richer error context suitable for logging
extension XPCServiceError {
  /**
   Creates a log context with privacy-aware information about the error.

   - Returns: A log context suitable for privacy-aware logging
   */
  public func createLogContext() -> XPCErrorLogContext {
    let description: String
    let details: String

    switch self {
      case let .connectionFailed(message):
        description="XPC connection failed"
        details=message
      case let .serviceNotRunning(message):
        description="XPC service not running"
        details=message
      case let .endpointNotFound(message):
        description="XPC endpoint not found"
        details=message
      case let .messageEncodingFailed(message):
        description="XPC message encoding failed"
        details=message
      case let .responseDecodingFailed(message):
        description="XPC response decoding failed"
        details=message
      case let .authenticationFailed(message):
        description="XPC authentication failed"
        details=message
      case let .handlerError(message, error):
        description="XPC handler error"
        details="\(message): \(error)"
      case let .incompatibleMessageType(message):
        description="XPC incompatible message type"
        details=message
      case let .cancelled(message):
        description="XPC operation cancelled"
        details=message
      case let .unexpected(message):
        description="Unexpected XPC error"
        details=message
    }

    return XPCErrorLogContext(description: description, details: details)
  }
}

/**
 Structured log context for XPC errors.

 This context provides privacy-aware information for logging XPC-related errors,
 ensuring that sensitive data is properly handled.
 */
public struct XPCErrorLogContext: Sendable {
  /// General description of the error
  public let description: String

  /// More detailed information, potentially sensitive
  public let details: String

  /**
   Initialises a new XPC error log context.

   - Parameters:
      - description: General description of the error
      - details: More detailed information, potentially sensitive
   */
  public init(description: String, details: String) {
    self.description=description
    self.details=details
  }
}
