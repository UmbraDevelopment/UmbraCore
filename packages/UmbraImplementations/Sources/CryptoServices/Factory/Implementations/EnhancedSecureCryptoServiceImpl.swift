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
    self.wrapped=wrapped
    self.logger=logger
    self.rateLimiter=rateLimiter
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
      let context=CryptoLogContext(
        operation: "encrypt",
        identifier: dataIdentifier,
        status: "rateLimited"
      )

      await logger.warning("Rate limited encryption operation", context: context)
      return .failure(.operationFailed("Rate limited"))
    }

    // Input validation
    if dataIdentifier.isEmpty {
      let context=CryptoLogContext(
        operation: "encrypt",
        status: "error",
        metadata: LogMetadataDTOCollection().withPublic(key: "error", value: "emptyDataIdentifier")
      )

      await logger.error("Empty data identifier provided for encryption", context: context)
      return .failure(.operationFailed("dataIdentifier cannot be empty"))
    }

    if keyIdentifier.isEmpty {
      let context=CryptoLogContext(
        operation: "encrypt",
        status: "error",
        metadata: LogMetadataDTOCollection().withPublic(key: "error", value: "emptyKeyIdentifier")
      )

      await logger.error("Empty key identifier provided for encryption", context: context)
      return .failure(.operationFailed("keyIdentifier cannot be empty"))
    }

    // Verify key exists
    let keyResult=await secureStorage.retrieveData(withIdentifier: keyIdentifier)
    guard case .success=keyResult else {
      let context=CryptoLogContext(
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
      let context=CryptoLogContext(
        operation: "decrypt",
        identifier: encryptedDataIdentifier,
        status: "rateLimited"
      )

      await logger.warning("Rate limited decryption operation", context: context)
      return .failure(.operationFailed("Rate limited"))
    }

    // Input validation
    if encryptedDataIdentifier.isEmpty {
      let context=CryptoLogContext(
        operation: "decrypt",
        status: "error",
        metadata: LogMetadataDTOCollection().withPublic(key: "error", value: "emptyDataIdentifier")
      )

      await logger.error("Empty data identifier provided for decryption", context: context)
      return .failure(.operationFailed("encryptedDataIdentifier cannot be empty"))
    }

    if keyIdentifier.isEmpty {
      let context=CryptoLogContext(
        operation: "decrypt",
        status: "error",
        metadata: LogMetadataDTOCollection().withPublic(key: "error", value: "emptyKeyIdentifier")
      )

      await logger.error("Empty key identifier provided for decryption", context: context)
      return .failure(.operationFailed("keyIdentifier cannot be empty"))
    }

    // Verify encrypted data exists
    let dataResult=await secureStorage.retrieveData(withIdentifier: encryptedDataIdentifier)
    guard case .success=dataResult else {
      let context=CryptoLogContext(
        operation: "decrypt",
        identifier: encryptedDataIdentifier,
        status: "error",
        metadata: LogMetadataDTOCollection().withPublic(key: "error", value: "dataNotFound")
      )

      await logger.error(
        "Encrypted data not found: \(encryptedDataIdentifier)",
        context: context
      )
      return .failure(.dataNotFound)
    }

    // Verify key exists
    let keyResult=await secureStorage.retrieveData(withIdentifier: keyIdentifier)
    guard case .success=keyResult else {
      let context=CryptoLogContext(
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
   Hashes data using the specified algorithm.

   - Parameters:
     - dataIdentifier: Identifier for the data to hash
     - options: Optional hashing parameters

   - Returns: Identifier for the hashed data or error
   */
  public func hash(
    dataIdentifier: String,
    options: SecurityCoreInterfaces.HashingOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Check rate limiter
    if rateLimiter.isRateLimited(.hash) {
      let context=CryptoLogContext(
        operation: "hash",
        identifier: dataIdentifier,
        status: "rateLimited"
      )

      await logger.warning("Rate limited hashing operation", context: context)
      return .failure(.operationFailed("Rate limited"))
    }

    // Input validation
    if dataIdentifier.isEmpty {
      let context=CryptoLogContext(
        operation: "hash",
        status: "error",
        metadata: LogMetadataDTOCollection().withPublic(key: "error", value: "emptyDataIdentifier")
      )

      await logger.error("Empty data identifier provided for hashing", context: context)
      return .failure(.operationFailed("dataIdentifier cannot be empty"))
    }

    // Verify data exists
    let dataResult=await secureStorage.retrieveData(withIdentifier: dataIdentifier)
    guard case .success=dataResult else {
      let context=CryptoLogContext(
        operation: "hash",
        identifier: dataIdentifier,
        status: "error",
        metadata: LogMetadataDTOCollection().withPublic(key: "error", value: "dataNotFound")
      )

      await logger.error(
        "Data not found for hashing: \(dataIdentifier)",
        context: context
      )
      return .failure(.dataNotFound)
    }

    // Use the wrapped implementation to perform the hashing
    return await wrapped.hash(
      dataIdentifier: dataIdentifier,
      options: options
    )
  }

  /**
   Verifies a hash against the original data.

   - Parameters:
     - dataIdentifier: Identifier for the data to verify
     - hashIdentifier: Identifier for the hash to verify against
     - options: Optional verification parameters

   - Returns: true if the hash matches, false otherwise or error
   */
  public func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options: SecurityCoreInterfaces.HashingOptions?
  ) async -> Result<Bool, SecurityStorageError> {
    // Check rate limiter
    if rateLimiter.isRateLimited(.verify) {
      let context=CryptoLogContext(
        operation: "verifyHash",
        identifier: dataIdentifier,
        status: "rateLimited"
      )

      await logger.warning("Rate limited hash verification operation", context: context)
      return .failure(.operationFailed("Rate limited"))
    }

    // Input validation
    if dataIdentifier.isEmpty {
      let context=CryptoLogContext(
        operation: "verifyHash",
        status: "error",
        metadata: LogMetadataDTOCollection().withPublic(key: "error", value: "emptyDataIdentifier")
      )

      await logger.error("Empty data identifier provided for hash verification", context: context)
      return .failure(.operationFailed("dataIdentifier cannot be empty"))
    }

    if hashIdentifier.isEmpty {
      let context=CryptoLogContext(
        operation: "verifyHash",
        status: "error",
        metadata: LogMetadataDTOCollection().withPublic(key: "error", value: "emptyHashIdentifier")
      )

      await logger.error("Empty hash identifier provided for verification", context: context)
      return .failure(.operationFailed("hashIdentifier cannot be empty"))
    }

    // Verify data exists
    let dataResult=await secureStorage.retrieveData(withIdentifier: dataIdentifier)
    guard case .success=dataResult else {
      let context=CryptoLogContext(
        operation: "verifyHash",
        identifier: dataIdentifier,
        status: "error",
        metadata: LogMetadataDTOCollection().withPublic(key: "error", value: "dataNotFound")
      )

      await logger.error(
        "Data not found for hash verification: \(dataIdentifier)",
        context: context
      )
      return .failure(.dataNotFound)
    }

    // Verify hash exists
    let hashResult=await secureStorage.retrieveData(withIdentifier: hashIdentifier)
    guard case .success=hashResult else {
      let context=CryptoLogContext(
        operation: "verifyHash",
        identifier: hashIdentifier,
        status: "error",
        metadata: LogMetadataDTOCollection().withPublic(key: "error", value: "hashNotFound")
      )

      await logger.error(
        "Hash not found for verification: \(hashIdentifier)",
        context: context
      )
      return .failure(.hashNotFound)
    }

    // Use the wrapped implementation to perform the verification
    return await wrapped.verifyHash(
      dataIdentifier: dataIdentifier,
      hashIdentifier: hashIdentifier,
      options: options
    )
  }

  /**
   Export data from secure storage.

   This operation is rate-limited and includes additional validation.

   - Parameters:
     - identifier: Identifier for the data to export

   - Returns: The exported data or error
   */
  public func exportData(
    withIdentifier identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    // Check rate limiter
    if rateLimiter.isRateLimited(.export) {
      let context=CryptoLogContext(
        operation: "exportData",
        identifier: identifier,
        status: "rateLimited"
      )

      await logger.warning("Rate limited data export operation", context: context)
      return .failure(.operationFailed("Rate limited"))
    }

    // Input validation
    if identifier.isEmpty {
      let context=CryptoLogContext(
        operation: "exportData",
        status: "error",
        metadata: LogMetadataDTOCollection().withPublic(key: "error", value: "emptyIdentifier")
      )

      await logger.error("Empty identifier provided for data export", context: context)
      return .failure(.operationFailed("identifier cannot be empty"))
    }

    // Use the wrapped implementation to perform the export
    return await wrapped.exportData(withIdentifier: identifier)
  }

  /**
   Generate a new cryptographic key.

   - Parameters:
     - options: Key generation parameters

   - Returns: Identifier for the generated key or error
   */
  public func generateKey(
    options: SecurityCoreInterfaces.KeyGenerationOptions
  ) async -> Result<String, SecurityStorageError> {
    // Check rate limiter
    if rateLimiter.isRateLimited(.generateKey) {
      let context=CryptoLogContext(
        operation: "generateKey",
        status: "rateLimited"
      )

      await logger.warning("Rate limited key generation operation", context: context)
      return .failure(.operationFailed("Rate limited"))
    }

    // Use the wrapped implementation to generate the key
    return await wrapped.generateKey(options: options)
  }
}

/**
 Simple rate limiter for security operations.
 */
public class RateLimiter {
  public enum Operation: String {
    case encrypt
    case decrypt
    case hash
    case verify
    case export
    case generateKey
  }

  private var lastOperationTime: [Operation: Date]=[:]
  private let minimumInterval: TimeInterval=0.1 // 100ms minimum between operations

  /**
   Check if an operation is currently rate limited.

   - Parameter operation: The operation to check

   - Returns: true if the operation is rate limited, false otherwise
   */
  public func isRateLimited(_ operation: Operation) -> Bool {
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
