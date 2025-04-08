import CoreSecurityTypes
import CryptoLogger
import Foundation
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

  /// Rate limiting configuration for security operations
  private let rateLimiter: RateLimiterAdapter

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
    rateLimiter: RateLimiterAdapter
  ) {
    self.wrapped=wrapped
    self.logger=logger
    self.rateLimiter=rateLimiter
  }

  /**
   Creates a log context for crypto operations.

   - Parameters:
     - operation: The operation being performed
     - identifier: Optional identifier for the data or key
     - details: Optional additional details
   - Returns: A LogContextDTO for logging
   */
  private func createLogContext(
    operation: String,
    identifier: String?=nil,
    details: String?=nil
  ) -> LogContextDTO {
    var context=CryptoLogContext(
      operation: operation,
      identifier: identifier
    )

    if let details {
      context=context.with(
        key: "details",
        value: details,
        privacy: .private
      )
    }

    return context
  }

  // MARK: - Encryption Operations

  /**
   Encrypts a string using the specified key.

   - Parameters:
     - data: The string to encrypt
     - keyIdentifier: Identifier for the encryption key
     - options: Optional encryption options
   - Returns: Identifier for the encrypted data or an error
   */
  public func encrypt(
    data: String,
    keyIdentifier: String,
    options: EncryptionOptions?=nil
  ) async -> Result<String, SecurityStorageError> {
    // Check rate limiter
    if rateLimiter.isRateLimited("encrypt") {
      let context=createLogContext(
        operation: "encrypt",
        details: "Rate limited"
      )

      await logger.warning("Rate limited encryption operation", context: context)
      return .failure(.operationFailed("Rate limited"))
    }

    // Validate inputs
    if data.isEmpty {
      let context=createLogContext(
        operation: "encrypt",
        details: "Empty data"
      )

      await logger.error("Empty data provided for encryption", context: context)
      return .failure(.operationFailed("data cannot be empty"))
    }

    if keyIdentifier.isEmpty {
      let context=createLogContext(
        operation: "encrypt",
        details: "Empty key identifier"
      )

      await logger.error("Empty key identifier provided for encryption", context: context)
      return .failure(.operationFailed("keyIdentifier cannot be empty"))
    }

    // Get the key
    let keyResult=await wrapped.retrieveData(identifier: keyIdentifier)
    guard case let .success(key)=keyResult else {
      let context=createLogContext(
        operation: "encrypt",
        identifier: keyIdentifier,
        details: "Key not found"
      )

      await logger.error("Key not found for encryption: \(keyIdentifier)", context: context)
      return .failure(.keyNotFound)
    }

    // Delegate to wrapped implementation
    return await wrapped.encrypt(data: data, keyIdentifier: keyIdentifier, options: options)
  }

  /**
   Decrypts a string using the specified key.

   - Parameters:
     - encryptedDataIdentifier: Identifier for the encrypted data
     - keyIdentifier: Identifier for the decryption key
     - options: Optional decryption options
   - Returns: The decrypted string or an error
   */
  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options: DecryptionOptions?=nil
  ) async -> Result<String, SecurityStorageError> {
    // Check rate limiter
    if rateLimiter.isRateLimited("decrypt") {
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

      await logger.error("Empty data identifier provided for decryption", context: context)
      return .failure(.operationFailed("encryptedDataIdentifier cannot be empty"))
    }

    if keyIdentifier.isEmpty {
      let context=createLogContext(
        operation: "decrypt",
        details: "Empty key identifier"
      )

      await logger.error("Empty key identifier provided for decryption", context: context)
      return .failure(.operationFailed("keyIdentifier cannot be empty"))
    }

    // Get the encrypted data
    let dataResult=await wrapped.retrieveData(identifier: encryptedDataIdentifier)
    guard case .success=dataResult else {
      let context=createLogContext(
        operation: "decrypt",
        identifier: encryptedDataIdentifier,
        details: "Data not found"
      )

      await logger.error("Encrypted data not found: \(encryptedDataIdentifier)", context: context)
      return .failure(.dataNotFound)
    }

    // Get the key
    let keyResult=await wrapped.retrieveData(identifier: keyIdentifier)
    guard case .success=keyResult else {
      let context=createLogContext(
        operation: "decrypt",
        identifier: keyIdentifier,
        details: "Key not found"
      )

      await logger.error("Key not found for decryption: \(keyIdentifier)", context: context)
      return .failure(.keyNotFound)
    }

    // Delegate to wrapped implementation
    return await wrapped.decrypt(
      encryptedDataIdentifier: encryptedDataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )
  }

  // MARK: - Hashing Operations

  /**
   Generates a hash for the specified data.

   - Parameters:
     - dataIdentifier: Identifier for the data to hash
     - options: Optional hashing options
   - Returns: Identifier for the generated hash or an error
   */
  public func generateHash(
    dataIdentifier: String,
    options: HashingOptions?=nil
  ) async -> Result<String, SecurityStorageError> {
    // Check rate limiter
    if rateLimiter.isRateLimited("hash") {
      let context=createLogContext(
        operation: "hash",
        details: "Rate limited"
      )

      await logger.warning("Rate limited hashing operation", context: context)
      return .failure(.operationFailed("Rate limited"))
    }

    // Validate inputs
    if dataIdentifier.isEmpty {
      let context=createLogContext(
        operation: "hash",
        details: "Empty data identifier"
      )

      await logger.error("Empty data identifier provided for hashing", context: context)
      return .failure(.operationFailed("dataIdentifier cannot be empty"))
    }

    // Get the data
    let dataResult=await wrapped.retrieveData(identifier: dataIdentifier)
    guard case .success=dataResult else {
      let context=createLogContext(
        operation: "hash",
        identifier: dataIdentifier,
        details: "Data not found"
      )

      await logger.error("Data not found for hashing: \(dataIdentifier)", context: context)
      return .failure(.dataNotFound)
    }

    // Delegate to wrapped implementation
    return await wrapped.generateHash(dataIdentifier: dataIdentifier, options: options)
  }

  /**
   Verifies a hash against the specified data.

   - Parameters:
     - dataIdentifier: Identifier for the data to verify
     - hashIdentifier: Identifier for the hash to verify against
     - options: Optional verification options
   - Returns: Whether the hash is valid or an error
   */
  public func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options: HashingOptions?=nil
  ) async -> Result<Bool, SecurityStorageError> {
    // Check rate limiter
    if rateLimiter.isRateLimited("verify") {
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

      await logger.error("Empty data identifier provided for hash verification", context: context)
      return .failure(.operationFailed("dataIdentifier cannot be empty"))
    }

    if hashIdentifier.isEmpty {
      let context=createLogContext(
        operation: "verifyHash",
        details: "Empty hash identifier"
      )

      await logger.error("Empty hash identifier provided for verification", context: context)
      return .failure(.operationFailed("hashIdentifier cannot be empty"))
    }

    // Get the data
    let dataResult=await wrapped.retrieveData(identifier: dataIdentifier)
    guard case .success=dataResult else {
      let context=createLogContext(
        operation: "verifyHash",
        identifier: dataIdentifier,
        details: "Data not found"
      )

      await logger.error(
        "Data not found for hash verification: \(dataIdentifier)",
        context: context
      )
      return .failure(.dataNotFound)
    }

    // Get the hash
    let hashResult=await wrapped.retrieveData(identifier: hashIdentifier)
    guard case .success=hashResult else {
      let context=createLogContext(
        operation: "verifyHash",
        identifier: hashIdentifier,
        details: "Hash not found"
      )

      await logger.error("Hash not found for verification: \(hashIdentifier)", context: context)
      return .failure(.hashNotFound)
    }

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
    if rateLimiter.isRateLimited("export") {
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

      await logger.error("Empty identifier provided for data export", context: context)
      return .failure(.operationFailed("identifier cannot be empty"))
    }

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
    options: KeyGenerationOptions?=nil
  ) async -> Result<String, SecurityStorageError> {
    // Check rate limiter
    if rateLimiter.isRateLimited("generateKey") {
      let context=createLogContext(
        operation: "generateKey",
        details: "Rate limited"
      )

      await logger.warning("Rate limited key generation operation", context: context)
      return .failure(.operationFailed("Rate limited"))
    }

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
    customIdentifier: String?=nil
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
    return await wrapped.importData(data, customIdentifier: customIdentifier)
  }

  // MARK: - Delegated Operations

  /**
   Generates a hash for the specified data.

   - Parameters:
     - dataIdentifier: Identifier for the data to hash
     - options: Optional hashing options
   - Returns: Identifier for the generated hash or an error
   */
  public func generateHash(
    dataIdentifier: String,
    options: HashingOptions?=nil
  ) async -> Result<String, SecurityStorageError> {
    let context=createLogContext(
      operation: "generateHash",
      identifier: dataIdentifier
    )
    await logger.info(
      "Generating hash for data with identifier: \(dataIdentifier)",
      context: context
    )
    return await wrapped.generateHash(dataIdentifier: dataIdentifier, options: options)
  }

  /**
   Stores data in secure storage.

   - Parameters:
     - data: The data to store
     - identifier: Identifier for the data
   - Returns: Success or an error
   */
  public func storeData(
    data: [UInt8],
    identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    let context=createLogContext(
      operation: "storeData",
      identifier: identifier
    )

    await logger.info("Storing data with identifier: \(identifier)", context: context)
    return await wrapped.storeData(
      data: data,
      identifier: identifier
    )
  }

  /**
   Retrieves data from secure storage.

   - Parameter identifier: Identifier for the data to retrieve
   - Returns: The retrieved data or an error
   */
  public func retrieveData(
    identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    let context=createLogContext(
      operation: "retrieveData",
      identifier: identifier
    )

    await logger.info("Retrieving data with identifier: \(identifier)", context: context)
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
    let context=createLogContext(
      operation: "deleteData",
      identifier: identifier
    )
    await logger.info("Deleting data with identifier: \(identifier)", context: context)
    return await wrapped.deleteData(identifier: identifier)
  }
}

/**
 Base rate limiter for security operations.
 This class provides a common interface for rate limiting that can be
 implemented by different rate limiting strategies.
 */
public class RateLimiterAdapter {
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
  open func isRateLimited(_ operation: String) -> Bool {
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
