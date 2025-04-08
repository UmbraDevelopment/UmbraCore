import CoreSecurityTypes
import CryptoInterfaces
import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import Security
import UmbraErrors
import CommonCrypto

/**
 Default implementation of CryptoServiceProtocol using SecureStorageProtocol.

 This implementation provides a standard set of cryptographic operations using
 the provided secure storage for persisting cryptographic materials. It serves
 as the baseline implementation when more specialised providers aren't selected.
 */
public actor DefaultCryptoServiceImpl: CryptoServiceProtocol {
  /// The secure storage to use
  public let secureStorage: SecureStorageProtocol

  /// Optional logger
  private let logger: LoggingProtocol?

  // Store the provider type if needed for logic
  private let providerType: CoreSecurityTypes.SecurityProviderType = .basic

  /**
   Initialises the crypto service.
   */
  public init(
    secureStorage: SecureStorageProtocol,
    logger: LoggingProtocol? = nil
  ) {
    self.secureStorage = secureStorage
    self.logger = logger
  }

  // MARK: - CryptoServiceProtocol Conformance (Corrected Signatures)

  // Corrected encrypt signature and implementation details
  public func encrypt(
    dataIdentifier: String,
    keyIdentifier: String,
    options: CoreSecurityTypes.EncryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    let context: BaseLogContextDTO = BaseLogContextDTO(
      domainName: "CryptoService",
      source: "DefaultCryptoServiceImpl.encrypt",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "dataIdentifier", value: dataIdentifier)
        .withPrivate(key: "keyIdentifier", value: keyIdentifier)
        .withPublic(key: "options", value: String(describing: options))
    )

    await logger?.log(
      .debug,
      "Encrypting data for identifier: \(dataIdentifier) with key: \(keyIdentifier)",
      context: context
    )

    // --- Mock Implementation ---
    // Retrieve original data first
    let originalDataResult: Result<[UInt8], SecurityStorageError> = await secureStorage.retrieveData(withIdentifier: dataIdentifier)
    guard case let .success(originalData) = originalDataResult else {
      if case let .failure(error) = originalDataResult {
        await logger?.log(.error, "Failed to retrieve original data for encryption: \(error)", context: context)
        return .failure(error) // Pass storage error directly
      } else {
        await logger?.log(.error, "Failed to retrieve original data for encryption due to unknown error state", context: context)
        return .failure(.storageUnavailable) // Or another suitable error
      }
    }

    // Create mock encrypted data
    var encryptedDataBytes = [UInt8]()
    let iv = generateRandomBytes(count: 16)
    encryptedDataBytes.append(contentsOf: iv)
    encryptedDataBytes.append(contentsOf: originalData) // Use retrieved data bytes
    let keyIDBytes = Array(keyIdentifier.utf8)
    encryptedDataBytes.append(UInt8(keyIDBytes.count))
    encryptedDataBytes.append(contentsOf: keyIDBytes)

    // Store the mock encrypted data
    let encryptedDataStoreIdentifier = "encrypted_\(UUID().uuidString)"
    let storeResult = await secureStorage.storeData(
      encryptedDataBytes, // Use [UInt8] directly
      withIdentifier: encryptedDataStoreIdentifier
    )

    switch storeResult {
      case .success:
        await logger?.log(.info, "Successfully encrypted data to identifier: \(encryptedDataStoreIdentifier)", context: context)
        return .success(encryptedDataStoreIdentifier)
      case .failure(let error):
        await logger?.log(.error, "Failed to store encrypted data: \(error)", context: context)
        return .failure(error) // Pass storage error directly
    }
  }

  // Corrected decrypt signature and implementation details
  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options: CoreSecurityTypes.DecryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    let context: BaseLogContextDTO = BaseLogContextDTO(
      domainName: "CryptoService",
      source: "DefaultCryptoServiceImpl.decrypt",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "encryptedDataIdentifier", value: encryptedDataIdentifier)
        .withPrivate(key: "keyIdentifier", value: keyIdentifier)
        .withPublic(key: "options", value: String(describing: options))
    )

    await logger?.log(
      .debug,
      "Decrypting data with identifier: \(encryptedDataIdentifier) using key: \(keyIdentifier)",
      context: context
    )

    // Retrieve the encrypted data
    let dataResult: Result<[UInt8], SecurityStorageError> = await secureStorage.retrieveData(
      withIdentifier: encryptedDataIdentifier // Use correct method name
    )

    switch dataResult {
      case let .success(encryptedDataBytes):
        // --- Mock Implementation ---
        // Assuming format: [IV (16 bytes)][Data][Key ID Length (1 byte)][Key ID]
        if encryptedDataBytes.count > 17 {
          let dataStartIndex = 16
          guard let keyIDLengthByte = encryptedDataBytes.last else {
              await logger?.log(.error, "Invalid encrypted data format: missing key ID length", context: context)
              return .failure(.decryptionFailed)
          }
          let keyIDLength = Int(keyIDLengthByte)
          let keyIDStartIndex = encryptedDataBytes.count - 1 - keyIDLength

          // Basic validation
          guard keyIDStartIndex > dataStartIndex, keyIDStartIndex < encryptedDataBytes.count - 1 else {
              await logger?.log(.error, "Invalid encrypted data format: key ID length mismatch", context: context)
              return .failure(.decryptionFailed)
          }

          let decryptedDataBytes = Array(encryptedDataBytes[dataStartIndex..<keyIDStartIndex])
          // Store decrypted data and return its ID
          let decryptedDataIdentifier = "decrypted_\(UUID().uuidString)"
          let storeDecryptedResult = await secureStorage.storeData(
             decryptedDataBytes, // Use [UInt8]
             withIdentifier: decryptedDataIdentifier
          )

          switch storeDecryptedResult {
          case .success:
              await logger?.log(.info, "Successfully decrypted data to identifier: \(decryptedDataIdentifier)", context: context)
              return .success(decryptedDataIdentifier)
          case .failure(let error):
              await logger?.log(.error, "Failed to store decrypted data: \(error)", context: context)
              return .failure(error) // Pass storage error directly
          }

        } else {
          await logger?.log(
            .error,
            "Invalid encrypted data format",
            context: context
          )
          // Use a more specific error from SecurityStorageError if available, or .decryptionFailed
          return .failure(.decryptionFailed)
        }

      case .failure(let error):
        await logger?.log(
          .error,
          "Failed to retrieve encrypted data for decryption: \(error)",
          context: context
        )
        return .failure(error) // Pass storage error directly
    }
  }

  // Renamed to hash, corrected signature and implementation details
  public func hash(
    dataIdentifier: String,
    options: CoreSecurityTypes.HashingOptions?
  ) async -> Result<String, SecurityStorageError> {
    let algorithm: CoreSecurityTypes.HashAlgorithm = options?.algorithm ?? .sha256 // Get algorithm from options

    let context: BaseLogContextDTO = BaseLogContextDTO(
      domainName: "CryptoService",
      source: "DefaultCryptoServiceImpl.hash",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "dataIdentifier", value: dataIdentifier)
        .withPublic(key: "algorithm", value: String(describing: algorithm))
        .withPublic(key: "options", value: String(describing: options))
    )

    await logger?.log(
      .debug,
      "Generating hash for data identifier: \(dataIdentifier) with algorithm: \(algorithm)",
      context: context
    )

    // --- Mock Implementation ---
    // Retrieve original data first (needed for hashing)
    let originalDataResult: Result<[UInt8], SecurityStorageError> = await secureStorage.retrieveData(withIdentifier: dataIdentifier)
    guard case .success = originalDataResult else {
      if case let .failure(error) = originalDataResult {
        await logger?.log(.error, "Failed to retrieve original data for hashing: \(error)", context: context)
        return .failure(error) // Pass storage error directly
      } else {
        await logger?.log(.error, "Failed to retrieve original data for hashing due to unknown error state", context: context)
        return .failure(.storageUnavailable)
      }
    }

    // Generate mock hash based on retrieved data (length used as simple example)
    var generatedHash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    _ = originalDataResult.success?.withUnsafeBytes { // Use withUnsafeBytes for [UInt8]
        CC_SHA256($0.baseAddress, CC_LONG(originalDataResult.success?.count ?? 0), &generatedHash)
    }

    // Store the hash
    let hashIdentifier: String = "hash_\(UUID().uuidString)"
    let storeResult: Result<Void, SecurityStorageError> = await secureStorage.storeData(
      generatedHash, // Use [UInt8]
      withIdentifier: hashIdentifier
    )

    switch storeResult {
      case .success:
        await logger?.log(.info, "Successfully stored hash to identifier: \(hashIdentifier)", context: context)
        return .success(hashIdentifier)
      case .failure(let error):
        await logger?.log(.error, "Failed to store hash: \(error)", context: context)
        return .failure(error) // Pass storage error directly
    }
  }

  // Corrected storeData signature and implementation details
  public func storeData(
    data: Data,
    identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    let context: BaseLogContextDTO = BaseLogContextDTO(
      domainName: "CryptoService",
      source: "DefaultCryptoServiceImpl.storeData",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "identifier", value: identifier)
        .withPrivate(key: "data_size", value: String(data.count)) // Convert Int to String
    )

    await logger?.log(.debug, "Storing data with identifier: \(identifier)", context: context)
    // Use the correct storage method
    let result: Result<Void, SecurityStorageError> = await secureStorage.storeData(
        [UInt8](data), // Convert Data to [UInt8] for the protocol
        withIdentifier: identifier
    )

    if case .failure(let error) = result {
       await logger?.log(.error, "Failed to store data: \(error)", context: context)
    } else {
       await logger?.log(.info, "Successfully stored data for identifier: \(identifier)", context: context)
    }
    return result
  }

  // Corrected retrieveData signature and implementation details
  public func retrieveData(
    identifier: String
  ) async -> Result<Data, SecurityStorageError> { // Protocol expects Data
    let context: BaseLogContextDTO = BaseLogContextDTO(
      domainName: "CryptoService",
      source: "DefaultCryptoServiceImpl.retrieveData",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "identifier", value: identifier)
    )

    await logger?.log(.debug, "Retrieving data with identifier: \(identifier)", context: context)
    // Use the correct storage method and map result
    let result: Result<[UInt8], SecurityStorageError> = await secureStorage.retrieveData(withIdentifier: identifier)

    // Handle result and map error synchronously after await
    switch result {
      case let .success(bytes):
        return .success(Data(bytes))
      case .failure(let error):
        await logger?.log(.error, "Failed to retrieve data: \(error)", context: context)
        return .failure(error) // Pass storage error directly
    }
  }

  // Corrected deleteData signature and implementation details
  public func deleteData(
    identifier: String
  ) async -> Result<Void, SecurityStorageError> {
     let context: BaseLogContextDTO = BaseLogContextDTO(
      domainName: "CryptoService",
      source: "DefaultCryptoServiceImpl.deleteData",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "identifier", value: identifier)
    )
    await logger?.log(.debug, "Deleting data with identifier: \(identifier)", context: context)
    let result: Result<Void, SecurityStorageError> = await secureStorage.deleteData(withIdentifier: identifier) // Use correct method
    if case .failure(let error) = result {
       await logger?.log(.error, "Failed to delete data: \(error)", context: context)
    } else {
       await logger?.log(.info, "Successfully deleted data for identifier: \(identifier)", context: context)
    }
    return result
  }

  // Added for protocol conformance
  public func generateHash(
    dataIdentifier: String,
    options: CoreSecurityTypes.HashingOptions?
  ) async -> Result<String, SecurityStorageError> {
    let context: BaseLogContextDTO = BaseLogContextDTO(domainName: "CryptoService", source: "DefaultCryptoServiceImpl.generateHash")
    await logger?.log(.warning, "generateHash is not implemented by default", context: context)
    // This should ideally use the `hash` method's logic, but returning unsupported for now.
    return .failure(.unsupportedOperation) // Or delegate to self.hash?
  }

  // Added for protocol conformance
  public func importData(
    _ data: Data,
    customIdentifier: String
  ) async -> Result<String, SecurityStorageError> {
    let context: LogContextDTO = LogContextDTO(subsystem: "CryptoService", category: "Import")
    await logger?.debug("Importing raw data with custom identifier: \(customIdentifier)", context: context)
    // Store the raw data using the secure storage protocol
    let result: Result<Void, SecurityStorageError> = await secureStorage.storeData([UInt8](data), withIdentifier: customIdentifier)
    switch result {
      case .success:
        return .success(customIdentifier)
      case .failure(let error):
        await logger?.error("Failed to import raw data: \(error.description)", context: context)
        return .failure(error) // Pass the storage error through
    }
  }

  // Conforms to: func importData(_ data: [UInt8], customIdentifier: String?) async -> Result<String, SecurityStorageError>
  public func importData(
    _ data: [UInt8],
    customIdentifier: String?
  ) async -> Result<String, SecurityStorageError> {
    let context: LogContextDTO = LogContextDTO(subsystem: "CryptoService", category: "Import")
    await logger?.debug("Importing [UInt8] data...", context: context)
    // Convert [UInt8] to Data for storage
    let dataToStore = Data(data)
    // Determine the identifier to use
    let effectiveIdentifier = customIdentifier ?? UUID().uuidString

    // Use the secure storage protocol to store the data
    let result: Result<Void, SecurityStorageError> = await secureStorage.storeData([UInt8](dataToStore), withIdentifier: effectiveIdentifier)

    // Handle the result and return appropriately
    switch result {
      case .success:
        await logger?.debug("Successfully imported data with identifier: \(effectiveIdentifier)", context: context)
        return .success(effectiveIdentifier)
      case .failure(let error):
        await logger?.error("Failed to import data: \(error.description)", context: context)
        // Map StorageCoreError to SecurityStorageError if needed, or pass through
        return .failure(error) // Assuming SecureStorageError is compatible or wrapping occurs
    }
  }

  // Conforms to: func exportData(identifier: String) async -> Result<[UInt8], SecurityStorageError>
  public func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    let context: LogContextDTO = LogContextDTO(subsystem: "CryptoService", category: "Export")
    await logger?.debug("Exporting data with identifier: \(identifier)", context: context)
    let result = await secureStorage.retrieveData(withIdentifier: identifier)
    switch result {
      case .success(let data):
        return .success(Array(data)) // Convert Data to [UInt8]
      case .failure(let error):
        await logger?.error("Failed to export data: \(error.description)", context: context)
        // Map StorageCoreError to SecurityStorageError or pass through
        return .failure(error)
    }
  }

  // MARK: - Helper Methods (Example - Needs actual implementation)

  /**
   Generates cryptographically secure random bytes.
   - Parameter count: The number of bytes to generate.
   - Returns: A Data object containing the random bytes.
   */
  private func generateRandomBytes(count: Int) -> [UInt8] {
    var bytes = [UInt8](repeating: 0, count: count)
    let status = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
    if status == errSecSuccess {
      return bytes
    } else {
      // Fallback or handle error appropriately
      let context = BaseLogContextDTO(
        domainName: "CryptoService",
        source: "DefaultCryptoServiceImpl.generateRandomBytes",
        metadata: LogMetadataDTOCollection()
          .withPublic(key: "requestedByteCount", value: count)
          .withPublic(key: "errorCode", value: status)
      )
      await logger?.log(.error, "Failed to generate secure random bytes, status: \(status)", context: context)
      // Returning non-secure bytes as a fallback - consider throwing an error instead
      return [UInt8](repeating: 0, count: count)
    }
  }

  // MARK: - Missing CryptoServiceProtocol Methods

  public func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options _: CoreSecurityTypes.HashingOptions? = nil
  ) async -> Result<Bool, SecurityStorageError> {
    let context: BaseLogContextDTO = BaseLogContextDTO(
      domainName: "CryptoService",
      source: "DefaultCryptoServiceImpl.verifyHash",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "dataIdentifier", value: dataIdentifier)
        .withPublic(key: "hashIdentifier", value: hashIdentifier)
    )
    await logger?.log(
      .debug,
      "Verifying hash for data \(dataIdentifier) against hash \(hashIdentifier)", context: context
    )
    // 1. Retrieve original data
    let dataResult = await secureStorage.retrieveData(withIdentifier: dataIdentifier)
    guard case .success(let originalData) = dataResult else {
      await logger?.log(.error, "Failed to retrieve original data for hash verification", context: context)
      // Correct Result error handling
      if case let .failure(error) = dataResult {
         return .failure(error)
      }
      return .failure(.dataNotFound) // Use correct error case without associated value
    }

    // 2. Retrieve stored hash
    let hashResult = await secureStorage.retrieveData(withIdentifier: hashIdentifier)
    guard case .success(let storedHash) = hashResult else {
      await logger?.log(.error, "Failed to retrieve stored hash for verification", context: context)
      // Correct Result error handling
      if case let .failure(error) = hashResult {
         return .failure(error)
      }
      return .failure(.dataNotFound) // Use correct error case without associated value
    }

    // 3. Generate hash of original data using CommonCrypto
    var generatedHash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    _ = originalData.withUnsafeBytes { // Use withUnsafeBytes for [UInt8]
        CC_SHA256($0.baseAddress, CC_LONG(originalData.count), &generatedHash)
    }

    // 4. Compare hashes
    let hashesMatch = generatedHash == storedHash
    await logger?.log(.info, "Hash verification result: \(hashesMatch)", context: context)
    return .success(hashesMatch)
  }

  // Note: generateKey needs the optional options parameter
  public func generateKey(
    length: Int,
    options _: CoreSecurityTypes.KeyGenerationOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    let context: BaseLogContextDTO = BaseLogContextDTO(
      domainName: "CryptoService",
      source: "DefaultCryptoServiceImpl.generateKey",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "length", value: length)
    )
    await logger?.log(.debug, "Generating key of length \(length)...", context: context)
    let keyData = generateRandomBytes(count: length)
    let keyIdentifier = "key_\(UUID().uuidString)"
    let storeResult = await secureStorage.storeData(keyData, withIdentifier: keyIdentifier)

    switch storeResult {
      case .success:
        await logger?.log(.info, "Successfully generated and stored key with id: \(keyIdentifier)", context: context)
        return .success(keyIdentifier)
      case .failure(let error):
        await logger?.log(.error, "Failed to store generated key: \(error.description)", context: context)
        return .failure(error)
    }
  }
}
