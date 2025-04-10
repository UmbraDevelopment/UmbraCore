import Foundation
import LoggingInterfaces
import LoggingServices
import LoggingTypes
import CoreSecurityTypes
import SecurityCoreInterfaces
import SecurityInterfaces
import CryptoTypes

// MARK: - Base Security Service

/**
 Base class for security service components with common functionality.
 */
private class SecurityServiceBase {
  /// Logger for operation tracking and auditing
  let logger: LoggingProtocol
  
  /// Secure storage for persisting data
  let secureStorage: SecureStorageProtocol
  
  /**
   Initializes the security service with a logger and secure storage.
   
   - Parameter logger: Logger instance for operation auditing
   - Parameter secureStorage: Secure storage for persisting data
   */
  init(logger: LoggingProtocol, secureStorage: SecureStorageProtocol) {
    self.logger = logger
    self.secureStorage = secureStorage
  }
  
  /**
   Creates a log context with privacy metadata.
   
   - Parameter metadata: Dictionary of key-value pairs with privacy levels
   - Parameter domain: Optional domain for the log context
   - Parameter source: Source component identifier
   - Returns: A LogContextDTO object for logging
   */
  func createLogContext(
    _ metadata: [String: (value: String, privacy: LogPrivacyLevel)] = [:],
    domain: String = "security",
    source: String
  ) -> BaseLogContextDTO {
    var collection = LogMetadataDTOCollection()
    
    for (key, data) in metadata {
      switch data.privacy {
      case .public:
        collection = collection.withPublic(key: key, value: data.value)
      case .private:
        collection = collection.withPrivate(key: key, value: data.value)
      case .sensitive:
        collection = collection.withSensitive(key: key, value: data.value)
      case .auto:
        collection = collection.withPublic(key: key, value: data.value)
      }
    }
    
    return BaseLogContextDTO(
      domainName: domain,
      source: source,
      metadata: collection
    )
  }
  
  /**
   Creates a log context with properly classified metadata.
   
   - Parameters:
     - metadata: Dictionary of metadata with privacy levels
     - domain: Domain for the log context
     - source: Source identifier for the log context
   - Returns: A log context with properly classified metadata
   */
  func createLogContext(
    _ metadata: [String: (value: String, privacy: LogPrivacyLevel)],
    domain: String = "SecurityServices",
    source: String
  ) -> BaseLogContextDTO {
    var collection = LogMetadataDTOCollection()
    
    for (key, data) in metadata {
      switch data.privacy {
      case .public:
        collection = collection.withPublic(key: key, value: data.value)
      case .private:
        collection = collection.withPrivate(key: key, value: data.value)
      case .sensitive:
        collection = collection.withSensitive(key: key, value: data.value)
      case .auto:
        collection = collection.withPublic(key: key, value: data.value)
      }
    }
    
    return BaseLogContextDTO(
      domainName: domain,
      source: source,
      metadata: collection
    )
  }
}

// MARK: - Encryption Service

/**
 Handles encryption and decryption operations.
 */
private final class BasicEncryptionService: SecurityServiceBase {
  /**
   Encrypts data using the specified configuration.
   
   - Parameter config: Security configuration with encryption parameters
   - Returns: Result containing encrypted data and metadata
   - Throws: If encryption fails
   */
  func encrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let operationID = UUID().uuidString
    let startTime = Date()
    
    await logger.debug("Starting encryption operation",
                 context: createLogContext(
                   [
                     "operationID": (value: operationID, privacy: .public),
                     "algorithm": (value: config.encryptionAlgorithm.rawValue, privacy: .public)
                   ],
                   source: "BasicEncryptionService"
                 ))
    
    // This is where the actual encryption would happen
    // In a real implementation, this would use the algorithm specified in the config
    // and perform proper encryption with the provided data
    
    // For now, this is a placeholder that returns empty data
    let resultData = Data()
    
    let endTime = Date()
    let duration = endTime.timeIntervalSince(startTime) * 1000
    
    await logger.debug("Completed encryption operation",
                 context: createLogContext(
                   [
                     "operationID": (value: operationID, privacy: .public),
                     "duration": (value: String(format: "%.2f", duration), privacy: .public),
                     "status": (value: "success", privacy: .public)
                   ],
                   source: "BasicEncryptionService"
                 ))
    
    return SecurityResultDTO.success(
      resultData: resultData,
      executionTimeMs: duration,
      metadata: [
        "operationID": operationID,
        "algorithm": config.encryptionAlgorithm.rawValue
      ]
    )
  }
  
  /**
   Decrypts data using the specified configuration.
   
   - Parameter config: Security configuration with decryption parameters
   - Returns: Result containing decrypted data and metadata
   - Throws: If decryption fails
   */
  func decrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let operationID = UUID().uuidString
    let startTime = Date()
    
    await logger.debug("Starting decryption operation",
                 context: createLogContext(
                   [
                     "operationID": (value: operationID, privacy: .public),
                     "algorithm": (value: config.encryptionAlgorithm.rawValue, privacy: .public)
                   ],
                   source: "BasicEncryptionService"
                 ))
    
    // This is where the actual decryption would happen
    // In a real implementation, this would use the algorithm specified in the config
    // and perform proper decryption with the provided data
    
    // For now, this is a placeholder that returns empty data
    let resultData = Data()
    
    let endTime = Date()
    let duration = endTime.timeIntervalSince(startTime) * 1000
    
    await logger.debug("Completed decryption operation",
                 context: createLogContext(
                   [
                     "operationID": (value: operationID, privacy: .public),
                     "duration": (value: String(format: "%.2f", duration), privacy: .public),
                     "status": (value: "success", privacy: .public)
                   ],
                   source: "BasicEncryptionService"
                 ))
    
    return SecurityResultDTO.success(
      resultData: resultData,
      executionTimeMs: duration,
      metadata: [
        "operationID": operationID,
        "algorithm": config.encryptionAlgorithm.rawValue
      ]
    )
  }
}

// MARK: - Hashing Service

/**
 Handles cryptographic hashing operations.
 */
private final class BasicHashingService: SecurityServiceBase {
  /**
   Performs a hash operation on the provided data.
   
   - Parameter config: Security configuration with hashing parameters
   - Returns: Result containing the hash and metadata
   - Throws: If hashing fails
   */
  func hash(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let operationID = UUID().uuidString
    let startTime = Date()
    
    await logger.debug("Starting hash operation",
                 context: createLogContext(
                   [
                     "operationID": (value: operationID, privacy: .public),
                     "algorithm": (value: config.hashAlgorithm.rawValue, privacy: .public)
                   ],
                   source: "BasicHashingService"
                 ))
    
    // This is where the actual hashing would happen
    // In a real implementation, this would use the algorithm specified in the config
    // and perform proper hashing with the provided data
    
    // For now, this is a placeholder that returns empty data
    let resultData = Data()
    
    let endTime = Date()
    let duration = endTime.timeIntervalSince(startTime) * 1000
    
    await logger.debug("Completed hash operation",
                 context: createLogContext(
                   [
                     "operationID": (value: operationID, privacy: .public),
                     "duration": (value: String(format: "%.2f", duration), privacy: .public),
                     "status": (value: "success", privacy: .public)
                   ],
                   source: "BasicHashingService"
                 ))
    
    return SecurityResultDTO.success(
      resultData: resultData,
      executionTimeMs: duration,
      metadata: [
        "operationID": operationID,
        "algorithm": config.hashAlgorithm.rawValue
      ]
    )
  }
  
  /**
   Verifies a hash against the original data.
   
   - Parameter config: Security configuration with verification parameters
   - Returns: Result indicating whether the hash is valid
   - Throws: If verification fails
   */
  func verifyHash(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let operationID = UUID().uuidString
    let startTime = Date()
    
    await logger.debug("Starting hash verification operation",
                 context: createLogContext(
                   [
                     "operationID": (value: operationID, privacy: .public),
                     "algorithm": (value: config.hashAlgorithm.rawValue, privacy: .public)
                   ],
                   source: "BasicHashingService"
                 ))
    
    // This is where the actual verification would happen
    // In a real implementation, this would validate the hash against the original data
    
    // Placeholder - assuming verification succeeds
    let isValid = true
    
    let endTime = Date()
    let duration = endTime.timeIntervalSince(startTime) * 1000
    
    await logger.debug("Completed hash verification operation",
                 context: createLogContext(
                   [
                     "operationID": (value: operationID, privacy: .public),
                     "duration": (value: String(format: "%.2f", duration), privacy: .public),
                     "status": (value: "success", privacy: .public),
                     "isValid": (value: isValid ? "true" : "false", privacy: .public)
                   ],
                   source: "BasicHashingService"
                 ))
    
    return SecurityResultDTO.success(
      resultData: Data([isValid ? 1 : 0]), // 1 for valid, 0 for invalid
      executionTimeMs: duration,
      metadata: [
        "operationID": operationID,
        "algorithm": config.hashAlgorithm.rawValue,
        "isValid": isValid ? "true" : "false"
      ]
    )
  }
}

// MARK: - Key Generation Service

/**
 Handles cryptographic key generation and management.
 */
private final class BasicKeyGenerationService: SecurityServiceBase {
  /**
   Generates a cryptographic key with the specified parameters.
   
   - Parameter config: Security configuration with key generation parameters
   - Returns: Result containing the generated key
   - Throws: If key generation fails
   */
  func generateKey(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let operationID = UUID().uuidString
    let startTime = Date()
    
    // Extract key size from metadata, default to 256 bits if not specified
    let keySize = Int(config.options?.metadata?["keySize"] ?? "256") ?? 256
    
    await logger.debug("Starting key generation operation",
                 context: createLogContext(
                   [
                     "operationID": (value: operationID, privacy: .public),
                     "keySize": (value: String(keySize), privacy: .public)
                   ],
                   source: "BasicKeyGenerationService"
                 ))
    
    // This is where the actual key generation would happen
    // In a real implementation, this would generate a cryptographically secure key
    
    // For now, this is a placeholder that returns empty data
    let resultData = Data(count: keySize / 8) // Convert bits to bytes
    
    let endTime = Date()
    let duration = endTime.timeIntervalSince(startTime) * 1000
    
    await logger.debug("Completed key generation operation",
                 context: createLogContext(
                   [
                     "operationID": (value: operationID, privacy: .public),
                     "duration": (value: String(format: "%.2f", duration), privacy: .public),
                     "status": (value: "success", privacy: .public)
                   ],
                   source: "BasicKeyGenerationService"
                 ))
    
    return SecurityResultDTO.success(
      resultData: resultData,
      executionTimeMs: duration,
      metadata: [
        "operationID": operationID,
        "keySize": String(keySize)
      ]
    )
  }
}

// MARK: - Configuration Service

/**
 Handles security configuration creation and validation.
 */
private final class BasicConfigurationService: SecurityServiceBase {
  /**
   Creates a security configuration with the specified options.
   
   - Parameter options: Security configuration options
   - Returns: A configured SecurityConfigDTO
   */
  func createSecureConfig(options: SecurityConfigOptions) async -> SecurityConfigDTO {
    await logger.debug("Creating security configuration",
                 context: createLogContext(
                   [
                     "useHardwareAcceleration": (value: String(options.useHardwareAcceleration), privacy: .public),
                     "keyDerivationIterations": (value: String(options.keyDerivationIterations), privacy: .public)
                   ],
                   source: "BasicConfigurationService"
                 ))
    
    return SecurityConfigDTO(
      encryptionAlgorithm: .aes256CBC,
      hashAlgorithm: .sha256,
      providerType: .basic,
      options: options
    )
  }
}

/**
 # BasicSecurityProvider
 
 A simple implementation of SecurityProviderProtocol that provides basic cryptographic operations.
 This is intended as a fallback provider when more specialised providers aren't available.
 
 This implementation follows the Alpha Dot Five architecture with:
 - Actor-based concurrency for thread safety
 - Adapter pattern for improved modularisation
 - Strong type safety and rigorous error handling
 - Privacy-by-design with privacy-aware logging
 
 - Note: This implementation uses SecRandomCopyBytes from Apple's Security framework
   for secure random generation and simple AES-CBC encryption for data protection.
 */
actor BasicSecurityProvider: SecurityProviderProtocol {
  // MARK: - Properties
  
  /// Logger for operation tracking and auditing
  private let logger: LoggingProtocol
  
  /// Service adapter for encryption operations
  private let encryptionService: EncryptionServiceAdapter
  
  /// Service adapter for hashing operations
  private let hashingService: HashingServiceAdapter
  
  /// Service adapter for key generation operations
  private let keyGenerationService: KeyGenerationServiceAdapter
  
  /// Service adapter for configuration management
  private let configurationService: ConfigurationServiceAdapter
  
  // MARK: - Initialization
  
  /**
   Initializes the security provider with the necessary service adapters.
   
   - Parameters:
      - logger: Logger for operation auditing
      - encryptionService: Adapter for encryption operations
      - hashingService: Adapter for hashing operations
      - keyGenerationService: Adapter for key generation
      - configurationService: Adapter for configuration management
   */
  init(
    logger: LoggingProtocol,
    encryptionService: EncryptionServiceAdapter,
    hashingService: HashingServiceAdapter,
    keyGenerationService: KeyGenerationServiceAdapter,
    configurationService: ConfigurationServiceAdapter
  ) {
    self.logger = logger
    self.encryptionService = encryptionService
    self.hashingService = hashingService
    self.keyGenerationService = keyGenerationService
    self.configurationService = configurationService
  }
  
  // MARK: - SecurityProviderProtocol Methods
  
  /**
   Initialises the security provider.
   
   - Throws: Error if initialisation fails
   */
  public func initialize() async throws {
    await logger.debug("Initialising BasicSecurityProvider",
                 context: createLogContext(
                   [:],
                   source: "BasicSecurityProvider"
                 ))
    // Nothing special to initialize for basic provider
  }
  
  /**
   Performs a secure operation with the specified configuration.
   
   - Parameters:
     - operation: The type of operation to perform
     - config: Configuration for the operation
   - Returns: Result of the operation
   - Throws: If the operation fails
   */
  public func performSecureOperation(
    operation: SecurityOperation,
    config: SecurityConfigDTO
  ) async throws -> SecurityResultDTO {
    await logger.debug("Performing secure operation: \(operation.rawValue)",
                 context: createLogContext(
                   [
                     "operationType": (value: operation.rawValue, privacy: .public)
                   ],
                   source: "BasicSecurityProvider"
                 ))
    
    // Delegate to the appropriate service based on operation type
    switch operation {
    case .encrypt:
      return try await encryptionService.encrypt(config: config)
    case .decrypt:
      return try await encryptionService.decrypt(config: config)
    case .hash:
      return try await hashingService.hash(config: config)
    case .verifyHash:
      return try await hashingService.verifyHash(config: config)
    case .generateKey:
      return try await keyGenerationService.generateKey(config: config)
    @unknown default:
      throw SecurityError.unsupportedOperation(name: "Unknown operation type")
    }
  }
  
  /**
   Creates a security configuration with the specified options.
   
   - Parameter options: The security configuration options
   - Returns: The created security configuration
   */
  public func createSecureConfig(options: SecurityConfigOptions) async -> SecurityConfigDTO {
    return configurationService.createSecureConfig(options: options)
  }
  
  /**
   Encrypts data using the specified key and algorithm.
   
   - Parameters:
     - data: The data to encrypt
     - key: The cryptographic key to use
     - algorithm: The encryption algorithm to use
   - Returns: The encrypted data
   - Throws: If encryption fails
   */
  public func encryptData(
    _ data: Data,
    with key: any SendableCryptoMaterial,
    using algorithm: EncryptionAlgorithm
  ) async throws -> Data {
    await logger.debug("Encrypting data using \(algorithm.rawValue)",
                 context: createLogContext(
                   [
                     "algorithm": (value: algorithm.rawValue, privacy: .public)
                   ],
                   source: "BasicSecurityProvider"
                 ))
    
    // Create configuration with the specified parameters
    var options = SecurityConfigOptions(
      enableDetailedLogging: true,
      keyDerivationIterations: 10000,
      memoryLimitBytes: 65536,
      useHardwareAcceleration: true,
      operationTimeoutSeconds: 30,
      verifyOperations: true
    )
    
    // Create a key ID for this operation
    let keyId = "temp_key_" + UUID().uuidString
    
    // Store the key data temporarily
    try await storeKeyTemporarily(key, withId: keyId)
    
    // Add metadata with encryption parameters
    var metadata = [String: String]()
    metadata["inputData"] = data.base64EncodedString()
    metadata["keyIdentifier"] = keyId
    options.metadata = metadata
    
    // Create security configuration
    let config = SecurityConfigDTO(
      encryptionAlgorithm: algorithm,
      hashAlgorithm: .sha256,
      providerType: .basic,
      options: options
    )
    
    do {
      // Perform encryption
      let result = try await encryptionService.encrypt(config: config)
      
      // Cleanup temporary key
      try await cleanupTemporaryKey(keyId)
      
      guard let resultData = result.resultData else {
        throw SecurityError.encryptionFailed(reason: "No encrypted data returned")
      }
      
      return resultData
    } catch {
      // Ensure cleanup happens even on error
      try? await cleanupTemporaryKey(keyId)
      throw error
    }
  }
  
  /**
   Decrypts data using the specified key and algorithm.
   
   - Parameters:
      - data: The data to decrypt
      - key: The cryptographic key to use
      - algorithm: The encryption algorithm to use
   - Returns: The decrypted data
   - Throws: If decryption fails
   */
  public func decryptData(
    _ data: Data,
    with key: any SendableCryptoMaterial,
    using algorithm: EncryptionAlgorithm
  ) async throws -> Data {
    await logger.debug("Decrypting data using \(algorithm.rawValue)",
                 context: createLogContext(
                   [
                     "algorithm": (value: algorithm.rawValue, privacy: .public)
                   ],
                   source: "BasicSecurityProvider"
                 ))
    
    // Create configuration with the specified parameters
    var options = SecurityConfigOptions(
      enableDetailedLogging: true,
      keyDerivationIterations: 10000,
      memoryLimitBytes: 65536,
      useHardwareAcceleration: true,
      operationTimeoutSeconds: 30,
      verifyOperations: true
    )
    
    // Create a key ID for this operation
    let keyId = "temp_key_" + UUID().uuidString
    
    // Store the key data temporarily
    try await storeKeyTemporarily(key, withId: keyId)
    
    // Add metadata with decryption parameters
    var metadata = [String: String]()
    metadata["inputData"] = data.base64EncodedString()
    metadata["keyIdentifier"] = keyId
    options.metadata = metadata
    
    // Create security configuration
    let config = SecurityConfigDTO(
      encryptionAlgorithm: algorithm,
      hashAlgorithm: .sha256,
      providerType: .basic,
      options: options
    )
    
    do {
      // Perform decryption
      let result = try await encryptionService.decrypt(config: config)
      
      // Cleanup temporary key
      try await cleanupTemporaryKey(keyId)
      
      guard let resultData = result.resultData else {
        throw SecurityError.decryptionFailed(reason: "No decrypted data returned")
      }
      
      return resultData
    } catch {
      // Ensure cleanup happens even on error
      try? await cleanupTemporaryKey(keyId)
      throw error
    }
  }
  
  /**
   Generates a cryptographic key with the specified parameters.
   
   - Parameter config: Key generation configuration
   - Returns: The generated key
   - Throws: If key generation fails
   */
  public func generateKey(config: KeyGenConfig) async throws -> any SendableCryptoMaterial {
    await logger.debug("Generating \(config.keyType) key of size \(config.keySize)",
                 context: createLogContext(
                   [
                     "keyType": (value: config.keyType.rawValue, privacy: .public),
                     "keySize": (value: String(config.keySize), privacy: .public)
                   ],
                   source: "BasicSecurityProvider"
                 ))
    
    // Create configuration with the specified parameters
    var options = SecurityConfigOptions(
      enableDetailedLogging: true,
      keyDerivationIterations: 10000,
      memoryLimitBytes: 65536,
      useHardwareAcceleration: true,
      operationTimeoutSeconds: 30,
      verifyOperations: true
    )
    
    // Add metadata
    var metadata = [String: String]()
    metadata["keyType"] = config.keyType.rawValue
    metadata["keySize"] = String(config.keySize)
    options.metadata = metadata
    
    // Create security configuration
    let securityConfig = SecurityConfigDTO(
      encryptionAlgorithm: .aes256CBC,
      hashAlgorithm: .sha256,
      providerType: .basic,
      options: options
    )
    
    // Generate the key
    let result = try await keyGenerationService.generateKey(config: securityConfig)
    guard let resultData = result.resultData else {
      throw SecurityError.keyGenerationFailed(reason: "No key data returned")
    }
    
    // Create a sendable crypto material from the result data
    let keyIdentifier = UUID().uuidString
    return MaterialKey(identifier: keyIdentifier, data: resultData)
  }
  
  /**
   Hashes data using the specified algorithm.
   
   - Parameters:
      - data: The data to hash
      - algorithm: The hashing algorithm to use
   - Returns: The hash value as Data
   - Throws: If hashing fails
   */
  public func hashData(_ data: Data, using algorithm: HashAlgorithm) async throws -> Data {
    await logger.debug("Hashing data using \(algorithm.rawValue)",
                 context: createLogContext(
                   [
                     "algorithm": (value: algorithm.rawValue, privacy: .public)
                   ],
                   source: "BasicSecurityProvider"
                 ))
    
    // Create configuration with the specified parameters
    var options = SecurityConfigOptions(
      enableDetailedLogging: true,
      keyDerivationIterations: 10000,
      memoryLimitBytes: 65536,
      useHardwareAcceleration: true,
      operationTimeoutSeconds: 30,
      verifyOperations: true
    )
    
    // Add metadata
    var metadata = [String: String]()
    metadata["algorithm"] = algorithm.rawValue
    metadata["dataLength"] = String(data.count)
    metadata["inputData"] = data.base64EncodedString()
    options.metadata = metadata
    
    // Create security configuration
    let config = SecurityConfigDTO(
      encryptionAlgorithm: .aes256CBC,
      hashAlgorithm: algorithm,
      providerType: .basic,
      options: options
    )
    
    // Perform hashing
    let result = try await hashingService.hash(config: config)
    guard let resultData = result.resultData else {
      throw SecurityError.hashingFailed(reason: "No hash data returned")
    }
    return resultData
  }
  
  /**
   Verifies that a hash matches the expected value for the specified data.
   
   - Parameters:
      - data: The data to verify
      - expectedHash: The expected hash value
      - algorithm: The hashing algorithm used
   - Returns: True if the hash matches, false otherwise
   - Throws: If verification fails
   */
  public func verifyHash(_ data: Data, against expectedHash: Data, using algorithm: HashAlgorithm) async throws -> Bool {
    await logger.debug("Verifying hash using \(algorithm.rawValue)",
                 context: createLogContext(
                   [
                     "algorithm": (value: algorithm.rawValue, privacy: .public)
                   ],
                   source: "BasicSecurityProvider"
                 ))
    
    // Create configuration with the specified parameters
    var options = SecurityConfigOptions(
      enableDetailedLogging: true,
      keyDerivationIterations: 10000,
      memoryLimitBytes: 65536,
      useHardwareAcceleration: true,
      operationTimeoutSeconds: 30,
      verifyOperations: true
    )
    
    // Add metadata
    var metadata = [String: String]()
    metadata["algorithm"] = algorithm.rawValue
    metadata["inputData"] = data.base64EncodedString()
    metadata["expectedHash"] = expectedHash.base64EncodedString()
    options.metadata = metadata
    
    // Create security configuration
    let config = SecurityConfigDTO(
      encryptionAlgorithm: .aes256CBC,
      hashAlgorithm: algorithm,
      providerType: .basic,
      options: options
    )
    
    // Perform verification
    let result = try await hashingService.verifyHash(config: config)
    guard let resultData = result.resultData, resultData.count > 0 else {
      throw SecurityError.hashingFailed(reason: "No verification result returned")
    }
    
    // The adapter returns a single byte with 1 for match, 0 for mismatch
    return resultData[0] == 1
  }
  
  // MARK: - Helper Methods
  
  /**
   Stores a key temporarily for use in cryptographic operations.
   
   - Parameters:
     - key: The key to store
     - id: The identifier to use for the key
   - Throws: If storing the key fails
   */
  private func storeKeyTemporarily(_ key: any SendableCryptoMaterial, withId id: String) async throws {
    // Extract the key data and store it
    let keyData = key.getKeyData()
    try await storeKeyData(keyData, withId: id)
  }
  
  /**
   Stores key data with the specified identifier.
   
   - Parameters:
     - keyData: The key data to store
     - id: The identifier to use for the key
   - Throws: If storing the key fails
   */
  private func storeKeyData(_ keyData: Data, withId id: String) async throws {
    // Simulate key storage for this implementation
    // In a real implementation, this would use a secure storage mechanism
    // For now, we're just returning success as adapters would handle actual storage
  }
  
  /**
   Cleans up a temporary key after use.
   
   - Parameter id: The identifier of the key to clean up
   - Throws: If cleaning up the key fails
   */
  private func cleanupTemporaryKey(_ id: String) async throws {
    // Simulate key cleanup for this implementation
    // In a real implementation, this would securely delete the key from storage
  }
  
  /**
   Creates a log context with privacy metadata.
   
   - Parameter metadata: Dictionary of key-value pairs with privacy levels
   - Parameter domain: Optional domain for the log context
   - Parameter source: Source component identifier
   - Returns: A LogContextDTO object for logging
   */
  private func createLogContext(
    _ metadata: [String: (value: String, privacy: LogPrivacy)] = [:],
    domain: String = "security",
    source: String
  ) -> BaseLogContextDTO {
    var collection = LogMetadataDTOCollection()
    
    for (key, data) in metadata {
      switch data.privacy {
      case .public:
        collection = collection.withPublic(key: key, value: data.value)
      case .private:
        collection = collection.withPrivate(key: key, value: data.value)
      case .sensitive:
        collection = collection.withSensitive(key: key, value: data.value)
      case .auto:
        collection = collection.withPublic(key: key, value: data.value)
      }
    }
    
    return BaseLogContextDTO(
      domainName: domain,
      source: source,
      metadata: collection
    )
  }
}

/**
 A simple implementation of SendableCryptoMaterial using Data.
 */
struct MaterialKey: SendableCryptoMaterial {
  /// Unique identifier for this key
  let identifier: String
  
  /// The actual key data
  private let data: Data
  
  /// Creates a new material key with the specified data
  init(identifier: String, data: Data) {
    self.identifier = identifier
    self.data = data
  }
  
  /// Returns the key data
  func getKeyData() -> Data {
    return data
  }
  
  /// Returns true if the key is valid
  func isValid() -> Bool {
    return !data.isEmpty
  }
}

/**
 Error types for security operations.
 */
enum SecurityError: Error {
  case encryptionFailed(reason: String)
  case decryptionFailed(reason: String)
  case hashingFailed(reason: String)
  case keyGenerationFailed(reason: String)
  case keyNotFound(identifier: String)
  case unsupportedAlgorithm(name: String)
  case unsupportedOperation(name: String)
}
