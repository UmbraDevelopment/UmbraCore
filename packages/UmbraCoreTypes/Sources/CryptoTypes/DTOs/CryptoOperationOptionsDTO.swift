/**
 # CryptoOperationOptionsDTO
 
 Configuration options for cryptographic operations.
 
 This DTO provides a Foundation-independent way to configure
 encryption, decryption, and other cryptographic operations.
 */
public struct CryptoOperationOptionsDTO: Sendable, Equatable {
    /// The encryption or decryption mode to use
    public let mode: CryptoMode
    
    /// Padding mode to use for the operation
    public let padding: PaddingMode
    
    /// Custom initialization vector if needed
    public let initializationVector: [UInt8]?
    
    /// Additional authenticated data for AEAD ciphers
    public let authenticatedData: [UInt8]?
    
    /// Create a new CryptoOperationOptionsDTO
    /// 
    /// - Parameters:
    ///   - mode: The encryption or decryption mode to use
    ///   - padding: Padding mode to use for the operation
    ///   - initializationVector: Custom initialization vector if needed
    ///   - authenticatedData: Additional authenticated data for AEAD ciphers
    public init(
        mode: CryptoMode,
        padding: PaddingMode,
        initializationVector: [UInt8]? = nil,
        authenticatedData: [UInt8]? = nil
    ) {
        self.mode = mode
        self.padding = padding
        self.initializationVector = initializationVector
        self.authenticatedData = authenticatedData
    }
    
    /// Creates standard options for GCM mode encryption
    public static func standardGCM() -> CryptoOperationOptionsDTO {
        CryptoOperationOptionsDTO(
            mode: .gcm,
            padding: .none
        )
    }
    
    /// Creates standard options for CBC mode encryption
    public static func standardCBC() -> CryptoOperationOptionsDTO {
        CryptoOperationOptionsDTO(
            mode: .cbc,
            padding: .pkcs7
        )
    }
}

/// Encryption/Decryption modes
public enum CryptoMode: String, Sendable, Equatable {
    case ecb // Electronic Codebook
    case cbc // Cipher Block Chaining
    case cfb // Cipher Feedback
    case ofb // Output Feedback
    case ctr // Counter
    case gcm // Galois/Counter Mode
    case ccm // Counter with CBC-MAC
}

/// Padding modes for encryption/decryption
public enum PaddingMode: String, Sendable, Equatable {
    case none
    case pkcs7
    case iso7816
    case zeroPadding
    case ansix923
}
