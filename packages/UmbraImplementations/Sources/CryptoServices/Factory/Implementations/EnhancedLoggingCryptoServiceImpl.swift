import CryptoInterfaces
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import CoreSecurityTypes
import Foundation

/**
 # EnhancedLoggingCryptoServiceImpl

 A decorator implementation of CryptoServiceProtocol that adds enhanced logging capabilities.
 This implementation wraps another CryptoServiceProtocol implementation and provides detailed
 logging for cryptographic operations.
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
        .withPublic(key: "keyIdentifier", value: keyIdentifier)
        .withPublic(key: "dataIdentifier", value: dataIdentifier)
        // options?.algorithm could be added if needed
    )
    await logger.log(.debug, "Encrypt operation started", context: context)

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
      let updatedMetadata = context.metadata.withPublic(key: "encryptedIdentifier", value: encryptedIdentifier)
      // Create a new context with the updated metadata
      let successContext = EnhancedLogContext(
        domainName: context.domainName,
        operationName: "encrypt",
        source: context.source,
        correlationID: context.correlationID,
        metadata: updatedMetadata
      )
      // Log with the new context
      await logger.log(.info, "Encrypt operation successful", context: successContext)
    case let .failure(error):
      // Use the correct logError method
      await logger.logError(error, context: context)
    }

    return result
  }

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
    await logger.log(.debug, "Decrypt operation started", context: context)

    // Perform the operation
    let result = await wrapped.decrypt(
      encryptedDataIdentifier: encryptedDataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )

    // Log the result
    switch result {
    case let .success(decryptedIdentifier):
      let updatedMetadata = context.metadata.withPublic(key: "decryptedIdentifier", value: decryptedIdentifier)
      let successContext = EnhancedLogContext(
        domainName: context.domainName,
        operationName: "decrypt",
        source: context.source,
        correlationID: context.correlationID,
        metadata: updatedMetadata
      )
      await logger.log(.info, "Decrypt operation successful", context: successContext)
    case let .failure(error):
      await logger.logError(error, context: context)
    }

    return result
  }

  public func hash(
    dataIdentifier: String,
    options: HashingOptions? = nil
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
      let updatedMetadata = context.metadata.withPublic(key: "hashIdentifier", value: hashIdentifier)
      let successContext = EnhancedLogContext(
        domainName: context.domainName,
        operationName: "hash",
        source: context.source,
        correlationID: context.correlationID,
        metadata: updatedMetadata
      )
      await logger.log(.info, "Hash operation successful", context: successContext)
    case let .failure(error):
      await logger.logError(error, context: context)
    }

    return result
  }

  public func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options: HashingOptions? = nil
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
    case let .success(isValid):
      let updatedMetadata = context.metadata.withPublic(key: "isValid", value: "\(isValid)")
      let successContext = EnhancedLogContext(
        domainName: context.domainName,
        operationName: "verifyHash",
        source: context.source,
        correlationID: context.correlationID,
        metadata: updatedMetadata
      )
      await logger.log(.info, "Verify hash operation successful", context: successContext)
    case let .failure(error):
      await logger.logError(error, context: context)
    }

    return result
  }

  public func generateKey(
    length: Int,
    options: CoreSecurityTypes.KeyGenerationOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    let context = EnhancedLogContext(
      domainName: "CryptoService",
      operationName: "generateKey",
      source: "EnhancedLoggingCryptoServiceImpl.generateKey",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "keyLength", value: "\(length)")
        // options could be added here if needed
    )
    await logger.log(.debug, "Generate key operation started", context: context)

    // Perform the operation
    let result = await wrapped.generateKey(
      length: length,
      options: options
    )

    // Log the result
    switch result {
    case let .success(keyIdentifier):
      let updatedMetadata = context.metadata.withPublic(key: "keyIdentifier", value: keyIdentifier)
      let successContext = EnhancedLogContext(
        domainName: context.domainName,
        operationName: "generateKey",
        source: context.source,
        correlationID: context.correlationID,
        metadata: updatedMetadata
      )
      await logger.log(.info, "Generate key operation successful", context: successContext)
    case let .failure(error):
      await logger.logError(error, context: context)
    }

    return result
  }

  public func storeData(
    data: Data,
    identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    let context = EnhancedLogContext(
      domainName: "CryptoService",
      operationName: "storeData",
      source: "EnhancedLoggingCryptoServiceImpl.storeData",
      metadata: LogMetadataDTOCollection()
        .withPrivate(key: "identifier", value: identifier)
        .withPrivate(key: "dataSize", value: "\(data.count)")
    )
    await logger.log(.debug, "Store data operation started", context: context)

    // Perform the operation
    let result = await wrapped.storeData(data: data, identifier: identifier)

    // Log the result
    if case let .failure(error) = result {
      await logger.logError(error, context: context)
    } else {
      await logger.log(.info, "Store data operation successful", context: context)
    }

    return result
  }

  public func retrieveData(
    identifier: String
  ) async -> Result<Data, SecurityStorageError> {
    let context = EnhancedLogContext(
      domainName: "CryptoService",
      operationName: "retrieveData",
      source: "EnhancedLoggingCryptoServiceImpl.retrieveData",
      metadata: LogMetadataDTOCollection()
        .withPrivate(key: "identifier", value: identifier)
    )
    await logger.log(.debug, "Retrieve data operation started", context: context)

    // Perform the operation
    let result = await wrapped.retrieveData(identifier: identifier)

    // Log the result
    switch result {
    case let .success(retrievedData):
      let updatedMetadata = context.metadata.withPrivate(key: "retrievedDataSize", value: "\(retrievedData.count)")
      let successContext = EnhancedLogContext(
        domainName: context.domainName,
        operationName: "retrieveData",
        source: context.source,
        correlationID: context.correlationID,
        metadata: updatedMetadata
      )
      await logger.log(.info, "Retrieve data operation successful", context: successContext)
    case let .failure(error):
      await logger.logError(error, context: context)
    }

    return result
  }

  public func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    let context = EnhancedLogContext(
      domainName: "CryptoService",
      operationName: "exportData",
      source: "EnhancedLoggingCryptoServiceImpl.exportData",
      metadata: LogMetadataDTOCollection()
        .withPrivate(key: "identifier", value: identifier)
    )
    await logger.log(.warning, "Export data operation started (potential security risk)", context: context)

    // Perform the operation
    let result = await wrapped.exportData(identifier: identifier)

    // Log the result
    switch result {
    case let .success(exportedData):
      let updatedMetadata = context.metadata.withPrivate(key: "exportedDataSize", value: "\(exportedData.count)")
      let successContext = EnhancedLogContext(
        domainName: context.domainName,
        operationName: "exportData",
        source: context.source,
        correlationID: context.correlationID,
        metadata: updatedMetadata
      )
      await logger.log(.info, "Export data operation successful", context: successContext)
    case let .failure(error):
      await logger.logError(error, context: context)
    }

    return result
  }

  public func importData(
    _ data: [UInt8],
    customIdentifier: String?
  ) async -> Result<String, SecurityStorageError> {
    // Create an enhanced log context with proper privacy tags
    let context = EnhancedLogContext(
      domainName: "CryptoService",
      operationName: "importData",
      source: "EnhancedLoggingCryptoServiceImpl.importData_UInt8",
      metadata: LogMetadataDTOCollection()
        .withPrivate(key: "dataSize", value: "\(data.count)")
        .withPublic(key: "customIdentifier", value: customIdentifier ?? "nil")
    )
    await logger.log(.debug, "Import data ([UInt8]) operation started", context: context)

    // Perform the operation
    let result = await wrapped.importData(data, customIdentifier: customIdentifier)

    // Log the result
    switch result {
    case let .success(storedIdentifier):
      let updatedMetadata = context.metadata.withPrivate(key: "storedIdentifier", value: storedIdentifier)
      let successContext = EnhancedLogContext(
        domainName: context.domainName,
        operationName: "importData",
        source: context.source,
        correlationID: context.correlationID,
        metadata: updatedMetadata
      )
      await logger.log(.info, "Import data ([UInt8]) operation successful", context: successContext)
    case let .failure(error):
      await logger.logError(error, context: context)
    }

    return result
  }

  public func importData(
    _ data: Data,
    customIdentifier: String
  ) async -> Result<String, SecurityStorageError> {
    let context = EnhancedLogContext(
      domainName: "CryptoService",
      operationName: "importData",
      source: "EnhancedLoggingCryptoServiceImpl.importData_Data",
      metadata: LogMetadataDTOCollection()
        .withPrivate(key: "dataSize", value: "\(data.count)")
        .withPublic(key: "customIdentifier", value: customIdentifier)
    )
    await logger.log(.debug, "Import data (Data) operation started", context: context)

    // Perform the operation
    let result = await wrapped.importData(data, customIdentifier: customIdentifier)

    // Log the result
    switch result {
    case let .success(storedIdentifier):
      let updatedMetadata = context.metadata.withPrivate(key: "storedIdentifier", value: storedIdentifier)
      let successContext = EnhancedLogContext(
        domainName: context.domainName,
        operationName: "importData",
        source: context.source,
        correlationID: context.correlationID,
        metadata: updatedMetadata
      )
      await logger.log(.info, "Import data (Data) operation successful", context: successContext)
    case let .failure(error):
      await logger.logError(error, context: context)
    }

    return result
  }

  public func deleteData(
    identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    let context = EnhancedLogContext(
      domainName: "CryptoService",
      operationName: "deleteData",
      source: "EnhancedLoggingCryptoServiceImpl.deleteData",
      metadata: LogMetadataDTOCollection()
        .withPrivate(key: "identifier", value: identifier)
    )
    await logger.log(.debug, "Delete data operation started", context: context)

    // Perform the operation
    let result = await wrapped.deleteData(identifier: identifier)

    // Log the result
    if case let .failure(error) = result {
      await logger.logError(error, context: context)
    } else {
      let successContext = EnhancedLogContext(
        domainName: context.domainName,
        operationName: "deleteData",
        source: context.source,
        correlationID: context.correlationID,
        metadata: context.metadata
      )
      await logger.log(.info, "Delete data operation successful", context: successContext)
    }

    return result
  }

  // MARK: - Signing (Stubs - Needs implementation if wrapped supports it)

  public func signData(dataIdentifier: String, keyIdentifier: String, options: CoreSecurityTypes.SigningOptions? = nil) async -> Result<String, SecurityStorageError> {
    // Create context for logging
    let context = EnhancedLogContext(
      domainName: "CryptoService",
      operationName: "signData",
      source: "EnhancedLoggingCryptoServiceImpl.signData",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "dataIdentifier", value: dataIdentifier)
        .withPrivate(key: "keyIdentifier", value: keyIdentifier)
    )
    // TODO: Add logging & delegate to wrapped.signData
    await logger.log(.warning, "signData not implemented in EnhancedLoggingCryptoServiceImpl", context: context)
    return .failure(.unsupportedOperation)
  }

  public func verifySignature(dataIdentifier: String, signatureIdentifier: String, keyIdentifier: String) async -> Result<Bool, SecurityStorageError> {
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
    // TODO: Add logging & delegate to wrapped.verifySignature
    await logger.log(.warning, "verifySignature not implemented in EnhancedLoggingCryptoServiceImpl", context: context)
    return .failure(.unsupportedOperation)
  }

  public func generateHash(
    dataIdentifier: String,
    options: HashingOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    let context = EnhancedLogContext(
      domainName: "CryptoService",
      operationName: "generateHash",
      source: "EnhancedLoggingCryptoServiceImpl.generateHash",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "dataIdentifier", value: dataIdentifier)
    )
    await logger.log(.debug, "Generate hash operation started", context: context)

    let result = await wrapped.generateHash(dataIdentifier: dataIdentifier, options: options)

    // Log the result
    switch result {
    case let .success(hashIdentifier):
      let updatedMetadata = context.metadata.withPublic(key: "hashIdentifier", value: hashIdentifier)
      let successContext = EnhancedLogContext(
        domainName: context.domainName,
        operationName: "generateHash",
        source: context.source,
        correlationID: context.correlationID,
        metadata: updatedMetadata
      )
      await logger.log(.info, "Generate hash operation successful", context: successContext)
    case let .failure(error):
      await logger.logError(error, context: context)
    }

    return result
  }
}
