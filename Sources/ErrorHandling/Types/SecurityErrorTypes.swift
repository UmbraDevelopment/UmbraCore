import Foundation

// Local type declarations to replace imports
// These replace the removed ErrorHandling and ErrorHandlingDomains imports

/// Error domain namespace
public enum ErrorDomain {
  /// Security domain
  public static let security = "Security"
  /// Crypto domain
  public static let crypto = "Crypto"
  /// Application domain
  public static let application = "Application"
}

/// Error context protocol
public protocol ErrorContext {
  /// Domain of the error
  var domain: String { get }
  /// Code of the error
  var code: Int { get }
  /// Description of the error
  var description: String { get }
}

/// Base error context implementation
public struct BaseErrorContext: ErrorContext {
  /// Domain of the error
  public let domain: String
  /// Code of the error
  public let code: Int
  /// Description of the error
  public let description: String

  /// Initialise with domain, code and description
  public init(domain: String, code: Int, description: String) {
    self.domain = domain
    self.code = code
    self.description = description
  }
}

/// Core security error types used throughout the UmbraCore framework
///
/// This enum defines all security-related errors in a single, flat structure
/// that integrates with the domain-specific errors in UmbraErrors.Security hierarchy.
/// This approach promotes a consistent error taxonomy while maintaining clear
/// separation between internal and external error representations.
public enum SecurityError: Error, Equatable, Sendable {
  // MARK: - Domain Error Wrappers

  /// Core security error from UmbraErrors.GeneralSecurity.Core
  case domainCoreError(UmbraErrors.GeneralSecurity.Core)

  /// Protocol-related security error from UmbraErrors.Security.Protocols
  case domainProtocolError(UmbraErrors.Security.Protocols)

  /// XPC-related security error from UmbraErrors.Security.XPC
  case domainXPCError(UmbraErrors.Security.XPC)

  // MARK: - Authentication Errors

  /// Authentication process failed
  case authenticationFailed(reason: String)

  /// User attempted to access resource without proper authorisation
  case unauthorizedAccess(reason: String)

  /// Provided credentials are invalid
  case invalidCredentials(reason: String)

  /// User session has expired
  case sessionExpired(reason: String)

  /// Authentication token has expired
  case tokenExpired(reason: String)

  // MARK: - Cryptographic Errors

  /// Encryption operation failed
  case encryptionFailed(reason: String)

  /// Decryption operation failed
  case decryptionFailed(reason: String)

  /// Key generation failed
  case keyGenerationFailed(reason: String)

  /// Hashing operation failed
  case hashingFailed(reason: String)

  /// Digital signature verification failed
  case signatureInvalid(reason: String)

  // MARK: - Access Control Errors

  /// Permission denied for the requested operation
  case permissionDenied(reason: String)

  /// Certificate validation failed
  case certificateInvalid(reason: String)

  // MARK: - Communication Errors

  /// Secure communication channel failed
  case secureChannelFailed(reason: String)

  /// Security configuration error
  case securityConfigurationError(reason: String)

  // MARK: - General Errors

  /// Internal error within the security system
  case internalError(reason: String)

  /// Unknown security error
  case unknown(reason: String)
}

// MARK: - CustomStringConvertible

extension SecurityError: CustomStringConvertible {
  public var description: String {
    switch self {
      case let .domainCoreError(error):
        "Core security error: \(String(describing: error))"
      case let .domainProtocolError(error):
        "Protocol security error: \(String(describing: error))"
      case let .domainXPCError(error):
        "XPC security error: \(String(describing: error))"
      case let .authenticationFailed(reason):
        "Authentication failed: \(reason)"
      case let .unauthorizedAccess(reason):
        "Unauthorized access: \(reason)"
      case let .invalidCredentials(reason):
        "Invalid credentials: \(reason)"
      case let .sessionExpired(reason):
        "Session expired: \(reason)"
      case let .tokenExpired(reason):
        "Token expired: \(reason)"
      case let .encryptionFailed(reason):
        "Encryption failed: \(reason)"
      case let .decryptionFailed(reason):
        "Decryption failed: \(reason)"
      case let .keyGenerationFailed(reason):
        "Key generation failed: \(reason)"
      case let .hashingFailed(reason):
        "Hashing failed: \(reason)"
      case let .signatureInvalid(reason):
        "Signature invalid: \(reason)"
      case let .permissionDenied(reason):
        "Permission denied: \(reason)"
      case let .certificateInvalid(reason):
        "Certificate invalid: \(reason)"
      case let .secureChannelFailed(reason):
        "Secure channel failed: \(reason)"
      case let .securityConfigurationError(reason):
        "Security configuration error: \(reason)"
      case let .internalError(reason):
        "Internal security error: \(reason)"
      case let .unknown(reason):
        "Unknown security error: \(reason)"
    }
  }
}

// MARK: - LocalizedError

extension SecurityError: LocalizedError {
  public var errorDescription: String? {
    description
  }
}

// MARK: - Equatable

extension SecurityError {
  public static func == (lhs: SecurityError, rhs: SecurityError) -> Bool {
    switch (lhs, rhs) {
      case let (.domainCoreError(lhsError), .domainCoreError(rhsError)):
        String(describing: lhsError) == String(describing: rhsError)
      case let (.domainProtocolError(lhsError), .domainProtocolError(rhsError)):
        String(describing: lhsError) == String(describing: rhsError)
      case let (.domainXPCError(lhsError), .domainXPCError(rhsError)):
        String(describing: lhsError) == String(describing: rhsError)
      case let (.authenticationFailed(lhsReason), .authenticationFailed(rhsReason)):
        lhsReason == rhsReason
      case let (.unauthorizedAccess(lhsReason), .unauthorizedAccess(rhsReason)):
        lhsReason == rhsReason
      case let (.invalidCredentials(lhsReason), .invalidCredentials(rhsReason)):
        lhsReason == rhsReason
      case let (.sessionExpired(lhsReason), .sessionExpired(rhsReason)):
        lhsReason == rhsReason
      case let (.tokenExpired(lhsReason), .tokenExpired(rhsReason)):
        lhsReason == rhsReason
      case let (.encryptionFailed(lhsReason), .encryptionFailed(rhsReason)):
        lhsReason == rhsReason
      case let (.decryptionFailed(lhsReason), .decryptionFailed(rhsReason)):
        lhsReason == rhsReason
      case let (.keyGenerationFailed(lhsReason), .keyGenerationFailed(rhsReason)):
        lhsReason == rhsReason
      case let (.hashingFailed(lhsReason), .hashingFailed(rhsReason)):
        lhsReason == rhsReason
      case let (.signatureInvalid(lhsReason), .signatureInvalid(rhsReason)):
        lhsReason == rhsReason
      case let (.permissionDenied(lhsReason), .permissionDenied(rhsReason)):
        lhsReason == rhsReason
      case let (.certificateInvalid(lhsReason), .certificateInvalid(rhsReason)):
        lhsReason == rhsReason
      case let (.secureChannelFailed(lhsReason), .secureChannelFailed(rhsReason)):
        lhsReason == rhsReason
      case let (.securityConfigurationError(lhsReason), .securityConfigurationError(rhsReason)):
        lhsReason == rhsReason
      case let (.internalError(lhsReason), .internalError(rhsReason)):
        lhsReason == rhsReason
      case let (.unknown(lhsReason), .unknown(rhsReason)):
        lhsReason == rhsReason
      default:
        false
    }
  }
}
