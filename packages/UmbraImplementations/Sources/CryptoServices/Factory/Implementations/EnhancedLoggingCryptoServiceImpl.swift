import Foundation
import LoggingInterfaces
import LoggingTypes
import OSLog
import SecurityCoreInterfaces
import UmbraErrors

/**
 # EnhancedLoggingCryptoServiceImpl

 A decorator implementation of CryptoServiceProtocol that adds privacy-aware logging capabilities.
 This implementation wraps another CryptoServiceProtocol implementation and provides enhanced
 logging with proper privacy tags for sensitive data.
 */
public actor EnhancedLoggingCryptoServiceImpl: CryptoServiceProtocol {
  /// The wrapped implementation
  private let wrapped: CryptoServiceProtocol
  /// The secure storage, required by the protocol
  public let secureStorage: SecureStorageProtocol
  /// Enhanced privacy-aware logger
  private let logger: PrivacyAwareLoggingProtocol

  /**
   Initialises a new enhanced logging crypto service.

   - Parameters:
     - wrapped: The crypto service to wrap.
     - secureStorage: The secure storage to use (required by protocol).
     - logger: The privacy-aware logger to use for logging.
   */
  public init(
    wrapped: CryptoServiceProtocol,
    secureStorage: SecureStorageProtocol,
    logger: PrivacyAwareLoggingProtocol
  ) {
    self.wrapped = wrapped
    self.secureStorage = secureStorage
    self.logger = logger
  }

  public func encrypt(
    dataIdentifier: String,
    keyIdentifier: String,
    options: EncryptionOptions? = nil
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
      let finalContext = context.withMetadata(context.metadata.withPublic(key: "encryptedIdentifier", value: encryptedIdentifier))
      await logger.log(.info, "Encrypt operation successful", context: finalContext)
    case let .failure(error):
      let finalContext = context.withMetadata(context.metadata.withError(error))
      await logger.log(.error, "Encrypt operation failed", context: finalContext)
    }

    return result
  }

  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options: SecurityCoreInterfaces.DecryptionOptions? = nil
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
      let finalContext = context.withMetadata(context.metadata.withPublic(key: "decryptedIdentifier", value: decryptedIdentifier))
      await logger.log(.info, "Decrypt operation successful", context: finalContext)
    case let .failure(error):
      let finalContext = context.withMetadata(context.metadata.withError(error))
      await logger.log(.error, "Decrypt operation failed", context: finalContext)
    }

    return result
  }

  public func generateHash(
    dataIdentifier: String,
    options: HashingOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    let algorithm = options?.algorithm ?? .sha256
    let context = EnhancedLogContext(
      domainName: "CryptoService",
      operationName: "generateHash",
      source: "EnhancedLoggingCryptoServiceImpl.hash",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "dataIdentifier", value: dataIdentifier)
        .withPublic(key: "algorithm", value: "\(algorithm)")
    )
    await logger.log(.debug, "Hash operation started", context: context)

    // Perform the operation
    let result = await wrapped.generateHash(
      dataIdentifier: dataIdentifier,
      options: options
    )

    // Log the result
    switch result {
    case let .success(hashIdentifier):
      let finalContext = context.withMetadata(context.metadata.withPublic(key: "hashIdentifier", value: hashIdentifier))
      await logger.log(.info, "Hash operation successful", context: finalContext)
    case let .failure(error):
      let finalContext = context.withMetadata(context.metadata.withError(error))
      await logger.log(.error, "Hash operation failed", context: finalContext)
    }

    return result
  }

  public func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options: SecurityCoreInterfaces.HashingOptions? = nil
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
      let finalContext = context.withMetadata(context.metadata.withPublic(key: "isValid", value: "\(isValid)"))
      await logger.log(.info, "Verify hash operation successful", context: finalContext)
    case let .failure(error):
      let finalContext = context.withMetadata(context.metadata.withError(error))
      await logger.log(.error, "Verify hash operation failed", context: finalContext)
    }

    return result
  }

  public func generateKey(
    length: Int,
    options: SecurityCoreInterfaces.KeyGenerationOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    let context = EnhancedLogContext(
      domainName: "CryptoService",
      operationName: "generateKey",
      source: "EnhancedLoggingCryptoServiceImpl.generateKey",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "keyLength", value: length)
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
      let finalContext = context.withMetadata(context.metadata.withPublic(key: "keyIdentifier", value: keyIdentifier))
      await logger.log(.info, "Generate key operation successful", context: finalContext)
    case let .failure(error):
      let finalContext = context.withMetadata(context.metadata.withError(error))
      await logger.log(.error, "Generate key operation failed", context: finalContext)
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
        .withPrivate(key: "identifier", value: identifier) // Identifier might be sensitive
        .withPrivate(key: "dataSize", value: data.count), // Data size might be sensitive
    )
    await logger.log(.debug, "Store data operation started", context: context)

    // Perform the operation
    let result = await wrapped.storeData(data: data, identifier: identifier)

    // Log the result
    if case let .failure(error) = result {
      let finalContext = context.withMetadata(context.metadata.withError(error))
      await logger.log(.error, "Store data operation failed", context: finalContext)
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
        .withPrivate(key: "identifier", value: identifier) // Identifier might be sensitive
    )
    await logger.log(.debug, "Retrieve data operation started", context: context)

    // Perform the operation
    let result = await wrapped.retrieveData(identifier: identifier)

    // Log the result
    switch result {
    case let .success(retrievedData):
      let finalContext = context.withMetadata(context.metadata.withPrivate(key: "retrievedDataSize", value: retrievedData.count))
      await logger.log(.info, "Retrieve data operation successful", context: finalContext)
    case let .failure(error):
      let finalContext = context.withMetadata(context.metadata.withError(error))
      await logger.log(.error, "Retrieve data operation failed", context: finalContext)
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
        .withPrivate(key: "identifier", value: identifier) // Identifier might be sensitive
    )
    await logger.log(.warning, "Export data operation started (potential security risk)", context: context)

    // Perform the operation
    let result = await wrapped.exportData(identifier: identifier)

    // Log the result
    switch result {
    case let .success(exportedData):
      let finalContext = context.withMetadata(context.metadata.withPrivate(key: "exportedDataSize", value: exportedData.count))
      await logger.log(.info, "Export data operation successful", context: finalContext)
    case let .failure(error):
      let finalContext = context.withMetadata(context.metadata.withError(error))
      await logger.log(.error, "Export data operation failed", context: finalContext)
    }

    return result
  }

  public func importData(
    _ data: Data,
    customIdentifier: String?
  ) async -> Result<String, SecurityStorageError> {
    // Create an enhanced log context with proper privacy tags
    let context = EnhancedLogContext(
      domainName: "CryptoService",
      operationName: "importData",
      source: "EnhancedLoggingCryptoServiceImpl.importData",
      metadata: LogMetadataDTOCollection()
        .withPrivate(key: "customIdentifier", value: customIdentifier ?? "nil") // Identifier might be sensitive
        .withPrivate(key: "dataSize", value: data.count) // Data size might be sensitive
    )
    await logger.log(.debug, "Import data operation started", context: context)

    // Perform the operation
    // Handle optional customIdentifier - assuming wrapped needs non-optional or handles nil
    // If wrapped.importData requires non-optional, need better handling
    let result = await wrapped.importData(data, customIdentifier: customIdentifier ?? "") // Provide default "" if nil

    // Log the result
    switch result {
    case let .success(storedIdentifier):
      let finalContext = context.withMetadata(context.metadata.withPrivate(key: "storedIdentifier", value: storedIdentifier))
      await logger.log(.info, "Import data operation successful", context: finalContext)
    case let .failure(error):
      let finalContext = context.withMetadata(context.metadata.withError(error))
      await logger.log(.error, "Import data operation failed", context: finalContext)
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
        .withPrivate(key: "identifier", value: identifier) // Identifier might be sensitive
    )
    await logger.log(.debug, "Delete data operation started", context: context)

    // Perform the operation
    let result = await wrapped.deleteData(identifier: identifier)

    // Log the result
    if case let .failure(error) = result {
      let finalContext = context.withMetadata(context.metadata.withError(error))
      await logger.log(.error, "Delete data operation failed", context: finalContext)
    } else {
      await logger.log(.info, "Delete data operation successful", context: context)
    }

    return result
  }

  // MARK: - Signing (Stubs - Needs implementation if wrapped supports it)

  public func signData(dataIdentifier: String, keyIdentifier: String, options: SecurityCoreInterfaces.SigningOptions?) async -> Result<String, SecurityStorageError> {
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
}
