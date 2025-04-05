import CryptoInterfaces
import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import SecurityCoreInterfaces
import UmbraErrors

/**
 A default implementation of CryptoServiceProtocol that delegates operations to a SecurityProviderProtocol.

 This class serves as a bridge between the CryptoServiceProtocol and SecurityProviderProtocol interfaces,
 enabling the use of any security provider that conforms to SecurityProviderProtocol with the
 CryptoServiceProtocol API.
 */
public actor DefaultCryptoServiceWithProviderImpl: CryptoServiceProtocol {
  private let provider: SecurityProviderProtocol
  private let secureStorage: SecureStorageProtocol
  private let logger: LoggingProtocol

  public init(
    provider: SecurityProviderProtocol,
    secureStorage: SecureStorageProtocol,
    logger: LoggingProtocol
  ) {
    self.provider=provider
    self.secureStorage=secureStorage
    self.logger=logger
  }

  public func encrypt(
    data: [UInt8],
    keyIdentifier: String,
    options _: CryptoServiceOptions?=nil
  ) async -> Result<String, SecurityStorageError> {
    // Log encrypt operation
    await logger.debug(
      "Encrypting data with key: \(keyIdentifier)",
      metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
      source: "CryptoServiceWithProvider"
    )

    // Prepare operation options
    let encryptionOptions=SecurityProviderOptions(
      algorithm: .aes256GCM,
      mode: .encrypt,
      keySize: 256
    )

    // Delegate to security provider
    let result=await provider.performOperation(
      .encryption,
      data: data,
      keyIdentifier: keyIdentifier,
      options: encryptionOptions
    )

    // Transform result to match expected return type
    switch result {
      case let .success(encryptedData):
        // Store the encrypted data securely
        let identifier="encrypted_\(UUID().uuidString)"

        let storeResult=await secureStorage.storeSecurely(
          data: encryptedData,
          identifier: identifier
        )

        switch storeResult {
          case .success:
            return .success(identifier)
          case let .failure(error):
            await logger.error(
              "Failed to store encrypted data: \(error)",
              metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
              source: "CryptoServiceWithProvider"
            )
            return .failure(.storageFailure(error))
        }

      case let .failure(error):
        await logger.error(
          "Encryption failed: \(error)",
          metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
          source: "CryptoServiceWithProvider"
        )
        return .failure(.operationFailed(error))
    }
  }

  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options _: CryptoServiceOptions?=nil
  ) async -> Result<[UInt8], SecurityStorageError> {
    // Retrieve the encrypted data from secure storage
    let dataResult=await exportData(identifier: encryptedDataIdentifier)
    guard case let .success(data)=dataResult else {
      if case let .failure(error)=dataResult {
        await logger.error(
          "Failed to retrieve encrypted data for decryption: \(error)",
          metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
          source: "CryptoServiceWithProvider"
        )
      }
      return .failure(.keyNotFound(encryptedDataIdentifier))
    }

    // Log decrypt operation
    await logger.debug(
      "Decrypting data using key: \(keyIdentifier)",
      metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
      source: "CryptoServiceWithProvider"
    )

    // Prepare operation options
    let decryptionOptions=SecurityProviderOptions(
      algorithm: .aes256GCM,
      mode: .decrypt,
      keySize: 256
    )

    // Delegate to security provider
    let result=await provider.performOperation(
      .decryption,
      data: data,
      keyIdentifier: keyIdentifier,
      options: decryptionOptions
    )

    // Transform result to match expected return type
    switch result {
      case let .success(decryptedData):
        return .success(decryptedData)
      case let .failure(error):
        await logger.error(
          "Decryption failed: \(error)",
          metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
          source: "CryptoServiceWithProvider"
        )
        return .failure(.operationFailed(error))
    }
  }

  public func generateHash(
    data: [UInt8],
    algorithm: HashAlgorithm
  ) async -> Result<String, SecurityStorageError> {
    // Log hash generation operation
    await logger.debug(
      "Generating hash with algorithm: \(algorithm)",
      metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
      source: "CryptoServiceWithProvider"
    )

    // Map hash algorithm to security provider algorithm
    let providerAlgorithm: HashingAlgorithm=switch algorithm {
      case .sha256:
        .sha256
      case .sha512:
        .sha512
    }

    // Prepare operation options
    let hashOptions=SecurityProviderOptions(
      hashAlgorithm: providerAlgorithm
    )

    // Delegate to security provider
    let result=await provider.performOperation(
      .hashing,
      data: data,
      options: hashOptions
    )

    // Transform result to match expected return type
    switch result {
      case let .success(hashedData):
        // Store the hash securely
        let identifier="hash_\(UUID().uuidString)"

        let storeResult=await secureStorage.storeSecurely(
          data: hashedData,
          identifier: identifier
        )

        switch storeResult {
          case .success:
            return .success(identifier)
          case let .failure(error):
            await logger.error(
              "Failed to store hash: \(error)",
              metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
              source: "CryptoServiceWithProvider"
            )
            return .failure(.storageFailure(error))
        }

      case let .failure(error):
        await logger.error(
          "Hash generation failed: \(error)",
          metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
          source: "CryptoServiceWithProvider"
        )
        return .failure(.operationFailed(error))
    }
  }

  public func verifyHash(
    dataIdentifier: String,
    expectedHashIdentifier: String
  ) async -> Result<Bool, SecurityStorageError> {
    // Get the data to verify
    let dataResult=await exportData(identifier: dataIdentifier)
    guard case let .success(data)=dataResult else {
      if case let .failure(error)=dataResult {
        await logger.error(
          "Failed to retrieve data for hash verification: \(error)",
          metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
          source: "CryptoServiceWithProvider"
        )
      }
      return .failure(.keyNotFound(dataIdentifier))
    }

    // Get the expected hash
    let hashResult=await exportData(identifier: expectedHashIdentifier)
    guard case let .success(expectedHash)=hashResult else {
      if case let .failure(error)=hashResult {
        await logger.error(
          "Failed to retrieve expected hash: \(error)",
          metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
          source: "CryptoServiceWithProvider"
        )
      }
      return .failure(.keyNotFound(expectedHashIdentifier))
    }

    // Log hash verification operation
    await logger.debug(
      "Verifying hash for data",
      metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
      source: "CryptoServiceWithProvider"
    )

    // Delegate to security provider
    let result=await provider.verifyHash(
      data: data,
      expectedHash: expectedHash
    )

    return result.map { $0 }.mapError { error in
      SecurityStorageError.operationFailed(error)
    }
  }

  public func generateKey(
    length: Int,
    options _: KeyGenerationOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Log key generation operation
    await logger.debug(
      "Generating key with length: \(length)",
      metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
      source: "CryptoServiceWithProvider"
    )

    // Prepare key generation options
    let keyOptions=SecurityProviderOptions(
      keySize: length * 8,
      algorithm: .aes256GCM
    )

    // Delegate to security provider
    let result=await provider.generateKey(
      options: keyOptions
    )

    // Transform result to match expected return type
    switch result {
      case let .success(keyIdentifier):
        return .success(keyIdentifier)
      case let .failure(error):
        await logger.error(
          "Key generation failed: \(error)",
          metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
          source: "CryptoServiceWithProvider"
        )
        return .failure(.operationFailed(error))
    }
  }

  public func storeData(
    data: [UInt8],
    identifier: String
  ) async -> Result<Bool, SecurityStorageError> {
    // Log data storage operation
    await logger.debug(
      "Storing data with identifier: \(identifier)",
      metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
      source: "CryptoServiceWithProvider"
    )

    // Delegate to secure storage
    let result=await secureStorage.storeSecurely(
      data: data,
      identifier: identifier
    )

    return result.map { _ in true }.mapError { error in
      SecurityStorageError.storageFailure(error)
    }
  }

  public func retrieveData(
    identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    // Log data retrieval operation
    await logger.debug(
      "Retrieving data with identifier: \(identifier)",
      metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
      source: "CryptoServiceWithProvider"
    )

    // Delegate to secure storage
    return await exportData(identifier: identifier)
  }

  public func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    // Log data export operation
    await logger.debug(
      "Exporting data with identifier: \(identifier)",
      metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
      source: "CryptoServiceWithProvider"
    )

    // Delegate to secure storage
    let result=await secureStorage.retrieveSecurely(
      identifier: identifier
    )

    return result.mapError { error in
      switch error {
        case .keyNotFound:
          .keyNotFound(identifier)
        default:
          .storageFailure(error)
      }
    }
  }

  public func importData(
    data: [UInt8],
    identifier: String
  ) async -> Result<String, SecurityStorageError> {
    // Log data import operation
    await logger.debug(
      "Importing data with identifier: \(identifier)",
      metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
      source: "CryptoServiceWithProvider"
    )

    // Delegate to secure storage
    let result=await secureStorage.storeSecurely(
      data: data,
      identifier: identifier
    )

    return result.map { _ in identifier }.mapError { error in
      SecurityStorageError.storageFailure(error)
    }
  }

  public func deleteData(
    identifier: String
  ) async -> Result<Bool, SecurityStorageError> {
    // Log data deletion operation
    await logger.debug(
      "Deleting data with identifier: \(identifier)",
      metadata: LogMetadataDTOCollection().toPrivacyMetadata(),
      source: "CryptoServiceWithProvider"
    )

    // Delegate to secure storage
    let result=await secureStorage.deleteSecurely(
      identifier: identifier
    )

    return result.map { _ in true }.mapError { error in
      switch error {
        case .keyNotFound:
          .keyNotFound(identifier)
        default:
          .storageFailure(error)
      }
    }
  }
}
