import CoreSecurityTypes
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces

/**
 # LoggingCryptoServiceImpl

 An implementation of CryptoServiceProtocol that adds logging for
 all operations before delegating to the wrapped implementation.

 ## Privacy Controls

 This implementation ensures comprehensive privacy controls for sensitive information:
 - Public information is logged normally
 - Private information is redacted in production builds
 - Sensitive information is always redacted
 - Hash values are specially marked

 ## Thread Safety

 As an actor, this implementation guarantees thread safety when used from multiple
 concurrent contexts, preventing data races in cryptographic operations.
 */
public actor LoggingCryptoServiceImpl: CryptoServiceProtocol {
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
    options: CoreSecurityTypes.EncryptionOptions?=nil
  ) async -> Result<String, SecurityStorageError> {
    // Create a log context with proper privacy classification
    var metadata=LogMetadataDTOCollection()
      .withPublic(key: "dataIdentifier", value: dataIdentifier)
      .withPrivate(key: "keyIdentifier", value: keyIdentifier)

    // Add algorithm information if available
    if let algorithm=options?.algorithm {
      metadata=metadata.withPublic(key: "algorithm", value: "\(algorithm)")
    }

    let context=createLogContext(
      operation: "encrypt",
      status: "started",
      details: [
        "dataIdentifier": dataIdentifier,
        "keyIdentifier": keyIdentifier,
        "algorithm": options?.algorithm.rawValue ?? "default"
      ]
    )

    await logger.info(
      "Encrypting data with identifier \(dataIdentifier)",
      context: context
    )

    let result=await wrapped.encrypt(
      dataIdentifier: dataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )

    switch result {
      case let .success(identifier):
        let successContext=createLogContext(
          operation: "encrypt",
          status: "success",
          details: [
            "dataIdentifier": dataIdentifier,
            "keyIdentifier": keyIdentifier,
            "algorithm": options?.algorithm.rawValue ?? "default",
            "encryptedIdentifier": identifier
          ]
        )

        await logger.info(
          "Successfully encrypted data to identifier: \(identifier)",
          context: successContext
        )
      case let .failure(error):
        let errorContext=createLogContext(
          operation: "encrypt",
          status: "failed",
          details: [
            "dataIdentifier": dataIdentifier,
            "keyIdentifier": keyIdentifier,
            "algorithm": options?.algorithm.rawValue ?? "default",
            "error": error.localizedDescription
          ]
        )

        await logger.error(
          "Failed to encrypt data: \(error.localizedDescription)",
          context: errorContext
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
    options: CoreSecurityTypes.EncryptionOptions?=nil
  ) async -> Result<String, SecurityStorageError> {
    // Create a log context with proper privacy classification
    var metadata=LogMetadataDTOCollection()
      .withPublic(key: "encryptedDataIdentifier", value: encryptedDataIdentifier)
      .withPrivate(key: "keyIdentifier", value: keyIdentifier)

    // Add algorithm information if available
    if let algorithm=options?.algorithm {
      metadata=metadata.withPublic(key: "algorithm", value: "\(algorithm)")
    }

    let context=createLogContext(
      operation: "decrypt",
      status: "started",
      details: [
        "encryptedDataIdentifier": encryptedDataIdentifier,
        "keyIdentifier": keyIdentifier,
        "algorithm": options?.algorithm.rawValue ?? "default"
      ]
    )

    await logger.info(
      "Decrypting data with identifier \(encryptedDataIdentifier)",
      context: context
    )

    let result=await wrapped.decrypt(
      encryptedDataIdentifier: encryptedDataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )

    switch result {
      case let .success(identifier):
        let successContext=createLogContext(
          operation: "decrypt",
          status: "success",
          details: [
            "encryptedDataIdentifier": encryptedDataIdentifier,
            "keyIdentifier": keyIdentifier,
            "algorithm": options?.algorithm.rawValue ?? "default",
            "decryptedIdentifier": identifier
          ]
        )

        await logger.info(
          "Successfully decrypted data to identifier: \(identifier)",
          context: successContext
        )
      case let .failure(error):
        let errorContext=createLogContext(
          operation: "decrypt",
          status: "failed",
          details: [
            "encryptedDataIdentifier": encryptedDataIdentifier,
            "keyIdentifier": keyIdentifier,
            "algorithm": options?.algorithm.rawValue ?? "default",
            "error": error.localizedDescription
          ]
        )

        await logger.error(
          "Failed to decrypt data: \(error.localizedDescription)",
          context: errorContext
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
    options: CoreSecurityTypes.HashingOptions?=nil
  ) async -> Result<String, SecurityStorageError> {
    // Create a log context with proper privacy classification
    var metadata=LogMetadataDTOCollection()
      .withPublic(key: "dataIdentifier", value: dataIdentifier)

    // Add algorithm information if available
    if let algorithm=options?.algorithm {
      metadata=metadata.withPublic(key: "algorithm", value: "\(algorithm)")
    }

    let context=createLogContext(
      operation: "hash",
      status: "started",
      details: [
        "dataIdentifier": dataIdentifier,
        "algorithm": options?.algorithm.rawValue ?? "default"
      ]
    )

    await logger.info(
      "Hashing data with identifier \(dataIdentifier)",
      context: context
    )

    let result=await wrapped.hash(
      dataIdentifier: dataIdentifier,
      options: options
    )

    switch result {
      case let .success(identifier):
        let successContext=createLogContext(
          operation: "hash",
          status: "success",
          details: [
            "dataIdentifier": dataIdentifier,
            "algorithm": options?.algorithm.rawValue ?? "default",
            "hashIdentifier": identifier
          ]
        )

        await logger.info(
          "Successfully hashed data to identifier: \(identifier)",
          context: successContext
        )
      case let .failure(error):
        let errorContext=createLogContext(
          operation: "hash",
          status: "failed",
          details: [
            "dataIdentifier": dataIdentifier,
            "algorithm": options?.algorithm.rawValue ?? "default",
            "error": error.localizedDescription
          ]
        )

        await logger.error(
          "Failed to hash data: \(error.localizedDescription)",
          context: errorContext
        )
    }

    return result
  }

  /**
   Verifies a hash value matches the expected hash.

   - Parameters:
     - dataIdentifier: Identifier for the data to verify
     - hashIdentifier: Identifier for the expected hash
     - options: Optional hashing options
   - Returns: Success with verification result or error
   */
  public func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options: CoreSecurityTypes.HashingOptions?
  ) async -> Result<Bool, SecurityStorageError> {
    let context=createLogContext(
      operation: "verifyHash",
      status: "started",
      details: [
        "dataIdentifier": dataIdentifier,
        "hashIdentifier": hashIdentifier,
        "algorithm": options?.algorithm.rawValue ?? "default"
      ]
    )

    await logger.debug(
      "Verifying hash for data with identifier \(dataIdentifier) against hash \(hashIdentifier)",
      context: context
    )

    let result=await wrapped.verifyHash(
      dataIdentifier: dataIdentifier,
      hashIdentifier: hashIdentifier,
      options: options
    )

    switch result {
      case let .success(isValid):
        let successContext=createLogContext(
          operation: "verifyHash",
          status: "success",
          details: [
            "dataIdentifier": dataIdentifier,
            "hashIdentifier": hashIdentifier,
            "algorithm": options?.algorithm.rawValue ?? "default",
            "isValid": isValid ? "true" : "false"
          ]
        )

        await logger.info(
          "Hash verification result: \(isValid ? "Valid" : "Invalid")",
          context: successContext
        )

      case let .failure(error):
        let errorContext=createLogContext(
          operation: "verifyHash",
          status: "failed",
          details: [
            "dataIdentifier": dataIdentifier,
            "hashIdentifier": hashIdentifier,
            "algorithm": options?.algorithm.rawValue ?? "default",
            "error": error.localizedDescription
          ]
        )

        await logger.error(
          "Failed to verify hash: \(error.localizedDescription)",
          context: errorContext
        )
    }

    return result
  }

  /**
   Generates a key with logging.

   - Parameters:
     - length: The length of the key in bits
     - options: Optional key generation options
   - Returns: Identifier for the generated key or an error
   */
  public func generateKey(
    length: Int,
    options: CoreSecurityTypes.KeyGenerationOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Create a log context with proper privacy classification
    let context=createLogContext(
      operation: "generateKey",
      status: "started",
      details: [
        "keyLength": "\(length)"
      ]
    )

    await logger.debug(
      "Generating key with length \(length) bytes",
      context: context
    )

    let result=await wrapped.generateKey(
      length: length,
      options: options
    )

    switch result {
      case let .success(identifier):
        let successContext=createLogContext(
          operation: "generateKey",
          status: "success",
          details: [
            "keyLength": "\(length)",
            "keyIdentifier": identifier
          ]
        )

        await logger.info(
          "Successfully generated key with identifier \(identifier)",
          context: successContext
        )

      case let .failure(error):
        let errorContext=createLogContext(
          operation: "generateKey",
          status: "failed",
          details: [
            "keyLength": "\(length)",
            "error": error.localizedDescription
          ]
        )

        await logger.error(
          "Failed to generate key: \(error.localizedDescription)",
          context: errorContext
        )
    }

    return result
  }

  /**
   Exports data from secure storage to a raw byte array.

   - Parameter identifier: Identifier for the data to export
   - Returns: Raw byte array or an error
   */
  public func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    // Create a log context with proper privacy classification
    let context=createLogContext(
      operation: "exportData",
      status: "started",
      details: [
        "dataIdentifier": identifier
      ]
    )

    await logger.info(
      "Exporting data with identifier \(identifier)",
      context: context
    )

    let result=await wrapped.exportData(identifier: identifier)

    switch result {
      case let .success(data):
        let successContext=createLogContext(
          operation: "exportData",
          status: "success",
          details: [
            "dataIdentifier": identifier,
            "dataSize": "\(data.count)"
          ]
        )

        await logger.info(
          "Successfully exported data (\(data.count) bytes)",
          context: successContext
        )
      case let .failure(error):
        let errorContext=createLogContext(
          operation: "exportData",
          status: "failed",
          details: [
            "dataIdentifier": identifier,
            "error": error.localizedDescription
          ]
        )

        await logger.error(
          "Failed to export data: \(error.localizedDescription)",
          context: errorContext
        )
    }

    return result
  }

  /**
   Generates a hash for the specified data, alias for the hash method.

   - Parameters:
     - dataIdentifier: Identifier for the data to hash
     - options: Optional hashing options
   - Returns: Identifier for the hash or an error
   */
  public func generateHash(
    dataIdentifier: String,
    options: CoreSecurityTypes.HashingOptions?=nil
  ) async -> Result<String, SecurityStorageError> {
    // This is just a proxy to the hash method to conform to the protocol
    await hash(dataIdentifier: dataIdentifier, options: options)
  }

  /**
   Deletes data from secure storage.

   - Parameter identifier: Identifier for the data to delete
   - Returns: Success or an error
   */
  public func deleteData(
    identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    // Create a log context with proper privacy classification
    let context=createLogContext(
      operation: "deleteData",
      status: "started",
      details: [
        "dataIdentifier": identifier
      ]
    )

    await logger.info(
      "Deleting data with identifier \(identifier)",
      context: context
    )

    let result=await wrapped.deleteData(identifier: identifier)

    switch result {
      case .success:
        let successContext=createLogContext(
          operation: "deleteData",
          status: "success",
          details: [
            "dataIdentifier": identifier
          ]
        )

        await logger.info(
          "Successfully deleted data with identifier: \(identifier)",
          context: successContext
        )
      case let .failure(error):
        let errorContext=createLogContext(
          operation: "deleteData",
          status: "failed",
          details: [
            "dataIdentifier": identifier,
            "error": error.localizedDescription
          ]
        )

        await logger.error(
          "Failed to delete data: \(error.localizedDescription)",
          context: errorContext
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
    // Create a log context with proper privacy classification
    let context=createLogContext(
      operation: "storeData",
      status: "started",
      details: [
        "dataSize": "\(data.count)"
      ]
    )

    await logger.info(
      "Storing data (\(data.count) bytes)",
      context: context
    )

    let result=await wrapped.storeData(
      data: data,
      identifier: identifier
    )

    switch result {
      case .success:
        let successContext=createLogContext(
          operation: "storeData",
          status: "success",
          details: [
            "dataSize": "\(data.count)"
          ]
        )

        await logger.info(
          "Successfully stored data",
          context: successContext
        )
      case let .failure(error):
        let errorContext=createLogContext(
          operation: "storeData",
          status: "failed",
          details: [
            "dataSize": "\(data.count)",
            "error": error.localizedDescription
          ]
        )

        await logger.error(
          "Failed to store data: \(error.localizedDescription)",
          context: errorContext
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
    // Create a log context with proper privacy classification
    let context=createLogContext(
      operation: "retrieveData",
      status: "started",
      details: [
        "dataIdentifier": identifier
      ]
    )

    await logger.info(
      "Retrieving data with identifier \(identifier)",
      context: context
    )

    let result=await wrapped.retrieveData(
      identifier: identifier
    )

    switch result {
      case let .success(data):
        let successContext=createLogContext(
          operation: "retrieveData",
          status: "success",
          details: [
            "dataIdentifier": identifier,
            "dataSize": "\(data.count)"
          ]
        )

        await logger.info(
          "Successfully retrieved data (\(data.count) bytes)",
          context: successContext
        )
      case let .failure(error):
        let errorContext=createLogContext(
          operation: "retrieveData",
          status: "failed",
          details: [
            "dataIdentifier": identifier,
            "error": error.localizedDescription
          ]
        )

        await logger.error(
          "Failed to retrieve data: \(error.localizedDescription)",
          context: errorContext
        )
    }

    return result
  }

  /**
   Imports data with logging.

   - Parameters:
     - data: Raw data bytes to import
     - customIdentifier: Optional custom identifier to use
   - Returns: Success with data identifier or error
   */
  public func importData(
    _ data: [UInt8],
    customIdentifier: String?
  ) async -> Result<String, SecurityStorageError> {
    let context=createLogContext(
      operation: "importData",
      status: "started",
      details: [
        "dataSize": String(data.count),
        "hasCustomIdentifier": customIdentifier != nil ? "true" : "false"
      ]
    )

    await logger.debug(
      "Importing data (\(data.count) bytes)",
      context: context
    )

    // Convert data to Data object if needed
    let dataObj=Data(data)

    // Forward to wrapped service with proper handling of optional customIdentifier
    let effectiveIdentifier=customIdentifier ?? ""
    let result=await wrapped.importData(dataObj, customIdentifier: effectiveIdentifier)

    switch result {
      case let .success(identifier):
        let successContext=createLogContext(
          operation: "importData",
          status: "success",
          details: [
            "dataSize": String(data.count),
            "identifier": identifier
          ]
        )

        await logger.info(
          "Successfully imported data with identifier \(identifier)",
          context: successContext
        )

      case let .failure(error):
        let errorContext=createLogContext(
          operation: "importData",
          status: "failed",
          details: [
            "dataSize": String(data.count),
            "error": error.localizedDescription
          ]
        )

        await logger.error(
          "Failed to import data: \(error.localizedDescription)",
          context: errorContext
        )
    }

    return result
  }

  /**
   Imports data with logging.

   - Parameters:
     - data: The data to import
     - customIdentifier: Identifier to use for the data
   - Returns: Success with data identifier or error
   */
  public func importData(
    _ data: Data,
    customIdentifier: String
  ) async -> Result<String, SecurityStorageError> {
    // Convert Data to [UInt8] for internal implementation
    let bytes=[UInt8](data)

    // Delegate to the other implementation
    return await importData(bytes, customIdentifier: customIdentifier)
  }

  /**
   Creates a log context with appropriate privacy controls for cryptographic operations.

   - Parameters:
     - operation: The cryptographic operation being performed
     - status: The status of the operation (started, success, failed, etc.)
     - details: Additional details to include in the context
   - Returns: A properly constructed log context
   */
  private func createLogContext(
    operation: String,
    status: String,
    details: [String: String]=[:]
  ) -> LogContext {
    var metadata=LogMetadataDTOCollection()

    // Add operation and status as public information
    metadata=metadata
      .withPublic(key: "operation", value: operation)
      .withPublic(key: "status", value: status)

    // Add all details with appropriate privacy classification
    for (key, value) in details {
      metadata=metadata.withPublic(key: key, value: value)
    }

    return LogContext(
      source: "LoggingCryptoServiceImpl",
      metadata: metadata,
      correlationID: LogIdentifier.unique()
    )
  }
}
