import CoreSecurityTypes
import Foundation

/**
 # Parameter Standards
 
 This file defines standardised parameters, enumerations, and type aliases to ensure
 consistency across the UmbraCore cryptographic services. All implementations should
 adhere to these standards to maintain compatibility and predictability.
 
 ## Usage
 
 Use these types instead of string literals or ad-hoc type definitions to ensure
 consistent interfaces across all cryptographic modules.
 */

// MARK: - Encryption Algorithms

/**
 Standardised encryption algorithm identifiers.
 
 These values should be used consistently across all cryptographic services
 when referring to encryption algorithms. Avoid using string literals.
 */
public enum StandardEncryptionAlgorithm: String, Codable, Sendable, CaseIterable {
    /// AES-256 with Galois/Counter Mode
    case aes256GCM = "AES-256-GCM"
    
    /// AES-256 with Cipher Block Chaining Mode
    case aes256CBC = "AES-256-CBC"
    
    /// AES-128 with Galois/Counter Mode
    case aes128GCM = "AES-128-GCM"
    
    /// AES-128 with Cipher Block Chaining Mode
    case aes128CBC = "AES-128-CBC"
    
    /// ChaCha20 stream cipher with Poly1305 authenticator
    case chacha20Poly1305 = "ChaCha20-Poly1305"
    
    /// Default algorithm is AES-256-GCM
    public static var `default`: StandardEncryptionAlgorithm {
        return .aes256GCM
    }
    
    /// The key size in bytes required for this algorithm
    public var keySizeBytes: Int {
        switch self {
        case .aes256GCM, .aes256CBC, .chacha20Poly1305:
            return 32 // 256 bits = 32 bytes
        case .aes128GCM, .aes128CBC:
            return 16 // 128 bits = 16 bytes
        }
    }
    
    /// The initialization vector size in bytes required for this algorithm
    public var ivSizeBytes: Int {
        switch self {
        case .aes256GCM, .aes128GCM, .chacha20Poly1305:
            return 12 // 96 bits = 12 bytes (standard for GCM)
        case .aes256CBC, .aes128CBC:
            return 16 // 128 bits = 16 bytes (standard for CBC)
        }
    }
}

// MARK: - Hash Algorithms

/**
 Standardised hash algorithm identifiers.
 
 These values should be used consistently across all cryptographic services
 when referring to hash algorithms. Avoid using string literals.
 */
public enum StandardHashAlgorithm: String, Codable, Sendable, CaseIterable {
    /// SHA-256 hash function (32 bytes output)
    case sha256 = "SHA-256"
    
    /// SHA-384 hash function (48 bytes output)
    case sha384 = "SHA-384"
    
    /// SHA-512 hash function (64 bytes output)
    case sha512 = "SHA-512"
    
    /// HMAC-SHA-256 (keyed hash)
    case hmacSHA256 = "HMAC-SHA-256"
    
    /// Default hash algorithm is SHA-256
    public static var `default`: StandardHashAlgorithm {
        return .sha256
    }
    
    /// The output size in bytes for this hash algorithm
    public var outputSizeBytes: Int {
        switch self {
        case .sha256, .hmacSHA256:
            return 32 // 256 bits = 32 bytes
        case .sha384:
            return 48 // 384 bits = 48 bytes
        case .sha512:
            return 64 // 512 bits = 64 bytes
        }
    }
}

// MARK: - Encryption Modes

/**
 Standardised encryption mode identifiers.
 
 These values should be used consistently across all cryptographic services
 when referring to encryption modes. Avoid using string literals.
 */
public enum StandardEncryptionMode: String, Codable, Sendable, CaseIterable {
    /// Galois/Counter Mode (authenticated encryption)
    case gcm = "GCM"
    
    /// Cipher Block Chaining Mode
    case cbc = "CBC"
    
    /// Counter Mode
    case ctr = "CTR"
    
    /// Default mode is GCM (authenticated encryption)
    public static var `default`: StandardEncryptionMode {
        return .gcm
    }
    
    /// Whether this mode provides authentication
    public var providesAuthentication: Bool {
        switch self {
        case .gcm:
            return true
        case .cbc, .ctr:
            return false
        }
    }
}

// MARK: - Padding Types

/**
 Standardised padding type identifiers.
 
 These values should be used consistently across all cryptographic services
 when referring to padding types. Avoid using string literals.
 */
public enum StandardPaddingType: String, Codable, Sendable, CaseIterable {
    /// No padding (for modes that don't require it, like GCM)
    case none = "NoPadding"
    
    /// PKCS#7 padding (standard for CBC mode)
    case pkcs7 = "PKCS7Padding"
    
    /// Default padding is None
    public static var `default`: StandardPaddingType {
        return .none
    }
    
    /// Get the appropriate padding for an encryption mode
    public static func forMode(_ mode: StandardEncryptionMode) -> StandardPaddingType {
        switch mode {
        case .gcm, .ctr:
            return .none
        case .cbc:
            return .pkcs7
        }
    }
}

// MARK: - Key Usage

/**
 Standardised key usage identifiers.
 
 These values should be used consistently across all cryptographic services
 when referring to key usage. Avoid using string literals.
 */
public enum StandardKeyUsage: String, Codable, Sendable, CaseIterable {
    /// Key used for encryption operations
    case encryption = "encryption"
    
    /// Key used for signing operations
    case signing = "signing"
    
    /// Key used as a master key
    case master = "master"
    
    /// Key used for key derivation
    case derivation = "derivation"
    
    /// Default usage is encryption
    public static var `default`: StandardKeyUsage {
        return .encryption
    }
}

// MARK: - Helper Extensions

/// Extension to EncryptionOptions to provide conversion from standardised parameters
extension EncryptionOptions {
    /**
     Creates a new EncryptionOptions with standardised parameters.
     
     - Parameters:
        - algorithm: Standard encryption algorithm
        - mode: Standard encryption mode
        - padding: Standard padding type
        - iv: Initialisation vector
        - aad: Additional authenticated data
     - Returns: A new EncryptionOptions instance
     */
    public static func standard(
        algorithm: StandardEncryptionAlgorithm = .default,
        mode: StandardEncryptionMode = .default,
        padding: StandardPaddingType? = nil,
        iv: Data,
        aad: Data? = nil
    ) -> EncryptionOptions {
        // Use appropriate padding for the mode if not specified
        let effectivePadding = padding ?? StandardPaddingType.forMode(mode)
        
        return EncryptionOptions(
            algorithm: algorithm.rawValue,
            mode: mode.rawValue,
            padding: effectivePadding.rawValue,
            iv: iv,
            aad: aad
        )
    }
}

/// Extension to DecryptionOptions to provide conversion from standardised parameters
extension DecryptionOptions {
    /**
     Creates a new DecryptionOptions with standardised parameters.
     
     - Parameters:
        - algorithm: Standard encryption algorithm
        - mode: Standard encryption mode
        - padding: Standard padding type
        - iv: Initialisation vector
        - aad: Additional authenticated data
     - Returns: A new DecryptionOptions instance
     */
    public static func standard(
        algorithm: StandardEncryptionAlgorithm = .default,
        mode: StandardEncryptionMode = .default,
        padding: StandardPaddingType? = nil,
        iv: Data,
        aad: Data? = nil
    ) -> DecryptionOptions {
        // Use appropriate padding for the mode if not specified
        let effectivePadding = padding ?? StandardPaddingType.forMode(mode)
        
        return DecryptionOptions(
            algorithm: algorithm.rawValue,
            mode: mode.rawValue,
            padding: effectivePadding.rawValue,
            iv: iv,
            aad: aad
        )
    }
}

/// Extension to HashingOptions to provide conversion from standardised parameters
extension HashingOptions {
    /**
     Creates a new HashingOptions with a standardised algorithm.
     
     - Parameters:
        - algorithm: Standard hash algorithm
        - metadata: Additional metadata
     - Returns: A new HashingOptions instance
     */
    public static func standard(
        algorithm: StandardHashAlgorithm = .default,
        metadata: [String: String]? = nil
    ) -> HashingOptions {
        return HashingOptions(
            algorithm: algorithm.rawValue,
            metadata: metadata
        )
    }
}

/// Extension to KeyGenerationOptions to provide conversion from standardised parameters
extension KeyGenerationOptions {
    /**
     Creates a new KeyGenerationOptions with standardised parameters.
     
     - Parameters:
        - algorithm: Standard encryption algorithm
        - keyUsage: Standard key usage
        - metadata: Additional metadata
     - Returns: A new KeyGenerationOptions instance
     */
    public static func standard(
        algorithm: StandardEncryptionAlgorithm = .default,
        keyUsage: StandardKeyUsage = .default,
        metadata: [String: String]? = nil
    ) -> KeyGenerationOptions {
        return KeyGenerationOptions(
            algorithm: algorithm.rawValue,
            keyUsage: keyUsage.rawValue,
            metadata: metadata
        )
    }
}
