import Foundation

/// Configuration for cryptographic operations
@frozen
public struct CryptoConfiguration: Sendable {
  /// Key length in bits (256 for AES-256)
  public let keyLength: Int
  /// IV length in bytes (12 for GCM mode)
  public let ivLength: Int
  /// Salt length in bytes
  public let saltLength: Int
  /// Minimum number of iterations for PBKDF2
  public let minimumPBKDF2Iterations: Int

  public init(
    keyLength: Int = 256,
    ivLength: Int = 12,
    saltLength: Int = 32,
    minimumPBKDF2Iterations: Int = 10_000
  ) {
    self.keyLength = keyLength
    self.ivLength = ivLength
    self.saltLength = saltLength
    self.minimumPBKDF2Iterations = minimumPBKDF2Iterations
  }

  /// Default configuration
  public static let `default` = CryptoConfiguration()
}
