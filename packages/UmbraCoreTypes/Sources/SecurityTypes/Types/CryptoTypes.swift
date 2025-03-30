import Foundation

/**
 # Key Identifier
 
 A typealias for a string that uniquely identifies a cryptographic key.
 
 This identifier is used to reference keys stored in key management systems.
 */
public typealias KeyIdentifier = String

/**
 # Encryption Algorithm
 
 An enumeration of supported encryption algorithms.
 */
public enum EncryptionAlgorithm: String, Codable, Sendable {
    /// AES with Galois/Counter Mode
    case aesGCM
    /// AES with Cipher Block Chaining mode
    case aesCBC
    /// ChaCha20 with Poly1305
    case chacha20Poly1305
}

/**
 # Signing Algorithm
 
 An enumeration of supported digital signature algorithms.
 */
public enum SigningAlgorithm: String, Codable, Sendable {
    /// RSA with PKCS#1 padding
    case rsaPKCS1
    /// RSA with PSS padding
    case rsaPSS
    /// ECDSA using the P-256 curve
    case ecdsaP256
    /// ECDSA using the P-384 curve
    case ecdsaP384
    /// Ed25519 signature algorithm
    case ed25519
}

/**
 # Key Derivation Algorithm
 
 An enumeration of supported key derivation algorithms.
 */
public enum KeyDerivationAlgorithm: String, Codable, Sendable {
    /// PBKDF2 with HMAC-SHA1
    case pbkdf2SHA1
    /// PBKDF2 with HMAC-SHA256
    case pbkdf2SHA256
    /// PBKDF2 with HMAC-SHA512
    case pbkdf2SHA512
    /// Argon2id
    case argon2id
    /// Scrypt
    case scrypt
}
