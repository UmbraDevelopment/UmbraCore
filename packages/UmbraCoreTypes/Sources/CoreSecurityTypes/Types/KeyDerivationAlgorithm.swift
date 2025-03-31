import Foundation

/**
 # Key Derivation Algorithm
 
 Defines the key derivation algorithms supported by the Alpha Dot Five architecture.
 Provides strong typing for key derivation operations to ensure consistent implementation.
 
 ## Supported Algorithms
 - PBKDF2: Password-Based Key Derivation Function 2
 - HKDF: HMAC-based Key Derivation Function
 - Argon2: Modern memory-hard password hashing and key derivation function
 */
public enum KeyDerivationAlgorithm: String, Sendable, Equatable, Codable, CaseIterable {
    /// PBKDF2 with HMAC-SHA256
    case pbkdf2HmacSha256
    
    /// PBKDF2 with HMAC-SHA512
    case pbkdf2HmacSha512
    
    /// HKDF with SHA-256
    case hkdfSha256
    
    /// HKDF with SHA-512
    case hkdfSha512
    
    /// Argon2id (balanced variant suitable for both side-channel resistance and memory-hardness)
    case argon2id
    
    /// Argon2d (faster and uses data-depending memory access, more suitable against GPU attacks)
    case argon2d
    
    /// Argon2i (designed to resist side-channel attacks, uses data-independent memory access)
    case argon2i
}
