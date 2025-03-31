import Foundation
import UmbraErrorsCore

/// Domain identifier for security-related errors
public enum SecurityErrorDomain: String, CaseIterable, Sendable {
  /// Domain identifier
  public static let domain="Security"

  // Authentication errors
  case authenticationFailed="AUTHENTICATION_FAILED"
  case unauthorisedAccess="UNAUTHORISED_ACCESS"
  case credentialsExpired="CREDENTIALS_EXPIRED"
  case invalidCredentials="INVALID_CREDENTIALS"

  // Encryption errors
  case encryptionFailed="ENCRYPTION_FAILED"
  case decryptionFailed="DECRYPTION_FAILED"
  case keyGenerationFailed="KEY_GENERATION_FAILED"

  // Key management errors
  case keyRetrievalFailed="KEY_RETRIEVAL_FAILED"
  case keyStorageFailed="KEY_STORAGE_FAILED"
  case keyDeletionFailed="KEY_DELETION_FAILED"
  case keyRotationFailed="KEY_ROTATION_FAILED"
  case keyNotFound="KEY_NOT_FOUND"
  case keyCorrupted="KEY_CORRUPTED"

  // General security errors
  case invalidConfiguration="INVALID_CONFIGURATION"
  case invalidOperation="INVALID_OPERATION"
  case operationFailed="OPERATION_FAILED"
  case securityServiceUnavailable="SECURITY_SERVICE_UNAVAILABLE"

  // Input validation errors
  case invalidInput="INVALID_INPUT"
  case invalidParameter="INVALID_PARAMETER"

  // Hashing errors
  case hashingFailed="HASHING_FAILED"
  case hashVerificationFailed="HASH_VERIFICATION_FAILED"

  // Signature errors
  case signatureFailed="SIGNATURE_FAILED"
  case signatureVerificationFailed="SIGNATURE_VERIFICATION_FAILED"

  // System errors
  case internalError="INTERNAL_ERROR"
  case externalSystemError="EXTERNAL_SYSTEM_ERROR"

  // Miscellaneous
  case unspecified="UNSPECIFIED"
}

/// Extension to add more functionality to the security error domain
extension SecurityErrorDomain {
  /// Map to a standard error severity
  public var defaultSeverity: ErrorSeverity {
    switch self {
      case .invalidInput, .invalidParameter:
        .warning

      case .keyNotFound, .unauthorisedAccess:
        .info

      case .encryptionFailed, .decryptionFailed, .keyGenerationFailed,
           .keyRetrievalFailed, .keyStorageFailed, .keyDeletionFailed,
           .keyRotationFailed, .keyCorrupted, .hashingFailed,
           .hashVerificationFailed, .signatureFailed, .signatureVerificationFailed,
           .authenticationFailed, .invalidCredentials, .credentialsExpired:
        .error

      case .invalidConfiguration, .invalidOperation, .operationFailed,
           .securityServiceUnavailable, .internalError, .externalSystemError:
        .critical

      default:
        .error
    }
  }

  /// Get a user-friendly description of the error
  /// All descriptions use British English spelling
  public var localizedDescription: String {
    switch self {
      case .authenticationFailed:
        "Authentication failed"

      case .unauthorisedAccess:
        "Unauthorised access attempt"

      case .credentialsExpired:
        "The credentials have expired"

      case .invalidCredentials:
        "The credentials provided are invalid"

      case .encryptionFailed:
        "Failed to encrypt the data"

      case .decryptionFailed:
        "Failed to decrypt the data"

      case .keyGenerationFailed:
        "Failed to generate a cryptographic key"

      case .keyRetrievalFailed:
        "Failed to retrieve the cryptographic key"

      case .keyStorageFailed:
        "Failed to store the cryptographic key"

      case .keyDeletionFailed:
        "Failed to delete the cryptographic key"

      case .keyRotationFailed:
        "Failed to rotate the cryptographic key"

      case .keyNotFound:
        "The requested cryptographic key was not found"

      case .keyCorrupted:
        "The cryptographic key is corrupted"

      case .invalidConfiguration:
        "The security configuration is invalid"

      case .invalidOperation:
        "The requested security operation is invalid"

      case .operationFailed:
        "The security operation failed"

      case .securityServiceUnavailable:
        "The security service is currently unavailable"

      case .invalidInput:
        "The input data is invalid for this security operation"

      case .invalidParameter:
        "One or more parameters for the security operation are invalid"

      case .hashingFailed:
        "Failed to compute the hash value"

      case .hashVerificationFailed:
        "Failed to verify the hash value"

      case .signatureFailed:
        "Failed to create the digital signature"

      case .signatureVerificationFailed:
        "Failed to verify the digital signature"

      case .internalError:
        "An internal security error has occurred"

      case .externalSystemError:
        "An error occurred in an external security system"

      case .unspecified:
        "An unspecified security error occurred"
    }
  }
}
