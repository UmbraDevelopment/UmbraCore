import Foundation

/// Comprehensive error type for XPC operations
///
/// This enum provides specific error cases for different types of
/// failures that can occur when working with XPC services.
@frozen
public enum XPCError: LocalizedError, Sendable {
  public enum Category: String, Sendable {
    case crypto
    case credentials
    case security
    case connection
    case invalidRequest
  }

  /// An error occurred in the XPC service
  case serviceError(category: Category, underlying: Error, message: String)
  
  /// Connection to the XPC service failed
  case connectionError(message: String)
  
  /// The request to the XPC service was invalid
  case invalidRequest(message: String)
  
  /// The operation was cancelled
  case operationCancelled(reason: String)
  
  /// The operation timed out
  case timeout(operation: String)
  
  /// Security validation failed
  case securityValidationFailed(reason: String)
  
  /// The service is unavailable
  case serviceUnavailable(name: String)
  
  /// The connection to the XPC service failed
  case connectionFailed(String)
  
  /// Failed to send a message over the XPC connection
  case messageFailed(String)
  
  /// The message format is invalid for XPC transmission
  case invalidMessage(String)
  
  /// The data is invalid
  case invalidData(message: String)

  /// Whether this error is potentially recoverable
  public var isRecoverable: Bool {
    switch self {
      case let .serviceError(category, _, _):
        switch category {
          case .connection:
            true
          default:
            false
        }
      case .connectionError, .timeout, .serviceUnavailable, .connectionFailed:
        true
      case .invalidRequest, .operationCancelled, .securityValidationFailed, 
           .messageFailed, .invalidMessage, .invalidData:
        false
    }
  }

  public var errorDescription: String? {
    switch self {
      case let .serviceError(category, error, message):
        "[\(category.rawValue.capitalized)] \(message): \(error.localizedDescription)"
      case let .connectionError(message):
        "[Connection] \(message)"
      case let .invalidRequest(message):
        "[Invalid Request] \(message)"
      case let .operationCancelled(reason):
        "[Cancelled] \(reason)"
      case let .timeout(operation):
        "[Timeout] Operation timed out: \(operation)"
      case let .securityValidationFailed(reason):
        "[Security] Validation failed: \(reason)"
      case let .serviceUnavailable(name):
        "[Service] \(name) is unavailable"
      case let .connectionFailed(reason):
        "[Connection] XPC connection failed: \(reason)"
      case let .messageFailed(reason):
        "[Message] Failed to send XPC message: \(reason)"
      case let .invalidMessage(reason):
        "[Message] Invalid XPC message format: \(reason)"
      case let .invalidData(message):
        "[Data] XPC invalid data: \(message)"
    }
  }
}
