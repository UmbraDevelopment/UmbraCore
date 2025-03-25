import Foundation
import UmbraCoreTypes

/// Error type specifically for security protocol operations
/// Used throughout the security protocol interfaces for consistent error handling
public enum SecurityProtocolError: Error, Equatable, Sendable {
  /// Operation failed due to an internal error
  case internalError(String)
  
  /// Invalid input was provided
  case invalidInput(String)
  
  /// Operation is not supported by the implementation
  case unsupportedOperation(name: String)
  
  /// Key management error occurred
  case keyManagementError(String)
  
  /// Cryptographic operation failed
  case cryptographicError(String)
  
  /// Authentication failed
  case authenticationFailed(String)
  
  /// Secure storage operation failed
  case storageError(String)
  
  /// Security configuration error
  case configurationError(String)
  
  /// General security error with explanation
  case securityError(String)
  
  /// Error comparison
  public static func == (lhs: SecurityProtocolError, rhs: SecurityProtocolError) -> Bool {
    switch (lhs, rhs) {
    case let (.internalError(lmsg), .internalError(rmsg)):
      return lmsg == rmsg
    case let (.invalidInput(lmsg), .invalidInput(rmsg)):
      return lmsg == rmsg
    case let (.unsupportedOperation(lname), .unsupportedOperation(rname)):
      return lname == rname
    case let (.keyManagementError(lmsg), .keyManagementError(rmsg)):
      return lmsg == rmsg
    case let (.cryptographicError(lmsg), .cryptographicError(rmsg)):
      return lmsg == rmsg
    case let (.authenticationFailed(lmsg), .authenticationFailed(rmsg)):
      return lmsg == rmsg
    case let (.storageError(lmsg), .storageError(rmsg)):
      return lmsg == rmsg
    case let (.configurationError(lmsg), .configurationError(rmsg)):
      return lmsg == rmsg
    case let (.securityError(lmsg), .securityError(rmsg)):
      return lmsg == rmsg
    default:
      return false
    }
  }
  
  /// Maps this error to a descriptive message
  public var localizedDescription: String {
    switch self {
    case .internalError(let message):
      return "Internal error: \(message)"
    case .invalidInput(let message):
      return "Invalid input: \(message)"
    case .unsupportedOperation(let name):
      return "Unsupported operation: \(name)"
    case .keyManagementError(let message):
      return "Key management error: \(message)"
    case .cryptographicError(let message):
      return "Cryptographic error: \(message)"
    case .authenticationFailed(let message):
      return "Authentication failed: \(message)"
    case .storageError(let message):
      return "Storage error: \(message)"
    case .configurationError(let message):
      return "Configuration error: \(message)"
    case .securityError(let message):
      return "Security error: \(message)"
    }
  }
}
