import Foundation

/// Represents encryption algorithms supported by the security modules
public enum EncryptionAlgorithm: String, Sendable, Equatable, CaseIterable {
  // MARK: - Symmetric Algorithms
  
  /// AES-256 in GCM mode (Authenticated Encryption with Associated Data)
  case aes256Gcm = "AES-256-GCM"
  
  /// AES-256 in CBC mode with PKCS7 padding
  case aes256Cbc = "AES-256-CBC"
  
  /// ChaCha20-Poly1305 authenticated encryption
  case chaCha20Poly1305 = "CHACHA20-POLY1305"
  
  // MARK: - Asymmetric Algorithms
  
  /// RSA encryption with OAEP padding
  case rsaOaep = "RSA-OAEP"
  
  /// RSA encryption with PKCS1 padding
  case rsaPkcs1 = "RSA-PKCS1"
  
  /// Elliptic Curve Diffie-Hellman with Curve25519
  case ecdhCurve25519 = "ECDH-Curve25519"
  
  // MARK: - Properties
  
  /// Whether the algorithm is symmetric
  public var isSymmetric: Bool {
    switch self {
      case .aes256Gcm, .aes256Cbc, .chaCha20Poly1305:
        return true
      case .rsaOaep, .rsaPkcs1, .ecdhCurve25519:
        return false
    }
  }
  
  /// Whether the algorithm provides authentication
  public var isAuthenticated: Bool {
    switch self {
      case .aes256Gcm, .chaCha20Poly1305:
        return true
      case .aes256Cbc, .rsaOaep, .rsaPkcs1, .ecdhCurve25519:
        return false
    }
  }
  
  /// Default key size in bits for this algorithm
  public var defaultKeySizeBits: Int {
    switch self {
      case .aes256Gcm, .aes256Cbc:
        return 256
      case .chaCha20Poly1305:
        return 256
      case .rsaOaep, .rsaPkcs1:
        return 2048
      case .ecdhCurve25519:
        return 256
    }
  }
  
  /// Whether the algorithm requires an initialisation vector (IV)
  public var requiresIV: Bool {
    switch self {
      case .aes256Gcm, .aes256Cbc:
        return true
      case .chaCha20Poly1305:
        return true
      case .rsaOaep, .rsaPkcs1, .ecdhCurve25519:
        return false
    }
  }
  
  /// Initialise from a string
  /// - Parameter string: String representation of the algorithm
  /// - Returns: The corresponding EncryptionAlgorithm, or nil if not recognised
  public init?(from string: String) {
    if let algorithm = EncryptionAlgorithm(rawValue: string) {
      self = algorithm
      return
    }
    
    // Handle legacy identifiers
    let normalised = string.uppercased()
    switch normalised {
      case "AES256GCM", "AES-GCM":
        self = .aes256Gcm
      case "AES256CBC", "AES-CBC":
        self = .aes256Cbc
      case "CHACHA20POLY1305", "CHACHA20":
        self = .chaCha20Poly1305
      case "RSA-OAEP-SHA256", "RSA-OAEP-SHA1":
        self = .rsaOaep
      case "RSA-PKCS1-V1.5", "RSA-PKCS1":
        self = .rsaPkcs1
      case "X25519", "CURVE25519":
        self = .ecdhCurve25519
      default:
        return nil
    }
  }
}
