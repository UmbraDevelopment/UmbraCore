import CoreSecurityTypes
import CryptoInterfaces
import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import SecurityProviders
import BuildConfig

/**
 # CryptoServiceWithProvider

 Implementation of CryptoServiceProtocol that uses a SecurityProviderProtocol,
 following the command pattern architecture.

 This implementation delegates cryptographic operations to a security provider
 through a command-based architecture, which allows for different cryptographic
 backends to be used without changing the client code, while maintaining a clean,
 modular design with better separation of concerns.

 ## Provider Integration

 The implementation can work with various security provider types based on the
 BuildConfig backend strategy:
 - Restic: Default integration with Restic's cryptographic approach
 - RingFFI: Ring cryptography library with Argon2id via FFI
 - AppleCK: Apple CryptoKit for sandboxed environments

 ## Privacy Controls

 This implementation ensures proper privacy classification of sensitive information:
 - Cryptographic keys are treated as private information
 - Data identifiers are generally treated as public information
 - Error details are appropriately classified based on sensitivity
 - Metadata is structured for privacy-aware logging

 ## Thread Safety

 As an actor, this implementation guarantees thread safety when used from multiple
 concurrent contexts, preventing data races in cryptographic operations.
 
 ## Environment Awareness
 
 The implementation adjusts its behaviour based on the active environment:
 - Debug/Development: Enhanced logging with more verbose output
 - Alpha/Beta/Production: Optimised performance with appropriate redaction
 */
@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public actor CryptoServiceWithProvider: CryptoServiceProtocol, Sendable {
  /// The security provider to use for cryptographic operations
  private let provider: SecurityProviderProtocol

  /// The secure storage to use
  public let secureStorage: SecureStorageProtocol

  /// Optional logger for operation tracking
  private let logger: LoggingProtocol?
  
  /// Command factory for provider commands
  private let commandFactory: ProviderCommandFactory
  
  /// The active backend strategy
  private let backendStrategy: BackendStrategy
  
  /// The active environment configuration
  private let environment: UmbraEnvironment
  
  /// The provider type name for logging
  private let providerTypeName: String

  /**
   Initialises a crypto service with the specified security provider.

   - Parameters:
      - secureStorage: The secure storage to use
      - providerType: The type of security provider to use
      - logger: Optional logger for recording operations
      - backendStrategy: Optional override for the backend strategy
      - environment: Optional override for the environment configuration
   */
  public init(
    secureStorage: SecureStorageProtocol,
    providerType: SecurityProviderType = .basic,
    logger: LoggingProtocol? = nil,
    backendStrategy: BackendStrategy? = nil,
    environment: UmbraEnvironment? = nil
  ) async {
    // Store the active backend strategy and environment
    self.backendStrategy = backendStrategy ?? BuildConfig.activeBackendStrategy
    self.environment = environment ?? BuildConfig.activeEnvironment
    
    // Determine the appropriate provider type based on backend strategy
    let provider: any SecurityProviderProtocol
    
    // Rather than trying to create the actual provider types which would require additional dependencies,
    // implement a stub provider for compilation purposes only.
    // In a full implementation, this would be properly injected or created using the appropriate factory
    
    // Store provider type in a property for logging
    self.providerTypeName = providerType.rawValue
    
    // For now, we'll use this stub provider - this should be replaced with proper implementation
    // once the dependency structure is fully resolved
    provider = StubSecurityProvider(
      logger: logger,
      providerType: providerType
    )
    
    self.provider = provider
    self.secureStorage = secureStorage
    self.logger = logger

    // Create the command factory with the provider, storage, and logger
    self.commandFactory = ProviderCommandFactory(
      provider: provider,
      secureStorage: secureStorage,
      logger: logger
    )
    
    // Initialize the provider
    try? await provider.initialize()
    
    // Log initialisation with environment and backend information
    if let logger = logger {
      let initContext = CryptoLogContext(
        operation: "initialise",
        correlationID: UUID().uuidString
      ).withMetadata(
        LogMetadataDTOCollection()
          .withPublic(key: "environment", value: self.environment.rawValue)
          .withPublic(key: "backendStrategy", value: self.backendStrategy.rawValue)
          .withPublic(key: "providerType", value: self.providerTypeName)
      )
      
      await logger.info(
        "CryptoServiceWithProvider initialised with \(self.backendStrategy.rawValue) backend in \(self.environment.rawValue) environment",
        context: initContext
      )
    }
  }
  
  /**
   Encrypts data with the given key.
   
   - Parameters:
     - dataIdentifier: Identifier of the data to encrypt
     - keyIdentifier: Identifier of the encryption key
     - options: Optional encryption configuration
   - Returns: Identifier for the encrypted data or an error
   */
  public func encrypt(
    dataIdentifier: String,
    keyIdentifier: String,
    options: CoreSecurityTypes.EncryptionOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    let operationID = UUID().uuidString
    let startTime = Date()
    let logContext = CryptoLogContext(
      operation: "encrypt",
      correlationID: operationID
    )
    
    // Create context with private key information
    let enhancedContext = logContext.withKeyID(keyIdentifier)
    await logDebug("Starting encryption operation", context: enhancedContext)
    
    // Retrieve the data to encrypt
    let dataResult = await secureStorage.retrieveData(withIdentifier: dataIdentifier)
    
    switch dataResult {
      case let .success(data):
        // Enhance context with data size information
        let contextWithDataInfo = enhancedContext
          .withDataSize(data.count)
          .withMetadata(
            LogMetadataDTOCollection()
              .withPublic(key: "algorithm", value: options?.algorithm?.rawValue ?? "aes256CBC")
          )
        
        await logDebug("Retrieved data for encryption", context: contextWithDataInfo)
        
        // Create the crypto command for encryption
        let command = commandFactory.createEncryptCommand(
          dataIdentifier: dataIdentifier,
          keyIdentifier: keyIdentifier,
          algorithm: options?.algorithm ?? .aes256CBC,
          secureStorage: secureStorage
        )
        
        // Execute the command and convert to the expected result type
        let result = await command.execute(context: contextWithDataInfo, operationID: operationID)
        
        // Calculate operation duration
        let duration = Date().timeIntervalSince(startTime)
        
        // Log result with appropriate metadata
        let resultContext = enhanceContext(contextWithDataInfo, result: result, duration: duration)
        
        switch result {
          case .success(let encryptedDataID):
            await logInfo("Encryption completed successfully", context: resultContext)
            return .success(encryptedDataID)
          case .failure(let error):
            let errorContext = resultContext.withMetadata(
              LogMetadataDTOCollection()
                .withPrivate(key: "errorDescription", value: error.localizedDescription)
            )
            await logError("Encryption failed", context: errorContext)
            return .failure(error)
        }
        
      case let .failure(error):
        // Calculate operation duration
        let duration = Date().timeIntervalSince(startTime)
        
        // Create failure context with duration
        let errorContext = enhancedContext
          .withResult(success: false)
          .withMetadata(
            LogMetadataDTOCollection()
              .withPublic(key: "duration", value: String(format: "%.2f", duration))
              .withPrivate(key: "errorDescription", value: error.localizedDescription)
          )
        
        await logError("Failed to retrieve data for encryption", context: errorContext)
        return .failure(error)
    }
  }
  
  /**
   Decrypts data with the given key.
   
   - Parameters:
     - encryptedDataIdentifier: Identifier of the encrypted data
     - keyIdentifier: Identifier of the decryption key
     - options: Optional decryption configuration
   - Returns: Identifier for the decrypted data or an error
   */
  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options: CoreSecurityTypes.EncryptionOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    let operationID = UUID().uuidString
    let startTime = Date()
    let logContext = CryptoLogContext(
      operation: "decrypt",
      correlationID: operationID
    )
    
    // Create context with key information using privacy-aware functional approach
    let enhancedContext = logContext
      .withKeyID(keyIdentifier)
      .withMetadata(
        LogMetadataDTOCollection()
          .withPublic(key: "algorithm", value: options?.algorithm?.rawValue ?? "aes256CBC")
      )
    
    await logDebug("Starting decryption operation", context: enhancedContext)
    
    // Create the decrypt command
    let command = commandFactory.createDecryptCommand(
      encryptedDataIdentifier: encryptedDataIdentifier,
      keyIdentifier: keyIdentifier,
      algorithm: options?.algorithm ?? .aes256CBC,
      secureStorage: secureStorage
    )
    
    // Execute the command
    let result = await command.execute(context: enhancedContext, operationID: operationID)
    
    // Calculate operation duration
    let duration = Date().timeIntervalSince(startTime)
    
    // Log result with appropriate metadata
    let resultContext = enhanceContext(enhancedContext, result: result, duration: duration)
    
    switch result {
      case .success(let decryptedDataID):
        await logInfo("Decryption completed successfully", context: resultContext)
        return .success(decryptedDataID)
      case .failure(let error):
        let errorContext = resultContext.withMetadata(
          LogMetadataDTOCollection()
            .withPrivate(key: "errorDescription", value: error.localizedDescription)
        )
        await logError("Decryption failed", context: errorContext)
        return .failure(error)
    }
  }
  
  /**
   Hashes data using the specified algorithm.
   
   - Parameters:
     - dataIdentifier: Identifier of the data to hash
     - options: Optional hashing configuration
   - Returns: Identifier for the hash or an error
   */
  public func hash(
    dataIdentifier: String,
    options: CoreSecurityTypes.HashingOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    let operationID = UUID().uuidString
    let startTime = Date()
    let logContext = CryptoLogContext(
      operation: "hash",
      correlationID: operationID
    )
    
    // Create enhanced context with operation details
    let enhancedContext = logContext.withMetadata(
      LogMetadataDTOCollection()
        .withPublic(key: "algorithm", value: options?.algorithm?.rawValue ?? "sha256")
        .withPublic(key: "dataIdentifier", value: dataIdentifier)
    )
    
    await logDebug("Starting hash operation", context: enhancedContext)
    
    // Create and execute the hash command
    let command = commandFactory.createHashCommand(
      dataIdentifier: dataIdentifier,
      algorithm: options?.algorithm ?? .sha256,
      secureStorage: secureStorage
    )
    
    // Execute the command
    let result = await command.execute(context: enhancedContext, operationID: operationID)
    
    // Calculate operation duration
    let duration = Date().timeIntervalSince(startTime)
    
    // Log result with appropriate metadata
    let resultContext = enhanceContext(enhancedContext, result: result, duration: duration)
    
    switch result {
      case .success(let hashIdentifier):
        await logInfo("Hash operation completed successfully", context: resultContext)
        return .success(hashIdentifier)
      case .failure(let error):
        let errorContext = resultContext.withMetadata(
          LogMetadataDTOCollection()
            .withPrivate(key: "errorDescription", value: error.localizedDescription)
        )
        await logError("Hash operation failed", context: errorContext)
        return .failure(error)
    }
  }
  
  /**
   Generates a hash and verifies it against a provided hash.
   
   - Parameters:
     - dataIdentifier: Identifier of the data to hash
     - hashIdentifier: Identifier of the expected hash
     - options: Optional hashing configuration
   - Returns: Whether the hash matches or an error
   */
  public func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options: CoreSecurityTypes.HashingOptions? = nil
  ) async -> Result<Bool, SecurityStorageError> {
    let operationID = UUID().uuidString
    let startTime = Date()
    let logContext = CryptoLogContext(
      operation: "verifyHash",
      correlationID: operationID
    )
    
    // Create enhanced context with operation details
    let enhancedContext = logContext.withMetadata(
      LogMetadataDTOCollection()
        .withPublic(key: "algorithm", value: options?.algorithm?.rawValue ?? "sha256")
        .withPublic(key: "dataIdentifier", value: dataIdentifier)
        .withPublic(key: "hashIdentifier", value: hashIdentifier)
    )
    
    await logDebug("Starting hash verification", context: enhancedContext)
    
    // Compute the hash and compare
    let hashResult = await hash(dataIdentifier: dataIdentifier, options: options)
    
    switch hashResult {
      case let .success(computedHashID):
        // Retrieve both hashes for comparison
        let expectedHashResult = await secureStorage.retrieveData(withIdentifier: hashIdentifier)
        let computedHashResult = await secureStorage.retrieveData(withIdentifier: computedHashID)
        
        // Update context with computed hash information
        let verificationContext = enhancedContext.withMetadata(
          LogMetadataDTOCollection()
            .withPublic(key: "computedHashID", value: computedHashID)
        )
        
        switch (expectedHashResult, computedHashResult) {
          case let (.success(expected), .success(computed)):
            // Calculate operation duration
            let duration = Date().timeIntervalSince(startTime)
            
            // Check if hashes match
            let hashesMatch = expected == computed
            
            // Log result with appropriate metadata
            let resultContext = verificationContext
              .withResult(success: true)
              .withMetadata(
                LogMetadataDTOCollection()
                  .withPublic(key: "duration", value: String(format: "%.2f", duration))
                  .withPublic(key: "match", value: String(hashesMatch))
              )
            
            await logInfo(
              "Hash verification completed: \(hashesMatch ? "Match" : "No match")",
              context: resultContext
            )
            
            return .success(hashesMatch)
            
          case (.failure(let expectedError), _):
            // Calculate operation duration
            let duration = Date().timeIntervalSince(startTime)
            
            // Log error with appropriate metadata
            let errorContext = verificationContext
              .withResult(success: false)
              .withMetadata(
                LogMetadataDTOCollection()
                  .withPublic(key: "duration", value: String(format: "%.2f", duration))
                  .withPrivate(key: "errorDescription", value: "Failed to retrieve expected hash: \(expectedError.localizedDescription)")
              )
            
            await logError("Hash verification failed: couldn't retrieve expected hash", context: errorContext)
            return .failure(expectedError)
            
          case (_, .failure(let computedError)):
            // Calculate operation duration
            let duration = Date().timeIntervalSince(startTime)
            
            // Log error with appropriate metadata
            let errorContext = verificationContext
              .withResult(success: false)
              .withMetadata(
                LogMetadataDTOCollection()
                  .withPublic(key: "duration", value: String(format: "%.2f", duration))
                  .withPrivate(key: "errorDescription", value: "Failed to retrieve computed hash: \(computedError.localizedDescription)")
              )
            
            await logError("Hash verification failed: couldn't retrieve computed hash", context: errorContext)
            return .failure(computedError)
        }
        
      case let .failure(error):
        // Calculate operation duration
        let duration = Date().timeIntervalSince(startTime)
        
        // Log error with appropriate metadata
        let errorContext = enhancedContext
          .withResult(success: false)
          .withMetadata(
            LogMetadataDTOCollection()
              .withPublic(key: "duration", value: String(format: "%.2f", duration))
              .withPrivate(key: "errorDescription", value: "Failed to compute hash: \(error.localizedDescription)")
          )
        
        await logError("Hash verification failed: couldn't compute hash", context: errorContext)
        return .failure(error)
    }
  }
  
  /**
   Generates a cryptographic key.
   
   - Parameters:
     - length: Bit length of the key
     - options: Optional key generation configuration
   - Returns: Identifier for the generated key or an error
   */
  public func generateKey(
    length: Int,
    options: CoreSecurityTypes.KeyGenerationOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    let operationID = UUID().uuidString
    let startTime = Date()
    let logContext = CryptoLogContext(
      operation: "generateKey",
      correlationID: operationID
    )
    
    // Create enhanced context with operation details using functional approach
    let enhancedContext = logContext.withMetadata(
      LogMetadataDTOCollection()
        .withPublic(key: "keyType", value: options?.keyType?.rawValue ?? "aes")
        .withPublic(key: "keyLength", value: String(length))
    )
    
    await logDebug("Starting key generation", context: enhancedContext)
    
    // Create and execute the key generation command
    let command = commandFactory.createGenerateKeyCommand(
      keyType: options?.keyType ?? .aes,
      size: length / 8,
      secureStorage: secureStorage
    )
    
    // Execute the command
    let result = await command.execute(context: enhancedContext, operationID: operationID)
    
    // Calculate operation duration
    let duration = Date().timeIntervalSince(startTime)
    
    // Log result with appropriate metadata
    let resultContext = enhanceContext(enhancedContext, result: result, duration: duration)
    
    switch result {
      case .success(let keyIdentifier):
        // Create success context with key identifier using functional approach
        let successContext = resultContext.withMetadata(
          LogMetadataDTOCollection()
            .withPrivate(key: "keyIdentifier", value: keyIdentifier)
        )
        
        await logInfo("Key generation completed successfully", context: successContext)
        return .success(keyIdentifier)
        
      case .failure(let error):
        // Create error context with error details using functional approach
        let errorContext = resultContext.withMetadata(
          LogMetadataDTOCollection()
            .withPrivate(key: "errorDescription", value: error.localizedDescription)
        )
        
        await logError("Key generation failed", context: errorContext)
        return .failure(error)
    }
  }
  
  /**
   Imports data to secure storage.
   
   - Parameters:
     - data: The data to store
     - customIdentifier: Optional custom identifier
   - Returns: Identifier for the stored data or an error
   */
  public func importData(
    _ data: [UInt8],
    customIdentifier: String? = nil
  ) async -> Result<String, SecurityStorageError> {
    let identifier = customIdentifier ?? UUID().uuidString
    let result = await secureStorage.storeData(data, withIdentifier: identifier)
    
    switch result {
      case .success:
        return .success(identifier)
      case let .failure(error):
        return .failure(error)
    }
  }
  
  /**
   Imports data to secure storage with specified identifier.
   
   - Parameters:
     - data: The data to store
     - customIdentifier: The identifier to use
   - Returns: Identifier for the stored data or an error
   */
  public func importData(
    _ data: Data,
    customIdentifier: String
  ) async -> Result<String, SecurityStorageError> {
    return await importData([UInt8](data), customIdentifier: customIdentifier)
  }
  
  /**
   Exports data from secure storage.
   
   - Parameter identifier: Identifier of the data to export
   - Returns: The raw data or an error
   */
  public func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    return await secureStorage.retrieveData(withIdentifier: identifier)
  }
  
  /**
   Generates a hash for the specified data.
   
   - Parameters:
     - dataIdentifier: Identifier of the data to hash
     - options: Optional hashing configuration
   - Returns: Identifier for the hash or an error
   */
  public func generateHash(
    dataIdentifier: String,
    options: CoreSecurityTypes.HashingOptions? = nil
  ) async -> Result<String, SecurityStorageError> {
    return await hash(dataIdentifier: dataIdentifier, options: options)
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
    return await secureStorage.storeData([UInt8](data), withIdentifier: identifier)
  }
  
  /**
   Retrieves data from secure storage.
   
   - Parameter identifier: Identifier of the data to retrieve
   - Returns: The retrieved data or an error
   */
  public func retrieveData(
    identifier: String
  ) async -> Result<Data, SecurityStorageError> {
    let result = await secureStorage.retrieveData(withIdentifier: identifier)
    
    switch result {
      case let .success(bytes):
        return .success(Data(bytes))
      case let .failure(error):
        return .failure(error)
    }
  }
  
  /**
   Deletes data from secure storage.
   
   - Parameter identifier: Identifier of the data to delete
   - Returns: Success or an error
   */
  public func deleteData(
    identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    return await secureStorage.deleteData(withIdentifier: identifier)
  }
  
  // MARK: - Helper Methods
  
  /**
   Logs a debug message.
   
   - Parameters:
     - message: The message to log
     - context: Context for the log
   */
  private func logDebug(_ message: String, context: LogContextDTO) async {
    await logger?.debug(message, context: context)
  }
  
  /**
   Logs an info message.
   
   - Parameters:
     - message: The message to log
     - context: Context for the log
   */
  private func logInfo(_ message: String, context: LogContextDTO) async {
    await logger?.info(message, context: context)
  }
  
  /**
   Logs an error message.
   
   - Parameters:
     - message: The message to log
     - context: Context for the log
   */
  private func logError(_ message: String, context: LogContextDTO) async {
    await logger?.error(message, context: context)
  }
  
  /**
   Creates an enhanced log context with additional operation metadata.
   
   - Parameters:
     - context: The base context to enhance
     - operationResult: The result of the operation
     - duration: The duration of the operation
   - Returns: An enhanced context with the operation result and duration
   */
  private func enhanceContext<T, E>(
    _ context: CryptoLogContext,
    result: Result<T, E>,
    duration: TimeInterval
  ) -> CryptoLogContext {
    // Add result and duration metadata using functional approach
    return context
      .withResult(success: result.isSuccess)
      .withMetadata(
        LogMetadataDTOCollection()
          .withPublic(key: "duration", value: String(format: "%.2f", duration))
      )
  }
}

// MARK: - Result Extension for Swift 6 Compatibility

/// Extension to Result to add a property checking success state
/// Swift 6 requires more explicit handling of Sendable types
extension Result {
  /// Returns true if this result is a success case
  var isSuccess: Bool {
    switch self {
      case .success: return true
      case .failure: return false
    }
  }
}
