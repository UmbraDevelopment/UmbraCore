import Foundation

/**
 Data transfer object for security configuration settings.

 This DTO provides a standardised way to pass security configuration
 between components while maintaining type safety and actor isolation.
 */
public struct SecurityConfigDTO: Sendable, Equatable {
  /// Encryption algorithm to use
  public let encryptionAlgorithm: EncryptionAlgorithm

  /// Hash algorithm to use
  public let hashAlgorithm: HashAlgorithm

  /// Provider type to use for security operations
  public let providerType: SecurityProviderType

  /// Optional configuration options
  public let options: SecurityConfigOptions?

  /**
   Initialises a new security configuration.

   - Parameters:
     - encryptionAlgorithm: Encryption algorithm to use
     - hashAlgorithm: Hash algorithm to use
     - providerType: Provider type to use
     - options: Optional configuration options
   */
  public init(
    encryptionAlgorithm: EncryptionAlgorithm,
    hashAlgorithm: HashAlgorithm,
    providerType: SecurityProviderType,
    options: SecurityConfigOptions?=nil
  ) {
    self.encryptionAlgorithm=encryptionAlgorithm
    self.hashAlgorithm=hashAlgorithm
    self.providerType=providerType
    self.options=options
  }

  /// Creates a standard AES encryption configuration for the specified provider
  /// - Parameter providerType: The security provider type to use
  /// - Returns: A configuration with AES-256-CBC encryption and SHA-256 hashing
  public static func aesEncryption(providerType: SecurityProviderType) -> SecurityConfigDTO {
    SecurityConfigDTO(
      encryptionAlgorithm: .aes256CBC,
      hashAlgorithm: .sha256,
      providerType: providerType,
      options: nil
    )
  }
}
