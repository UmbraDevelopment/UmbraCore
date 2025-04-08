import CoreSecurityTypes
import CryptoLogger
import Foundation
import CryptoInterfaces
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces

/**
 Enhanced implementation of CryptoServiceProtocol with additional security features.

 This implementation wraps another CryptoServiceProtocol implementation and adds:
 - Rate limiting prevention to mitigate brute force attacks
 - Enhanced logging for security operations
 - Additional input validation to prevent common security issues
 - Runtime security checks for enhanced protection

 This implementation can be used as a decorator over any other crypto implementation for extra
 validation of cryptographic operations.
 */
public actor EnhancedSecureCryptoServiceImpl: @preconcurrency CryptoServiceProtocol {

  /// The wrapped implementation that does the actual cryptographic work
  private let wrapped: CryptoServiceProtocol

  /// Logger for operations
  private let logger: LoggingProtocol

  /// Rate limiter for operations
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
   Creates a log context for a cryptographic operation.

   - Parameters:
     - operation: The type of operation (encrypt, decrypt, etc.)
     - identifier: Optional identifier for the data or key
     - details: Optional additional details about the operation
   - Returns: A log context for the operation
   */
  private func createLogContext(
    operation: String,
    identifier: String?=nil,
    details: String?=nil
  ) -> LoggingTypes.CryptoLogContext {
    var additionalContext = LogMetadataDTOCollection()
    
    if let identifier = identifier {
      additionalContext = additionalContext.withPublic(
        key: "identifier", 
        value: identifier
      )
    }
    
    if let details = details {
      additionalContext = additionalContext.withPrivate(
        key: "details", 
        value: details
      )
    }
    
    return LoggingTypes.CryptoLogContext(
      operation: operation,
      additionalContext: additionalContext
    )
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
    if await rateLimiter.isRateLimited("encrypt") {
      let context=createLogContext(
        operation: "encrypt",
        details: "Rate limited"
      )

      await logger.warning("Rate limited encryption operation", context: context)
      return .failure(.operationFailed("Rate limited"))
    }

    // Validate inputs
    if dataIdentifier.isEmpty {
      let context=createLogContext(
        operation: "encrypt",
        details: "Empty data identifier"
      )
      await logger.error("Invalid data identifier", context: context)
      return .failure(.invalidInput("Data identifier cannot be empty"))
    }

    if keyIdentifier.isEmpty {
      let context=createLogContext(
        operation: "encrypt",
        details: "Empty key identifier"
      )
      await logger.error("Invalid key identifier", context: context)
      return .failure(.invalidInput("Key identifier cannot be empty"))
    }

    // Create log context
    let context=createLogContext(
      operation: "encrypt",
      details: "Encrypting data with key \(keyIdentifier)"
    )

    // Log the operation
    await logger.info("Encrypting data", context: context)

    // Delegate to wrapped implementation
    return await wrapped.encrypt(dataIdentifier: dataIdentifier, keyIdentifier: keyIdentifier, options: options)
  }

  /**
   Decrypts data using the specified key.

   - Parameters:
     - encryptedDataIdentifier: Identifier for the encrypted data
     - keyIdentifier: Identifier for the decryption key
     - options: Optional decryption options
   - Returns: Identifier for the decrypted data or an error
   */
  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options: CoreSecurityTypes.DecryptionOptions?=nil
  ) async -> Result<String, SecurityStorageError> {
    // Check rate limiter
    if await rateLimiter.isRateLimited("decrypt") {
      let context=createLogContext(
        operation: "decrypt",
        details: "Rate limited"
      )

      await logger.warning("Rate limited decryption operation", context: context)
      return .failure(.operationFailed("Rate limited"))
    }

    // Validate inputs
    if encryptedDataIdentifier.isEmpty {
      let context=createLogContext(
        operation: "decrypt",
        details: "Empty data identifier"
      )

      await logger.error("Invalid data identifier", context: context)
      return .failure(.invalidInput("Encrypted data identifier cannot be empty"))
    }

    if keyIdentifier.isEmpty {
      let context=createLogContext(
        operation: "decrypt",
        details: "Empty key identifier"
      )

      await logger.error("Invalid key identifier", context: context)
      return .failure(.invalidInput("Key identifier cannot be empty"))
    }

    // Create log context
    let context=createLogContext(
      operation: "decrypt",
      details: "Decrypting data with key \(keyIdentifier)"
    )

    // Log the operation
    await logger.info("Decrypting data", context: context)

    // Delegate to wrapped implementation
    return await wrapped.decrypt(
      encryptedDataIdentifier: encryptedDataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )
  }

  // MARK: - Hashing Operations

  /**
   Computes a cryptographic hash of data in secure storage.

   - Parameters:
     - dataIdentifier: Identifier for the data to hash in secure storage.
     - options: Optional hashing configuration.
   - Returns: Identifier for the generated hash in secure storage, or an error.
   */
  public func generateHash(
    dataIdentifier: String,
    options: CoreSecurityTypes.HashingOptions?
  ) async -> Result<String, SecurityStorageError> {
    let context = createLogContext(
      operation: "generateHash",
      identifier: dataIdentifier
    )
    
    await logger.info("Generating hash for data with identifier: \(dataIdentifier)", context: context)
    
    // Check rate limiter
    if await rateLimiter.isRateLimited("hash") {
      await logger.error("Operation rate limited: hash", context: context)
      return .failure(.operationRateLimited)
    }
    
    return await wrapped.generateHash(dataIdentifier: dataIdentifier, options: options)
  }

  /**
   Computes a cryptographic hash of data in secure storage.
   This is an alias for generateHash to maintain compatibility with the protocol.

   - Parameters:
     - dataIdentifier: Identifier for the data to hash in secure storage.
     - options: Optional hashing configuration.
   - Returns: Identifier for the hash in secure storage, or an error.
   */
  public func hash(
    dataIdentifier: String,
    options: CoreSecurityTypes.HashingOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Simply delegate to generateHash for implementation
    return await generateHash(dataIdentifier: dataIdentifier, options: options)
  }

  /**
   Verifies a hash against the specified data.

   - Parameters:
     - dataIdentifier: Identifier for the data to verify
     - hashIdentifier: Identifier for the hash to verify against
     - options: Optional hashing options
   - Returns: True if the hash matches, false otherwise, or an error
   */
  public func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options: CoreSecurityTypes.HashingOptions?=nil
  ) async -> Result<Bool, SecurityStorageError> {
    // Check rate limiter
    if await rateLimiter.isRateLimited("verify") {
      let context=createLogContext(
        operation: "verifyHash",
        details: "Rate limited"
      )

      await logger.warning("Rate limited hash verification operation", context: context)
      return .failure(.operationFailed("Rate limited"))
    }

    // Validate inputs
    if dataIdentifier.isEmpty {
      let context=createLogContext(
        operation: "verifyHash",
        details: "Empty data identifier"
      )

      await logger.error("Invalid data identifier", context: context)
      return .failure(.invalidInput("Data identifier cannot be empty"))
    }

    if hashIdentifier.isEmpty {
      let context=createLogContext(
        operation: "verifyHash",
        details: "Empty hash identifier"
      )

      await logger.error("Invalid hash identifier", context: context)
      return .failure(.invalidInput("Hash identifier cannot be empty"))
    }

    // Create log context
    let context=createLogContext(
      operation: "verifyHash",
      details: "Verifying hash for data \(dataIdentifier)"
    )

    // Log the operation
    await logger.info("Verifying hash", context: context)

    // Delegate to wrapped implementation
    return await wrapped.verifyHash(
      dataIdentifier: dataIdentifier,
      hashIdentifier: hashIdentifier,
      options: options
    )
  }

  // MARK: - Data Export Operations

  /**
   Exports data as a byte array.

   - Parameter identifier: Identifier for the data to export
   - Returns: The exported data or an error
   */
  public func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    // Check rate limiter
    if await rateLimiter.isRateLimited("exportData") {
      let context=createLogContext(
        operation: "exportData",
        details: "Rate limited"
      )

      await logger.warning("Rate limited data export operation", context: context)
      return .failure(.operationFailed("Rate limited"))
    }

    // Validate inputs
    if identifier.isEmpty {
      let context=createLogContext(
        operation: "exportData",
        details: "Empty identifier"
      )

      await logger.error("Invalid identifier", context: context)
      return .failure(.invalidInput("Identifier cannot be empty"))
    }

    // Create log context
    let context=createLogContext(
      operation: "exportData",
      details: "Exporting data \(identifier)"
    )

    // Log the operation
    await logger.info("Exporting data", context: context)

    // Delegate to wrapped implementation
    return await wrapped.exportData(identifier: identifier)
  }

  // MARK: - Key Generation Operations

  /**
   Generates a new cryptographic key.

   - Parameters:
     - length: Length of the key in bits
     - options: Optional key generation options
   - Returns: Identifier for the generated key or an error
   */
  public func generateKey(
    length: Int,
    options: CoreSecurityTypes.KeyGenerationOptions?=nil
  ) async -> Result<String, SecurityStorageError> {
    // Check rate limiter
    if await rateLimiter.isRateLimited("generateKey") {
      let context=createLogContext(
        operation: "generateKey",
        details: "Rate limited"
      )

      await logger.warning("Rate limited key generation operation", context: context)
      return .failure(.operationFailed("Rate limited"))
    }

    // Validate inputs
    if length <= 0 {
      let context=createLogContext(
        operation: "generateKey",
        details: "Invalid key length"
      )

      await logger.error("Invalid key length", context: context)
      return .failure(.invalidInput("Key length must be positive"))
    }

    // Create log context
    let context=createLogContext(
      operation: "generateKey",
      details: "Generating key of length \(length)"
    )

    // Log the operation
    await logger.info("Generating cryptographic key", context: context)

    // Delegate to wrapped implementation
    return await wrapped.generateKey(length: length, options: options)
  }

  // MARK: - Data Import Operations

  /**
   Imports data from a byte array.

   - Parameters:
     - data: The data to import
     - customIdentifier: Optional custom identifier for the data
   - Returns: Identifier for the imported data or an error
   */
  public func importData(
    _ data: [UInt8],
    customIdentifier: String?
  ) async -> Result<String, SecurityStorageError> {
    let context=createLogContext(
      operation: "importDataUInt8",
      identifier: customIdentifier
    )
    await logger.info(
      "Importing data with identifier: \(customIdentifier ?? "unknown")",
      context: context
    )
    return await wrapped.importData(data, customIdentifier: customIdentifier)
  }

  /**
   Imports data from Foundation Data.

   - Parameters:
     - data: The data to import
     - customIdentifier: Custom identifier for the data
   - Returns: Identifier for the imported data or an error
   */
  public func importData(
    _ data: Data,
    customIdentifier: String
  ) async -> Result<String, SecurityStorageError> {
    let context=createLogContext(
      operation: "importDataFoundation",
      identifier: customIdentifier
    )
    await logger.info("Importing Data with identifier: \(customIdentifier)", context: context)
    // Convert Data to [UInt8] and delegate to the other importData method
    return await wrapped.importData(Array(data), customIdentifier: customIdentifier)
  }

  /**
   Imports data from a string.

   - Parameters:
     - data: The string data to import
     - customIdentifier: Optional custom identifier for the data
   - Returns: Identifier for the imported data or an error
   */
  public func importData(
    _ data: String,
    customIdentifier: String
  ) async -> Result<String, SecurityStorageError> {
    let context=createLogContext(
      operation: "importDataString",
      identifier: customIdentifier
    )
    await logger.info("Importing data with identifier: \(customIdentifier)", context: context)
    
    // Convert String to [UInt8] using UTF8 encoding
    guard let dataBytes = data.data(using: .utf8) else {
      await logger.error("Failed to encode string as UTF-8", context: context)
      return .failure(.invalidInput("Failed to encode string as UTF-8"))
    }
    
    // Delegate to the wrapped implementation with the converted bytes
    return await wrapped.importData([UInt8](dataBytes), customIdentifier: customIdentifier)
  }

  // MARK: - Delegated Operations

  /**
   Stores data in secure storage.

   - Parameters:
     - data: The data to store
     - identifier: Identifier for the data
   - Returns: Success or an error
   */
  public func storeData(
    data: Data,
    identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    // Check rate limiter
    if await rateLimiter.isRateLimited("storeData") {
      let context=createLogContext(
        operation: "storeData",
        details: "Rate limited"
      )

      await logger.warning("Rate limited data storage operation", context: context)
      return .failure(.operationFailed("Rate limited"))
    }

    // Validate inputs
    if identifier.isEmpty {
      let context=createLogContext(
        operation: "storeData",
        details: "Empty identifier"
      )

      await logger.error("Invalid identifier", context: context)
      return .failure(.invalidInput("Identifier cannot be empty"))
    }

    // Create log context
    let context=createLogContext(
      operation: "storeData",
      details: "Storing data with identifier \(identifier)"
    )

    // Log the operation
    await logger.info("Storing data", context: context)

    // Delegate to wrapped implementation
    return await wrapped.storeData(data: data, identifier: identifier)
  }

  /**
   Retrieves data from secure storage.

   - Parameter identifier: Identifier for the data to retrieve
   - Returns: The retrieved data or an error
   */
  public func retrieveData(
    identifier: String
  ) async -> Result<Data, SecurityStorageError> {
    // Check rate limiter
    if await rateLimiter.isRateLimited("retrieveData") {
      let context=createLogContext(
        operation: "retrieveData",
        details: "Rate limited"
      )

      await logger.warning("Rate limited data retrieval operation", context: context)
      return .failure(.operationFailed("Rate limited"))
    }

    // Validate inputs
    if identifier.isEmpty {
      let context=createLogContext(
        operation: "retrieveData",
        details: "Empty identifier"
      )

      await logger.error("Invalid identifier", context: context)
      return .failure(.invalidInput("Identifier cannot be empty"))
    }

    // Create log context
    let context=createLogContext(
      operation: "retrieveData",
      details: "Retrieving data with identifier \(identifier)"
    )

    // Log the operation
    await logger.info("Retrieving data", context: context)

    // Delegate to wrapped implementation
    return await wrapped.retrieveData(identifier: identifier)
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
    if await rateLimiter.isRateLimited("deleteData") {
      let context=createLogContext(
        operation: "deleteData",
        details: "Rate limited"
      )

      await logger.warning("Rate limited delete operation", context: context)
      return .failure(.operationFailed("Rate limited"))
    }

    // Validate inputs
    if identifier.isEmpty {
      let context=createLogContext(
        operation: "deleteData",
        details: "Empty identifier"
      )

      await logger.error("Invalid identifier", context: context)
      return .failure(.invalidInput("Identifier cannot be empty"))
    }

    // Create log context
    let context=createLogContext(
      operation: "deleteData",
      details: "Deleting data with identifier \(identifier)"
    )

    // Log the operation
    await logger.info("Deleting data", context: context)

    // Delegate to wrapped implementation
    return await wrapped.deleteData(identifier: identifier)
  }
}

/**
 Base rate limiter for security operations.
 This class provides a common interface for rate limiting that can be
 implemented by different rate limiting strategies.
 */
public actor BaseRateLimiter: Sendable {
  private var lastOperationTime: [String: Date]=[:]
  private let minimumInterval: TimeInterval=0.1 // 100ms minimum between operations

  /**
   Initialises a new rate limiter.
   */
  public init() {}

  /**
   Check if an operation is currently rate limited.

   - Parameter operation: The operation to check

   - Returns: true if the operation is rate limited, false otherwise
   */
  public func isRateLimited(_ operation: String) async -> Bool {
    let now=Date()

    if
      let lastTime=lastOperationTime[operation],
      now.timeIntervalSince(lastTime) < minimumInterval
    {
      return true
    }

    lastOperationTime[operation]=now
    return false
  }
}
