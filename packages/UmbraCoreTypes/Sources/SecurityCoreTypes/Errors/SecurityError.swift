import Foundation
import SecurityTypes
import UmbraErrors

/// Security error implementation
/// Represents errors specific to security operations with descriptive messages
public struct SecurityError: Error, Equatable, Sendable {
  /// Error description
  public let description: String

  /// Initialise with a description
  public init(description: String) {
    self.description = description
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

/// Error domain namespace
/// Provides standardised domain strings for error categorisation
public enum SecurityErrorDomain {
  /// Security domain
  public static let security = "Security"
  /// Crypto domain
  public static let crypto = "Crypto"
  /// Key management domain
  public static let keyManagement = "KeyManagement"
  /// Storage domain
  public static let storage = "Storage"
  /// XPC service domain
  public static let xpcService = "XPCService"
  /// General application domain
  public static let application = "Application"
}
