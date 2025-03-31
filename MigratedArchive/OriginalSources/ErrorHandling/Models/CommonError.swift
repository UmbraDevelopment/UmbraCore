import Foundation

/// Common error types used across the UmbraCore framework
public enum CommonError: LocalizedError, Equatable {
  /// A required service dependency is not available
  case dependencyUnavailable(String)

  /// An operation failed due to invalid state
  case invalidState(String)

  /// A required resource is not available
  case resourceUnavailable(String)

  /// An operation failed due to system constraints
  case systemConstraint(String)

  /// An operation failed due to security restrictions
  case securityViolation(String)

  /// An operation timed out
  case timeout(String)

  public var errorDescription: String? {
    switch self {
      case let .dependencyUnavailable(details):
        "Required dependency unavailable: \(details)"
      case let .invalidState(details):
        "Invalid state: \(details)"
      case let .resourceUnavailable(details):
        "Resource unavailable: \(details)"
      case let .systemConstraint(details):
        "System constraint: \(details)"
      case let .securityViolation(details):
        "Security violation: \(details)"
      case let .timeout(details):
        "Operation timed out: \(details)"
    }
  }
}
