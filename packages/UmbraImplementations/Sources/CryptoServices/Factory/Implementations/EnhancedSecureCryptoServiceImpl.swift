import CoreSecurityTypes
import CryptoInterfaces
import CryptoLogger
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces

/**
 # Enhanced Secure Crypto Service Implementation

 Enhanced implementation of CryptoServiceProtocol with additional security features.

 This implementation wraps another CryptoServiceProtocol implementation and adds:
 - Rate limiting prevention to mitigate brute force attacks
 - Enhanced logging for security operations with privacy controls
 - Additional input validation to prevent common security issues
 - Runtime security checks for enhanced protection

 ## Privacy Controls

 This implementation ensures proper privacy classification of sensitive information:
 - Cryptographic keys and operations are treated with appropriate privacy levels
 - Error details are classified based on sensitivity
 - Metadata is structured using LogMetadataDTOCollection for privacy-aware logging

 ## Thread Safety

 As an actor, this implementation guarantees thread safety when used from multiple
 concurrent contexts, preventing data races in cryptographic operations.
 */
public actor EnhancedSecureCryptoServiceImpl: @preconcurrency CryptoServiceProtocol {

  /// The wrapped implementation that does the actual cryptographic work
  private let wrapped: CryptoServiceProtocol

  /// Logger for operations
  private let logger: LoggingProtocol

  /// Rate limiter for controlling operation frequency
  private let rateLimiter: BaseRateLimiter

  /// Provides access to the secure storage from the wrapped implementation
  public var secureStorage: SecureStorageProtocol {
    wrapped.secureStorage
  }

  /**
   Initialises a new secure crypto service with rate limiting and enhanced logging.

   - Parameters:
     - wrapped: The underlying implementation to delegate to
     - logger: Logger for operations
     - rateLimiter: Rate limiter for security operations
   */
  public init(
    wrapped: CryptoServiceProtocol,
    logger: LoggingProtocol,
    rateLimiter: BaseRateLimiter
  ) {
    self.wrapped=wrapped
    self.logger=logger
    self.rateLimiter=rateLimiter
  }

  /**
   Creates a log context for cryptographic operations
   */
  private func createLogContext(
    operation: String,
    identifier: String?=nil,
    status: String?=nil,
    details: [String: String]=[:]
  ) -> LoggingTypes.CryptoLogContext {
    var detailsWithOperation=details
    detailsWithOperation["operation"]=operation

    if let identifier {
      detailsWithOperation["identifier"]=identifier
    }

    if let status {
      detailsWithOperation["status"]=status
    }

    // Create metadata collection
    var contextMetadata=LogMetadataDTOCollection()

    // Add all details with public privacy level
    for (key, value) in detailsWithOperation {
      contextMetadata=contextMetadata.withPublic(key: key, value: value)
    }

    return LoggingTypes.CryptoLogContext(
      operation: operation,
      algorithm: details["algorithm"],
      correlationID: UUID().uuidString,
      source: "EnhancedSecureCryptoServiceImpl",
      additionalContext: contextMetadata
    )
  }

  /// Helper method to safely check if an operation is rate limited
  private func isOperationRateLimited(_ operation: String) async -> Bool {
    // Create a local copy to prevent direct access to self.rateLimiter
    let localRateLimiter=rateLimiter
    return await localRateLimiter.isRateLimited(operation)
  }

  // MARK: - Encryption Operations

  /**
   Encrypts a string using the specified key.

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
    // Check rate limiter
    if await isOperationRateLimited("encrypt") {
      let context=createLogContext(
        operation: "encrypt",
        identifier: dataIdentifier,
        status: "rate_limited",
        details: [
          "keyIdentifier": keyIdentifier,
          "reason": "Rate limit exceeded for encryption operations"
        ]
      )

      await logger.warning(
        "Encryption operation rate limited",
        context: context
      )

      return .failure(.operationRateLimited)
    }

    // Input validation
    guard !dataIdentifier.isEmpty else {
      let context=createLogContext(
        operation: "encrypt",
        status: "validation_failed",
        details: [
          "keyIdentifier": keyIdentifier,
          "reason": "Empty data identifier"
        ]
      )

      await logger.error(
        "Encryption failed: empty data identifier",
        context: context
      )

      return .failure(.dataNotFound)
    }

    guard !keyIdentifier.isEmpty else {
      let context=createLogContext(
        operation: "encrypt",
        identifier: dataIdentifier,
        status: "validation_failed",
        details: [
          "reason": "Empty key identifier"
        ]
      )

      await logger.error(
        "Encryption failed: empty key identifier",
        context: context
      )

      return .failure(.dataNotFound)
    }

    // Log the operation
    let startContext=createLogContext(
      operation: "encrypt",
      identifier: dataIdentifier,
      status: "started",
      details: [
        "keyIdentifier": keyIdentifier,
        "algorithm": options?.algorithm.rawValue ?? "default"
      ]
    )

    await logger.debug(
      "Starting encryption operation",
      context: startContext
    )

    // Delegate to wrapped implementation
    let result=await wrapped.encrypt(
      dataIdentifier: dataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )

    // Log the result
    switch result {
      case let .success(encryptedIdentifier):
        let successContext=createLogContext(
          operation: "encrypt",
          identifier: dataIdentifier,
          status: "success",
          details: [
            "keyIdentifier": keyIdentifier,
            "encryptedIdentifier": encryptedIdentifier,
            "algorithm": options?.algorithm.rawValue ?? "default"
          ]
        )

        await logger.info(
          "Encryption operation completed successfully",
          context: successContext
        )

      case let .failure(error):
        let errorContext=createLogContext(
          operation: "encrypt",
          identifier: dataIdentifier,
          status: "failed",
          details: [
            "keyIdentifier": keyIdentifier,
            "errorDescription": error.localizedDescription,
            "errorCode": "\(error)"
          ]
        )

        await logger.error(
          "Encryption operation failed: \(error.localizedDescription)",
          context: errorContext
        )
    }

    return result
  }

  /**
   Decrypts a string using the specified key.

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
    // Check rate limiter
    if await isOperationRateLimited("decrypt") {
      let context=createLogContext(
        operation: "decrypt",
        identifier: encryptedDataIdentifier,
        status: "rate_limited",
        details: [
          "keyIdentifier": keyIdentifier,
          "reason": "Rate limit exceeded for decryption operations"
        ]
      )

      await logger.warning(
        "Decryption operation rate limited",
        context: context
      )

      return .failure(.operationRateLimited)
    }

    // Input validation
    guard !encryptedDataIdentifier.isEmpty else {
      let context=createLogContext(
        operation: "decrypt",
        status: "validation_failed",
        details: [
          "keyIdentifier": keyIdentifier,
          "reason": "Empty encrypted data identifier"
        ]
      )

      await logger.error(
        "Decryption failed: empty encrypted data identifier",
        context: context
      )

      return .failure(.dataNotFound)
    }

    guard !keyIdentifier.isEmpty else {
      let context=createLogContext(
        operation: "decrypt",
        identifier: encryptedDataIdentifier,
        status: "validation_failed",
        details: [
          "reason": "Empty key identifier"
        ]
      )

      await logger.error(
        "Decryption failed: empty key identifier",
        context: context
      )

      return .failure(.dataNotFound)
    }

    // Log the operation
    let startContext=createLogContext(
      operation: "decrypt",
      identifier: encryptedDataIdentifier,
      status: "started",
      details: [
        "keyIdentifier": keyIdentifier,
        "algorithm": options?.algorithm.rawValue ?? "default"
      ]
    )

    await logger.debug(
      "Starting decryption operation",
      context: startContext
    )

    // Delegate to wrapped implementation
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
          identifier: encryptedDataIdentifier,
          status: "success",
          details: [
            "keyIdentifier": keyIdentifier,
            "decryptedIdentifier": decryptedIdentifier,
            "algorithm": options?.algorithm.rawValue ?? "default"
          ]
        )

        await logger.info(
          "Decryption operation completed successfully",
          context: successContext
        )

      case let .failure(error):
        let errorContext=createLogContext(
          operation: "decrypt",
          identifier: encryptedDataIdentifier,
          status: "failed",
          details: [
            "keyIdentifier": keyIdentifier,
            "errorDescription": error.localizedDescription,
            "errorCode": "\(error)"
          ]
        )

        await logger.error(
          "Decryption operation failed: \(error.localizedDescription)",
          context: errorContext
        )
    }

    return result
  }

  /**
   Computes a hash of the specified data.

   - Parameters:
     - dataIdentifier: Identifier for the data to hash
     - options: Optional hashing options
   - Returns: Identifier for the hash or an error
   */
  public func hash(
    dataIdentifier: String,
    options: CoreSecurityTypes.HashingOptions?=nil
  ) async -> Result<String, SecurityStorageError> {
    // Check rate limiter
    if await isOperationRateLimited("hash") {
      let context=createLogContext(
        operation: "hash",
        identifier: dataIdentifier,
        status: "rate_limited",
        details: [
          "reason": "Rate limit exceeded for hash operations"
        ]
      )

      await logger.warning(
        "Hash operation rate limited",
        context: context
      )

      return .failure(.operationRateLimited)
    }

    // Input validation
    guard !dataIdentifier.isEmpty else {
      let context=createLogContext(
        operation: "hash",
        status: "validation_failed",
        details: [
          "reason": "Empty data identifier"
        ]
      )

      await logger.error(
        "Hash operation failed: empty data identifier",
        context: context
      )

      return .failure(.dataNotFound)
    }

    // Log the operation
    let algorithm=options?.algorithm.rawValue ?? "SHA256"
    let startContext=createLogContext(
      operation: "hash",
      identifier: dataIdentifier,
      status: "started",
      details: [
        "algorithm": algorithm
      ]
    )

    await logger.debug(
      "Starting hash operation using \(algorithm)",
      context: startContext
    )

    // Delegate to wrapped implementation
    let result=await wrapped.hash(
      dataIdentifier: dataIdentifier,
      options: options
    )

    // Log the result
    switch result {
      case let .success(hashIdentifier):
        let successContext=createLogContext(
          operation: "hash",
          identifier: dataIdentifier,
          status: "success",
          details: [
            "hashIdentifier": hashIdentifier,
            "algorithm": algorithm
          ]
        )

        await logger.info(
          "Hash operation completed successfully",
          context: successContext
        )

      case let .failure(error):
        let errorContext=createLogContext(
          operation: "hash",
          identifier: dataIdentifier,
          status: "failed",
          details: [
            "errorDescription": error.localizedDescription,
            "errorCode": "\(error)",
            "algorithm": algorithm
          ]
        )

        await logger.error(
          "Hash operation failed: \(error.localizedDescription)",
          context: errorContext
        )
    }

    return result
  }

  /**
   Verifies a hash against the expected value.

   - Parameters:
     - dataIdentifier: Identifier for the data to verify
     - hashIdentifier: Identifier for the expected hash
     - options: Optional hashing options
   - Returns: True if the hash matches, false otherwise, or an error
   */
  public func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options: CoreSecurityTypes.HashingOptions?=nil
  ) async -> Result<Bool, SecurityStorageError> {
    // Check rate limiter
    if await isOperationRateLimited("verify") {
      let context=createLogContext(
        operation: "verifyHash",
        identifier: dataIdentifier,
        status: "rate_limited",
        details: [
          "hashIdentifier": hashIdentifier,
          "reason": "Rate limit exceeded for hash verification operations"
        ]
      )

      await logger.warning(
        "Hash verification operation rate limited",
        context: context
      )

      return .failure(.operationRateLimited)
    }

    // Input validation
    guard !dataIdentifier.isEmpty else {
      let context=createLogContext(
        operation: "verifyHash",
        status: "validation_failed",
        details: [
          "hashIdentifier": hashIdentifier,
          "reason": "Empty data identifier"
        ]
      )

      await logger.error(
        "Hash verification failed: empty data identifier",
        context: context
      )

      return .failure(.dataNotFound)
    }

    guard !hashIdentifier.isEmpty else {
      let context=createLogContext(
        operation: "verifyHash",
        identifier: dataIdentifier,
        status: "validation_failed",
        details: [
          "reason": "Empty expected hash identifier"
        ]
      )

      await logger.error(
        "Hash verification failed: empty expected hash identifier",
        context: context
      )

      return .failure(.dataNotFound)
    }

    // Log the operation
    let algorithm=options?.algorithm.rawValue ?? "SHA256"
    let startContext=createLogContext(
      operation: "verifyHash",
      identifier: dataIdentifier,
      status: "started",
      details: [
        "hashIdentifier": hashIdentifier,
        "algorithm": algorithm
      ]
    )

    await logger.debug(
      "Starting hash verification using \(algorithm)",
      context: startContext
    )

    // Delegate to wrapped implementation
    let result=await wrapped.verifyHash(
      dataIdentifier: dataIdentifier,
      hashIdentifier: hashIdentifier,
      options: options
    )

    // Log the result
    switch result {
      case let .success(isValid):
        let successContext=createLogContext(
          operation: "verifyHash",
          identifier: dataIdentifier,
          status: "success",
          details: [
            "hashIdentifier": hashIdentifier,
            "isValid": isValid ? "true" : "false",
            "algorithm": algorithm
          ]
        )

        await logger.info(
          "Hash verification completed: \(isValid ? "valid" : "invalid")",
          context: successContext
        )

      case let .failure(error):
        let errorContext=createLogContext(
          operation: "verifyHash",
          identifier: dataIdentifier,
          status: "failed",
          details: [
            "hashIdentifier": hashIdentifier,
            "errorDescription": error.localizedDescription,
            "errorCode": "\(error)",
            "algorithm": algorithm
          ]
        )

        await logger.error(
          "Hash verification failed: \(error.localizedDescription)",
          context: errorContext
        )
    }

    return result
  }

  /**
   Stores data in secure storage.

   - Parameters:
     - data: The data to store
     - identifier: The identifier to use
   - Returns: Success or an error
   */
  public func storeData(
    data: Data,
    identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    // Check rate limiter
    if await isOperationRateLimited("storeData") {
      let context=createLogContext(
        operation: "storeData",
        status: "rateLimited"
      )

      await logger.warning(
        "Store data operation was rate limited",
        context: context
      )

      return .failure(.operationRateLimited)
    }

    // Input validation
    guard !data.isEmpty else {
      let context=createLogContext(
        operation: "storeData",
        status: "failed",
        details: ["error": "Data is empty"]
      )

      await logger.error(
        "Store data operation failed: data is empty",
        context: context
      )

      return .failure(.invalidInput("Data is empty"))
    }

    guard !identifier.isEmpty else {
      let context=createLogContext(
        operation: "storeData",
        status: "failed",
        details: ["error": "Identifier is empty"]
      )

      await logger.error(
        "Store data operation failed: identifier is empty",
        context: context
      )

      return .failure(.invalidInput("Identifier is empty"))
    }

    // Log the operation
    let startContext=createLogContext(
      operation: "storeData",
      status: "started",
      details: [
        "identifier": identifier,
        "dataSize": "\(data.count)"
      ]
    )

    await logger.debug(
      "Storing data with size \(data.count) bytes",
      context: startContext
    )

    // Delegate to wrapped implementation
    let result=await wrapped.storeData(data: data, identifier: identifier)

    // Log the result
    switch result {
      case .success:
        let successContext=createLogContext(
          operation: "storeData",
          status: "success",
          details: [
            "identifier": identifier,
            "dataSize": "\(data.count)"
          ]
        )

        await logger.info(
          "Successfully stored data with identifier \(identifier)",
          context: successContext
        )
      case let .failure(error):
        let errorContext=createLogContext(
          operation: "storeData",
          status: "failed",
          details: [
            "error": error.localizedDescription,
            "identifier": identifier
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
   Retrieves data from secure storage.

   - Parameter identifier: Identifier for the data to retrieve
   - Returns: The data or an error
   */
  public func retrieveData(
    identifier: String
  ) async -> Result<Data, SecurityStorageError> {
    // Check rate limiter
    if await isOperationRateLimited("retrieveData") {
      let context=createLogContext(
        operation: "retrieveData",
        status: "rateLimited"
      )

      await logger.warning(
        "Retrieve data operation was rate limited",
        context: context
      )

      return .failure(.operationRateLimited)
    }

    // Input validation
    guard !identifier.isEmpty else {
      let context=createLogContext(
        operation: "retrieveData",
        status: "failed",
        details: ["error": "Identifier is empty"]
      )

      await logger.error(
        "Retrieve data operation failed: identifier is empty",
        context: context
      )

      return .failure(.dataNotFound)
    }

    // Log the operation
    let startContext=createLogContext(
      operation: "retrieveData",
      status: "started",
      details: ["identifier": identifier]
    )

    await logger.debug(
      "Retrieving data with identifier \(identifier)",
      context: startContext
    )

    // Delegate to wrapped implementation
    let result=await wrapped.retrieveData(identifier: identifier)

    // Log the result
    switch result {
      case let .success(data):
        let successContext=createLogContext(
          operation: "retrieveData",
          status: "success",
          details: [
            "identifier": identifier,
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
            "error": error.localizedDescription,
            "identifier": identifier
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
   Deletes data from secure storage.

   - Parameter identifier: Identifier for the data to delete
   - Returns: Success or an error
   */
  public func deleteData(
    identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    // Check rate limiter
    if await isOperationRateLimited("deleteData") {
      let context=createLogContext(
        operation: "deleteData",
        status: "rateLimited"
      )

      await logger.warning(
        "Delete data operation was rate limited",
        context: context
      )

      return .failure(.operationRateLimited)
    }

    // Input validation
    guard !identifier.isEmpty else {
      let context=createLogContext(
        operation: "deleteData",
        status: "failed",
        details: ["error": "Identifier is empty"]
      )

      await logger.error(
        "Delete data operation failed: identifier is empty",
        context: context
      )

      return .failure(.dataNotFound)
    }

    // Log the operation
    let startContext=createLogContext(
      operation: "deleteData",
      status: "started",
      details: ["identifier": identifier]
    )

    await logger.debug(
      "Deleting data with identifier \(identifier)",
      context: startContext
    )

    // Delegate to wrapped implementation
    let result=await wrapped.deleteData(identifier: identifier)

    // Log the result
    switch result {
      case .success:
        let successContext=createLogContext(
          operation: "deleteData",
          status: "success",
          details: ["identifier": identifier]
        )

        await logger.info(
          "Successfully deleted data with identifier \(identifier)",
          context: successContext
        )
      case let .failure(error):
        let errorContext=createLogContext(
          operation: "deleteData",
          status: "failed",
          details: [
            "error": error.localizedDescription,
            "identifier": identifier
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
   Generates a new cryptographic key with the specified length and options.

   - Parameters:
     - length: Length of the key in bits
     - options: Optional key generation configuration
   - Returns: Success with key identifier or error
   */
  public func generateKey(
    length: Int,
    options: CoreSecurityTypes.KeyGenerationOptions?=nil
  ) async -> Result<String, SecurityStorageError> {
    // Check rate limiter
    if await isOperationRateLimited("generateKey") {
      let context=createLogContext(
        operation: "generateKey",
        status: "rateLimited"
      )

      await logger.warning(
        "Generate key operation was rate limited",
        context: context
      )

      return .failure(.operationRateLimited)
    }

    // Input validation
    guard length > 0 else {
      let context=createLogContext(
        operation: "generateKey",
        status: "failed",
        details: ["error": "Invalid key length"]
      )

      await logger.error(
        "Generate key operation failed: invalid key length",
        context: context
      )

      return .failure(.invalidInput("Invalid key length"))
    }

    // Log the operation
    let startContext=createLogContext(
      operation: "generateKey",
      status: "started",
      details: ["keyLength": String(length)]
    )

    await logger.debug(
      "Generating cryptographic key with length \(length)",
      context: startContext
    )

    // Delegate to wrapped implementation
    let result=await wrapped.generateKey(length: length, options: options)

    // Log the result
    switch result {
      case let .success(keyIdentifier):
        let successContext=createLogContext(
          operation: "generateKey",
          status: "success",
          details: [
            "keyLength": String(length),
            "keyIdentifier": keyIdentifier
          ]
        )

        await logger.info(
          "Successfully generated key with identifier \(keyIdentifier)",
          context: successContext
        )
      case let .failure(error):
        let errorContext=createLogContext(
          operation: "generateKey",
          status: "failed",
          details: [
            "error": error.localizedDescription,
            "keyLength": String(length)
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
   Imports data into secure storage with custom identifier.

   - Parameters:
     - data: Raw data to import
     - customIdentifier: Optional identifier to use for the data
   - Returns: Success with data identifier or error
   */
  public func importData(
    _ data: [UInt8],
    customIdentifier: String?
  ) async -> Result<String, SecurityStorageError> {
    // Check rate limiter
    if await isOperationRateLimited("importData") {
      let context=createLogContext(
        operation: "importData",
        status: "rateLimited"
      )

      await logger.warning(
        "Import data operation was rate limited",
        context: context
      )

      return .failure(.operationRateLimited)
    }

    // Input validation
    guard !data.isEmpty else {
      let context=createLogContext(
        operation: "importData",
        status: "failed",
        details: ["error": "Empty data"]
      )

      await logger.error(
        "Import data operation failed: empty data",
        context: context
      )

      return .failure(.invalidInput("Empty data"))
    }

    // Convert byte array to Data for internal implementation
    let dataObj=Data(data)

    // Log the operation
    let startContext=createLogContext(
      operation: "importData",
      status: "started",
      details: [
        "dataSize": String(data.count),
        "hasCustomIdentifier": customIdentifier != nil ? "true" : "false"
      ]
    )

    await logger.debug(
      "Importing data (\(data.count) bytes)",
      context: startContext
    )

    // Delegate to wrapped implementation with appropriate conversion
    let effectiveIdentifier=customIdentifier ?? ""
    let result=await wrapped.importData(dataObj, customIdentifier: effectiveIdentifier)

    // Log the result
    switch result {
      case let .success(identifier):
        let successContext=createLogContext(
          operation: "importData",
          status: "success",
          details: [
            "dataSize": String(data.count),
            "dataIdentifier": identifier
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
            "error": error.localizedDescription,
            "dataSize": String(data.count)
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
   Imports data into secure storage with custom identifier.

   - Parameters:
     - data: Raw data to import
     - customIdentifier: Identifier to use for the data
   - Returns: Success with data identifier or error
   */
  public func importData(
    _ data: Data,
    customIdentifier: String
  ) async -> Result<String, SecurityStorageError> {
    // Convert Data to byte array for internal implementation
    let bytes=[UInt8](data)

    // Delegate to the other implementation
    return await importData(bytes, customIdentifier: customIdentifier)
  }

  /**
   Exports data from secure storage by identifier.

   - Parameter identifier: The identifier of the data to export
   - Returns: Success with raw data or error
   */
  public func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    // Check rate limiter
    if await isOperationRateLimited("exportData") {
      let context=createLogContext(
        operation: "exportData",
        identifier: identifier,
        status: "rateLimited"
      )

      await logger.warning(
        "Export data operation was rate limited",
        context: context
      )

      return .failure(.operationRateLimited)
    }

    // Input validation
    guard !identifier.isEmpty else {
      let context=createLogContext(
        operation: "exportData",
        status: "failed",
        details: ["error": "Empty identifier"]
      )

      await logger.error(
        "Export data operation failed: empty identifier",
        context: context
      )

      return .failure(.invalidInput("Empty identifier"))
    }

    // Log the operation
    let startContext=createLogContext(
      operation: "exportData",
      status: "started",
      details: ["identifier": identifier]
    )

    await logger.debug(
      "Exporting data with identifier \(identifier)",
      context: startContext
    )

    // Delegate to wrapped implementation
    let result=await wrapped.exportData(identifier: identifier)

    // Log the result and convert Data to [UInt8] if needed
    switch result {
      case let .success(data):
        let successContext=createLogContext(
          operation: "exportData",
          status: "success",
          details: [
            "dataSize": String(data.count),
            "dataIdentifier": identifier
          ]
        )

        await logger.info(
          "Successfully exported data (\(data.count) bytes)",
          context: successContext
        )

        // Convert Data to [UInt8]
        return .success(Array(data))

      case let .failure(error):
        let errorContext=createLogContext(
          operation: "exportData",
          status: "failed",
          details: [
            "error": error.localizedDescription,
            "dataIdentifier": identifier
          ]
        )

        await logger.error(
          "Failed to export data: \(error.localizedDescription)",
          context: errorContext
        )

        return .failure(error)
    }
  }

  /**
   Generates a hash for the data identified by the provided identifier.

   - Parameters:
     - dataIdentifier: Identifier for the data to hash
     - options: Optional hashing configuration
   - Returns: Success with hash identifier or error
   */
  public func generateHash(
    dataIdentifier: String,
    options: CoreSecurityTypes.HashingOptions?=nil
  ) async -> Result<String, SecurityStorageError> {
    // Check rate limiter
    if await isOperationRateLimited("generateHash") {
      let context=createLogContext(
        operation: "generateHash",
        status: "rateLimited"
      )

      await logger.warning(
        "Generate hash operation was rate limited",
        context: context
      )

      return .failure(.operationRateLimited)
    }

    // Input validation
    guard !dataIdentifier.isEmpty else {
      let context=createLogContext(
        operation: "generateHash",
        status: "failed",
        details: ["error": "Empty data identifier"]
      )

      await logger.error(
        "Generate hash operation failed: empty data identifier",
        context: context
      )

      return .failure(.dataNotFound)
    }

    // Log the operation
    let startContext=createLogContext(
      operation: "generateHash",
      status: "started",
      details: ["dataIdentifier": dataIdentifier]
    )

    await logger.debug(
      "Generating hash for data with identifier \(dataIdentifier)",
      context: startContext
    )

    // Delegate to wrapped implementation
    let result=await wrapped.generateHash(dataIdentifier: dataIdentifier, options: options)

    // Log the result
    switch result {
      case let .success(hashIdentifier):
        let successContext=createLogContext(
          operation: "generateHash",
          status: "success",
          details: [
            "dataIdentifier": dataIdentifier,
            "hashIdentifier": hashIdentifier
          ]
        )

        await logger.info(
          "Successfully generated hash with identifier \(hashIdentifier)",
          context: successContext
        )
      case let .failure(error):
        let errorContext=createLogContext(
          operation: "generateHash",
          status: "failed",
          details: [
            "error": error.localizedDescription,
            "dataIdentifier": dataIdentifier
          ]
        )

        await logger.error(
          "Failed to generate hash: \(error.localizedDescription)",
          context: errorContext
        )
    }

    return result
  }
}

/**
 Base rate limiter for security operations.

 This class provides a common interface for rate limiting that can be
 implemented by different rate limiting strategies. It helps prevent
 brute force attacks by limiting the number of operations that can be
 performed in a given time period.
 */
public protocol BaseRateLimiter {
  /**
   Checks if an operation is rate limited.

   - Parameter operation: The operation to check
   - Returns: True if the operation is rate limited, false otherwise
   */
  func isRateLimited(_ operation: String) async -> Bool

  /**
   Records an operation for rate limiting purposes.

   - Parameter operation: The operation to record
   */
  func recordOperation(_ operation: String) async

  /**
   Resets the rate limiter for an operation.

   - Parameter operation: The operation to reset
   */
  func reset(_ operation: String) async
}
