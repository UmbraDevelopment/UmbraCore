import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingServices
import LoggingTypes
import SecurityCoreInterfaces
import UmbraErrors

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

 Implements privacy-aware logging through SecureLoggerActor, ensuring that
 sensitive information is properly tagged with privacy levels according to the
 Alpha Dot Five architecture principles.
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

  /**
   The secure logger for privacy-aware logging of sensitive security operations

   This logger ensures proper privacy tagging for all security-sensitive information
   in accordance with the Alpha Dot Five architecture principles.
   */
  private let secureLogger: SecureLoggerActor

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
  private var operationData: [String: [UInt8]]=[:]

  /**
   Initialises the security provider with all required services.

   - Parameters:
     - cryptoService: Service for cryptographic operations
     - keyManager: Service for key management operations
     - logger: Logger for general operations
     - secureLogger: Secure logger for privacy-aware logging (will be created if nil)
   */
  public init(
    cryptoService: SecurityCoreInterfaces.CryptoServiceProtocol,
    keyManager: KeyManagementProtocol,
    logger: LoggingInterfaces.LoggingProtocol,
    secureLogger: SecureLoggerActor?=nil
  ) {
    self.cryptoService=cryptoService
    self.keyManager=keyManager
    self.logger=logger
    self.secureLogger=secureLogger ?? SecureLoggerActor(
      subsystem: "com.umbra.security",
      category: "SecurityProvider",
      includeTimestamps: true
    )

    // Initialize component services
    encryptionService=EncryptionService(
      cryptoService: cryptoService,
      logger: logger
    )

    hashingService=HashingService(
      cryptoService: cryptoService,
      logger: logger
    )

    signatureService=SignatureService(
      cryptoService: cryptoService,
      keyManagementService: keyManager,
      logger: logger
    )

    // Initialise the secure storage service
    storageService=SecureStorageService(
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

    // Log with secure logger for enhanced privacy awareness
    await secureLogger.securityEvent(
      action: "SecurityProviderInitialisation",
      status: .success,
      subject: nil,
      resource: nil,
      additionalMetadata: [
        "operation": PrivacyTaggedValue(value: "start", privacyLevel: .public),
        "provider": PrivacyTaggedValue(value: "SecurityProviderService", privacyLevel: .public)
      ]
    )

    // Initialize dependencies
    if let initialisable=cryptoService as? AsyncServiceInitializable {
      try await initialisable.initialize()
    }

    if let initialisable=keyManager as? AsyncServiceInitializable {
      try await initialisable.initialize()
    }

    await logger.info("Security provider service initialized successfully")

    // Log successful initialisation with secure logger
    await secureLogger.securityEvent(
      action: "SecurityProviderInitialisation",
      status: .success,
      subject: nil,
      resource: nil,
      additionalMetadata: [
        "operation": PrivacyTaggedValue(value: "complete", privacyLevel: .public),
        "provider": PrivacyTaggedValue(value: "SecurityProviderService", privacyLevel: .public)
      ]
    )
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

  // MARK: - Core Encryption/Decryption Operations

  /**
   Encrypts binary data with the provided key.

   - Parameters:
     - data: Data to encrypt
     - key: Encryption key
   - Returns: Encrypted data
   - Throws: Security protocol errors if encryption fails
   */
  public func encrypt(_ data: [UInt8], key: [UInt8]) async throws -> [UInt8] {
    let dataIdentifier=await storeDataForOperation(data)
    let keyIdentifier=await storeDataForOperation(key)

    let result=await cryptoService.encrypt(
      dataIdentifier: dataIdentifier,
      keyIdentifier: keyIdentifier,
      options: EncryptionOptions(algorithm: .aes256CBC)
    )

    switch result {
      case let .success(encryptedDataIdentifier):
        // Retrieve the encrypted data using the identifier
        if
          let encryptedData=await retrieveDataForOperation(
            withIdentifier: encryptedDataIdentifier
          )
        {
          return encryptedData
        } else {
          throw SecurityProtocolError.inputError("Failed to retrieve encrypted data")
        }
      case let .failure(error):
        throw error
    }
  }

  /**
   Decrypts binary data with the provided key.

   - Parameters:
     - data: Encrypted data to decrypt
     - key: Decryption key
   - Returns: Decrypted data
   - Throws: Security protocol errors if decryption fails
   */
  public func decrypt(_ data: [UInt8], key: [UInt8]) async throws -> [UInt8] {
    let encryptedDataIdentifier=await storeDataForOperation(data)
    let keyIdentifier=await storeDataForOperation(key)

    let result=await cryptoService.decrypt(
      encryptedDataIdentifier: encryptedDataIdentifier,
      keyIdentifier: keyIdentifier,
      options: DecryptionOptions(algorithm: .aes256CBC)
    )

    switch result {
      case let .success(decryptedDataIdentifier):
        // Retrieve the decrypted data using the identifier
        if
          let decryptedData=await retrieveDataForOperation(
            withIdentifier: decryptedDataIdentifier
          )
        {
          return decryptedData
        } else {
          throw SecurityProtocolError.inputError("Failed to retrieve decrypted data")
        }
      case let .failure(error):
        throw error
    }
  }

  /**
   Signs data with the provided key.

   - Parameters:
     - data: Data to sign
     - key: Signing key
   - Returns: Signature
   - Throws: Security protocol errors if signing fails
   */
  public func sign(_ data: [UInt8], key: [UInt8]) async throws -> [UInt8] {
    let dataIdentifier=await storeDataForOperation(data + key)

    let result=await cryptoService.hash(
      dataIdentifier: dataIdentifier,
      options: HashingOptions(algorithm: .sha256)
    )

    switch result {
      case let .success(signatureIdentifier):
        // Retrieve the signature using the identifier
        if let signatureData=await retrieveDataForOperation(withIdentifier: signatureIdentifier) {
          return signatureData
        } else {
          throw SecurityProtocolError.inputError("Failed to retrieve signature data")
        }
      case let .failure(error):
        throw error
    }
  }

  // MARK: - Data Management for Operations

  /**
   Stores data for a security operation.

   - Parameter data: The data to store
   - Returns: A unique identifier for the stored data
   */
  private func storeDataForOperation(_ data: [UInt8]) async -> String {
    let identifier=UUID().uuidString
    operationData[identifier]=data
    return identifier
  }

  /**
   Retrieves data for a security operation.

   - Parameter identifier: The identifier for the stored data
   - Returns: The retrieved data, or nil if not found
   */
  private func retrieveDataForOperation(withIdentifier identifier: String) async -> [UInt8]? {
    let result=operationData[identifier]
    // Clean up after retrieval
    operationData[identifier]=nil
    return result
  }

  /**
   Helper to get or create a key for the current operation.

   - Parameters:
     - config: The security configuration
     - operation: The security operation requiring a key
   - Returns: Byte array key if available
   - Throws: Error if key retrieval fails
   */
  private func getKeyForOperation(
    config: SecurityConfigDTO,
    operation: SecurityOperation
  ) async throws -> [UInt8]? {
    // Check if the key is directly provided in the options
    if let keyB64=config.options?.metadata?["key"], let keyData=Data(base64Encoded: keyB64) {
      return [UInt8](keyData)
    }

    // Check if a key identifier is provided to load from key manager
    if let keyID=config.options?.metadata?["keyIdentifier"] {
      await logger.debug("Retrieving key for operation", metadata: [
        "operation": "\(operation.rawValue)",
        "keyIdentifier": keyID
      ])

      let result=await keyManager.retrieveKey(withIdentifier: keyID)
      switch result {
        case let .success(key):
          return key
        case let .failure(error):
          throw SecurityProtocolError.inputError(
            "Failed to retrieve key with identifier \(keyID): \(error.localizedDescription)"
          )
      }
    }

    return nil
  }

  /**
   Encrypts data with the specified configuration.

   Delegates to the encryption service for implementation.

   - Parameter config: Configuration for the encryption operation
   - Returns: Result containing encrypted data or error
   */
  public func encrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    // Create operation ID for tracing
    let operationID=UUID().uuidString
    let startTime=Date()

    // Log with secure logger for enhanced privacy awareness
    await secureLogger.securityEvent(
      action: "Encryption",
      status: .success,
      subject: nil,
      resource: nil,
      additionalMetadata: [
        "operationId": PrivacyTaggedValue(value: operationID, privacyLevel: .public),
        "operation": PrivacyTaggedValue(value: "start", privacyLevel: .public),
        "operationType": PrivacyTaggedValue(value: config.operationType.rawValue,
                                            privacyLevel: .public),
        "dataSize": PrivacyTaggedValue(value: config.inputData?.count ?? 0, privacyLevel: .public),
        "hasKey": PrivacyTaggedValue(value: config.keyIdentifier != nil, privacyLevel: .public)
      ]
    )

    do {
      // Delegate to encryption service
      let result=try await encryptionService.encrypt(config: config)

      // Calculate operation duration
      let duration=Date().timeIntervalSince(startTime)

      // Log success with secure logger
      await secureLogger.securityEvent(
        action: "Encryption",
        status: .success,
        subject: nil,
        resource: nil,
        additionalMetadata: [
          "operationId": PrivacyTaggedValue(value: operationID, privacyLevel: .public),
          "operation": PrivacyTaggedValue(value: "complete", privacyLevel: .public),
          "durationMs": PrivacyTaggedValue(value: Int(duration * 1000), privacyLevel: .public),
          "resultSize": PrivacyTaggedValue(value: result.data?.count ?? 0, privacyLevel: .public)
        ]
      )

      return result
    } catch {
      // Calculate operation duration
      let duration=Date().timeIntervalSince(startTime)

      // Log failure with secure logger
      await secureLogger.securityEvent(
        action: "Encryption",
        status: .failed,
        subject: nil,
        resource: nil,
        additionalMetadata: [
          "operationId": PrivacyTaggedValue(value: operationID, privacyLevel: .public),
          "operation": PrivacyTaggedValue(value: "error", privacyLevel: .public),
          "durationMs": PrivacyTaggedValue(value: Int(duration * 1000), privacyLevel: .public),
          "errorType": PrivacyTaggedValue(value: String(describing: type(of: error)),
                                          privacyLevel: .public),
          "errorDescription": PrivacyTaggedValue(value: error.localizedDescription,
                                                 privacyLevel: .public)
        ]
      )

      throw error
    }
  }

  /**
   Decrypts data with the specified configuration.

   Delegates to the encryption service for implementation.

   - Parameter config: Configuration for the decryption operation
   - Returns: Result containing decrypted data or error
   */
  public func decrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    // Create operation ID for tracing
    let operationID=UUID().uuidString
    let startTime=Date()

    // Log with secure logger for enhanced privacy awareness
    await secureLogger.securityEvent(
      action: "Decryption",
      status: .success,
      subject: nil,
      resource: nil,
      additionalMetadata: [
        "operationId": PrivacyTaggedValue(value: operationID, privacyLevel: .public),
        "operation": PrivacyTaggedValue(value: "start", privacyLevel: .public),
        "operationType": PrivacyTaggedValue(value: config.operationType.rawValue,
                                            privacyLevel: .public),
        "dataSize": PrivacyTaggedValue(value: config.inputData?.count ?? 0, privacyLevel: .public),
        "hasKey": PrivacyTaggedValue(value: config.keyIdentifier != nil, privacyLevel: .public)
      ]
    )

    do {
      // Delegate to encryption service
      let result=try await encryptionService.decrypt(config: config)

      // Calculate operation duration
      let duration=Date().timeIntervalSince(startTime)

      // Log success with secure logger
      await secureLogger.securityEvent(
        action: "Decryption",
        status: .success,
        subject: nil,
        resource: nil,
        additionalMetadata: [
          "operationId": PrivacyTaggedValue(value: operationID, privacyLevel: .public),
          "operation": PrivacyTaggedValue(value: "complete", privacyLevel: .public),
          "durationMs": PrivacyTaggedValue(value: Int(duration * 1000), privacyLevel: .public),
          "resultSize": PrivacyTaggedValue(value: result.data?.count ?? 0, privacyLevel: .public)
        ]
      )

      return result
    } catch {
      // Calculate operation duration
      let duration=Date().timeIntervalSince(startTime)

      // Log failure with secure logger
      await secureLogger.securityEvent(
        action: "Decryption",
        status: .failed,
        subject: nil,
        resource: nil,
        additionalMetadata: [
          "operationId": PrivacyTaggedValue(value: operationID, privacyLevel: .public),
          "operation": PrivacyTaggedValue(value: "error", privacyLevel: .public),
          "durationMs": PrivacyTaggedValue(value: Int(duration * 1000), privacyLevel: .public),
          "errorType": PrivacyTaggedValue(value: String(describing: type(of: error)),
                                          privacyLevel: .public),
          "errorDescription": PrivacyTaggedValue(value: error.localizedDescription,
                                                 privacyLevel: .public)
        ]
      )

      throw error
    }
  }

  /**
   Generates a cryptographic key with the specified configuration.

   Delegates to the key management service for implementation.

   - Parameter config: Configuration for the key generation operation
   - Returns: Result containing key identifier or error
   */
  public func generateKey(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    // Create operation ID for tracing
    let operationID=UUID().uuidString
    let startTime=Date()

    // Log operation with standard logger
    await logger.info(
      "Generating cryptographic key",
      metadata: ["keyType": config.keyType.rawValue],
      source: "CoreSecurityProvider"
    )

    // Log with secure logger for enhanced privacy awareness
    await secureLogger.securityEvent(
      action: "KeyGeneration",
      status: .success,
      subject: nil,
      resource: nil,
      additionalMetadata: [
        "operationId": PrivacyTaggedValue(value: operationID, privacyLevel: .public),
        "operation": PrivacyTaggedValue(value: "start", privacyLevel: .public),
        "keyType": PrivacyTaggedValue(value: config.keyType.rawValue, privacyLevel: .public),
        "keySize": PrivacyTaggedValue(value: config.keySize, privacyLevel: .public)
      ]
    )

    do {
      // Process the request through the key management service
      let result=try await keyManager.generateKey(
        type: config.keyType,
        size: config.keySize,
        metadata: config.metadata
      )

      // Calculate operation duration
      let duration=Date().timeIntervalSince(startTime)

      // Create result data
      let resultDTO=SecurityResultDTO(
        status: .success,
        data: Data(result.identifier.utf8),
        metadata: ["keyType": config.keyType.rawValue, "keySize": String(config.keySize)]
      )

      // Log success with secure logger
      await secureLogger.securityEvent(
        action: "KeyGeneration",
        status: .success,
        subject: nil,
        resource: result.identifier,
        additionalMetadata: [
          "operationId": PrivacyTaggedValue(value: operationID, privacyLevel: .public),
          "operation": PrivacyTaggedValue(value: "complete", privacyLevel: .public),
          "durationMs": PrivacyTaggedValue(value: Int(duration * 1000), privacyLevel: .public),
          "keyType": PrivacyTaggedValue(value: config.keyType.rawValue, privacyLevel: .public)
        ]
      )

      // Log completion
      await logger.info(
        "Key generation completed successfully",
        metadata: ["keyType": config.keyType.rawValue, "keyId": result.identifier],
        source: "CoreSecurityProvider"
      )

      return resultDTO
    } catch {
      // Calculate operation duration
      let duration=Date().timeIntervalSince(startTime)

      // Log failure with secure logger
      await secureLogger.securityEvent(
        action: "KeyGeneration",
        status: .failed,
        subject: nil,
        resource: nil,
        additionalMetadata: [
          "operationId": PrivacyTaggedValue(value: operationID, privacyLevel: .public),
          "operation": PrivacyTaggedValue(value: "error", privacyLevel: .public),
          "durationMs": PrivacyTaggedValue(value: Int(duration * 1000), privacyLevel: .public),
          "errorType": PrivacyTaggedValue(value: String(describing: type(of: error)),
                                          privacyLevel: .public),
          "errorDescription": PrivacyTaggedValue(value: error.localizedDescription,
                                                 privacyLevel: .public),
          "keyType": PrivacyTaggedValue(value: config.keyType.rawValue, privacyLevel: .public)
        ]
      )

      // Log error
      await logger.error(
        "Key generation failed: \(error.localizedDescription)",
        metadata: ["keyType": config.keyType.rawValue, "error": error.localizedDescription],
        source: "CoreSecurityProvider"
      )

      throw error
    }
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
    let startTime=Date()
    let operationID=UUID().uuidString

    await logger.debug("Starting secure store operation", metadata: [
      "operation_id": operationID,
      "algorithm": config.encryptionAlgorithm.rawValue
    ])

    // Extract required parameters from configuration
    guard
      let dataString=config.options?.metadata?["data"],
      let inputData=Data(base64Encoded: dataString)
    else {
      throw SecurityError.invalidInput("Missing or invalid input data for secure storage")
    }

    // First encrypt the data
    let encryptionResult=try await encrypt(config: config)

    if !encryptionResult.successful {
      return encryptionResult
    }

    // Then store the encrypted data using the key manager
    guard let encryptedData=encryptionResult.resultData else {
      throw SecurityError.internalError("Encryption successful but no encrypted data returned")
    }

    let keyIdentifier=UUID().uuidString
    let storeResult=try await keyManager.storeKey(
      identifier: keyIdentifier,
      keyData: encryptedData,
      metadata: config.options?.metadata ?? [:]
    )

    let executionTime=Date().timeIntervalSince(startTime) * 1000

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
    let startTime=Date()
    let operationID=UUID().uuidString

    await logger.debug("Starting secure retrieve operation", metadata: [
      "operation_id": operationID,
      "algorithm": config.encryptionAlgorithm.rawValue
    ])

    // Extract required parameters from configuration
    guard let keyIdentifier=config.options?.metadata?["key_identifier"] else {
      throw SecurityError.invalidInput("Missing key identifier for secure retrieval")
    }

    // Retrieve the encrypted data using the key manager
    let retrieveResult=try await keyManager.getKey(
      identifier: keyIdentifier,
      metadata: config.options?.metadata ?? [:]
    )

    if !retrieveResult.successful || retrieveResult.keyData == nil {
      let errorDetails=retrieveResult.errorDetails ?? "Failed to retrieve data"
      return SecurityResultDTO(
        successful: false,
        resultData: nil,
        errorDetails: errorDetails,
        executionTimeMs: Date().timeIntervalSince(startTime) * 1000,
        metadata: retrieveResult.metadata
      )
    }

    // Decrypt the retrieved data
    let decryptConfig=SecurityConfigDTO(
      encryptionAlgorithm: config.encryptionAlgorithm,
      hashAlgorithm: config.hashAlgorithm,
      providerType: config.providerType,
      options: config.options
    )

    guard let keyData=retrieveResult.keyData else {
      throw SecurityError.internalError("Key data missing after successful retrieval")
    }

    // Modify the config to include the encrypted data
    var decryptMetadata=config.options?.metadata ?? [:]
    decryptMetadata["data"]=keyData.base64EncodedString()

    let decryptOptions=SecurityConfigOptions(
      enableDetailedLogging: config.options?.enableDetailedLogging ?? false,
      keyDerivationIterations: config.options?.keyDerivationIterations ?? 100_000,
      memoryLimitBytes: config.options?.memoryLimitBytes ?? 65536,
      useHardwareAcceleration: config.options?.useHardwareAcceleration ?? true,
      operationTimeoutSeconds: config.options?.operationTimeoutSeconds ?? 30.0,
      verifyOperations: config.options?.verifyOperations ?? true,
      metadata: decryptMetadata
    )

    let decryptResult=try await decrypt(
      config: SecurityConfigDTO(
        encryptionAlgorithm: config.encryptionAlgorithm,
        hashAlgorithm: config.hashAlgorithm,
        providerType: config.providerType,
        options: decryptOptions
      )
    )

    let executionTime=Date().timeIntervalSince(startTime) * 1000

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
    let startTime=Date()
    let operationID=UUID().uuidString

    await logger.debug("Starting secure delete operation", metadata: [
      "operation_id": operationID
    ])

    // Extract required parameters from configuration
    guard let keyIdentifier=config.options?.metadata?["key_identifier"] else {
      throw SecurityError.invalidInput("Missing key identifier for secure deletion")
    }

    // Delete the key using the key manager
    let deleteResult=try await keyManager.deleteKey(
      identifier: keyIdentifier,
      metadata: config.options?.metadata ?? [:]
    )

    let executionTime=Date().timeIntervalSince(startTime) * 1000

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
   - Returns: The result of the operation
   */
  public func performSecureOperation(
    operation: CoreSecurityTypes.SecurityOperation,
    config: CoreSecurityTypes.SecurityConfigDTO
  ) async throws -> CoreSecurityTypes.SecurityResultDTO {
    let startTime=Date()
    let operationID=UUID().uuidString

    await logger.debug("Starting secure operation: \(operation.rawValue)", metadata: [
      "operation_id": operationID,
      "algorithm": config.encryptionAlgorithm.rawValue
    ])

    let result: CoreSecurityTypes.SecurityResultDTO=switch operation {
      case .encryption:
        try await encrypt(config: config)
      case .decryption:
        try await decrypt(config: config)
      case .hashing:
        try await hash(config: config)
      case .keyGeneration:
        try await generateKey(config: config)
      case .keyRotation:
        try await rotateKey(config: config)
      case .keyDeletion:
        try await secureDelete(config: config)
      case .secureStorage:
        try await secureStore(config: config)
      case .secureRetrieval:
        try await secureRetrieve(config: config)
    }

    let executionTime=Date().timeIntervalSince(startTime) * 1000

    // Add execution time to the result metadata
    var updatedMetadata=result.metadata ?? [:]
    updatedMetadata["execution_time_ms"]="\(executionTime)"
    updatedMetadata["operation_id"]=operationID

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
    // Determine the encryption algorithm based on the hardware acceleration setting
    let encryption: CoreSecurityTypes.EncryptionAlgorithm=if options.useHardwareAcceleration {
      .aes256GCM // Hardware accelerated where available
    } else {
      .aes256CBC // Software implementation
    }

    // Determine the signing algorithm based on options
    let signing: CoreSecurityTypes.SigningAlgorithm=if options.useHardwareAcceleration {
      .ed25519 // Hardware accelerated where available
    } else {
      .hmacSHA256 // Software implementation
    }

    // Determine the hashing algorithm
    let hashing: CoreSecurityTypes.HashingAlgorithm=if options.useStrongerHashing {
      .sha512 // Stronger but slower
    } else {
      .sha256 // Good balance of security and performance
    }

    // Create the security options with selected algorithms
    let securityOptions=SecurityOptions(
      encryption: encryption,
      decryption: encryption,
      signing: signing,
      hashing: hashing,
      metadata: options.metadata
    )

    // Create the configuration DTO with the options
    return SecurityConfigDTO(
      options: securityOptions,
      data: options.data,
      outputFormat: options.outputFormat ?? .binary
    )
  }

  /**
   Maps a standard error to a SecurityProtocolError for consistent error handling.

   - Parameter error: The error to map
   - Returns: A properly typed SecurityProtocolError
   */
  private func mapToSecurityError(_ error: Error) -> SecurityProtocolError {
    if let securityError=error as? SecurityProtocolError {
      return securityError
    }

    // Map known error types to appropriate security errors
    if let nsError=error as? NSError {
      switch nsError.domain {
        case NSURLErrorDomain:
          return .networkError(
            "Network error during security operation: \(nsError.localizedDescription)"
          )
        case NSOSStatusErrorDomain:
          return .systemError(
            "System error during security operation: \(nsError.localizedDescription)"
          )
        default:
          break
      }
    }

    // Default error mapping
    return .generalError("Security operation failed: \(error.localizedDescription)")
  }

  /**
   Creates a security result DTO with error information.

   - Parameter error: The error that occurred
   - Returns: A SecurityResultDTO with error details
   */
  private func createErrorResult(_ error: Error) -> SecurityResultDTO {
    let securityError=mapToSecurityError(error)
    return SecurityResultDTO.failure(
      errorCode: securityError.code,
      errorDetails: securityError.localizedDescription
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
    let operationID=UUID().uuidString
    let startTime=Date()

    // Create base metadata
    var operationMetadata=metadata
    operationMetadata["operationID"]=operationID
    operationMetadata["operation"]=String(describing: operation)

    // Log operation start
    await logger.info(
      "Starting security operation: \(operation)",
      metadata: operationMetadata,
      source: "CoreSecurityProvider"
    )

    do {
      // Process the operation based on type
      let result: SecurityResultDTO=try await {
        switch operation {
          case let .encrypt(data, key, algorithm):
            let config=SecurityConfigDTO(
              operationType: .encrypt,
              data: data,
              key: key,
              algorithm: algorithm,
              metadata: metadata
            )
            return try await encrypt(config: config)

          case let .decrypt(data, key, algorithm):
            let config=SecurityConfigDTO(
              operationType: .decrypt,
              data: data,
              key: key,
              algorithm: algorithm,
              metadata: metadata
            )
            return try await decrypt(config: config)

          case let .generateKey(type, size):
            let config=SecurityConfigDTO(
              operationType: .generateKey,
              keyType: type,
              keySize: size,
              metadata: metadata
            )
            return try await generateKey(config: config)

          case let .sign(data, key, algorithm):
            let config=SecurityConfigDTO(
              operationType: .sign,
              data: data,
              key: key,
              algorithm: algorithm,
              metadata: metadata
            )
            return try await sign(config: config)

          case let .verify(data, signature, key, algorithm):
            let config=SecurityConfigDTO(
              operationType: .verify,
              data: data,
              signature: signature,
              key: key,
              algorithm: algorithm,
              metadata: metadata
            )
            return try await verify(config: config)

          case let .store(data, identifier):
            let config=SecurityConfigDTO(
              operationType: .store,
              data: data,
              identifier: identifier,
              metadata: metadata
            )
            return try await store(config: config)

          case let .retrieve(identifier):
            let config=SecurityConfigDTO(
              operationType: .retrieve,
              identifier: identifier,
              metadata: metadata
            )
            return try await retrieve(config: config)
        }
      }()

      // Calculate operation duration
      let duration=Date().timeIntervalSince(startTime)

      // Log operation completion
      var resultMetadata=operationMetadata
      resultMetadata["duration"]=String(format: "%.3f", duration)
      resultMetadata["status"]="success"

      await logger.info(
        "Completed security operation: \(operation)",
        metadata: resultMetadata,
        source: "CoreSecurityProvider"
      )

      return result
    } catch {
      // Calculate operation duration
      let duration=Date().timeIntervalSince(startTime)

      // Log operation failure
      var errorMetadata=operationMetadata
      errorMetadata["duration"]=String(format: "%.3f", duration)
      errorMetadata["status"]="error"
      errorMetadata["error"]=error.localizedDescription

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
