import Foundation

/**
 Defines the supported security operation types.

 This enumeration follows the architecture pattern for type-safe
 representation of domain concepts.
 */
public enum SecurityOperation: String, Sendable, Codable, Equatable, CaseIterable {
  /// Encryption operation
  case encrypt

  /// Decryption operation
  case decrypt

  /// Hashing operation
  case hash

  /// Hash verification operation
  case verifyHash

  /// Signature generation operation
  case sign

  /// Signature verification operation
  case verify

  /// Key derivation operation
  case deriveKey

  /// Random generation operation
  case generateRandom

  /// Key storage operation
  case storeKey

  /// Key retrieval operation
  case retrieveKey

  /// Key deletion operation
  case deleteKey

  /// Returns a human-readable description of the operation
  public var localizedDescription: String {
    switch self {
      case .encrypt:
        "Encryption"
      case .decrypt:
        "Decryption"
      case .hash:
        "Hashing"
      case .verifyHash:
        "Hash Verification"
      case .sign:
        "Signature Generation"
      case .verify:
        "Signature Verification"
      case .deriveKey:
        "Key Derivation"
      case .generateRandom:
        "Random Generation"
      case .storeKey:
        "Key Storage"
      case .retrieveKey:
        "Key Retrieval"
      case .deleteKey:
        "Key Deletion"
    }
  }

  /// Returns whether the operation is potentially sensitive for logging
  public var isSensitiveOperation: Bool {
    switch self {
      case .encrypt, .decrypt, .deriveKey, .storeKey, .retrieveKey:
        true
      case .hash, .verifyHash, .sign, .verify, .generateRandom, .deleteKey:
        false
    }
  }
}
