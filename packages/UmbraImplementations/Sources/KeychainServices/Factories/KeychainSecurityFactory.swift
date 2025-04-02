import CoreSecurityTypes
import Foundation
import KeychainInterfaces
import LoggingInterfaces
import LoggingServices
import SecurityCoreInterfaces
import UmbraErrors
import SecurityProviders
import KeychainServices.Fallbacks

/**
 # KeychainSecurityFactory

 Factory for creating instances of KeychainSecurityActor with appropriate dependencies.

 This factory follows the Alpha Dot Five architecture pattern, providing
 standardised methods for creating actors with proper dependency injection.

 ## Usage Example

 ```swift
 // Create a keychain security actor with default settings
 let securityActor = await KeychainSecurityFactory.createActor()

 // Create with custom configurations
 let customActor = await KeychainSecurityFactory.createActor(
     keychainServiceIdentifier: "com.example.customApp"
 )
 ```
 */
public enum KeychainSecurityFactory {
  /// Default service identifier for keychain entries
  public static let defaultServiceIdentifier="com.umbra.keychain"

  /**
   Creates a KeychainSecurityActor with default implementations of all dependencies.

   - Parameters:
      - keychainServiceIdentifier: Optional custom service identifier for the keychain
      - logger: Optional custom logger

   - Returns: A properly configured KeychainSecurityActor
   */
  public static func createActor(
    keychainServiceIdentifier: String=defaultServiceIdentifier,
    logger: LoggingServiceProtocol?=nil
  ) async -> KeychainSecurityActor {
    // Get the default keychain service
    let keychainService=await KeychainServiceFactory.createService(
      serviceIdentifier: keychainServiceIdentifier,
      logger: logger
    )

    // Create a security provider
    let securityProvider = await createSecurityProvider(logger: logger)

    // Create an adapter for the logger
    let loggerToUse: LoggingProtocol
    if let logger = logger {
      loggerToUse = LoggingAdapter(wrapping: logger)
    } else {
      loggerToUse = SimpleLogger()
    }

    // Create and return the actor
    return await KeychainSecurityActor(
      keychainService: keychainService,
      securityProvider: securityProvider,
      logger: loggerToUse
    )
  }

  /**
   Creates a KeychainSecurityActor with custom dependencies.

   - Parameters:
      - keychainService: Custom keychain service
      - securityProvider: Custom security provider
      - logger: Optional custom logger

   - Returns: A properly configured KeychainSecurityActor
   */
  public static func createActor(
    keychainService: KeychainServiceProtocol,
    securityProvider: SecurityProviderProtocol,
    logger: LoggingProtocol?=nil
  ) async -> KeychainSecurityActor {
    return await KeychainSecurityActor(
      keychainService: keychainService,
      securityProvider: securityProvider,
      logger: logger
    )
  }
  
  /**
   Creates a basic security provider implementation suitable for development and testing.
   
   - Parameter logger: Optional logger to use with the provider
   - Returns: A security provider implementation
   */
  private static func createSecurityProvider(
    logger: LoggingServiceProtocol?
  ) async -> SecurityProviderProtocol {
    // Use a proper type-safe approach to handle the optional logger
    let loggerToUse: LoggingProtocol
    if let logger = logger {
      loggerToUse = LoggingAdapter(wrapping: logger)
    } else {
      loggerToUse = SimpleLogger()
    }
    
    // Create services for the security provider
    let cryptoService = BasicCryptoService(logger: loggerToUse)
    let keyManager = BasicKeyManager(logger: loggerToUse)
    
    // Create and return the actor-based security provider
    return SecurityProviderImpl(
      cryptoService: cryptoService,
      keyManager: keyManager
    )
  }
  
  /**
   Creates an in-memory keychain security actor for testing.

   - Parameters:
      - logger: Optional custom logger

   - Returns: A keychain security actor using an in-memory keychain service
   */
  public static func createInMemoryActor(
    logger: LoggingServiceProtocol?=nil
  ) async -> KeychainSecurityActor {
    // Create a basic in-memory keychain service
    let keychainService=await KeychainServiceFactory.createInMemoryService(
      logger: logger
    )

    // Create a security provider
    let securityProvider = await createSecurityProvider(logger: logger)

    // Create an adapter for the logger
    let loggerToUse: LoggingProtocol
    if let logger = logger {
      loggerToUse = LoggingAdapter(wrapping: logger)
    } else {
      loggerToUse = SimpleLogger()
    }

    // Create and return the actor
    return await KeychainSecurityActor(
      keychainService: keychainService,
      securityProvider: securityProvider,
      logger: loggerToUse
    )
  }
}

// MARK: - Security Provider Extensions

extension SecurityProviderProtocol {
  public func keyManager() async -> any KeyManagementProtocol {
    // Use the BasicKeyManager from the Fallbacks directory
    return BasicKeyManager()
  }
}

// MARK: - BasicSecurityProvider Implementation

/**
 Basic security provider implementation for testing and development.
 
 This simple implementation provides basic security functionality that is
 suitable for testing, but should not be used in production environments where
 stronger security guarantees are required.
 */
final class BasicSecurityProvider: SecurityProviderProtocol, AsyncServiceInitializable {
  private let logger: LoggingProtocol
  
  /**
   Initialises a new BasicSecurityProvider with optional logging.
   
   - Parameter logger: Optional logger for operations
   */
  init(logger: LoggingProtocol? = nil) {
    self.logger = logger ?? SimpleLogger()
  }
  
  /**
   Required initialiser for AsyncServiceInitializable protocol.
   */
  public init() async throws {
    self.logger = SimpleLogger()
  }

  /**
   Initialises the security provider.
   */
  public func initialize() async throws {
    await logger.debug("Initialising BasicSecurityProvider", metadata: nil, source: "BasicSecurityProvider")
    // No additional initialisation needed for basic implementation
  }
  
  /**
   Creates a new CryptoServiceProtocol implementation.
   
   - Returns: A CryptoServiceProtocol instance
   */
  public func cryptoService() async -> any CryptoServiceProtocol {
    return BasicCryptoService()
  }
  
  /**
   Creates a new KeyManagementProtocol implementation.
   
   - Returns: A KeyManagementProtocol instance
   */
  public func keyManager() async -> any KeyManagementProtocol {
    return BasicKeyManager(logger: logger)
  }
  
  /**
   Encrypts data with the specified configuration.

   - Parameter config: Configuration for the encryption operation
   - Returns: Result containing encrypted data or error
   */
  public func encrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    await logger.debug("BasicSecurityProvider: Starting encryption operation", metadata: nil, source: "BasicSecurityProvider")
    
    // Get the data from options
    guard let options = config.options,
          let dataToEncrypt = options.customOptions?["data"] as? [UInt8] else {
      throw SecurityProtocolError.inputError("No data provided for encryption")
    }
    
    // Get key identifier from options
    guard let keyIdentifier = options.customOptions?["keyIdentifier"] as? String else {
      throw SecurityProtocolError.inputError("No key identifier provided for encryption")
    }
    
    let crypto = await cryptoService()
    let result = await crypto.encrypt(
      dataIdentifier: options.customOptions?["dataIdentifier"] as? String ?? UUID().uuidString,
      keyIdentifier: keyIdentifier,
      options: config.options as? EncryptionOptions
    )
    
    switch result {
    case .success(let identifier):
      return SecurityResultDTO.success(
        resultData: identifier.data(using: .utf8),
        executionTimeMs: 0.1
      )
    case .failure(let error):
      throw error
    }
  }
  
  /**
   Decrypts data with the specified configuration.

   - Parameter config: Configuration for the decryption operation
   - Returns: Result containing decrypted data or error
   */
  public func decrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    await logger.debug("BasicSecurityProvider: Starting decryption operation", metadata: nil, source: "BasicSecurityProvider")
    
    guard let dataIdentifier = config.dataIdentifier else {
      throw SecurityProtocolError.invalidInput("No data identifier provided for decryption")
    }
    
    guard let keyIdentifier = config.keyIdentifier else {
      throw SecurityProtocolError.invalidInput("No key identifier provided for decryption")
    }
    
    let crypto = await cryptoService()
    let result = await crypto.decrypt(
      encryptedDataIdentifier: dataIdentifier,
      keyIdentifier: keyIdentifier,
      options: config.options as? DecryptionOptions
    )
    
    switch result {
    case .success(let identifier):
      return SecurityResultDTO.success(
        resultData: identifier.data(using: .utf8),
        executionTimeMs: 0.1
      )
    case .failure(let error):
      throw error
    }
  }
  
  /**
   Generates a cryptographic key with the specified configuration.

   - Parameter config: Configuration for the key generation operation
   - Returns: Result containing key identifier or error
   */
  public func generateKey(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    await logger.debug("BasicSecurityProvider: Starting key generation", metadata: nil, source: "BasicSecurityProvider")
    
    let keyManager = await keyManager()
    let keySize = config.keySize ?? 256
    let keyType = config.keyType ?? .aes
    
    do {
      let keyId = try await keyManager.generateKey(
        size: keySize,
        type: keyType,
        persistent: true
      )
      
      return SecurityResultDTO.success(
        resultData: keyId.data(using: .utf8),
        executionTimeMs: 0.1
      )
    } catch {
      if let secError = error as? SecurityProtocolError {
        throw secError
      } else {
        throw SecurityProtocolError.operationFailed("Key generation failed: \(error.localizedDescription)")
      }
    }
  }
  
  /**
   Computes a hash of data with the specified configuration.

   - Parameter config: Configuration for the hashing operation
   - Returns: Result containing hash or error
   */
  public func hash(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    await logger.debug("BasicSecurityProvider: Starting hash operation", metadata: nil, source: "BasicSecurityProvider")
    
    // Extract data identifier from options metadata
    guard let dataIdentifier = config.options?.metadata?["dataIdentifier"] else {
      throw SecurityProtocolError.inputError("No data identifier provided for hashing")
    }
    
    // Start timer for operation time tracking
    let startTime = Date()
    
    // Perform hash operation
    let result = await secureStorage.hash(
      dataIdentifier: dataIdentifier,
      options: nil
    )
    
    // Calculate execution time
    let executionTime = Date().timeIntervalSince(startTime) * 1000
    
    // Process the result
    switch result {
    case .success(let identifier):
      // Convert the string identifier to data using UTF-8 encoding
      let resultData = identifier.data(using: String.Encoding.utf8)
      
      return SecurityResultDTO.success(
        resultData: resultData,
        executionTimeMs: executionTime,
        metadata: ["hashIdentifier": identifier]
      )
    case .failure(let error):
      return SecurityResultDTO.failure(
        errorDetails: "Hash operation failed: \(error)",
        executionTimeMs: executionTime
      )
    }
  }
  
  /**
   Verifies a hash against data with the specified configuration.

   - Parameter config: Configuration for the verification operation
   - Returns: Result containing verification status or error
   */
  public func verifyHash(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    await logger.debug("BasicSecurityProvider: Starting hash verification", metadata: nil, source: "BasicSecurityProvider")
    
    // Extract data and hash identifiers from the options metadata
    guard let dataIdentifier = config.options?.metadata?["dataIdentifier"] else {
      throw SecurityProtocolError.inputError("No data identifier provided for hash verification")
    }
    
    guard let hashIdentifier = config.options?.metadata?["hashIdentifier"] else {
      throw SecurityProtocolError.inputError("No hash identifier provided for verification")
    }
    
    // Start timer for operation time tracking
    let startTime = Date()
    
    // Perform the verification
    let result = await secureStorage.verifyHash(
      dataIdentifier: dataIdentifier,
      hashIdentifier: hashIdentifier,
      options: nil // We don't need to cast to HashingOptions anymore
    )
    
    // Calculate execution time
    let executionTime = Date().timeIntervalSince(startTime) * 1000
    
    // Return appropriate result
    switch result {
    case .success(let isMatch):
      return SecurityResultDTO.success(
        resultData: Data([UInt8(isMatch ? 1 : 0)]),
        executionTimeMs: executionTime,
        metadata: ["verified": isMatch ? "true" : "false"]
      )
    case .failure(let error):
      return SecurityResultDTO.failure(
        errorDetails: "Hash verification failed: \(error)",
        executionTimeMs: executionTime
      )
    }
  }
  
  /**
   Securely stores data with the specified configuration.

   - Parameter config: Configuration for the storage operation
   - Returns: Result containing storage identifier or error
   */
  public func secureStore(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    await logger.debug("BasicSecurityProvider: Starting secure storage operation", metadata: nil, source: "BasicSecurityProvider")
    
    // Extract data from options
    guard let data = config.options?.metadata?["data"], 
          let dataBytes = Data(base64Encoded: data)?.bytes else {
      throw SecurityProtocolError.inputError("No valid data provided for secure storage")
    }
    
    let identifier = config.options?.metadata?["identifier"] ?? UUID().uuidString
    
    // Start timer for operation time tracking
    let startTime = Date()
    
    // Perform storage operation
    let result = await secureStorage.storeData(dataBytes, withIdentifier: identifier)
    
    // Calculate execution time
    let executionTime = Date().timeIntervalSince(startTime) * 1000
    
    // Process the result
    switch result {
    case .success:
      return SecurityResultDTO.success(
        resultData: identifier.data(using: String.Encoding.utf8),
        executionTimeMs: executionTime,
        metadata: ["identifier": identifier]
      )
    case .failure(let error):
      return SecurityResultDTO.failure(
        errorDetails: "Storage operation failed: \(error)",
        executionTimeMs: executionTime
      )
    }
  }
  
  /**
   Securely retrieves data with the specified configuration.

   - Parameter config: Configuration for the retrieval operation
   - Returns: Result containing retrieved data or error
   */
  public func secureRetrieve(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    await logger.debug("BasicSecurityProvider: Starting secure retrieval operation", metadata: nil, source: "BasicSecurityProvider")
    
    guard let identifier = config.dataIdentifier else {
      throw SecurityProtocolError.invalidInput("No data identifier provided for secure retrieval")
    }
    
    let crypto = await cryptoService()
    let result = await crypto.exportData(identifier: identifier)
    
    switch result {
    case .success(let data):
      return SecurityResultDTO.success(
        resultData: Data(data),
        executionTimeMs: 0.1
      )
    case .failure(let error):
      throw error
    }
  }
  
  /**
   Securely deletes data with the specified configuration.

   - Parameter config: Configuration for the deletion operation
   - Returns: Result containing deletion confirmation or error
   */
  public func secureDelete(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    await logger.debug("BasicSecurityProvider: Starting secure deletion operation", metadata: nil, source: "BasicSecurityProvider")
    
    guard let identifier = config.dataIdentifier else {
      throw SecurityProtocolError.invalidInput("No data identifier provided for secure deletion")
    }
    
    // In a real implementation, this would securely delete data
    // Here we just simulate successful deletion
    
    return SecurityResultDTO.success(
      executionTimeMs: 0.1,
      metadata: ["deleted": identifier]
    )
  }
  
  /**
   Signs data with the specified configuration.

   - Parameter config: Configuration for the signing operation
   - Returns: Result containing signature data or error
   */
  public func sign(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    await logger.debug("BasicSecurityProvider: Starting signing operation", metadata: nil, source: "BasicSecurityProvider")
    
    guard let data = config.data else {
      throw SecurityProtocolError.invalidInput("No data provided for signing")
    }
    
    guard let keyIdentifier = config.keyIdentifier else {
      throw SecurityProtocolError.invalidInput("No key identifier provided for signing")
    }
    
    // In a real implementation, this would compute a real signature
    // Here we just create a dummy signature
    let signature = Data(repeating: 0, count: 64)
    
    return SecurityResultDTO.success(
      resultData: signature,
      executionTimeMs: 0.1
    )
  }
  
  /**
   Verifies a signature with the specified configuration.

   - Parameter config: Configuration for the verification operation
   - Returns: Result containing verification status or error
   */
  public func verify(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    await logger.debug("BasicSecurityProvider: Starting signature verification", metadata: nil, source: "BasicSecurityProvider")
    
    guard let data = config.data else {
      throw SecurityProtocolError.invalidInput("No data provided for verification")
    }
    
    guard let signature = config.signature else {
      throw SecurityProtocolError.invalidInput("No signature provided for verification")
    }
    
    guard let keyIdentifier = config.keyIdentifier else {
      throw SecurityProtocolError.invalidInput("No key identifier provided for verification")
    }
    
    // In a real implementation, this would verify a real signature
    // Here we just return true for testing purposes
    return SecurityResultDTO.success(
      executionTimeMs: 0.1,
      metadata: ["verified": "true"]
    )
  }
  
  /**
   Performs a secure operation based on the operation type and configuration.

   - Parameters:
     - operation: The security operation to perform
     - config: Configuration for the operation
   - Returns: Result of the operation
   */
  public func performSecureOperation(
    operation: SecurityOperation,
    config: SecurityConfigDTO
  ) async throws -> SecurityResultDTO {
    await logger.debug("BasicSecurityProvider: Performing operation \(operation)", metadata: nil, source: "BasicSecurityProvider")
    
    switch operation {
    case .encrypt:
      return try await encrypt(config: config)
    case .decrypt:
      return try await decrypt(config: config)
    case .hash:
      return try await hash(config: config)
    case .verifyHash:
      return try await verifyHash(config: config)
    case .generateKey:
      return try await generateKey(config: config)
    case .sign:
      return try await sign(config: config)
    case .verify:
      return try await verify(config: config)
    case .secureStore:
      return try await secureStore(config: config)
    case .secureRetrieve:
      return try await secureRetrieve(config: config)
    case .secureDelete:
      return try await secureDelete(config: config)
    }
  }
  
  /**
   Creates a secure configuration with the specified options.

   - Parameter options: The options to configure
   - Returns: A properly configured SecurityConfigDTO
   */
  public func createSecureConfig(options: SecurityConfigOptions) async -> SecurityConfigDTO {
    await logger.debug("BasicSecurityProvider: Creating secure configuration", metadata: nil, source: "BasicSecurityProvider")
    
    // Create a basic configuration with the provided options
    return SecurityConfigDTO(
      encryptionAlgorithm: .aes256gcm,
      hashAlgorithm: .sha256,
      providerType: .standard,
      options: options
    )
  }
}

// MARK: - Basic Crypto Service Implementation

/**
 Basic implementation of CryptoServiceProtocol for development and testing.
 
 This implementation follows the Alpha Dot Five architecture with proper
 privacy-by-design principles and actor-based concurrency.
 */
final class BasicCryptoService: CryptoServiceProtocol {
  // Required by protocol
  public let secureStorage: SecureStorageProtocol
  
  init() {
    self.secureStorage = MockSecureStorage()
  }
  
  public func encrypt(
    dataIdentifier: String,
    keyIdentifier: String,
    options: EncryptionOptions?
  ) async -> Result<String, SecurityProtocolError> {
    // Get the data from secure storage
    let dataResult = await secureStorage.retrieveData(withIdentifier: dataIdentifier)
    
    switch dataResult {
    case .success(let data):
      // Get the key from secure storage
      let keyResult = await secureStorage.retrieveData(withIdentifier: keyIdentifier)
      
      switch keyResult {
      case .success(let key):
        // In a real implementation, this would perform actual encryption
        // Here we just store the original data with a new identifier
        let encryptedIdentifier = "encrypted_\(UUID().uuidString)"
        let storeResult = await secureStorage.storeData(data, withIdentifier: encryptedIdentifier)
        
        switch storeResult {
        case .success:
          return .success(encryptedIdentifier)
        case .failure(let error):
          return .failure(.storageError(error.localizedDescription))
        }
      case .failure(let error):
        return .failure(.keyError("Failed to retrieve key: \(error.localizedDescription)"))
      }
    case .failure(let error):
      return .failure(.inputError("Failed to retrieve data: \(error.localizedDescription)"))
    }
  }
  
  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options: DecryptionOptions?
  ) async -> Result<String, SecurityProtocolError> {
    // Get the encrypted data from secure storage
    let dataResult = await secureStorage.retrieveData(withIdentifier: encryptedDataIdentifier)
    
    switch dataResult {
    case .success(let encryptedData):
      // Get the key from secure storage
      let keyResult = await secureStorage.retrieveData(withIdentifier: keyIdentifier)
      
      switch keyResult {
      case .success(let key):
        // In a real implementation, this would perform actual decryption
        // Here we just store the original data with a new identifier
        let decryptedIdentifier = "decrypted_\(UUID().uuidString)"
        let storeResult = await secureStorage.storeData(encryptedData, withIdentifier: decryptedIdentifier)
        
        switch storeResult {
        case .success:
          return .success(decryptedIdentifier)
        case .failure(let error):
          return .failure(.storageError(error.localizedDescription))
        }
      case .failure(let error):
        return .failure(.keyError("Failed to retrieve key: \(error.localizedDescription)"))
      }
    case .failure(let error):
      return .failure(.inputError("Failed to retrieve encrypted data: \(error.localizedDescription)"))
    }
  }
  
  public func hash(
    dataIdentifier: String,
    options: HashingOptions?
  ) async -> Result<String, SecurityProtocolError> {
    // Get the data from secure storage
    let dataResult = await secureStorage.retrieveData(withIdentifier: dataIdentifier)
    
    switch dataResult {
    case .success(let data):
      // In a real implementation, this would compute an actual hash
      // Here we create dummy hash data
      let hashData = Data(repeating: 0, count: 32)
      let hashIdentifier = "hash_\(UUID().uuidString)"
      
      let storeResult = await secureStorage.storeData(hashData, withIdentifier: hashIdentifier)
      
      switch storeResult {
      case .success:
        return .success(hashIdentifier)
      case .failure(let error):
        return .failure(.storageError(error.localizedDescription))
      }
    case .failure(let error):
      return .failure(.inputError("Failed to retrieve data for hashing: \(error.localizedDescription)"))
    }
  }
  
  public func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options: HashingOptions?
  ) async -> Result<Bool, SecurityProtocolError> {
    // Get the data from secure storage
    let dataResult = await secureStorage.retrieveData(withIdentifier: dataIdentifier)
    
    switch dataResult {
    case .success(let data):
      // Get the hash from secure storage
      let hashResult = await secureStorage.retrieveData(withIdentifier: hashIdentifier)
      
      switch hashResult {
      case .success(let hashData):
        // In a real implementation, this would compute and verify an actual hash
        // Here we just return true for testing purposes
        return .success(true)
      case .failure(let error):
        return .failure(.inputError("Failed to retrieve hash: \(error.localizedDescription)"))
      }
    case .failure(let error):
      return .failure(.inputError("Failed to retrieve data for hash verification: \(error.localizedDescription)"))
    }
  }

  public func generateKey(
    length: Int,
    options: KeyGenerationOptions?
  ) async -> Result<String, SecurityProtocolError> {
    // In a real implementation, this would generate a cryptographic key
    // Here we just create a random key
    let keyData = Data(count: length / 8)  // Convert bits to bytes
    let keyIdentifier = "key_\(UUID().uuidString)"
    
    let storeResult = await secureStorage.storeData(keyData, withIdentifier: keyIdentifier)
    
    switch storeResult {
    case .success:
      return .success(keyIdentifier)
    case .failure(let error):
      return .failure(.storageError(error.localizedDescription))
    }
  }
  
  public func importData(
    _ data: [UInt8],
    customIdentifier: String?
  ) async -> Result<String, SecurityProtocolError> {
    let identifier = customIdentifier ?? "imported_\(UUID().uuidString)"
    let storeResult = await secureStorage.storeData(data, withIdentifier: identifier)
    
    switch storeResult {
    case .success:
      return .success(identifier)
    case .failure(let error):
      return .failure(.storageError(error.localizedDescription))
    }
  }
  
  public func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityProtocolError> {
    let retrieveResult = await secureStorage.retrieveData(withIdentifier: identifier)
    
    switch retrieveResult {
    case .success(let data):
      return .success([UInt8](data))
    case .failure(let error):
      return .failure(.storageError(error.localizedDescription))
    }
  }
}

/**
 A mock implementation of SecureStorageProtocol for testing purposes.
 */
final class MockSecureStorage: SecureStorageProtocol {
  // Use an actor for thread-safe access to storage
  private actor SecureStore {
    var storage: [String: [UInt8]] = [:]
    
    func store(_ data: [UInt8], forKey key: String) {
      storage[key] = data
    }
    
    func retrieve(forKey key: String) -> [UInt8]? {
      return storage[key]
    }
    
    func delete(forKey key: String) {
      storage.removeValue(forKey: key)
    }
    
    func allKeys() -> [String] {
      return Array(storage.keys)
    }
  }
  
  private let store = SecureStore()
  
  public func storeData(_ data: [UInt8], withIdentifier identifier: String) async -> Result<Void, SecurityProtocolError> {
    await store.store(data, forKey: identifier)
    return .success(())
  }
  
  public func retrieveData(withIdentifier identifier: String) async -> Result<[UInt8], SecurityProtocolError> {
    if let data = await store.retrieve(forKey: identifier) {
      return .success(data)
    } else {
      return .failure(.inputError("Item not found with identifier: \(identifier)"))
    }
  }
  
  public func deleteData(withIdentifier identifier: String) async -> Result<Void, SecurityProtocolError> {
    await store.delete(forKey: identifier)
    return .success(())
  }
  
  public func listDataIdentifiers() async -> Result<[String], SecurityProtocolError> {
    return .success(await store.allKeys())
  }
  
  // Convenience methods for Foundation Data type bridging
  
  func storeSecure(data: Data, identifier: String) async -> Result<Void, SecurityProtocolError> {
    return await storeData([UInt8](data), withIdentifier: identifier)
  }
  
  func retrieveSecure(identifier: String) async -> Result<Data, SecurityProtocolError> {
    let result = await retrieveData(withIdentifier: identifier)
    switch result {
    case .success(let bytes):
      return .success(Data(bytes))
    case .failure(let error):
      return .failure(error)
    }
  }
}

/**
 Simple logger for basic security operations
 */
private struct SimpleLogger: LoggingProtocol {
  var loggingActor: LoggingActor {
    fatalError("Not implemented")
  }
  
  func logMessage(_ level: LogLevel, _ message: String, context: LogContext) async {}
  func trace(_ message: String, metadata: PrivacyMetadata?, source: String) async {}
  func debug(_ message: String, metadata: PrivacyMetadata?, source: String) async {}
  func info(_ message: String, metadata: PrivacyMetadata?, source: String) async {}
  func warning(_ message: String, metadata: PrivacyMetadata?, source: String) async {}
  func error(_ message: String, metadata: PrivacyMetadata?, source: String) async {}
  func critical(_ message: String, metadata: PrivacyMetadata?, source: String) async {}
}

// Global instances for convenience
private let basicProvider = BasicSecurityProvider()
private let basicLogger = SimpleLogger()

/**
 This function executes a secure operation with the specified configuration and measures
 performance metrics. It handles errors and ensures consistent result structures.
 
 - Parameters:
   - operation: The name of the security operation being performed
   - config: Security configuration options
   
 - Returns: A SecurityResultDTO with the operation result or error
 
 - Throws: May throw errors during security operations
 */
private func performSecureOperation(
  _ operation: SecurityOperation,
  config: SecurityConfigDTO
) async throws -> SecurityResultDTO {
  await basicLogger.debug("Executing \(operation) operation", metadata: nil, source: "KeychainSecurityFactory")
  
  // Record the start time for performance measurement
  let startTime = Date()
  
  // Execute the operation based on the type
  var result: SecurityResultDTO
  
  switch operation {
  case .encrypt(let data, let key):
    result = await basicProvider.encrypt(data: data, key: key, config: config)
    
  case .decrypt(let data, let key):
    result = await basicProvider.decrypt(encryptedData: data, key: key, config: config)
    
  case .sign(let data, let key):
    result = await basicProvider.sign(data: data, key: key, config: config)
    
  case .verify(let signature, let data, let key):
    result = await basicProvider.verify(signature: signature, data: data, key: key, config: config)
    
  case .hash(let data):
    result = await basicProvider.hash(data: data, config: config)
  }
  
  // Calculate operation duration
  let executionTime = Date().timeIntervalSince(startTime)
  
  // Update the result with execution time and return
  // We need to create a new SecurityResultDTO with the execution time
  return SecurityResultDTO(
    success: result.success,
    data: result.data,
    error: result.error,
    executionTime: executionTime
  )
}
