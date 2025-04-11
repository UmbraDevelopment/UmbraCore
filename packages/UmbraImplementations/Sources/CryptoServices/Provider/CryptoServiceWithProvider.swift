import CoreSecurityTypes
import CryptoInterfaces
import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import SecurityProviders

/**
 # CryptoServiceWithProvider

 Implementation of CryptoServiceProtocol that uses a SecurityProviderProtocol,
 following the command pattern architecture.

 This implementation delegates cryptographic operations to a security provider
 through a command-based architecture, which allows for different cryptographic
 backends to be used without changing the client code, while maintaining a clean,
 modular design with better separation of concerns.

 ## Provider Integration

 The implementation can work with various security provider types:
 - Platform providers (e.g., Apple CryptoKit)
 - Custom providers (e.g., Ring cryptography library via FFI)
 - Basic fallback providers

 ## Privacy Controls

 This implementation ensures proper privacy classification of sensitive information:
 - Cryptographic keys are treated as private information
 - Data identifiers are generally treated as public information
 - Error details are appropriately classified based on sensitivity
 - Metadata is structured for privacy-aware logging

 ## Thread Safety

 As an actor, this implementation guarantees thread safety when used from multiple
 concurrent contexts, preventing data races in cryptographic operations.
 */
public actor CryptoServiceWithProvider: CryptoServiceProtocol {
  /// The security provider to use for cryptographic operations
  private let provider: SecurityProviderProtocol

  /// The secure storage to use
  public let secureStorage: SecureStorageProtocol

  /// Optional logger for operation tracking
  private let logger: LoggingProtocol?

  /// Command factory for creating operation commands
  private let commandFactory: ProviderCommandFactory

  /**
   Initialises a new crypto service with a security provider.

   - Parameters:
      - secureStorage: The secure storage to use
      - providerType: The type of security provider to use
      - logger: Optional logger for recording operations
   */
  public init(
    secureStorage: SecureStorageProtocol,
    providerType: SecurityProviderType = .basic,
    logger: LoggingProtocol?=nil
  ) {
    // Create the appropriate provider based on the provider type
    let providerFactory=SecurityProviderFactory()
    provider=providerFactory.createProvider(ofType: providerType)

    self.secureStorage=secureStorage
    self.logger=logger

    // Create the command factory with the provider, storage, and logger
    commandFactory=ProviderCommandFactory(
      provider: provider,
      secureStorage: secureStorage,
      logger: logger
    )
  }

  /**
   Alternative initialiser with an explicit provider instance.

   - Parameters:
      - provider: The security provider to use
      - secureStorage: The secure storage to use
      - logger: Optional logger for recording operations
   */
  public init(
    provider: SecurityProviderProtocol,
    secureStorage: SecureStorageProtocol,
    logger: LoggingProtocol?=nil
  ) {
    self.provider=provider
    self.secureStorage=secureStorage
    self.logger=logger

    // Create the command factory with the provider, storage, and logger
    commandFactory=ProviderCommandFactory(
      provider: provider,
      secureStorage: secureStorage,
      logger: logger
    )
  }

  /**
   Encrypts data using the specified key.

   - Parameters:
      - data: The data to encrypt
      - keyIdentifier: Identifier for the encryption key
      - algorithm: The encryption algorithm to use
   - Returns: The encryption result
   */
  public func encrypt(
    data: [UInt8],
    keyIdentifier: String,
    algorithm: EncryptionAlgorithm = .aes256CBC
  ) async -> Result<[UInt8], SecurityStorageError> {
    let operationID=UUID().uuidString
    let logContext=CryptoLogContext(
      operation: "encrypt",
      algorithm: algorithm.rawValue,
      correlationID: operationID
    )

    // Create and execute the provider encrypt command
    let command=commandFactory.createProviderEncryptCommand(
      data: data,
      keyIdentifier: keyIdentifier,
      algorithm: algorithm
    )

    return await command.execute(context: logContext, operationID: operationID)
  }

  /**
   Decrypts data using the appropriate key.

   - Parameters:
      - data: The encrypted data to decrypt
      - keyIdentifier: Identifier for the decryption key
      - algorithm: The encryption algorithm used
   - Returns: The decryption result
   */
  public func decrypt(
    data: [UInt8],
    keyIdentifier: String,
    algorithm: EncryptionAlgorithm = .aes256CBC
  ) async -> Result<[UInt8], SecurityStorageError> {
    let operationID=UUID().uuidString
    let logContext=CryptoLogContext(
      operation: "decrypt",
      algorithm: algorithm.rawValue,
      correlationID: operationID
    )

    // Create and execute the provider decrypt command
    let command=commandFactory.createProviderDecryptCommand(
      data: data,
      keyIdentifier: keyIdentifier,
      algorithm: algorithm
    )

    return await command.execute(context: logContext, operationID: operationID)
  }

  /**
   Computes a cryptographic hash of the specified data.

   - Parameters:
      - data: The data to hash
      - algorithm: The hash algorithm to use
   - Returns: The hashing result
   */
  public func hash(
    data: [UInt8],
    algorithm: HashAlgorithm = .sha256
  ) async -> Result<[UInt8], SecurityStorageError> {
    let operationID=UUID().uuidString
    let logContext=CryptoLogContext(
      operation: "hash",
      algorithm: algorithm.rawValue,
      correlationID: operationID
    )

    // Create and execute the provider hash command
    let command=commandFactory.createProviderHashCommand(
      data: data,
      algorithm: algorithm
    )

    return await command.execute(context: logContext, operationID: operationID)
  }

  /**
   Verifies that a hash matches the expected value.

   - Parameters:
      - data: The data to verify
      - expectedHash: The expected hash value
      - algorithm: The hash algorithm to use
   - Returns: The verification result
   */
  public func verifyHash(
    data: [UInt8],
    expectedHash: [UInt8],
    algorithm: HashAlgorithm = .sha256
  ) async -> Result<Bool, SecurityStorageError> {
    let operationID=UUID().uuidString
    let logContext=CryptoLogContext(
      operation: "verifyHash",
      algorithm: algorithm.rawValue,
      correlationID: operationID
    )

    // Create and execute the provider verify hash command
    let command=commandFactory.createProviderVerifyHashCommand(
      data: data,
      expectedHash: expectedHash,
      algorithm: algorithm
    )

    return await command.execute(context: logContext, operationID: operationID)
  }

  /**
   Generates a cryptographic key.

   - Parameters:
      - type: The type of key to generate
      - size: Optional key size in bits
      - identifier: Optional predefined identifier for the key
   - Returns: The key generation result
   */
  public func generateKey(
    type: KeyType,
    size: Int?=nil,
    identifier: String?=nil
  ) async -> Result<CryptoKey, SecurityStorageError> {
    let operationID=UUID().uuidString
    let logContext=CryptoLogContext(
      operation: "generateKey",
      correlationID: operationID
    )

    // Create and execute the provider generate key command
    let command=commandFactory.createProviderGenerateKeyCommand(
      keyType: type,
      size: size,
      identifier: identifier
    )

    return await command.execute(context: logContext, operationID: operationID)
  }

  /**
   Derives a key from an existing key.

   - Parameters:
      - fromKey: Identifier of the source key
      - salt: Optional salt for key derivation
      - info: Optional context info for key derivation
      - keyType: The type of key to derive
      - targetIdentifier: Optional identifier for the derived key
   - Returns: The key derivation result
   */
  public func deriveKey(
    fromKey: String,
    salt: [UInt8]?,
    info: [UInt8]?,
    keyType: KeyType,
    targetIdentifier: String?
  ) async -> Result<CryptoKey, SecurityStorageError> {
    let operationID=UUID().uuidString
    let logContext=CryptoLogContext(
      operation: "deriveKey",
      correlationID: operationID
    )

    // Create and execute the provider derive key command
    let command=commandFactory.createProviderDeriveKeyCommand(
      sourceKeyIdentifier: fromKey,
      salt: salt,
      info: info,
      keyType: keyType,
      targetIdentifier: targetIdentifier
    )

    return await command.execute(context: logContext, operationID: operationID)
  }
}
