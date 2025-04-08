import Foundation

/**
 * Options for decryption operations.
 *
 * This type encapsulates various parameters that can be used to
 * customize decryption operations.
 */
public struct DecryptionOptions: Sendable, Equatable {
  /// Algorithm to use for decryption
  public let algorithm: EncryptionAlgorithm

  /// Additional authenticated data for authenticated encryption modes
  public let authenticatedData: [UInt8]?

  /// Padding mode to use for block ciphers
  public let padding: PaddingMode?

  /**
   * Creates new decryption options.
   *
   * - Parameters:
   *   - algorithm: Algorithm to use for decryption
   *   - authenticatedData: Additional authenticated data for authenticated encryption modes
   *   - padding: Padding mode to use for block ciphers
   */
  public init(
    algorithm: EncryptionAlgorithm = .aes256CBC,
    authenticatedData: [UInt8]?=nil,
    padding: PaddingMode? = .pkcs7
  ) {
    self.algorithm=algorithm
    self.authenticatedData=authenticatedData
    self.padding=padding
  }

  /// Default options using AES-256-CBC with PKCS#7 padding
  public static let `default`=DecryptionOptions()

  /// Options for AES-256-GCM authenticated encryption
  public static let aesGCM=DecryptionOptions(algorithm: .aes256GCM)

  /// Options for ChaCha20-Poly1305 authenticated encryption
  public static let chaCha20=DecryptionOptions(algorithm: .chaCha20Poly1305)
}
