import Foundation

/// Security core error implementation
/// This replaces the previous typealias with a concrete implementation
public enum SecurityCoreError: Error, Equatable {
  /// Generic security error
  case generic(description: String)
  /// Authentication failed error
  case authenticationFailed(reason: String)
  /// Authorization failed error
  case authorizationFailed(reason: String)
  /// Cryptographic error
  case cryptographicError(reason: String)

  /// Compare two SecurityCoreErrors
  public static func == (lhs: SecurityCoreError, rhs: SecurityCoreError) -> Bool {
    switch (lhs, rhs) {
      case let (.generic(lDesc), .generic(rDesc)):
        lDesc == rDesc
      case let (.authenticationFailed(lReason), .authenticationFailed(rReason)):
        lReason == rReason
      case let (.authorizationFailed(lReason), .authorizationFailed(rReason)):
        lReason == rReason
      case let (.cryptographicError(lReason), .cryptographicError(rReason)):
        lReason == rReason
      default:
        false
    }
  }
}
