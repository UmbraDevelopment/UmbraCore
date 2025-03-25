/**
 # UmbraCore Security Types
 
 This file provides security-related type definitions for the UmbraCore security framework.
 */

import Foundation

/// Secure data representation for handling sensitive information
public struct SecureData: Sendable {
    /// The underlying data being secured
    private let data: Data
    
    /// Creates a new secure data instance
    /// - Parameter data: The underlying data to secure
    public init(_ data: Data) {
        self.data = data
    }
    
    /// Retrieves the underlying data (should be used carefully)
    public func getData() -> Data {
        return data
    }
}

/// Secure key representation for cryptographic operations
public struct SecureKey: Sendable {
    /// The underlying key data
    private let keyData: Data
    
    /// Creates a new secure key instance
    /// - Parameter data: The underlying key data
    public init(_ data: Data) {
        self.keyData = data
    }
    
    /// Retrieves the underlying key data (should be used carefully)
    public func getKeyData() -> Data {
        return keyData
    }
}

/// Encryption algorithm options
/// This is the consolidated enum that combines functionality from multiple previous definitions
public enum EncryptionAlgorithm: String, Codable, Sendable {
    /// AES-256 in GCM mode (authenticated encryption)
    case aes256Gcm = "AES-256-GCM"
    /// AES-256 in CBC mode with PKCS#7 padding
    case aes256Cbc = "AES-256-CBC"
    /// ChaCha20 with Poly1305 authentication
    case chacha20Poly1305 = "CHACHA20-POLY1305"
    /// AES in Galois/Counter Mode (legacy)
    case aesGCM = "AES-GCM"
    /// AES in Cipher Block Chaining mode (legacy)
    case aesCBC = "AES-CBC"
    
    /// Default algorithm for encryption
    public static var `default`: EncryptionAlgorithm {
        return .aes256Gcm
    }
}

/// Error type for cryptographic operations
public enum CryptoError: Error, Sendable {
    /// Invalid or corrupted input data
    case invalidData
    /// Invalid key format or length
    case invalidKey
    /// Unsupported encryption algorithm
    case unsupportedAlgorithm
    /// Authentication failed during decryption
    case authenticationFailed
    /// Encryption operation failed
    case encryptionFailed
    /// Decryption operation failed
    case decryptionFailed
    /// Feature not implemented
    case notImplemented(String)
    /// Internal error
    case internalError(String)
}
