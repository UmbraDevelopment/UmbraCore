import CoreSecurityTypes
import CryptoInterfaces
import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces

/**
 Factory for creating provider-based cryptographic operation commands.

 This factory creates commands that delegate to a SecurityProviderProtocol
 implementation for cryptographic operations, following the command pattern
 to provide a clean, modular architecture with better separation of concerns.
 */
public class ProviderCommandFactory {
  /// The security provider to use for operations
  private let provider: SecurityProviderProtocol

  /// The secure storage to use
  private let secureStorage: SecureStorageProtocol

  /// Optional logger for operation tracking
  private let logger: LoggingProtocol?

  /**
   Initialises a new provider command factory.

   - Parameters:
      - provider: The security provider to use
      - secureStorage: The secure storage to use
      - logger: Optional logger for operation tracking
   */
  public init(
    provider: SecurityProviderProtocol,
    secureStorage: SecureStorageProtocol,
    logger: LoggingProtocol?=nil
  ) {
    self.provider=provider
    self.secureStorage=secureStorage
    self.logger=logger
  }

  /**
   Creates a command for encrypting data using the provider.

   - Parameters:
      - data: The data to encrypt
      - keyIdentifier: Identifier for the encryption key
      - algorithm: The encryption algorithm to use
   - Returns: A command for encrypting data
   */
  public func createProviderEncryptCommand(
    data: [UInt8],
    keyIdentifier: String,
    algorithm: EncryptionAlgorithm
  ) -> ProviderEncryptCommand {
    ProviderEncryptCommand(
      data: data,
      keyIdentifier: keyIdentifier,
      algorithm: algorithm,
      provider: provider,
      secureStorage: secureStorage,
      logger: logger
    )
  }

  /**
   Creates a command for decrypting data using the provider.

   - Parameters:
      - data: The encrypted data to decrypt
      - keyIdentifier: Identifier for the decryption key
      - algorithm: The encryption algorithm used
   - Returns: A command for decrypting data
   */
  public func createProviderDecryptCommand(
    data: [UInt8],
    keyIdentifier: String,
    algorithm: EncryptionAlgorithm
  ) -> ProviderDecryptCommand {
    ProviderDecryptCommand(
      data: data,
      keyIdentifier: keyIdentifier,
      algorithm: algorithm,
      provider: provider,
      secureStorage: secureStorage,
      logger: logger
    )
  }

  /**
   Creates a command for hashing data using the provider.

   - Parameters:
      - data: The data to hash
      - algorithm: The hash algorithm to use
   - Returns: A command for hashing data
   */
  public func createProviderHashCommand(
    data: [UInt8],
    algorithm: HashAlgorithm
  ) -> ProviderHashCommand {
    ProviderHashCommand(
      data: data,
      algorithm: algorithm,
      provider: provider,
      secureStorage: secureStorage,
      logger: logger
    )
  }

  /**
   Creates a command for verifying a hash using the provider.

   - Parameters:
      - data: The data to verify
      - expectedHash: The expected hash value
      - algorithm: The hash algorithm to use
   - Returns: A command for verifying a hash
   */
  public func createProviderVerifyHashCommand(
    data: [UInt8],
    expectedHash: [UInt8],
    algorithm: HashAlgorithm
  ) -> ProviderVerifyHashCommand {
    ProviderVerifyHashCommand(
      data: data,
      expectedHash: expectedHash,
      algorithm: algorithm,
      provider: provider,
      secureStorage: secureStorage,
      logger: logger
    )
  }

  /**
   Creates a command for generating a key using the provider.

   - Parameters:
      - keyType: The type of key to generate
      - size: Optional key size in bits
      - identifier: Optional predefined identifier for the key
   - Returns: A command for generating a key
   */
  public func createProviderGenerateKeyCommand(
    keyType: KeyType,
    size: Int?=nil,
    identifier: String?=nil
  ) -> ProviderGenerateKeyCommand {
    ProviderGenerateKeyCommand(
      keyType: keyType,
      size: size,
      identifier: identifier,
      provider: provider,
      secureStorage: secureStorage,
      logger: logger
    )
  }

  /**
   Creates a command for deriving a key using the provider.

   - Parameters:
      - sourceKeyIdentifier: Identifier of the source key
      - salt: Optional salt for key derivation
      - info: Optional context info for key derivation
      - keyType: The type of key to derive
      - targetIdentifier: Optional identifier for the derived key
   - Returns: A command for deriving a key
   */
  public func createProviderDeriveKeyCommand(
    sourceKeyIdentifier: String,
    salt: [UInt8]?,
    info: [UInt8]?,
    keyType: KeyType,
    targetIdentifier: String?
  ) -> ProviderDeriveKeyCommand {
    ProviderDeriveKeyCommand(
      sourceKeyIdentifier: sourceKeyIdentifier,
      salt: salt,
      info: info,
      keyType: keyType,
      targetIdentifier: targetIdentifier,
      provider: provider,
      secureStorage: secureStorage,
      logger: logger
    )
  }
}
