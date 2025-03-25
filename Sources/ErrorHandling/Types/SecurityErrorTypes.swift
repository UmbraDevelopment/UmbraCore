import Foundation
import Interfaces
import UmbraErrorsCore

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

  /// Hash verification failed
  case hashVerificationFailed(reason: String)

  /// Digital signature verification failed
  case signatureVerificationFailed(reason: String)

  /// Key generation failed
  case keyGenerationFailed(reason: String)

  /// Key material is invalid
  case invalidKeyMaterial(reason: String)

  // MARK: - Access Control Errors

  /// Permission denied for resource
  case permissionDenied(resource: String, reason: String)

  /// Biometric authentication failed
  case biometricAuthenticationFailed(reason: String)

  /// Access control level violation
  case securityLevelViolation(required: String, current: String)

  /// Too many failed authentication attempts
  case tooManyFailedAttempts(attempts: Int, lockoutTime: String?)

  // MARK: - System Security Errors

  /// Secure Enclave operation failed
  case secureEnclaveError(reason: String)

  /// Keychain operation failed
  case keychainError(reason: String)

  /// Tampered binary detected
  case binaryTampering(reason: String)

  /// Memory corruption or exploit attempt detected
  case securityExploitDetected(description: String)

  /// Jailbreak or unsecured environment detected
  case unsecuredEnvironment(reason: String)
}

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
      case let .hashVerificationFailed(reason):
        "Hash verification failed: \(reason)"
      case let .signatureVerificationFailed(reason):
        "Signature verification failed: \(reason)"
      case let .keyGenerationFailed(reason):
        "Key generation failed: \(reason)"
      case let .invalidKeyMaterial(reason):
        "Invalid key material: \(reason)"
      case let .permissionDenied(resource, reason):
        "Permission denied for \(resource): \(reason)"
      case let .biometricAuthenticationFailed(reason):
        "Biometric authentication failed: \(reason)"
      case let .securityLevelViolation(required, current):
        "Security level violation: required \(required), current \(current)"
      case let .tooManyFailedAttempts(attempts, lockoutTime):
        if let lockout = lockoutTime {
          "Too many failed attempts (\(attempts)). Locked out until \(lockout)."
        } else {
          "Too many failed attempts (\(attempts))."
        }
      case let .secureEnclaveError(reason):
        "Secure Enclave error: \(reason)"
      case let .keychainError(reason):
        "Keychain error: \(reason)"
      case let .binaryTampering(reason):
        "Binary tampering detected: \(reason)"
      case let .securityExploitDetected(description):
        "Security exploit detected: \(description)"
      case let .unsecuredEnvironment(reason):
        "Unsecured environment detected: \(reason)"
    }
  }
}

extension SecurityError: LocalizedError {
  public var errorDescription: String? {
    description
  }
}

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
      case let (.hashVerificationFailed(lhsReason), .hashVerificationFailed(rhsReason)):
        lhsReason == rhsReason
      case let (.signatureVerificationFailed(lhsReason), .signatureVerificationFailed(rhsReason)):
        lhsReason == rhsReason
      case let (.keyGenerationFailed(lhsReason), .keyGenerationFailed(rhsReason)):
        lhsReason == rhsReason
      case let (.invalidKeyMaterial(lhsReason), .invalidKeyMaterial(rhsReason)):
        lhsReason == rhsReason
      case let (.permissionDenied(lhsResource, lhsReason), .permissionDenied(rhsResource, rhsReason)):
        lhsResource == rhsResource && lhsReason == rhsReason
      case let (.biometricAuthenticationFailed(lhsReason), .biometricAuthenticationFailed(rhsReason)):
        lhsReason == rhsReason
      case let (.securityLevelViolation(lhsRequired, lhsCurrent), .securityLevelViolation(rhsRequired, rhsCurrent)):
        lhsRequired == rhsRequired && lhsCurrent == rhsCurrent
      case let (.tooManyFailedAttempts(lhsAttempts, lhsLockoutTime), .tooManyFailedAttempts(rhsAttempts, rhsLockoutTime)):
        lhsAttempts == rhsAttempts && lhsLockoutTime == rhsLockoutTime
      case let (.secureEnclaveError(lhsReason), .secureEnclaveError(rhsReason)):
        lhsReason == rhsReason
      case let (.keychainError(lhsReason), .keychainError(rhsReason)):
        lhsReason == rhsReason
      case let (.binaryTampering(lhsReason), .binaryTampering(rhsReason)):
        lhsReason == rhsReason
      case let (.securityExploitDetected(lhsDescription), .securityExploitDetected(rhsDescription)):
        lhsDescription == rhsDescription
      case let (.unsecuredEnvironment(lhsReason), .unsecuredEnvironment(rhsReason)):
        lhsReason == rhsReason
      default:
        false
    }
  }
}
