import Foundation

/**
 Local module option types for encryption, decryption, hashing, and key generation.
 These types mirror the ones in SecurityCoreInterfaces to provide type-safe conversions.
 */

/**
 Encryption algorithm options available in this module.
 */
public enum EncryptionAlgorithm: String, Sendable {
    case aes = "AES"
    case chacha20 = "ChaCha20"
}

/**
 Encryption mode options available in this module.
 */
public enum EncryptionMode: String, Sendable {
    case cbc = "CBC"
    case gcm = "GCM"
}

/**
 Encryption padding options available in this module.
 */
public enum EncryptionPadding: String, Sendable {
    case none = "None"
    case pkcs7 = "PKCS7"
}

/**
 Options for configuring encryption operations.
 */
public struct EncryptionOptions: Sendable {
    /// The encryption algorithm to use
    public let algorithm: EncryptionAlgorithm
    
    /// The encryption mode to use
    public let mode: EncryptionMode
    
    /// The padding scheme to use
    public let padding: EncryptionPadding
    
    /// Additional authenticated data for authenticated encryption modes
    public let additionalAuthenticatedData: [UInt8]?
    
    /**
     Creates a new set of encryption options.
     
     - Parameters:
        - algorithm: The encryption algorithm to use
        - mode: The encryption mode to use
        - padding: The padding scheme to use
        - additionalAuthenticatedData: Additional data to authenticate (for GCM)
     */
    public init(
        algorithm: EncryptionAlgorithm = .aes,
        mode: EncryptionMode = .gcm,
        padding: EncryptionPadding = .pkcs7,
        additionalAuthenticatedData: [UInt8]? = nil
    ) {
        self.algorithm = algorithm
        self.mode = mode
        self.padding = padding
        self.additionalAuthenticatedData = additionalAuthenticatedData
    }
}

/**
 Options for configuring decryption operations.
 Uses the same type parameters as encryption for consistency.
 */
public typealias DecryptionOptions = EncryptionOptions

/**
 Hashing algorithm options available in this module.
 */
public enum HashingAlgorithm: String, Sendable {
    case sha256 = "SHA256"
    case sha512 = "SHA512"
    case blake2b = "BLAKE2b"
}

/**
 Options for configuring hashing operations.
 */
public struct HashingOptions: Sendable {
    /// The hashing algorithm to use
    public let algorithm: HashingAlgorithm
    
    /// Optional salt to use in hashing
    public let salt: [UInt8]?
    
    /**
     Creates a new set of hashing options.
     
     - Parameters:
        - algorithm: The hashing algorithm to use
        - salt: Optional salt for the hash
     */
    public init(
        algorithm: HashingAlgorithm = .sha256,
        salt: [UInt8]? = nil
    ) {
        self.algorithm = algorithm
        self.salt = salt
    }
}

/**
 Key type options available in this module.
 */
public enum KeyType: String, Sendable {
    case symmetric = "Symmetric"
    case asymmetric = "Asymmetric"
}

/**
 Options for configuring key generation operations.
 */
public struct KeyGenerationOptions: Sendable {
    /// The type of key to generate
    public let keyType: KeyType
    
    /// Whether to use secure enclave for storage (Apple platforms only)
    public let useSecureEnclave: Bool
    
    /// Optional custom identifier for the key
    public let customIdentifier: String?
    
    /**
     Creates a new set of key generation options.
     
     - Parameters:
        - keyType: The type of key to generate
        - useSecureEnclave: Whether to use secure enclave
        - customIdentifier: Optional custom identifier
     */
    public init(
        keyType: KeyType = .symmetric,
        useSecureEnclave: Bool = false,
        customIdentifier: String? = nil
    ) {
        self.keyType = keyType
        self.useSecureEnclave = useSecureEnclave
        self.customIdentifier = customIdentifier
    }
}
