import CoreSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import CryptoLogger
import UnifiedCryptoTypes

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
  private let logger: PrivacyAwareLoggingProtocol

  /// Rate limiting configuration for security operations
  private let rateLimiter: RateLimiter

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
    logger: PrivacyAwareLoggingProtocol,
    rateLimiter: RateLimiter=RateLimiter()
  ) {
    self.wrapped = wrapped
    self.logger = logger
    self.rateLimiter = rateLimiter
  }

  /**
   Encrypts data using the specified key.

   - Parameters:
     - dataIdentifier: Identifier for the data to encrypt
     - keyIdentifier: Identifier for the encryption key
     - options: Optional encryption parameters

   - Returns: Identifier for the encrypted data or error
   */
  public func encrypt(
    dataIdentifier: String,
    keyIdentifier: String,
    options: SecurityCoreInterfaces.EncryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Check rate limiter
    if rateLimiter.isRateLimited(.encrypt) {
      let context = CryptoLogContext(
        operation: "encrypt",
        identifier: dataIdentifier,
        status: "rateLimited"
      )
      
      await logger.warning("Rate limited encryption operation", context: context)
      return .failure(.rateLimited)
    }

    // Input validation
    if dataIdentifier.isEmpty {
      let context = CryptoLogContext(
        operation: "encrypt",
        status: "error",
        metadata: LogMetadataDTOCollection().withPublic(key: "error", value: "emptyDataIdentifier")
      )
      
      await logger.error("Empty data identifier provided for encryption", context: context)
      return .failure(.invalidArgument("dataIdentifier cannot be empty"))
    }

    if keyIdentifier.isEmpty {
      let context = CryptoLogContext(
        operation: "encrypt",
        status: "error",
        metadata: LogMetadataDTOCollection().withPublic(key: "error", value: "emptyKeyIdentifier")
      )
      
      await logger.error("Empty key identifier provided for encryption", context: context)
      return .failure(.invalidArgument("keyIdentifier cannot be empty"))
    }

    // Verify key exists
    let keyResult=await secureStorage.retrieveData(withIdentifier: keyIdentifier)
    guard case .success=keyResult else {
      let context = CryptoLogContext(
        operation: "encrypt",
        identifier: keyIdentifier,
        status: "error",
        metadata: LogMetadataDTOCollection().withPublic(key: "error", value: "keyNotFound")
      )
      
      await logger.error(
        "Key not found for encryption: \(keyIdentifier)",
        context: context
      )
      return .failure(.keyNotFound)
    }

    // Use the wrapped implementation to perform the encryption
    return await wrapped.encrypt(
      dataIdentifier: dataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )
  }

  /**
   Decrypts data using the specified key.

   - Parameters:
     - encryptedDataIdentifier: Identifier for the encrypted data
     - keyIdentifier: Identifier for the decryption key
     - options: Optional decryption parameters

   - Returns: Identifier for the decrypted data or error
   */
  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options: SecurityCoreInterfaces.DecryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Check rate limiter
    if rateLimiter.isRateLimited(.decrypt) {
      let context = CryptoLogContext(
        operation: "decrypt",
        identifier: encryptedDataIdentifier,
        status: "rateLimited"
      )
      
      await logger.warning("Rate limited decryption operation", context: context)
      return .failure(.rateLimited)
    }

    // Input validation
    if encryptedDataIdentifier.isEmpty {
      let context = CryptoLogContext(
        operation: "decrypt",
        status: "error",
        metadata: LogMetadataDTOCollection().withPublic(key: "error", value: "emptyDataIdentifier")
      )
      
      await logger.error("Empty data identifier provided for decryption", context: context)
      return .failure(.invalidArgument("encryptedDataIdentifier cannot be empty"))
    }

    if keyIdentifier.isEmpty {
      let context = CryptoLogContext(
        operation: "decrypt",
        status: "error",
        metadata: LogMetadataDTOCollection().withPublic(key: "error", value: "emptyKeyIdentifier")
      )
      
      await logger.error("Empty key identifier provided for decryption", context: context)
      return .failure(.invalidArgument("keyIdentifier cannot be empty"))
    }

    // Verify encrypted data exists
    let dataResult=await secureStorage.retrieveData(withIdentifier: encryptedDataIdentifier)
    guard case .success=dataResult else {
      let context = CryptoLogContext(
        operation: "decrypt",
        identifier: encryptedDataIdentifier,
        status: "error",
        metadata: LogMetadataDTOCollection().withPublic(key: "error", value: "dataNotFound")
      )
      
      await logger.error(
        "Encrypted data not found: \(encryptedDataIdentifier)",
        context: context
      )
      return .failure(.keyNotFound)
    }

    // Verify key exists
    let keyResult=await secureStorage.retrieveData(withIdentifier: keyIdentifier)
    guard case .success=keyResult else {
      let context = CryptoLogContext(
        operation: "decrypt",
        identifier: keyIdentifier,
        status: "error",
        metadata: LogMetadataDTOCollection().withPublic(key: "error", value: "keyNotFound")
      )
      
      await logger.error(
        "Key not found for decryption: \(keyIdentifier)",
        context: context
      )
      return .failure(.keyNotFound)
    }

    // Use the wrapped implementation to perform the decryption
    return await wrapped.decrypt(
      encryptedDataIdentifier: encryptedDataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )
  }

  /**
   Create a hash of the specified data.

   - Parameters:
     - dataIdentifier: Identifier for the data to hash
     - options: Optional hashing options
   - Returns: Identifier for the hash or an error
   */
  public func hash(
    dataIdentifier: String,
    options: HashingOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Check rate limiter
    if rateLimiter.isRateLimited(.hash) {
      let context = CryptoLogContext(
        operation: "hash",
        identifier: dataIdentifier,
        status: "rateLimited"
      )
      
      await logger.warning("Rate limited hashing operation", context: context)
      return .failure(.rateLimited)
    }

    // Input validation
    if dataIdentifier.isEmpty {
      let context = CryptoLogContext(
        operation: "hash",
        status: "error",
        metadata: LogMetadataDTOCollection().withPublic(key: "error", value: "emptyDataIdentifier")
      )
      
      await logger.error("Empty data identifier provided for hashing", context: context)
      return .failure(.invalidArgument("dataIdentifier cannot be empty"))
    }

    // Delegate to wrapped implementation
    return await wrapped.hash(
      dataIdentifier: dataIdentifier,
      options: options
    )
  }

  /**
   Verify that a hash matches the expected data.

   - Parameters:
     - dataIdentifier: Identifier for the data to verify
     - hashIdentifier: Identifier for the expected hash
     - options: Optional hashing options used for verification
   - Returns: Whether the hash matches or an error
   */
  public func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options: HashingOptions?
  ) async -> Result<Bool, SecurityStorageError> {
    // Check rate limiter
    if rateLimiter.isRateLimited(.verify) {
      let context = CryptoLogContext(
        operation: "verifyHash",
        identifier: dataIdentifier,
        status: "rateLimited"
      )
      
      await logger.warning("Rate limited hash verification operation", context: context)
      return .failure(.rateLimited)
    }

    // Verify data exists
    let dataResult=await secureStorage.retrieveData(withIdentifier: dataIdentifier)
    guard case .success=dataResult else {
      let context = CryptoLogContext(
        operation: "verifyHash",
        identifier: dataIdentifier,
        status: "error",
        metadata: LogMetadataDTOCollection().withPublic(key: "error", value: "dataNotFound")
      )
      
      await logger.error(
        "Data not found for hash verification: \(dataIdentifier)",
        context: context
      )
      return .failure(.keyNotFound)
    }

    // Verify hash exists
    let hashResult=await secureStorage.retrieveData(withIdentifier: hashIdentifier)
    guard case .success=hashResult else {
      let context = CryptoLogContext(
        operation: "verifyHash",
        identifier: hashIdentifier,
        status: "error",
        metadata: LogMetadataDTOCollection().withPublic(key: "error", value: "hashNotFound")
      )
      
      await logger.error(
        "Hash not found for verification: \(hashIdentifier)",
        context: context
      )
      return .failure(.keyNotFound)
    }

    // Delegate to wrapped implementation
    return await wrapped.verifyHash(
      dataIdentifier: dataIdentifier,
      hashIdentifier: hashIdentifier,
      options: options
    )
  }

  /**
   Generate a new cryptographic key.

   - Parameters:
     - length: Length of the key in bits
     - options: Optional key generation options
   - Returns: Identifier for the generated key or an error
   */
  public func generateKey(
    length: Int,
    options: KeyGenerationOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Check rate limiter
    if rateLimiter.isRateLimited(.generateKey) {
      let context = CryptoLogContext(
        operation: "generateKey",
        status: "rateLimited"
      )
      
      await logger.warning("Rate limited key generation operation", context: context)
      return .failure(.rateLimited)
    }

    // Input validation
    if length < 128 || length > 4096 || length % 8 != 0 {
      let context = CryptoLogContext(
        operation: "generateKey",
        status: "error",
        metadata: LogMetadataDTOCollection().withPublic(key: "error", value: "invalidKeyLength")
      )
      
      await logger.error(
        "Invalid key length: \(length)",
        context: context
      )
      return .failure(.invalidArgument("Invalid key length: \(length)"))
    }

    // Delegate to wrapped implementation
    return await wrapped.generateKey(
      length: length,
      options: options
    )
  }

  /**
   Import data into secure storage.

   - Parameters:
     - data: The data to import
     - customIdentifier: Optional custom identifier to use
   - Returns: Identifier for the imported data or an error
   */
  public func importData(
    _ data: [UInt8],
    customIdentifier: String?
  ) async -> Result<String, SecurityStorageError> {
    // Check rate limiter
    if rateLimiter.isRateLimited(.importData) {
      let context = CryptoLogContext(
        operation: "importData",
        status: "rateLimited"
      )
      
      await logger.warning("Rate limited data import operation", context: context)
      return .failure(.rateLimited)
    }

    // Input validation
    if data.isEmpty {
      let context = CryptoLogContext(
        operation: "importData",
        status: "error",
        metadata: LogMetadataDTOCollection().withPublic(key: "error", value: "emptyData")
      )
      
      await logger.error("Empty data provided for import", context: context)
      return .failure(.invalidArgument("Invalid input: empty data"))
    }

    if let customIdentifier, customIdentifier.isEmpty {
      let context = CryptoLogContext(
        operation: "importData",
        status: "error",
        metadata: LogMetadataDTOCollection().withPublic(key: "error", value: "emptyCustomIdentifier")
      )
      
      await logger.error(
        "Empty custom identifier provided for import",
        context: context
      )
      return .failure(.invalidArgument("Invalid input: empty custom identifier"))
    }

    // Delegate to wrapped implementation
    return await wrapped.importData(
      data,
      customIdentifier: customIdentifier
    )
  }

  /**
   Export data from secure storage.

   This operation is rate-limited and includes additional validation.

   - Parameter identifier: Identifier for the data to export
   - Returns: The raw data or an error
   */
  public func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    // Check rate limiter
    if rateLimiter.isRateLimited(.exportData) {
      let context = CryptoLogContext(
        operation: "exportData",
        identifier: identifier,
        status: "rateLimited"
      )
      
      await logger.warning("Rate limited data export operation", context: context)
      return .failure(.rateLimited)
    }

    // Input validation
    if identifier.isEmpty {
      let context = CryptoLogContext(
        operation: "exportData",
        status: "error",
        metadata: LogMetadataDTOCollection().withPublic(key: "error", value: "emptyIdentifier")
      )
      
      await logger.error("Empty identifier provided for data export", context: context)
      return .failure(.invalidArgument("Invalid input: empty identifier"))
    }

    // Verify data exists
    let dataResult=await secureStorage.retrieveData(withIdentifier: identifier)
    guard case .success=dataResult else {
      let context = CryptoLogContext(
        operation: "exportData",
        identifier: identifier,
        status: "error",
        metadata: LogMetadataDTOCollection().withPublic(key: "error", value: "dataNotFound")
      )
      
      await logger.error(
        "Data not found for export: \(identifier)",
        context: context
      )
      return .failure(.keyNotFound)
    }

    // Delegate to wrapped implementation
    return await wrapped.exportData(identifier: identifier)
  }
}

/**
 Simple rate limiter for security operations.
 */
public final class RateLimiter: Sendable {
  /// Operations that can be rate limited
  public enum Operation: String, Sendable {
    case encrypt
    case decrypt
    case hash
    case verifyHash
    case generateKey
    case importData
    case exportData
  }

  // For a real implementation, this would track operations and their timestamps
  // This is just a placeholder for the example
  public func isRateLimited(_: Operation) -> Bool {
    // In a real implementation, we would check if the operation has been
    // performed too many times in a short period
    false
  }

  public init() {}
}
