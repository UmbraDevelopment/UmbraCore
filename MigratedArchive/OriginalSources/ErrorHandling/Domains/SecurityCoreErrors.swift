import Foundation
import Interfaces
import UmbraErrorsCore

extension UmbraErrors.Security {
  /// Core security errors related to authentication, authorisation, encryption, etc.
  public enum Core: Error,
  StandardErrorCapabilitiesProtocol /* , AuthenticationErrors, SecurityOperationErrors */ {
    // Authentication errors
    /// Authentication failed due to invalid credentials or expired session
    case authenticationFailed(reason: String)

    /// Authorisation failed due to insufficient permissions
    case authorizationFailed(reason: String)

    /// Insufficient permissions to access a resource
    case insufficientPermissions(resource: String, requiredPermission: String)

    // Cryptographic operation errors
    /// Encryption operation failed
    case encryptionFailed(reason: String)

    /// Decryption operation failed
    case decryptionFailed(reason: String)

    /// Hash operation failed
    case hashingFailed(reason: String)

    /// Signature verification failed
    case signatureInvalid(reason: String)

    /// Invalid certificate or certificate chain
    case certificateInvalid(reason: String)

    /// Certificate has expired
    case certificateExpired(reason: String)

    // Security policy errors
    /// Operation violates security policy
    case policyViolation(policy: String, reason: String)

    /// Secure connection failed
    case secureConnectionFailed(reason: String)

    /// Secure storage operation failed
    case secureStorageFailed(operation: String, reason: String)

    /// Tampered data detected
    case dataIntegrityViolation(reason: String)

    /// Generic security error
    case internalError(reason: String)

    // MARK: - UmbraError Protocol

    /// Domain identifier for security core errors
    public var domain: String {
      ErrorDomain.security
    }

    /// Error code uniquely identifying the error type
    public var code: String {
      switch self {
        case .authenticationFailed:
          "authentication_failed"
        case .authorizationFailed:
          "authorization_failed"
        case .insufficientPermissions:
          "insufficient_permissions"
        case .encryptionFailed:
          "encryption_failed"
        case .decryptionFailed:
          "decryption_failed"
        case .hashingFailed:
          "hashing_failed"
        case .signatureInvalid:
          "signature_invalid"
        case .certificateInvalid:
          "certificate_invalid"
        case .certificateExpired:
          "certificate_expired"
        case .policyViolation:
          "policy_violation"
        case .secureConnectionFailed:
          "secure_connection_failed"
        case .secureStorageFailed:
          "secure_storage_failed"
        case .dataIntegrityViolation:
          "data_integrity_violation"
        case .internalError:
          "internal_error"
      }
    }

    /// String description for CustomStringConvertible conformance
    public var description: String {
      errorDescription
    }

    /// Human-readable error description
    public var errorDescription: String {
      switch self {
        case let .authenticationFailed(reason):
          "Authentication failed: \(reason)"
        case let .authorizationFailed(reason):
          "Authorization failed: \(reason)"
        case let .insufficientPermissions(resource, permission):
          "Insufficient permissions to access \(resource). Required: \(permission)"
        case let .encryptionFailed(reason):
          "Encryption failed: \(reason)"
        case let .decryptionFailed(reason):
          "Decryption failed: \(reason)"
        case let .hashingFailed(reason):
          "Hash operation failed: \(reason)"
        case let .signatureInvalid(reason):
          "Signature verification failed: \(reason)"
        case let .certificateInvalid(reason):
          "Invalid certificate: \(reason)"
        case let .certificateExpired(reason):
          "Certificate expired: \(reason)"
        case let .policyViolation(policy, reason):
          "Security policy violation (\(policy)): \(reason)"
        case let .secureConnectionFailed(reason):
          "Secure connection failed: \(reason)"
        case let .secureStorageFailed(operation, reason):
          "Secure storage operation '\(operation)' failed: \(reason)"
        case let .dataIntegrityViolation(reason):
          "Data integrity violation detected: \(reason)"
        case let .internalError(reason):
          "Internal security error: \(reason)"
      }
    }

    /// Source information about where the error occurred
    public var source: UmbraErrorsCore.ErrorSource? {
      nil // Source is typically set when the error is created with context
    }

    /// The underlying error, if any
    public var underlyingError: Error? {
      nil // Underlying error is typically set when the error is created with context
    }

    /// Additional context for the error
    public var context: UmbraErrorsCore.ErrorContext {
      UmbraErrorsCore.ErrorContext(
        source: domain,
        operation: "security_operation",
        details: errorDescription
      )
    }

    /// Creates a new instance of the error with additional context
    public func with(context _: UmbraErrorsCore.ErrorContext) -> Self {
      // Since these are enum cases, we need to return a new instance with the same value
      self
    }

    /// Creates a new instance of the error with a specified underlying error
    public func with(underlyingError _: Error) -> Self {
      // Since these are enum cases, we need to return a new instance with the same value
      self
    }

    /// Creates a new instance of the error with source information
    public func with(source _: UmbraErrorsCore.ErrorSource) -> Self {
      // Return self for now - in a real implementation we would attach the source
      self
    }
  }
}

extension UmbraErrors.Security.Core {
  // MARK: - AuthenticationErrors Protocol

  // Note: Factory methods moved to extension below with 'make' prefix
  // to avoid ambiguity with enum cases and to maintain a consistent pattern
  // across the codebase.

  /// Creates an authentication failure error
  public static func makeAuthenticationFailed(reason: String) -> Self {
    .authenticationFailed(reason: reason)
  }

  /// Creates an authorization failure error
  public static func makeAuthorizationFailed(reason: String) -> Self {
    .authorizationFailed(reason: reason)
  }

  /// Creates an error for insufficient permissions
  public static func makeInsufficientPermissions(
    resource: String,
    requiredPermission: String
  ) -> Self {
    .insufficientPermissions(resource: resource, requiredPermission: requiredPermission)
  }

  // MARK: - SecurityOperationErrors Protocol

  // Note: Factory methods moved to extension below with 'make' prefix
  // to avoid ambiguity with enum cases and to maintain a consistent pattern
  // across the codebase.

  /// Creates an error for encryption failure
  public static func makeEncryptionFailed(reason: String) -> Self {
    .encryptionFailed(reason: reason)
  }

  /// Creates an error for decryption failure
  public static func makeDecryptionFailed(reason: String) -> Self {
    .decryptionFailed(reason: reason)
  }

  /// Creates an error for signature verification failure
  public static func makeSignatureInvalid(reason: String) -> Self {
    .signatureInvalid(reason: reason)
  }

  /// Creates an error for hashing failure
  public static func makeHashingFailed(reason: String) -> Self {
    .hashingFailed(reason: reason)
  }
}
