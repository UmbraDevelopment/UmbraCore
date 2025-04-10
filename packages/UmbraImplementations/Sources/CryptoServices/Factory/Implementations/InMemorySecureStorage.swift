import CryptoKit
import CryptoLogger
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces

/**
 A secure in-memory implementation of SecureStorageProtocol.

 This implementation stores all data in memory with encryption at rest,
 providing confidentiality and integrity protection. It does not persist
 data between app runs but ensures that data is protected while in memory.

 It follows the Alpha Dot Five architecture principles:
 - Data encryption at rest using AES-GCM for authenticated encryption
 - Privacy-aware logging for sensitive operations
 - Actor-based concurrency for thread safety
 - Type-safe interfaces with proper error handling
 */
public actor InMemorySecureStorage: SecureStorageProtocol {
  /// Encrypted in-memory storage dictionary
  private var encryptedStorage: [String: EncryptedItem]=[:]

  /// Master encryption key for data at rest
  private let masterKey: SymmetricKey

  /// Base URL for virtual storage (used for logging only)
  private let baseURL: URL

  /// Logger for operations
  private let logger: PrivacyAwareLoggingProtocol

  /**
   Struct representing encrypted data and metadata.
   */
  private struct EncryptedItem {
    /// The sealed box containing the encrypted data and authentication tag
    let sealedBox: AES.GCM.SealedBox

    /// When the item was last modified
    let lastModified: Date

    /**
     Initialises a new encrypted item with the given sealed box.
     */
    init(sealedBox: AES.GCM.SealedBox) {
      self.sealedBox=sealedBox
      lastModified=Date()
    }

    /**
     Extracts the ciphertext from the sealed box.
     */
    var ciphertext: Data {
      sealedBox.ciphertext
    }

    /**
     Returns the size of the encrypted data in bytes.
     */
    var size: Int {
      sealedBox.ciphertext.count + sealedBox.tag.count + Data(sealedBox.nonce).count
    }
  }

  /**
   Initialises a new in-memory secure storage with encryption.

   - Parameters:
     - logger: Logger for operation tracking
     - baseURL: Optional base URL for virtual storage location (used in logs)
     - masterKeyData: Optional master key for encryption, generated if not provided
   */
  public init(
    logger: PrivacyAwareLoggingProtocol,
    baseURL: URL=URL(string: "memory://secure-storage")!,
    masterKeyData: Data?=nil
  ) {
    self.logger=logger
    self.baseURL=baseURL

    // Use provided master key or generate a new one
    if let keyData=masterKeyData {
      masterKey=SymmetricKey(data: keyData)
    } else {
      // Generate a secure AES-256 key for encryption
      masterKey=SymmetricKey(size: .bits256)
    }
  }

  /**
   Securely stores data with encryption using AES-GCM.

   - Parameters:
     - data: The data to store
     - identifier: The identifier to associate with the data
   - Returns: Success or failure with error information
   */
  public func storeData(
    _ data: [UInt8],
    withIdentifier identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    let context=CryptoLogContext(
      operation: "storeData",
      identifier: identifier,
      status: "started",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "dataSize", value: String(data.count))
        .withPublic(key: "storageLocation", value: baseURL.absoluteString)
    )

    await logger.debug("Storing data with encryption", context: context)

    do {
      // Validate the identifier
      guard !identifier.isEmpty else {
        throw SecurityStorageError.invalidIdentifier(reason: "Empty identifier not allowed")
      }

      // Convert byte array to Data for encryption
      let plainData=Data(data)

      // Encrypt the data using AES-GCM
      let sealedBox=try AES.GCM.seal(plainData, using: masterKey)

      // Store the encrypted data
      let encryptedItem=EncryptedItem(sealedBox: sealedBox)
      encryptedStorage[identifier]=encryptedItem

      let successContext=CryptoLogContext(
        operation: "storeData",
        identifier: identifier,
        status: "success",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "dataSize", value: String(data.count))
          .withPublic(key: "encryptedSize", value: String(encryptedItem.size))
          .withPublic(key: "storageLocation", value: baseURL.absoluteString)
      )

      await logger.debug("Data encrypted and stored successfully", context: successContext)
      return .success(())
    } catch {
      let errorContext=CryptoLogContext(
        operation: "storeData",
        identifier: identifier,
        status: "error",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "error", value: "\(type(of: error))")
          .withPublic(key: "errorMessage", value: error.localizedDescription)
      )

      await logger.error("Failed to encrypt and store data", context: errorContext)

      if let storageError=error as? SecurityStorageError {
        return .failure(storageError)
      } else {
        return .failure(.storageFailure(reason: "Encryption failed: \(error.localizedDescription)"))
      }
    }
  }

  /**
   Retrieves and decrypts data associated with the given identifier.

   - Parameter identifier: The identifier for the data to retrieve
   - Returns: The decrypted data or an error
   */
  public func retrieveData(
    withIdentifier identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    let context=CryptoLogContext(
      operation: "retrieveData",
      identifier: identifier,
      status: "started",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "storageLocation", value: baseURL.absoluteString)
    )

    await logger.debug("Retrieving encrypted data", context: context)

    do {
      // Validate the identifier
      guard !identifier.isEmpty else {
        throw SecurityStorageError.invalidIdentifier(reason: "Empty identifier not allowed")
      }

      // Get the encrypted data
      guard let encryptedItem=encryptedStorage[identifier] else {
        throw SecurityStorageError.identifierNotFound(identifier: identifier)
      }

      // Decrypt the data
      let decryptedData=try AES.GCM.open(encryptedItem.sealedBox, using: masterKey)

      // Convert to byte array
      let result=[UInt8](decryptedData)

      let successContext=CryptoLogContext(
        operation: "retrieveData",
        identifier: identifier,
        status: "success",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "encryptedSize", value: String(encryptedItem.size))
          .withPublic(key: "decryptedSize", value: String(result.count))
          .withPublic(key: "storageLocation", value: baseURL.absoluteString)
      )

      await logger.debug("Data retrieved and decrypted successfully", context: successContext)
      return .success(result)
    } catch {
      let errorContext=CryptoLogContext(
        operation: "retrieveData",
        identifier: identifier,
        status: "error",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "error", value: "\(type(of: error))")
          .withPublic(key: "errorMessage", value: error.localizedDescription)
      )

      await logger.error("Failed to retrieve or decrypt data", context: errorContext)

      if let storageError=error as? SecurityStorageError {
        return .failure(storageError)
      } else if error is CryptoKit.CryptoKitError {
        return .failure(.storageFailure(reason: "Decryption failed: \(error.localizedDescription)"))
      } else {
        return .failure(.generalError(reason: error.localizedDescription))
      }
    }
  }

  /**
   Securely deletes the data associated with an identifier.

   - Parameter identifier: The identifier of the data to delete
   - Returns: Success or an error
   */
  public func deleteData(
    withIdentifier identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    let context=CryptoLogContext(
      operation: "deleteData",
      identifier: identifier,
      status: "started",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "storageLocation", value: baseURL.absoluteString)
    )

    await logger.debug("Deleting encrypted data", context: context)

    do {
      // Validate the identifier
      guard !identifier.isEmpty else {
        throw SecurityStorageError.invalidIdentifier(reason: "Empty identifier not allowed")
      }

      // Check if the data exists
      guard encryptedStorage[identifier] != nil else {
        throw SecurityStorageError.identifierNotFound(identifier: identifier)
      }

      // Remove the data
      encryptedStorage.removeValue(forKey: identifier)

      let successContext=CryptoLogContext(
        operation: "deleteData",
        identifier: identifier,
        status: "success",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "storageLocation", value: baseURL.absoluteString)
      )

      await logger.debug("Encrypted data deleted successfully", context: successContext)
      return .success(())
    } catch {
      let errorContext=CryptoLogContext(
        operation: "deleteData",
        identifier: identifier,
        status: "error",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "error", value: "\(type(of: error))")
          .withPublic(key: "errorMessage", value: error.localizedDescription)
      )

      await logger.error("Failed to delete encrypted data", context: errorContext)

      if let storageError=error as? SecurityStorageError {
        return .failure(storageError)
      } else {
        return .failure(.generalError(reason: error.localizedDescription))
      }
    }
  }

  /**
   Lists all identifiers in the secure storage.

   - Returns: Array of identifiers or an error
   */
  public func listDataIdentifiers() async -> Result<[String], SecurityStorageError> {
    let context=CryptoLogContext(
      operation: "listDataIdentifiers",
      status: "started",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "storageLocation", value: baseURL.absoluteString)
    )

    await logger.debug("Listing all encrypted data identifiers", context: context)

    let identifiers=Array(encryptedStorage.keys)

    let successContext=CryptoLogContext(
      operation: "listDataIdentifiers",
      status: "success",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "count", value: String(identifiers.count))
        .withPublic(key: "storageLocation", value: baseURL.absoluteString)
    )

    await logger.debug("Retrieved all encrypted data identifiers", context: successContext)
    return .success(identifiers)
  }

  /**
   Exports the encrypted data directly without decryption.
   Useful for backup operations.

   - Parameter identifier: Identifier of the data to export
   - Returns: The encrypted data bytes or an error
   */
  public func exportData(withIdentifier identifier: String) async
  -> Result<[UInt8], SecurityStorageError> {
    let context=CryptoLogContext(
      operation: "exportData",
      identifier: identifier,
      status: "started",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "storageLocation", value: baseURL.absoluteString)
    )

    await logger.debug("Exporting encrypted data", context: context)

    do {
      // Validate the identifier
      guard !identifier.isEmpty else {
        throw SecurityStorageError.invalidIdentifier(reason: "Empty identifier not allowed")
      }

      // Check if the data exists
      guard let encryptedItem=encryptedStorage[identifier] else {
        throw SecurityStorageError.identifierNotFound(identifier: identifier)
      }

      // Export as combined format: nonce + ciphertext + tag
      var exportData=Data()
      exportData.append(contentsOf: encryptedItem.sealedBox.nonce)
      exportData.append(encryptedItem.sealedBox.ciphertext)
      exportData.append(encryptedItem.sealedBox.tag)

      let result=[UInt8](exportData)

      let successContext=CryptoLogContext(
        operation: "exportData",
        identifier: identifier,
        status: "success",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "dataSize", value: String(result.count))
          .withPublic(key: "storageLocation", value: baseURL.absoluteString)
      )

      await logger.debug("Encrypted data exported successfully", context: successContext)
      return .success(result)
    } catch {
      let errorContext=CryptoLogContext(
        operation: "exportData",
        identifier: identifier,
        status: "error",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "error", value: "\(type(of: error))")
          .withPublic(key: "errorMessage", value: error.localizedDescription)
      )

      await logger.error("Failed to export encrypted data", context: errorContext)

      if let storageError=error as? SecurityStorageError {
        return .failure(storageError)
      } else {
        return .failure(.generalError(reason: error.localizedDescription))
      }
    }
  }
}
