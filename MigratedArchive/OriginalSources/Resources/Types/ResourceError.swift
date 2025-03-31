import Foundation

/// Errors that can occur during resource operations
public enum ResourceError: LocalizedError, Sendable {
  /// Resource acquisition failed
  case acquisitionFailed(String)

  /// Resource is in an invalid state for the requested operation
  case invalidState(String)

  /// Resource pool is exhausted (no more resources available)
  case poolExhausted

  /// Resource not found in pool
  case resourceNotFound(String)

  /// Resource operation failed
  case operationFailed(String)

  public var errorDescription: String? {
    switch self {
      case let .acquisitionFailed(message):
        "Resource acquisition failed: \(message)"
      case let .invalidState(message):
        "Resource in invalid state: \(message)"
      case .poolExhausted:
        "Resource pool exhausted: no more resources available"
      case let .resourceNotFound(id):
        "Resource not found: \(id)"
      case let .operationFailed(message):
        "Resource operation failed: \(message)"
    }
  }
}
