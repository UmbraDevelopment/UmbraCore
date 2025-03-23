import ErrorHandlingInterfaces
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

extension UmbraErrors.Security {
  /// Core security errors related to authentication, authorisation, encryption, etc.
  public enum Core: Error, UmbraError, StandardErrorCapabilities, AuthenticationErrors,
  SecurityOperationErrors {
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
      "Security.Core"
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

    /// Human-readable description of the error
    public var errorDescription: String {
      switch self {
        case let .authenticationFailed(reason):
          "Authentication failed: \(reason)"
        case let .authorizationFailed(reason):
          "Authorisation failed: \(reason)"
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
    public var source: ErrorHandlingInterfaces.ErrorSource? {
      nil // Source is typically set when the error is created with context
    }

    /// The underlying error, if any
    public var underlyingError: Error? {
      nil // Underlying error is typically set when the error is created with context
    }

    /// Additional context for the error
    public var context: ErrorHandlingInterfaces.ErrorContext {
      ErrorHandlingInterfaces.ErrorContext(
        source: domain,
        operation: "security_operation",
        details: errorDescription
      )
    }

    /// Creates a new instance of the error with additional context
    public func with(context _: ErrorHandlingInterfaces.ErrorContext) -> Self {
      // Since these are enum cases, we need to return a new instance with the same value
      switch self {
        case let .authenticationFailed(reason):
          .authenticationFailed(reason: reason)
        case let .authorizationFailed(reason):
          .authorizationFailed(reason: reason)
        case let .insufficientPermissions(resource, permission):
          .insufficientPermissions(resource: resource, requiredPermission: permission)
        case let .encryptionFailed(reason):
          .encryptionFailed(reason: reason)
        case let .decryptionFailed(reason):
          .decryptionFailed(reason: reason)
        case let .hashingFailed(reason):
          .hashingFailed(reason: reason)
        case let .signatureInvalid(reason):
          .signatureInvalid(reason: reason)
        case let .certificateInvalid(reason):
          .certificateInvalid(reason: reason)
        case let .certificateExpired(reason):
          .certificateExpired(reason: reason)
        case let .policyViolation(policy, reason):
          .policyViolation(policy: policy, reason: reason)
        case let .secureConnectionFailed(reason):
          .secureConnectionFailed(reason: reason)
        case let .secureStorageFailed(operation, reason):
          .secureStorageFailed(operation: operation, reason: reason)
        case let .dataIntegrityViolation(reason):
          .dataIntegrityViolation(reason: reason)
        case let .internalError(reason):
          .internalError(reason: reason)
      }
      // In a real implementation, we would attach the context
    }

    /// Creates a new instance of the error with a specified underlying error
    public func with(underlyingError _: Error) -> Self {
      // Similar to above, return a new instance with the same value
      self // In a real implementation, we would attach the underlying error
    }

    /// Creates a new instance of the error with source information
    public func with(source _: ErrorHandlingInterfaces.ErrorSource) -> Self {
      // Similar to above, return a new instance with the same value
      self // In a real implementation, we would attach the source information
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
