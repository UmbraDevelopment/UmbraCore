import CoreSecurityTypes
import Foundation
import SecurityCoreInterfaces

/**
 # Parameter Standards
 
 This module defines standard parameter configurations for cryptographic operations
 in the UmbraCore system. It provides factories for creating consistently configured
 parameter objects for common use cases.
 
 These standards:
 - Ensure consistent configuration across the system
 - Provide sensible defaults for common scenarios
 - Simplify the API for higher-level components
 */
public enum ParameterStandards {
    
    // MARK: - Standardized Algorithm Configurations
    
    /// Standard encryption algorithms
    public enum StandardEncryptionAlgorithm: String, Sendable {
        case aes256CBC = "AES-256-CBC"
        case aes256GCM = "AES-256-GCM"
        case chacha20Poly1305 = "ChaCha20-Poly1305"
        
        /// Default algorithm
        public static let `default`: StandardEncryptionAlgorithm = .aes256GCM
        
        /// Converts to CoreSecurityTypes.EncryptionAlgorithm
        public var toCoreType: EncryptionAlgorithm {
            switch self {
            case .aes256CBC:
                return .aes256CBC
            case .aes256GCM:
                return .aes256GCM
            case .chacha20Poly1305:
                return .chacha20Poly1305
            }
        }
    }
    
    /// Standard encryption modes
    public enum StandardEncryptionMode: String, Sendable {
        case cbc = "CBC"
        case gcm = "GCM"
        
        /// Default mode
        public static let `default`: StandardEncryptionMode = .gcm
        
        /// Converts to CoreSecurityTypes.EncryptionMode
        public var toCoreType: EncryptionMode {
            switch self {
            case .cbc:
                return .cbc
            case .gcm:
                return .gcm
            }
        }
    }
    
    /// Standard encryption padding methods
    public enum StandardPadding: String, Sendable {
        case pkcs7 = "PKCS7"
        case none = "None"
        
        /// Default padding
        public static let `default`: StandardPadding = .pkcs7
        
        /// Converts to CoreSecurityTypes.EncryptionPadding
        public var toCoreType: EncryptionPadding {
            switch self {
            case .pkcs7:
                return .pkcs7
            case .none:
                return .none
            }
        }
    }
    
    /// Standard hash algorithms
    public enum StandardHashAlgorithm: String, Sendable {
        case sha256 = "SHA-256"
        case sha512 = "SHA-512"
        case blake2b = "BLAKE2b"
        
        /// Default hash algorithm
        public static let `default`: StandardHashAlgorithm = .sha256
        
        /// Converts to CoreSecurityTypes.HashAlgorithm
        public var toCoreType: HashAlgorithm {
            switch self {
            case .sha256:
                return .sha256
            case .sha512:
                return .sha512
            case .blake2b:
                return .blake2b
            }
        }
    }
    
    /// Standard key usage specifications
    public enum StandardKeyUsage: String, Sendable {
        case encryption = "encryption"
        case signing = "signing"
        case authentication = "authentication"
        case derivation = "derivation"
        
        /// Default key usage
        public static let `default`: StandardKeyUsage = .encryption
    }
    
    // MARK: - Factory Methods
    
    /**
     Creates standard encryption options with sensible defaults.
     
     - Parameters:
        - algorithm: The encryption algorithm to use
        - mode: The encryption mode to use
        - padding: The padding method to use
        - iv: The initialisation vector (generated if nil)
        - aad: Additional authenticated data for AEAD modes
     - Returns: A new EncryptionOptions instance
     */
    public static func standardEncryption(
        algorithm: StandardEncryptionAlgorithm = .default,
        mode: StandardEncryptionMode = .default,
        padding: StandardPadding? = nil,
        iv: Data? = nil,
        aad: Data? = nil
    ) -> EncryptionOptions {
        // Determine the appropriate padding based on the algorithm and mode
        let effectivePadding: StandardPadding
        
        if let padding = padding {
            effectivePadding = padding
        } else if mode == .cbc {
            effectivePadding = .pkcs7
        } else {
            effectivePadding = .none
        }
        
        // Convert Data types to byte arrays
        let ivBytes: [UInt8]? = iv.map { [UInt8]($0) }
        let aadBytes: [UInt8]? = aad.map { [UInt8]($0) }
        
        return EncryptionOptions(
            algorithm: algorithm.toCoreType,
            mode: mode.toCoreType,
            padding: effectivePadding.toCoreType,
            iv: ivBytes,
            additionalAuthenticatedData: aadBytes
        )
    }
    
    /**
     Creates standard decryption options with sensible defaults.
     
     - Parameters:
        - algorithm: The decryption algorithm to use
        - mode: The decryption mode to use
        - padding: The padding method to use
        - iv: The initialisation vector
        - aad: Additional authenticated data for AEAD modes
     - Returns: A new DecryptionOptions instance
     */
    public static func standardDecryption(
        algorithm: StandardEncryptionAlgorithm = .default,
        mode: StandardEncryptionMode = .default,
        padding: StandardPadding? = nil,
        iv: Data,
        aad: Data? = nil
    ) -> DecryptionOptions {
        // Decryption options mirror encryption options
        // Determine the appropriate padding based on the algorithm and mode
        let effectivePadding: StandardPadding
        
        if let padding = padding {
            effectivePadding = padding
        } else if mode == .cbc {
            effectivePadding = .pkcs7
        } else {
            effectivePadding = .none
        }
        
        // Convert Data types to byte arrays
        let ivBytes: [UInt8] = [UInt8](iv)
        let aadBytes: [UInt8]? = aad.map { [UInt8]($0) }
        
        return DecryptionOptions(
            algorithm: algorithm.toCoreType,
            mode: mode.toCoreType,
            padding: effectivePadding.toCoreType,
            iv: ivBytes,
            additionalAuthenticatedData: aadBytes
        )
    }
    
    /**
     Creates standard hashing options.
     
     - Parameter algorithm: The hash algorithm to use
     - Returns: A new HashingOptions instance
     */
    public static func standardHashing(
        algorithm: StandardHashAlgorithm = .default
    ) -> CoreSecurityTypes.HashingOptions {
        return CoreSecurityTypes.HashingOptions(
            algorithm: algorithm.toCoreType
        )
    }
    
    /**
     Creates standard key generation options.
     
     - Parameters:
        - keyType: The type of key to generate
        - keySizeInBits: The key size in bits
        - isExtractable: Whether the key can be exported
        - useSecureEnclave: Whether to use secure hardware when available
     - Returns: A new KeyGenerationOptions instance
     */
    public static func standardKeyGeneration(
        keyType: KeyType = .aes,
        keySizeInBits: Int = 256,
        isExtractable: Bool = true,
        useSecureEnclave: Bool = false
    ) -> CoreSecurityTypes.KeyGenerationOptions {
        return CoreSecurityTypes.KeyGenerationOptions(
            keyType: keyType,
            keySizeInBits: keySizeInBits,
            isExtractable: isExtractable,
            useSecureEnclave: useSecureEnclave
        )
    }
}
