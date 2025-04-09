import CoreSecurityTypes
import CryptoLogger
import Foundation
import CryptoInterfaces
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
public actor EnhancedSecureCryptoServiceImpl: CryptoServiceProtocol {

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
    self.wrapped = wrapped
    self.logger = logger
    self.rateLimiter = rateLimiter
  }

  /**
   Creates a log context for a cryptographic operation.

   - Parameters:
     - operation: The type of operation (encrypt, decrypt, etc.)
     - identifier: Optional identifier for the data or key
     - status: Optional status of the operation
     - details: Optional additional details about the operation
   - Returns: A log context for the operation
   */
  private func createLogContext(
    operation: String,
    identifier: String? = nil,
    status: String? = nil,
    details: [String: String] = [:]
  ) -> CryptoLogContext {
    var metadata = LogMetadataDTOCollection()
    
    if let identifier = identifier {
      metadata = metadata.withPublic(key: "identifier", value: identifier)
    }
    
    // Add all details with appropriate privacy levels
    for (key, value) in details {
      if key.contains("key") || key.contains("password") || key.contains("secret") {
        metadata = metadata.withSensitive(key: key, value: value)
      } else if key.contains("hash") {
        metadata = metadata.withHashed(key: key, value: value)
      } else if key.contains("error") || key.contains("result") {
        metadata = metadata.withPublic(key: key, value: value)
      } else {
        metadata = metadata.withPrivate(key: key, value: value)
      }
    }
    
    return CryptoLogContext(
      operation: operation,
      identifier: identifier,
      status: status,
      metadata: metadata
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
    options: CoreSecurityTypes.EncryptionOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    // Check rate limiter
    if await rateLimiter.isRateLimited("encrypt") {
      let context = createLogContext(
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
      
      return .failure(.rateLimited)
    }
    
    // Input validation
    guard !dataIdentifier.isEmpty else {
      let context = createLogContext(
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
      
      return .failure(.invalidIdentifier)
    }
    
    guard !keyIdentifier.isEmpty else {
      let context = createLogContext(
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
      
      return .failure(.invalidIdentifier)
    }
    
    // Log the operation
    let startContext = createLogContext(
      operation: "encrypt",
      identifier: dataIdentifier,
      status: "started",
      details: [
        "keyIdentifier": keyIdentifier,
        "algorithm": options?.algorithm?.rawValue ?? "default"
      ]
    )
    
    await logger.debug(
      "Starting encryption operation",
      context: startContext
    )
    
    // Delegate to wrapped implementation
    let result = await wrapped.encrypt(
      dataIdentifier: dataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )
    
    // Log the result
    switch result {
      case .success(let encryptedIdentifier):
        let successContext = createLogContext(
          operation: "encrypt",
          identifier: dataIdentifier,
          status: "success",
          details: [
            "keyIdentifier": keyIdentifier,
            "encryptedIdentifier": encryptedIdentifier,
            "algorithm": options?.algorithm?.rawValue ?? "default"
          ]
        )
        
        await logger.info(
          "Encryption operation completed successfully",
          context: successContext
        )
        
      case .failure(let error):
        let errorContext = createLogContext(
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
    options: CoreSecurityTypes.EncryptionOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    // Check rate limiter
    if await rateLimiter.isRateLimited("decrypt") {
      let context = createLogContext(
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
      
      return .failure(.rateLimited)
    }
    
    // Input validation
    guard !encryptedDataIdentifier.isEmpty else {
      let context = createLogContext(
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
      
      return .failure(.invalidIdentifier)
    }
    
    guard !keyIdentifier.isEmpty else {
      let context = createLogContext(
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
      
      return .failure(.invalidIdentifier)
    }
    
    // Log the operation
    let startContext = createLogContext(
      operation: "decrypt",
      identifier: encryptedDataIdentifier,
      status: "started",
      details: [
        "keyIdentifier": keyIdentifier,
        "algorithm": options?.algorithm?.rawValue ?? "default"
      ]
    )
    
    await logger.debug(
      "Starting decryption operation",
      context: startContext
    )
    
    // Delegate to wrapped implementation
    let result = await wrapped.decrypt(
      encryptedDataIdentifier: encryptedDataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )
    
    // Log the result
    switch result {
      case .success(let decryptedIdentifier):
        let successContext = createLogContext(
          operation: "decrypt",
          identifier: encryptedDataIdentifier,
          status: "success",
          details: [
            "keyIdentifier": keyIdentifier,
            "decryptedIdentifier": decryptedIdentifier,
            "algorithm": options?.algorithm?.rawValue ?? "default"
          ]
        )
        
        await logger.info(
          "Decryption operation completed successfully",
          context: successContext
        )
        
      case .failure(let error):
        let errorContext = createLogContext(
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
    options: CoreSecurityTypes.HashingOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    // Check rate limiter
    if await rateLimiter.isRateLimited("hash") {
      let context = createLogContext(
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
      
      return .failure(.rateLimited)
    }
    
    // Input validation
    guard !dataIdentifier.isEmpty else {
      let context = createLogContext(
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
      
      return .failure(.invalidIdentifier)
    }
    
    // Log the operation
    let algorithm = options?.algorithm?.rawValue ?? "SHA256"
    let startContext = createLogContext(
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
    let result = await wrapped.hash(
      dataIdentifier: dataIdentifier,
      options: options
    )
    
    // Log the result
    switch result {
      case .success(let hashIdentifier):
        let successContext = createLogContext(
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
        
      case .failure(let error):
        let errorContext = createLogContext(
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
     - expectedHashIdentifier: Identifier for the expected hash
     - options: Optional hashing options
   - Returns: True if the hash matches, false otherwise, or an error
   */
  public func verifyHash(
    dataIdentifier: String,
    expectedHashIdentifier: String,
    options: CoreSecurityTypes.HashingOptions? = nil
  ) async -> Result<Bool, SecurityStorageError> {
    // Check rate limiter
    if await rateLimiter.isRateLimited("verify") {
      let context = createLogContext(
        operation: "verifyHash",
        identifier: dataIdentifier,
        status: "rate_limited",
        details: [
          "expectedHashIdentifier": expectedHashIdentifier,
          "reason": "Rate limit exceeded for hash verification operations"
        ]
      )
      
      await logger.warning(
        "Hash verification operation rate limited",
        context: context
      )
      
      return .failure(.rateLimited)
    }
    
    // Input validation
    guard !dataIdentifier.isEmpty else {
      let context = createLogContext(
        operation: "verifyHash",
        status: "validation_failed",
        details: [
          "expectedHashIdentifier": expectedHashIdentifier,
          "reason": "Empty data identifier"
        ]
      )
      
      await logger.error(
        "Hash verification failed: empty data identifier",
        context: context
      )
      
      return .failure(.invalidIdentifier)
    }
    
    guard !expectedHashIdentifier.isEmpty else {
      let context = createLogContext(
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
      
      return .failure(.invalidIdentifier)
    }
    
    // Log the operation
    let algorithm = options?.algorithm?.rawValue ?? "SHA256"
    let startContext = createLogContext(
      operation: "verifyHash",
      identifier: dataIdentifier,
      status: "started",
      details: [
        "expectedHashIdentifier": expectedHashIdentifier,
        "algorithm": algorithm
      ]
    )
    
    await logger.debug(
      "Starting hash verification using \(algorithm)",
      context: startContext
    )
    
    // Delegate to wrapped implementation
    let result = await wrapped.verifyHash(
      dataIdentifier: dataIdentifier,
      expectedHashIdentifier: expectedHashIdentifier,
      options: options
    )
    
    // Log the result
    switch result {
      case .success(let isValid):
        let successContext = createLogContext(
          operation: "verifyHash",
          identifier: dataIdentifier,
          status: "success",
          details: [
            "expectedHashIdentifier": expectedHashIdentifier,
            "isValid": isValid ? "true" : "false",
            "algorithm": algorithm
          ]
        )
        
        await logger.info(
          "Hash verification completed: \(isValid ? "valid" : "invalid")",
          context: successContext
        )
        
      case .failure(let error):
        let errorContext = createLogContext(
          operation: "verifyHash",
          identifier: dataIdentifier,
          status: "failed",
          details: [
            "expectedHashIdentifier": expectedHashIdentifier,
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

  // MARK: - Data Storage Operations

  /**
   Stores data securely.

   - Parameters:
     - data: The data to store
     - options: Optional storage options
   - Returns: Identifier for the stored data or an error
   */
  public func storeData(
    _ data: Data,
    options: CoreSecurityTypes.StorageOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    // Check rate limiter
    if await rateLimiter.isRateLimited("storeData") {
      let context = createLogContext(
        operation: "storeData",
        status: "rate_limited",
        details: [
          "dataSize": "\(data.count)",
          "reason": "Rate limit exceeded for data storage operations"
        ]
      )
      
      await logger.warning(
        "Data storage operation rate limited",
        context: context
      )
      
      return .failure(.rateLimited)
    }
    
    // Input validation
    guard !data.isEmpty else {
      let context = createLogContext(
        operation: "storeData",
        status: "validation_failed",
        details: [
          "reason": "Empty data"
        ]
      )
      
      await logger.error(
        "Data storage failed: empty data",
        context: context
      )
      
      return .failure(.invalidData)
    }
    
    // Log the operation
    let startContext = createLogContext(
      operation: "storeData",
      status: "started",
      details: [
        "dataSize": "\(data.count)",
        "storageType": options?.storageType?.rawValue ?? "default"
      ]
    )
    
    await logger.debug(
      "Starting data storage operation",
      context: startContext
    )
    
    // Delegate to wrapped implementation
    let result = await wrapped.storeData(data, options: options)
    
    // Log the result
    switch result {
      case .success(let dataIdentifier):
        let successContext = createLogContext(
          operation: "storeData",
          identifier: dataIdentifier,
          status: "success",
          details: [
            "dataSize": "\(data.count)",
            "storageType": options?.storageType?.rawValue ?? "default"
          ]
        )
        
        await logger.info(
          "Data storage operation completed successfully",
          context: successContext
        )
        
      case .failure(let error):
        let errorContext = createLogContext(
          operation: "storeData",
          status: "failed",
          details: [
            "dataSize": "\(data.count)",
            "errorDescription": error.localizedDescription,
            "errorCode": "\(error)",
            "storageType": options?.storageType?.rawValue ?? "default"
          ]
        )
        
        await logger.error(
          "Data storage operation failed: \(error.localizedDescription)",
          context: errorContext
        )
    }
    
    return result
  }

  /**
   Retrieves data securely.

   - Parameters:
     - dataIdentifier: Identifier for the data to retrieve
     - options: Optional retrieval options
   - Returns: The retrieved data or an error
   */
  public func retrieveData(
    _ dataIdentifier: String,
    options: CoreSecurityTypes.StorageOptions? = nil
  ) async -> Result<Data, SecurityStorageError> {
    // Check rate limiter
    if await rateLimiter.isRateLimited("retrieveData") {
      let context = createLogContext(
        operation: "retrieveData",
        identifier: dataIdentifier,
        status: "rate_limited",
        details: [
          "reason": "Rate limit exceeded for data retrieval operations"
        ]
      )
      
      await logger.warning(
        "Data retrieval operation rate limited",
        context: context
      )
      
      return .failure(.rateLimited)
    }
    
    // Input validation
    guard !dataIdentifier.isEmpty else {
      let context = createLogContext(
        operation: "retrieveData",
        status: "validation_failed",
        details: [
          "reason": "Empty data identifier"
        ]
      )
      
      await logger.error(
        "Data retrieval failed: empty data identifier",
        context: context
      )
      
      return .failure(.invalidIdentifier)
    }
    
    // Log the operation
    let startContext = createLogContext(
      operation: "retrieveData",
      identifier: dataIdentifier,
      status: "started",
      details: [
        "storageType": options?.storageType?.rawValue ?? "default"
      ]
    )
    
    await logger.debug(
      "Starting data retrieval operation",
      context: startContext
    )
    
    // Delegate to wrapped implementation
    let result = await wrapped.retrieveData(dataIdentifier, options: options)
    
    // Log the result
    switch result {
      case .success(let data):
        let successContext = createLogContext(
          operation: "retrieveData",
          identifier: dataIdentifier,
          status: "success",
          details: [
            "dataSize": "\(data.count)",
            "storageType": options?.storageType?.rawValue ?? "default"
          ]
        )
        
        await logger.info(
          "Data retrieval operation completed successfully",
          context: successContext
        )
        
      case .failure(let error):
        let errorContext = createLogContext(
          operation: "retrieveData",
          identifier: dataIdentifier,
          status: "failed",
          details: [
            "errorDescription": error.localizedDescription,
            "errorCode": "\(error)",
            "storageType": options?.storageType?.rawValue ?? "default"
          ]
        )
        
        await logger.error(
          "Data retrieval operation failed: \(error.localizedDescription)",
          context: errorContext
        )
    }
    
    return result
  }

  /**
   Deletes data securely.

   - Parameters:
     - dataIdentifier: Identifier for the data to delete
     - options: Optional deletion options
   - Returns: Success or an error
   */
  public func deleteData(
    _ dataIdentifier: String,
    options: CoreSecurityTypes.StorageOptions? = nil
  ) async -> Result<Void, SecurityStorageError> {
    // Check rate limiter
    if await rateLimiter.isRateLimited("deleteData") {
      let context = createLogContext(
        operation: "deleteData",
        identifier: dataIdentifier,
        status: "rate_limited",
        details: [
          "reason": "Rate limit exceeded for data deletion operations"
        ]
      )
      
      await logger.warning(
        "Data deletion operation rate limited",
        context: context
      )
      
      return .failure(.rateLimited)
    }
    
    // Input validation
    guard !dataIdentifier.isEmpty else {
      let context = createLogContext(
        operation: "deleteData",
        status: "validation_failed",
        details: [
          "reason": "Empty data identifier"
        ]
      )
      
      await logger.error(
        "Data deletion failed: empty data identifier",
        context: context
      )
      
      return .failure(.invalidIdentifier)
    }
    
    // Log the operation
    let startContext = createLogContext(
      operation: "deleteData",
      identifier: dataIdentifier,
      status: "started",
      details: [
        "storageType": options?.storageType?.rawValue ?? "default"
      ]
    )
    
    await logger.debug(
      "Starting data deletion operation",
      context: startContext
    )
    
    // Delegate to wrapped implementation
    let result = await wrapped.deleteData(dataIdentifier, options: options)
    
    // Log the result
    switch result {
      case .success:
        let successContext = createLogContext(
          operation: "deleteData",
          identifier: dataIdentifier,
          status: "success",
          details: [
            "storageType": options?.storageType?.rawValue ?? "default"
          ]
        )
        
        await logger.info(
          "Data deletion operation completed successfully",
          context: successContext
        )
        
      case .failure(let error):
        let errorContext = createLogContext(
          operation: "deleteData",
          identifier: dataIdentifier,
          status: "failed",
          details: [
            "errorDescription": error.localizedDescription,
            "errorCode": "\(error)",
            "storageType": options?.storageType?.rawValue ?? "default"
          ]
        )
        
        await logger.error(
          "Data deletion operation failed: \(error.localizedDescription)",
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
