import Foundation
import UmbraErrors

/// Security protocol errors used by the security implementation
/// 
/// Aligned with the Alpha Dot Five architecture principles for consistent error handling
/// across security operations with British English documentation.
public enum SecurityProtocolError: Error, Equatable, Sendable {
    /// Error during hashing operation
    case hashingFailed(message: String)
    
    /// Error during key retrieval operation
    case keyRetrievalFailed(message: String)
    
    /// Error during key storage operation
    case keyStorageFailed(message: String)
    
    /// Error during key deletion operation
    case keyDeletionFailed(message: String)
    
    /// Error during key rotation operation
    case keyRotationFailed(message: String)
    
    /// Error during encryption operation
    case encryptionFailed(message: String)
    
    /// Error during decryption operation
    case decryptionFailed(message: String)
    
    /// Error during signature operation
    case signatureFailed(message: String)
    
    /// Error during verification operation
    case verificationFailed(message: String)
    
    /// Error due to invalid configuration
    case invalidConfiguration(message: String)
    
    /// Error due to invalid operation
    case invalidOperation(message: String)
    
    /// Error due to unknown/unspecified reason
    case unknown(message: String)
}
