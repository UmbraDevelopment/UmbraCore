import CoreSecurityTypes
import CryptoTypes
import Foundation

/// Defines the algorithms available for encryption operations
public enum EncryptionAlgorithm: String, Sendable, Equatable, CaseIterable {
    /// AES 256-bit in CBC (Cipher Block Chaining) mode
    case aes256CBC = "aes256CBC"
    
    /// AES 256-bit in GCM (Galois/Counter Mode) for authenticated encryption
    case aes256GCM = "aes256GCM"
}

/**
 Options for configuring encryption operations.
 
 These options control the algorithm, mode, and additional parameters used for encryption.
 */
public struct EncryptionOptions: Sendable, Equatable {
    /// The encryption algorithm to use
    public let algorithm: EncryptionAlgorithm
    
    /// Optional authenticated data for authenticated encryption modes
    public let authenticatedData: [UInt8]?
    
    /// Optional padding mode to use
    public let padding: PaddingMode?
    
    /// Default initialiser
    /// - Parameters:
    ///   - algorithm: The encryption algorithm to use (defaults to AES-256-CBC)
    ///   - authenticatedData: Optional authenticated data for authenticated encryption modes
    ///   - padding: Optional padding mode to use
    public init(
        algorithm: EncryptionAlgorithm = .aes256CBC,
        authenticatedData: [UInt8]? = nil,
        padding: PaddingMode? = .pkcs7
    ) {
        self.algorithm = algorithm
        self.authenticatedData = authenticatedData
        self.padding = padding
    }
}
