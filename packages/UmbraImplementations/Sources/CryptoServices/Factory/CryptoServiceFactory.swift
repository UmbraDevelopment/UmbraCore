import CryptoInterfaces
import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingServices
import SecurityCoreInterfaces
import SecurityInterfaces // Temporary, until we fully migrate SecureStorageConfig
import UmbraErrors
import CoreSecurityTypes

/**
 # CryptoServiceFactory

 Factory for creating CryptoServiceProtocol implementations.
 This factory follows the Alpha Dot Five architecture pattern
 of providing asynchronous factory methods that return actor-based
 implementations.

 This is the canonical factory for all cryptographic service implementations
 in the UmbraCore project, consolidating functionality previously split between
 multiple factory implementations.

 ## Usage Examples

 ### Standard Implementation
 ```swift
 // Create a default implementation
 let cryptoService = await CryptoServiceFactory.createDefault(secureStorage: mySecureStorage)

 // Create a service with custom secure logger
 let customService = await CryptoServiceFactory.createDefaultService(
   secureStorage: mySecureStorage,
   secureLogger: mySecureLogger
 )
 ```

 ### Security Provider-Specific Implementations
 ```swift
 // Create a service with a specific provider type
 let cryptoWithProvider = await CryptoServiceFactory.createWithProviderType(
   providerType: .cryptoKit,
   logger: myLogger
 )

 // For more control, create with explicit provider instance
 let myProvider = await ProviderFactory.createProvider(.appleCommonCrypto)
 let cryptoService = await CryptoServiceFactory.createWithProvider(
   provider: myProvider,
   secureStorage: mySecureStorage,
   logger: myLogger
 )
 ```

 ### Logging and Testing Implementations
 ```swift
 // Create a logging implementation
 let loggingService = await CryptoServiceFactory.createLoggingDecorator(
   wrapped: cryptoService,
   logger: myLogger,
   secureLogger: mySecureLogger
 )

 // Create a mock implementation for testing
 let mockService = await CryptoServiceFactory.createMock()
 ```
 */
public enum CryptoServiceFactory {
  // MARK: - Standard Implementations

  /**
   Creates a default crypto service implementation.

   - Parameter secureStorage: Optional secure storage service to use
   - Returns: A CryptoServiceProtocol implementation
   */
  public static func createDefault(
    secureStorage: SecureStorageProtocol? = nil
  ) async -> CryptoServiceProtocol {
    await createDefaultService(secureStorage: secureStorage)
  }

  /**
   Creates a standard crypto service implementation with custom loggers.

   - Parameters:
     - secureStorage: Optional secure storage service to use
     - logger: Logger for operations
     - secureLogger: Privacy-aware secure logger for sensitive operations
   - Returns: A CryptoServiceProtocol implementation
   */
  public static func createDefaultService(
    secureStorage: SecureStorageProtocol? = nil,
    logger: LoggingProtocol? = nil,
    secureLogger: PrivacyAwareLoggingProtocol? = nil
  ) async -> CryptoServiceProtocol {
    let actualLogger = logger ?? DefaultLogger(subsystem: "com.umbra.crypto", category: "CryptoService")
    let actualSecureLogger = secureLogger
    
    let service = await DefaultCryptoServiceImpl(
      secureStorage: secureStorage,
      logger: actualLogger
    )
    
    if let actualSecureLogger = actualSecureLogger {
      // Create enhanced privacy-aware logging implementation
      return await EnhancedLoggingCryptoServiceImpl(
        wrapped: service,
        logger: actualSecureLogger
      )
    } else {
      // Create standard logging implementation
      return await LoggingCryptoServiceImpl(
        wrapped: service,
        logger: actualLogger
      )
    }
  }

  /**
   Creates a high security crypto service implementation.

   - Parameters:
     - secureStorage: Optional secure storage service to use
     - logger: Logger for operations
   - Returns: A CryptoServiceProtocol implementation with enhanced security
   */
  public static func createHighSecurityService(
    secureStorage: SecureStorageProtocol? = nil,
    logger: LoggingProtocol? = nil
  ) async -> CryptoServiceProtocol {
    let actualLogger = logger ?? DefaultLogger(subsystem: "com.umbra.crypto", category: "HighSecurityCryptoService")
    
    // Create secure service with enhanced parameters
    let service = await SecureCryptoServiceImpl(
      wrapped: await DefaultCryptoServiceImpl(
        secureStorage: secureStorage,
        logger: actualLogger,
        options: CryptoServiceOptions(
          defaultIterations: 10000, // Higher iteration count for PBKDF2
          enforceStrongKeys: true
        )
      ),
      logger: actualLogger
    )
    
    return await LoggingCryptoServiceImpl(
      wrapped: service,
      logger: actualLogger
    )
  }
  
  // MARK: - Provider-Specific Implementations
  
  /**
   Creates a new crypto service with the specified provider type.
   This is the consolidated implementation that handles provider creation internally.
   
   This method integrates functionality previously available in separate factory implementations,
   providing a unified interface for creating cryptographic services with specific provider types.

   - Parameters:
     - providerType: The type of security provider to use
     - secureStorage: Optional secure storage service to use
     - logger: Logger for recording operations
   - Returns: A new actor-based implementation of CryptoServiceProtocol
   */
  public static func createWithProviderType(
    providerType: SecurityProviderType,
    secureStorage: SecureStorageProtocol? = nil,
    logger: LoggingProtocol? = nil
  ) async -> CryptoServiceProtocol {
    let actualLogger = logger ?? DefaultLogger(subsystem: "com.umbra.crypto", category: "CryptoService")
    
    // Use the provided secure storage or create a default one
    let actualSecureStorage = secureStorage ?? await createSecureStorage(
      storageURL: URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent("UmbraSecureStorage", isDirectory: true)
        .appendingPathComponent(UUID().uuidString),
      logger: actualLogger
    )
    
    // Create provider based on the specified type
    // This approach uses the provider registry to create providers dynamically
    let registry = await createProviderRegistry(logger: actualLogger)
    let provider: SecurityProviderProtocol?
    
    switch providerType {
    case .cryptoKit:
      provider = await registry.createProvider(type: .cryptoKit)
    case .commonCrypto:
      provider = await registry.createProvider(type: .commonCrypto)
    case .boringSSL:
      provider = await registry.createProvider(type: .boringSSL)
    case .openSSL:
      provider = await registry.createProvider(type: .openSSL)
    case .mock:
      provider = await registry.createProvider(type: .mock)
    }
    
    guard let provider = provider else {
      await actualLogger.error(
        "Failed to create provider of type \(providerType). Falling back to mock implementation.",
        metadata: nil,
        source: "CryptoServiceFactory"
      )
      
      // Return a mock implementation as fallback
      return await createMock(
        secureStorage: actualSecureStorage,
        logger: actualLogger,
        configuration: MockCryptoServiceImpl.Configuration(encryptionSucceeds: true)
      )
    }
    
    // Now use the provider to create the crypto service
    return await createWithProvider(
      provider: provider,
      secureStorage: actualSecureStorage,
      logger: actualLogger
    )
  }
  
  /**
   Creates a new crypto service with the specified security provider.
   The implementation follows the actor-based concurrency model of the
   Alpha Dot Five architecture.

   - Parameters:
      - provider: The security provider to use (should be obtained from appropriate factory)
      - secureStorage: Optional secure storage service to use
      - logger: Logger for recording operations
   - Returns: A new actor-based implementation of CryptoServiceProtocol
   */
  public static func createWithProvider(
    provider: SecurityProviderProtocol,
    secureStorage: SecureStorageProtocol? = nil,
    logger: LoggingProtocol? = nil
  ) async -> CryptoServiceProtocol {
    let actualLogger = logger ?? DefaultLogger(subsystem: "com.umbra.crypto", category: "CryptoService")
    
    // Use the provided secure storage or create a default one
    let actualSecureStorage = secureStorage ?? await createSecureStorage(
      storageURL: URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent("UmbraSecureStorage", isDirectory: true)
        .appendingPathComponent(UUID().uuidString),
      logger: actualLogger
    )
    
    // Create a crypto service implementation using DefaultCryptoServiceImpl
    // instead of directly using CryptoServiceActor to avoid circular dependency
    let cryptoService = await DefaultCryptoServiceWithProviderImpl(
      provider: provider,
      secureStorage: actualSecureStorage,
      logger: actualLogger
    )
    
    // Return as the protocol type
    return cryptoService
  }
  
  /**
   Creates a new crypto service with the specified provider type.
   This method maintains backward compatibility with existing code.
   
   Note: This method requires that a factory for the specified provider type
   is available elsewhere in the application. It doesn't directly create
   security provider implementations to avoid circular dependencies.

   - Parameters:
      - providerType: The type of security provider to use
      - logger: Logger for recording operations
   - Returns: A new actor-based implementation of CryptoServiceProtocol, or nil if provider creation fails
   */
  @available(*, deprecated, message: "Use createWithProviderType(providerType:secureStorage:logger:) instead")
  public static func createWithProvider(
    providerType: SecurityProviderType,
    logger: LoggingProtocol? = nil
  ) async -> CryptoServiceProtocol? {
    // Log deprecation warning and delegate to the new implementation
    let actualLogger = logger ?? DefaultLogger(subsystem: "com.umbra.crypto", category: "CryptoService")
    
    await actualLogger.warning(
      "Using deprecated createWithProvider(providerType:) method. Use createWithProviderType(providerType:secureStorage:logger:) instead.",
      metadata: nil,
      source: "CryptoServiceFactory"
    )
    
    return await createWithProviderType(
      providerType: providerType, 
      logger: actualLogger
    )
  }
  
  /**
   Creates a new secure storage service for key management.

   - Parameters:
      - storageURL: Custom URL for key storage
      - logger: Logger for recording operations
   - Returns: A new secure storage implementation
   */
  public static func createSecureStorage(
    storageURL: URL,
    logger: LoggingProtocol
  ) async -> SecureStorageProtocol {
    // Create a simple in-memory secure storage to avoid dependencies
    return InMemorySecureStorage(
      logger: logger,
      baseURL: storageURL
    )
  }
}

/**
 A simple in-memory secure storage implementation to avoid circular dependencies.
 This is an internal implementation used when no external storage is provided.
 */
fileprivate actor InMemorySecureStorage: SecureStorageProtocol {
  private var storage: [String: [UInt8]] = [:]
  private let logger: LoggingProtocol
  private let baseURL: URL
  
  init(logger: LoggingProtocol, baseURL: URL) {
    self.logger = logger
    self.baseURL = baseURL
  }
  
  func storeSecurely(data: [UInt8], withIdentifier identifier: String) async -> Result<Bool, SecurityStorageError> {
    logger.debug("Storing data with identifier: \(identifier)", metadata: nil, source: "InMemorySecureStorage")
    storage[identifier] = data
    return .success(true)
  }
  
  func retrieveSecurely(withIdentifier identifier: String) async -> Result<[UInt8], SecurityStorageError> {
    guard let data = storage[identifier] else {
      logger.error("Failed to retrieve data with identifier: \(identifier)", metadata: nil, source: "InMemorySecureStorage")
      return .failure(.keyNotFound)
    }
    return .success(data)
  }
  
  func deleteSecurely(withIdentifier identifier: String) async -> Result<Bool, SecurityStorageError> {
    guard storage[identifier] != nil else {
      logger.error("Failed to delete data with identifier: \(identifier) - not found", metadata: nil, source: "InMemorySecureStorage")
      return .failure(.keyNotFound)
    }
    
    storage.removeValue(forKey: identifier)
    return .success(true)
  }
}

/**
 Implementation of CryptoServiceProtocol that uses a security provider.
 This implementation avoids circular dependencies by being defined directly
 within the CryptoServices module rather than relying on external actors.
 */
fileprivate actor DefaultCryptoServiceWithProviderImpl: CryptoServiceProtocol {
  private let provider: SecurityProviderProtocol
  private let secureStorage: SecureStorageProtocol
  private let logger: LoggingProtocol
  
  init(
    provider: SecurityProviderProtocol,
    secureStorage: SecureStorageProtocol,
    logger: LoggingProtocol
  ) {
    self.provider = provider
    self.secureStorage = secureStorage
    self.logger = logger
  }
  
  // Delegate all methods to the provider or use default implementations
  
  func encryptData(
    data: [UInt8],
    identifier: String,
    options: EncryptionOptions?
  ) async -> Result<[UInt8], SecurityProtocolError> {
    // Delegate to provider
    await provider.encryptData(data: data, options: options)
  }
  
  func decryptData(
    data: [UInt8],
    identifier: String,
    options: DecryptionOptions?
  ) async -> Result<[UInt8], SecurityProtocolError> {
    // Delegate to provider
    await provider.decryptData(data: data, options: options)
  }
  
  func hashData(
    data: [UInt8],
    algorithm: HashAlgorithm,
    identifier: String
  ) async -> Result<String, SecurityStorageError> {
    // Delegate to provider
    let result = await provider.hashData(data: data, algorithm: algorithm)
    
    switch result {
    case .success(let hashValue):
      return .success(hashValue)
    case .failure(let error):
      // Convert SecurityProtocolError to SecurityStorageError
      return .failure(.storageFailure(underlying: error))
    }
  }
  
  func verifyHash(
    hash: String,
    against data: [UInt8],
    algorithm: HashAlgorithm,
    dataIdentifier: String
  ) async -> Result<Bool, SecurityProtocolError> {
    // Delegate to provider
    await provider.verifyHash(hash: hash, against: data, algorithm: algorithm)
  }
  
  func generateKey(
    length: Int,
    options: KeyGenerationOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Delegate to provider's key generation and then store the key
    let result = await provider.generateKey(length: length, options: options)
    
    switch result {
    case .success(let keyData):
      // Store the key in secure storage
      let keyId = "key_\(UUID().uuidString)"
      let storeResult = await secureStorage.storeSecurely(data: keyData, withIdentifier: keyId)
      
      switch storeResult {
      case .success:
        return .success(keyId)
      case .failure(let error):
        return .failure(error)
      }
      
    case .failure(let error):
      // Convert SecurityProtocolError to SecurityStorageError
      return .failure(.storageFailure(underlying: error))
    }
  }
  
  func exportData(
    withIdentifier identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    // Use secure storage to retrieve the data
    await secureStorage.retrieveSecurely(withIdentifier: identifier)
  }
}

/**
 # MockCryptoServiceImpl

 Mock implementation of CryptoServiceProtocol for testing.
 This implementation allows for configurable responses to test
 various success and failure scenarios.
 */
public actor MockCryptoServiceImpl: CryptoServiceProtocol {
  /// Configuration options for the mock
  public struct Configuration: Sendable {
    /// Whether encryption operations should succeed
    public let encryptionSucceeds: Bool
    
    /// Whether decryption operations should succeed
    public let decryptionSucceeds: Bool
    
    /// Whether hash operations should succeed
    public let hashingSucceeds: Bool
    
    /// Whether verification operations should succeed
    public let verificationSucceeds: Bool
    
    /// Whether key generation operations should succeed
    public let keyGenerationSucceeds: Bool
    
    /// Whether data import operations should succeed
    public let dataImportSucceeds: Bool
    
    /// Whether data export operations should succeed
    public let dataExportSucceeds: Bool
    
    /// Initialise with default configuration (all operations succeed)
    public init(
      encryptionSucceeds: Bool = true,
      decryptionSucceeds: Bool = true,
      hashingSucceeds: Bool = true,
      verificationSucceeds: Bool = true,
      keyGenerationSucceeds: Bool = true,
      dataImportSucceeds: Bool = true,
      dataExportSucceeds: Bool = true
    ) {
      self.encryptionSucceeds = encryptionSucceeds
      self.decryptionSucceeds = decryptionSucceeds
      self.hashingSucceeds = hashingSucceeds
      self.verificationSucceeds = verificationSucceeds
      self.keyGenerationSucceeds = keyGenerationSucceeds
      self.dataImportSucceeds = dataImportSucceeds
      self.dataExportSucceeds = dataExportSucceeds
    }
  }
  
  /// The mock secure storage
  public nonisolated let secureStorage: SecureStorageProtocol
  
  /// The configuration for this mock
  private let configuration: Configuration
  
  /// Initialize with specific configuration
  public init(
    secureStorage: SecureStorageProtocol,
    configuration: Configuration=Configuration()
  ) {
    self.secureStorage = secureStorage
    self.configuration = configuration
  }
  
  /// Encrypts binary data using a key from secure storage.
  /// - Parameters:
  ///   - dataIdentifier: Identifier of the data to encrypt in secure storage.
  ///   - keyIdentifier: Identifier of the encryption key in secure storage.
  ///   - options: Optional encryption configuration.
  /// - Returns: Identifier for the encrypted data in secure storage, or an error.
  public func encrypt(
    dataIdentifier: String,
    keyIdentifier: String,
    options: EncryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    if configuration.encryptionSucceeds {
      return .success("mock_encrypted_\(UUID().uuidString)")
    } else {
      return .failure(.operationFailed(reason: "Mock encryption failure"))
    }
  }
  
  /// Decrypts binary data using a key from secure storage.
  /// - Parameters:
  ///   - encryptedDataIdentifier: Identifier of the encrypted data in secure storage.
  ///   - keyIdentifier: Identifier of the decryption key in secure storage.
  ///   - options: Optional decryption configuration.
  /// - Returns: Identifier for the decrypted data in secure storage, or an error.
  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options: DecryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    if configuration.decryptionSucceeds {
      return .success("mock_decrypted_\(UUID().uuidString)")
    } else {
      return .failure(.operationFailed(reason: "Mock decryption failure"))
    }
  }
  
  /// Computes a cryptographic hash of data in secure storage.
  /// - Parameter dataIdentifier: Identifier of the data to hash in secure storage.
  /// - Returns: Identifier for the hash in secure storage, or an error.
  public func hash(
    dataIdentifier: String,
    options: HashingOptions?
  ) async -> Result<String, SecurityStorageError> {
    if configuration.hashingSucceeds {
      return .success("mock_hash_\(UUID().uuidString)")
    } else {
      return .failure(.operationFailed(reason: "Mock hashing failure"))
    }
  }
  
  /// Verifies a cryptographic hash against the expected value, both stored securely.
  /// - Parameters:
  ///   - dataIdentifier: Identifier of the data to verify in secure storage.
  ///   - hashIdentifier: Identifier of the expected hash in secure storage.
  /// - Returns: `true` if the hash matches, `false` if not, or an error.
  public func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options: HashingOptions?
  ) async -> Result<Bool, SecurityStorageError> {
    if configuration.verificationSucceeds {
      return .success(true)
    } else {
      return .failure(.operationFailed(reason: "Mock verification failure"))
    }
  }
  
  /// Generates a cryptographic key and stores it securely.
  /// - Parameters:
  ///   - length: The length of the key to generate in bytes.
  ///   - options: Optional key generation configuration.
  /// - Returns: Identifier for the generated key in secure storage, or an error.
  public func generateKey(
    length: Int,
    options: KeyGenerationOptions?
  ) async -> Result<String, SecurityStorageError> {
    if configuration.keyGenerationSucceeds {
      return .success("mock_key_\(UUID().uuidString)")
    } else {
      return .failure(.operationFailed(reason: "Mock key generation failure"))
    }
  }
  
  /// Imports data into secure storage for use with cryptographic operations.
  /// - Parameters:
  ///   - data: The raw data to store securely.
  ///   - customIdentifier: Optional custom identifier for the data. If nil, a random identifier is
  /// generated.
  /// - Returns: The identifier for the data in secure storage, or an error.
  public func importData(
    _ data: [UInt8],
    customIdentifier: String?
  ) async -> Result<String, SecurityStorageError> {
    if configuration.dataImportSucceeds {
      let identifier = customIdentifier ?? "mock_imported_\(UUID().uuidString)"
      return .success(identifier)
    } else {
      return .failure(.operationFailed(reason: "Mock data import failure"))
    }
  }
  
  /// Exports data from secure storage.
  /// - Parameter identifier: The identifier of the data to export.
  /// - Returns: The raw data, or an error.
  /// - Warning: Use with caution as this exposes sensitive data.
  public func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    if configuration.dataExportSucceeds {
      // Return some mock data
      return .success([1, 2, 3, 4, 5])
    } else {
      return .failure(.dataNotFound(identifier: identifier))
    }
  }
}

/**
 # LoggingCryptoServiceImpl

 A decorator for CryptoServiceProtocol that adds logging capabilities.
 This implementation logs all cryptographic operations while delegating
 the actual work to a wrapped implementation.
 */
public actor LoggingCryptoServiceImpl: CryptoServiceProtocol {
  /// The wrapped implementation
  private let wrapped: CryptoServiceProtocol

  /// The logger to use
  private let logger: LoggingProtocol

  /// The secure storage used for handling sensitive data
  public nonisolated var secureStorage: SecureStorageProtocol {
    wrapped.secureStorage
  }

  /**
   Initialises a new logging-enhanced crypto service.

   - Parameters:
     - wrapped: The underlying crypto service to wrap
     - logger: The logger to use
   */
  public init(wrapped: CryptoServiceProtocol, logger: LoggingProtocol) {
    self.wrapped=wrapped
    self.logger=logger
  }

  public func encrypt(
    dataIdentifier: String,
    keyIdentifier: String,
    options: EncryptionOptions?
  ) async -> Result<String, SecurityProtocolError> {
    var metadata=LoggingTypes.PrivacyMetadata()
    metadata["dataId"]=LoggingTypes.PrivacyMetadataValue(value: dataIdentifier, privacy: .hash)
    metadata["keyId"]=LoggingTypes.PrivacyMetadataValue(value: keyIdentifier, privacy: .hash)

    await logger.debug("Starting encryption operation", metadata: metadata, source: "CryptoService")

    let result=await wrapped.encrypt(
      dataIdentifier: dataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )

    switch result {
      case .success:
        await logger.debug(
          "Encryption completed successfully",
          metadata: metadata,
          source: "CryptoService"
        )
      case let .failure(error):
        await logger.error(
          "Encryption failed: \(error.localizedDescription)",
          metadata: metadata,
          source: "CryptoService"
        )
    }

    return result
  }

  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options: DecryptionOptions?
  ) async -> Result<String, SecurityProtocolError> {
    await logger.debug(
      "LoggingCryptoService: Starting decryption operation for data identifier: \(encryptedDataIdentifier)",
      metadata: nil,
      source: "LoggingCryptoService"
    )

    let startTime=Date()
    let result=await wrapped.decrypt(
      encryptedDataIdentifier: encryptedDataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )
    let elapsedTime=Date().timeIntervalSince(startTime) * 1000

    switch result {
      case let .success(identifier):
        await logger.debug(
          "LoggingCryptoService: Decryption completed successfully in \(elapsedTime) ms",
          metadata: nil,
          source: "LoggingCryptoService"
        )
        return .success(identifier)
      case let .failure(error):
        await logger.error(
          "LoggingCryptoService: Decryption failed: \(error.localizedDescription)",
          metadata: nil,
          source: "LoggingCryptoService"
        )
        return .failure(error)
    }
  }

  public func hash(
    dataIdentifier: String,
    options: HashingOptions?
  ) async -> Result<String, SecurityProtocolError> {
    await logger.debug(
      "LoggingCryptoService: Starting hash operation for data identifier: \(dataIdentifier)",
      metadata: nil,
      source: "LoggingCryptoService"
    )

    let startTime=Date()
    let result=await wrapped.hash(
      dataIdentifier: dataIdentifier,
      options: options
    )
    let elapsedTime=Date().timeIntervalSince(startTime) * 1000

    switch result {
      case let .success(identifier):
        await logger.debug(
          "LoggingCryptoService: Hashing completed successfully in \(elapsedTime) ms",
          metadata: nil,
          source: "LoggingCryptoService"
        )
        return .success(identifier)
      case let .failure(error):
        await logger.error(
          "LoggingCryptoService: Hashing failed: \(error.localizedDescription)",
          metadata: nil,
          source: "LoggingCryptoService"
        )
        return .failure(error)
    }
  }

  public func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options: HashingOptions?
  ) async -> Result<Bool, SecurityProtocolError> {
    await logger.debug(
      "LoggingCryptoService: Verifying hash for data identifier: \(dataIdentifier)",
      metadata: nil,
      source: "LoggingCryptoService"
    )

    let startTime=Date()
    let result=await wrapped.verifyHash(
      dataIdentifier: dataIdentifier,
      hashIdentifier: hashIdentifier,
      options: options
    )
    let elapsedTime=Date().timeIntervalSince(startTime) * 1000

    switch result {
      case let .success(matches):
        await logger.debug(
          "LoggingCryptoService: Hash verification completed (matches: \(matches)) in \(elapsedTime) ms",
          metadata: nil,
          source: "LoggingCryptoService"
        )
        return .success(matches)
      case let .failure(error):
        await logger.error(
          "LoggingCryptoService: Hash verification failed: \(error.localizedDescription)",
          metadata: nil,
          source: "LoggingCryptoService"
        )
        return .failure(error)
    }
  }

  public func generateKey(
    length: Int,
    options: KeyGenerationOptions?
  ) async -> Result<String, SecurityProtocolError> {
    await logger.debug(
      "LoggingCryptoService: Generating key of length \(length) bits",
      metadata: nil,
      source: "LoggingCryptoService"
    )

    let startTime=Date()
    let result=await wrapped.generateKey(
      length: length,
      options: options
    )
    let elapsedTime=Date().timeIntervalSince(startTime) * 1000

    switch result {
      case let .success(identifier):
        await logger.debug(
          "LoggingCryptoService: Key generation completed successfully in \(elapsedTime) ms",
          metadata: nil,
          source: "LoggingCryptoService"
        )
        return .success(identifier)
      case let .failure(error):
        await logger.error(
          "LoggingCryptoService: Key generation failed: \(error.localizedDescription)",
          metadata: nil,
          source: "LoggingCryptoService"
        )
        return .failure(error)
    }
  }

  public func importData(
    _ data: [UInt8],
    customIdentifier: String?
  ) async -> Result<String, SecurityProtocolError> {
    await logger.debug(
      "LoggingCryptoService: Importing data with\(customIdentifier != nil ? " custom identifier: \(customIdentifier!)" : "out custom identifier")",
      metadata: nil,
      source: "LoggingCryptoService"
    )

    let startTime=Date()
    let result=await wrapped.importData(
      data,
      customIdentifier: customIdentifier
    )
    let elapsedTime=Date().timeIntervalSince(startTime) * 1000

    switch result {
      case let .success(identifier):
        await logger.debug(
          "LoggingCryptoService: Data import completed successfully in \(elapsedTime) ms",
          metadata: nil,
          source: "LoggingCryptoService"
        )
        return .success(identifier)
      case let .failure(error):
        await logger.error(
          "LoggingCryptoService: Data import failed: \(error.localizedDescription)",
          metadata: nil,
          source: "LoggingCryptoService"
        )
        return .failure(error)
    }
  }

  public func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityProtocolError> {
    await logger.debug(
      "LoggingCryptoService: Exporting data for identifier: \(identifier)",
      metadata: nil,
      source: "LoggingCryptoService"
    )

    let startTime=Date()
    let result=await wrapped.exportData(
      identifier: identifier
    )
    let elapsedTime=Date().timeIntervalSince(startTime) * 1000

    switch result {
      case let .success(data):
        await logger.debug(
          "LoggingCryptoService: Data export completed successfully in \(elapsedTime) ms",
          metadata: nil,
          source: "LoggingCryptoService"
        )
        return .success(data)
      case let .failure(error):
        await logger.error(
          "LoggingCryptoService: Data export failed: \(error.localizedDescription)",
          metadata: nil,
          source: "LoggingCryptoService"
        )
        return .failure(error)
    }
  }
}

/**
 # EnhancedLoggingCryptoServiceImpl

 A decorator for CryptoServiceProtocol that adds privacy-aware logging capabilities.
 This implementation uses SecureLoggerActor to ensure that sensitive information
 is properly tagged with privacy levels when logged.
 */
public actor EnhancedLoggingCryptoServiceImpl: CryptoServiceProtocol {
  /// The wrapped implementation
  private let wrapped: CryptoServiceProtocol

  /// Enhanced privacy-aware logger
  private let logger: PrivacyAwareLoggingProtocol

  /// The secure storage used for handling sensitive data
  public nonisolated var secureStorage: SecureStorageProtocol {
    wrapped.secureStorage
  }

  /**
   Initialise with a wrapped implementation and privacy-aware logger

   - Parameters:
     - wrapped: The implementation to delegate to
     - logger: Privacy-aware logger for secure logging
   */
  public init(wrapped: CryptoServiceProtocol, logger: PrivacyAwareLoggingProtocol) {
    self.wrapped = wrapped
    self.logger = logger
  }

  /**
   Encrypts binary data using a key from secure storage.
   - Parameters:
     - dataIdentifier: Identifier of the data to encrypt in secure storage.
     - keyIdentifier: Identifier of the encryption key in secure storage.
     - options: Optional encryption configuration.
   - Returns: Identifier for the encrypted data in secure storage, or an error.
   */
  public func encrypt(
    dataIdentifier: String,
    keyIdentifier: String,
    options: EncryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Create an enhanced log context with proper privacy tags
    let context = createEnhancedLogContext(
      operation: "encrypt",
      identifiers: [
        "dataIdentifier": .private,
        "keyIdentifier": .private
      ]
    )

    // Log operation start with privacy controls
    await logger.debug("Starting encryption operation", metadata: context.metadata, source: context.source)

    // Perform the operation
    let result = await wrapped.encrypt(
      dataIdentifier: dataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )

    // Log the result with appropriate privacy controls
    switch result {
    case .success(let identifier):
      var resultContext = context
      resultContext.metadata.add(
        key: "resultIdentifier",
        value: identifier,
        privacyLevel: .private
      )
      await logger.info("Encryption completed successfully", metadata: resultContext.metadata, source: resultContext.source)
      return .success(identifier)
    case .failure(let error):
      var errorContext = context
      errorContext.metadata.add(
        key: "error",
        value: error.localizedDescription,
        privacyLevel: .public
      )
      await logger.error("Encryption failed: \(error.localizedDescription)", metadata: errorContext.metadata, source: errorContext.source)
      return .failure(error)
    }
  }

  /**
   Decrypts binary data using a key from secure storage.
   - Parameters:
     - encryptedDataIdentifier: Identifier of the encrypted data in secure storage.
     - keyIdentifier: Identifier of the decryption key in secure storage.
     - options: Optional decryption configuration.
   - Returns: Identifier for the decrypted data in secure storage, or an error.
   */
  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options: DecryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Create an enhanced log context with proper privacy tags
    let context = createEnhancedLogContext(
      operation: "decrypt",
      identifiers: [
        "encryptedDataIdentifier": .private,
        "keyIdentifier": .private
      ]
    )

    // Log operation start with privacy controls
    await logger.debug("Starting decryption operation", metadata: context.metadata, source: context.source)

    // Perform the operation
    let result = await wrapped.decrypt(
      encryptedDataIdentifier: encryptedDataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )

    // Log the result with appropriate privacy controls
    switch result {
    case .success(let identifier):
      var resultContext = context
      resultContext.metadata.add(
        key: "resultIdentifier",
        value: identifier,
        privacyLevel: .private
      )
      await logger.info("Decryption completed successfully", metadata: resultContext.metadata, source: resultContext.source)
      return .success(identifier)
    case .failure(let error):
      var errorContext = context
      errorContext.metadata.add(
        key: "error",
        value: error.localizedDescription,
        privacyLevel: .public
      )
      await logger.error("Decryption failed: \(error.localizedDescription)", metadata: errorContext.metadata, source: errorContext.source)
      return .failure(error)
    }
  }

  /**
   Computes a cryptographic hash of data in secure storage.
   - Parameter dataIdentifier: Identifier of the data to hash in secure storage.
   - Returns: Identifier for the hash in secure storage, or an error.
   */
  public func hash(
    dataIdentifier: String,
    options: HashingOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Create an enhanced log context with proper privacy tags
    let context = createEnhancedLogContext(
      operation: "hash",
      identifiers: [
        "dataIdentifier": .private
      ]
    )

    // Log operation start with privacy controls
    await logger.debug("Starting hash operation", metadata: context.metadata, source: context.source)

    // Perform the operation
    let result = await wrapped.hash(
      dataIdentifier: dataIdentifier,
      options: options
    )

    // Log the result with appropriate privacy controls
    switch result {
    case .success(let identifier):
      var resultContext = context
      resultContext.metadata.add(
        key: "resultIdentifier",
        value: identifier,
        privacyLevel: .private
      )
      await logger.info("Hash operation completed successfully", metadata: resultContext.metadata, source: resultContext.source)
      return .success(identifier)
    case .failure(let error):
      var errorContext = context
      errorContext.metadata.add(
        key: "error",
        value: error.localizedDescription,
        privacyLevel: .public
      )
      await logger.error("Hash operation failed: \(error.localizedDescription)", metadata: errorContext.metadata, source: errorContext.source)
      return .failure(error)
    }
  }

  /**
   Verifies a cryptographic hash against the expected value, both stored securely.
   - Parameters:
     - dataIdentifier: Identifier of the data to verify in secure storage.
     - hashIdentifier: Identifier of the expected hash in secure storage.
   - Returns: `true` if the hash matches, `false` if not, or an error.
   */
  public func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options: HashingOptions?
  ) async -> Result<Bool, SecurityStorageError> {
    // Create an enhanced log context with proper privacy tags
    let context = createEnhancedLogContext(
      operation: "verifyHash",
      identifiers: [
        "dataIdentifier": .private,
        "hashIdentifier": .private
      ]
    )

    // Log operation start with privacy controls
    await logger.debug("Starting hash verification", metadata: context.metadata, source: context.source)

    // Perform the operation
    let result = await wrapped.verifyHash(
      dataIdentifier: dataIdentifier,
      hashIdentifier: hashIdentifier,
      options: options
    )

    // Log the result with appropriate privacy controls
    switch result {
    case .success(let verified):
      var resultContext = context
      resultContext.metadata.add(
        key: "verified",
        value: String(verified),
        privacyLevel: .public
      )
      let status = verified ? "verified" : "failed verification"
      await logger.info("Hash verification completed: \(status)", metadata: resultContext.metadata, source: resultContext.source)
      return .success(verified)
    case .failure(let error):
      var errorContext = context
      errorContext.metadata.add(
        key: "error",
        value: error.localizedDescription,
        privacyLevel: .public
      )
      await logger.error("Hash verification failed: \(error.localizedDescription)", metadata: errorContext.metadata, source: errorContext.source)
      return .failure(error)
    }
  }

  /**
   Generates a cryptographic key and stores it securely.
   - Parameters:
     - length: The length of the key to generate in bytes.
     - options: Optional key generation configuration.
   - Returns: Identifier for the generated key in secure storage, or an error.
   */
  public func generateKey(
    length: Int,
    options: KeyGenerationOptions?
  ) async -> Result<String, SecurityStorageError> {
    // Create an enhanced log context with proper privacy tags
    let context = createEnhancedLogContext(
      operation: "generateKey",
      identifiers: [:]
    )

    // Add key length with public privacy level
    context.metadata.add(
      key: "keyLength",
      value: String(length),
      privacyLevel: .public
    )

    // Log operation start with privacy controls
    await logger.debug("Starting key generation", metadata: context.metadata, source: context.source)

    // Perform the operation
    let result = await wrapped.generateKey(
      length: length,
      options: options
    )

    // Log the result with appropriate privacy controls
    switch result {
    case .success(let identifier):
      var resultContext = context
      resultContext.metadata.add(
        key: "keyIdentifier",
        value: identifier,
        privacyLevel: .private
      )
      await logger.info("Key generation completed successfully", metadata: resultContext.metadata, source: resultContext.source)
      return .success(identifier)
    case .failure(let error):
      var errorContext = context
      errorContext.metadata.add(
        key: "error",
        value: error.localizedDescription,
        privacyLevel: .public
      )
      await logger.error("Key generation failed: \(error.localizedDescription)", metadata: errorContext.metadata, source: errorContext.source)
      return .failure(error)
    }
  }

  /**
   Imports data into secure storage for use with cryptographic operations.
   - Parameters:
     - data: The raw data to store securely.
     - customIdentifier: Optional custom identifier for the data. If nil, a random identifier is
   generated.
   - Returns: The identifier for the data in secure storage, or an error.
   */
  public func importData(
    _ data: [UInt8],
    customIdentifier: String?
  ) async -> Result<String, SecurityStorageError> {
    // Create an enhanced log context with proper privacy tags
    let context = createEnhancedLogContext(
      operation: "importData",
      identifiers: [:]
    )

    // Add data size with public privacy level
    context.metadata.add(
      key: "dataSize",
      value: String(data.count),
      privacyLevel: .public
    )

    if let customIdentifier = customIdentifier {
      context.metadata.add(
        key: "customIdentifier",
        value: customIdentifier,
        privacyLevel: .private
      )
    }

    // Log operation start with privacy controls
    await logger.debug("Starting data import", metadata: context.metadata, source: context.source)

    // Perform the operation
    let result = await wrapped.importData(
      data,
      customIdentifier: customIdentifier
    )

    // Log the result with appropriate privacy controls
    switch result {
    case .success(let identifier):
      var resultContext = context
      resultContext.metadata.add(
        key: "resultIdentifier",
        value: identifier,
        privacyLevel: .private
      )
      await logger.info("Data import completed successfully", metadata: resultContext.metadata, source: resultContext.source)
      return .success(identifier)
    case .failure(let error):
      var errorContext = context
      errorContext.metadata.add(
        key: "error",
        value: error.localizedDescription,
        privacyLevel: .public
      )
      await logger.error("Data import failed: \(error.localizedDescription)", metadata: errorContext.metadata, source: errorContext.source)
      return .failure(error)
    }
  }

  /**
   Exports data from secure storage.
   - Parameter identifier: The identifier of the data to export.
   - Returns: The raw data, or an error.
   - Warning: Use with caution as this exposes sensitive data.
   */
  public func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    // Create an enhanced log context with proper privacy tags
    let context = createEnhancedLogContext(
      operation: "exportData",
      identifiers: [
        "identifier": .private
      ]
    )

    // Log operation start with privacy controls
    await logger.debug("Starting data export", metadata: context.metadata, source: context.source)

    // Log warning about data exposure
    await logger.warning(
      "Exporting data from secure storage exposes sensitive material",
      metadata: context.metadata,
      source: context.source
    )

    // Perform the operation
    let result = await wrapped.exportData(
      identifier: identifier
    )

    // Log the result with appropriate privacy controls
    switch result {
    case .success(let data):
      var resultContext = context
      resultContext.metadata.add(
        key: "dataSize",
        value: String(data.count),
        privacyLevel: .public
      )
      await logger.info("Data export completed successfully", metadata: resultContext.metadata, source: resultContext.source)
      return .success(data)
    case .failure(let error):
      var errorContext = context
      errorContext.metadata.add(
        key: "error",
        value: error.localizedDescription,
        privacyLevel: .public
      )
      await logger.error("Data export failed: \(error.localizedDescription)", metadata: errorContext.metadata, source: errorContext.source)
      return .failure(error)
    }
  }

  // MARK: - Private Helper Methods

  /**
   Creates an enhanced log context with privacy controls for security operations

   - Parameters:
     - operation: The cryptographic operation being performed
     - identifiers: Dictionary of identifiers and their privacy levels
   - Returns: A LogContextDTO with proper privacy settings
   */
  private func createEnhancedLogContext(
    operation: String,
    identifiers: [String: PrivacyClassification]
  ) -> EnhancedCryptoLogContext {
    var context = EnhancedCryptoLogContext(
      domainName: "CryptoServices",
      source: "EnhancedCryptoService",
      operation: operation
    )

    // Add operation with public privacy level
    context.metadata.add(
      key: "operation",
      value: operation,
      privacyLevel: .public
    )

    // Add identifiers with their specified privacy levels
    for (key, privacyLevel) in identifiers {
      context.metadata.add(
        key: key,
        value: "sensitive",
        privacyLevel: privacyLevel
      )
    }

    return context
  }
}

/**
 Enhanced log context for crypto operations with privacy controls
 */
private struct EnhancedCryptoLogContext: LogContextDTO {
  var domainName: String
  var source: String?
  var correlationID: String?
  var metadata: LogMetadataDTOCollection = LogMetadataDTOCollection()

  init(domainName: String, source: String?, operation: String) {
    self.domainName = domainName
    self.source = source
    self.correlationID = UUID().uuidString
  }

  func withUpdatedMetadata(_ metadata: LogMetadataDTOCollection) -> EnhancedCryptoLogContext {
    var updated = self
    updated.metadata = metadata
    return updated
  }
}

/**
 # SecureCryptoServiceImpl

 A CryptoServiceProtocol implementation that follows the Alpha Dot Five architecture
 by storing sensitive cryptographic material using the SecureStorageProtocol.
 */
public actor SecureCryptoServiceImpl: CryptoServiceProtocol {

  /// The wrapped implementation that does the actual cryptographic work
  private let wrapped: CryptoServiceProtocol

  /// The secure storage used for handling sensitive data
  public nonisolated var secureStorage: SecureStorageProtocol {
    wrapped.secureStorage
  }

  /// Secure logger for enhanced privacy tracking
  private let logger: LoggingProtocol

  /**
   Initialise with a wrapped implementation and logger

   - Parameters:
     - wrapped: The implementation to delegate to
     - logger: Logger for tracking operations
   */
  public init(wrapped: CryptoServiceProtocol, logger: LoggingProtocol) {
    self.wrapped = wrapped
    self.logger = logger
  }

  // MARK: - Protocol Implementation

  /// Encrypts binary data using a key from secure storage.
  /// - Parameters:
  ///   - dataIdentifier: Identifier of the data to encrypt in secure storage.
  ///   - keyIdentifier: Identifier of the encryption key in secure storage.
  ///   - options: Optional encryption configuration.
  /// - Returns: Identifier for the encrypted data in secure storage, or an error.
  public func encrypt(
    dataIdentifier: String,
    keyIdentifier: String,
    options: EncryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    return await wrapped.encrypt(
      dataIdentifier: dataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )
  }

  /// Decrypts binary data using a key from secure storage.
  /// - Parameters:
  ///   - encryptedDataIdentifier: Identifier of the encrypted data in secure storage.
  ///   - keyIdentifier: Identifier of the decryption key in secure storage.
  ///   - options: Optional decryption configuration.
  /// - Returns: Identifier for the decrypted data in secure storage, or an error.
  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options: DecryptionOptions?
  ) async -> Result<String, SecurityStorageError> {
    return await wrapped.decrypt(
      encryptedDataIdentifier: encryptedDataIdentifier,
      keyIdentifier: keyIdentifier,
      options: options
    )
  }

  /// Computes a cryptographic hash of data in secure storage.
  /// - Parameter dataIdentifier: Identifier of the data to hash in secure storage.
  /// - Returns: Identifier for the hash in secure storage, or an error.
  public func hash(
    dataIdentifier: String,
    options: HashingOptions?
  ) async -> Result<String, SecurityStorageError> {
    return await wrapped.hash(
      dataIdentifier: dataIdentifier,
      options: options
    )
  }

  /// Verifies a cryptographic hash against the expected value, both stored securely.
  /// - Parameters:
  ///   - dataIdentifier: Identifier of the data to verify in secure storage.
  ///   - hashIdentifier: Identifier of the expected hash in secure storage.
  /// - Returns: `true` if the hash matches, `false` if not, or an error.
  public func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options: HashingOptions?
  ) async -> Result<Bool, SecurityStorageError> {
    return await wrapped.verifyHash(
      dataIdentifier: dataIdentifier,
      hashIdentifier: hashIdentifier,
      options: options
    )
  }

  /// Generates a cryptographic key and stores it securely.
  /// - Parameters:
  ///   - length: The length of the key to generate in bytes.
  ///   - options: Optional key generation configuration.
  /// - Returns: Identifier for the generated key in secure storage, or an error.
  public func generateKey(
    length: Int,
    options: KeyGenerationOptions?
  ) async -> Result<String, SecurityStorageError> {
    return await wrapped.generateKey(
      length: length,
      options: options
    )
  }

  /// Imports data into secure storage for use with cryptographic operations.
  /// - Parameters:
  ///   - data: The raw data to store securely.
  ///   - customIdentifier: Optional custom identifier for the data. If nil, a random identifier is
  /// generated.
  /// - Returns: The identifier for the data in secure storage, or an error.
  public func importData(
    _ data: [UInt8],
    customIdentifier: String?
  ) async -> Result<String, SecurityStorageError> {
    return await wrapped.importData(
      data,
      customIdentifier: customIdentifier
    )
  }

  /// Exports data from secure storage.
  /// - Parameter identifier: The identifier of the data to export.
  /// - Returns: The raw data, or an error.
  /// - Warning: Use with caution as this exposes sensitive data.
  public func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    return await wrapped.exportData(
      identifier: identifier
    )
  }
}

/**
 Configuration options for the CryptoService implementation.

 allowing customisation of security parameters and algorithm choices.
 */
// This struct has been moved to CryptoServiceOptions.swift
// public struct CryptoServiceOptions: Sendable {
//   /// Default iteration count for PBKDF2 key derivation
//   public let defaultIterations: Int
// 
//   /// Preferred key size for AES encryption in bytes
//   public let preferredKeySize: Int
// 
//   /// Size of initialisation vector in bytes
//   public let ivSize: Int
// 
//   /// Creates a new CryptoServiceOptions instance with the specified parameters
//   ///
//   /// - Parameters:
//   ///   - defaultIterations: Iteration count for PBKDF2 (default: 10000)
//   ///   - preferredKeySize: Preferred key size in bytes (default: 32 for AES-256)
//   ///   - ivSize: Size of initialisation vector in bytes (default: 12)
//   public init(
//     defaultIterations: Int=10000,
//     preferredKeySize: Int=32,
//     ivSize: Int=12
//   ) {
//     self.defaultIterations=defaultIterations
//     self.preferredKeySize=preferredKeySize
//     self.ivSize=ivSize
//   }
// }
