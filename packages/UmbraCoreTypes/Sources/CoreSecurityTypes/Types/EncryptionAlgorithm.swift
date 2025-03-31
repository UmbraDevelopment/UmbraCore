import Foundation

/**
 Defines the supported encryption algorithms in the security subsystem.

 This enumeration follows the architecture pattern for type-safe
 representation of domain concepts.
 */
public enum EncryptionAlgorithm: String, Sendable, Codable, Equatable, CaseIterable {
  /// Advanced Encryption Standard with 256-bit key, CBC mode
  case aes256CBC="AES-256-CBC"

  /// Advanced Encryption Standard with 256-bit key, GCM mode
  case aes256GCM="AES-256-GCM"

  /// ChaCha20 with Poly1305 for authenticated encryption
  case chacha20Poly1305="ChaCha20-Poly1305"

  /// Returns a human-readable description of the algorithm
  public var localizedDescription: String {
    switch self {
      case .aes256CBC:
        "AES-256 (CBC mode)"
      case .aes256GCM:
        "AES-256 (GCM mode)"
      case .chacha20Poly1305:
        "ChaCha20-Poly1305"
    }
  }

  /// Returns whether the algorithm supports authenticated encryption
  public var supportsAuthentication: Bool {
    switch self {
      case .aes256CBC:
        false
      case .aes256GCM, .chacha20Poly1305:
        true
    }
  }
}
