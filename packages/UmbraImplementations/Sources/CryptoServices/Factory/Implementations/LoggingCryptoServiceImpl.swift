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
    let context = CryptoLogContext(
      operation: "encrypt",
      identifier: dataIdentifier,
      status: "started",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "dataIdentifier", value: dataIdentifier)
        .withPrivate(key: "keyIdentifier", value: keyIdentifier)
    )
    
    // Add algorithm information if available
    let contextWithAlgorithm: CryptoLogContext
    if let algorithm = options?.algorithm {
      contextWithAlgorithm = context.withPublicMetadata(
        key: "algorithm", 
        value: "\(algorithm)"
      )
    } else {
      contextWithAlgorithm = context
    }
    
    await logger.info(
      "Encrypting data with identifier \(dataIdentifier)",
      context: contextWithAlgorithm
    )

    let result = await wrapped.encrypt(
      dataIdentifier: dataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )

    switch result {
      case let .success(identifier):
        let successContext = context.withStatus("success")
          .withPublicMetadata(key: "encryptedIdentifier", value: identifier)
        
        await logger.info(
          "Successfully encrypted data to identifier: \(identifier)",
          context: successContext
        )
      case let .failure(error):
        let errorContext = context.withStatus("failed")
          .withPublicMetadata(key: "errorDescription", value: error.localizedDescription)
        
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
    let context = CryptoLogContext(
      operation: "decrypt",
      identifier: encryptedDataIdentifier,
      status: "started",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "encryptedDataIdentifier", value: encryptedDataIdentifier)
        .withPrivate(key: "keyIdentifier", value: keyIdentifier)
    )
    
    // Add algorithm information if available
    let contextWithAlgorithm: CryptoLogContext
    if let algorithm = options?.algorithm {
      contextWithAlgorithm = context.withPublicMetadata(
        key: "algorithm", 
        value: "\(algorithm)"
      )
    } else {
      contextWithAlgorithm = context
    }
    
    await logger.info(
      "Decrypting data with identifier \(encryptedDataIdentifier)",
      context: contextWithAlgorithm
    )

    let result = await wrapped.decrypt(
      encryptedDataIdentifier: encryptedDataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )

    switch result {
      case let .success(identifier):
        let successContext = context.withStatus("success")
          .withPublicMetadata(key: "decryptedIdentifier", value: identifier)
        
        await logger.info(
          "Successfully decrypted data to identifier: \(identifier)",
          context: successContext
        )
      case let .failure(error):
        let errorContext = context.withStatus("failed")
          .withPublicMetadata(key: "errorDescription", value: error.localizedDescription)
        
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
    let context = CryptoLogContext(
      operation: "hash",
      identifier: dataIdentifier,
      status: "started",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "dataIdentifier", value: dataIdentifier)
    )
    
    // Add algorithm information if available
    let contextWithAlgorithm: CryptoLogContext
    if let algorithm = options?.algorithm {
      contextWithAlgorithm = context.withPublicMetadata(
        key: "algorithm", 
        value: "\(algorithm)"
      )
    } else {
      contextWithAlgorithm = context
    }
    
    await logger.info(
      "Hashing data with identifier \(dataIdentifier)",
      context: contextWithAlgorithm
    )

    let result = await wrapped.hash(
      dataIdentifier: dataIdentifier,
      options: options
    )

    switch result {
      case let .success(identifier):
        let successContext = context.withStatus("success")
          .withHashedMetadata(key: "hashIdentifier", value: identifier)
        
        await logger.info(
          "Successfully hashed data to identifier: \(identifier)",
          context: successContext
        )
      case let .failure(error):
        let errorContext = context.withStatus("failed")
          .withPublicMetadata(key: "errorDescription", value: error.localizedDescription)
        
        await logger.error(
          "Failed to hash data: \(error)",
          context: errorContext
        )
    }

    return result
  }

  /**
   Verifies a hash with logging.

   - Parameters:
     - dataIdentifier: Identifier for the data to verify
     - hashIdentifier: Identifier for the expected hash
     - options: Optional hashing options
   - Returns: Whether the hash is valid or an error
   */
  public func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options: CoreSecurityTypes.HashingOptions? = nil
  ) async -> Result<Bool, SecurityStorageError> {
    // Create a log context with proper privacy classification
    let context = CryptoLogContext(
      operation: "verifyHash",
      identifier: dataIdentifier,
      status: "started",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "dataIdentifier", value: dataIdentifier)
        .withPublic(key: "hashIdentifier", value: hashIdentifier)
    )
    
    // Add algorithm information if available
    let contextWithAlgorithm: CryptoLogContext
    if let algorithm = options?.algorithm {
      contextWithAlgorithm = context.withPublicMetadata(
        key: "algorithm", 
        value: "\(algorithm)"
      )
    } else {
      contextWithAlgorithm = context
    }
    
    await logger.info(
      "Verifying hash for data with identifier \(dataIdentifier) against hash \(hashIdentifier)",
      context: contextWithAlgorithm
    )

    let result = await wrapped.verifyHash(
      dataIdentifier: dataIdentifier,
      hashIdentifier: hashIdentifier,
      options: options
    )

    switch result {
      case let .success(matches):
        let successContext = context.withStatus("success")
          .withPublicMetadata(key: "matches", value: matches ? "true" : "false")
        
        await logger.info(
          "Hash verification result: \(matches ? "Match" : "No match")",
          context: successContext
        )
      case let .failure(error):
        let errorContext = context.withStatus("failed")
          .withPublicMetadata(key: "errorDescription", value: error.localizedDescription)
        
        await logger.error(
          "Failed to verify hash: \(error)",
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
    let context = CryptoLogContext(
      operation: "generateKey",
      status: "started",
      metadata: LogMetadataDTOCollection()
    )
    
    // Add key type and algorithm information if available
    var contextWithOptions = context
    if let keyType = options?.keyType {
      contextWithOptions = contextWithOptions.withPublicMetadata(
        key: "keyType", 
        value: "\(keyType)"
      )
    }
    
    if let algorithm = options?.algorithm {
      contextWithOptions = contextWithOptions.withPublicMetadata(
        key: "algorithm", 
        value: "\(algorithm)"
      )
    }
    
    await logger.info(
      "Generating cryptographic key",
      context: contextWithOptions
    )

    let result = await wrapped.generateKey(options: options)

    switch result {
      case let .success(identifier):
        let successContext = context.withStatus("success")
          .withSensitiveMetadata(key: "keyIdentifier", value: identifier)
        
        await logger.info(
          "Successfully generated key with identifier: \(identifier)",
          context: successContext
        )
      case let .failure(error):
        let errorContext = context.withStatus("failed")
          .withPublicMetadata(key: "errorDescription", value: error.localizedDescription)
        
        await logger.error(
          "Failed to generate key: \(error)",
          context: errorContext
        )
    }

    return result
  }

  /**
   Stores data with logging.

   - Parameters:
     - data: Data to store
     - options: Optional storage options
   - Returns: Void or an error
   */
  public func storeData(
    data: Data,
    options: CoreSecurityTypes.StorageOptions? = nil
  ) async -> Result<Void, SecurityStorageError> {
    // Create a log context with proper privacy classification
    let context = CryptoLogContext(
      operation: "storeData",
      status: "started",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "dataSize", value: "\(data.count)")
    )
    
    // Add storage type if available
    let contextWithOptions: CryptoLogContext
    if let storageType = options?.storageType {
      contextWithOptions = context.withPublicMetadata(
        key: "storageType", 
        value: "\(storageType)"
      )
    } else {
      contextWithOptions = context
    }
    
    await logger.info(
      "Storing data (\(data.count) bytes)",
      context: contextWithOptions
    )

    let result = await wrapped.storeData(
      data: data,
      options: options
    )

    switch result {
      case .success:
        let successContext = context.withStatus("success")
        
        await logger.info(
          "Successfully stored data",
          context: successContext
        )
      case let .failure(error):
        let errorContext = context.withStatus("failed")
          .withPublicMetadata(key: "errorDescription", value: error.localizedDescription)
        
        await logger.error(
          "Failed to store data: \(error)",
          context: errorContext
        )
    }

    return result
  }

  /**
   Retrieves data with logging.

   - Parameters:
     - dataIdentifier: Identifier for the data to retrieve
     - options: Optional retrieval options
   - Returns: Data or an error
   */
  public func retrieveData(
    dataIdentifier: String,
    options: CoreSecurityTypes.StorageOptions? = nil
  ) async -> Result<Data, SecurityStorageError> {
    // Create a log context with proper privacy classification
    let context = CryptoLogContext(
      operation: "retrieveData",
      identifier: dataIdentifier,
      status: "started",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "dataIdentifier", value: dataIdentifier)
    )
    
    // Add storage type if available
    let contextWithOptions: CryptoLogContext
    if let storageType = options?.storageType {
      contextWithOptions = context.withPublicMetadata(
        key: "storageType", 
        value: "\(storageType)"
      )
    } else {
      contextWithOptions = context
    }
    
    await logger.info(
      "Retrieving data with identifier \(dataIdentifier)",
      context: contextWithOptions
    )

    let result = await wrapped.retrieveData(
      dataIdentifier: dataIdentifier,
      options: options
    )

    switch result {
      case let .success(data):
        let successContext = context.withStatus("success")
          .withPublicMetadata(key: "dataSize", value: "\(data.count)")
        
        await logger.info(
          "Successfully retrieved data (\(data.count) bytes)",
          context: successContext
        )
      case let .failure(error):
        let errorContext = context.withStatus("failed")
          .withPublicMetadata(key: "errorDescription", value: error.localizedDescription)
        
        await logger.error(
          "Failed to retrieve data: \(error)",
          context: errorContext
        )
    }

    return result
  }

  /**
   Imports data with logging.

   - Parameters:
     - data: Data to import
     - options: Optional import options
   - Returns: Identifier for the imported data or an error
   */
  public func importData(
    data: Data,
    options: CoreSecurityTypes.ImportOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    // Create a log context with proper privacy classification
    let context = CryptoLogContext(
      operation: "importData",
      status: "started",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "dataSize", value: "\(data.count)")
    )
    
    // Add import type if available
    let contextWithOptions: CryptoLogContext
    if let importType = options?.importType {
      contextWithOptions = context.withPublicMetadata(
        key: "importType", 
        value: "\(importType)"
      )
    } else {
      contextWithOptions = context
    }
    
    await logger.info(
      "Importing data (\(data.count) bytes)",
      context: contextWithOptions
    )

    let result = await wrapped.importData(
      data: data,
      options: options
    )

    switch result {
      case let .success(identifier):
        let successContext = context.withStatus("success")
          .withPrivateMetadata(key: "importedIdentifier", value: identifier)
        
        await logger.info(
          "Successfully imported data with identifier: \(identifier)",
          context: successContext
        )
      case let .failure(error):
        let errorContext = context.withStatus("failed")
          .withPublicMetadata(key: "errorDescription", value: error.localizedDescription)
        
        await logger.error(
          "Failed to import data: \(error)",
          context: errorContext
        )
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
    // Create a log context with proper privacy classification
    let context = CryptoLogContext(
      operation: "signData",
      identifier: dataIdentifier,
      status: "started",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "dataIdentifier", value: dataIdentifier)
        .withPrivate(key: "keyIdentifier", value: keyIdentifier)
    )
    
    // Add algorithm information if available
    let contextWithAlgorithm: CryptoLogContext
    if let algorithm = options?.algorithm {
      contextWithAlgorithm = context.withPublicMetadata(
        key: "algorithm", 
        value: "\(algorithm)"
      )
    } else {
      contextWithAlgorithm = context
    }
    
    await logger.info(
      "Signing data with identifier \(dataIdentifier)",
      context: contextWithAlgorithm
    )

    let result = await wrapped.signData(
      dataIdentifier: dataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )

    switch result {
      case let .success(signatureIdentifier):
        let successContext = context.withStatus("success")
          .withPublicMetadata(key: "signatureIdentifier", value: signatureIdentifier)
        
        await logger.info(
          "Successfully signed data with signature identifier: \(signatureIdentifier)",
          context: successContext
        )
      case let .failure(error):
        let errorContext = context.withStatus("failed")
          .withPublicMetadata(key: "errorDescription", value: error.localizedDescription)
        
        await logger.error(
          "Failed to sign data: \(error)",
          context: errorContext
        )
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
    // Create a log context with proper privacy classification
    let context = CryptoLogContext(
      operation: "verifySignature",
      identifier: dataIdentifier,
      status: "started",
      metadata: LogMetadataDTOCollection()
        .withPublic(key: "dataIdentifier", value: dataIdentifier)
        .withPublic(key: "signatureIdentifier", value: signatureIdentifier)
        .withPrivate(key: "keyIdentifier", value: keyIdentifier)
    )
    
    // Add algorithm information if available
    let contextWithAlgorithm: CryptoLogContext
    if let algorithm = options?.algorithm {
      contextWithAlgorithm = context.withPublicMetadata(
        key: "algorithm", 
        value: "\(algorithm)"
      )
    } else {
      contextWithAlgorithm = context
    }
    
    await logger.info(
      "Verifying signature for data with identifier \(dataIdentifier)",
      context: contextWithAlgorithm
    )

    let result = await wrapped.verifySignature(
      dataIdentifier: dataIdentifier,
      signatureIdentifier: signatureIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )

    switch result {
      case let .success(isValid):
        let successContext = context.withStatus("success")
          .withPublicMetadata(key: "isValid", value: isValid ? "true" : "false")
        
        await logger.info(
          "Signature verification result: \(isValid ? "Valid" : "Invalid")",
          context: successContext
        )
      case let .failure(error):
        let errorContext = context.withStatus("failed")
          .withPublicMetadata(key: "errorDescription", value: error.localizedDescription)
        
        await logger.error(
          "Failed to verify signature: \(error)",
          context: errorContext
        )
    }

    return result
  }
}
