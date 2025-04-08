import CoreSecurityTypes
import Foundation
import LoggingInterfaces
import SecurityCoreInterfaces

/**
 * A mock implementation of CryptoServiceProtocol for testing purposes.
 *
 * This implementation provides configurable success/failure behavior for all methods,
 * making it useful for unit testing components that depend on CryptoServiceProtocol.
 */
public actor MockCryptoServiceImpl: @preconcurrency CryptoServiceProtocol {
  /// Configuration options for the mock
  public struct Configuration: Sendable {
    /// Whether encryption operations should succeed
    public var encryptionSucceeds: Bool

    /// Whether decryption operations should succeed
    public var decryptionSucceeds: Bool

    /// Whether hashing operations should succeed
    public var hashingSucceeds: Bool

    /// Whether verification operations should succeed
    public var verificationSucceeds: Bool

    /// Whether key generation operations should succeed
    public var keyGenerationSucceeds: Bool

    /// Whether data storage operations should succeed
    public var storageSucceeds: Bool

    /// Whether a verified hash matches (if verification succeeds)
    public var hashMatches: Bool

    /// Whether export data operations should succeed
    public var exportDataSucceeds: Bool

    /// Creates a new configuration with specified options
    public init(
      encryptionSucceeds: Bool=true,
      decryptionSucceeds: Bool=true,
      hashingSucceeds: Bool=true,
      verificationSucceeds: Bool=true,
      keyGenerationSucceeds: Bool=true,
      storageSucceeds: Bool=true,
      hashMatches: Bool=true,
      exportDataSucceeds: Bool=true
    ) {
      self.encryptionSucceeds=encryptionSucceeds
      self.decryptionSucceeds=decryptionSucceeds
      self.hashingSucceeds=hashingSucceeds
      self.verificationSucceeds=verificationSucceeds
      self.keyGenerationSucceeds=keyGenerationSucceeds
      self.storageSucceeds=storageSucceeds
      self.hashMatches=hashMatches
      self.exportDataSucceeds=exportDataSucceeds
    }
  }

  /// The configuration for this mock implementation
  private let configuration: Configuration

  /// Logger for diagnostic information
  private let logger: LoggingProtocol

  /// The secure storage used by this service
  public let secureStorage: SecureStorageProtocol

  /**
   Creates a new mock crypto service with the specified configuration

   - Parameter configuration: The configuration for this mock implementation
   - Parameter logger: The logger for diagnostic information
   - Parameter secureStorage: The secure storage to use
   */
  public init(
    configuration: Configuration=Configuration(),
    logger: LoggingProtocol,
    secureStorage: SecureStorageProtocol
  ) {
    self.configuration=configuration
    self.logger=logger
    self.secureStorage=secureStorage
  }

  /**
   Encrypts data with configurable success/failure behavior.

   - Parameters:
   - dataIdentifier: Identifier for the data to encrypt
   - keyIdentifier: Identifier for the encryption key
   - options: Optional encryption options (ignored in this implementation)
   - Returns: Identifier for the encrypted data or an error
   */
  public func encrypt(
    dataIdentifier: String,
    keyIdentifier _: String,
    options _: CoreSecurityTypes.EncryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    await logger.debug(
      "Encrypting data \(dataIdentifier)",
      context: CryptoLogContext(
        operation: "encrypt",
        additionalContext: LogMetadataDTOCollection().withPrivate(
          key: "dataIdentifier",
          value: dataIdentifier
        )
      )
    )

    if configuration.encryptionSucceeds {
      let encryptedID="encrypted_\(dataIdentifier)"

      // Mock data to store
      let mockData: [UInt8]=[0x01, 0x02, 0x03, 0x04]

      // Store encrypted data
      _=await secureStorage.storeData(mockData, withIdentifier: encryptedID)

      await logger.debug(
        "Encryption succeeded: \(encryptedID)",
        context: CryptoLogContext(
          operation: "encrypt",
          additionalContext: LogMetadataDTOCollection().withPrivate(
            key: "encryptedID",
            value: encryptedID
          )
        )
      )

      return .success(encryptedID)
    } else {
      await logger.debug(
        "Encryption failed",
        context: CryptoLogContext(
          operation: "encrypt",
          additionalContext: LogMetadataDTOCollection().withPublic(
            key: "result",
            value: "failure"
          )
        )
      )
      return .failure(.operationFailed("Mock encryption failure"))
    }
  }

  /**
   Decrypts data with configurable success/failure behavior.

   - Parameters:
   - encryptedDataIdentifier: Identifier for the encrypted data
   - keyIdentifier: Identifier for the decryption key
   - options: Optional decryption options (ignored in this implementation)
   - Returns: Identifier for the decrypted data or an error
   */
  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier _: String,
    options _: CoreSecurityTypes.DecryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    await logger.debug(
      "Decrypting data \(encryptedDataIdentifier)",
      context: CryptoLogContext(
        operation: "decrypt",
        additionalContext: LogMetadataDTOCollection().withPrivate(
          key: "encryptedDataIdentifier",
          value: encryptedDataIdentifier
        )
      )
    )

    if configuration.decryptionSucceeds {
      let decryptedID="decrypted_\(encryptedDataIdentifier)"

      // Mock data to store
      let mockData: [UInt8]=[0x01, 0x02, 0x03, 0x04]

      _=await secureStorage.storeData(mockData, withIdentifier: decryptedID)

      await logger.debug(
        "Decryption succeeded: \(decryptedID)",
        context: CryptoLogContext(
          operation: "decrypt",
          additionalContext: LogMetadataDTOCollection().withPrivate(
            key: "decryptedID",
            value: decryptedID
          )
        )
      )

      return .success(decryptedID)
    } else {
      await logger.debug(
        "Decryption failed",
        context: CryptoLogContext(
          operation: "decrypt",
          additionalContext: LogMetadataDTOCollection().withPublic(
            key: "result",
            value: "failure"
          )
        )
      )
      return .failure(.operationFailed("Mock decryption failure"))
    }
  }

  /**
   Hashes data with configurable success/failure behavior.

   - Parameters:
   - dataIdentifier: Identifier for the data to hash
   - options: Optional hashing options (ignored in this implementation)
   - Returns: Identifier for the hash or an error
   */
  public func hash(
    dataIdentifier: String,
    options _: CoreSecurityTypes.HashingOptions?
  ) async -> Result<String, SecurityStorageError> {
    await logger.debug(
      "Hashing data \(dataIdentifier)",
      context: CryptoLogContext(
        operation: "hash",
        additionalContext: LogMetadataDTOCollection().withPrivate(
          key: "dataIdentifier",
          value: dataIdentifier
        )
      )
    )

    if configuration.hashingSucceeds {
      let identifier="hash_\(dataIdentifier)"

      // Store a mock hash value
      _=await secureStorage.storeData([0x01, 0x02, 0x03, 0x04], withIdentifier: identifier)

      await logger.debug(
        "Hashing succeeded: \(identifier)",
        context: CryptoLogContext(
          operation: "hash",
          additionalContext: LogMetadataDTOCollection().withPrivate(
            key: "identifier",
            value: identifier
          )
        )
      )

      return .success(identifier)
    } else {
      await logger.debug(
        "Hashing failed",
        context: CryptoLogContext(
          operation: "hash",
          additionalContext: LogMetadataDTOCollection().withPublic(
            key: "result",
            value: "failure"
          )
        )
      )
      return .failure(.operationFailed("Mock hashing failure"))
    }
  }

  /**
   Verifies a hash with configurable success/failure behavior.

   - Parameters:
   - dataIdentifier: Identifier for the data to verify
   - hashIdentifier: Identifier for the expected hash
   - options: Optional hashing options (ignored in this implementation)
   - Returns: Whether the hash matches or an error
   */
  public func verifyHash(
    dataIdentifier _: String,
    hashIdentifier _: String,
    options _: CoreSecurityTypes.HashingOptions?
  ) async -> Result<Bool, SecurityStorageError> {
    await logger.debug(
      "Verifying hash",
      context: CryptoLogContext(
        operation: "verifyHash",
        additionalContext: LogMetadataDTOCollection().withPublic(
          key: "operation",
          value: "verifyHash"
        )
      )
    )

    if configuration.verificationSucceeds {
      await logger.debug(
        "Verification succeeded",
        context: CryptoLogContext(
          operation: "verifyHash",
          additionalContext: LogMetadataDTOCollection().withPublic(
            key: "result",
            value: "success"
          )
        )
      )
      return .success(configuration.hashMatches)
    } else {
      await logger.debug(
        "Verification failed",
        context: CryptoLogContext(
          operation: "verifyHash",
          additionalContext: LogMetadataDTOCollection().withPublic(
            key: "result",
            value: "failure"
          )
        )
      )
      return .failure(.operationFailed("Mock hash verification failure"))
    }
  }

  /**
   Generates a cryptographic key with configurable success/failure behavior.

   - Parameters:
   - length: Length of the key in bytes
   - options: Optional key generation options (ignored in this implementation)
   - Returns: Identifier for the generated key or an error
   */
  public func generateKey(
    length: Int,
    options _: CoreSecurityTypes.KeyGenerationOptions?
  ) async -> Result<String, SecurityStorageError> {
    await logger.debug(
      "Generating key with length \(length)",
      context: CryptoLogContext(
        operation: "generateKey",
        additionalContext: LogMetadataDTOCollection().withPrivate(
          key: "length",
          value: String(length)
        )
      )
    )

    if configuration.keyGenerationSucceeds {
      let keyID="key_\(UUID().uuidString)"

      // Mock key data
      let keyData: [UInt8]=Array(repeating: 0x42, count: length)

      _=await secureStorage.storeData(keyData, withIdentifier: keyID)

      await logger.debug(
        "Key generation succeeded: \(keyID)",
        context: CryptoLogContext(
          operation: "generateKey",
          additionalContext: LogMetadataDTOCollection().withPrivate(
            key: "keyID",
            value: keyID
          )
        )
      )

      return .success(keyID)
    } else {
      await logger.debug(
        "Key generation failed",
        context: CryptoLogContext(
          operation: "generateKey",
          additionalContext: LogMetadataDTOCollection().withPublic(
            key: "result",
            value: "failure"
          )
        )
      )
      return .failure(.operationFailed("Mock key generation failure"))
    }
  }

  /**
   Imports data with configurable success/failure behavior.

   - Parameters:
   - data: The data to import
   - customIdentifier: Optional custom identifier
   - Returns: Identifier for the imported data or an error
   */
  public func importData(
    _ data: [UInt8],
    customIdentifier: String?
  ) async -> Result<String, SecurityStorageError> {
    await logger.debug(
      "Importing data with custom identifier \(customIdentifier ?? "nil")",
      context: CryptoLogContext(
        operation: "importData",
        additionalContext: LogMetadataDTOCollection().withPrivate(
          key: "customIdentifier",
          value: customIdentifier ?? "nil"
        )
      )
    )

    if configuration.storageSucceeds {
      let identifier=customIdentifier ?? "imported_\(UUID().uuidString)"

      _=await secureStorage.storeData(data, withIdentifier: identifier)

      await logger.debug(
        "Import succeeded: \(identifier)",
        context: CryptoLogContext(
          operation: "importData",
          additionalContext: LogMetadataDTOCollection().withPrivate(
            key: "identifier",
            value: identifier
          )
        )
      )

      return .success(identifier)
    } else {
      await logger.debug(
        "Import failed",
        context: CryptoLogContext(
          operation: "importData",
          additionalContext: LogMetadataDTOCollection().withPublic(
            key: "result",
            value: "failure"
          )
        )
      )
      return .failure(.operationFailed("Mock data import failure"))
    }
  }

  /**
   Exports data with configurable success/failure behavior.

   - Parameter identifier: Identifier for the data to export
   - Returns: The exported data or an error
   */
  public func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    await logger.debug(
      "Exporting data \(identifier)",
      context: CryptoLogContext(
        operation: "exportData",
        additionalContext: LogMetadataDTOCollection().withPrivate(
          key: "identifier",
          value: identifier
        )
      )
    )

    if configuration.exportDataSucceeds {
      await logger.debug(
        "Export succeeded",
        context: CryptoLogContext(
          operation: "exportData",
          additionalContext: LogMetadataDTOCollection().withPublic(
            key: "result",
            value: "success"
          )
        )
      )
      return .success([UInt8](repeating: 42, count: 32))
    } else {
      await logger.debug(
        "Export failed",
        context: CryptoLogContext(
          operation: "exportData",
          additionalContext: LogMetadataDTOCollection().withPublic(
            key: "result",
            value: "failure"
          )
        )
      )
      return .failure(.operationFailed("Export failed"))
    }
  }

  /**
   Generates a hash of the data associated with the given identifier.

   - Parameters:
     - dataIdentifier: Identifier for the data to hash in secure storage.
     - options: Optional hashing configuration.
   - Returns: Identifier for the generated hash in secure storage, or an error.
   */
  public func generateHash(
    dataIdentifier: String,
    options _: HashingOptions?
  ) async -> Result<String, SecurityStorageError> {
    await logger.debug(
      "Generating hash for data \(dataIdentifier)",
      context: CryptoLogContext(
        operation: "generateHash",
        additionalContext: LogMetadataDTOCollection().withPrivate(
          key: "dataIdentifier",
          value: dataIdentifier
        )
      )
    )

    if configuration.hashingSucceeds {
      let hashIdentifier="mock_hash_\(dataIdentifier)"
      await logger.debug(
        "Hash generation succeeded: \(hashIdentifier)",
        context: CryptoLogContext(
          operation: "generateHash",
          additionalContext: LogMetadataDTOCollection().withPrivate(
            key: "hashIdentifier",
            value: hashIdentifier
          )
        )
      )
      return .success(hashIdentifier)
    } else {
      await logger.debug(
        "Hash generation failed",
        context: CryptoLogContext(
          operation: "generateHash",
          additionalContext: LogMetadataDTOCollection().withPublic(
            key: "result",
            value: "failure"
          )
        )
      )
      return .failure(.hashingFailed)
    }
  }

  /**
   Stores raw data under a specific identifier in secure storage.

   - Parameters:
     - data: The data to store.
     - identifier: The identifier to use for storage.
   - Returns: Success or an error.
   */
  public func storeData(
    data _: Data,
    identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    await logger.debug(
      "Storing data with identifier \(identifier)",
      context: CryptoLogContext(
        operation: "storeData",
        additionalContext: LogMetadataDTOCollection().withPrivate(
          key: "identifier",
          value: identifier
        )
      )
    )

    if configuration.storageSucceeds {
      await logger.debug(
        "Storage succeeded",
        context: CryptoLogContext(
          operation: "storeData",
          additionalContext: LogMetadataDTOCollection().withPublic(
            key: "result",
            value: "success"
          )
        )
      )
      return .success(())
    } else {
      await logger.debug(
        "Storage failed",
        context: CryptoLogContext(
          operation: "storeData",
          additionalContext: LogMetadataDTOCollection().withPublic(
            key: "result",
            value: "failure"
          )
        )
      )
      return .failure(.operationFailed("Storage failed"))
    }
  }

  /**
   Retrieves data from secure storage by its identifier.

   - Parameter identifier: The identifier of the data to retrieve.
   - Returns: The retrieved data or an error.
   */
  public func retrieveData(
    identifier: String
  ) async -> Result<Data, SecurityStorageError> {
    await logger.debug(
      "Retrieving data with identifier \(identifier)",
      context: CryptoLogContext(
        operation: "retrieveData",
        additionalContext: LogMetadataDTOCollection().withPrivate(
          key: "identifier",
          value: identifier
        )
      )
    )

    if configuration.storageSucceeds {
      await logger.debug(
        "Retrieval succeeded",
        context: CryptoLogContext(
          operation: "retrieveData",
          additionalContext: LogMetadataDTOCollection().withPublic(
            key: "result",
            value: "success"
          )
        )
      )
      // Return some mock data
      return .success(Data(repeating: 42, count: 32))
    } else {
      await logger.debug(
        "Retrieval failed",
        context: CryptoLogContext(
          operation: "retrieveData",
          additionalContext: LogMetadataDTOCollection().withPublic(
            key: "result",
            value: "failure"
          )
        )
      )
      return .failure(.dataNotFound)
    }
  }

  /**
   Deletes data from secure storage by its identifier.

   - Parameter identifier: The identifier of the data to delete.
   - Returns: Success or an error.
   */
  public func deleteData(
    identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    await logger.debug(
      "Deleting data with identifier \(identifier)",
      context: CryptoLogContext(
        operation: "deleteData",
        additionalContext: LogMetadataDTOCollection().withPrivate(
          key: "identifier",
          value: identifier
        )
      )
    )

    if configuration.storageSucceeds {
      await logger.debug(
        "Deletion succeeded",
        context: CryptoLogContext(
          operation: "deleteData",
          additionalContext: LogMetadataDTOCollection().withPublic(
            key: "result",
            value: "success"
          )
        )
      )
      return .success(())
    } else {
      await logger.debug(
        "Deletion failed",
        context: CryptoLogContext(
          operation: "deleteData",
          additionalContext: LogMetadataDTOCollection().withPublic(
            key: "result",
            value: "failure"
          )
        )
      )
      return .failure(.operationFailed("Deletion failed"))
    }
  }

  /**
   Imports data into secure storage with a specific identifier.

   - Parameters:
     - data: The data to import.
     - customIdentifier: The identifier to use for storage.
   - Returns: The identifier used for storage (which might be the custom one or a derived one), or an error.
   */
  public func importData(
    _: Data,
    customIdentifier: String
  ) async -> Result<String, SecurityStorageError> {
    await logger.debug(
      "Importing data with custom identifier \(customIdentifier)",
      context: CryptoLogContext(
        operation: "importData",
        additionalContext: LogMetadataDTOCollection().withPrivate(
          key: "customIdentifier",
          value: customIdentifier
        )
      )
    )

    if configuration.storageSucceeds {
      await logger.debug(
        "Import succeeded",
        context: CryptoLogContext(
          operation: "importData",
          additionalContext: LogMetadataDTOCollection().withPublic(
            key: "result",
            value: "success"
          )
        )
      )
      return .success(customIdentifier)
    } else {
      await logger.debug(
        "Import failed",
        context: CryptoLogContext(
          operation: "importData",
          additionalContext: LogMetadataDTOCollection().withPublic(
            key: "result",
            value: "failure"
          )
        )
      )
      return .failure(.operationFailed("Import failed"))
    }
  }
}
