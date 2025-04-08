import Foundation

/**
 * Hash algorithms supported by the system.
 *
 * This enum defines the various cryptographic hash algorithms
 * that can be used for hashing operations.
 */
public enum HashAlgorithm: String, Sendable, Equatable, CaseIterable {
  /// SHA-1 (not recommended for security-critical applications)
  case sha1

  /// SHA-256 (recommended for most applications)
  case sha256

  /// SHA-384
  case sha384

  /// SHA-512
  case sha512

  /// HMAC with SHA-256
  case hmacSHA256

  /// HMAC with SHA-512
  case hmacSHA512

  /// PBKDF2 key derivation function
  case pbkdf2

  /// Argon2id password hashing
  case argon2id

  /// Blake2b
  case blake2b

  /// Blake3
  case blake3

  /// Returns the digest length in bytes for this algorithm
  public var digestLength: Int {
    switch self {
      case .sha1:
        20
      case .sha256, .hmacSHA256:
        32
      case .sha384:
        48
      case .sha512, .hmacSHA512:
        64
      case .pbkdf2:
        32 // Default output size, typically configurable
      case .argon2id:
        32 // Default output size, typically configurable
      case .blake2b:
        64 // Default output size, typically configurable
      case .blake3:
        32 // Default output size, typically configurable
    }
  }

  /// Returns whether this algorithm is considered cryptographically secure
  public var isSecure: Bool {
    switch self {
      case .sha1:
        false // SHA-1 is no longer considered secure
      default:
        true
    }
  }
}
