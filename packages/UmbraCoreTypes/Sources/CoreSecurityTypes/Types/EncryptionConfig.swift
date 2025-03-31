import Foundation

/**
 # EncryptionConfig
 
 Configuration settings for encryption operations in the Alpha Dot Five architecture.
 Provides a strongly-typed structure for encryption parameters to prevent misconfiguration.
 
 ## Usage
 ```swift
 let config = EncryptionConfig(
     algorithm: .aesGCM,
     keyIdentifier: keyId,
     additionalAuthenticatedData: contextData
 )
 ```
 */
public struct EncryptionConfig: Sendable, Equatable {
    /// The encryption algorithm to use
    public let algorithm: EncryptionAlgorithm
    
    /// The identifier of the key to use for encryption
    public let keyIdentifier: KeyIdentifier
    
    /// Additional authenticated data for authenticated encryption modes
    public let additionalAuthenticatedData: Data?
    
    /// Additional algorithm-specific options (using Sendable-compatible type)
    public let options: [String: String]
    
    /// Creates a new encryption configuration
    public init(
        algorithm: EncryptionAlgorithm,
        keyIdentifier: KeyIdentifier,
        additionalAuthenticatedData: Data? = nil,
        options: [String: String] = [:]
    ) {
        self.algorithm = algorithm
        self.keyIdentifier = keyIdentifier
        self.additionalAuthenticatedData = additionalAuthenticatedData
        self.options = options
    }
    
    /// Check equality by comparing all properties
    public static func == (lhs: EncryptionConfig, rhs: EncryptionConfig) -> Bool {
        lhs.algorithm == rhs.algorithm &&
        lhs.keyIdentifier == rhs.keyIdentifier &&
        lhs.additionalAuthenticatedData == rhs.additionalAuthenticatedData &&
        lhs.options == rhs.options
    }
}
