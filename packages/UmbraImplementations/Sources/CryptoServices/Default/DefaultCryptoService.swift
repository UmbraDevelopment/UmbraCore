import CoreSecurityTypes
import CryptoInterfaces
import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import BuildConfig

/**
 A default implementation of CryptoServiceProtocol that provides basic 
 cryptographic operations.
 
 This implementation is intended as a minimal starting point and reference 
 implementation. For production use, consider using one of the more comprehensive
 implementations with enhanced security features.
 
 Note: This implementation may not provide all security features mentioned
 in the protocol definition.
 */
public actor DefaultCryptoService: CryptoServiceProtocol {
  /// The secure storage to use
  public let secureStorage: SecureStorageProtocol
  
  /// The logger to use
  private let logger: LoggingProtocol?
  
  /**
   Creates a new default crypto service.
   
   - Parameters:
     - secureStorage: The secure storage implementation to use
     - logger: Optional logger for recording operations
   */
  public init(secureStorage: SecureStorageProtocol, logger: LoggingProtocol? = nil) {
    self.secureStorage = secureStorage
    self.logger = logger
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
    let logContext = createLogContext(
      operation: "encrypt",
      operationID: operationID,
      dataIdentifier: dataIdentifier,
      keyIdentifier: keyIdentifier
    )
    
    await logDebug("Starting encryption operation", context: logContext)
    
    // First retrieve the data to encrypt
    let dataResult = await secureStorage.retrieveData(withIdentifier: dataIdentifier)
    
    switch dataResult {
      case let .success(data):
        // Create and execute the encrypt command with the data
        let command = EncryptDataCommand(
          data: data,
          keyIdentifier: keyIdentifier,
          algorithm: options?.algorithm ?? .aes256CBC,
          secureStorage: secureStorage,
          logger: logger
        )
        
        return await command.execute(context: logContext, operationID: operationID)
        
      case let .failure(error):
        await logError("Failed to retrieve data for encryption", context: logContext)
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
    let logContext = createLogContext(
      operation: "decrypt",
      operationID: operationID,
      dataIdentifier: encryptedDataIdentifier,
      keyIdentifier: keyIdentifier
    )
    
    await logDebug("Starting decryption operation", context: logContext)
    
    // Extract the encrypted data
    let dataResult = await secureStorage.retrieveData(withIdentifier: encryptedDataIdentifier)
    
    switch dataResult {
      case let .success(encryptedData):
        // Decrypt the data
        let decryptCommand = DecryptDataCommand(
          data: encryptedData,
          keyIdentifier: keyIdentifier,
          algorithm: options?.algorithm ?? .aes256CBC,
          secureStorage: secureStorage,
          logger: logger
        )
        
        let decryptResult = await decryptCommand.execute(context: logContext, operationID: operationID)
        
        switch decryptResult {
          case let .success(decryptedDataId):
            await logInfo("Decryption successful", context: logContext)
            return .success(decryptedDataId)
            
          case let .failure(error):
            await logError("Decryption failed", context: logContext)
            return .failure(error)
        }
        
      case let .failure(error):
        await logError("Failed to retrieve encrypted data", context: logContext)
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
    let logContext = createLogContext(
      operation: "hash",
      operationID: operationID,
      dataIdentifier: dataIdentifier
    )
    
    await logDebug("Starting hash operation", context: logContext)
    
    // First retrieve the data to hash
    let dataResult = await secureStorage.retrieveData(withIdentifier: dataIdentifier)
    
    switch dataResult {
      case let .success(data):
        // Create and execute the hash command with the data
        let command = HashDataCommand(
          data: data,
          algorithm: options?.algorithm ?? .sha256,
          salt: nil, // HashingOptions doesn't have salt, so we pass nil
          secureStorage: secureStorage,
          logger: logger
        )
        
        return await command.execute(context: logContext, operationID: operationID)
        
      case let .failure(error):
        await logError("Failed to retrieve data for hashing", context: logContext)
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
    let logContext = createLogContext(
      operation: "verifyHash",
      operationID: operationID,
      dataIdentifier: dataIdentifier
    )
    
    await logDebug("Starting hash verification operation", context: logContext)
    
    // Compute the hash of the data
    let hashResult = await hash(dataIdentifier: dataIdentifier, options: options)
    
    switch hashResult {
      case let .success(computedHashIdentifier):
        // Retrieve both hashes
        let expectedHashResult = await secureStorage.retrieveData(withIdentifier: hashIdentifier)
        let computedHashResult = await secureStorage.retrieveData(withIdentifier: computedHashIdentifier)
        
        switch (expectedHashResult, computedHashResult) {
          case let (.success(expectedHash), .success(computedHash)):
            // Compare the hashes
            let match = expectedHash == computedHash
            await logInfo("Hash verification \(match ? "matched" : "failed")", context: logContext)
            return .success(match)
            
          case (.failure(let error), _):
            await logError("Failed to retrieve expected hash", context: logContext)
            return .failure(error)
            
          case (_, .failure(let error)):
            await logError("Failed to retrieve computed hash", context: logContext)
            return .failure(error)
        }
        
      case let .failure(error):
        await logError("Failed to compute hash", context: logContext)
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
    let logContext = createLogContext(
      operation: "generateKey",
      operationID: operationID
    )
    
    await logDebug("Starting key generation operation", context: logContext)
    
    let command = GenerateKeyCommand(
      keyType: options?.keyType ?? .aes,
      size: length / 8, // Convert from bits to bytes
      secureStorage: secureStorage,
      logger: logger
    )
    
    let result = await command.execute(context: logContext, operationID: operationID)
    
    switch result {
      case let .success(key):
        return .success(key.id)
      case let .failure(error):
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
    let operationID = UUID().uuidString
    let logContext = createLogContext(
      operation: "importData",
      operationID: operationID
    )
    
    await logDebug("Starting data import operation", context: logContext)
    
    // Just use the secure storage directly for this operation
    let identifier = customIdentifier ?? UUID().uuidString
    let storeResult = await secureStorage.storeData(data, withIdentifier: identifier)
    
    switch storeResult {
      case .success:
        await logInfo("Data imported successfully", context: logContext)
        return .success(identifier)
      case let .failure(error):
        await logError("Failed to import data", context: logContext)
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
    // Convert Data to [UInt8] and use the other implementation
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
    let operationID = UUID().uuidString
    let logContext = createLogContext(
      operation: "exportData",
      operationID: operationID,
      dataIdentifier: identifier
    )
    
    await logDebug("Starting data export operation", context: logContext)
    
    // Directly use secure storage for this operation
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
   Creates a log context for cryptographic operations.
   
   - Parameters:
     - operation: The operation being performed
     - operationID: Correlation ID for the operation
     - dataIdentifier: Optional data identifier for context
     - keyIdentifier: Optional key identifier for context
   - Returns: A log context for the operation
   */
  private func createLogContext(
    operation: String,
    operationID: String,
    dataIdentifier: String? = nil,
    keyIdentifier: String? = nil
  ) -> LogContextDTO {
    var metadata = LogMetadataDTOCollection()
    metadata = metadata.withPublic(key: "operationID", value: operationID)
    
    if let dataIdentifier = dataIdentifier {
      metadata = metadata.withPublic(key: "dataIdentifier", value: dataIdentifier)
    }
    
    if let keyIdentifier = keyIdentifier {
      metadata = metadata.withPrivate(key: "keyIdentifier", value: keyIdentifier)
    }
    
    return EnhancedLogContext(
      domainName: "CryptoServices",
      operationName: operation,
      source: "DefaultCryptoService",
      correlationID: operationID,
      category: "Security",
      metadata: metadata
    )
  }
  
  /**
   Logs a debug message.
   
   - Parameters:
     - message: The message to log
     - context: Context for the log
   */
  private func logDebug(_ message: String, context: LogContextDTO) async {
    await logger?.log(.debug, message, context: context)
  }
  
  /**
   Logs an info message.
   
   - Parameters:
     - message: The message to log
     - context: Context for the log
   */
  private func logInfo(_ message: String, context: LogContextDTO) async {
    await logger?.log(.info, message, context: context)
  }
  
  /**
   Logs an error message.
   
   - Parameters:
     - message: The message to log
     - context: Context for the log
   */
  private func logError(_ message: String, context: LogContextDTO) async {
    await logger?.log(.error, message, context: context)
  }
}

// MARK: - Extensions

extension Data {
  /// Convert Data to [UInt8]
  var bytes: [UInt8] {
    return [UInt8](self)
  }
}

// Custom extensions can be enabled via the ENABLE_DEFAULT_CRYPTO_EXTENSIONS flag
#if ENABLE_DEFAULT_CRYPTO_EXTENSIONS
extension DefaultCryptoService {
  // Add custom extensions here
}
#endif
