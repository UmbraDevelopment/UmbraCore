import Foundation
import CryptoTypes
import CoreSecurityTypes
import SecurityCoreInterfaces

/**
 # Crypto Service Types
 
 This file contains type definitions for the CryptoServices module.
 
 These types provide proper interfaces for cryptographic operations while
 maintaining compatibility with the Alpha Dot Five architecture.
 */

/**
 Options for cryptographic operations.
 
 Provides configuration parameters for encryption and decryption operations.
 */
public struct CryptoOptions: Sendable, Equatable {
    /// The algorithm to use for the operation
    public let algorithm: EncryptionAlgorithm
    
    /// Additional parameters for the operation
    public let parameters: [String: Any]?
    
    /// Initialises a new CryptoOptions instance
    /// - Parameters:
    ///   - algorithm: The encryption algorithm to use
    ///   - parameters: Additional parameters for the operation
    public init(
        algorithm: EncryptionAlgorithm = .aes256,
        parameters: [String: Any]? = nil
    ) {
        self.algorithm = algorithm
        self.parameters = parameters
    }
}

/**
 Options for key derivation operations.
 
 Configures how keys are derived from passwords or other key material.
 */
public struct KeyDerivationOptions: Sendable, Equatable {
    /// The algorithm to use for key derivation
    public let algorithm: KeyDerivationAlgorithm
    
    /// Number of iterations for the key derivation function
    public let iterations: Int
    
    /// Size of the derived key in bits
    public let outputKeySize: Int
    
    /// Initialises a new KeyDerivationOptions instance
    /// - Parameters:
    ///   - algorithm: The key derivation algorithm to use
    ///   - iterations: Number of iterations for the KDF
    ///   - outputKeySize: Size of the derived key in bits
    public init(
        algorithm: KeyDerivationAlgorithm = .pbkdf2,
        iterations: Int = 10000,
        outputKeySize: Int = 256
    ) {
        self.algorithm = algorithm
        self.iterations = iterations
        self.outputKeySize = outputKeySize
    }
    
    /// Key derivation algorithms supported by the crypto service
    public enum KeyDerivationAlgorithm: String, Sendable, Equatable {
        /// PBKDF2 (Password-Based Key Derivation Function 2)
        case pbkdf2
        /// Argon2
        case argon2
        /// scrypt
        case scrypt
    }
}

/**
 Options for HMAC operations.
 
 Configures the hash algorithm and other parameters for HMAC operations.
 */
public struct HMACOptions: Sendable, Equatable {
    /// The hash algorithm to use for the HMAC
    public let algorithm: HashAlgorithm
    
    /// Additional parameters for the HMAC operation
    public let parameters: [String: Any]?
    
    /// Initialises a new HMACOptions instance
    /// - Parameters:
    ///   - algorithm: The hash algorithm to use
    ///   - parameters: Additional parameters for the HMAC
    public init(
        algorithm: HashAlgorithm = .sha256,
        parameters: [String: Any]? = nil
    ) {
        self.algorithm = algorithm
        self.parameters = parameters
    }
}

/**
 Configuration for secure storage operations.
 
 Provides parameters for secure storage operations like storing, retrieving, 
 and deleting cryptographic keys and other sensitive data.
 */
public struct SecureStorageConfig: Sendable, Equatable {
    /// The access control level for the stored data
    public let accessControl: AccessControlLevel
    
    /// Whether to encrypt the data before storage
    public let encrypt: Bool
    
    /// Context information for the stored data
    public let context: [String: String]
    
    /// Initialises a new SecureStorageConfig instance
    /// - Parameters:
    ///   - accessControl: The access control level
    ///   - encrypt: Whether to encrypt the data
    ///   - context: Context information for the stored data
    public init(
        accessControl: AccessControlLevel = .standard,
        encrypt: Bool = true,
        context: [String: String] = [:]
    ) {
        self.accessControl = accessControl
        self.encrypt = encrypt
        self.context = context
    }
    
    /// Access control levels for secure storage
    public enum AccessControlLevel: String, Sendable, Equatable {
        /// Standard access control, requires application unlocked
        case standard
        /// Restricted access control, requires user authentication
        case restricted
        /// High security access control, requires biometric authentication or passcode
        case highSecurity
    }
}
