import Foundation
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
    info: [String: String]? = nil
  ) {
    self.domain = domain
    self.code = code
    self.description = description
    self.info = info
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
  public static func withReason(_ reason: String, domain: String = ErrorDomain.security) -> SecurityError {
    SecurityError(domain: domain, code: 1, description: reason)
  }
  
  /// Convert to UmbraErrors.XPC.SecurityError
  /// - Returns: The corresponding XPC security error
  public func toXPCError() -> UmbraErrors.XPC.SecurityError {
    .internalError(description: description)
  }
}

/// Error domain namespace for security errors
public enum ErrorDomain {
  /// Security domain for general security errors
  public static let security = "Security"
  
  /// Crypto domain for cryptographic operation errors
  public static let crypto = "Crypto"
  
  /// Key management domain for key-related errors
  public static let keyManagement = "KeyManagement"
  
  /// Storage domain for secure storage errors
  public static let storage = "Storage"
  
  /// Application domain for application-specific security errors
  public static let application = "Application"
}
