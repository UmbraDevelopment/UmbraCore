import Foundation

/**
 Error type for security protocol violations.

 This error type follows the architecture pattern for domain-specific errors
 with detailed information and proper Sendable conformance for actor isolation.
 */
public enum SecurityProtocolError: Error, Equatable, Sendable {
  /// Protocol version mismatch
  case versionMismatch(expected: String, actual: String)

  /// Invalid message format
  case invalidMessageFormat(details: String)

  /// Authentication failure
  case authenticationFailed(reason: String)

  /// Message tampering detected
  case messageIntegrityViolation(details: String)

  /// Sequence violation (e.g., replay attack)
  case sequenceViolation(details: String)

  /// Protocol timeout
  case timeout(operationName: String, limit: TimeInterval)

  /// State machine error
  case invalidState(expected: String, actual: String)

  /// Creates a human-readable description of the error
  public var localizedDescription: String {
    switch self {
      case let .versionMismatch(expected, actual):
        "Protocol version mismatch: expected \(expected), got \(actual)"
      case let .invalidMessageFormat(details):
        "Invalid message format: \(details)"
      case let .authenticationFailed(reason):
        "Authentication failed: \(reason)"
      case let .messageIntegrityViolation(details):
        "Message integrity violation: \(details)"
      case let .sequenceViolation(details):
        "Protocol sequence violation: \(details)"
      case let .timeout(operationName, limit):
        "Protocol operation '\(operationName)' timed out after \(limit) seconds"
      case let .invalidState(expected, actual):
        "Invalid protocol state: expected '\(expected)', but was in '\(actual)'"
    }
  }

  /// Returns an error code for this error
  public var errorCode: Int {
    switch self {
      case .versionMismatch: 1001
      case .invalidMessageFormat: 1002
      case .authenticationFailed: 1003
      case .messageIntegrityViolation: 1004
      case .sequenceViolation: 1005
      case .timeout: 1006
      case .invalidState: 1007
    }
  }
}
