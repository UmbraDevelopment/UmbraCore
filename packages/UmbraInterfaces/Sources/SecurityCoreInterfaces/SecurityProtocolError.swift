import Foundation

/// Errors that can occur during security storage operations
public enum SecurityStorageError: Error, Sendable {
    /// The secure storage is not available
    case storageUnavailable
    
    /// The data was not found in secure storage
    case dataNotFound
    
    /// The key was not found in secure storage
    case keyNotFound
    
    /// The hash was not found in secure storage
    case hashNotFound
    
    /// Encryption operation failed
    case encryptionFailed
    
    /// Decryption operation failed
    case decryptionFailed
    
    /// Hashing operation failed
    case hashingFailed
    
    /// Hash verification failed
    case hashVerificationFailed
    
    /// Key generation failed
    case keyGenerationFailed
    
    /// The operation is not supported
    case unsupportedOperation
    
    /// The protocol implementation is not available
    case implementationUnavailable
    
    /// Generic operation failure with optional message
    case operationFailed(String)
    
    /// Description of the error for logging and debugging
    public var description: String {
        switch self {
        case .storageUnavailable:
            return "Secure storage is not available"
        case .dataNotFound:
            return "Data not found in secure storage"
        case .keyNotFound:
            return "Key not found in secure storage"
        case .hashNotFound:
            return "Hash not found in secure storage"
        case .encryptionFailed:
            return "Encryption operation failed"
        case .decryptionFailed:
            return "Decryption operation failed"
        case .hashingFailed:
            return "Hashing operation failed"
        case .hashVerificationFailed:
            return "Hash verification failed"
        case .keyGenerationFailed:
            return "Key generation failed"
        case .unsupportedOperation:
            return "The operation is not supported"
        case .implementationUnavailable:
            return "The protocol implementation is not available"
        case .operationFailed(let message):
            return "Operation failed: \(message)"
        }
    }
}
