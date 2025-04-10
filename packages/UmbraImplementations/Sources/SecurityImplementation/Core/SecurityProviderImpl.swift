import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingServices
import LoggingTypes
import SecurityCoreInterfaces
import UmbraErrors

/**
 Creates a log context from a metadata dictionary.
 
 - Parameter metadata: Dictionary of metadata values
 - Parameter domain: Domain name for the log context
 - Parameter source: Source identifier for the log context
 - Returns: A BaseLogContextDTO with proper privacy tagging
 */
private func createLogContext(
  _ metadata: [String: (value: String, privacy: LogPrivacyLevel)],
  domain: String = "SecurityServices",
  source: String = "SecurityProviderService"
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
    }
  }
  
  return BaseLogContextDTO(
    domainName: domain,
    source: source,
    metadata: collection
  )
}

/**
 # Security Provider Service (Canonical Implementation)

 Actor-based implementation of the SecurityProviderProtocol, providing
 a secure interface to all cryptographic and key management services at the core infrastructure level.
 This is the canonical implementation for the Alpha Dot Five architecture.

 ## Concurrency

 Uses Swift's actor model to ensure thread safety for all security operations,
 preventing data races and ensuring security invariants are maintained.

 ## Security

 Centralises access control, encryption, signing, and key management through
 a unified interface with comprehensive logging and error handling.

 ## Privacy-Aware Logging

 Implements privacy-aware logging to ensure that sensitive information is properly tagged 
 with privacy levels according to the Alpha Dot Five architecture principles.
 */
// Using @preconcurrency to resolve protocol conformance issues with isolated methods
@preconcurrency
public actor SecurityProviderService: SecurityProviderProtocol, AsyncServiceInitializable {
  // MARK: - Dependencies

  /**
   The cryptographic service used for operations

   Required by the SecurityProviderProtocol
   */
  public let cryptoService: SecurityCoreInterfaces.CryptoServiceProtocol

  /**
   The key management service used for key operations

   Required by the SecurityProviderProtocol
   */
  public let keyManager: KeyManagementProtocol

  /**
   The standard logger instance for recording general operation details
   */
  let logger: LoggingInterfaces.LoggingProtocol

  // MARK: - Service Components

  /**
   The encryption service for handling encryption/decryption operations
   */
  private let encryptionService: EncryptionService

  /**
   The signature service for handling sign/verify operations
   */
  private let signatureService: SignatureService

  /**
   The secure storage service for handling key persistence
   */
  private let storageService: SecureStorageService

  /**
   The hashing service for handling hashing operations
   */
  private let hashingService: HashingService

  /**
   Temporary data storage for operations
   */
  private var operationData: [String: [UInt8]] = [:]

  /**
   Service initialisation state
   */
  private var isInitialized = false

  /**
   Initialises the security provider with the specified dependencies

   - Parameters:
     - cryptoService: Service for cryptographic operations
     - keyManager: Service for key management
     - logger: Logger for general operation details
   */
  public init(
    cryptoService: SecurityCoreInterfaces.CryptoServiceProtocol,
    keyManager: KeyManagementProtocol,
    logger: LoggingInterfaces.LoggingProtocol
  ) {
    self.cryptoService = cryptoService
    self.keyManager = keyManager
    self.logger = logger

    // Create service components
    encryptionService = EncryptionService(
      cryptoService: cryptoService,
      logger: logger
    )

    signatureService = SignatureService(
      cryptoService: cryptoService,
      keyManagementService: keyManager,
      logger: logger
    )

    storageService = SecureStorageService(
      logger: logger
    )

    hashingService = HashingService(
      cryptoService: cryptoService,
      logger: logger
    )

    // Log initialisation
    Task {
      let context = createLogContext([
        "operation": (value: "start", privacy: .public),
        "provider": (value: "SecurityProviderService", privacy: .public)
      ])
      
      await logger.debug(
        "Initialising Security Provider Service",
        context: context
      )
    }
  }

  /**
   Asynchronous initialisation method required by AsyncServiceInitializable protocol

   - Throws: SecurityError if initialisation fails
   */
  public func initialize() async throws {
    // Perform any async initialisation steps here
    // In this case, we don't need any additional async init
    
    let context = createLogContext([
      "operation": (value: "complete", privacy: .public),
      "provider": (value: "SecurityProviderService", privacy: .public)
    ])
    
    await logger.debug(
      "Security Provider Service initialisation complete",
      context: context
    )
    
    isInitialized = true
  }

  /**
   Encrypts data with the specified configuration

   - Parameter config: Configuration for the encryption operation
   - Returns: Result containing encrypted data or error information
   - Throws: SecurityError if encryption fails
   */
  public func encrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    try await encryptionService.encrypt(config: config)
  }

  /**
   Decrypts data with the specified configuration

   - Parameter config: Configuration for the decryption operation
   - Returns: Result containing decrypted data or error information
   - Throws: SecurityError if decryption fails
   */
  public func decrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    try await encryptionService.decrypt(config: config)
  }

  /**
   Signs data with the specified configuration

   - Parameter config: Configuration for the signing operation
   - Returns: Result containing signature data or error information
   - Throws: SecurityError if signing fails
   */
  public func sign(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    try await signatureService.sign(config: config)
  }

  /**
   Verifies a signature with the specified configuration

   - Parameter config: Configuration for the verification operation
   - Returns: Result containing verification status or error information
   - Throws: SecurityError if verification fails
   */
  public func verify(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    try await signatureService.verify(config: config)
  }

  /**
   Hashes data with the specified configuration

   - Parameter config: Configuration for the hashing operation
   - Returns: Result containing hash data or error information
   - Throws: SecurityError if hashing fails
   */
  public func hash(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    try await hashingService.hash(config: config)
  }

  /**
   Gets the key manager service instance

   - Returns: The key manager service
   */
  public func getKeyManager() -> KeyManagementProtocol {
    keyManager
  }

  /**
   Retrieves a key for a specific operation

   - Parameters:
     - identifier: Key identifier
     - operation: Security operation requiring the key
   - Returns: Key data as byte array
   - Throws: SecurityError if key retrieval fails
   */
  public func getKey(
    identifier: String,
    operation: SecurityOperation
  ) async throws -> [UInt8]? {
    let context = createLogContext([
      "operation": (value: operation.rawValue, privacy: .public),
      "keyIdentifier": (value: identifier, privacy: .private)
    ])
    
    await logger.debug(
      "Retrieving key for operation",
      context: context
    )

    // Delegate to key manager
    return try await keyManager.getKey(identifier: identifier)
  }

  /**
   Performs a secure operation with the specified configuration

   This is a higher-level method that selects the appropriate operation based on the
   configuration operationType field, providing a unified interface for security operations.

   - Parameter config: Configuration for the security operation
   - Returns: Result containing operation output or error information
   - Throws: SecurityError if the operation fails
   */
  public func performSecureOperation(
    config: SecurityConfigDTO
  ) async throws -> SecurityResultDTO {
    let operationID = UUID().uuidString
    let startTime = Date()

    // Create operating context
    let context = createLogContext([
      "operationId": (value: operationID, privacy: .public),
      "operation": (value: "start", privacy: .public),
      "operationType": (value: config.operationType.rawValue, privacy: .public),
      "dataSize": (value: String(config.inputData?.count ?? 0), privacy: .public),
      "hasKey": (value: String(config.keyIdentifier != nil), privacy: .public)
    ])
    
    await logger.debug(
      "Starting secure operation: \(config.operationType.rawValue)",
      context: context
    )

    do {
      // Select operation based on type
      let result: SecurityResultDTO
      switch config.operationType {
      case .encrypt:
        result = try await encrypt(config: config)
      case .decrypt:
        result = try await decrypt(config: config)
      case .sign:
        result = try await sign(config: config)
      case .verify:
        result = try await verify(config: config)
      case .hash:
        result = try await hash(config: config)
      case .generate:
        result = try await generateKey(config: config)
      case .store:
        result = try await secureStore(config: config)
      case .retrieve:
        result = try await secureRetrieve(config: config)
      }

      // Calculate duration for metrics
      let duration = Date().timeIntervalSince(startTime)

      // Log success
      let successContext = createLogContext([
        "operationId": (value: operationID, privacy: .public),
        "operation": (value: "complete", privacy: .public),
        "durationMs": (value: String(Int(duration * 1000)), privacy: .public),
        "resultSize": (value: String(result.data?.count ?? 0), privacy: .public)
      ])
      
      await logger.debug(
        "Secure operation completed successfully",
        context: successContext
      )

      return result
    } catch {
      // Calculate duration for metrics
      let duration = Date().timeIntervalSince(startTime)

      // Log failure
      let errorContext = createLogContext([
        "operationId": (value: operationID, privacy: .public),
        "operation": (value: "error", privacy: .public),
        "durationMs": (value: String(Int(duration * 1000)), privacy: .public),
        "errorType": (value: String(describing: type(of: error)), privacy: .public),
        "errorDescription": (value: error.localizedDescription, privacy: .private)
      ])
      
      await logger.error(
        "Secure operation failed: \(config.operationType.rawValue)",
        context: errorContext
      )

      // Map to security error and re-throw
      if let secError = error as? SecurityError {
        throw secError
      } else {
        throw SecurityError.operationError(
          "Operation failed: \(error.localizedDescription)"
        )
      }
    }
  }

  /**
   Generates a cryptographic key with the specified configuration

   - Parameter config: Configuration for the key generation operation
   - Returns: Result containing key data or error information
   - Throws: SecurityError if key generation fails
   */
  public func generateKey(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    // Create operation ID for tracing
    let operationID = UUID().uuidString
    let startTime = Date()

    // Log start of operation
    let context = createLogContext([
      "operationId": (value: operationID, privacy: .public),
      "operation": (value: "start", privacy: .public),
      "operationType": (value: config.operationType.rawValue, privacy: .public),
      "dataSize": (value: String(config.inputData?.count ?? 0), privacy: .public),
      "hasKey": (value: String(config.keyIdentifier != nil), privacy: .public)
    ])
    
    await logger.debug(
      "Starting key generation operation",
      context: context
    )

    do {
      // Extract key size if provided
      let keySize: Int
      if let keySizeStr = config.options?.metadata?["keySize"], let size = Int(keySizeStr) {
        keySize = size
      } else {
        // Default to 256-bit key
        keySize = 256
      }

      // Generate key using the key manager
      let keyData = try await keyManager.generateKey(size: keySize)

      // Store the key if an identifier is provided
      if let keyIdentifier = config.keyIdentifier {
        try await keyManager.storeKey(keyData, withIdentifier: keyIdentifier)
      }

      // Calculate duration for metrics
      let duration = Date().timeIntervalSince(startTime)

      // Log success
      let successContext = createLogContext([
        "operationId": (value: operationID, privacy: .public),
        "operation": (value: "complete", privacy: .public),
        "durationMs": (value: String(Int(duration * 1000)), privacy: .public),
        "keySize": (value: String(keySize), privacy: .public)
      ])
      
      await logger.debug(
        "Key generation completed successfully",
        context: successContext
      )

      // Return result
      return SecurityResultDTO(
        operationID: operationID,
        data: Data(keyData),
        status: .success,
        metadata: nil
      )
    } catch {
      // Calculate duration for metrics
      let duration = Date().timeIntervalSince(startTime)

      // Log failure
      let errorContext = createLogContext([
        "operationId": (value: operationID, privacy: .public),
        "operation": (value: "error", privacy: .public),
        "durationMs": (value: String(Int(duration * 1000)), privacy: .public),
        "errorType": (value: String(describing: type(of: error)), privacy: .public),
        "errorDescription": (value: error.localizedDescription, privacy: .private)
      ])
      
      await logger.error(
        "Key generation failed",
        context: errorContext
      )

      // Rethrow as security error
      if let secError = error as? SecurityError {
        throw secError
      } else {
        throw SecurityError.keyGenerationError(
          "Key generation failed: \(error.localizedDescription)"
        )
      }
    }
  }

  /**
   Stores data securely with the specified configuration

   - Parameter config: Configuration for the storage operation
   - Returns: Result containing operation status or error information
   - Throws: SecurityError if storage fails
   */
  public func secureStore(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    try await storageService.store(config: config)
  }

  /**
   Retrieves data securely with the specified configuration

   - Parameter config: Configuration for the retrieval operation
   - Returns: Result containing retrieved data or error information
   - Throws: SecurityError if retrieval fails
   */
  public func secureRetrieve(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    try await storageService.retrieve(config: config)
  }

  /**
   Performs a secure operation with data, key, and options

   - Parameters:
     - operation: The security operation to perform
     - data: The data to operate on
     - key: The key to use for the operation
     - options: Additional options for the operation
   - Returns: The result of the operation
   */
  public func performSecureOperation(
    operation: SecurityOperation,
    data: Data?,
    key: String?,
    options: SecurityConfigOptions?
  ) async -> SecurityResultDTO {
    // Create configuration from parameters
    let config = SecurityConfigDTO(
      operationType: operation,
      inputData: data,
      keyIdentifier: key,
      options: options
    )
    
    do {
      // Delegate to the standard operation method
      return try await performSecureOperation(
        config: config
      )
    } catch {
      // Handle errors and convert to result
      return SecurityResultDTO(
        success: false,
        resultData: nil,
        executionTimeMs: 0,
        metadata: [
          "operation": operation.rawValue,
          "error": error.localizedDescription
        ]
      )
    }
  }

  /**
   Creates a secure configuration with the specified options.
   
   - Parameter options: The options for the configuration
   - Returns: A secure configuration with the specified options
   */
  public func createSecureConfig(options: SecurityConfigOptions) async -> SecurityConfigDTO {
    return SecurityConfigDTO(
      encryptionAlgorithm: .aes256GCM,
      hashAlgorithm: .sha256,
      providerType: .default,
      options: options
    )
  }

  /**
   Performs a secure operation with the specified configuration.
   
   This method is part of the SecurityProviderProtocol and is required for conformance.
   It delegates to appropriate service implementations based on the operation type.

   - Parameters:
     - operation: The type of security operation to perform
     - config: Configuration for the operation
   - Returns: Result of the operation
   - Throws: SecurityProtocolError if validation fails
   */
  public func performSecureOperation(
    operation: SecurityOperation,
    config: SecurityConfigDTO
  ) async throws -> SecurityResultDTO {
    // Log operation start
    await logOperationStart(operation: operation, config: config)
    
    do {
      // Validate the configuration for this operation
      try await validateConfiguration(operation: operation, config: config)
      
      // Process the operation based on type
      switch operation {
      case .encrypt:
        return try await encryptionService.encrypt(config: config)
      case .decrypt:
        return try await encryptionService.decrypt(config: config)
      case .hash:
        return try await hashingService.hash(config: config)
      case .sign:
        return await signatureService.sign(config: config)
      case .verify:
        return await signatureService.verify(config: config)
      case .secure:
        return try await storageService.secureStore(config: config)
      case .retrieve:
        return try await storageService.secureRetrieve(config: config)
      default:
        throw SecurityProtocolError.unsupportedOperation(
          "Operation \(operation) is not supported by this provider"
        )
      }
    } catch {
      // Log operation failure
      await logOperationFailure(operation: operation, error: error)
      
      // Return appropriate error
      throw error
    }
  }

  // MARK: - Protocol Conformance Methods
  
  /// Get the crypto service
  /// - Returns: The crypto service
  public func cryptoService() async -> any CryptoServiceProtocol {
    return self.cryptoService
  }
  
  /// Get the key manager
  /// - Returns: The key manager
  public func keyManager() async -> any KeyManagementProtocol {
    return self.keyManager
  }
  
  /// Securely delete data
  /// - Parameter config: The configuration for the deletion operation
  /// - Returns: The result of the deletion operation
  public func secureDelete(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    // Create a sanitized copy of the configuration
    let sanitizedConfig = config
    
    // Log the operation start
    await logOperationStart(
      operation: .secureDelete,
      config: sanitizedConfig
    )
    
    let startTime = Date()
    
    // Perform the secure deletion
    // This is a placeholder implementation that should be replaced
    // with actual secure deletion logic
    let result = SecurityResultDTO(
      success: true,
      resultData: nil,
      executionTimeMs: Date().timeIntervalSince(startTime) * 1000,
      metadata: [
        "operation": "secureDelete",
        "status": "success"
      ]
    )
    
    // Log the operation completion
    await logOperationCompletion(
      operation: .secureDelete,
      result: result
    )
    
    return result
  }
}
