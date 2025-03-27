import Foundation

/// Encryption algorithm options
/// This is the consolidated enum that combines functionality from multiple previous definitions
public enum EncryptionAlgorithm: String, Codable, Sendable {
  /// AES-256 in GCM mode (authenticated encryption)
  case aes256Gcm = "AES-256-GCM"
  
  /// AES-256 in CBC mode with PKCS#7 padding
  case aes256Cbc = "AES-256-CBC"
  
  /// ChaCha20 with Poly1305 authentication
  case chacha20Poly1305 = "CHACHA20-POLY1305"
  
  /// XChaCha20 with Poly1305 authentication (extended nonce)
  case xchacha20Poly1305 = "XCHACHA20-POLY1305"
  
  /// RSA encryption
  case rsa = "RSA"
  
  /// The algorithm name suitable for display
  public var displayName: String {
    switch self {
      case .aes256Gcm:
        "AES-256 (GCM)"
      case .aes256Cbc:
        "AES-256 (CBC)"
      case .chacha20Poly1305:
        "ChaCha20-Poly1305"
      case .xchacha20Poly1305:
        "XChaCha20-Poly1305"
      case .rsa:
        "RSA"
    }
  }
}
