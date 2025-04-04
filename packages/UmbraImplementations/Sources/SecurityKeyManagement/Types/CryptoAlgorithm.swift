import Foundation

/**
 # CryptoAlgorithm
 
 Represents the cryptographic algorithms supported by the security system.
 This enumeration provides a strongly-typed representation of algorithms
 that can be used for encryption, decryption, and key generation operations.
 
 Each algorithm has associated properties such as key sizes and modes of operation.
 */
public enum CryptoAlgorithm: String, Sendable, Codable, Equatable, CaseIterable {
    /// Advanced Encryption Standard with Cipher Block Chaining
    case aes = "AES"
    
    /// RSA asymmetric encryption
    case rsa = "RSA"
    
    /// Curve25519-based elliptic curve cryptography
    case curve25519 = "ED25519"
    
    /// ChaCha20-Poly1305 authenticated encryption
    case chaCha20Poly1305 = "CHACHA20-POLY1305"
    
    /// A secure hashing algorithm (SHA-2 family)
    case sha256 = "SHA256"
    
    /// HMAC-based algorithm
    case hmac = "HMAC"
    
    /// Default algorithm for new keys
    public static var `default`: CryptoAlgorithm {
        return .aes
    }
    
    /**
     Get the recommended key size in bits for this algorithm.
     
     - Returns: The recommended key size in bits
     */
    public var recommendedKeySize: Int {
        switch self {
        case .aes:
            return 256
        case .rsa:
            return 2048
        case .curve25519:
            return 256
        case .chaCha20Poly1305:
            return 256
        case .sha256:
            return 256
        case .hmac:
            return 256
        }
    }
    
    /**
     Determines if the given key size is valid for this algorithm.
     
     - Parameter size: Key size in bits to validate
     - Returns: True if the key size is valid for this algorithm
     */
    public func isValidKeySize(_ size: Int) -> Bool {
        switch self {
        case .aes:
            return [128, 192, 256].contains(size)
        case .rsa:
            return size >= 2048 && size <= 4096
        case .curve25519:
            return size == 256
        case .chaCha20Poly1305:
            return size == 256
        case .sha256:
            return size == 256
        case .hmac:
            return size >= 128 && size <= 512
        }
    }
}
