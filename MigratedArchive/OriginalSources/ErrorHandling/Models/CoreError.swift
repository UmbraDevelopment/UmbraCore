import Foundation

/// Base error type for UmbraCore errors
@frozen
public enum CoreError: LocalizedError, Equatable {
  /// Indicates an operation that requires authentication failed
  case authenticationFailed
  /// Indicates an operation failed due to insufficient permissions
  case insufficientPermissions
  /// Indicates an operation failed due to invalid configuration
  case invalidConfiguration(String)
  /// Indicates an operation failed due to a system error
  case systemError(String)

  // MARK: Public

  public var errorDescription: String? {
    switch self {
      case .authenticationFailed:
        "Authentication failed"
      case .insufficientPermissions:
        "Insufficient permissions to perform the operation"
      case let .invalidConfiguration(details):
        "Invalid configuration: \(details)"
      case let .systemError(details):
        "System error: \(details)"
    }
  }
}
