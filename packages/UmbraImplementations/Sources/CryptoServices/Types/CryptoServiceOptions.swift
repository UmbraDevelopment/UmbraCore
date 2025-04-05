import CoreSecurityTypes
import CryptoTypes
import DomainSecurityTypes
import Foundation

/**
 Options for configuring cryptographic services.
 */
public struct CryptoServiceOptions: Sendable, Equatable {
  /// The encryption algorithm to use for operations
  public let algorithm: EncryptionAlgorithm

  /// The hash algorithm to use for operations
  public let hashAlgorithm: CoreSecurityTypes.HashAlgorithm

  /// The key length to use for key generation in bytes
  public let keyLength: Int

  /// Additional parameters for cryptographic operations
  public let parameters: [String: CryptoParameter]?

  /// Creates a new instance with the specified options
  public init(
    algorithm: EncryptionAlgorithm = .aes128GCM,
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
