import Foundation
import UmbraCoreTypes

/// Error type specifically for security protocol operations
/// Used throughout the security protocol interfaces for consistent error handling
public enum SecurityProtocolError: Error, Equatable, Sendable {
  /// Operation failed due to an internal error
  case internalError(String)

  /// Invalid input was provided
  case invalidInput(String)

  /// Operation is not supported
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

  /// Service error with code (for compatibility with legacy error types)
  case serviceError(code: Int, message: String)

  /// Error comparison
  public static func == (lhs: SecurityProtocolError, rhs: SecurityProtocolError) -> Bool {
    switch (lhs, rhs) {
      case let (.internalError(lmsg), .internalError(rmsg)):
        lmsg == rmsg
      case let (.invalidInput(lmsg), .invalidInput(rmsg)):
        lmsg == rmsg
      case let (.unsupportedOperation(lname), .unsupportedOperation(rname)):
        lname == rname
      case let (.keyManagementError(lmsg), .keyManagementError(rmsg)):
        lmsg == rmsg
      case let (.cryptographicError(lmsg), .cryptographicError(rmsg)):
        lmsg == rmsg
      case let (.authenticationFailed(lmsg), .authenticationFailed(rmsg)):
        lmsg == rmsg
      case let (.storageError(lmsg), .storageError(rmsg)):
        lmsg == rmsg
      case let (.configurationError(lmsg), .configurationError(rmsg)):
        lmsg == rmsg
      case let (.securityError(lmsg), .securityError(rmsg)):
        lmsg == rmsg
      case let (.serviceError(lcode, lmsg), .serviceError(rcode, rmsg)):
        lcode == rcode && lmsg == rmsg
      default:
        false
    }
  }

  /// Maps this error to a descriptive message
  public var localizedDescription: String {
    switch self {
      case let .internalError(message):
        "Internal error: \(message)"
      case let .invalidInput(message):
        "Invalid input: \(message)"
      case let .unsupportedOperation(name):
        "Unsupported operation: \(name)"
      case let .keyManagementError(message):
        "Key management error: \(message)"
      case let .cryptographicError(message):
        "Cryptographic error: \(message)"
      case let .authenticationFailed(message):
        "Authentication failed: \(message)"
      case let .storageError(message):
        "Storage error: \(message)"
      case let .configurationError(message):
        "Configuration error: \(message)"
      case let .securityError(message):
        "Security error: \(message)"
      case let .serviceError(code, message):
        "Service error (\(code)): \(message)"
    }
  }
}
