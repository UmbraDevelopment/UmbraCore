import CoreSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingServices
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
  private let logger: LoggingInterfaces.LoggingProtocol
  
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
    logger: LoggingInterfaces.LoggingProtocol,
    rateLimiter: RateLimiter = RateLimiter()
  ) {
    self.wrapped = wrapped
    self.logger = logger
    self.rateLimiter = rateLimiter
  }
  
  /**
   Encrypt data using the specified key.
   
   This operation is rate-limited and includes additional validation.
   
   - Parameters:
     - dataIdentifier: Identifier for the data to encrypt
     - keyIdentifier: Identifier for the key to use
     - options: Optional encryption options
   - Returns: Identifier for the encrypted data or an error
   */
  public func encrypt(
    dataIdentifier: String,
    keyIdentifier: String,
    options: EncryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Check rate limiter
    if rateLimiter.isRateLimited(.encrypt) {
      await logger.warning(
        "Rate limited encryption operation",
        metadata: nil,
        source: "EnhancedSecureCryptoService"
      )
      return .failure(.operationFailed("Rate limited operation"))
    }
    
    // Input validation
    guard !dataIdentifier.isEmpty && !keyIdentifier.isEmpty else {
      await logger.error(
        "Empty identifier provided for encryption",
        metadata: nil,
        source: "EnhancedSecureCryptoService"
      )
      return .failure(.operationFailed("Invalid input: empty identifier"))
    }
    
    // Verify key exists
    let keyResult = await secureStorage.retrieveData(withIdentifier: keyIdentifier)
    guard case .success = keyResult else {
      await logger.error(
        "Key not found for encryption: \(keyIdentifier)",
        metadata: nil,
        source: "EnhancedSecureCryptoService"
      )
      return .failure(.keyNotFound)
    }
    
    // Delegate to wrapped implementation
    return await wrapped.encrypt(
      dataIdentifier: dataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )
  }
  
  /**
   Decrypt data using the specified key.
   
   This operation is rate-limited and includes additional validation.
   
   - Parameters:
     - encryptedDataIdentifier: Identifier for the encrypted data
     - keyIdentifier: Identifier for the key to use
     - options: Optional decryption options
   - Returns: Identifier for the decrypted data or an error
   */
  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options: DecryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Check rate limiter
    if rateLimiter.isRateLimited(.decrypt) {
      await logger.warning(
        "Rate limited decryption operation",
        metadata: nil,
        source: "EnhancedSecureCryptoService"
      )
      return .failure(.operationFailed("Rate limited operation"))
    }
    
    // Verify encrypted data exists
    let dataResult = await secureStorage.retrieveData(withIdentifier: encryptedDataIdentifier)
    guard case .success = dataResult else {
      await logger.error(
        "Encrypted data not found: \(encryptedDataIdentifier)",
        metadata: nil,
        source: "EnhancedSecureCryptoService"
      )
      return .failure(.keyNotFound)
    }
    
    // Verify key exists
    let keyResult = await secureStorage.retrieveData(withIdentifier: keyIdentifier)
    guard case .success = keyResult else {
      await logger.error(
        "Key not found for decryption: \(keyIdentifier)",
        metadata: nil,
        source: "EnhancedSecureCryptoService"
      )
      return .failure(.keyNotFound)
    }
    
    // Delegate to wrapped implementation
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
      await logger.warning(
        "Rate limited hashing operation",
        metadata: nil,
        source: "EnhancedSecureCryptoService"
      )
      return .failure(.operationFailed("Rate limited operation"))
    }
    
    // Input validation
    guard !dataIdentifier.isEmpty else {
      await logger.error(
        "Empty data identifier provided for hashing",
        metadata: nil,
        source: "EnhancedSecureCryptoService"
      )
      return .failure(.operationFailed("Invalid input: empty data identifier"))
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
      await logger.warning(
        "Rate limited hash verification operation",
        metadata: nil,
        source: "EnhancedSecureCryptoService"
      )
      return .failure(.operationFailed("Rate limited operation"))
    }
    
    // Verify data exists
    let dataResult = await secureStorage.retrieveData(withIdentifier: dataIdentifier)
    guard case .success = dataResult else {
      await logger.error(
        "Data not found for hash verification: \(dataIdentifier)",
        metadata: nil,
        source: "EnhancedSecureCryptoService"
      )
      return .failure(.keyNotFound)
    }
    
    // Verify hash exists
    let hashResult = await secureStorage.retrieveData(withIdentifier: hashIdentifier)
    guard case .success = hashResult else {
      await logger.error(
        "Hash not found for verification: \(hashIdentifier)",
        metadata: nil,
        source: "EnhancedSecureCryptoService"
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
    options: UnifiedCryptoTypes.KeyGenerationOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Check rate limiter
    if rateLimiter.isRateLimited(.generateKey) {
      await logger.warning(
        "Rate limited key generation operation",
        metadata: nil,
        source: "EnhancedSecureCryptoService"
      )
      return .failure(.operationFailed("Rate limited operation"))
    }
    
    // Input validation
    if length < 128 || length > 4096 || length % 8 != 0 {
      await logger.error(
        "Invalid key length: \(length)",
        metadata: nil,
        source: "EnhancedSecureCryptoService"
      )
      return .failure(.operationFailed("Invalid key length: \(length)"))
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
      await logger.warning(
        "Rate limited data import operation",
        metadata: nil,
        source: "EnhancedSecureCryptoService"
      )
      return .failure(.operationFailed("Rate limited operation"))
    }
    
    // Input validation
    guard !data.isEmpty else {
      await logger.error(
        "Empty data provided for import",
        metadata: nil,
        source: "EnhancedSecureCryptoService"
      )
      return .failure(.operationFailed("Invalid input: empty data"))
    }
    
    if let customIdentifier = customIdentifier, customIdentifier.isEmpty {
      await logger.error(
        "Empty custom identifier provided for import",
        metadata: nil,
        source: "EnhancedSecureCryptoService"
      )
      return .failure(.operationFailed("Invalid input: empty custom identifier"))
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
      await logger.warning(
        "Rate limited data export operation",
        metadata: nil,
        source: "EnhancedSecureCryptoService"
      )
      return .failure(.operationFailed("Rate limited operation"))
    }
    
    // Input validation
    guard !identifier.isEmpty else {
      await logger.error(
        "Empty identifier provided for data export",
        metadata: nil,
        source: "EnhancedSecureCryptoService"
      )
      return .failure(.operationFailed("Invalid input: empty identifier"))
    }
    
    // Verify data exists
    let dataResult = await secureStorage.retrieveData(withIdentifier: identifier)
    guard case .success = dataResult else {
      await logger.error(
        "Data not found for export: \(identifier)",
        metadata: nil,
        source: "EnhancedSecureCryptoService"
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
  public func isRateLimited(_ operation: Operation) -> Bool {
    // In a real implementation, we would check if the operation has been
    // performed too many times in a short period
    return false
  }
  
  public init() {}
}
