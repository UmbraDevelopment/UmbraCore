import CryptoInterfaces
import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import SecurityCoreInterfaces
import UmbraErrors

/**
 # LoggingCryptoServiceImpl

 A decorator implementation of CryptoServiceProtocol that adds logging capabilities.
 This implementation wraps another CryptoServiceProtocol implementation and logs
 all operations before delegating to the wrapped implementation.
 */
public actor LoggingCryptoServiceImpl: CryptoServiceProtocol {
  /// The wrapped implementation
  private let wrapped: CryptoServiceProtocol

  /// The logger to use
  private let logger: LoggingProtocol

  /**
   Initialises a new logging crypto service.

   - Parameters:
     - wrapped: The crypto service to wrap
     - logger: The logger to use
   */
  public init(
    wrapped: CryptoServiceProtocol,
    logger: LoggingProtocol
  ) {
    self.wrapped=wrapped
    self.logger=logger
  }

  public func encrypt(
    data: [UInt8],
    keyIdentifier: String,
    options: CryptoServiceOptions?=nil
  ) async -> Result<String, SecurityStorageError> {
    await logger.debug(
      "LoggingCryptoService: Encrypting data with key: \(keyIdentifier)",
      metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
      source: "LoggingCryptoService"
    )

    let result=await wrapped.encrypt(
      data: data,
      keyIdentifier: keyIdentifier,
      options: options
    )

    switch result {
      case let .success(identifier):
        await logger.debug(
          "LoggingCryptoService: Encryption successful, data stored with identifier: \(identifier)",
          metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
          source: "LoggingCryptoService"
        )
      case let .failure(error):
        await logger.error(
          "LoggingCryptoService: Encryption failed: \(error)",
          metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
          source: "LoggingCryptoService"
        )
    }

    return result
  }

  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options: CryptoServiceOptions?=nil
  ) async -> Result<[UInt8], SecurityStorageError> {
    await logger.debug(
      "LoggingCryptoService: Decrypting data with identifier: \(encryptedDataIdentifier) using key: \(keyIdentifier)",
      metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
      source: "LoggingCryptoService"
    )

    let result=await wrapped.decrypt(
      encryptedDataIdentifier: encryptedDataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )

    switch result {
      case .success:
        await logger.debug(
          "LoggingCryptoService: Decryption successful",
          metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
          source: "LoggingCryptoService"
        )
      case let .failure(error):
        await logger.error(
          "LoggingCryptoService: Decryption failed: \(error)",
          metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
          source: "LoggingCryptoService"
        )
    }

    return result
  }

  public func generateHash(
    data: [UInt8],
    algorithm: HashAlgorithm
  ) async -> Result<String, SecurityStorageError> {
    await logger.debug(
      "LoggingCryptoService: Generating hash with algorithm: \(algorithm)",
      metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
      source: "LoggingCryptoService"
    )

    let result=await wrapped.generateHash(
      data: data,
      algorithm: algorithm
    )

    switch result {
      case let .success(identifier):
        await logger.debug(
          "LoggingCryptoService: Hash generation successful, hash stored with identifier: \(identifier)",
          metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
          source: "LoggingCryptoService"
        )
      case let .failure(error):
        await logger.error(
          "LoggingCryptoService: Hash generation failed: \(error)",
          metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
          source: "LoggingCryptoService"
        )
    }

    return result
  }

  public func verifyHash(
    dataIdentifier: String,
    expectedHashIdentifier: String
  ) async -> Result<Bool, SecurityStorageError> {
    await logger.debug(
      "LoggingCryptoService: Verifying hash for data identifier: \(dataIdentifier)",
      metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
      source: "LoggingCryptoService"
    )

    let result=await wrapped.verifyHash(
      dataIdentifier: dataIdentifier,
      expectedHashIdentifier: expectedHashIdentifier
    )

    switch result {
      case let .success(matches):
        await logger.debug(
          "LoggingCryptoService: Hash verification result: \(matches)",
          metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
          source: "LoggingCryptoService"
        )
      case let .failure(error):
        await logger.error(
          "LoggingCryptoService: Hash verification failed: \(error)",
          metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
          source: "LoggingCryptoService"
        )
    }

    return result
  }

  public func generateKey(
    length: Int,
    options: KeyGenerationOptions?
  ) async -> Result<String, SecurityStorageError> {
    await logger.debug(
      "LoggingCryptoService: Generating key with length: \(length)",
      metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
      source: "LoggingCryptoService"
    )

    let result=await wrapped.generateKey(
      length: length,
      options: options
    )

    switch result {
      case let .success(identifier):
        await logger.debug(
          "LoggingCryptoService: Key generation successful, key stored with identifier: \(identifier)",
          metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
          source: "LoggingCryptoService"
        )
      case let .failure(error):
        await logger.error(
          "LoggingCryptoService: Key generation failed: \(error)",
          metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
          source: "LoggingCryptoService"
        )
    }

    return result
  }

  public func storeData(
    data: [UInt8],
    identifier: String
  ) async -> Result<Bool, SecurityStorageError> {
    await logger.debug(
      "LoggingCryptoService: Storing data with identifier: \(identifier)",
      metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
      source: "LoggingCryptoService"
    )

    let result=await wrapped.storeData(
      data: data,
      identifier: identifier
    )

    switch result {
      case .success:
        await logger.debug(
          "LoggingCryptoService: Data storage successful",
          metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
          source: "LoggingCryptoService"
        )
      case let .failure(error):
        await logger.error(
          "LoggingCryptoService: Data storage failed: \(error)",
          metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
          source: "LoggingCryptoService"
        )
    }

    return result
  }

  public func retrieveData(
    identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    await logger.debug(
      "LoggingCryptoService: Retrieving data with identifier: \(identifier)",
      metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
      source: "LoggingCryptoService"
    )

    let result=await wrapped.retrieveData(
      identifier: identifier
    )

    switch result {
      case .success:
        await logger.debug(
          "LoggingCryptoService: Data retrieval successful",
          metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
          source: "LoggingCryptoService"
        )
      case let .failure(error):
        await logger.error(
          "LoggingCryptoService: Data retrieval failed: \(error)",
          metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
          source: "LoggingCryptoService"
        )
    }

    return result
  }

  public func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    await logger.debug(
      "LoggingCryptoService: Exporting data with identifier: \(identifier)",
      metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
      source: "LoggingCryptoService"
    )

    let result=await wrapped.exportData(
      identifier: identifier
    )

    switch result {
      case .success:
        await logger.debug(
          "LoggingCryptoService: Data export successful",
          metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
          source: "LoggingCryptoService"
        )
      case let .failure(error):
        await logger.error(
          "LoggingCryptoService: Data export failed: \(error)",
          metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
          source: "LoggingCryptoService"
        )
    }

    return result
  }

  public func importData(
    data: [UInt8],
    identifier: String
  ) async -> Result<String, SecurityStorageError> {
    await logger.debug(
      "LoggingCryptoService: Importing data with identifier: \(identifier)",
      metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
      source: "LoggingCryptoService"
    )

    let result=await wrapped.importData(
      data: data,
      identifier: identifier
    )

    switch result {
      case let .success(identifier):
        await logger.debug(
          "LoggingCryptoService: Data import successful, stored with identifier: \(identifier)",
          metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
          source: "LoggingCryptoService"
        )
      case let .failure(error):
        await logger.error(
          "LoggingCryptoService: Data import failed: \(error)",
          metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
          source: "LoggingCryptoService"
        )
    }

    return result
  }

  public func deleteData(
    identifier: String
  ) async -> Result<Bool, SecurityStorageError> {
    await logger.debug(
      "LoggingCryptoService: Deleting data with identifier: \(identifier)",
      metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
      source: "LoggingCryptoService"
    )

    let result=await wrapped.deleteData(
      identifier: identifier
    )

    switch result {
      case .success:
        await logger.debug(
          "LoggingCryptoService: Data deletion successful",
          metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
          source: "LoggingCryptoService"
        )
      case let .failure(error):
        await logger.error(
          "LoggingCryptoService: Data deletion failed: \(error)",
          metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
          source: "LoggingCryptoService"
        )
    }

    return result
  }
}
