import Foundation
import CoreSecurityTypes

/// Standard encryption algorithm types supported by the CryptoKit implementation.
///
/// These types provide a consistent interface for specifying encryption algorithms
/// across the Apple Security Provider implementation.
public enum StandardEncryptionAlgorithm: String, Sendable, Equatable, CaseIterable {
    /// AES-256 in GCM mode
    case aes256GCM = "AES-256-GCM"
    
    /// AES-256 in CBC mode
    case aes256CBC = "AES-256-CBC"
    
    /// ChaCha20-Poly1305
    case chacha20Poly1305 = "CHACHA20-POLY1305"
    
    /// Convert to CoreSecurityTypes.EncryptionAlgorithm
    public var encryptionAlgorithm: EncryptionAlgorithm {
        switch self {
        case .aes256GCM:
            return .aes256GCM
        case .aes256CBC:
            return .aes256CBC
        case .chacha20Poly1305:
            return .chacha20Poly1305
        }
    }
    
    /// Create from CoreSecurityTypes.EncryptionAlgorithm
    public init?(from algorithm: EncryptionAlgorithm) {
        switch algorithm {
        case .aes256GCM:
            self = .aes256GCM
        case .aes256CBC:
            self = .aes256CBC
        case .chacha20Poly1305:
            self = .chacha20Poly1305
        }
    }
}

/// Standard encryption modes supported by the CryptoKit implementation.
///
/// These types provide a consistent interface for specifying encryption modes
/// across the Apple Security Provider implementation.
public enum StandardEncryptionMode: String, Sendable, Equatable, CaseIterable {
    /// Galois/Counter Mode (GCM)
    case gcm = "GCM"
    
    /// Cipher Block Chaining (CBC)
    case cbc = "CBC"
    
    /// Stream cipher mode (for ChaCha20-Poly1305)
    case stream = "STREAM"
}

/// Purpose for a cryptographic key.
///
/// Defines the intended usage of a cryptographic key to ensure
/// it is used appropriately in security operations.
public enum KeyPurpose: String, Sendable, Equatable, CaseIterable {
    /// Key used for encryption operations
    case encryption = "ENCRYPTION"
    
    /// Key used for signing operations
    case signing = "SIGNING"
    
    /// Key used for key derivation
    case derivation = "DERIVATION"
    
    /// Key used for key wrapping
    case wrapping = "WRAPPING"
    
    /// General purpose key
    case general = "GENERAL"
}

/// Error handling utilities for cryptographic operations.
///
/// Provides standardised validation and error handling for CryptoKit operations.
public enum CryptoErrorHandling {
    /// Validate a condition and return a result.
    ///
    /// - Parameters:
    ///   - condition: The condition to validate
    ///   - code: The error code to use if validation fails
    ///   - message: The error message
    /// - Returns: A Result indicating success or failure
    public static func validate<T>(
        _ condition: Bool,
        code: CryptoErrorCode,
        message: String
    ) -> Result<T, CryptoOperationError> where T: Sendable {
        if condition {
            // This is a placeholder since we don't have an actual value
            // In a real implementation, this would return a valid value
            fatalError("Success case not implemented - this is a placeholder")
        } else {
            return .failure(CryptoOperationError(
                code: code,
                message: message
            ))
        }
    }
    
    /// Validate a key for a specific algorithm.
    ///
    /// - Parameters:
    ///   - key: The key data to validate
    ///   - algorithm: The algorithm the key will be used with
    /// - Returns: A Result indicating success or failure
    public static func validateKey(
        _ key: Data,
        algorithm: StandardEncryptionAlgorithm
    ) -> Result<Void, CryptoOperationError> {
        // Check if key size is appropriate for the algorithm
        let requiredKeySize: Int
        
        switch algorithm {
        case .aes256GCM, .aes256CBC:
            requiredKeySize = 32 // 256 bits
        case .chacha20Poly1305:
            requiredKeySize = 32 // 256 bits
        }
        
        guard key.count == requiredKeySize else {
            return .failure(CryptoOperationError(
                code: .invalidKey,
                message: "Invalid key size: expected \(requiredKeySize), got \(key.count)"
            ))
        }
        
        return .success(())
    }
}
