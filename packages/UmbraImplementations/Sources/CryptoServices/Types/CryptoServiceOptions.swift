import CoreSecurityTypes
import CryptoTypes
import DomainSecurityTypes
import Foundation

/**
 Options for configuring cryptographic services.
 */
public struct CryptoServiceOptions: Sendable {
  /// The encryption algorithm to use for operations
  public let algorithm: CoreSecurityTypes.EncryptionAlgorithm

  /// The hash algorithm to use for operations
  public let hashAlgorithm: CoreSecurityTypes.HashAlgorithm

  /// The key length in bytes
  public let keyLength: Int

  /// Additional parameters
  public let parameters: [String: CryptoParameter]?

  /// Creates a new instance with the specified options
  public init(
    algorithm: CoreSecurityTypes.EncryptionAlgorithm = .aes256GCM,
    hashAlgorithm: CoreSecurityTypes.HashAlgorithm = .sha256,
    keyLength: Int=32,
    parameters: [String: CryptoParameter]?=nil
  ) {
    self.algorithm=algorithm
    self.hashAlgorithm=hashAlgorithm
    self.keyLength=keyLength
    self.parameters=parameters
  }
}
