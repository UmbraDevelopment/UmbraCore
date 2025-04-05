import CoreSecurityTypes
import CryptoTypes
import Foundation

/**
 Options for configuring cryptographic key generation.
 
 These options control the algorithm, key size, and other parameters used for key generation.
 */
public struct KeyGenerationOptions: Sendable, Equatable {
    /// The key algorithm to use
    public let algorithm: KeyAlgorithm
    
    /// Whether the key should be exportable
    public let exportable: Bool
    
    /// Whether the key requires authentication for usage
    public let requiresAuthentication: Bool
    
    /**
     Purpose of cryptographic keys.
     
     This enum defines different purposes a cryptographic key can serve.
     */
    public enum KeyPurpose: String, Sendable, Equatable {
        /// Key used for encryption operations
        case encryption = "encryption"
        
        /// Key used for signing operations
        case signing = "signing"
        
        /// Key used for key exchange
        case keyExchange = "key_exchange"
        
        /// General purpose keys
        case generic = "generic"
    }
    
    /// Default initialiser
    /// - Parameters:
    ///   - algorithm: The key algorithm to use (defaults to AES)
    ///   - exportable: Whether the key should be exportable (defaults to false)
    ///   - requiresAuthentication: Whether the key requires authentication for usage (defaults to false)
    public init(
        algorithm: KeyAlgorithm = .aes,
        exportable: Bool = false,
        requiresAuthentication: Bool = false
    ) {
        self.algorithm = algorithm
        self.exportable = exportable
        self.requiresAuthentication = requiresAuthentication
    }
}
