import Foundation
import SecurityTypes
import UmbraErrors

/// Comprehensive security error implementation
/// This struct consolidates error handling for security operations across UmbraCore
public struct SecurityError: Error, Equatable, Sendable {
  /// Error domain for categorisation
  public let domain: String

  /// Error code for programmatic handling
  public let code: Int

  /// Human-readable error description
  public let description: String

  /// Additional information about the error
  public let info: [String: String]?

  /// Initialise with domain, code, and description
  /// - Parameters:
  ///   - domain: Error domain (e.g., "Security", "Crypto")
  ///   - code: Error code
  ///   - description: Human-readable description of the error
  ///   - info: Optional additional information
  public init(
    domain: String,
    code: Int,
    description: String,
    info: [String: String]?=nil
  ) {
    self.domain=domain
    self.code=code
    self.description=description
    self.info=info
  }

  /// Compare two SecurityErrors
  public static func == (lhs: SecurityError, rhs: SecurityError) -> Bool {
    lhs.domain == rhs.domain &&
      lhs.code == rhs.code &&
      lhs.description == rhs.description
  }

  /// Create with a specific error domain and reason
  /// - Parameters:
  ///   - domain: Error domain
  ///   - reason: Error reason
  /// - Returns: Configured SecurityError
  public static func withReason(
    domain: String,
    reason: String,
    code: Int=1001,
    info: [String: String]?=nil
  ) -> SecurityError {
    SecurityError(
      domain: domain,
      code: code,
      description: reason,
      info: info
    )
  }

  /// Create a generic security error
  /// - Parameters:
  ///   - reason: Error reason
  ///   - code: Error code
  /// - Returns: Configured SecurityError
  public static func generic(
    reason: String,
    code: Int=1000,
    info: [String: String]?=nil
  ) -> SecurityError {
    SecurityError(
      domain: "Security",
      code: code,
      description: reason,
      info: info
    )
  }
}
