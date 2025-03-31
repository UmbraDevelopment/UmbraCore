/**
 # KeyGenerationOptionsDTO
 
 Configuration options for cryptographic key generation.
 
 This DTO provides a Foundation-independent way to configure
 parameters for generating cryptographic keys.
 */
public struct KeyGenerationOptionsDTO: Sendable, Equatable {
    /// The algorithm for which to generate a key
    public let algorithm: KeyAlgorithm
    
    /// Key size in bits
    public let keySize: Int
    
    /// Whether the key should be exportable
    public let exportable: Bool
    
    /// Whether the key requires authentication for use
    public let requiresAuthentication: Bool
    
    /// Additional algorithm-specific options
    public let algorithmOptions: [String: String]
    
    /// Create a new KeyGenerationOptionsDTO
    /// 
    /// - Parameters:
    ///   - algorithm: The algorithm for which to generate a key
    ///   - keySize: Key size in bits
    ///   - exportable: Whether the key should be exportable
    ///   - requiresAuthentication: Whether the key requires authentication for use
    ///   - algorithmOptions: Additional algorithm-specific options
    public init(
        algorithm: KeyAlgorithm,
        keySize: Int,
        exportable: Bool = true,
        requiresAuthentication: Bool = false,
        algorithmOptions: [String: String] = [:]
    ) {
        self.algorithm = algorithm
        self.keySize = keySize
        self.exportable = exportable
        self.requiresAuthentication = requiresAuthentication
        self.algorithmOptions = algorithmOptions
    }
    
    /// Creates standard options for AES key generation
    public static func standardAES() -> KeyGenerationOptionsDTO {
        KeyGenerationOptionsDTO(
            algorithm: .aes,
            keySize: 256
        )
    }
    
    /// Creates standard options for RSA key generation
    public static func standardRSA() -> KeyGenerationOptionsDTO {
        KeyGenerationOptionsDTO(
            algorithm: .rsa,
            keySize: 2048
        )
    }
    
    /// Creates standard options for EC key generation
    public static func standardEC() -> KeyGenerationOptionsDTO {
        KeyGenerationOptionsDTO(
            algorithm: .ellipticCurve,
            keySize: 256,
            algorithmOptions: ["curve": "secp256r1"]
        )
    }
}

/// Key algorithms for cryptographic operations
public enum KeyAlgorithm: String, Sendable, Equatable {
    case aes            // Advanced Encryption Standard
    case rsa            // RSA Encryption
    case ellipticCurve  // Elliptic Curve Cryptography
    case hmac           // Hash-based Message Authentication Code
    case ed25519        // Edwards-curve Digital Signature Algorithm
    case x25519         // Curve25519 key exchange
    case chacha20       // ChaCha20 stream cipher
}
