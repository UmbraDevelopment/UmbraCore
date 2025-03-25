import Foundation
import Interfaces
import UmbraErrorsCore

/// Core security error types used throughout the UmbraCore framework
///
/// This enum defines all security-related errors in a single, flat structure
/// that integrates with the domain-specific errors in UmbraErrors module.
/// This approach promotes a consistent error taxonomy while maintaining clear
/// separation between internal and external error representations.
public enum SecurityError: Error, Equatable, Sendable {
  // MARK: - Domain Error Wrappers

  /// Core security error from UmbraErrorsCore
  case domainSecurityError(UmbraErrorsCore.UmbraError)

  // MARK: - Authentication Errors

  /// Authentication process failed
  case authenticationFailed(reason: String)

  /// User attempted to access resource without proper authorisation
  case unauthorizedAccess(reason: String)

  /// Provided credentials are invalid
  case invalidCredentials(reason: String)

  // MARK: - Cryptography Errors
  
  /// Failed to encrypt data
  case encryptionFailed(reason: String)
  
  /// Failed to decrypt data
  case decryptionFailed(reason: String)
  
  /// Cryptographic key is invalid or corrupted
  case invalidKey(reason: String)
  
  /// Failed to generate cryptographic key
  case keyGenerationFailed(reason: String)
  
  /// Digital signature verification failed
  case signatureVerificationFailed(reason: String)
  
  /// Certificate is invalid, expired, or untrusted
  case certificateInvalid(reason: String)

  // MARK: - Access Control Errors
  
  /// Permission denied to access a resource
  case permissionDenied(resource: String, reason: String)
  
  /// Session has expired
  case sessionExpired
  
  /// User account is locked or disabled
  case accountLocked(reason: String)
  
  /// Rate limit exceeded for API or service
  case rateLimitExceeded(service: String)

  // MARK: - Secure Storage Errors
  
  /// Failed to store data securely
  case secureStorageFailed(reason: String)
  
  /// Failed to retrieve data from secure storage
  case secureRetrievalFailed(reason: String)
  
  /// Secure storage is corrupted or tampered with
  case secureStorageCorruption
  
  /// Unable to initialise secure storage
  case secureStorageInitialisationFailed(reason: String)
}

// MARK: - CustomStringConvertible
extension SecurityError: CustomStringConvertible {
  public var description: String {
    switch self {
      case let .domainSecurityError(error):
        return "Security error: \(String(describing: error))"
      case let .authenticationFailed(reason):
        return "Authentication failed: \(reason)"
      case let .unauthorizedAccess(reason):
        return "Unauthorized access: \(reason)"
      case let .invalidCredentials(reason):
        return "Invalid credentials: \(reason)"
      case let .encryptionFailed(reason):
        return "Encryption failed: \(reason)"
      case let .decryptionFailed(reason):
        return "Decryption failed: \(reason)"
      case let .invalidKey(reason):
        return "Invalid key: \(reason)"
      case let .keyGenerationFailed(reason):
        return "Key generation failed: \(reason)"
      case let .signatureVerificationFailed(reason):
        return "Signature verification failed: \(reason)"
      case let .certificateInvalid(reason):
        return "Certificate invalid: \(reason)"
      case let .permissionDenied(resource, reason):
        return "Permission denied for \(resource): \(reason)"
      case .sessionExpired:
        return "Session expired"
      case let .accountLocked(reason):
        return "Account locked: \(reason)"
      case let .rateLimitExceeded(service):
        return "Rate limit exceeded for \(service)"
      case let .secureStorageFailed(reason):
        return "Secure storage failed: \(reason)"
      case let .secureRetrievalFailed(reason):
        return "Secure retrieval failed: \(reason)"
      case .secureStorageCorruption:
        return "Secure storage corruption detected"
      case let .secureStorageInitialisationFailed(reason):
        return "Secure storage initialisation failed: \(reason)"
    }
  }
}

// MARK: - Equatable
extension SecurityError {
  public static func == (lhs: SecurityError, rhs: SecurityError) -> Bool {
    switch (lhs, rhs) {
      case let (.domainSecurityError(lhsError), .domainSecurityError(rhsError)):
        return String(describing: lhsError) == String(describing: rhsError)
      case let (.authenticationFailed(lhsReason), .authenticationFailed(rhsReason)):
        return lhsReason == rhsReason
      case let (.unauthorizedAccess(lhsReason), .unauthorizedAccess(rhsReason)):
        return lhsReason == rhsReason
      case let (.invalidCredentials(lhsReason), .invalidCredentials(rhsReason)):
        return lhsReason == rhsReason
      case let (.encryptionFailed(lhsReason), .encryptionFailed(rhsReason)):
        return lhsReason == rhsReason
      case let (.decryptionFailed(lhsReason), .decryptionFailed(rhsReason)):
        return lhsReason == rhsReason
      case let (.invalidKey(lhsReason), .invalidKey(rhsReason)):
        return lhsReason == rhsReason
      case let (.keyGenerationFailed(lhsReason), .keyGenerationFailed(rhsReason)):
        return lhsReason == rhsReason
      case let (.signatureVerificationFailed(lhsReason), .signatureVerificationFailed(rhsReason)):
        return lhsReason == rhsReason
      case let (.certificateInvalid(lhsReason), .certificateInvalid(rhsReason)):
        return lhsReason == rhsReason
      case let (.permissionDenied(lhsResource, lhsReason), .permissionDenied(rhsResource, rhsReason)):
        return lhsResource == rhsResource && lhsReason == rhsReason
      case (.sessionExpired, .sessionExpired):
        return true
      case let (.accountLocked(lhsReason), .accountLocked(rhsReason)):
        return lhsReason == rhsReason
      case let (.rateLimitExceeded(lhsService), .rateLimitExceeded(rhsService)):
        return lhsService == rhsService
      case let (.secureStorageFailed(lhsReason), .secureStorageFailed(rhsReason)):
        return lhsReason == rhsReason
      case let (.secureRetrievalFailed(lhsReason), .secureRetrievalFailed(rhsReason)):
        return lhsReason == rhsReason
      case (.secureStorageCorruption, .secureStorageCorruption):
        return true
      case let (.secureStorageInitialisationFailed(lhsReason), .secureStorageInitialisationFailed(rhsReason)):
        return lhsReason == rhsReason
      default:
        return false
    }
  }
}

extension SecurityError: LocalizedError {
  public var errorDescription: String? {
    description
  }
}
