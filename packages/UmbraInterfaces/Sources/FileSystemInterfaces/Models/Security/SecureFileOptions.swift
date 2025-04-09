import Foundation

/**
 # Secure File Options
 
 Options for secure file operations including encryption and integrity settings.
 
 This struct provides configuration options for secure file operations
 to ensure data integrity and security during file operations.
 
 ## Alpha Dot Five Architecture
 
 This type follows the Alpha Dot Five architecture principles:
 - Uses immutable structs for thread safety
 - Implements Sendable for safe concurrent access
 - Provides clear, well-documented properties
 - Uses British spelling in documentation
 */
public struct SecureFileOptions: Sendable, Equatable {
    /// Whether to encrypt the data during write operations
    public let encryptData: Bool
    
    /// The encryption key to use (if encryptData is true)
    public let encryptionKey: Data?
    
    /// Whether to verify file integrity after write operations
    public let verifyIntegrity: Bool
    
    /// The checksum algorithm to use for integrity verification
    public let checksumAlgorithm: ChecksumAlgorithm?
    
    /**
     Creates a new set of secure file options.
     
     - Parameters:
        - encryptData: Whether to encrypt the data
        - encryptionKey: Optional encryption key
        - verifyIntegrity: Whether to verify file integrity
        - checksumAlgorithm: Optional checksum algorithm for integrity verification
     */
    public init(
        encryptData: Bool = false,
        encryptionKey: Data? = nil,
        verifyIntegrity: Bool = false,
        checksumAlgorithm: ChecksumAlgorithm? = nil
    ) {
        self.encryptData = encryptData
        self.encryptionKey = encryptionKey
        self.verifyIntegrity = verifyIntegrity
        self.checksumAlgorithm = checksumAlgorithm
    }
    
    /// Default options (no encryption, no integrity verification)
    public static let `default` = SecureFileOptions()
    
    /// Options for maximum security (encryption and integrity verification)
    public static let maximumSecurity = SecureFileOptions(
        encryptData: true,
        verifyIntegrity: true,
        checksumAlgorithm: .sha256
    )
    
    /// Options for integrity verification only
    public static let integrityVerification = SecureFileOptions(
        encryptData: false,
        verifyIntegrity: true,
        checksumAlgorithm: .sha256
    )
}
