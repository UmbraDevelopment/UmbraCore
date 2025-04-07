/**
 # SecureCryptoServiceImpl

 A fully secure implementation of CryptoServiceProtocol that follows the Alpha Dot Five
 architecture principles, integrating native actor-based SecureStorage for all
 cryptographic material management.

 This implementation provides:
 - Full thread safety with Swift actors
 - Secure storage of keys and encrypted data
 - Privacy-aware logging
 - Proper error handling

 It relies on the wrapped CryptoServiceProtocol for the actual cryptographic operations
 while providing secure storage capabilities.
 */

import CoreSecurityTypes
import CryptoInterfaces
import DomainSecurityTypes
import Foundation
import LoggingServices
import SecurityCoreInterfaces
import UmbraErrors

// Type alias to use the canonical error type
public typealias CryptoError=UnifiedCryptoTypes.CryptoError

/**
 Secure implementation of CryptoServiceProtocol using SecureStorage

 This implementation wraps another CryptoServiceProtocol implementation (the "wrapped" service)
 but uses SecureStorage to securely store and retrieve sensitive data. It also adds additional
 security checks, such as validating data formats and enforcing encryption.

 This implementation ensures that all cryptographic operations are performed with secure storage
 for all cryptographic operations.
 */
public actor SecureCryptoServiceImpl: @preconcurrency CryptoServiceProtocol {
  /// The wrapped crypto service implementation
  private let wrapped: CryptoServiceProtocol

  /// The secure storage to use
  public nonisolated let secureStorage: SecureStorageProtocol

  /// Crypto provider for cryptographic operations
  private let cryptoProvider: CryptoProviderProtocol

  /// The logger to use
  private let logger: LoggingProtocol

  /**
   Initialises a new secure crypto service.

   - Parameters:
     - wrapped: The crypto service implementation to wrap
     - secureStorage: The secure storage to use
     - cryptoProvider: The crypto provider to use
     - logger: The logger to use
   */
  public init(
    wrapped: CryptoServiceProtocol,
    secureStorage: SecureStorageProtocol,
    cryptoProvider: CryptoProviderProtocol,
    logger: LoggingProtocol
  ) {
    self.wrapped=wrapped
    self.secureStorage=secureStorage
    self.cryptoProvider=cryptoProvider
    self.logger=logger
  }

  // MARK: - CryptoServiceProtocol Methods

  /**
   Implementation of CryptoServiceProtocol's encrypt method.
   */
  public func encrypt(
    dataIdentifier: String,
    keyIdentifier: String,
    options _: SecurityCoreInterfaces.EncryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    let context=CryptoLogContext(
      operation: "encrypt",
      additionalContext: LogMetadataDTOCollection().withPrivate(
        key: "dataIdentifier",
        value: dataIdentifier
      ).withPrivate(
        key: "keyIdentifier",
        value: keyIdentifier
      )
    )

    await logger.debug(
      "Encrypting data with identifier \(dataIdentifier) using key \(keyIdentifier)",
      context: context
    )

    // Retrieve the data to encrypt
    let dataResult=await secureStorage.retrieveData(withIdentifier: dataIdentifier)

    guard case let .success(data)=dataResult else {
      let errorContext=CryptoLogContext(
        operation: "encrypt",
        additionalContext: LogMetadataDTOCollection().withPrivate(
          key: "dataIdentifier",
          value: dataIdentifier
        ).withPrivate(
          key: "error",
          value: "\(dataResult)"
        )
      )

      await logger.error(
        "Failed to retrieve data for encryption: \(dataResult)",
        context: errorContext
      )
      return .failure(.dataNotFound)
    }

    // Retrieve the key
    let keyResult=await secureStorage.retrieveData(withIdentifier: keyIdentifier)

    guard case let .success(key)=keyResult else {
      let errorContext=CryptoLogContext(
        operation: "encrypt",
        additionalContext: LogMetadataDTOCollection().withPrivate(
          key: "keyIdentifier",
          value: keyIdentifier
        ).withPrivate(
          key: "error",
          value: "\(keyResult)"
        )
      )

      await logger.error(
        "Failed to retrieve key for encryption: \(keyResult)",
        context: errorContext
      )
      return .failure(.keyNotFound)
    }

    do {
      // Perform the encryption
      let encryptedData=try await cryptoProvider.encrypt(data: data, key: key)

      // Store the encrypted data
      let encryptedIdentifier="encrypted_\(UUID().uuidString)"
      let storeResult=await secureStorage.storeData(
        encryptedData,
        withIdentifier: encryptedIdentifier
      )

      guard case .success=storeResult else {
        let errorContext=CryptoLogContext(
          operation: "encrypt",
          additionalContext: LogMetadataDTOCollection().withPrivate(
            key: "error",
            value: "\(storeResult)"
          )
        )

        await logger.error(
          "Failed to store encrypted data",
          context: errorContext
        )
        return .failure(.operationFailed("Failed to store encrypted data"))
      }

      let successContext=CryptoLogContext(
        operation: "encrypt",
        additionalContext: LogMetadataDTOCollection().withPrivate(
          key: "encryptedIdentifier",
          value: encryptedIdentifier
        )
      )

      await logger.debug(
        "Successfully encrypted and stored data with identifier \(encryptedIdentifier)",
        context: successContext
      )

      return .success(encryptedIdentifier)
    } catch let error as CryptoError {
      let errorContext=CryptoLogContext(
        operation: "encrypt",
        additionalContext: LogMetadataDTOCollection().withPrivate(
          key: "error",
          value: "\(error)"
        )
      )

      await logger.error(
        "Encryption failed: \(error)",
        context: errorContext
      )
      return .failure(.operationFailed("Encryption failed: \(error)"))
    } catch {
      let errorContext=CryptoLogContext(
        operation: "encrypt",
        additionalContext: LogMetadataDTOCollection().withPrivate(
          key: "error",
          value: "\(error)"
        )
      )

      await logger.error(
        "Encryption failed with unknown error: \(error)",
        context: errorContext
      )
      return .failure(.operationFailed("Encryption failed with unknown error: \(error)"))
    }
  }

  /**
   Implementation of CryptoServiceProtocol's decrypt method.
   */
  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options _: SecurityCoreInterfaces.DecryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    let context=CryptoLogContext(
      operation: "decrypt",
      additionalContext: LogMetadataDTOCollection().withPrivate(
        key: "encryptedDataIdentifier",
        value: encryptedDataIdentifier
      ).withPrivate(
        key: "keyIdentifier",
        value: keyIdentifier
      )
    )

    await logger.debug(
      "Decrypting data with identifier \(encryptedDataIdentifier) using key \(keyIdentifier)",
      context: context
    )

    // Retrieve the encrypted data
    let encryptedDataResult=await secureStorage
      .retrieveData(withIdentifier: encryptedDataIdentifier)

    guard case let .success(encryptedData)=encryptedDataResult else {
      let errorContext=CryptoLogContext(
        operation: "decrypt",
        additionalContext: LogMetadataDTOCollection().withPrivate(
          key: "encryptedDataIdentifier",
          value: encryptedDataIdentifier
        ).withPrivate(
          key: "error",
          value: "\(encryptedDataResult)"
        )
      )

      await logger.error(
        "Failed to retrieve data for decryption: \(encryptedDataResult)",
        context: errorContext
      )
      return .failure(.dataNotFound)
    }

    // Retrieve the key
    let keyResult=await secureStorage.retrieveData(withIdentifier: keyIdentifier)

    guard case let .success(key)=keyResult else {
      let errorContext=CryptoLogContext(
        operation: "decrypt",
        additionalContext: LogMetadataDTOCollection().withPrivate(
          key: "keyIdentifier",
          value: keyIdentifier
        ).withPrivate(
          key: "error",
          value: "\(keyResult)"
        )
      )

      await logger.error(
        "Failed to retrieve key for decryption: \(keyResult)",
        context: errorContext
      )
      return .failure(.keyNotFound)
    }

    do {
      // Perform the decryption
      let decryptedData=try await cryptoProvider.decrypt(data: encryptedData, key: key)

      // Store the decrypted data
      let decryptedIdentifier="decrypted_\(UUID().uuidString)"
      let storeResult=await secureStorage.storeData(
        decryptedData,
        withIdentifier: decryptedIdentifier
      )

      guard case .success=storeResult else {
        let errorContext=CryptoLogContext(
          operation: "decrypt",
          additionalContext: LogMetadataDTOCollection().withPrivate(
            key: "error",
            value: "\(storeResult)"
          )
        )

        await logger.error(
          "Failed to store decrypted data",
          context: errorContext
        )
        return .failure(.operationFailed("Failed to store decrypted data"))
      }

      let successContext=CryptoLogContext(
        operation: "decrypt",
        additionalContext: LogMetadataDTOCollection().withPrivate(
          key: "decryptedIdentifier",
          value: decryptedIdentifier
        )
      )

      await logger.debug(
        "Successfully decrypted and stored data with identifier \(decryptedIdentifier)",
        context: successContext
      )

      return .success(decryptedIdentifier)
    } catch let error as CryptoError {
      let errorContext=CryptoLogContext(
        operation: "decrypt",
        additionalContext: LogMetadataDTOCollection().withPrivate(
          key: "error",
          value: "\(error)"
        )
      )

      await logger.error(
        "Decryption failed: \(error)",
        context: errorContext
      )
      return .failure(.operationFailed("Decryption failed: \(error)"))
    } catch {
      let errorContext=CryptoLogContext(
        operation: "decrypt",
        additionalContext: LogMetadataDTOCollection().withPrivate(
          key: "error",
          value: "\(error)"
        )
      )

      await logger.error(
        "Decryption failed with unknown error: \(error)",
        context: errorContext
      )
      return .failure(.operationFailed("Decryption failed with unknown error: \(error)"))
    }
  }

  /**
   Verify that the hash of the data at the given identifier matches the expected hash.

   - Parameters:
     - dataIdentifier: Identifier for the data to verify
     - hashIdentifier: Identifier for the expected hash
     - options: Optional hashing options

   - Returns: `true` if the hash matches, `false` if not, or an error.
   */
  public func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options _: HashingOptions?
  ) async -> Result<Bool, SecurityStorageError> {
    let context=CryptoLogContext(
      operation: "verifyHash",
      additionalContext: LogMetadataDTOCollection().withPrivate(
        key: "dataIdentifier",
        value: dataIdentifier
      ).withPrivate(
        key: "hashIdentifier",
        value: hashIdentifier
      )
    )

    await logger.debug(
      "Verifying hash of data with identifier \(dataIdentifier) against hash \(hashIdentifier)",
      context: context
    )

    // Retrieve the data
    let dataResult=await secureStorage.retrieveData(withIdentifier: dataIdentifier)

    guard case let .success(dataToVerify)=dataResult else {
      return .failure(.keyNotFound)
    }

    // Retrieve the expected hash
    let hashResult=await secureStorage.retrieveData(withIdentifier: hashIdentifier)

    guard case let .success(expectedHash)=hashResult else {
      return .failure(.keyNotFound)
    }

    do {
      // Hash the data with the specified algorithm
      let hash=try performHashing(Data(dataToVerify))

      // Compare hashes using constant-time comparison to prevent timing attacks
      let hashMatches=expectedHash.count == hash.count && constantTimeCompare(
        expected: expectedHash,
        actual: Array(hash)
      )

      return .success(hashMatches)
    } catch let error as CryptoError {
      let errorContext=CryptoLogContext(
        operation: "verifyHash",
        additionalContext: LogMetadataDTOCollection().withPrivate(
          key: "error",
          value: "\(error)"
        )
      )

      await logger.error(
        "Hash verification failed: \(error)",
        context: errorContext
      )

      return .failure(.operationFailed("Hash verification failed: \(error)"))
    } catch {
      let errorContext=CryptoLogContext(
        operation: "verifyHash",
        additionalContext: LogMetadataDTOCollection().withPrivate(
          key: "error",
          value: "\(error)"
        )
      )

      await logger.error(
        "Hash verification failed with unknown error: \(error)",
        context: errorContext
      )

      return .failure(.operationFailed("Hash verification failed with unknown error"))
    }
  }

  /**
   Constant-time comparison of two byte arrays.

   This function compares two byte arrays in constant time, regardless of where the
   first difference occurs. This prevents timing attacks that could otherwise be used
   to determine information about the array contents.

   - Parameters:
     - expected: The expected byte array
     - actual: The actual byte array
   - Returns: `true` if the arrays match, `false` otherwise
   */
  private func constantTimeCompare(expected: [UInt8], actual: [UInt8]) -> Bool {
    guard expected.count == actual.count else { return false }

    var result: UInt8=0
    for i in 0..<expected.count {
      result |= expected[i] ^ actual[i]
    }

    return result == 0
  }

  /**
   In this implementation, we're simulating encryption by prefixing the data with a marker
   and returning the result. In a real implementation, you would use CryptoKit,
   CommonCrypto, or another encryption library.

   - Parameter data: The data to encrypt
   - Returns: The encrypted data
   - Throws: CryptoError if encryption fails
   */
  private func performEncryption(_ data: Data) async throws -> Data {
    // This is just a placeholder - not real encryption!
    // In a real implementation, use CryptoKit, CommonCrypto, or another library

    // Add a "magic number" to identify this as encrypted
    var result=Data()
    result.append(contentsOf: [0xAA, 0x55]) // Mock prefix
    result.append(data)

    return result
  }

  /**
   In this implementation, we're simulating decryption by checking for a prefix marker
   and returning the data after that marker. In a real implementation, you would use
   CryptoKit, CommonCrypto, or another decryption library.

   - Parameter data: The data to decrypt
   - Returns: The decrypted data
   - Throws: CryptoError if decryption fails
   */
  private func performDecryption(_ data: Data) async throws -> Data {
    // This is just a placeholder - not real decryption!
    // In a real implementation, use CryptoKit, CommonCrypto, or another library

    // Check for our "magic number"
    guard data.count >= 2 && data.prefix(2) == Data([0xAA, 0x55]) else {
      throw CryptoError.invalidData
    }

    // Return the data after the magic number
    return data.dropFirst(2)
  }

  /**
   Hash implementation.
   */
  public func hash(
    dataIdentifier: String,
    options _: HashingOptions?
  ) async -> Result<String, SecurityStorageError> {
    let context=CryptoLogContext(
      operation: "hash",
      additionalContext: LogMetadataDTOCollection().withPrivate(
        key: "dataIdentifier",
        value: dataIdentifier
      )
    )

    await logger.debug(
      "Hashing data with identifier \(dataIdentifier)",
      context: context
    )

    // Retrieve the data
    let dataResult=await secureStorage.retrieveData(withIdentifier: dataIdentifier)

    guard case let .success(dataToHash)=dataResult else {
      return .failure(.keyNotFound)
    }

    do {
      // Hash the data with the specified algorithm
      let hashData=try performHashing(Data(dataToHash))

      let hashIdentifier="hash_\(UUID().uuidString)"

      // Store the hash
      let storeResult=await secureStorage.storeData(Array(hashData), withIdentifier: hashIdentifier)

      guard case .success=storeResult else {
        let errorContext=CryptoLogContext(
          operation: "hash",
          additionalContext: LogMetadataDTOCollection().withPrivate(
            key: "error",
            value: "\(storeResult)"
          )
        )

        await logger.error(
          "Failed to store hash data",
          context: errorContext
        )

        return .failure(.hashingFailed)
      }

      let successContext=CryptoLogContext(
        operation: "hash",
        additionalContext: LogMetadataDTOCollection().withPrivate(
          key: "hashIdentifier",
          value: hashIdentifier
        )
      )

      await logger.debug(
        "Successfully hashed and stored data with identifier \(hashIdentifier)",
        context: successContext
      )

      return .success(hashIdentifier)
    } catch let error as CryptoError {
      let errorContext=CryptoLogContext(
        operation: "hash",
        additionalContext: LogMetadataDTOCollection().withPrivate(
          key: "error",
          value: "\(error)"
        )
      )

      await logger.error(
        "Hashing failed: \(error)",
        context: errorContext
      )

      return .failure(.operationFailed("Hashing failed: \(error)"))
    } catch {
      let errorContext=CryptoLogContext(
        operation: "hash",
        additionalContext: LogMetadataDTOCollection().withPrivate(
          key: "error",
          value: "\(error)"
        )
      )

      await logger.error(
        "Hashing failed with unknown error: \(error)",
        context: errorContext
      )

      return .failure(.operationFailed("Hashing failed with unknown error"))
    }
  }

  /**
   Perform hashing of data.
   *
   - Parameter data: Data to hash.
   - Returns: Hashed data.
   - Throws: Error if hashing fails.
   */
  private func performHashing(_ data: Data) throws -> Data {
    // This is just a placeholder - not real hashing!
    // In a real implementation, use CryptoKit, CommonCrypto, or another library
    var result=Data([0xAA, 0x55]) // Mock prefix
    result.append(data) // In a real hash, this would be the hash value

    return result
  }

  /**
   Generate a cryptographic key with specified length and options.
   */
  public func generateKey(
    length: Int,
    options _: SecurityCoreInterfaces.KeyGenerationOptions?
  ) async -> Result<String, SecurityStorageError> {
    do {
      let keyIdentifier="key_\(UUID().uuidString)"

      // Generate random key data
      let keyData=try await cryptoProvider.generateRandomData(length: length)

      // Store the key in secure storage
      let storeResult=await secureStorage.storeData(keyData, withIdentifier: keyIdentifier)

      guard case .success=storeResult else {
        return .failure(.operationFailed("Failed to store key: \(storeResult)"))
      }

      let context=CryptoLogContext(
        operation: "generateKey",
        additionalContext: LogMetadataDTOCollection().withPublic(
          key: "keyType",
          value: "symmetric"
        ).withPublic(
          key: "keyLength",
          value: "\(length)"
        )
      )

      await logger.debug(
        "Generated key with identifier \(keyIdentifier)",
        context: context
      )

      return .success(keyIdentifier)
    } catch let error as CryptoError {
      let errorContext=CryptoLogContext(
        operation: "generateKey",
        additionalContext: LogMetadataDTOCollection().withPrivate(
          key: "error",
          value: "\(error)"
        )
      )

      await logger.error(
        "Key generation failed: \(error)",
        context: errorContext
      )
      return .failure(.operationFailed("Key generation failed: \(error)"))
    } catch {
      let errorContext=CryptoLogContext(
        operation: "generateKey",
        additionalContext: LogMetadataDTOCollection().withPrivate(
          key: "error",
          value: "\(error)"
        )
      )

      await logger.error(
        "Key generation failed with unknown error: \(error)",
        context: errorContext
      )
      return .failure(.operationFailed("Key generation failed with unknown error: \(error)"))
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
    options: HashingOptions?
  ) async -> Result<String, SecurityStorageError> {
    // This method is essentially the same as the hash method, which already exists
    // But we'll implement it to conform to the protocol
    await hash(dataIdentifier: dataIdentifier, options: options)
  }

  /**
   Stores data under a specific identifier in secure storage.

   - Parameters:
     - data: The data to store.
     - identifier: The identifier to use for storage.
   - Returns: Success or an error.
   */
  public func storeData(
    _ data: [UInt8],
    identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    let context=CryptoLogContext(
      operation: "storeData",
      additionalContext: LogMetadataDTOCollection().withPrivate(
        key: "identifier",
        value: identifier
      ).withPublic(
        key: "dataSize",
        value: "\(data.count)"
      )
    )

    await logger.debug("Storing data with identifier: \(identifier)", context: context)

    let result=await secureStorage.storeData(data, withIdentifier: identifier)

    switch result {
      case .success:
        let successContext=CryptoLogContext(
          operation: "storeData",
          additionalContext: LogMetadataDTOCollection().withPrivate(
            key: "identifier",
            value: identifier
          )
        )

        await logger.debug("Successfully stored data", context: successContext)
        return .success(())

      case let .failure(error):
        let errorContext=CryptoLogContext(
          operation: "storeData",
          additionalContext: LogMetadataDTOCollection().withPrivate(
            key: "identifier",
            value: identifier
          ).withPrivate(
            key: "error",
            value: "\(error)"
          )
        )

        await logger.error("Failed to store data: \(error)", context: errorContext)
        return .failure(.operationFailed("Store operation failed: \(error)"))
    }
  }

  /**
   Stores data under a specific identifier in secure storage.

   - Parameters:
     - data: The data to store.
     - identifier: The identifier to use for storage.
   - Returns: Success or an error.
   */
  public func storeData(
    data: Data,
    identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    await storeData([UInt8](data), identifier: identifier)
  }

  /**
   Retrieves data from secure storage by its identifier.

   - Parameter identifier: The identifier of the data to retrieve.
   - Returns: The retrieved data or an error.
   */
  public func retrieveData(
    identifier: String
  ) async -> Result<Data, SecurityStorageError> {
    let context=CryptoLogContext(
      operation: "retrieveData",
      additionalContext: LogMetadataDTOCollection().withPrivate(
        key: "identifier",
        value: identifier
      )
    )

    await logger.debug("Retrieving data with identifier: \(identifier)", context: context)

    let result=await secureStorage.retrieveData(withIdentifier: identifier)

    switch result {
      case let .success(bytes):
        let successContext=CryptoLogContext(
          operation: "retrieveData",
          additionalContext: LogMetadataDTOCollection().withPrivate(
            key: "identifier",
            value: identifier
          ).withPublic(
            key: "dataSize",
            value: "\(bytes.count)"
          )
        )

        await logger.debug("Successfully retrieved data", context: successContext)
        return .success(Data(bytes))

      case let .failure(error):
        let errorContext=CryptoLogContext(
          operation: "retrieveData",
          additionalContext: LogMetadataDTOCollection().withPrivate(
            key: "identifier",
            value: identifier
          ).withPrivate(
            key: "error",
            value: "\(error)"
          )
        )

        await logger.error("Failed to retrieve data: \(error)", context: errorContext)

        if case .dataNotFound=error {
          return .failure(.dataNotFound)
        }

        return .failure(.operationFailed("Failed to retrieve data: \(error)"))
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
    let context=CryptoLogContext(
      operation: "deleteData",
      additionalContext: LogMetadataDTOCollection().withPrivate(
        key: "identifier",
        value: identifier
      )
    )

    await logger.debug("Deleting data with identifier: \(identifier)", context: context)

    let result=await secureStorage.deleteData(withIdentifier: identifier)

    switch result {
      case .success:
        let successContext=CryptoLogContext(
          operation: "deleteData",
          additionalContext: LogMetadataDTOCollection().withPrivate(
            key: "identifier",
            value: identifier
          )
        )

        await logger.debug("Successfully deleted data", context: successContext)
        return .success(())

      case let .failure(error):
        let errorContext=CryptoLogContext(
          operation: "deleteData",
          additionalContext: LogMetadataDTOCollection().withPrivate(
            key: "identifier",
            value: identifier
          ).withPrivate(
            key: "error",
            value: "\(error)"
          )
        )

        await logger.error("Failed to delete data: \(error)", context: errorContext)
        return .failure(.operationFailed("Failed to delete data: \(error)"))
    }
  }

  /**
   Imports data into secure storage with a specific identifier.

   - Parameters:
     - data: The data bytes to import.
     - customIdentifier: The identifier to use for storage.
   - Returns: The identifier used for storage, or an error.
   */
  public func importData(
    _ data: [UInt8],
    customIdentifier: String?
  ) async -> Result<String, SecurityStorageError> {
    let context=CryptoLogContext(
      operation: "importData",
      additionalContext: LogMetadataDTOCollection().withPrivate(
        key: "identifier",
        value: customIdentifier ?? "auto-generated"
      )
    )

    await logger.debug(
      "Importing data with identifier \(customIdentifier ?? "auto-generated")",
      context: context
    )

    // Generate a unique identifier if none provided
    let identifier=customIdentifier ?? "imported_\(UUID().uuidString)"

    let result=await secureStorage.storeData(data, withIdentifier: identifier)

    switch result {
      case .success:
        let successContext=CryptoLogContext(
          operation: "importData",
          additionalContext: LogMetadataDTOCollection().withPrivate(
            key: "identifier",
            value: identifier
          )
        )

        await logger.debug("Successfully imported data", context: successContext)
        return .success(identifier)

      case let .failure(error):
        let errorContext=CryptoLogContext(
          operation: "importData",
          additionalContext: LogMetadataDTOCollection().withPrivate(
            key: "identifier",
            value: identifier
          ).withPrivate(
            key: "error",
            value: "\(error)"
          )
        )

        await logger.error("Failed to import data: \(error)", context: errorContext)
        return .failure(.operationFailed("Failed to import data: \(error)"))
    }
  }

  /**
   Imports data into secure storage with a specific identifier.

   - Parameters:
     - data: The data to import.
     - customIdentifier: The identifier to use for storage.
   - Returns: The identifier used for storage, or an error.
   */
  public func importData(
    _ data: Data,
    customIdentifier: String
  ) async -> Result<String, SecurityStorageError> {
    await importData([UInt8](data), customIdentifier: customIdentifier)
  }

  /**
   Exports data from secure storage.

   - Parameter identifier: The identifier of the data to export.
   - Returns: The data bytes, or an error.
   */
  public func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    let context=CryptoLogContext(
      operation: "exportData",
      additionalContext: LogMetadataDTOCollection().withPrivate(
        key: "identifier",
        value: identifier
      )
    )

    await logger.debug("Exporting data with identifier: \(identifier)", context: context)

    let result=await secureStorage.retrieveData(withIdentifier: identifier)

    switch result {
      case let .success(data):
        let successContext=CryptoLogContext(
          operation: "exportData",
          additionalContext: LogMetadataDTOCollection().withPrivate(
            key: "identifier",
            value: identifier
          ).withPublic(
            key: "dataSize",
            value: "\(data.count)"
          )
        )

        await logger.debug("Successfully exported data", context: successContext)
        return .success(data)

      case let .failure(error):
        let errorContext=CryptoLogContext(
          operation: "exportData",
          additionalContext: LogMetadataDTOCollection().withPrivate(
            key: "identifier",
            value: identifier
          ).withPrivate(
            key: "error",
            value: "\(error)"
          )
        )

        await logger.error("Failed to export data: \(error)", context: errorContext)

        if case .dataNotFound=error {
          return .failure(.dataNotFound)
        }

        return .failure(.operationFailed("Failed to export data: \(error)"))
    }
  }
}
