import Foundation
import UmbraErrorsCore

/// Domain identifier for security-related errors
public enum SecurityErrorDomain: String, CaseIterable, Sendable {
    /// Domain identifier
    public static let domain = "Security"
    
    // Authentication errors
    case authenticationFailed = "AUTHENTICATION_FAILED"
    case unauthorisedAccess = "UNAUTHORISED_ACCESS"
    case credentialsExpired = "CREDENTIALS_EXPIRED"
    case invalidCredentials = "INVALID_CREDENTIALS"
    
    // Encryption errors
    case encryptionFailed = "ENCRYPTION_FAILED"
    case decryptionFailed = "DECRYPTION_FAILED"
    case keyGenerationFailed = "KEY_GENERATION_FAILED"
    
    // Key management errors
    case keyRetrievalFailed = "KEY_RETRIEVAL_FAILED"
    case keyStorageFailed = "KEY_STORAGE_FAILED"
    case keyDeletionFailed = "KEY_DELETION_FAILED"
    case keyRotationFailed = "KEY_ROTATION_FAILED"
    case keyNotFound = "KEY_NOT_FOUND"
    case keyCorrupted = "KEY_CORRUPTED"
    
    // General security errors
    case invalidConfiguration = "INVALID_CONFIGURATION"
    case invalidOperation = "INVALID_OPERATION"
    case operationFailed = "OPERATION_FAILED"
    case securityServiceUnavailable = "SECURITY_SERVICE_UNAVAILABLE"
    
    // Input validation errors
    case invalidInput = "INVALID_INPUT"
    case invalidParameter = "INVALID_PARAMETER"
    
    // Hashing errors
    case hashingFailed = "HASHING_FAILED"
    case hashVerificationFailed = "HASH_VERIFICATION_FAILED"
    
    // Signature errors
    case signatureFailed = "SIGNATURE_FAILED"
    case signatureVerificationFailed = "SIGNATURE_VERIFICATION_FAILED"
    
    // System errors
    case internalError = "INTERNAL_ERROR"
    case externalSystemError = "EXTERNAL_SYSTEM_ERROR"
    
    // Miscellaneous
    case unspecified = "UNSPECIFIED"
}

/// Extension to add more functionality to the security error domain
extension SecurityErrorDomain {
    /// Map to a standard error severity
    public var defaultSeverity: ErrorSeverity {
        switch self {
        case .invalidInput, .invalidParameter:
            return .warning
            
        case .keyNotFound, .unauthorisedAccess:
            return .info
            
        case .encryptionFailed, .decryptionFailed, .keyGenerationFailed,
             .keyRetrievalFailed, .keyStorageFailed, .keyDeletionFailed,
             .keyRotationFailed, .keyCorrupted, .hashingFailed, 
             .hashVerificationFailed, .signatureFailed, .signatureVerificationFailed,
             .authenticationFailed, .invalidCredentials, .credentialsExpired:
            return .error
            
        case .invalidConfiguration, .invalidOperation, .operationFailed,
             .securityServiceUnavailable, .internalError, .externalSystemError:
            return .critical
            
        default:
            return .error
        }
    }
    
    /// Get a user-friendly description of the error
    /// All descriptions use British English spelling
    public var localizedDescription: String {
        switch self {
        case .authenticationFailed:
            return "Authentication failed"
            
        case .unauthorisedAccess:
            return "Unauthorised access attempt"
            
        case .credentialsExpired:
            return "The credentials have expired"
            
        case .invalidCredentials:
            return "The credentials provided are invalid"
            
        case .encryptionFailed:
            return "Failed to encrypt the data"
            
        case .decryptionFailed:
            return "Failed to decrypt the data"
            
        case .keyGenerationFailed:
            return "Failed to generate a cryptographic key"
            
        case .keyRetrievalFailed:
            return "Failed to retrieve the cryptographic key"
            
        case .keyStorageFailed:
            return "Failed to store the cryptographic key"
            
        case .keyDeletionFailed:
            return "Failed to delete the cryptographic key"
            
        case .keyRotationFailed:
            return "Failed to rotate the cryptographic key"
            
        case .keyNotFound:
            return "The requested cryptographic key was not found"
            
        case .keyCorrupted:
            return "The cryptographic key is corrupted"
            
        case .invalidConfiguration:
            return "The security configuration is invalid"
            
        case .invalidOperation:
            return "The requested security operation is invalid"
            
        case .operationFailed:
            return "The security operation failed"
            
        case .securityServiceUnavailable:
            return "The security service is currently unavailable"
            
        case .invalidInput:
            return "The input data is invalid for this security operation"
            
        case .invalidParameter:
            return "One or more parameters for the security operation are invalid"
            
        case .hashingFailed:
            return "Failed to compute the hash value"
            
        case .hashVerificationFailed:
            return "Failed to verify the hash value"
            
        case .signatureFailed:
            return "Failed to create the digital signature"
            
        case .signatureVerificationFailed:
            return "Failed to verify the digital signature"
            
        case .internalError:
            return "An internal security error has occurred"
            
        case .externalSystemError:
            return "An error occurred in an external security system"
            
        case .unspecified:
            return "An unspecified security error occurred"
        }
    }
}
