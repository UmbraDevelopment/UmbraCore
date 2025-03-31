import Foundation

/**
 # Signature Algorithm
 
 Defines the digital signature algorithms supported by the Alpha Dot Five architecture.
 Provides strong typing for signature operations in cryptographic contexts.
 
 ## Supported Algorithms
 - ED25519: Edwards-curve Digital Signature Algorithm (EdDSA) with Curve25519
 - ECDSA: Elliptic Curve Digital Signature Algorithm with various curves
 - RSA: RSA signature algorithm with various padding options
 */
public enum SignatureAlgorithm: String, Sendable, Equatable, Codable, CaseIterable {
    /// ED25519 signature algorithm
    case ed25519
    
    /// ECDSA with P-256 curve
    case ecdsaP256
    
    /// ECDSA with P-384 curve
    case ecdsaP384
    
    /// ECDSA with P-521 curve
    case ecdsaP521
    
    /// RSA with PKCS#1 padding and SHA-256
    case rsaPkcs1Sha256
    
    /// RSA with PKCS#1 padding and SHA-384
    case rsaPkcs1Sha384
    
    /// RSA with PKCS#1 padding and SHA-512
    case rsaPkcs1Sha512
    
    /// RSA with PSS padding and SHA-256
    case rsaPssSha256
    
    /// RSA with PSS padding and SHA-384
    case rsaPssSha384
    
    /// RSA with PSS padding and SHA-512
    case rsaPssSha512
}
