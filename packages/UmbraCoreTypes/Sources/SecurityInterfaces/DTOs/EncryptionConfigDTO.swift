import Foundation

/// Data transfer object representing configuration for encryption operations.
///
/// This type provides all the necessary parameters for configuring encryption operations,
/// including algorithm selection, key management, and operation options.
public struct EncryptionConfigDTO: Sendable, Equatable {
    /// The encryption algorithm to use
    public let algorithm: EncryptionAlgorithmDTO
    
    /// The key to use for encryption
    public let key: [UInt8]
    
    /// The initialisation vector to use (if applicable)
    public let iv: [UInt8]?
    
    /// Additional authenticated data (for AEAD algorithms)
    public let aad: [UInt8]?
    
    /// Additional options for the encryption operation
    public let options: [String: String]
    
    /// Creates a new encryption configuration
    /// - Parameters:
    ///   - algorithm: The encryption algorithm to use
    ///   - key: The key to use for encryption
    ///   - iv: The initialisation vector to use (if applicable)
    ///   - aad: Additional authenticated data (for AEAD algorithms)
    ///   - options: Additional options for the encryption operation
    public init(
        algorithm: EncryptionAlgorithmDTO,
        key: [UInt8],
        iv: [UInt8]? = nil,
        aad: [UInt8]? = nil,
        options: [String: String] = [:]
    ) {
        self.algorithm = algorithm
        self.key = key
        self.iv = iv
        self.aad = aad
        self.options = options
    }
}

/// Data transfer object representing configuration for decryption operations.
///
/// This type provides all the necessary parameters for configuring decryption operations,
/// mirroring the encryption configuration structure.
public struct DecryptionConfigDTO: Sendable, Equatable {
    /// The encryption algorithm to use
    public let algorithm: EncryptionAlgorithmDTO
    
    /// The key to use for decryption
    public let key: [UInt8]
    
    /// The initialisation vector to use (if applicable)
    public let iv: [UInt8]?
    
    /// Additional authenticated data (for AEAD algorithms)
    public let aad: [UInt8]?
    
    /// Additional options for the decryption operation
    public let options: [String: String]
    
    /// Creates a new decryption configuration
    /// - Parameters:
    ///   - algorithm: The encryption algorithm to use
    ///   - key: The key to use for decryption
    ///   - iv: The initialisation vector to use (if applicable)
    ///   - aad: Additional authenticated data (for AEAD algorithms)
    ///   - options: Additional options for the decryption operation
    public init(
        algorithm: EncryptionAlgorithmDTO,
        key: [UInt8],
        iv: [UInt8]? = nil,
        aad: [UInt8]? = nil,
        options: [String: String] = [:]
    ) {
        self.algorithm = algorithm
        self.key = key
        self.iv = iv
        self.aad = aad
        self.options = options
    }
}

/// The encryption algorithm to use for cryptographic operations
public enum EncryptionAlgorithmDTO: String, Sendable, Equatable, CaseIterable {
    /// AES encryption with CBC mode
    case aesCBC = "AES-CBC"
    
    /// AES encryption with GCM mode (authenticated encryption)
    case aesGCM = "AES-GCM"
    
    /// ChaCha20 encryption
    case chaCha20 = "ChaCha20"
    
    /// ChaCha20-Poly1305 authenticated encryption
    case chaCha20Poly1305 = "ChaCha20-Poly1305"
    
    /// RSA encryption
    case rsa = "RSA"
    
    /// Returns the recommended key size in bits for this algorithm
    public var recommendedKeySize: Int {
        switch self {
        case .aesCBC, .aesGCM:
            return 256
        case .chaCha20, .chaCha20Poly1305:
            return 256
        case .rsa:
            return 2048
        }
    }
    
    /// Returns whether this algorithm requires an initialisation vector
    public var requiresIV: Bool {
        switch self {
        case .aesCBC, .aesGCM, .chaCha20, .chaCha20Poly1305:
            return true
        case .rsa:
            return false
        }
    }
    
    /// Returns the recommended IV size in bytes for this algorithm
    public var recommendedIVSize: Int? {
        switch self {
        case .aesCBC:
            return 16
        case .aesGCM:
            return 12
        case .chaCha20, .chaCha20Poly1305:
            return 12
        case .rsa:
            return nil
        }
    }
    
    /// Returns whether this algorithm supports authentication
    public var supportsAuthentication: Bool {
        switch self {
        case .aesGCM, .chaCha20Poly1305:
            return true
        case .aesCBC, .chaCha20, .rsa:
            return false
        }
    }
}

/// The hash algorithm to use for hash operations
public enum HashAlgorithmDTO: String, Sendable, Equatable, CaseIterable {
    /// SHA-256 hash algorithm
    case sha256 = "SHA-256"
    
    /// SHA-384 hash algorithm
    case sha384 = "SHA-384"
    
    /// SHA-512 hash algorithm
    case sha512 = "SHA-512"
    
    /// BLAKE2b hash algorithm
    case blake2b = "BLAKE2b"
    
    /// BLAKE3 hash algorithm
    case blake3 = "BLAKE3"
    
    /// Returns the digest size in bytes for this algorithm
    public var digestSize: Int {
        switch self {
        case .sha256:
            return 32
        case .sha384:
            return 48
        case .sha512:
            return 64
        case .blake2b:
            return 64
        case .blake3:
            return 32
        }
    }
}
