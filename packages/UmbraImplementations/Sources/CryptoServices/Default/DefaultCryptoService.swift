import BuildConfig
import CoreSecurityTypes
import CryptoInterfaces
import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces

/// A default implementation of CryptoServiceProtocol that provides basic
/// cryptographic operations.
///
/// This implementation is intended as a minimal starting point and reference
/// implementation. For production use, consider using one of the more comprehensive
/// implementations with enhanced security features.
///
/// Note: This implementation may not provide all security features mentioned
/// in the protocol definition.
public actor DefaultCryptoService: CryptoServiceProtocol {
  /// The secure storage to use
  public let secureStorage: SecureStorageProtocol

  /// The logger to use
  private let logger: LoggingProtocol?

  /// Creates a new default crypto service.
  ///
  /// - Parameters:
  ///   - secureStorage: The secure storage implementation to use
  ///   - logger: Optional logger for operation tracking
  public init(
    secureStorage: SecureStorageProtocol,
    logger: LoggingProtocol?=nil
  ) {
    self.secureStorage=secureStorage
    self.logger=logger
  }

  /// Encrypts data with the given key.
  ///
  /// This method retrieves the data and key from secure storage using their identifiers,
  /// encrypts the data, and stores the result back in secure storage.
  ///
  /// - Parameters:
  ///   - dataIdentifier: The identifier of the data to encrypt
  ///   - keyIdentifier: The identifier of the key to use for encryption
  ///   - options: Optional encryption options
  /// - Returns: The encrypted data identifier or an error
  public func encrypt(
    dataIdentifier: String,
    keyIdentifier: String,
    options: EncryptionOptions?=nil
  ) async -> Result<String, SecurityStorageError> {
    let operationID=UUID().uuidString
    let logContext=createLogContext(
      operation: "encrypt",
      operationID: operationID,
      identifiers: [
        "dataIdentifier": dataIdentifier,
        "keyIdentifier": keyIdentifier
      ]
    )

    // Log operation start
    await logDebug("Starting encryption operation", context: logContext)

    // First retrieve the data to encrypt
    let dataResult=await secureStorage.retrieveData(withIdentifier: dataIdentifier)

    switch dataResult {
      case let .success(dataToEncrypt):
        // Then retrieve the encryption key
        let keyResult=await secureStorage.retrieveData(withIdentifier: keyIdentifier)

        switch keyResult {
          case let .success(key):
            // Create and execute the encryption command with the data and key
            let command=EncryptDataCommand(
              data: dataToEncrypt,
              key: key,
              algorithm: options?.algorithm ?? .aes256GCM,
              padding: options?.padding ?? .pkcs7,
              secureStorage: secureStorage,
              logger: logger
            )

            return await command.execute(context: logContext, operationID: operationID)

          case let .failure(error):
            await logError("Failed to retrieve encryption key", context: logContext)
            return .failure(error)
        }

      case let .failure(error):
        await logError("Failed to retrieve data for encryption", context: logContext)
        return .failure(error)
    }
  }

  /// Decrypts data with the given key.
  ///
  /// This method retrieves the encrypted data and key from secure storage using their identifiers,
  /// decrypts the data, and stores the result back in secure storage.
  ///
  /// - Parameters:
  ///   - encryptedDataIdentifier: The identifier of the encrypted data
  ///   - keyIdentifier: The identifier of the key to use for decryption
  ///   - options: Optional decryption options
  /// - Returns: The decrypted data identifier or an error
  public func decrypt(
    dataIdentifier: String,
    keyIdentifier: String,
    options: DecryptionOptions?=nil
  ) async -> Result<String, SecurityStorageError> {
    let operationID=UUID().uuidString
    let logContext=createLogContext(
      operation: "decrypt",
      operationID: operationID,
      identifiers: [
        "dataIdentifier": dataIdentifier,
        "keyIdentifier": keyIdentifier
      ]
    )

    // Log operation start
    await logDebug("Starting decryption operation", context: logContext)

    // First retrieve the encrypted data
    let dataResult=await secureStorage.retrieveData(withIdentifier: dataIdentifier)

    switch dataResult {
      case let .success(encryptedData):
        // Then retrieve the decryption key
        let keyResult=await secureStorage.retrieveData(withIdentifier: keyIdentifier)

        switch keyResult {
          case let .success(key):
            // Create and execute the decryption command with the data and key
            let command=DecryptDataCommand(
              data: encryptedData,
              key: key,
              algorithm: options?.algorithm ?? .aes256GCM,
              padding: options?.padding ?? .pkcs7,
              secureStorage: secureStorage,
              logger: logger
            )

            return await command.execute(context: logContext, operationID: operationID)

          case let .failure(error):
            await logError("Failed to retrieve decryption key", context: logContext)
            return .failure(error)
        }

      case let .failure(error):
        await logError("Failed to retrieve encrypted data", context: logContext)
        return .failure(error)
    }
  }

  /// Computes a hash of the given data.
  ///
  /// This method retrieves the data from secure storage using its identifier,
  /// hashes the data, and stores the result back in secure storage.
  ///
  /// - Parameters:
  ///   - dataIdentifier: The identifier of the data to hash
  ///   - options: Optional hashing options
  /// - Returns: The hash identifier or an error
  public func hash(
    dataIdentifier: String,
    options: CoreSecurityTypes.HashingOptions?=nil
  ) async -> Result<String, SecurityStorageError> {
    let operationID=UUID().uuidString
    let logContext=createLogContext(
      operation: "hash",
      operationID: operationID,
      identifiers: [
        "dataIdentifier": dataIdentifier
      ]
    )

    // Log operation start
    await logDebug("Starting hash operation", context: logContext)

    // First retrieve the data to hash
    let dataResult=await secureStorage.retrieveData(withIdentifier: dataIdentifier)

    switch dataResult {
      case let .success(data):
        // Create and execute the hash command with the data
        let command=HashDataCommand(
          data: data,
          algorithm: options?.algorithm ?? .sha256,
          salt: nil, // HashingOptions doesn't have salt, so we pass nil
          secureStorage: secureStorage,
          logger: logger
        )

        return await command.execute(context: logContext, operationID: operationID)

      case let .failure(error):
        await logError("Failed to retrieve data for hashing", context: logContext)
        return .failure(error)
    }
  }

  /// Generates a hash and verifies it against a provided hash.
  ///
  /// This method retrieves the data and expected hash from secure storage using their identifiers,
  /// hashes the data, and compares the result with the expected hash.
  ///
  /// - Parameters:
  ///   - dataIdentifier: The identifier of the data to hash
  ///   - hashIdentifier: The identifier of the expected hash
  ///   - options: Optional hashing options
  /// - Returns: Whether the hash matches or an error
  public func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options: CoreSecurityTypes.HashingOptions?=nil
  ) async -> Result<Bool, SecurityStorageError> {
    let operationID=UUID().uuidString
    let logContext=createLogContext(
      operation: "verifyHash",
      operationID: operationID,
      identifiers: [
        "dataIdentifier": dataIdentifier,
        "hashIdentifier": hashIdentifier
      ]
    )

    // Log operation start
    await logDebug("Starting hash verification operation", context: logContext)

    // Compute the hash of the data
    let hashResult=await hash(dataIdentifier: dataIdentifier, options: options)

    switch hashResult {
      case let .success(computedHashIdentifier):
        // Retrieve both hashes
        let expectedHashResult=await secureStorage.retrieveData(withIdentifier: hashIdentifier)
        let computedHashResult=await secureStorage
          .retrieveData(withIdentifier: computedHashIdentifier)

        switch (expectedHashResult, computedHashResult) {
          case let (.success(expectedHash), .success(computedHash)):
            // Compare the hashes
            let match=expectedHash == computedHash
            await logInfo("Hash verification \(match ? "matched" : "failed")", context: logContext)
            return .success(match)

          case let (.failure(error), _):
            await logError("Failed to retrieve expected hash", context: logContext)
            return .failure(error)

          case let (_, .failure(error)):
            await logError("Failed to retrieve computed hash", context: logContext)
            return .failure(error)
        }

      case let .failure(error):
        await logError("Failed to compute hash", context: logContext)
        return .failure(error)
    }
  }

  /// Generates a cryptographic key of the specified bit length.
  ///
  /// - Parameters:
  ///   - length: The bit length of the key (128, 192, 256, etc.)
  ///   - identifier: The identifier to associate with the key
  ///   - purpose: The intended purpose of the key
  ///   - options: Optional key generation options
  /// - Returns: Whether the key was generated successfully or an error
  public func generateKey(
    length: Int,
    identifier: String,
    purpose: KeyPurpose,
    options: KeyGenerationOptions?=nil
  ) async -> Result<Bool, SecurityStorageError> {
    let operationID=UUID().uuidString
    let logContext=createLogContext(
      operation: "generateKey",
      operationID: operationID,
      identifiers: [
        "keyIdentifier": identifier
      ],
      metadata: [
        "keyLength": String(length),
        "keyPurpose": purpose.rawValue
      ]
    )

    // Log operation start
    await logDebug("Starting key generation operation", context: logContext)

    // Calculate the key byte length
    let byteLength=length / 8
    if byteLength <= 0 {
      await logError("Invalid key length: \(length) bits", context: logContext)
      return .failure(.invalidKeyLength)
    }

    if let passwordString=options?.passwordString, !passwordString.isEmpty {
      // Password-based key derivation
      guard let passwordData=passwordString.data(using: .utf8) else {
        await logError("Failed to convert password to data", context: logContext)
        return .failure(.operationFailed("Failed to convert password to data"))
      }

      // Create and execute the key derivation command
      let command=DeriveKeyCommand(
        password: passwordData,
        keyLength: byteLength,
        iterations: options?.iterations ?? 10000,
        algorithm: .pbkdf2, // Default for basic implementation
        secureStorage: secureStorage,
        keyIdentifier: identifier,
        logger: logger
      )

      return await command.execute(context: logContext, operationID: operationID)
    } else {
      // Random key generation
      let command=GenerateKeyCommand(
        keyLength: byteLength,
        secureStorage: secureStorage,
        keyIdentifier: identifier,
        logger: logger
      )

      return await command.execute(context: logContext, operationID: operationID)
    }
  }

  /// Imports data from an external source.
  ///
  /// - Parameters:
  ///   - dataIdentifier: The identifier of the data to import
  ///   - options: Optional import options
  /// - Returns: The imported data identifier or an error
  public func importData(
    dataIdentifier: String,
    options _: ImportOptions?=nil
  ) async -> Result<String, SecurityStorageError> {
    // For a basic implementation, we just retrieve and store with a new identifier
    let operationID=UUID().uuidString
    let logContext=createLogContext(
      operation: "importData",
      operationID: operationID,
      identifiers: [
        "dataIdentifier": dataIdentifier
      ]
    )

    await logDebug("Starting data import operation", context: logContext)

    // Retrieve the data to import
    let dataResult=await secureStorage.retrieveData(withIdentifier: dataIdentifier)

    switch dataResult {
      case let .success(data):
        // Generate a new identifier for the imported data
        let importedDataIdentifier="imported_\(UUID().uuidString)"

        // Store the data with the new identifier
        let storeResult=await secureStorage.storeData(data, withIdentifier: importedDataIdentifier)

        switch storeResult {
          case .success:
            await logInfo("Data imported successfully", context: logContext.withMetadata(
              LogMetadataDTOCollection().withPublic(
                key: "importedDataIdentifier",
                value: importedDataIdentifier
              )
            ))
            return .success(importedDataIdentifier)

          case let .failure(error):
            await logError("Failed to store imported data", context: logContext)
            return .failure(error)
        }

      case let .failure(error):
        await logError("Failed to retrieve data for import", context: logContext)
        return .failure(error)
    }
  }

  /// Exports data to an external format.
  ///
  /// - Parameters:
  ///   - dataIdentifier: The identifier of the data to export
  ///   - options: Optional export options
  /// - Returns: The exported data identifier or an error
  public func exportData(
    dataIdentifier: String,
    options _: ExportOptions?=nil
  ) async -> Result<String, SecurityStorageError> {
    // For a basic implementation, we just retrieve and store with a new identifier
    let operationID=UUID().uuidString
    let logContext=createLogContext(
      operation: "exportData",
      operationID: operationID,
      identifiers: [
        "dataIdentifier": dataIdentifier
      ]
    )

    await logDebug("Starting data export operation", context: logContext)

    // Retrieve the data to export
    let dataResult=await secureStorage.retrieveData(withIdentifier: dataIdentifier)

    switch dataResult {
      case let .success(data):
        // Generate a new identifier for the exported data
        let exportedDataIdentifier="exported_\(UUID().uuidString)"

        // Store the data with the new identifier
        let storeResult=await secureStorage.storeData(data, withIdentifier: exportedDataIdentifier)

        switch storeResult {
          case .success:
            await logInfo("Data exported successfully", context: logContext.withMetadata(
              LogMetadataDTOCollection().withPublic(
                key: "exportedDataIdentifier",
                value: exportedDataIdentifier
              )
            ))
            return .success(exportedDataIdentifier)

          case let .failure(error):
            await logError("Failed to store exported data", context: logContext)
            return .failure(error)
        }

      case let .failure(error):
        await logError("Failed to retrieve data for export", context: logContext)
        return .failure(error)
    }
  }

  /// Stores raw data directly in secure storage.
  ///
  /// - Parameters:
  ///   - data: The data to store
  ///   - identifier: The identifier to use for the data
  /// - Returns: Whether the data was stored successfully or an error
  public func storeData(
    _ data: Data,
    withIdentifier identifier: String
  ) async -> Result<Bool, SecurityStorageError> {
    let operationID=UUID().uuidString
    let logContext=createLogContext(
      operation: "storeData",
      operationID: operationID,
      identifiers: [
        "dataIdentifier": identifier
      ],
      metadata: [
        "dataSize": String(data.count)
      ]
    )

    await logDebug("Starting data storage operation", context: logContext)

    // Store the data directly
    let storeResult=await secureStorage.storeData(data, withIdentifier: identifier)

    switch storeResult {
      case .success:
        await logInfo("Data stored successfully", context: logContext)
        return .success(true)

      case let .failure(error):
        await logError("Failed to store data", context: logContext)
        return .failure(error)
    }
  }

  // MARK: - Private Logging Methods

  /// Logs a debug message with the given context.
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - context: The context for the log
  private func logDebug(_ message: String, context: LogContextDTO) async {
    if let logger {
      await logger.debug(message, context: context)
    }
  }

  /// Logs an info message with the given context.
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - context: The context for the log
  private func logInfo(_ message: String, context: LogContextDTO) async {
    if let logger {
      await logger.info(message, context: context)
    }
  }

  /// Logs an error message with the given context.
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - context: The context for the log
  private func logError(_ message: String, context: LogContextDTO) async {
    if let logger {
      await logger.error(message, context: context)
    }
  }

  /// Creates a log context with the given operation details.
  ///
  /// - Parameters:
  ///   - operation: The operation name
  ///   - operationID: The operation ID
  ///   - identifiers: Additional identifiers for the context
  ///   - metadata: Additional metadata for the context
  /// - Returns: A configured log context
  private func createLogContext(
    operation: String,
    operationID: String,
    identifiers: [String: String]=[:],
    metadata _: [String: String]=[:]
  ) -> LogContextDTO {
    var metadata=LogMetadataDTOCollection()
      .withPublic(key: "operation", value: operation)
      .withPublic(key: "operationID", value: operationID)

    for (key, value) in identifiers {
      metadata=metadata.withPrivate(key: key, value: value)
    }

    for (key, value) in metadata {
      metadata=metadata.withPublic(key: key, value: value)
    }

    return LogContextDTO(
      domain: "security.crypto",
      category: "DefaultCryptoService",
      metadata: metadata
    )
  }
}

// MARK: Extensions

extension Data {
  /// Creates a Data object from a byte array.
  ///
  /// - Parameter bytes: The byte array to convert
  /// - Returns: A Data object containing the bytes
  public init(bytes: [UInt8]) {
    self.init(bytes)
  }
}
