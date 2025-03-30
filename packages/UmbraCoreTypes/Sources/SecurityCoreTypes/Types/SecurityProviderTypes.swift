import Foundation
import SecurityTypes

/**
 # Encryption Configuration
 
 Represents configuration parameters for encryption operations.
 */
public typealias EncryptionConfig = SecurityConfigDTO

/**
 # Encryption Result
 
 Represents the result of an encryption or decryption operation.
 */
public struct EncryptionResult: Sendable {
    /// The resulting data (encrypted or decrypted)
    public let data: SecureBytes?
    
    /// Initialisation vector used (if applicable)
    public let iv: InitialisationVector?
    
    /// Authentication tag (if applicable)
    public let authTag: Data?
    
    /// Additional information about the operation
    public let info: [String: String]?
    
    /// Create a new encryption result
    public init(
        data: SecureBytes?,
        iv: InitialisationVector? = nil,
        authTag: Data? = nil,
        info: [String: String]? = nil
    ) {
        self.data = data
        self.iv = iv
        self.authTag = authTag
        self.info = info
    }
}
