import CoreSecurityTypes
import CryptoInterfaces
import CryptoTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import SecurityInterfaces
import SecurityInterfacesDTOs
import SecurityInterfacesTypes
import UmbraErrors
import UmbraErrorsDTOs

/// Define a Crypto error domain for this service
enum CryptoError {
  static let domain="Crypto"

  enum ErrorCode: Int {
    case serviceUnavailable=1000
    case encryptionFailed=1001
    case decryptionFailed=1002
    case invalidParameters=1003
    case storageUnavailable=1004
    case storageFailed=1005
    case randomGenerationFailed=1006
    case hashingFailed=1007
    case notImplemented=1008
  }
}

/// An actor that provides cryptographic services through XPC
public actor CryptoXPCServiceActor {
  // MARK: - Private properties

  /// Security provider for cryptographic operations
  private let cryptoProvider: (any SecurityProviderProtocol)?

  /// Secure storage for persisting cryptographic materials
  private let secureStorage: (any SecureStorageProtocol)?

  /// Logger for the service
  private let logger: any LoggingProtocol

  /// The crypto service instance
  private var cryptoService: (any CryptoServiceProtocol)?

  /// The service monitor for tracking operation
  private let monitor: CryptoServiceMonitor

  // MARK: - Initialisation

  /// Creates a new CryptoXPCService actor
  /// - Parameters:
  ///   - cryptoProvider: The provider for cryptographic services
  ///   - secureStorage: The secure storage implementation
  ///   - logger: The logger to use
  public init(
    cryptoProvider: (any SecurityProviderProtocol)?,
    secureStorage: (any SecureStorageProtocol)?,
    logger: any LoggingProtocol
  ) {
    self.cryptoProvider=cryptoProvider
    self.secureStorage=secureStorage
    self.logger=logger
    monitor=CryptoServiceMonitor(logger: logger)
  }

  // MARK: - Private methods

  /// Gets a crypto service instance, creating one if needed
  /// - Returns: A crypto service or nil if unavailable
  private func getCryptoService() async -> (any CryptoServiceProtocol)? {
    // Return existing service if available
    if let cryptoService {
      return cryptoService
    }

    // Create a new service if we can
    guard let provider=cryptoProvider else {
      await logger.error(
        "Failed to get crypto service: No provider available",
        metadata: PrivacyMetadata(),
        source: "CryptoXPCServiceActor.getCryptoService"
      )
      return nil
    }

    // Get the service from the provider
    let service=await provider.cryptoService()
    cryptoService=service
    return service
  }

  // MARK: - Public API

  /// Encrypts data with the given options
  /// - Parameters:
  ///   - dataId: Identifier for the data to encrypt
  ///   - keyId: Identifier for the encryption key
  ///   - options: Options for the encryption operation
  /// - Returns: A result with the encrypted data ID or an error
  public func encrypt(
    dataID: String,
    keyID: String,
    options _: CryptoOperationOptionsDTO?
  ) async -> Result<String, UmbraErrorsDTOs.ErrorDTO> {
    await logger.trace(
      "Starting encrypt operation",
      metadata: PrivacyMetadata(),
      source: "CryptoXPCServiceActor.encrypt"
    )

    guard let cryptoService=await getCryptoService() else {
      let error=UmbraErrorsDTOs.ErrorDTO(
        identifier: "crypto.service.unavailable",
        domain: CryptoError.domain,
        description: "Crypto service unavailable",
        code: CryptoError.ErrorCode.serviceUnavailable.rawValue,
        contextData: ["operation": "encrypt"]
      )
      await logger.error(
        "Crypto service unavailable",
        metadata: PrivacyMetadata(),
        source: "CryptoXPCServiceActor.encrypt"
      )
      return .failure(error)
    }

    // Create the encryption options
    let encryptionOptions=EncryptionOptions(
      algorithm: .aes256GCM,
      authenticatedData: nil
    )

    // Perform the encryption
    let encryptResult=await cryptoService.encrypt(
      dataIdentifier: dataID,
      keyIdentifier: keyID,
      options: encryptionOptions
    )

    // Handle the result
    switch encryptResult {
      case let .success(encryptedDataID):
        await logger.debug(
          "Encryption successful",
          metadata: PrivacyMetadata(),
          source: "CryptoXPCServiceActor.encrypt"
        )
        return .success(encryptedDataID)

      case let .failure(error):
        let cryptoError=UmbraErrorsDTOs.ErrorDTO(
          identifier: "crypto.encryption.failed",
          domain: CryptoError.domain,
          description: "Failed to encrypt the data",
          code: CryptoError.ErrorCode.encryptionFailed.rawValue,
          contextData: ["underlyingError": String(describing: error)]
        )
        await logger.error(
          "Encryption failed",
          metadata: PrivacyMetadata(),
          source: "CryptoXPCServiceActor.encrypt"
        )
        return .failure(cryptoError)
    }
  }

  /// Decrypts data with the given options
  /// - Parameters:
  ///   - dataId: Identifier for the data to decrypt
  ///   - keyId: Identifier for the decryption key
  ///   - options: Options for the decryption operation
  /// - Returns: A result with the decrypted data ID or an error
  public func decrypt(
    dataID: String,
    keyID: String,
    options _: CryptoOperationOptionsDTO?
  ) async -> Result<String, UmbraErrorsDTOs.ErrorDTO> {
    await logger.trace(
      "Starting decrypt operation",
      metadata: PrivacyMetadata(),
      source: "CryptoXPCServiceActor.decrypt"
    )

    guard let cryptoService=await getCryptoService() else {
      let error=UmbraErrorsDTOs.ErrorDTO(
        identifier: "crypto.service.unavailable",
        domain: CryptoError.domain,
        description: "The cryptographic service is not available",
        code: CryptoError.ErrorCode.serviceUnavailable.rawValue,
        contextData: ["operation": "decrypt"]
      )
      await logger.error(
        "Crypto service unavailable",
        metadata: PrivacyMetadata(),
        source: "CryptoXPCServiceActor.decrypt"
      )
      return .failure(error)
    }

    // Create the decryption options
    let decryptionOptions=DecryptionOptions(
      algorithm: .aes256GCM,
      authenticatedData: nil
    )

    // Perform the decryption
    let decryptResult=await cryptoService.decrypt(
      encryptedDataIdentifier: dataID,
      keyIdentifier: keyID,
      options: decryptionOptions
    )

    // Handle the result
    switch decryptResult {
      case let .success(decryptedDataID):
        await logger.debug(
          "Decryption successful",
          metadata: PrivacyMetadata(),
          source: "CryptoXPCServiceActor.decrypt"
        )
        return .success(decryptedDataID)

      case let .failure(error):
        let cryptoError=UmbraErrorsDTOs.ErrorDTO(
          identifier: "crypto.decryption.failed",
          domain: CryptoError.domain,
          description: "Failed to decrypt the data",
          code: CryptoError.ErrorCode.decryptionFailed.rawValue,
          contextData: ["underlyingError": String(describing: error)]
        )
        await logger.error(
          "Decryption failed",
          metadata: PrivacyMetadata(),
          source: "CryptoXPCServiceActor.decrypt"
        )
        return .failure(cryptoError)
    }
  }

  /// Generates random bytes with the given length
  /// - Parameters:
  ///   - length: The number of random bytes to generate
  ///   - options: Options for the randomization operation
  /// - Returns: A result with the ID for the random data or an error
  public func generateRandomBytes(
    length: Int,
    options _: CoreSecurityTypes.RandomizationOptionsDTO?
  ) async -> Result<String, UmbraErrorsDTOs.ErrorDTO> {
    await logger.trace(
      "Starting generateRandomBytes operation",
      metadata: PrivacyMetadata(),
      source: "CryptoXPCServiceActor.generateRandomBytes"
    )

    // Validate input
    if length <= 0 {
      let error=UmbraErrorsDTOs.ErrorDTO(
        identifier: "crypto.random.invalid_length",
        domain: CryptoError.domain,
        description: "Length must be greater than zero",
        code: CryptoError.ErrorCode.invalidParameters.rawValue,
        contextData: ["length": String(length)]
      )
      await logger.error(
        "Invalid length for random bytes",
        metadata: PrivacyMetadata(),
        source: "CryptoXPCServiceActor.generateRandomBytes"
      )
      return .failure(error)
    }

    // Generate random bytes
    var randomBuffer=[UInt8](repeating: 0, count: length)
    let status=SecRandomCopyBytes(kSecRandomDefault, length, &randomBuffer)

    if status == 0 {
      // Successfully generated random bytes
      guard let cryptoService=await getCryptoService() else {
        let error=UmbraErrorsDTOs.ErrorDTO(
          identifier: "crypto.service.unavailable",
          domain: CryptoError.domain,
          description: "Crypto service unavailable",
          code: CryptoError.ErrorCode.serviceUnavailable.rawValue,
          contextData: ["operation": "generateRandomBytes"]
        )
        await logger.error(
          "Crypto service unavailable for storing random data",
          metadata: PrivacyMetadata(),
          source: "CryptoXPCServiceActor.generateRandomBytes"
        )
        return .failure(error)
      }

      // Store the random bytes using the crypto service
      let importResult=await cryptoService.importData(randomBuffer, customIdentifier: nil)

      // Process the result
      switch importResult {
        case let .success(dataID):
          await logger.debug(
            "Random data generation successful",
            metadata: PrivacyMetadata(),
            source: "CryptoXPCServiceActor.generateRandomBytes"
          )
          return .success(dataID)

        case let .failure(error):
          let cryptoError=UmbraErrorsDTOs.ErrorDTO(
            identifier: "crypto.random.storage_failed",
            domain: CryptoError.domain,
            description: "The random data was generated but could not be stored",
            code: CryptoError.ErrorCode.storageFailed.rawValue,
            contextData: ["underlyingError": String(describing: error)]
          )
          await logger.error(
            "Failed to store random data",
            metadata: PrivacyMetadata(),
            source: "CryptoXPCServiceActor.generateRandomBytes"
          )
          return .failure(cryptoError)
      }
    } else {
      let cryptoError=UmbraErrorsDTOs.ErrorDTO(
        identifier: "crypto.random.generation_failed",
        domain: CryptoError.domain,
        description: "The system crypto service failed to generate random bytes",
        code: CryptoError.ErrorCode.randomGenerationFailed.rawValue,
        contextData: ["status": String(status)]
      )
      await logger.error(
        "Random data generation failed",
        metadata: PrivacyMetadata(),
        source: "CryptoXPCServiceActor.generateRandomBytes"
      )
      return .failure(cryptoError)
    }
  }

  /// Computes a hash of the given data
  /// - Parameters:
  ///   - dataId: Identifier for the data to hash
  ///   - algorithm: The hash algorithm to use
  ///   - options: Options for the hash operation
  /// - Returns: A result with the ID for the hash result or an error
  public func hash(
    dataIdentifier: String,
    algorithm: CoreSecurityTypes.HashAlgorithm,
    options _: CryptoOperationOptionsDTO?
  ) async -> Result<String, UmbraErrorsDTOs.ErrorDTO> {
    await logger.trace(
      "Starting hash operation",
      metadata: PrivacyMetadata(),
      source: "CryptoXPCServiceActor.hash"
    )

    guard let cryptoService=await getCryptoService() else {
      let error=UmbraErrorsDTOs.ErrorDTO(
        identifier: "crypto.service.unavailable",
        domain: CryptoError.domain,
        description: "The cryptographic service is not available",
        code: CryptoError.ErrorCode.serviceUnavailable.rawValue,
        contextData: ["operation": "hash"]
      )
      await logger.error(
        "Crypto service unavailable",
        metadata: PrivacyMetadata(),
        source: "CryptoXPCServiceActor.hash"
      )
      return .failure(error)
    }

    // Create the options object
    let hashingOptions=HashingOptions(algorithm: algorithm)

    // Perform the hash operation
    let hashResult=await cryptoService.hash(
      dataIdentifier: dataIdentifier,
      options: hashingOptions
    )

    // Handle the result
    switch hashResult {
      case let .success(resultID):
        await logger.debug(
          "Hash operation successful",
          metadata: PrivacyMetadata(),
          source: "CryptoXPCServiceActor.hash"
        )
        return .success(resultID)

      case let .failure(error):
        let cryptoError=UmbraErrorsDTOs.ErrorDTO(
          identifier: "crypto.hash.failed",
          domain: CryptoError.domain,
          description: "Failed to hash the data",
          code: CryptoError.ErrorCode.hashingFailed.rawValue,
          contextData: ["underlyingError": String(describing: error)]
        )
        await logger.error(
          "Hash operation failed",
          metadata: PrivacyMetadata(),
          source: "CryptoXPCServiceActor.hash"
        )
        return .failure(cryptoError)
    }
  }

  /// Signs data with a given key
  /// - Parameters:
  ///   - dataId: The data to sign
  ///   - keyId: The key to use for signing
  ///   - metadata: Additional metadata for the signing operation
  /// - Returns: A result with the signature or an error
  public func sign(
    dataID _: String,
    keyID _: String,
    metadata _: Any?
  ) async -> Result<String, UmbraErrorsDTOs.ErrorDTO> {
    let error=UmbraErrorsDTOs.ErrorDTO(
      identifier: "crypto.operation.not_implemented",
      domain: CryptoError.domain,
      description: "This functionality is not yet implemented",
      code: CryptoError.ErrorCode.notImplemented.rawValue,
      contextData: ["operation": "sign"]
    )
    return .failure(error)
  }

  /// Verifies a signature against data
  /// - Parameters:
  ///   - signatureId: The signature to verify
  ///   - dataId: The data to verify against
  ///   - keyId: The key to use for verification
  ///   - metadata: Additional metadata for the verification operation
  /// - Returns: A result with a verification token or an error
  public func verify(
    signatureID _: String,
    dataID _: String,
    keyID _: String,
    metadata _: Any
  ) async -> Result<String, UmbraErrorsDTOs.ErrorDTO> {
    let error=UmbraErrorsDTOs.ErrorDTO(
      identifier: "crypto.operation.not_implemented",
      domain: CryptoError.domain,
      description: "This functionality is not yet implemented",
      code: CryptoError.ErrorCode.notImplemented.rawValue,
      contextData: ["operation": "verify"]
    )
    return .failure(error)
  }
}
