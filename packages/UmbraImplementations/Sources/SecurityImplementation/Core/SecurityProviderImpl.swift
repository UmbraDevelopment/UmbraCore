import Foundation
import LoggingInterfaces
import SecurityCoreInterfaces
import CoreSecurityTypes

/**
 # Core Security Provider Service

 Actor-based implementation of the SecurityProviderProtocol, providing
 a secure interface to all cryptographic and key management services at the core infrastructure level.

 ## Concurrency

 Uses Swift's actor model to ensure thread safety for all security operations,
 preventing data races and ensuring security invariants are maintained.

 ## Security

 Centralises access control, encryption, signing, and key management through
 a unified interface with comprehensive logging and error handling.
 */
// Using @preconcurrency to resolve protocol conformance issues with isolated methods
@preconcurrency
public actor CoreSecurityProviderService: SecurityProviderProtocol, AsyncServiceInitializable {
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
   The logger instance for recording operation details
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
   Initializes the security provider with all required services.

   - Parameters:
     - cryptoService: Service for cryptographic operations
     - keyManager: Service for key management operations
     - logger: Logger for security operations
   */
  public init(
    cryptoService: SecurityCoreInterfaces.CryptoServiceProtocol,
    keyManager: KeyManagementProtocol,
    logger: LoggingInterfaces.LoggingProtocol
  ) {
    self.cryptoService = cryptoService
    self.keyManager = keyManager
    self.logger = logger

    // Initialize component services
    self.encryptionService = EncryptionService(
      cryptoService: cryptoService,
      logger: logger
    )
    
    self.hashingService = HashingService(
      cryptoService: cryptoService,
      logger: logger
    )
    
    self.signatureService = SignatureService(
      cryptoService: cryptoService,
      keyManagementService: keyManager,
      logger: logger
    )

    // Initialise the secure storage service
    self.storageService = SecureStorageService(
      cryptoService: cryptoService,
      logger: logger
    )
  }

  /**
   Initializes the security provider service.
   
   This method performs any necessary setup that must occur before the service
   is ready for use, including initializing dependencies and verifying security configuration.
   
   - Throws: Error if initialization fails
   */
  public func initialize() async throws {
    await logger.info("Initializing security provider service")
    
    // Initialize dependencies
    try await cryptoService.initialize()
    try await keyManager.initialize()
    
    await logger.info("Security provider service initialized successfully")
  }

  // MARK: - SecurityProviderProtocol Implementation

  /**
   Provides access to the cryptographic service.

   - Returns: The cryptographic service instance
   */
  public func cryptoService() async -> SecurityCoreInterfaces.CryptoServiceProtocol {
    cryptoService
  }

  /**
   Provides access to the key management service.

   - Returns: The key management service instance
   */
  public func keyManager() async -> KeyManagementProtocol {
    keyManager
  }

  /**
   Encrypts data with the specified configuration.

   Delegates to the encryption service for implementation.

   - Parameter config: Configuration for the encryption operation
   - Returns: Result containing encrypted data or error
   */
  public func encrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    try await encryptionService.encrypt(config: config)
  }

  /**
   Decrypts data with the specified configuration.

   Delegates to the encryption service for implementation.

   - Parameter config: Configuration for the decryption operation
   - Returns: Result containing decrypted data or error
   */
  public func decrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    try await encryptionService.decrypt(config: config)
  }

  /**
   Generates a cryptographic key with the specified configuration.

   Delegates to the key management service for implementation.

   - Parameter config: Configuration for the key generation operation
   - Returns: Result containing key identifier or error
   */
  public func generateKey(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    // Log the operation
    await logger.info(
      "Generating cryptographic key",
      metadata: ["keyType": config.keyType.rawValue],
      source: "CoreSecurityProvider"
    )

    // Process the request through the key management service
    let result = try await keyManager.generateKey(
      type: config.keyType,
      size: config.keySize,
      metadata: config.metadata
    )

    // Create result data
    let resultDTO = SecurityResultDTO(
      status: .success,
      data: Data(result.identifier.utf8),
      metadata: ["keyType": config.keyType.rawValue, "keySize": String(config.keySize)]
    )

    // Log completion
    await logger.info(
      "Key generation completed successfully",
      metadata: ["keyType": config.keyType.rawValue],
      source: "CoreSecurityProvider"
    )

    return resultDTO
  }

  /**
   Signs data with the specified configuration

   Delegates to the signature service for implementation.

   - Parameter config: Configuration for the signing operation
   - Returns: Result containing signature or error
   */
  public func sign(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    try await signatureService.sign(config: config)
  }

  /**
   Verifies a signature with the specified configuration

   Delegates to the signature service for implementation.

   - Parameter config: Configuration for the verification operation
   - Returns: Result containing verification status or error
   */
  public func verify(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    try await signatureService.verify(config: config)
  }

  /**
   Stores data securely with the specified configuration

   Delegates to the secure storage service for implementation.

   - Parameter config: Configuration for the storage operation
   - Returns: Result containing operation status or error
   */
  public func store(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    try await storageService.store(config: config)
  }

  /**
   Retrieves data securely with the specified configuration

   Delegates to the secure storage service for implementation.

   - Parameter config: Configuration for the retrieval operation
   - Returns: Result containing retrieved data or error
   */
  public func retrieve(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    try await storageService.retrieve(config: config)
  }

  /**
   Securely stores data with the specified configuration.
   
   - Parameter config: Configuration for the secure storage operation
   - Returns: Result containing storage confirmation or error
   */
  public func secureStore(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let startTime = Date()
    let operationID = UUID().uuidString
    
    await logger.debug("Starting secure store operation", metadata: [
      "operation_id": operationID,
      "algorithm": config.encryptionAlgorithm.rawValue
    ])
    
    // Extract required parameters from configuration
    guard let dataString = config.options?.metadata?["data"],
          let inputData = Data(base64Encoded: dataString) else {
      throw SecurityError.invalidInput("Missing or invalid input data for secure storage")
    }
    
    // First encrypt the data
    let encryptionResult = try await encrypt(config: config)
    
    if !encryptionResult.successful {
      return encryptionResult
    }
    
    // Then store the encrypted data using the key manager
    guard let encryptedData = encryptionResult.resultData else {
      throw SecurityError.internalError("Encryption successful but no encrypted data returned")
    }
    
    let keyIdentifier = UUID().uuidString
    let storeResult = try await keyManager.storeKey(
      identifier: keyIdentifier,
      keyData: encryptedData,
      metadata: config.options?.metadata ?? [:]
    )
    
    let executionTime = Date().timeIntervalSince(startTime) * 1000
    
    return SecurityResultDTO(
      successful: storeResult.successful,
      resultData: keyIdentifier.data(using: .utf8),
      errorDetails: storeResult.errorDetails,
      executionTimeMs: executionTime,
      metadata: storeResult.metadata
    )
  }

  /**
   Retrieves securely stored data with the specified configuration.
   
   - Parameter config: Configuration for the secure retrieval operation
   - Returns: Result containing retrieved data or error
   */
  public func secureRetrieve(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let startTime = Date()
    let operationID = UUID().uuidString
    
    await logger.debug("Starting secure retrieve operation", metadata: [
      "operation_id": operationID,
      "algorithm": config.encryptionAlgorithm.rawValue
    ])
    
    // Extract required parameters from configuration
    guard let keyIdentifier = config.options?.metadata?["key_identifier"] else {
      throw SecurityError.invalidInput("Missing key identifier for secure retrieval")
    }
    
    // Retrieve the encrypted data using the key manager
    let retrieveResult = try await keyManager.getKey(
      identifier: keyIdentifier,
      metadata: config.options?.metadata ?? [:]
    )
    
    if !retrieveResult.successful || retrieveResult.keyData == nil {
      let errorDetails = retrieveResult.errorDetails ?? "Failed to retrieve data"
      return SecurityResultDTO(
        successful: false,
        resultData: nil,
        errorDetails: errorDetails,
        executionTimeMs: Date().timeIntervalSince(startTime) * 1000,
        metadata: retrieveResult.metadata
      )
    }
    
    // Decrypt the retrieved data
    let decryptConfig = SecurityConfigDTO(
      encryptionAlgorithm: config.encryptionAlgorithm,
      hashAlgorithm: config.hashAlgorithm,
      providerType: config.providerType,
      options: config.options
    )
    
    guard let keyData = retrieveResult.keyData else {
      throw SecurityError.internalError("Key data missing after successful retrieval")
    }
    
    // Modify the config to include the encrypted data
    var decryptMetadata = config.options?.metadata ?? [:]
    decryptMetadata["data"] = keyData.base64EncodedString()
    
    let decryptOptions = SecurityConfigOptions(
      enableDetailedLogging: config.options?.enableDetailedLogging ?? false,
      keyDerivationIterations: config.options?.keyDerivationIterations ?? 100_000,
      memoryLimitBytes: config.options?.memoryLimitBytes ?? 65536,
      useHardwareAcceleration: config.options?.useHardwareAcceleration ?? true,
      operationTimeoutSeconds: config.options?.operationTimeoutSeconds ?? 30.0,
      verifyOperations: config.options?.verifyOperations ?? true,
      metadata: decryptMetadata
    )
    
    let decryptResult = try await decrypt(
      config: SecurityConfigDTO(
        encryptionAlgorithm: config.encryptionAlgorithm,
        hashAlgorithm: config.hashAlgorithm,
        providerType: config.providerType,
        options: decryptOptions
      )
    )
    
    let executionTime = Date().timeIntervalSince(startTime) * 1000
    
    return SecurityResultDTO(
      successful: decryptResult.successful,
      resultData: decryptResult.resultData,
      errorDetails: decryptResult.errorDetails,
      executionTimeMs: executionTime,
      metadata: decryptResult.metadata
    )
  }

  /**
   Securely deletes stored data with the specified configuration.
   
   - Parameter config: Configuration for the secure deletion operation
   - Returns: Result containing deletion confirmation or error
   */
  public func secureDelete(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let startTime = Date()
    let operationID = UUID().uuidString
    
    await logger.debug("Starting secure delete operation", metadata: [
      "operation_id": operationID
    ])
    
    // Extract required parameters from configuration
    guard let keyIdentifier = config.options?.metadata?["key_identifier"] else {
      throw SecurityError.invalidInput("Missing key identifier for secure deletion")
    }
    
    // Delete the key using the key manager
    let deleteResult = try await keyManager.deleteKey(
      identifier: keyIdentifier,
      metadata: config.options?.metadata ?? [:]
    )
    
    let executionTime = Date().timeIntervalSince(startTime) * 1000
    
    return SecurityResultDTO(
      successful: deleteResult.successful,
      resultData: nil,
      errorDetails: deleteResult.errorDetails,
      executionTimeMs: executionTime,
      metadata: deleteResult.metadata
    )
  }

  /**
   Performs a security operation based on the provided configuration.
   
   - Parameters:
     - operation: The security operation to perform
     - config: Configuration for the operation
   - Returns: Result of the operation
   */
  public func performSecureOperation(
    operation: CoreSecurityTypes.SecurityOperation,
    config: CoreSecurityTypes.SecurityConfigDTO
  ) async throws -> CoreSecurityTypes.SecurityResultDTO {
    let startTime = Date()
    let operationID = UUID().uuidString
    
    await logger.debug("Starting secure operation: \(operation.rawValue)", metadata: [
      "operation_id": operationID,
      "algorithm": config.encryptionAlgorithm.rawValue
    ])
    
    let result: CoreSecurityTypes.SecurityResultDTO
    
    switch operation {
    case .encryption:
      result = try await encrypt(config: config)
    case .decryption:
      result = try await decrypt(config: config)
    case .hashing:
      result = try await hash(config: config)
    case .keyGeneration:
      result = try await generateKey(config: config)
    case .keyRotation:
      result = try await rotateKey(config: config)
    case .keyDeletion:
      result = try await secureDelete(config: config)
    case .secureStorage:
      result = try await secureStore(config: config)
    case .secureRetrieval:
      result = try await secureRetrieve(config: config)
    }
    
    let executionTime = Date().timeIntervalSince(startTime) * 1000
    
    // Add execution time to the result metadata
    var updatedMetadata = result.metadata ?? [:]
    updatedMetadata["execution_time_ms"] = "\(executionTime)"
    updatedMetadata["operation_id"] = operationID
    
    return CoreSecurityTypes.SecurityResultDTO(
      successful: result.successful,
      resultData: result.resultData,
      errorDetails: result.errorDetails,
      executionTimeMs: executionTime,
      metadata: updatedMetadata
    )
  }
  
  /**
   Creates a security configuration with appropriate settings.
   
   - Parameter options: The options to include in the configuration
   - Returns: A properly configured SecurityConfigDTO
   */
  public func createSecureConfig(options: SecurityConfigOptions) async -> SecurityConfigDTO {
    // Determine the most appropriate encryption algorithm based on options
    let encryptionAlgorithm: EncryptionAlgorithm
    if options.useHardwareAcceleration {
      encryptionAlgorithm = .aesGcm256
    } else {
      encryptionAlgorithm = .aesCbc256
    }
    
    // Determine appropriate hash algorithm
    let hashAlgorithm: HashAlgorithm = .sha256
    
    // Determine appropriate provider type based on options
    let providerType: SecurityProviderType
    if options.useHardwareAcceleration {
      providerType = .hardware
    } else {
      providerType = .software
    }
    
    return SecurityConfigDTO(
      encryptionAlgorithm: encryptionAlgorithm,
      hashAlgorithm: hashAlgorithm,
      providerType: providerType,
      options: options
    )
  }

  /**
   Processes a security operation based on the provided configuration.

   This is a unified entry point for all security operations, handling common
   aspects like logging, error mapping, and result formatting.

   - Parameters:
     - operation: The security operation to perform
     - metadata: Additional metadata for the operation
   - Returns: The result of the operation
   */
  public func processSecurityOperation(
    operation: SecurityOperation,
    metadata: [String: String]
  ) async -> CoreSecurityTypes.SecurityResultDTO {
    // Process the operation using actor-isolated state
    let operationID = UUID().uuidString
    let startTime = Date()

    // Create base metadata
    var operationMetadata = metadata
    operationMetadata["operationID"] = operationID
    operationMetadata["operation"] = String(describing: operation)

    // Log operation start
    await logger.info(
      "Starting security operation: \(operation)",
      metadata: operationMetadata,
      source: "CoreSecurityProvider"
    )

    do {
      // Process the operation based on type
      let result: SecurityResultDTO = try await {
        switch operation {
          case let .encrypt(data, key, algorithm):
            let config = SecurityConfigDTO(
              operationType: .encrypt,
              data: data,
              key: key,
              algorithm: algorithm,
              metadata: metadata
            )
            return try await encrypt(config: config)

          case let .decrypt(data, key, algorithm):
            let config = SecurityConfigDTO(
              operationType: .decrypt,
              data: data,
              key: key,
              algorithm: algorithm,
              metadata: metadata
            )
            return try await decrypt(config: config)

          case let .generateKey(type, size):
            let config = SecurityConfigDTO(
              operationType: .generateKey,
              keyType: type,
              keySize: size,
              metadata: metadata
            )
            return try await generateKey(config: config)

          case let .sign(data, key, algorithm):
            let config = SecurityConfigDTO(
              operationType: .sign,
              data: data,
              key: key,
              algorithm: algorithm,
              metadata: metadata
            )
            return try await sign(config: config)

          case let .verify(data, signature, key, algorithm):
            let config = SecurityConfigDTO(
              operationType: .verify,
              data: data,
              signature: signature,
              key: key,
              algorithm: algorithm,
              metadata: metadata
            )
            return try await verify(config: config)

          case let .store(data, identifier):
            let config = SecurityConfigDTO(
              operationType: .store,
              data: data,
              identifier: identifier,
              metadata: metadata
            )
            return try await store(config: config)

          case let .retrieve(identifier):
            let config = SecurityConfigDTO(
              operationType: .retrieve,
              identifier: identifier,
              metadata: metadata
            )
            return try await retrieve(config: config)
        }
      }()

      // Calculate operation duration
      let duration = Date().timeIntervalSince(startTime)

      // Log operation completion
      var resultMetadata = operationMetadata
      resultMetadata["duration"] = String(format: "%.3f", duration)
      resultMetadata["status"] = "success"

      await logger.info(
        "Completed security operation: \(operation)",
        metadata: resultMetadata,
        source: "CoreSecurityProvider"
      )

      return result
    } catch {
      // Calculate operation duration
      let duration = Date().timeIntervalSince(startTime)

      // Log operation failure
      var errorMetadata = operationMetadata
      errorMetadata["duration"] = String(format: "%.3f", duration)
      errorMetadata["status"] = "error"
      errorMetadata["error"] = error.localizedDescription

      await logger.error(
        "Failed security operation: \(operation)",
        metadata: errorMetadata,
        source: "CoreSecurityProvider"
      )

      // Return failure result
      return CoreSecurityTypes.SecurityResultDTO(
        status: .failure,
        error: error.localizedDescription,
        metadata: errorMetadata
      )
    }
  }
}
