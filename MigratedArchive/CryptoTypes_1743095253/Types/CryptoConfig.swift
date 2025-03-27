import Foundation

/// Configuration for cryptographic operations
public struct CryptoConfig: Sendable {
  /// Length of the encryption key in bits
  public let keyLength: Int
  /// Length of the initialization vector in bytes
  public let ivLength: Int

  /// Default configuration
  public static let `default`=CryptoConfig(keyLength: 256, ivLength: 16)

  /// Initialize a new crypto configuration
  /// - Parameters:
  ///   - keyLength: Length of the encryption key in bits
  ///   - ivLength: Length of the initialization vector in bytes
  public init(keyLength: Int, ivLength: Int) {
    self.keyLength=keyLength
    self.ivLength=ivLength
  }
}
