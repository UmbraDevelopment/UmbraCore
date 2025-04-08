import CoreSecurityTypes
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces

/**
 An implementation of CryptoServiceProtocol that adds logging for
 all operations before delegating to the wrapped implementation.
 */
public actor LoggingCryptoServiceImpl: @preconcurrency CryptoServiceProtocol {
  /// The wrapped implementation
  private let wrapped: CryptoServiceProtocol

  /// The logger for this implementation
  private let logger: LoggingInterfaces.LoggingProtocol

  /// The secure storage used by this service
  public let secureStorage: SecureStorageProtocol

  /**
   Creates a new LoggingCryptoServiceImpl.

   - Parameters:
   - wrapped: The CryptoServiceProtocol implementation to wrap
   - logger: The logger to use
   */
  public init(
    wrapped: CryptoServiceProtocol,
    logger: LoggingInterfaces.LoggingProtocol
  ) {
    self.wrapped=wrapped
    self.logger=logger
    secureStorage=wrapped.secureStorage
  }

  /**
   Encrypts data with logging.

   - Parameters:
   - dataIdentifier: Identifier for the data to encrypt
   - keyIdentifier: Identifier for the encryption key
   - options: Optional encryption options
   - Returns: Identifier for the encrypted data or an error
   */
  public func encrypt(
    dataIdentifier: String,
    keyIdentifier: String,
    options: CoreSecurityTypes.EncryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    await logger.info(
      "Encrypting data with identifier \(dataIdentifier) using key \(keyIdentifier)",
      context: CryptoLogContext(
        operation: "encrypt",
        additionalContext: LogMetadataDTOCollection().withPublic(
          key: "dataIdentifier",
          value: dataIdentifier
        ).withPublic(
          key: "keyIdentifier",
          value: keyIdentifier
        )
      )
    )

    let result=await wrapped.encrypt(
      dataIdentifier: dataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )

    switch result {
      case let .success(identifier):
        await logger.info(
          "Successfully encrypted data to identifier: \(identifier)",
          context: CryptoLogContext(
            operation: "encrypt",
            additionalContext: LogMetadataDTOCollection().withPrivate(
              key: "identifier",
              value: identifier
            )
          )
        )
      case let .failure(error):
        await logger.error(
          "Failed to encrypt data: \(error)",
          context: CryptoLogContext(
            operation: "encrypt",
            additionalContext: LogMetadataDTOCollection().withPrivate(
              key: "error",
              value: "\(error)"
            )
          )
        )
    }

    return result
  }

  /**
   Decrypts data with logging.

   - Parameters:
   - encryptedDataIdentifier: Identifier for the encrypted data
   - keyIdentifier: Identifier for the decryption key
   - options: Optional decryption options
   - Returns: Identifier for the decrypted data or an error
   */
  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options: CoreSecurityTypes.DecryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    await logger.info(
      "Decrypting data with identifier \(encryptedDataIdentifier) using key \(keyIdentifier)",
      context: CryptoLogContext(
        operation: "decrypt",
        additionalContext: LogMetadataDTOCollection().withPublic(
          key: "encryptedDataIdentifier",
          value: encryptedDataIdentifier
        ).withPublic(
          key: "keyIdentifier",
          value: keyIdentifier
        )
      )
    )

    let result=await wrapped.decrypt(
      encryptedDataIdentifier: encryptedDataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )

    switch result {
      case let .success(identifier):
        await logger.info(
          "Successfully decrypted data to identifier: \(identifier)",
          context: CryptoLogContext(
            operation: "decrypt",
            additionalContext: LogMetadataDTOCollection().withPrivate(
              key: "identifier",
              value: identifier
            )
          )
        )
      case let .failure(error):
        await logger.error(
          "Failed to decrypt data: \(error)",
          context: CryptoLogContext(
            operation: "decrypt",
            additionalContext: LogMetadataDTOCollection().withPrivate(
              key: "error",
              value: "\(error)"
            )
          )
        )
    }

    return result
  }

  /**
   Computes a hash with logging.

   - Parameters:
   - dataIdentifier: Identifier for the data to hash
   - options: Optional hashing options
   - Returns: Identifier for the hash or an error
   */
  public func hash(
    dataIdentifier: String,
    options: CoreSecurityTypes.HashingOptions?
  ) async -> Result<String, SecurityStorageError> {
    await logger.info(
      "Hashing data with identifier \(dataIdentifier)",
      context: CryptoLogContext(
        operation: "hash",
        additionalContext: LogMetadataDTOCollection().withPublic(
          key: "dataIdentifier",
          value: dataIdentifier
        )
      )
    )

    let result=await wrapped.hash(
      dataIdentifier: dataIdentifier,
      options: options
    )

    switch result {
      case let .success(identifier):
        await logger.info(
          "Successfully hashed data to identifier: \(identifier)",
          context: CryptoLogContext(
            operation: "hash",
            additionalContext: LogMetadataDTOCollection().withPrivate(
              key: "identifier",
              value: identifier
            )
          )
        )
      case let .failure(error):
        await logger.error(
          "Failed to hash data: \(error)",
          context: CryptoLogContext(
            operation: "hash",
            additionalContext: LogMetadataDTOCollection().withPrivate(
              key: "error",
              value: "\(error)"
            )
          )
        )
    }

    return result
  }

  /**
   Verifies a hash with logging.

   - Parameters:
   - dataIdentifier: Identifier for the data to verify
   - hashIdentifier: Identifier for the expected hash
   - options: Optional hashing options
   - Returns: Whether the hash is valid or an error
   */
  public func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options: CoreSecurityTypes.HashingOptions?
  ) async -> Result<Bool, SecurityStorageError> {
    await logger.info(
      "Verifying hash for data with identifier \(dataIdentifier) against hash \(hashIdentifier)",
      context: CryptoLogContext(
        operation: "verifyHash",
        additionalContext: LogMetadataDTOCollection().withPublic(
          key: "dataIdentifier",
          value: dataIdentifier
        ).withPublic(
          key: "hashIdentifier",
          value: hashIdentifier
        )
      )
    )

    let result=await wrapped.verifyHash(
      dataIdentifier: dataIdentifier,
      hashIdentifier: hashIdentifier,
      options: options
    )

    switch result {
      case let .success(matches):
        await logger.info(
          "Hash verification result: \(matches ? "Match" : "No match")",
          context: CryptoLogContext(
            operation: "verifyHash",
            additionalContext: LogMetadataDTOCollection().withPublic(
              key: "result",
              value: matches ? "match" : "no match"
            )
          )
        )
      case let .failure(error):
        await logger.error(
          "Failed to verify hash: \(error)",
          context: CryptoLogContext(
            operation: "verifyHash",
            additionalContext: LogMetadataDTOCollection().withPrivate(
              key: "error",
              value: "\(error)"
            )
          )
        )
    }

    return result
  }

  /**
   Generates a key with logging.

   - Parameters:
   - length: Length of the key to generate in bytes
   - options: Optional key generation options
   - Returns: Identifier for the generated key or an error
   */
  public func generateKey(
    length: Int,
    options: CoreSecurityTypes.KeyGenerationOptions?
  ) async -> Result<String, SecurityStorageError> {
    await logger.info(
      "Generating key with length \(length) bytes",
      context: CryptoLogContext(
        operation: "generateKey",
        additionalContext: LogMetadataDTOCollection().withPublic(
          key: "keyLength",
          value: "\(length)"
        )
      )
    )

    let result=await wrapped.generateKey(
      length: length,
      options: options
    )

    switch result {
      case let .success(identifier):
        await logger.info(
          "Successfully generated key with identifier: \(identifier)",
          context: CryptoLogContext(
            operation: "generateKey",
            additionalContext: LogMetadataDTOCollection().withPrivate(
              key: "identifier",
              value: identifier
            )
          )
        )
      case let .failure(error):
        await logger.error(
          "Failed to generate key: \(error)",
          context: CryptoLogContext(
            operation: "generateKey",
            additionalContext: LogMetadataDTOCollection().withPrivate(
              key: "error",
              value: "\(error)"
            )
          )
        )
    }

    return result
  }

  /**
   Imports data with logging.

   - Parameters:
   - data: Raw data to import
   - customIdentifier: Optional custom identifier for the data
   - Returns: Identifier for the imported data or an error
   */
  public func importData(
    _ data: [UInt8],
    customIdentifier: String?
  ) async -> Result<String, SecurityStorageError> {
    await logger.info(
      "Importing data\(customIdentifier != nil ? " with custom identifier \(customIdentifier!)" : "")",
      context: CryptoLogContext(
        operation: "importData",
        additionalContext: LogMetadataDTOCollection().withPublic(
          key: "customIdentifier",
          value: customIdentifier ?? ""
        )
      )
    )

    let result=await wrapped.importData(
      data,
      customIdentifier: customIdentifier
    )

    switch result {
      case let .success(identifier):
        await logger.info(
          "Successfully imported data with identifier: \(identifier)",
          context: CryptoLogContext(
            operation: "importData",
            additionalContext: LogMetadataDTOCollection().withPrivate(
              key: "identifier",
              value: identifier
            )
          )
        )
      case let .failure(error):
        await logger.error(
          "Failed to import data: \(error)",
          context: CryptoLogContext(
            operation: "importData",
            additionalContext: LogMetadataDTOCollection().withPrivate(
              key: "error",
              value: "\(error)"
            )
          )
        )
    }

    return result
  }

  /**
   Exports data with logging.

   - Parameter identifier: Identifier for the data to export
   - Returns: Raw bytes or an error
   */
  public func exportData(identifier: String) async -> Result<[UInt8], SecurityStorageError> {
    await logger.info(
      "Exporting data with identifier: \(identifier)",
      context: CryptoLogContext(
        operation: "exportData",
        additionalContext: LogMetadataDTOCollection().withPublic(
          key: "identifier",
          value: identifier
        )
      )
    )

    let result=await wrapped.exportData(identifier: identifier)

    switch result {
      case .success:
        await logger.info(
          "Successfully exported data with identifier: \(identifier)",
          context: CryptoLogContext(
            operation: "exportData",
            additionalContext: LogMetadataDTOCollection().withPublic(
              key: "identifier",
              value: identifier
            )
          )
        )
      case let .failure(error):
        await logger.error(
          "Failed to export data: \(error)",
          context: CryptoLogContext(
            operation: "exportData",
            additionalContext: LogMetadataDTOCollection().withPrivate(
              key: "error",
              value: "\(error)"
            )
          )
        )
    }

    return result
  }

  /**
   Generates a hash with logging.

   - Parameters:
   - dataIdentifier: Identifier for the data to hash
   - options: Optional hashing options
   - Returns: Identifier for the hash or an error
   */
  public func generateHash(
    dataIdentifier: String,
    options: CoreSecurityTypes.HashingOptions?
  ) async -> Result<String, SecurityStorageError> {
    await logger.info(
      "Generating hash for data with identifier \(dataIdentifier)",
      context: CryptoLogContext(
        operation: "generateHash",
        additionalContext: LogMetadataDTOCollection().withPublic(
          key: "dataIdentifier",
          value: dataIdentifier
        )
      )
    )

    let result=await wrapped.generateHash(
      dataIdentifier: dataIdentifier,
      options: options
    )

    switch result {
      case let .success(identifier):
        await logger.info(
          "Successfully generated hash with identifier: \(identifier)",
          context: CryptoLogContext(
            operation: "generateHash",
            additionalContext: LogMetadataDTOCollection().withPrivate(
              key: "identifier",
              value: identifier
            )
          )
        )
      case let .failure(error):
        await logger.error(
          "Failed to generate hash: \(error)",
          context: CryptoLogContext(
            operation: "generateHash",
            additionalContext: LogMetadataDTOCollection().withPrivate(
              key: "error",
              value: "\(error)"
            )
          )
        )
    }

    return result
  }

  /**
   Stores data with logging.

   - Parameters:
   - data: Data to store
   - identifier: Identifier for the data
   - Returns: Void or an error
   */
  public func storeData(
    data: Data,
    identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    await logger.info(
      "Storing data with identifier \(identifier)",
      context: CryptoLogContext(
        operation: "storeData",
        additionalContext: LogMetadataDTOCollection().withPublic(
          key: "identifier",
          value: identifier
        )
      )
    )

    let result=await wrapped.storeData(
      data: data,
      identifier: identifier
    )

    switch result {
      case .success:
        await logger.info(
          "Successfully stored data with identifier: \(identifier)",
          context: CryptoLogContext(
            operation: "storeData",
            additionalContext: LogMetadataDTOCollection().withPublic(
              key: "identifier",
              value: identifier
            )
          )
        )
      case let .failure(error):
        await logger.error(
          "Failed to store data: \(error)",
          context: CryptoLogContext(
            operation: "storeData",
            additionalContext: LogMetadataDTOCollection().withPrivate(
              key: "error",
              value: "\(error)"
            )
          )
        )
    }

    return result
  }

  /**
   Retrieves data with logging.

   - Parameter identifier: Identifier for the data to retrieve
   - Returns: Data or an error
   */
  public func retrieveData(
    identifier: String
  ) async -> Result<Data, SecurityStorageError> {
    await logger.info(
      "Retrieving data with identifier \(identifier)",
      context: CryptoLogContext(
        operation: "retrieveData",
        additionalContext: LogMetadataDTOCollection().withPublic(
          key: "identifier",
          value: identifier
        )
      )
    )

    let result=await wrapped.retrieveData(
      identifier: identifier
    )

    switch result {
      case .success:
        await logger.info(
          "Successfully retrieved data with identifier: \(identifier)",
          context: CryptoLogContext(
            operation: "retrieveData",
            additionalContext: LogMetadataDTOCollection().withPublic(
              key: "identifier",
              value: identifier
            )
          )
        )
      case let .failure(error):
        await logger.error(
          "Failed to retrieve data: \(error)",
          context: CryptoLogContext(
            operation: "retrieveData",
            additionalContext: LogMetadataDTOCollection().withPrivate(
              key: "error",
              value: "\(error)"
            )
          )
        )
    }

    return result
  }

  /**
   Deletes data with logging.

   - Parameter identifier: Identifier for the data to delete
   - Returns: Void or an error
   */
  public func deleteData(
    identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    await logger.info(
      "Deleting data with identifier \(identifier)",
      context: CryptoLogContext(
        operation: "deleteData",
        additionalContext: LogMetadataDTOCollection().withPublic(
          key: "identifier",
          value: identifier
        )
      )
    )

    let result=await wrapped.deleteData(
      identifier: identifier
    )

    switch result {
      case .success:
        await logger.info(
          "Successfully deleted data with identifier: \(identifier)",
          context: CryptoLogContext(
            operation: "deleteData",
            additionalContext: LogMetadataDTOCollection().withPublic(
              key: "identifier",
              value: identifier
            )
          )
        )
      case let .failure(error):
        await logger.error(
          "Failed to delete data: \(error)",
          context: CryptoLogContext(
            operation: "deleteData",
            additionalContext: LogMetadataDTOCollection().withPrivate(
              key: "error",
              value: "\(error)"
            )
          )
        )
    }

    return result
  }

  /**
   Imports data with logging.

   - Parameters:
   - data: Data to import
   - customIdentifier: Custom identifier for the data
   - Returns: Identifier for the imported data or an error
   */
  public func importData(
    _ data: Data,
    customIdentifier: String
  ) async -> Result<String, SecurityStorageError> {
    await logger.info(
      "Importing data with custom identifier \(customIdentifier)",
      context: CryptoLogContext(
        operation: "importData",
        additionalContext: LogMetadataDTOCollection().withPublic(
          key: "customIdentifier",
          value: customIdentifier
        )
      )
    )

    let result=await wrapped.importData(
      data,
      customIdentifier: customIdentifier
    )

    switch result {
      case let .success(identifier):
        await logger.info(
          "Successfully imported data with identifier: \(identifier)",
          context: CryptoLogContext(
            operation: "importData",
            additionalContext: LogMetadataDTOCollection().withPrivate(
              key: "identifier",
              value: identifier
            )
          )
        )
      case let .failure(error):
        await logger.error(
          "Failed to import data: \(error)",
          context: CryptoLogContext(
            operation: "importData",
            additionalContext: LogMetadataDTOCollection().withPrivate(
              key: "error",
              value: "\(error)"
            )
          )
        )
    }

    return result
  }
}
