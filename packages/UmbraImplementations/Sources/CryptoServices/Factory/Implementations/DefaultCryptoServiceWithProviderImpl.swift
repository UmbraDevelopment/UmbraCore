import CryptoInterfaces
import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
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
    self.provider = provider
    self.secureStorage = secureStorage
    self.logger = logger
  }

  public func encrypt(
    data: [UInt8],
    keyIdentifier: String,
    options _: CryptoServiceOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    // Log encrypt operation
    await logger.debug(
      "Encrypting data with key: \(keyIdentifier)",
      context: CryptoLogContext(
        operation: "encrypt",
        additionalContext: LogMetadataDTOCollection()
          .withPrivate(key: "keyIdentifier", value: keyIdentifier)
          .withPublic(key: "dataSize", value: "\(data.count)")
      )
    )

    // Prepare operation options
    let encryptionOptions = SecurityProviderOptions(
      algorithm: .aes256GCM,
      mode: .encrypt,
      keySize: 256
    )

    // Delegate to security provider
    let result = await provider.performOperation(
      .encryption,
      data: data,
      keyIdentifier: keyIdentifier,
      options: encryptionOptions
    )

    // Transform result to match expected return type
    switch result {
      case let .success(encryptedData):
        // Store the encrypted data securely
        let identifier = "encrypted_\(UUID().uuidString)"

        let storeResult = await secureStorage.storeData(
          encryptedData,
          withIdentifier: identifier
        )

        switch storeResult {
          case .success:
            return .success(identifier)
          case let .failure(error):
            await logger.error(
              "Failed to store encrypted data: \(error)",
              context: CryptoLogContext(
                operation: "encrypt",
                additionalContext: LogMetadataDTOCollection()
                  .withPrivate(key: "keyIdentifier", value: keyIdentifier)
                  .withPublic(key: "dataSize", value: "\(data.count)")
              )
            )
            return .failure(.storageFailure(error))
        }

      case let .failure(error):
        await logger.error(
          "Encryption failed: \(error)",
          context: CryptoLogContext(
            operation: "encrypt",
            additionalContext: LogMetadataDTOCollection()
              .withPrivate(key: "keyIdentifier", value: keyIdentifier)
              .withPublic(key: "dataSize", value: "\(data.count)")
          )
        )
        return .failure(.operationFailed(error))
    }
  }

  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options _: CryptoServiceOptions? = nil
  ) async -> Result<[UInt8], SecurityStorageError> {
    // Retrieve the encrypted data from secure storage
    let dataResult = await exportData(identifier: encryptedDataIdentifier)
    guard case let .success(data) = dataResult else {
      if case let .failure(error) = dataResult {
        await logger.error(
          "Failed to retrieve encrypted data for decryption: \(error)",
          context: CryptoLogContext(
            operation: "decrypt",
            additionalContext: LogMetadataDTOCollection()
              .withPrivate(key: "keyIdentifier", value: keyIdentifier)
              .withPublic(key: "dataSize", value: "\(encryptedDataIdentifier.count)")
          )
        )
      }
      return .failure(.keyNotFound(encryptedDataIdentifier))
    }

    // Log decrypt operation
    await logger.debug(
      "Decrypting data using key: \(keyIdentifier)",
      context: CryptoLogContext(
        operation: "decrypt",
        additionalContext: LogMetadataDTOCollection()
          .withPrivate(key: "keyIdentifier", value: keyIdentifier)
          .withPublic(key: "dataSize", value: "\(data.count)")
      )
    )

    // Prepare operation options
    let decryptionOptions = SecurityProviderOptions(
      algorithm: .aes256GCM,
      mode: .decrypt,
      keySize: 256
    )

    // Delegate to security provider
    let result = await provider.performOperation(
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
          context: CryptoLogContext(
            operation: "decrypt",
            additionalContext: LogMetadataDTOCollection()
              .withPrivate(key: "keyIdentifier", value: keyIdentifier)
              .withPublic(key: "dataSize", value: "\(data.count)")
          )
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
      context: CryptoLogContext(
        operation: "generateHash",
        additionalContext: LogMetadataDTOCollection()
          .withPublic(key: "algorithm", value: "\(algorithm)")
          .withPublic(key: "dataSize", value: "\(data.count)")
      )
    )

    // Map hash algorithm to security provider algorithm
    let providerAlgorithm: HashingAlgorithm = switch algorithm {
      case .sha256:
        .sha256
      case .sha512:
        .sha512
    }

    // Prepare operation options
    let hashOptions = SecurityProviderOptions(
      hashAlgorithm: providerAlgorithm
    )

    // Delegate to security provider
    let result = await provider.performOperation(
      .hashing,
      data: data,
      options: hashOptions
    )

    // Transform result to match expected return type
    switch result {
      case let .success(hashedData):
        // Store the hash securely
        let identifier = "hash_\(UUID().uuidString)"

        let storeResult = await secureStorage.storeData(
          hashedData,
          withIdentifier: identifier
        )

        switch storeResult {
          case .success:
            return .success(identifier)
          case let .failure(error):
            await logger.error(
              "Failed to store hash: \(error)",
              context: CryptoLogContext(
                operation: "generateHash",
                additionalContext: LogMetadataDTOCollection()
                  .withPublic(key: "algorithm", value: "\(algorithm)")
                  .withPublic(key: "dataSize", value: "\(data.count)")
              )
            )
            return .failure(.storageFailure(error))
        }

      case let .failure(error):
        await logger.error(
          "Hash generation failed: \(error)",
          context: CryptoLogContext(
            operation: "generateHash",
            additionalContext: LogMetadataDTOCollection()
              .withPublic(key: "algorithm", value: "\(algorithm)")
              .withPublic(key: "dataSize", value: "\(data.count)")
          )
        )
        return .failure(.operationFailed(error))
    }
  }

  public func verifyHash(
    dataIdentifier: String,
    expectedHashIdentifier: String
  ) async -> Result<Bool, SecurityStorageError> {
    // Get the data to verify
    let dataResult = await exportData(identifier: dataIdentifier)
    guard case let .success(data) = dataResult else {
      if case let .failure(error) = dataResult {
        await logger.error(
          "Failed to retrieve data for hash verification: \(error)",
          context: CryptoLogContext(
            operation: "verifyHash",
            additionalContext: LogMetadataDTOCollection()
              .withPrivate(key: "dataIdentifier", value: dataIdentifier)
              .withPublic(key: "expectedHashIdentifier", value: expectedHashIdentifier)
          )
        )
      }
      return .failure(.keyNotFound(dataIdentifier))
    }

    // Get the expected hash
    let hashResult = await exportData(identifier: expectedHashIdentifier)
    guard case let .success(expectedHash) = hashResult else {
      if case let .failure(error) = hashResult {
        await logger.error(
          "Failed to retrieve expected hash: \(error)",
          context: CryptoLogContext(
            operation: "verifyHash",
            additionalContext: LogMetadataDTOCollection()
              .withPrivate(key: "dataIdentifier", value: dataIdentifier)
              .withPublic(key: "expectedHashIdentifier", value: expectedHashIdentifier)
          )
        )
      }
      return .failure(.keyNotFound(expectedHashIdentifier))
    }

    // Log hash verification operation
    await logger.debug(
      "Verifying hash for data",
      context: CryptoLogContext(
        operation: "verifyHash",
        additionalContext: LogMetadataDTOCollection()
          .withPrivate(key: "dataIdentifier", value: dataIdentifier)
          .withPublic(key: "expectedHashIdentifier", value: expectedHashIdentifier)
      )
    )

    // Delegate to security provider
    let result = await provider.verifyHash(
      data: data,
      expectedHash: expectedHash
    )

    return result.map { $0 }.mapError { error in
      SecurityStorageError.operationFailed(error)
    }
  }

  /**
   Generates a cryptographic key with the specified length.
   
   - Parameters:
     - length: The length of the key in bytes
     - options: Optional key generation options
   - Returns: Success with the key identifier or an error
   */
  public func generateKey(
    length: Int,
    options: SecurityCoreInterfaces.KeyGenerationOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    // Log key generation operation
    await logger.debug(
      "Generating key with length: \(length)",
      context: CryptoLogContext(
        operation: "generateKey",
        additionalContext: LogMetadataDTOCollection()
          .withPublic(key: "keyLength", value: "\(length)")
      )
    )
    
    // Prepare key generation options
    let keyOptions = SecurityKeyOptions(
      keySize: length * 8,
      algorithm: .aes256GCM
    )
    
    // Delegate to security provider
    let result = await provider.generateKey(
      config: keyOptions
    )
    
    // Map result to expected format
    return result.mapError { error in
      SecurityStorageError.operationFailed("Key generation failed: \(error)")
    }
  }
  
  /**
   Stores data securely.
   
   - Parameters:
     - data: The data to store
     - identifier: The identifier to use for the stored data
   - Returns: Success or an error
   */
  public func storeData(
    data: Data,
    identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    // Log data storage operation
    await logger.debug(
      "Storing data with identifier: \(identifier)",
      context: CryptoLogContext(
        operation: "storeData",
        additionalContext: LogMetadataDTOCollection()
          .withPrivate(key: "identifier", value: identifier)
          .withPublic(key: "dataSize", value: "\(data.count)")
      )
    )
    
    // Delegate to secure storage
    let result = await secureStorage.storeData(
      [UInt8](data),
      withIdentifier: identifier
    )
    
    return result.map { _ in () }.mapError { error in
      SecurityStorageError.operationFailed("\(error)")
    }
  }
  
  /**
   Retrieves data from secure storage.
   
   - Parameter identifier: The identifier of the data to retrieve
   - Returns: Success with the retrieved data or an error
   */
  public func retrieveData(
    identifier: String
  ) async -> Result<Data, SecurityStorageError> {
    // Log data retrieval operation
    await logger.debug(
      "Retrieving data with identifier: \(identifier)",
      context: CryptoLogContext(
        operation: "retrieveData",
        additionalContext: LogMetadataDTOCollection()
          .withPrivate(key: "identifier", value: identifier)
      )
    )
    
    // Delegate to secure storage
    let result = await secureStorage.retrieveData(withIdentifier: identifier)
    
    return result.map { Data($0) }.mapError { error in
      if case .dataNotFound = error {
        return SecurityStorageError.dataNotFound
      }
      return SecurityStorageError.operationFailed("\(error)")
    }
  }
  
  /**
   Exports data from secure storage.
   
   - Parameter identifier: The identifier of the data to export
   - Returns: Success with the exported data or an error
   */
  public func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    // Log data export operation
    await logger.debug(
      "Exporting data with identifier: \(identifier)",
      context: CryptoLogContext(
        operation: "exportData",
        additionalContext: LogMetadataDTOCollection()
          .withPrivate(key: "identifier", value: identifier)
      )
    )
    
    // Delegate to secure storage
    let result = await secureStorage.retrieveData(withIdentifier: identifier)
    
    return result.mapError { error in
      if case .dataNotFound = error {
        return SecurityStorageError.dataNotFound
      }
      return SecurityStorageError.operationFailed("\(error)")
    }
  }
  
  /**
   Imports data into secure storage.
   
   - Parameters:
     - data: The data to import
     - identifier: The identifier to use for the imported data
   - Returns: Success with the identifier of the imported data or an error
   */
  public func importData(
    _ data: [UInt8],
    customIdentifier identifier: String?
  ) async -> Result<String, SecurityStorageError> {
    // Use provided identifier or generate a new one
    let actualIdentifier = identifier ?? UUID().uuidString
    
    // Log data import operation
    await logger.debug(
      "Importing data with identifier: \(actualIdentifier)",
      context: CryptoLogContext(
        operation: "importData",
        additionalContext: LogMetadataDTOCollection()
          .withPrivate(key: "identifier", value: actualIdentifier)
          .withPublic(key: "dataSize", value: "\(data.count)")
      )
    )
    
    // Delegate to secure storage
    let result = await secureStorage.storeData(
      data,
      withIdentifier: actualIdentifier
    )
    
    return result.map { _ in actualIdentifier }.mapError { error in
      SecurityStorageError.operationFailed("\(error)")
    }
  }
  
  /**
   Imports data using Data format
   
   - Parameters:
     - data: The data to import
     - customIdentifier: The identifier to use
   - Returns: The identifier used or an error
   */
  public func importData(
    _ data: Data,
    customIdentifier: String
  ) async -> Result<String, SecurityStorageError> {
    return await importData([UInt8](data), customIdentifier: customIdentifier)
  }
  
  /**
   Deletes data from secure storage.
   
   - Parameter identifier: The identifier of the data to delete
   - Returns: Success or an error
   */
  public func deleteData(
    identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    // Log data deletion operation
    await logger.debug(
      "Deleting data with identifier: \(identifier)",
      context: CryptoLogContext(
        operation: "deleteData",
        additionalContext: LogMetadataDTOCollection()
          .withPrivate(key: "identifier", value: identifier)
      )
    )
    
    // Delegate to secure storage
    let result = await secureStorage.deleteData(withIdentifier: identifier)
    
    return result.mapError { error in
      if case .dataNotFound = error {
        return SecurityStorageError.dataNotFound
      }
      return SecurityStorageError.operationFailed("\(error)")
    }
  }
}
