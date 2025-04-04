import CoreSecurityTypes
import CryptoTypes
import Foundation

/**
 Options for configuring decryption operations.
 
 These options control the algorithm, mode, and additional parameters used for decryption.
 */
public struct DecryptionOptions: Sendable, Equatable {
    /// The encryption algorithm to use
    public let algorithm: EncryptionAlgorithm
    
    /// Optional authenticated data for authenticated encryption modes
    public let authenticatedData: [UInt8]?
    
    /// Optional padding mode to use
    public let padding: PaddingMode?
    
    /// Default initialiser
    /// - Parameters:
    ///   - algorithm: The encryption algorithm to use (defaults to AES-256-CBC)
    ///   - authenticatedData: Optional authenticated data for authenticated decryption modes
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
