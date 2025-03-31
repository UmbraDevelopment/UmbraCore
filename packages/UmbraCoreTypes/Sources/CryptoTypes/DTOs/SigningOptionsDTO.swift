/**
 # SigningOptionsDTO
 
 Configuration options for cryptographic signing operations.
 
 This DTO provides a Foundation-independent way to configure
 digital signature creation and verification operations.
 */
public struct SigningOptionsDTO: Sendable, Equatable {
    /// The signing algorithm to use
    public let algorithm: SigningAlgorithm
    
    /// Hash algorithm to use before signing
    public let hashAlgorithm: HashAlgorithm
    
    /// Salt length for PSS padding modes
    public let saltLength: Int?
    
    /// Additional authenticated data
    public let authenticatedData: [UInt8]?
    
    /// Create a new SigningOptionsDTO
    /// 
    /// - Parameters:
    ///   - algorithm: The signing algorithm to use
    ///   - hashAlgorithm: Hash algorithm to use before signing
    ///   - saltLength: Salt length for PSS padding modes
    ///   - authenticatedData: Additional authenticated data
    public init(
        algorithm: SigningAlgorithm,
        hashAlgorithm: HashAlgorithm,
        saltLength: Int? = nil,
        authenticatedData: [UInt8]? = nil
    ) {
        self.algorithm = algorithm
        self.hashAlgorithm = hashAlgorithm
        self.saltLength = saltLength
        self.authenticatedData = authenticatedData
    }
    
    /// Creates standard options for RSA-PSS signing
    public static func standardRSA() -> SigningOptionsDTO {
        SigningOptionsDTO(
            algorithm: .rsaPSS,
            hashAlgorithm: .sha256,
            saltLength: 32
        )
    }
    
    /// Creates standard options for ECDSA signing
    public static func standardECDSA() -> SigningOptionsDTO {
        SigningOptionsDTO(
            algorithm: .ecdsa,
            hashAlgorithm: .sha256
        )
    }
}

/// Digital signature algorithms
public enum SigningAlgorithm: String, Sendable, Equatable {
    case rsaPKCS1   // PKCS#1 v1.5 padding
    case rsaPSS     // Probabilistic Signature Scheme
    case ecdsa      // Elliptic Curve Digital Signature Algorithm
    case hmac       // Hash-based Message Authentication Code
    case ed25519    // Edwards-curve Digital Signature Algorithm
}

/// Hash algorithms for cryptographic operations
public enum HashAlgorithm: String, Sendable, Equatable {
    case md5        // Not recommended for security applications
    case sha1       // Not recommended for security applications
    case sha224
    case sha256
    case sha384
    case sha512
    case blake2b
    case blake2s
}
