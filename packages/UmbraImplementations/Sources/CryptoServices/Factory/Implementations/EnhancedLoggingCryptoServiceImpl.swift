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
    self.wrapped=wrapped
    self.secureStorage=secureStorage
    self.logger=logger
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
    options: CoreSecurityTypes.EncryptionOptions?=nil
  ) async -> Result<String, SecurityStorageError> {
    // Create an enhanced log context with proper privacy tags
    let context=createLogContext(
      operation: "encrypt",
      algorithm: options?.algorithm,
      correlationID: nil,
      additionalMetadata: [
        ("dataIdentifier", (value: dataIdentifier, privacyLevel: .public)),
        ("keyIdentifier", (value: keyIdentifier, privacyLevel: .private))
      ],
      category: "Security"
    )

    await logger.log(.debug, "Encrypt operation started", context: context)

    // Perform the operation
    let result=await wrapped.encrypt(
      dataIdentifier: dataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )

    // Log the result
    switch result {
      case let .success(encryptedIdentifier):
        // Add public metadata for the successful operation
        let successContext=createLogContext(
          operation: "encrypt",
          algorithm: options?.algorithm,
          correlationID: nil,
          additionalMetadata: [
            ("dataIdentifier", (value: dataIdentifier, privacyLevel: .public)),
            ("keyIdentifier", (value: keyIdentifier, privacyLevel: .private)),
            ("encryptedIdentifier", (value: encryptedIdentifier, privacyLevel: .public))
          ],
          category: "Security"
        )
        // Log with the new context
        await logger.log(.info, "Encrypt operation successful", context: successContext)
      case let .failure(error):
        let errorContext=createLogContext(
          operation: "encrypt",
          algorithm: options?.algorithm,
          correlationID: nil,
          additionalMetadata: [
            ("dataIdentifier", (value: dataIdentifier, privacyLevel: .public)),
            ("keyIdentifier", (value: keyIdentifier, privacyLevel: .private)),
            ("errorDescription", (value: error.localizedDescription, privacyLevel: .public))
          ],
          category: "Security"
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
    options: CoreSecurityTypes.EncryptionOptions?=nil
  ) async -> Result<String, SecurityStorageError> {
    let context=createLogContext(
      operation: "decrypt",
      algorithm: options?.algorithm,
      correlationID: nil,
      additionalMetadata: [
        ("encryptedDataIdentifier", (value: encryptedDataIdentifier, privacyLevel: .public)),
        ("keyIdentifier", (value: keyIdentifier, privacyLevel: .private))
      ],
      category: "Security"
    )

    await logger.log(.debug, "Decrypt operation started", context: context)

    // Perform the operation
    let result=await wrapped.decrypt(
      encryptedDataIdentifier: encryptedDataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )

    // Log the result
    switch result {
      case let .success(decryptedIdentifier):
        let successContext=createLogContext(
          operation: "decrypt",
          algorithm: options?.algorithm,
          correlationID: nil,
          additionalMetadata: [
            ("encryptedDataIdentifier", (value: encryptedDataIdentifier, privacyLevel: .public)),
            ("keyIdentifier", (value: keyIdentifier, privacyLevel: .private)),
            ("decryptedIdentifier", (value: decryptedIdentifier, privacyLevel: .public))
          ],
          category: "Security"
        )
        await logger.log(.info, "Decrypt operation successful", context: successContext)
      case let .failure(error):
        let errorContext=createLogContext(
          operation: "decrypt",
          algorithm: options?.algorithm,
          correlationID: nil,
          additionalMetadata: [
            ("encryptedDataIdentifier", (value: encryptedDataIdentifier, privacyLevel: .public)),
            ("keyIdentifier", (value: keyIdentifier, privacyLevel: .private)),
            ("errorDescription", (value: error.localizedDescription, privacyLevel: .public))
          ],
          category: "Security"
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
    options: CoreSecurityTypes.HashingOptions?=nil
  ) async -> Result<String, SecurityStorageError> {
    let algorithm=options?.algorithm ?? .sha256
    let context=createLogContext(
      operation: "hash",
      algorithm: "\(algorithm)",
      correlationID: nil,
      additionalMetadata: [
        ("dataIdentifier", (value: dataIdentifier, privacyLevel: .public)),
        ("algorithm", (value: "\(algorithm)", privacyLevel: .public))
      ],
      category: "Security"
    )
    await logger.log(.debug, "Hash operation started", context: context)

    // Perform the operation
    let result=await wrapped.hash(
      dataIdentifier: dataIdentifier,
      options: options
    )

    // Log the result
    switch result {
      case let .success(hashIdentifier):
        let successContext=createLogContext(
          operation: "hash",
          algorithm: "\(algorithm)",
          correlationID: nil,
          additionalMetadata: [
            ("dataIdentifier", (value: dataIdentifier, privacyLevel: .public)),
            ("algorithm", (value: "\(algorithm)", privacyLevel: .public)),
            ("hashIdentifier", (value: hashIdentifier, privacyLevel: .public))
          ],
          category: "Security"
        )
        await logger.log(.info, "Hash operation successful", context: successContext)
      case let .failure(error):
        let errorContext=createLogContext(
          operation: "hash",
          algorithm: "\(algorithm)",
          correlationID: nil,
          additionalMetadata: [
            ("dataIdentifier", (value: dataIdentifier, privacyLevel: .public)),
            ("algorithm", (value: "\(algorithm)", privacyLevel: .public)),
            ("errorDescription", (value: error.localizedDescription, privacyLevel: .public))
          ],
          category: "Security"
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
    options: CoreSecurityTypes.HashingOptions?=nil
  ) async -> Result<Bool, SecurityStorageError> {
    let algorithm=options?.algorithm ?? .sha256
    let context=createLogContext(
      operation: "verifyHash",
      algorithm: "\(algorithm)",
      correlationID: nil,
      additionalMetadata: [
        ("dataIdentifier", (value: dataIdentifier, privacyLevel: .public)),
        ("hashIdentifier", (value: hashIdentifier, privacyLevel: .public)),
        ("algorithm", (value: "\(algorithm)", privacyLevel: .public))
      ],
      category: "Security"
    )
    await logger.log(.debug, "Verify hash operation started", context: context)

    // Perform the operation
    let result=await wrapped.verifyHash(
      dataIdentifier: dataIdentifier,
      hashIdentifier: hashIdentifier,
      options: options
    )

    // Log the result
    switch result {
      case let .success(matches):
        let successContext=createLogContext(
          operation: "verifyHash",
          algorithm: "\(algorithm)",
          correlationID: nil,
          additionalMetadata: [
            ("dataIdentifier", (value: dataIdentifier, privacyLevel: .public)),
            ("hashIdentifier", (value: hashIdentifier, privacyLevel: .public)),
            ("algorithm", (value: "\(algorithm)", privacyLevel: .public)),
            ("matches", (value: "\(matches)", privacyLevel: .public))
          ],
          category: "Security"
        )
        await logger.log(.info, "Verify hash operation successful", context: successContext)
      case let .failure(error):
        let errorContext=createLogContext(
          operation: "verifyHash",
          algorithm: "\(algorithm)",
          correlationID: nil,
          additionalMetadata: [
            ("dataIdentifier", (value: dataIdentifier, privacyLevel: .public)),
            ("hashIdentifier", (value: hashIdentifier, privacyLevel: .public)),
            ("algorithm", (value: "\(algorithm)", privacyLevel: .public)),
            ("errorDescription", (value: error.localizedDescription, privacyLevel: .public))
          ],
          category: "Security"
        )
        await logger.error("Verify hash operation failed", context: errorContext)
    }

    return result
  }

  /**
   Stores data in the secure storage.

   - Parameters:
     - data: The data to store
     - identifier: The identifier to use for the data
   - Returns: Success or an error
   */
  public func storeData(
    data: Data,
    identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    let context=createLogContext(
      operation: "storeData",
      correlationID: nil,
      additionalMetadata: [
        ("dataIdentifier", (value: identifier, privacyLevel: .public)),
        ("dataSize", (value: "\(data.count)", privacyLevel: .public))
      ],
      category: "Security"
    )

    await logger.log(.debug, "Store data operation started", context: context)

    // Perform the operation
    let result=await wrapped.storeData(
      data: data,
      identifier: identifier
    )

    // Log the result
    switch result {
      case .success:
        let successContext=createLogContext(
          operation: "storeData",
          correlationID: nil,
          additionalMetadata: [
            ("dataIdentifier", (value: identifier, privacyLevel: .public)),
            ("dataSize", (value: "\(data.count)", privacyLevel: .public))
          ],
          category: "Security"
        )
        await logger.log(.info, "Store data operation successful", context: successContext)
      case let .failure(error):
        let errorContext=createLogContext(
          operation: "storeData",
          correlationID: nil,
          additionalMetadata: [
            ("dataIdentifier", (value: identifier, privacyLevel: .public)),
            ("dataSize", (value: "\(data.count)", privacyLevel: .public)),
            ("errorDescription", (value: error.localizedDescription, privacyLevel: .public))
          ],
          category: "Security"
        )
        await logger.error("Store data operation failed", context: errorContext)
    }

    return result
  }

  /**
   Retrieves data from the secure storage.

   - Parameter identifier: Identifier for the data to retrieve
   - Returns: The retrieved data or an error
   */
  public func retrieveData(
    identifier: String
  ) async -> Result<Data, SecurityStorageError> {
    let context=createLogContext(
      operation: "retrieveData",
      correlationID: nil,
      additionalMetadata: [
        ("dataIdentifier", (value: identifier, privacyLevel: .public))
      ],
      category: "Security"
    )

    await logger.log(.debug, "Retrieve data operation started", context: context)

    // Perform the operation
    let result=await wrapped.retrieveData(
      identifier: identifier
    )

    // Log the result
    switch result {
      case let .success(data):
        let successContext=createLogContext(
          operation: "retrieveData",
          correlationID: nil,
          additionalMetadata: [
            ("dataIdentifier", (value: identifier, privacyLevel: .public)),
            ("dataSize", (value: "\(data.count)", privacyLevel: .public))
          ],
          category: "Security"
        )
        await logger.log(.info, "Retrieve data operation successful", context: successContext)
      case let .failure(error):
        let errorContext=createLogContext(
          operation: "retrieveData",
          correlationID: nil,
          additionalMetadata: [
            ("dataIdentifier", (value: identifier, privacyLevel: .public)),
            ("errorDescription", (value: error.localizedDescription, privacyLevel: .public))
          ],
          category: "Security"
        )
        await logger.error("Retrieve data operation failed", context: errorContext)
    }

    return result
  }

  /**
   Imports raw bytes into the secure storage.

   - Parameters:
     - data: The raw bytes to import
     - customIdentifier: Optional custom identifier for the data
   - Returns: Identifier for the imported data or an error
   */
  public func importData(
    _ data: [UInt8],
    customIdentifier: String?
  ) async -> Result<String, SecurityStorageError> {
    // Create an enhanced log context with proper privacy tags
    let context=createLogContext(
      operation: "importData",
      correlationID: nil,
      additionalMetadata: [
        ("dataSize", (value: "\(data.count)", privacyLevel: .public))
      ],
      category: "Security"
    )

    // Add custom identifier if provided
    let contextWithID: EnhancedLogContext
    if let customIdentifier {
      contextWithID=createLogContext(
        operation: "importData",
        correlationID: nil,
        additionalMetadata: [
          ("dataSize", (value: "\(data.count)", privacyLevel: .public)),
          ("customIdentifier", (value: customIdentifier, privacyLevel: .public))
        ],
        category: "Security"
      )
    } else {
      contextWithID=context
    }

    await logger.log(.debug, "Import data operation started", context: contextWithID)

    // Perform the operation
    let result=await wrapped.importData(
      data,
      customIdentifier: customIdentifier
    )

    // Log the result
    switch result {
      case let .success(identifier):
        let successContext=createLogContext(
          operation: "importData",
          correlationID: nil,
          additionalMetadata: [
            ("dataSize", (value: "\(data.count)", privacyLevel: .public)),
            ("identifier", (value: identifier, privacyLevel: .sensitive))
          ],
          category: "Security"
        )
        await logger.log(.info, "Import data operation successful", context: successContext)
      case let .failure(error):
        let errorContext=createLogContext(
          operation: "importData",
          correlationID: nil,
          additionalMetadata: [
            ("dataSize", (value: "\(data.count)", privacyLevel: .public)),
            ("errorDescription", (value: error.localizedDescription, privacyLevel: .public))
          ],
          category: "Security"
        )
        await logger.error("Import data operation failed", context: errorContext)
    }

    return result
  }

  /**
   Imports data into the secure storage with a specific identifier.

   - Parameters:
     - data: The data to import
     - customIdentifier: The identifier to use for the data
   - Returns: Identifier for the imported data or an error
   */
  public func importData(
    _ data: Data,
    customIdentifier: String
  ) async -> Result<String, SecurityStorageError> {
    // Create an enhanced log context with proper privacy tags
    let context=createLogContext(
      operation: "importData",
      correlationID: nil,
      additionalMetadata: [
        ("dataSize", (value: "\(data.count)", privacyLevel: .public)),
        ("customIdentifier", (value: customIdentifier, privacyLevel: .public))
      ],
      category: "Security"
    )

    await logger.log(.debug, "Import data operation started", context: context)

    // Perform the operation
    let result=await wrapped.importData(
      data,
      customIdentifier: customIdentifier
    )

    // Log the result
    switch result {
      case let .success(identifier):
        let successContext=createLogContext(
          operation: "importData",
          correlationID: nil,
          additionalMetadata: [
            ("dataSize", (value: "\(data.count)", privacyLevel: .public)),
            ("customIdentifier", (value: customIdentifier, privacyLevel: .public)),
            ("identifier", (value: identifier, privacyLevel: .sensitive))
          ],
          category: "Security"
        )
        await logger.log(.info, "Import data operation successful", context: successContext)
      case let .failure(error):
        let errorContext=createLogContext(
          operation: "importData",
          correlationID: nil,
          additionalMetadata: [
            ("dataSize", (value: "\(data.count)", privacyLevel: .public)),
            ("customIdentifier", (value: customIdentifier, privacyLevel: .public)),
            ("errorDescription", (value: error.localizedDescription, privacyLevel: .public))
          ],
          category: "Security"
        )
        await logger.error("Import data operation failed", context: errorContext)
    }

    return result
  }

  /**
   Signs data with a private key.

   - Parameters:
     - dataIdentifier: Identifier for the data to sign
     - keyIdentifier: Identifier for the signing key
     - options: Optional signing options
   - Returns: Result containing the signature identifier or an error
   */
  /* // Commenting out as this method is not part of CryptoServiceProtocol
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
       correlationID: nil,
       category: "Security",
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
         category: context.category,
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
           category: context.category,
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
           category: context.category,
           metadata: context.metadata.withPublic(
             key: "errorDescription",
             value: error.localizedDescription
           )
         )
         await logger.error("Sign data operation failed", context: errorContext)
     }

     return result
   }
   */

  /**
   Verifies a signature against the specified data.

   - Parameters:
     - dataIdentifier: Identifier for the data to verify
     - signatureIdentifier: Identifier for the signature to verify
     - keyIdentifier: Identifier for the verification key
     - options: Optional verification options
   - Returns: Result containing a boolean indicating if the signature is valid or an error
   */
  /* // Commenting out as this method is not part of CryptoServiceProtocol
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
       correlationID: nil,
       category: "Security",
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
         category: context.category,
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
           category: context.category,
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
           category: context.category,
           metadata: context.metadata.withPublic(
             key: "errorDescription",
             value: error.localizedDescription
           )
         )
         await logger.error("Verify signature operation failed", context: errorContext)
     }

     return result
   }
   */

  /**
   Generates a new cryptographic key.

   - Parameters:
     - length: Length of the key in bytes
     - options: Optional key generation options
   - Returns: Result containing the key identifier or an error
   */
  public func generateKey(
    length: Int,
    options: CoreSecurityTypes.KeyGenerationOptions?=nil
  ) async -> Result<String, SecurityStorageError> {
    // Create context for logging
    let context=createLogContext(
      operation: "generateKey",
      correlationID: nil,
      additionalMetadata: [
        ("keyLength", (value: "\(length)", privacyLevel: .public))
      ],
      category: "Security"
    )

    // Add key type and algorithm information if available
    var contextWithOptions=context
    if let keyType=options?.keyType {
      contextWithOptions=createLogContext(
        operation: "generateKey",
        correlationID: nil,
        additionalMetadata: [
          ("keyLength", (value: "\(length)", privacyLevel: .public)),
          ("keyType", (value: "\(keyType)", privacyLevel: .public))
        ],
        category: "Security"
      )
    }

    await logger.log(.debug, "Generate key operation started", context: contextWithOptions)

    // Perform the operation
    let result=await wrapped.generateKey(length: length, options: options)

    // Log the result
    switch result {
      case let .success(keyIdentifier):
        let successContext=createLogContext(
          operation: "generateKey",
          correlationID: nil,
          additionalMetadata: [
            ("keyLength", (value: "\(length)", privacyLevel: .public)),
            ("keyIdentifier", (value: keyIdentifier, privacyLevel: .sensitive))
          ],
          category: "Security"
        )
        await logger.log(.info, "Generate key operation successful", context: successContext)
      case let .failure(error):
        let errorContext=createLogContext(
          operation: "generateKey",
          correlationID: nil,
          additionalMetadata: [
            ("keyLength", (value: "\(length)", privacyLevel: .public)),
            ("errorDescription", (value: error.localizedDescription, privacyLevel: .public))
          ],
          category: "Security"
        )
        await logger.error("Generate key operation failed", context: errorContext)
    }

    return result
  }

  /**
   Exports data from secure storage.

   - Parameter identifier: Identifier for the data to export
   - Returns: The exported data as raw bytes or an error
   */
  public func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    // Create context for logging
    let context=createLogContext(
      operation: "exportData",
      correlationID: nil,
      additionalMetadata: [
        ("dataIdentifier", (value: identifier, privacyLevel: .public))
      ],
      category: "Security"
    )

    await logger.log(.debug, "Exporting data with identifier \(identifier)", context: context)

    // Perform the operation
    let result=await wrapped.exportData(identifier: identifier)

    // Log the result
    switch result {
      case let .success(data):
        let successContext=createLogContext(
          operation: "exportData",
          correlationID: nil,
          additionalMetadata: [
            ("dataIdentifier", (value: identifier, privacyLevel: .public)),
            ("dataSize", (value: "\(data.count)", privacyLevel: .public))
          ],
          category: "Security"
        )
        await logger.log(
          .info,
          "Data export successful (\(data.count) bytes)",
          context: successContext
        )
      case let .failure(error):
        let errorContext=createLogContext(
          operation: "exportData",
          correlationID: nil,
          additionalMetadata: [
            ("dataIdentifier", (value: identifier, privacyLevel: .public)),
            ("errorDescription", (value: error.localizedDescription, privacyLevel: .public))
          ],
          category: "Security"
        )
        await logger.error("Data export failed", context: errorContext)
    }

    return result
  }

  /**
   Generates a hash for the given data.

   - Parameters:
     - dataIdentifier: Identifier for the data to hash
     - options: Optional hashing options
   - Returns: The hash identifier or an error
   */
  public func generateHash(
    dataIdentifier: String,
    options: CoreSecurityTypes.HashingOptions?=nil
  ) async -> Result<String, SecurityStorageError> {
    // This is just a proxy to the hash method to match the protocol
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
    // Create context for logging
    let context=createLogContext(
      operation: "deleteData",
      correlationID: nil,
      additionalMetadata: [
        ("dataIdentifier", (value: identifier, privacyLevel: .public))
      ],
      category: "Security"
    )

    await logger.log(.debug, "Deleting data with identifier \(identifier)", context: context)

    // Perform the operation
    let result=await wrapped.deleteData(identifier: identifier)

    // Log the result
    switch result {
      case .success:
        let successContext=createLogContext(
          operation: "deleteData",
          correlationID: nil,
          additionalMetadata: [
            ("dataIdentifier", (value: identifier, privacyLevel: .public))
          ],
          category: "Security"
        )
        await logger.log(.info, "Data deletion successful", context: successContext)
      case let .failure(error):
        let errorContext=createLogContext(
          operation: "deleteData",
          correlationID: nil,
          additionalMetadata: [
            ("dataIdentifier", (value: identifier, privacyLevel: .public)),
            ("errorDescription", (value: error.localizedDescription, privacyLevel: .public))
          ],
          category: "Security"
        )
        await logger.error("Data deletion failed", context: errorContext)
    }

    return result
  }

  /**
   Creates a log context for crypto operations.
   
   - Parameters:
     - operation: Name of the operation being performed
     - algorithm: The cryptographic algorithm in use (optional)
     - correlationID: Optional correlation ID for request tracing
     - additionalMetadata: Additional metadata tuples to include with the context
     - category: Category for the log context
   - Returns: A configured log context
   */
  private func createLogContext(
    operation: String,
    algorithm: String?=nil,
    correlationID: String?=nil,
    additionalMetadata: [(String, (value: String, privacyLevel: PrivacyLevel))]=[],
    category: String="Security"
  ) -> EnhancedLogContext {
    var metadata=LogMetadataDTOCollection()
    
    // Add algorithm information if available
    if let algorithm=algorithm {
      metadata=metadata.withPublic(key: "algorithm", value: algorithm)
    }
    
    // Add additional metadata with proper privacy levels
    for (key, valueInfo) in additionalMetadata {
      switch valueInfo.privacyLevel {
        case .public:
          metadata=metadata.withPublic(key: key, value: valueInfo.value)
        case .private:
          metadata=metadata.withPrivate(key: key, value: valueInfo.value)
        case .sensitive:
          metadata=metadata.withSensitive(key: key, value: valueInfo.value)
        case .hash:
          metadata=metadata.withHashed(key: key, value: valueInfo.value)
        default:
          // Default to private for any other privacy level
          metadata=metadata.withPrivate(key: key, value: valueInfo.value)
      }
    }
    
    // Create and return the context with all parameters
    return EnhancedLogContext(
      domainName: "CryptoServices",
      operationName: operation,
      source: "EnhancedLoggingCryptoService",
      correlationID: correlationID,
      category: category,
      metadata: metadata
    )
  }
}
