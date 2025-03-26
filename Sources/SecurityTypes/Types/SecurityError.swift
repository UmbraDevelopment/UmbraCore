import Foundation

/// Security error implementation
import SecurityTypes
public struct SecurityError: Error, Equatable {
  /// Error description
  public let description: String

  /// Initialise with a description
  public init(description: String) {
    self.description=description
  }

  /// Compare two SecurityErrors
  public static func == (lhs: SecurityError, rhs: SecurityError) -> Bool {
    lhs.description == rhs.description
  }

  /// Create with a reason
  public static func withReason(_ reason: String) -> SecurityError {
    SecurityError(description: reason)
  }
}

/// Error domain namespace - local implementation
public enum ErrorDomain {
  /// Security domain
  public static let security="Security"
  /// Crypto domain
  public static let crypto="Crypto"
  /// Application domain
  public static let application="Application"
}
