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
    self.wrapped = wrapped
    self.logger = logger
    secureStorage = wrapped.secureStorage
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
    options: CoreSecurityTypes.EncryptionOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    // Create a log context with proper privacy classification
    var metadata = LogMetadataDTOCollection()
      .withPublic(key: "dataIdentifier", value: dataIdentifier)
      .withPrivate(key: "keyIdentifier", value: keyIdentifier)
    
    // Add algorithm information if available
    if let algorithm = options?.algorithm {
      metadata = metadata.withPublic(key: "algorithm", value: "\(algorithm)")
    }
    
    let context = CryptoLogContext(
      operation: "encrypt",
      algorithm: options?.algorithm.rawValue,
      correlationID: nil,
      source: "LoggingCryptoServiceImpl",
      additionalContext: metadata
    )
    
    await logger.info(
      "Encrypting data with identifier \(dataIdentifier)",
      context: context
    )

    let result = await wrapped.encrypt(
      dataIdentifier: dataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )

    switch result {
      case let .success(identifier):
        var successMetadata = metadata.withPublic(key: "encryptedIdentifier", value: identifier)
        let successContext = CryptoLogContext(
          operation: "encrypt",
          algorithm: options?.algorithm.rawValue,
          correlationID: nil,
          source: "LoggingCryptoServiceImpl",
          additionalContext: successMetadata
        )
        
        await logger.info(
          "Successfully encrypted data to identifier: \(identifier)",
          context: successContext
        )
      case let .failure(error):
        var errorMetadata = metadata.withPublic(key: "errorDescription", value: error.localizedDescription)
        let errorContext = CryptoLogContext(
          operation: "encrypt",
          algorithm: options?.algorithm.rawValue,
          correlationID: nil,
          source: "LoggingCryptoServiceImpl",
          additionalContext: errorMetadata
        )
        
        await logger.error(
          "Failed to encrypt data: \(error)",
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
    options: CoreSecurityTypes.EncryptionOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    // Create a log context with proper privacy classification
    var metadata = LogMetadataDTOCollection()
      .withPublic(key: "encryptedDataIdentifier", value: encryptedDataIdentifier)
      .withPrivate(key: "keyIdentifier", value: keyIdentifier)
    
    // Add algorithm information if available
    if let algorithm = options?.algorithm {
      metadata = metadata.withPublic(key: "algorithm", value: "\(algorithm)")
    }
    
    let context = CryptoLogContext(
      operation: "decrypt",
      algorithm: options?.algorithm.rawValue,
      correlationID: nil,
      source: "LoggingCryptoServiceImpl",
      additionalContext: metadata
    )
    
    await logger.info(
      "Decrypting data with identifier \(encryptedDataIdentifier)",
      context: context
    )

    let result = await wrapped.decrypt(
      encryptedDataIdentifier: encryptedDataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )

    switch result {
      case let .success(identifier):
        var successMetadata = metadata.withPublic(key: "decryptedIdentifier", value: identifier)
        let successContext = CryptoLogContext(
          operation: "decrypt",
          algorithm: options?.algorithm.rawValue,
          correlationID: nil,
          source: "LoggingCryptoServiceImpl",
          additionalContext: successMetadata
        )
        
        await logger.info(
          "Successfully decrypted data to identifier: \(identifier)",
          context: successContext
        )
      case let .failure(error):
        var errorMetadata = metadata.withPublic(key: "errorDescription", value: error.localizedDescription)
        let errorContext = CryptoLogContext(
          operation: "decrypt",
          algorithm: options?.algorithm.rawValue,
          correlationID: nil,
          source: "LoggingCryptoServiceImpl",
          additionalContext: errorMetadata
        )
        
        await logger.error(
          "Failed to decrypt data: \(error)",
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
    options: CoreSecurityTypes.HashingOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    // Create a log context with proper privacy classification
    var metadata = LogMetadataDTOCollection()
      .withPublic(key: "dataIdentifier", value: dataIdentifier)
    
    // Add algorithm information if available
    if let algorithm = options?.algorithm {
      metadata = metadata.withPublic(key: "algorithm", value: "\(algorithm)")
    }
    
    let context = CryptoLogContext(
      operation: "hash",
      algorithm: options?.algorithm.rawValue,
      correlationID: nil,
      source: "LoggingCryptoServiceImpl",
      additionalContext: metadata
    )
    
    await logger.info(
      "Hashing data with identifier \(dataIdentifier)",
      context: context
    )

    let result = await wrapped.hash(
      dataIdentifier: dataIdentifier,
      options: options
    )

    switch result {
      case let .success(identifier):
        var successMetadata = metadata.withHashed(key: "hashIdentifier", value: identifier)
        let successContext = CryptoLogContext(
          operation: "hash",
          algorithm: options?.algorithm.rawValue,
          correlationID: nil,
          source: "LoggingCryptoServiceImpl",
          additionalContext: successMetadata
        )
        
        await logger.info(
          "Successfully hashed data to identifier: \(identifier)",
          context: successContext
        )
      case let .failure(error):
        var errorMetadata = metadata.withPublic(key: "errorDescription", value: error.localizedDescription)
        let errorContext = CryptoLogContext(
          operation: "hash",
          algorithm: options?.algorithm.rawValue,
          correlationID: nil,
          source: "LoggingCryptoServiceImpl",
          additionalContext: errorMetadata
        )
        
        await logger.error(
          "Failed to hash data: \(error)",
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
     - algorithm: Hash algorithm to use
   - Returns: Success with verification result or error
   */
  public func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    algorithm: String
  ) async -> Result<Bool, SecurityStorageError> {
    let context = createLogContext(
      operation: "verifyHash",
      status: "started",
      details: [
        "dataIdentifier": dataIdentifier,
        "hashIdentifier": hashIdentifier,
        "algorithm": algorithm
      ]
    )
    
    await logger.debug(
      "Verifying hash for data with identifier \(dataIdentifier) against hash \(hashIdentifier)",
      context: context
    )
    
    let result = await wrapped.verifyHash(
      dataIdentifier: dataIdentifier,
      hashIdentifier: hashIdentifier,
      algorithm: algorithm
    )
    
    switch result {
      case .success(let isValid):
        let successContext = createLogContext(
          operation: "verifyHash",
          status: "success",
          details: [
            "dataIdentifier": dataIdentifier,
            "hashIdentifier": hashIdentifier, 
            "algorithm": algorithm,
            "isValid": isValid ? "true" : "false"
          ]
        )
        
        await logger.info(
          "Hash verification result: \(isValid ? "Valid" : "Invalid")",
          context: successContext
        )
        
      case .failure(let error):
        let errorContext = createLogContext(
          operation: "verifyHash",
          status: "failed",
          details: [
            "dataIdentifier": dataIdentifier,
            "hashIdentifier": hashIdentifier,
            "algorithm": algorithm,
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
     - options: Optional key generation options
   - Returns: Identifier for the generated key or an error
   */
  public func generateKey(
    options: CoreSecurityTypes.KeyGenerationOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    // Create a log context with proper privacy classification
    var metadata = LogMetadataDTOCollection()
    
    // Add key type and algorithm information if available
    if let keyType = options?.keyType {
      metadata = metadata.withPublic(key: "keyType", value: "\(keyType)")
    }
    
    let context = CryptoLogContext(
      operation: "generateKey",
      algorithm: nil,
      correlationID: nil,
      source: "LoggingCryptoServiceImpl",
      additionalContext: metadata
    )
    
    await logger.info(
      "Generating cryptographic key",
      context: context
    )

    let result = await wrapped.generateKey(options: options)

    switch result {
      case let .success(identifier):
        var successMetadata = metadata.withSensitive(key: "keyIdentifier", value: identifier)
        let successContext = CryptoLogContext(
          operation: "generateKey",
          algorithm: nil,
          correlationID: nil,
          source: "LoggingCryptoServiceImpl",
          additionalContext: successMetadata
        )
        
        await logger.info(
          "Successfully generated key with identifier: \(identifier)",
          context: successContext
        )
      case let .failure(error):
        var errorMetadata = metadata.withPublic(key: "errorDescription", value: error.localizedDescription)
        let errorContext = CryptoLogContext(
          operation: "generateKey",
          algorithm: nil,
          correlationID: nil,
          source: "LoggingCryptoServiceImpl",
          additionalContext: errorMetadata
        )
        
        await logger.error(
          "Failed to generate key: \(error)",
          context: errorContext
        )
    }

    return result
  }

  /**
   Generates a cryptographic key with specific length.

   - Parameters:
     - length: The length of the key in bits
     - options: Optional key generation options
   - Returns: Identifier for the generated key or an error
   */
  public func generateKey(
    length: Int,
    options: CoreSecurityTypes.KeyGenerationOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    // Create a log context with proper privacy classification
    var metadata = LogMetadataDTOCollection()
      .withPublic(key: "keyLength", value: "\(length)")
    
    // KeyGenerationOptions doesn't have an algorithm property, so we won't try to access it
    
    let context = CryptoLogContext(
      operation: "generateKey",
      algorithm: nil,
      correlationID: nil,
      source: "LoggingCryptoServiceImpl",
      additionalContext: metadata
    )
    
    await logger.info(
      "Generating cryptographic key of length \(length)",
      context: context
    )

    let result = await wrapped.generateKey(length: length, options: options)

    switch result {
      case let .success(identifier):
        var successMetadata = metadata.withSensitive(key: "keyIdentifier", value: identifier)
        let successContext = CryptoLogContext(
          operation: "generateKey",
          algorithm: nil,
          correlationID: nil,
          source: "LoggingCryptoServiceImpl",
          additionalContext: successMetadata
        )
        
        await logger.info(
          "Successfully generated key with identifier: \(identifier)",
          context: successContext
        )
      case let .failure(error):
        var errorMetadata = metadata.withPublic(key: "errorDescription", value: error.localizedDescription)
        let errorContext = CryptoLogContext(
          operation: "generateKey",
          algorithm: nil,
          correlationID: nil,
          source: "LoggingCryptoServiceImpl",
          additionalContext: errorMetadata
        )
        
        await logger.error(
          "Failed to generate key: \(error)",
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
    var metadata = LogMetadataDTOCollection()
      .withPublic(key: "dataIdentifier", value: identifier)
    
    let context = CryptoLogContext(
      operation: "exportData",
      algorithm: nil,
      correlationID: nil,
      source: "LoggingCryptoServiceImpl",
      additionalContext: metadata
    )
    
    await logger.info(
      "Exporting data with identifier \(identifier)",
      context: context
    )

    let result = await wrapped.exportData(identifier: identifier)

    switch result {
      case let .success(data):
        var successMetadata = metadata.withPublic(key: "dataSize", value: "\(data.count)")
        let successContext = CryptoLogContext(
          operation: "exportData",
          algorithm: nil,
          correlationID: nil,
          source: "LoggingCryptoServiceImpl",
          additionalContext: successMetadata
        )
        
        await logger.info(
          "Successfully exported data (\(data.count) bytes)",
          context: successContext
        )
      case let .failure(error):
        var errorMetadata = metadata.withPublic(key: "errorDescription", value: error.localizedDescription)
        let errorContext = CryptoLogContext(
          operation: "exportData",
          algorithm: nil,
          correlationID: nil,
          source: "LoggingCryptoServiceImpl",
          additionalContext: errorMetadata
        )
        
        await logger.error(
          "Failed to export data: \(error)",
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
    options: CoreSecurityTypes.HashingOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    // This is just a proxy to the hash method to conform to the protocol
    return await hash(dataIdentifier: dataIdentifier, options: options)
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
    var metadata = LogMetadataDTOCollection()
      .withPublic(key: "dataIdentifier", value: identifier)
    
    let context = CryptoLogContext(
      operation: "deleteData",
      algorithm: nil,
      correlationID: nil,
      source: "LoggingCryptoServiceImpl",
      additionalContext: metadata
    )
    
    await logger.info(
      "Deleting data with identifier \(identifier)",
      context: context
    )

    let result = await wrapped.deleteData(identifier: identifier)

    switch result {
      case .success:
        let successContext = CryptoLogContext(
          operation: "deleteData",
          algorithm: nil,
          correlationID: nil,
          source: "LoggingCryptoServiceImpl",
          additionalContext: metadata
        )
        
        await logger.info(
          "Successfully deleted data with identifier: \(identifier)",
          context: successContext
        )
      case let .failure(error):
        var errorMetadata = metadata.withPublic(key: "errorDescription", value: error.localizedDescription)
        let errorContext = CryptoLogContext(
          operation: "deleteData",
          algorithm: nil,
          correlationID: nil,
          source: "LoggingCryptoServiceImpl",
          additionalContext: errorMetadata
        )
        
        await logger.error(
          "Failed to delete data: \(error)",
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
    var metadata = LogMetadataDTOCollection()
      .withPublic(key: "dataSize", value: "\(data.count)")
    
    // Add storage type if available
    let context = CryptoLogContext(
      operation: "storeData",
      algorithm: nil,
      correlationID: nil,
      source: "LoggingCryptoServiceImpl",
      additionalContext: metadata
    )
    
    await logger.info(
      "Storing data (\(data.count) bytes)",
      context: context
    )

    let result = await wrapped.storeData(
      data: data,
      identifier: identifier
    )

    switch result {
      case .success:
        var successMetadata = metadata
        let successContext = CryptoLogContext(
          operation: "storeData",
          algorithm: nil,
          correlationID: nil,
          source: "LoggingCryptoServiceImpl",
          additionalContext: successMetadata
        )
        
        await logger.info(
          "Successfully stored data",
          context: successContext
        )
      case let .failure(error):
        var errorMetadata = metadata.withPublic(key: "errorDescription", value: error.localizedDescription)
        let errorContext = CryptoLogContext(
          operation: "storeData",
          algorithm: nil,
          correlationID: nil,
          source: "LoggingCryptoServiceImpl",
          additionalContext: errorMetadata
        )
        
        await logger.error(
          "Failed to store data: \(error)",
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
    let metadata = LogMetadataDTOCollection()
      .withPublic(key: "dataIdentifier", value: identifier)
    
    let context = CryptoLogContext(
      operation: "retrieveData",
      algorithm: nil,
      correlationID: nil,
      source: "LoggingCryptoServiceImpl",
      additionalContext: metadata
    )
    
    await logger.info(
      "Retrieving data with identifier \(identifier)",
      context: context
    )

    let result = await wrapped.retrieveData(
      identifier: identifier
    )

    switch result {
      case let .success(data):
        let successMetadata = metadata.withPublic(key: "dataSize", value: "\(data.count)")
        let successContext = CryptoLogContext(
          operation: "retrieveData",
          algorithm: nil,
          correlationID: nil,
          source: "LoggingCryptoServiceImpl",
          additionalContext: successMetadata
        )
        
        await logger.info(
          "Successfully retrieved data (\(data.count) bytes)",
          context: successContext
        )
      case let .failure(error):
        let errorMetadata = metadata.withPublic(key: "errorDescription", value: error.localizedDescription)
        let errorContext = CryptoLogContext(
          operation: "retrieveData",
          algorithm: nil,
          correlationID: nil,
          source: "LoggingCryptoServiceImpl",
          additionalContext: errorMetadata
        )
        
        await logger.error(
          "Failed to retrieve data: \(error.localizedDescription)",
          context: errorContext
        )
    }
    
    return result
  }

  /**
   Imports raw data into secure storage with optional custom identifier.

   - Parameters:
     - data: Raw data bytes to import
     - customIdentifier: Optional custom identifier to use
   - Returns: Success with data identifier or error
   */
  public func importData(
    _ data: [UInt8], 
    customIdentifier: String?
  ) async -> Result<String, SecurityStorageError> {
    let context = createLogContext(
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
    let dataObj = Data(data)
    
    // Forward to wrapped service
    let result = await wrapped.importData(dataObj, customIdentifier: customIdentifier)
    
    switch result {
    case .success(let identifier):
      let successContext = createLogContext(
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
      
    case .failure(let error):
      let errorContext = createLogContext(
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
}
