import Foundation

// Local type declarations to replace imports
// These replace the removed ErrorHandling and ErrorHandlingDomains imports

/// Error domain namespace
public enum ErrorDomain {
  /// Security domain
  public static let security="Security"
  /// Crypto domain
  public static let crypto="Crypto"
  /// Application domain
  public static let application="Application"
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
    self.domain=domain
    self.code=code
    self.description=description
  }
}

/// Domain-specific error type for security operations
public enum SecurityError: Error, UmbraError, CustomStringConvertible {
  // Authentication errors
  case authenticationFailed(String)
  case unauthorizedAccess(String)
  case invalidCredentials(String)
  case sessionExpired(String)
  case tokenExpired(String)

  // Cryptography errors
  case encryptionFailed(String)
  case decryptionFailed(String)
  case signatureInvalid(String)
  case hashingFailed(String)
  case keyGenerationFailed(String)

  // Access control errors
  case permissionDenied(String)
  case insufficientPrivileges(String)
  case accessRevoked(String)

  // Certificate errors
  case certificateExpired(String)
  case certificateInvalid(String)
  case certificateVerificationFailed(String)
  case certificateTrustFailed(String)

  // Other security errors
  case secureChannelFailed(String)
  case securityPolicyViolation(String)
  case securityConfigurationError(String)
  case unknown(String)

  // MARK: - DomainError Protocol

  /// Domain identifier for SecurityError
  public static var domain: String {
    "Security"
  }

  // MARK: - UmbraError Protocol

  /// Domain identifier for this error
  public var domain: String {
    SecurityError.domain
  }

  /// Error code
  public var code: String {
    switch self {
      case .authenticationFailed: "auth_failed"
      case .unauthorizedAccess: "unauthorized_access"
      case .invalidCredentials: "invalid_credentials"
      case .sessionExpired: "session_expired"
      case .tokenExpired: "token_expired"
      case .encryptionFailed: "encryption_failed"
      case .decryptionFailed: "decryption_failed"
      case .signatureInvalid: "signature_invalid"
      case .hashingFailed: "hashing_failed"
      case .keyGenerationFailed: "key_generation_failed"
      case .permissionDenied: "permission_denied"
      case .insufficientPrivileges: "insufficient_privileges"
      case .accessRevoked: "access_revoked"
      case .certificateExpired: "certificate_expired"
      case .certificateInvalid: "certificate_invalid"
      case .certificateVerificationFailed: "certificate_verification_failed"
      case .certificateTrustFailed: "certificate_trust_failed"
      case .secureChannelFailed: "secure_channel_failed"
      case .securityPolicyViolation: "security_policy_violation"
      case .securityConfigurationError: "security_configuration_error"
      case .unknown: "unknown_security_error"
    }
  }

  /// Human-readable description
  public var description: String {
    "[\(domain).\(code)] \(errorDescription)"
  }

  /// Human-readable error description
  public var errorDescription: String {
    switch self {
      case let .authenticationFailed(msg): "Authentication failed: \(msg)"
      case let .unauthorizedAccess(msg): "Unauthorized access: \(msg)"
      case let .invalidCredentials(msg): "Invalid credentials: \(msg)"
      case let .sessionExpired(msg): "Session expired: \(msg)"
      case let .tokenExpired(msg): "Token expired: \(msg)"
      case let .encryptionFailed(msg): "Encryption failed: \(msg)"
      case let .decryptionFailed(msg): "Decryption failed: \(msg)"
      case let .signatureInvalid(msg): "Invalid signature: \(msg)"
      case let .hashingFailed(msg): "Hashing failed: \(msg)"
      case let .keyGenerationFailed(msg): "Key generation failed: \(msg)"
      case let .permissionDenied(msg): "Permission denied: \(msg)"
      case let .insufficientPrivileges(msg): "Insufficient privileges: \(msg)"
      case let .accessRevoked(msg): "Access revoked: \(msg)"
      case let .certificateExpired(msg): "Certificate expired: \(msg)"
      case let .certificateInvalid(msg): "Invalid certificate: \(msg)"
      case let .certificateVerificationFailed(msg): "Certificate verification failed: \(msg)"
      case let .certificateTrustFailed(msg): "Certificate trust failed: \(msg)"
      case let .secureChannelFailed(msg): "Secure channel failed: \(msg)"
      case let .securityPolicyViolation(msg): "Security policy violation: \(msg)"
      case let .securityConfigurationError(msg): "Security configuration error: \(msg)"
      case let .unknown(msg): "Unknown security error: \(msg)"
    }
  }

  /// Source information for the error (optional)
  public var source: ErrorHandlingInterfaces.ErrorSource? {
    switch self {
      case .authenticationFailed, .unauthorizedAccess, .invalidCredentials, .sessionExpired,
           .tokenExpired,
           .encryptionFailed, .decryptionFailed, .signatureInvalid, .hashingFailed,
           .keyGenerationFailed,
           .permissionDenied, .insufficientPrivileges, .accessRevoked, .certificateExpired,
           .certificateInvalid,
           .certificateVerificationFailed, .certificateTrustFailed, .secureChannelFailed,
           .securityPolicyViolation,
           .securityConfigurationError, .unknown:
        nil
    }
  }

  /// Underlying error that caused this error (optional)
  public var underlyingError: Error? {
    switch self {
      case .authenticationFailed, .unauthorizedAccess, .invalidCredentials, .sessionExpired,
           .tokenExpired,
           .encryptionFailed, .decryptionFailed, .signatureInvalid, .hashingFailed,
           .keyGenerationFailed,
           .permissionDenied, .insufficientPrivileges, .accessRevoked, .certificateExpired,
           .certificateInvalid,
           .certificateVerificationFailed, .certificateTrustFailed, .secureChannelFailed,
           .securityPolicyViolation,
           .securityConfigurationError, .unknown:
        nil
    }
  }

  /// Context information about the error
  public var context: ErrorHandlingInterfaces.ErrorContext {
    switch self {
      case .authenticationFailed, .unauthorizedAccess, .invalidCredentials, .sessionExpired,
           .tokenExpired,
           .encryptionFailed, .decryptionFailed, .signatureInvalid, .hashingFailed,
           .keyGenerationFailed,
           .permissionDenied, .insufficientPrivileges, .accessRevoked, .certificateExpired,
           .certificateInvalid,
           .certificateVerificationFailed, .certificateTrustFailed, .secureChannelFailed,
           .securityPolicyViolation,
           .securityConfigurationError, .unknown:
        ErrorHandlingInterfaces.ErrorContext(
          source: "SecurityError",
          operation: "security_operation"
        )
    }
  }

  /// Create a new instance with updated context
  public func with(context _: ErrorHandlingInterfaces.ErrorContext) -> SecurityError {
    switch self {
      case let .authenticationFailed(msg):
        .authenticationFailed(msg)
      case let .unauthorizedAccess(msg):
        .unauthorizedAccess(msg)
      case let .invalidCredentials(msg):
        .invalidCredentials(msg)
      case let .sessionExpired(msg):
        .sessionExpired(msg)
      case let .tokenExpired(msg):
        .tokenExpired(msg)
      case let .encryptionFailed(msg):
        .encryptionFailed(msg)
      case let .decryptionFailed(msg):
        .decryptionFailed(msg)
      case let .signatureInvalid(msg):
        .signatureInvalid(msg)
      case let .hashingFailed(msg):
        .hashingFailed(msg)
      case let .keyGenerationFailed(msg):
        .keyGenerationFailed(msg)
      case let .permissionDenied(msg):
        .permissionDenied(msg)
      case let .insufficientPrivileges(msg):
        .insufficientPrivileges(msg)
      case let .accessRevoked(msg):
        .accessRevoked(msg)
      case let .certificateExpired(msg):
        .certificateExpired(msg)
      case let .certificateInvalid(msg):
        .certificateInvalid(msg)
      case let .certificateVerificationFailed(msg):
        .certificateVerificationFailed(msg)
      case let .certificateTrustFailed(msg):
        .certificateTrustFailed(msg)
      case let .secureChannelFailed(msg):
        .secureChannelFailed(msg)
      case let .securityPolicyViolation(msg):
        .securityPolicyViolation(msg)
      case let .securityConfigurationError(msg):
        .securityConfigurationError(msg)
      case let .unknown(msg):
        .unknown(msg)
    }
  }

  /// Create a new instance with an underlying error
  public func with(underlyingError _: Error) -> SecurityError {
    switch self {
      case let .authenticationFailed(msg):
        .authenticationFailed(msg)
      case let .unauthorizedAccess(msg):
        .unauthorizedAccess(msg)
      case let .invalidCredentials(msg):
        .invalidCredentials(msg)
      case let .sessionExpired(msg):
        .sessionExpired(msg)
      case let .tokenExpired(msg):
        .tokenExpired(msg)
      case let .encryptionFailed(msg):
        .encryptionFailed(msg)
      case let .decryptionFailed(msg):
        .decryptionFailed(msg)
      case let .signatureInvalid(msg):
        .signatureInvalid(msg)
      case let .hashingFailed(msg):
        .hashingFailed(msg)
      case let .keyGenerationFailed(msg):
        .keyGenerationFailed(msg)
      case let .permissionDenied(msg):
        .permissionDenied(msg)
      case let .insufficientPrivileges(msg):
        .insufficientPrivileges(msg)
      case let .accessRevoked(msg):
        .accessRevoked(msg)
      case let .certificateExpired(msg):
        .certificateExpired(msg)
      case let .certificateInvalid(msg):
        .certificateInvalid(msg)
      case let .certificateVerificationFailed(msg):
        .certificateVerificationFailed(msg)
      case let .certificateTrustFailed(msg):
        .certificateTrustFailed(msg)
      case let .secureChannelFailed(msg):
        .secureChannelFailed(msg)
      case let .securityPolicyViolation(msg):
        .securityPolicyViolation(msg)
      case let .securityConfigurationError(msg):
        .securityConfigurationError(msg)
      case let .unknown(msg):
        .unknown(msg)
    }
  }

  /// Create a new instance with source information
  public func with(source _: ErrorHandlingInterfaces.ErrorSource) -> SecurityError {
    switch self {
      case let .authenticationFailed(msg):
        .authenticationFailed(msg)
      case let .unauthorizedAccess(msg):
        .unauthorizedAccess(msg)
      case let .invalidCredentials(msg):
        .invalidCredentials(msg)
      case let .sessionExpired(msg):
        .sessionExpired(msg)
      case let .tokenExpired(msg):
        .tokenExpired(msg)
      case let .encryptionFailed(msg):
        .encryptionFailed(msg)
      case let .decryptionFailed(msg):
        .decryptionFailed(msg)
      case let .signatureInvalid(msg):
        .signatureInvalid(msg)
      case let .hashingFailed(msg):
        .hashingFailed(msg)
      case let .keyGenerationFailed(msg):
        .keyGenerationFailed(msg)
      case let .permissionDenied(msg):
        .permissionDenied(msg)
      case let .insufficientPrivileges(msg):
        .insufficientPrivileges(msg)
      case let .accessRevoked(msg):
        .accessRevoked(msg)
      case let .certificateExpired(msg):
        .certificateExpired(msg)
      case let .certificateInvalid(msg):
        .certificateInvalid(msg)
      case let .certificateVerificationFailed(msg):
        .certificateVerificationFailed(msg)
      case let .certificateTrustFailed(msg):
        .certificateTrustFailed(msg)
      case let .secureChannelFailed(msg):
        .secureChannelFailed(msg)
      case let .securityPolicyViolation(msg):
        .securityPolicyViolation(msg)
      case let .securityConfigurationError(msg):
        .securityConfigurationError(msg)
      case let .unknown(msg):
        .unknown(msg)
    }
  }
}

/// Extension to provide convenience initializers
extension SecurityError {
  /// Create a security error from another error
  public static func from(error: Error) -> SecurityError {
    if let securityError=error as? SecurityError {
      return securityError
    }
    // Explicitly cast to NSError to avoid ambiguity with localizedDescription
    let nsError=error as NSError
    return SecurityError.unknown("Wrapped error: " + nsError.localizedDescription)
  }
}
