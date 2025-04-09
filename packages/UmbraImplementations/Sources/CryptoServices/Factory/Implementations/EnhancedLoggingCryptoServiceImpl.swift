import CoreSecurityTypes
import CryptoInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces

/**
 # EnhancedLoggingCryptoServiceImpl

 A decorator implementation of CryptoServiceProtocol that adds enhanced logging capabilities.
 This implementation wraps another CryptoServiceProtocol implementation and provides detailed
 logging for cryptographic operations.
 
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
public actor EnhancedLoggingCryptoServiceImpl: CryptoServiceProtocol {
  /// The wrapped implementation
  private let wrapped: CryptoServiceProtocol
  /// The secure storage, required by the protocol
  public let secureStorage: SecureStorageProtocol
  /// Enhanced logger
  private let logger: LoggingProtocol

  /**
   Initialises a new enhanced logging crypto service.

   - Parameters:
     - wrapped: The crypto service to wrap.
     - secureStorage: The secure storage to use (required by protocol).
     - logger: The logger to use for logging.
   */
  public init(
    wrapped: CryptoServiceProtocol,
    secureStorage: SecureStorageProtocol,
    logger: LoggingProtocol
  ) {
    self.wrapped = wrapped
    self.secureStorage = secureStorage
    self.logger = logger
  }

  /**
   Encrypts data using the specified key.
   
   - Parameters:
     - dataIdentifier: Identifier for the data to encrypt
     - keyIdentifier: Identifier for the encryption key
     - options: Optional encryption options
   - Returns: Result containing the encrypted data identifier or an error
   */
  public func encrypt(
    dataIdentifier: String,
    keyIdentifier: String,
    options: CoreSecurityTypes.EncryptionOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    // Create an enhanced log context with proper privacy tags
    let context = EnhancedLogContext(
      domainName: "CryptoService",
      operationName: "encrypt",
      source: "EnhancedLoggingCryptoServiceImpl.encrypt",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "dataIdentifier", value: dataIdentifier)
        .withPrivate(key: "keyIdentifier", value: keyIdentifier)
    )
    
    // Add algorithm information if available
    let contextWithAlgorithm: EnhancedLogContext
    if let algorithm = options?.algorithm {
      contextWithAlgorithm = EnhancedLogContext(
        domainName: context.domainName,
        operationName: context.operationName,
        source: context.source,
        correlationID: context.correlationID,
        metadata: context.metadata.withPublic(key: "algorithm", value: "\(algorithm)")
      )
    } else {
      contextWithAlgorithm = context
    }
    
    await logger.log(.debug, "Encrypt operation started", context: contextWithAlgorithm)

    // Perform the operation
    let result = await wrapped.encrypt(
      dataIdentifier: dataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )

    // Log the result
    switch result {
      case let .success(encryptedIdentifier):
        // Add public metadata for the successful operation
        let successContext = EnhancedLogContext(
          domainName: context.domainName,
          operationName: "encrypt",
          source: context.source,
          correlationID: context.correlationID,
          metadata: context.metadata.withPublic(
            key: "encryptedIdentifier",
            value: encryptedIdentifier
          )
        )
        // Log with the new context
        await logger.log(.info, "Encrypt operation successful", context: successContext)
      case let .failure(error):
        let errorContext = EnhancedLogContext(
          domainName: context.domainName,
          operationName: "encrypt",
          source: context.source,
          correlationID: context.correlationID,
          metadata: context.metadata.withPublic(
            key: "errorDescription",
            value: error.localizedDescription
          )
        )
        await logger.error("Encrypt operation failed", context: errorContext)
    }

    return result
  }

  /**
   Decrypts data using the specified key.
   
   - Parameters:
     - encryptedDataIdentifier: Identifier for the encrypted data
     - keyIdentifier: Identifier for the decryption key
     - options: Optional decryption options
   - Returns: Result containing the decrypted data identifier or an error
   */
  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options: CoreSecurityTypes.EncryptionOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    let context = EnhancedLogContext(
      domainName: "CryptoService",
      operationName: "decrypt",
      source: "EnhancedLoggingCryptoServiceImpl.decrypt",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "encryptedDataIdentifier", value: encryptedDataIdentifier)
        .withPrivate(key: "keyIdentifier", value: keyIdentifier)
    )
    
    // Add algorithm information if available
    let contextWithAlgorithm: EnhancedLogContext
    if let algorithm = options?.algorithm {
      contextWithAlgorithm = EnhancedLogContext(
        domainName: context.domainName,
        operationName: context.operationName,
        source: context.source,
        correlationID: context.correlationID,
        metadata: context.metadata.withPublic(key: "algorithm", value: "\(algorithm)")
      )
    } else {
      contextWithAlgorithm = context
    }
    
    await logger.log(.debug, "Decrypt operation started", context: contextWithAlgorithm)

    // Perform the operation
    let result = await wrapped.decrypt(
      encryptedDataIdentifier: encryptedDataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )

    // Log the result
    switch result {
      case let .success(decryptedIdentifier):
        let successContext = EnhancedLogContext(
          domainName: context.domainName,
          operationName: "decrypt",
          source: context.source,
          correlationID: context.correlationID,
          metadata: context.metadata.withPublic(
            key: "decryptedIdentifier",
            value: decryptedIdentifier
          )
        )
        await logger.log(.info, "Decrypt operation successful", context: successContext)
      case let .failure(error):
        let errorContext = EnhancedLogContext(
          domainName: context.domainName,
          operationName: "decrypt",
          source: context.source,
          correlationID: context.correlationID,
          metadata: context.metadata.withPublic(
            key: "errorDescription",
            value: error.localizedDescription
          )
        )
        await logger.error("Decrypt operation failed", context: errorContext)
    }

    return result
  }

  /**
   Computes a hash of the specified data.
   
   - Parameters:
     - dataIdentifier: Identifier for the data to hash
     - options: Optional hashing options
   - Returns: Result containing the hash identifier or an error
   */
  public func hash(
    dataIdentifier: String,
    options: CoreSecurityTypes.HashingOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    let algorithm = options?.algorithm ?? .sha256
    let context = EnhancedLogContext(
      domainName: "CryptoService",
      operationName: "hash",
      source: "EnhancedLoggingCryptoServiceImpl.hash",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "dataIdentifier", value: dataIdentifier)
        .withPublic(key: "algorithm", value: "\(algorithm)")
    )
    await logger.log(.debug, "Hash operation started", context: context)

    // Perform the operation
    let result = await wrapped.hash(
      dataIdentifier: dataIdentifier,
      options: options
    )

    // Log the result
    switch result {
      case let .success(hashIdentifier):
        let successContext = EnhancedLogContext(
          domainName: context.domainName,
          operationName: "hash",
          source: context.source,
          correlationID: context.correlationID,
          metadata: context.metadata.withPublic(
            key: "hashIdentifier",
            value: hashIdentifier
          )
        )
        await logger.log(.info, "Hash operation successful", context: successContext)
      case let .failure(error):
        let errorContext = EnhancedLogContext(
          domainName: context.domainName,
          operationName: "hash",
          source: context.source,
          correlationID: context.correlationID,
          metadata: context.metadata.withPublic(
            key: "errorDescription",
            value: error.localizedDescription
          )
        )
        await logger.error("Hash operation failed", context: errorContext)
    }

    return result
  }

  /**
   Verifies that a hash matches the specified data.
   
   - Parameters:
     - dataIdentifier: Identifier for the data to verify
     - hashIdentifier: Identifier for the hash to compare against
     - options: Optional hashing options
   - Returns: Result containing a boolean indicating if the hash matches or an error
   */
  public func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options: CoreSecurityTypes.HashingOptions? = nil
  ) async -> Result<Bool, SecurityStorageError> {
    let algorithm = options?.algorithm ?? .sha256
    let context = EnhancedLogContext(
      domainName: "CryptoService",
      operationName: "verifyHash",
      source: "EnhancedLoggingCryptoServiceImpl.verifyHash",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "dataIdentifier", value: dataIdentifier)
        .withPublic(key: "hashIdentifier", value: hashIdentifier)
        .withPublic(key: "algorithm", value: "\(algorithm)")
    )
    await logger.log(.debug, "Verify hash operation started", context: context)

    // Perform the operation
    let result = await wrapped.verifyHash(
      dataIdentifier: dataIdentifier,
      hashIdentifier: hashIdentifier,
      options: options
    )

    // Log the result
    switch result {
      case let .success(matches):
        let successContext = EnhancedLogContext(
          domainName: context.domainName,
          operationName: "verifyHash",
          source: context.source,
          correlationID: context.correlationID,
          metadata: context.metadata.withPublic(
            key: "matches",
            value: "\(matches)"
          )
        )
        await logger.log(.info, "Verify hash operation successful", context: successContext)
      case let .failure(error):
        let errorContext = EnhancedLogContext(
          domainName: context.domainName,
          operationName: "verifyHash",
          source: context.source,
          correlationID: context.correlationID,
          metadata: context.metadata.withPublic(
            key: "errorDescription",
            value: error.localizedDescription
          )
        )
        await logger.error("Verify hash operation failed", context: errorContext)
    }

    return result
  }

  /**
   Stores data in the secure storage.
   
   - Parameters:
     - data: The data to store
     - options: Optional storage options
   - Returns: Result containing void on success or an error
   */
  public func storeData(
    data: Data,
    options: CoreSecurityTypes.StorageOptions? = nil
  ) async -> Result<Void, SecurityStorageError> {
    let context = EnhancedLogContext(
      domainName: "CryptoService",
      operationName: "storeData",
      source: "EnhancedLoggingCryptoServiceImpl.storeData",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "dataSize", value: "\(data.count)")
    )
    
    // Add storage type if available
    let contextWithOptions: EnhancedLogContext
    if let storageType = options?.storageType {
      contextWithOptions = EnhancedLogContext(
        domainName: context.domainName,
        operationName: context.operationName,
        source: context.source,
        correlationID: context.correlationID,
        metadata: context.metadata.withPublic(key: "storageType", value: "\(storageType)")
      )
    } else {
      contextWithOptions = context
    }
    
    await logger.log(.debug, "Store data operation started", context: contextWithOptions)

    // Perform the operation
    let result = await wrapped.storeData(
      data: data,
      options: options
    )

    // Log the result
    switch result {
      case .success:
        await logger.log(.info, "Store data operation successful", context: contextWithOptions)
      case let .failure(error):
        let errorContext = EnhancedLogContext(
          domainName: context.domainName,
          operationName: "storeData",
          source: context.source,
          correlationID: context.correlationID,
          metadata: context.metadata.withPublic(
            key: "errorDescription",
            value: error.localizedDescription
          )
        )
        await logger.error("Store data operation failed", context: errorContext)
    }

    return result
  }

  /**
   Retrieves data from secure storage.
   
   - Parameters:
     - dataIdentifier: Identifier for the data to retrieve
     - options: Optional retrieval options
   - Returns: Result containing the retrieved data or an error
   */
  public func retrieveData(
    dataIdentifier: String,
    options: CoreSecurityTypes.StorageOptions? = nil
  ) async -> Result<Data, SecurityStorageError> {
    let context = EnhancedLogContext(
      domainName: "CryptoService",
      operationName: "retrieveData",
      source: "EnhancedLoggingCryptoServiceImpl.retrieveData",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "dataIdentifier", value: dataIdentifier)
    )
    
    // Add storage type if available
    let contextWithOptions: EnhancedLogContext
    if let storageType = options?.storageType {
      contextWithOptions = EnhancedLogContext(
        domainName: context.domainName,
        operationName: context.operationName,
        source: context.source,
        correlationID: context.correlationID,
        metadata: context.metadata.withPublic(key: "storageType", value: "\(storageType)")
      )
    } else {
      contextWithOptions = context
    }
    
    await logger.log(.debug, "Retrieve data operation started", context: contextWithOptions)

    // Perform the operation
    let result = await wrapped.retrieveData(
      dataIdentifier: dataIdentifier,
      options: options
    )

    // Log the result
    switch result {
      case let .success(data):
        let successContext = EnhancedLogContext(
          domainName: context.domainName,
          operationName: "retrieveData",
          source: context.source,
          correlationID: context.correlationID,
          metadata: context.metadata.withPublic(
            key: "dataSize",
            value: "\(data.count)"
          )
        )
        await logger.log(.info, "Retrieve data operation successful", context: successContext)
      case let .failure(error):
        let errorContext = EnhancedLogContext(
          domainName: context.domainName,
          operationName: "retrieveData",
          source: context.source,
          correlationID: context.correlationID,
          metadata: context.metadata.withPublic(
            key: "errorDescription",
            value: error.localizedDescription
          )
        )
        await logger.error("Retrieve data operation failed", context: errorContext)
    }

    return result
  }

  /**
   Imports data from an external source.
   
   - Parameters:
     - data: The data to import
     - options: Optional import options
   - Returns: Result containing the imported data identifier or an error
   */
  public func importData(
    data: Data,
    options: CoreSecurityTypes.ImportOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    // Create an enhanced log context with proper privacy tags
    let context = EnhancedLogContext(
      domainName: "CryptoService",
      operationName: "importData",
      source: "EnhancedLoggingCryptoServiceImpl.importData",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "dataSize", value: "\(data.count)")
    )
    
    // Add import type if available
    let contextWithOptions: EnhancedLogContext
    if let importType = options?.importType {
      contextWithOptions = EnhancedLogContext(
        domainName: context.domainName,
        operationName: context.operationName,
        source: context.source,
        correlationID: context.correlationID,
        metadata: context.metadata.withPublic(key: "importType", value: "\(importType)")
      )
    } else {
      contextWithOptions = context
    }
    
    await logger.log(.debug, "Import data operation started", context: contextWithOptions)

    // Perform the operation
    let result = await wrapped.importData(
      data: data,
      options: options
    )

    // Log the result
    switch result {
      case let .success(importedIdentifier):
        let successContext = EnhancedLogContext(
          domainName: context.domainName,
          operationName: "importData",
          source: context.source,
          correlationID: context.correlationID,
          metadata: context.metadata.withPublic(
            key: "importedIdentifier",
            value: importedIdentifier
          )
        )
        await logger.log(.info, "Import data operation successful", context: successContext)
      case let .failure(error):
        let errorContext = EnhancedLogContext(
          domainName: context.domainName,
          operationName: "importData",
          source: context.source,
          correlationID: context.correlationID,
          metadata: context.metadata.withPublic(
            key: "errorDescription",
            value: error.localizedDescription
          )
        )
        await logger.error("Import data operation failed", context: errorContext)
    }

    return result
  }

  /**
   Signs data using the specified key.
   
   - Parameters:
     - dataIdentifier: Identifier for the data to sign
     - keyIdentifier: Identifier for the signing key
     - options: Optional signing options
   - Returns: Result containing the signature identifier or an error
   */
  public func signData(
    dataIdentifier: String,
    keyIdentifier: String,
    options: CoreSecurityTypes.SigningOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    // Create context for logging
    let context = EnhancedLogContext(
      domainName: "CryptoService",
      operationName: "signData",
      source: "EnhancedLoggingCryptoServiceImpl.signData",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "dataIdentifier", value: dataIdentifier)
        .withPrivate(key: "keyIdentifier", value: keyIdentifier)
    )
    
    // Add algorithm information if available
    let contextWithAlgorithm: EnhancedLogContext
    if let algorithm = options?.algorithm {
      contextWithAlgorithm = EnhancedLogContext(
        domainName: context.domainName,
        operationName: context.operationName,
        source: context.source,
        correlationID: context.correlationID,
        metadata: context.metadata.withPublic(key: "algorithm", value: "\(algorithm)")
      )
    } else {
      contextWithAlgorithm = context
    }
    
    await logger.log(.debug, "Sign data operation started", context: contextWithAlgorithm)

    // Perform the operation
    let result = await wrapped.signData(
      dataIdentifier: dataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )

    // Log the result
    switch result {
      case let .success(signatureIdentifier):
        let successContext = EnhancedLogContext(
          domainName: context.domainName,
          operationName: "signData",
          source: context.source,
          correlationID: context.correlationID,
          metadata: context.metadata.withPublic(
            key: "signatureIdentifier",
            value: signatureIdentifier
          )
        )
        await logger.log(.info, "Sign data operation successful", context: successContext)
      case let .failure(error):
        let errorContext = EnhancedLogContext(
          domainName: context.domainName,
          operationName: "signData",
          source: context.source,
          correlationID: context.correlationID,
          metadata: context.metadata.withPublic(
            key: "errorDescription",
            value: error.localizedDescription
          )
        )
        await logger.error("Sign data operation failed", context: errorContext)
    }

    return result
  }

  /**
   Verifies a signature against the specified data.
   
   - Parameters:
     - dataIdentifier: Identifier for the data to verify
     - signatureIdentifier: Identifier for the signature to verify
     - keyIdentifier: Identifier for the verification key
     - options: Optional verification options
   - Returns: Result containing a boolean indicating if the signature is valid or an error
   */
  public func verifySignature(
    dataIdentifier: String,
    signatureIdentifier: String,
    keyIdentifier: String,
    options: CoreSecurityTypes.SigningOptions? = nil
  ) async -> Result<Bool, SecurityStorageError> {
    // Create context for logging
    let context = EnhancedLogContext(
      domainName: "CryptoService",
      operationName: "verifySignature",
      source: "EnhancedLoggingCryptoServiceImpl.verifySignature",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "dataIdentifier", value: dataIdentifier)
        .withPublic(key: "signatureIdentifier", value: signatureIdentifier)
        .withPrivate(key: "keyIdentifier", value: keyIdentifier)
    )
    
    // Add algorithm information if available
    let contextWithAlgorithm: EnhancedLogContext
    if let algorithm = options?.algorithm {
      contextWithAlgorithm = EnhancedLogContext(
        domainName: context.domainName,
        operationName: context.operationName,
        source: context.source,
        correlationID: context.correlationID,
        metadata: context.metadata.withPublic(key: "algorithm", value: "\(algorithm)")
      )
    } else {
      contextWithAlgorithm = context
    }
    
    await logger.log(.debug, "Verify signature operation started", context: contextWithAlgorithm)

    // Perform the operation
    let result = await wrapped.verifySignature(
      dataIdentifier: dataIdentifier,
      signatureIdentifier: signatureIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )

    // Log the result
    switch result {
      case let .success(isValid):
        let successContext = EnhancedLogContext(
          domainName: context.domainName,
          operationName: "verifySignature",
          source: context.source,
          correlationID: context.correlationID,
          metadata: context.metadata.withPublic(
            key: "isValid",
            value: "\(isValid)"
          )
        )
        await logger.log(.info, "Verify signature operation successful", context: successContext)
      case let .failure(error):
        let errorContext = EnhancedLogContext(
          domainName: context.domainName,
          operationName: "verifySignature",
          source: context.source,
          correlationID: context.correlationID,
          metadata: context.metadata.withPublic(
            key: "errorDescription",
            value: error.localizedDescription
          )
        )
        await logger.error("Verify signature operation failed", context: errorContext)
    }

    return result
  }

  /**
   Generates a new cryptographic key.
   
   - Parameters:
     - options: Optional key generation options
   - Returns: Result containing the key identifier or an error
   */
  public func generateKey(
    options: CoreSecurityTypes.KeyGenerationOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    // Create context for logging
    let context = EnhancedLogContext(
      domainName: "CryptoService",
      operationName: "generateKey",
      source: "EnhancedLoggingCryptoServiceImpl.generateKey",
      metadata: LogMetadataDTOCollection()
    )
    
    // Add key type and algorithm information if available
    var contextWithOptions = context
    if let keyType = options?.keyType {
      contextWithOptions = EnhancedLogContext(
        domainName: context.domainName,
        operationName: context.operationName,
        source: context.source,
        correlationID: context.correlationID,
        metadata: context.metadata.withPublic(key: "keyType", value: "\(keyType)")
      )
    }
    
    if let algorithm = options?.algorithm {
      contextWithOptions = EnhancedLogContext(
        domainName: contextWithOptions.domainName,
        operationName: contextWithOptions.operationName,
        source: contextWithOptions.source,
        correlationID: contextWithOptions.correlationID,
        metadata: contextWithOptions.metadata.withPublic(key: "algorithm", value: "\(algorithm)")
      )
    }
    
    await logger.log(.debug, "Generate key operation started", context: contextWithOptions)

    // Perform the operation
    let result = await wrapped.generateKey(options: options)

    // Log the result
    switch result {
      case let .success(keyIdentifier):
        let successContext = EnhancedLogContext(
          domainName: context.domainName,
          operationName: "generateKey",
          source: context.source,
          correlationID: context.correlationID,
          metadata: context.metadata.withSensitive(
            key: "keyIdentifier",
            value: keyIdentifier
          )
        )
        await logger.log(.info, "Generate key operation successful", context: successContext)
      case let .failure(error):
        let errorContext = EnhancedLogContext(
          domainName: context.domainName,
          operationName: "generateKey",
          source: context.source,
          correlationID: context.correlationID,
          metadata: context.metadata.withPublic(
            key: "errorDescription",
            value: error.localizedDescription
          )
        )
        await logger.error("Generate key operation failed", context: errorContext)
    }

    return result
  }
}
