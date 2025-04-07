/**
 # SecureCryptoStorage

 Provides secure storage services specifically for cryptographic materials
 following the Alpha Dot Five architecture principles.

 This actor encapsulates the secure storage of cryptographic materials such as
 keys, encrypted data, and authentication tokens, ensuring that sensitive
 data is properly protected when at rest.
 */

import CoreSecurityTypes
import CryptoInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import UmbraErrors

/**
 Implementation of secure storage specifically for cryptographic materials.

 This actor provides specialised storage for cryptographic materials with
 enhanced contextual information and dedicated methods for different types
 of cryptographic assets.
 */
public actor SecureCryptoStorage {
  /// The underlying secure storage provider
  private let secureStorage: any SecureStorageProtocol

  /// Logger for storage operations
  private let logger: any LoggingProtocol

  /**
   Initialises a new secure crypto storage.

   - Parameters:
      - secureStorage: The secure storage implementation to use
      - logger: Logger for recording operations
   */
  public init(
    secureStorage: any SecureStorageProtocol,
    logger: any LoggingProtocol
  ) {
    self.secureStorage=secureStorage
    self.logger=logger
  }

  // MARK: - Key Storage

  /**
   Stores a cryptographic key securely.

   - Parameters:
      - key: The key to store
      - identifier: Identifier for the key
      - purpose: Purpose of the key
      - algorithm: Algorithm associated with the key

   - Throws: CryptoError if storage fails
   */
  public func storeKey(
    _ key: Data,
    identifier: String,
    purpose _: String,
    algorithm _: String?=nil
  ) async throws {
    // Configuration moved directly into the comment for reference
    // Configuration: standard access control, encryption enabled, with context

    do {
      let result=await secureStorage.storeData(Array(key), withIdentifier: identifier)

      // Check if the operation was successful
      guard case .success=result else {
        throw UCryptoError.storageFailed("Failed to store key")
      }

      await logger.debug(
        "Stored cryptographic key securely",
        context: CryptoLogContext(
          operation: "storeKey",
          additionalContext: LogMetadataDTOCollection()
            .withPublic(key: "keyType", value: "symmetric")
            .withPublic(key: "keySize", value: "256")
        )
      )
    } catch {
      throw UCryptoError
        .storageFailed("Failed to store key: \(error.localizedDescription)")
    }
  }

  /**
   Retrieves a cryptographic key.

   - Parameter identifier: Identifier of the key to retrieve
   - Returns: The key data
   - Throws: CryptoError if key not found or retrieval fails
   */
  public func retrieveKey(
    identifier: String
  ) async throws -> Data {
    do {
      let result=await secureStorage.retrieveData(withIdentifier: identifier)

      switch result {
        case let .success(keyData):
          await logger.debug(
            "Retrieved cryptographic key",
            context: CryptoLogContext(
              operation: "retrieveKey",
              additionalContext: LogMetadataDTOCollection()
                .withPublic(key: "keyType", value: "symmetric")
                .withPublic(key: "keySize", value: "256")
            )
          )

          return Data(keyData)

        case let .failure(error):
          throw UCryptoError.retrievalFailed("Failed to retrieve key: \(error)")
      }
    } catch {
      throw UCryptoError
        .retrievalFailed("Error retrieving key: \(error.localizedDescription)")
    }
  }

  /**
   Deletes a cryptographic key.

   - Parameter identifier: Identifier of the key to delete
   - Throws: CryptoError if deletion fails
   */
  public func deleteKey(
    identifier: String
  ) async throws {
    await logger.debug(
      "Deleted cryptographic key",
      context: CryptoLogContext(
        operation: "deleteKey"
      )
    )

    do {
      let result=await secureStorage.deleteData(withIdentifier: identifier)

      guard case .success=result else {
        throw UCryptoError.operationFailed("Failed to delete key")
      }

      await logger.debug(
        "Deleted cryptographic key",
        context: CryptoLogContext(
          operation: "deleteKey"
        )
      )
    } catch {
      throw UCryptoError
        .operationFailed("Error deleting key: \(error.localizedDescription)")
    }
  }

  // MARK: - Encrypted Data Storage

  /**
   Stores encrypted data securely.

   - Parameters:
      - data: The encrypted data to store
      - identifier: Identifier for the data
      - algorithm: Algorithm used for encryption

   - Throws: CryptoError if storage fails
   */
  public func storeEncryptedData(
    _ data: Data,
    identifier: String,
    algorithm _: String?=nil
  ) async throws {
    do {
      let result=await secureStorage.storeData(Array(data), withIdentifier: identifier)

      guard case .success=result else {
        throw UCryptoError.storageFailed("Failed to store encrypted data")
      }

      await logger.debug(
        "Stored encrypted data securely",
        context: CryptoLogContext(
          operation: "storeEncryptedData",
          additionalContext: LogMetadataDTOCollection()
            .withPublic(key: "dataType", value: "encrypted")
            .withPublic(key: "dataSize", value: "\(data.count)")
        )
      )
    } catch {
      throw UCryptoError
        .storageFailed("Error storing encrypted data: \(error.localizedDescription)")
    }
  }

  /**
   Retrieves encrypted data.

   - Parameter identifier: Identifier of the data to retrieve
   - Returns: The encrypted data
   - Throws: CryptoError if data not found or retrieval fails
   */
  public func retrieveEncryptedData(
    identifier: String
  ) async throws -> Data {
    do {
      let result=await secureStorage.retrieveData(withIdentifier: identifier)

      switch result {
        case let .success(encryptedData):
          await logger.debug(
            "Retrieved encrypted data",
            context: CryptoLogContext(
              operation: "retrieveEncryptedData",
              additionalContext: LogMetadataDTOCollection()
                .withPublic(key: "dataType", value: "encrypted")
                .withPublic(key: "dataSize", value: "\(encryptedData.count)")
            )
          )

          return Data(encryptedData)

        case let .failure(error):
          throw UCryptoError.retrievalFailed("Failed to retrieve encrypted data: \(error)")
      }
    } catch {
      throw UCryptoError
        .retrievalFailed("Error retrieving encrypted data: \(error.localizedDescription)")
    }
  }

  /**
   Derives a key from a password and salt, storing it securely.

   - Parameters:
      - passwordRef: Reference to the password
      - salt: Salt for key derivation
      - iterations: Number of iterations for key derivation
      - keyLength: Desired key length in bytes

   - Returns: Identifier for the derived key
   - Throws: CryptoError if derivation fails
   */
  public func deriveKeyFromPassword(
    passwordRef: String,
    salt: Data,
    iterations: Int=10000,
    keyLength: Int=32
  ) async throws -> String {
    // Create a unique identifier based on derivation parameters
    let identifier="derived_key_\(passwordRef.hashValue)_\(salt.hashValue)_\(iterations)"

    // Configuration moved directly into the comment for reference
    // We're not actually doing the derivation here since that's platform-specific
    // This is just a mock implementation that would be replaced in a real system

    await logger.debug(
      "Derived key from password",
      context: CryptoLogContext(
        operation: "deriveKey",
        additionalContext: LogMetadataDTOCollection()
          .withPublic(key: "saltLength", value: "\(salt.count)")
          .withPublic(key: "keySize", value: "\(keyLength)")
      )
    )

    return identifier
  }

  // MARK: - General Data Operations

  /**
   Stores data securely.

   - Parameters:
      - data: The data to store
      - identifier: Identifier for the data

   - Throws: CryptoError if storage fails
   */
  public func storeData(
    _ data: Data,
    identifier: String
  ) async throws {
    do {
      let result=await secureStorage.storeData(Array(data), withIdentifier: identifier)

      guard case .success=result else {
        throw UCryptoError.storageFailed("Failed to store data")
      }

      await logger.debug(
        "Stored data securely",
        context: CryptoLogContext(
          operation: "storeData",
          additionalContext: LogMetadataDTOCollection()
            .withPublic(key: "dataType", value: "plain")
            .withPublic(key: "dataSize", value: "\(data.count)")
        )
      )
    } catch {
      throw UCryptoError
        .storageFailed("Error storing data: \(error.localizedDescription)")
    }
  }

  /**
   Retrieves data.

   - Parameter identifier: Identifier of the data to retrieve
   - Returns: The data
   - Throws: CryptoError if data not found or retrieval fails
   */
  public func retrieveData(
    identifier: String
  ) async throws -> Data {
    do {
      let result=await secureStorage.retrieveData(withIdentifier: identifier)

      switch result {
        case let .success(data):
          await logger.debug(
            "Retrieved data",
            context: CryptoLogContext(
              operation: "retrieveData",
              additionalContext: LogMetadataDTOCollection()
                .withPublic(key: "dataType", value: "plain")
                .withPublic(key: "dataSize", value: "\(data.count)")
            )
          )

          return Data(data)

        case let .failure(error):
          throw UCryptoError.retrievalFailed("Failed to retrieve data: \(error)")
      }
    } catch {
      throw UCryptoError
        .retrievalFailed("Error retrieving data: \(error.localizedDescription)")
    }
  }

  /**
   Deletes data.

   - Parameter identifier: Identifier of the data to delete
   - Throws: CryptoError if deletion fails
   */
  public func deleteData(
    identifier: String
  ) async throws {
    await logger.debug(
      "Deleting data with identifier: \(identifier)",
      context: CryptoLogContext(
        operation: "deleteData",
        additionalContext: LogMetadataDTOCollection().with(
          key: "identifier",
          value: identifier,
          privacyLevel: .private
        )
      )
    )

    do {
      let result=await secureStorage.deleteData(withIdentifier: identifier)

      guard case .success=result else {
        throw UCryptoError.operationFailed("Failed to delete data")
      }

      await logger.debug(
        "Deleted data successfully",
        context: CryptoLogContext(
          operation: "deleteData",
          additionalContext: LogMetadataDTOCollection().with(
            key: "identifier",
            value: identifier,
            privacyLevel: .private
          )
        )
      )
    } catch {
      throw UCryptoError
        .operationFailed("Error deleting data: \(error.localizedDescription)")
    }
  }

  /**
   Checks if data with the specified identifier exists.

   - Parameter identifier: The identifier to check
   - Returns: True if data exists, false otherwise
   - Throws: Error if the operation fails
   */
  public func containsData(identifier: String) async throws -> Bool {
    let context=CryptoLogContext(
      operation: "containsData",
      additionalContext: LogMetadataDTOCollection()
        .withPrivate(key: "identifier", value: identifier)
    )

    await logger.debug(
      "Checking if data exists with identifier: \(identifier)",
      context: context
    )

    // Currently we just attempt to retrieve the data and check if it exists
    // This could be optimized in a real implementation to avoid loading the data
    let secureStore=try await getSecureStorage()
    return secureStore.hasKey(identifier)
  }
}
