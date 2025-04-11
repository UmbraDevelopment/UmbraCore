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
  domain: String="SecurityServices",
  source: String="SecurityProviderService"
) -> BaseLogContextDTO {
  var collection=LogMetadataDTOCollection()

  for (key, data) in metadata {
    switch data.privacy {
      case .public:
        collection=collection.withPublic(key: key, value: data.value)
      case .private:
        collection=collection.withPrivate(key: key, value: data.value)
      case .sensitive:
        collection=collection.withSensitive(key: key, value: data.value)
      case .hash:
        collection=collection.withPublic(key: key, value: data.value) // Treat as public for now
      case .auto:
        collection=collection.withPublic(key: key, value: data.value) // Treat as public for now
      @unknown default:
        // Handle any future privacy levels conservatively
        collection=collection.withPrivate(key: key, value: data.value)
    }
  }

  return BaseLogContextDTO(
    domainName: domain,
    source: source,
    metadata: collection
  )
}

/**
 Creates a log context for an operation with the specified configuration

 - Parameters:
   - config: Configuration for the operation
   - operationID: Unique identifier for the operation
 - Returns: A log context with appropriate metadata
 */
private func createLogContext(
  for config: SecurityConfigDTO,
  operationID: String
) -> SecurityLogContext {
  var metadata=LogMetadataDTOCollection()
  metadata=metadata.withPublic(key: "algorithm", value: config.encryptionAlgorithm.rawValue)
  metadata=metadata.withPublic(
    key: "dataSize",
    value: String(config.options?.metadata?["inputDataSize"] ?? "0")
  )
  metadata=metadata.withPublic(
    key: "hasKey",
    value: String(config.options?.metadata?["keyIdentifier"] != nil)
  )
  metadata=metadata.withPublic(key: "operationId", value: operationID)

  return SecurityLogContext(
    operation: "security_operation",
    component: "SecurityProvider",
    correlationID: operationID,
    source: "SecurityProvider",
    metadata: metadata
  )
}

/**
 Creates a log context for an operation with the specified operation type

 - Parameters:
   - operation: The security operation to perform
   - operationID: Unique identifier for the operation
 - Returns: A log context with appropriate metadata
 */
private func createOperationMetadata(
  _ operation: CoreSecurityTypes.SecurityOperation,
  _ operationID: String
) -> SecurityLogContext {
  var metadata=LogMetadataDTOCollection()
  metadata=metadata.withPublic(key: "operationType", value: operation.rawValue)
  metadata=metadata.withPublic(key: "operationId", value: operationID)

  return SecurityLogContext(
    operation: operation.rawValue,
    component: "SecurityProvider",
    correlationID: operationID,
    source: "SecurityProvider"
  )
}

/**
 # SecurityProviderImpl

 Implementation of the SecurityProviderProtocol according to Alpha Dot Five architecture principles.

 This implementation:
 - Uses actor-based concurrency for thread safety
 - Provides privacy-aware logging for security operations
 - Delegates to appropriate service implementations for specific tasks
 - Handles errors with proper context and information preservation
 */
public actor SecurityProviderImpl: SecurityProviderProtocol, AsyncServiceInitializable {
  // MARK: - Dependencies

  /// The cryptographic service used for operations
  private let cryptoServiceInstance: CryptoServiceProtocol

  /// The key management service used for key operations
  private let keyManager: KeyManagementProtocol

  /// The secure storage service used for storage operations
  private let storageService: SecureStorageService

  /// The logging service used for secure logging
  private let logger: LoggingProtocol

  // MARK: - Initialisation

  /**
   Initialises the security provider with required dependencies

   - Parameters:
     - cryptoService: The cryptographic service implementation
     - keyManager: The key management service implementation
     - logger: The logging service implementation
   */
  public init(
    cryptoService: CryptoServiceProtocol,
    keyManager: KeyManagementProtocol,
    logger: LoggingProtocol
  ) {
    cryptoServiceInstance=cryptoService
    self.keyManager=keyManager
    storageService=SecureStorageService(logger: logger)
    self.logger=logger
  }

  /**
   Asynchronous initializer required by AsyncServiceInitializable protocol

   - Returns: An initialised instance of the security provider
   */
  public static func createAsync() async -> SecurityProviderImpl {
    // Implementation depends on your factory pattern
    fatalError("Please use the initialiser with dependencies")
  }

  /**
   Encrypts data with the specified configuration

   - Parameter config: Configuration for the encryption operation
   - Returns: Result containing encrypted data or error information
   - Throws: SecurityError if encryption fails
   */
  public func encrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let operationID=UUID().uuidString
    let startTime=Date()

    // Create logging context for the operation
    let logContext=SecurityLogContext(
      operation: CoreSecurityTypes.SecurityOperation.encrypt.rawValue,
      component: "SecurityProviderImpl",
      operationID: operationID,
      correlationID: nil,
      source: "SecurityImplementation"
    )

    await logger.info("Starting encryption operation", context: logContext)

    do {
      // Extract data to encrypt from configuration
      guard
        let options=config.options,
        let inputDataBase64=options.metadata?["inputData"],
        let inputData=Data(base64Encoded: inputDataBase64)
      else {
        throw CoreSecurityTypes.SecurityError.invalidInputData
      }

      // Get encryption algorithm from config or use default
      let algorithm=config.encryptionAlgorithm

      // Create metadata for the operation
      var metadata=options.metadata ?? [:]
      metadata["algorithm"]=algorithm.rawValue

      // Perform encryption using crypto service
      let result=try await cryptoServiceInstance.encrypt(
        inputData,
        using: algorithm,
        options: options
      )

      // Calculate duration for metrics
      let duration=Date().timeIntervalSince(startTime) * 1000

      // Log success with privacy-aware metadata
      await logger.info(
        "Encryption operation completed successfully",
        context: logContext
      )

      // Return successful result
      return SecurityResultDTO.success(
        resultData: result.base64EncodedString(),
        executionTimeMs: duration,
        metadata: [
          "durationMs": String(format: "%.2f", duration),
          "algorithm": algorithm.rawValue
        ]
      )
    } catch {
      // Calculate duration before failure
      let duration=Date().timeIntervalSince(startTime) * 1000

      // Log failure with privacy-aware metadata
      let errorContext=logContext.adding(
        key: "errorType",
        value: "\(type(of: error))",
        privacy: .public
      ).adding(
        key: "errorMessage",
        value: error.localizedDescription,
        privacy: .private
      )

      await logger.error(
        "Encryption operation failed: \(error.localizedDescription)",
        context: errorContext
      )

      // Map to security error and re-throw
      if let secError=error as? CoreSecurityTypes.SecurityError {
        throw secError
      } else {
        throw CoreSecurityTypes.SecurityError.encryptionFailed(
          reason: "Operation failed: \(error.localizedDescription)"
        )
      }
    }
  }

  /**
   Decrypts data using the specified configuration.

   - Parameter config: Configuration for the decryption operation
   - Returns: Result containing decrypted data or error
   - Throws: SecurityError if decryption fails
   */
  public func decrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let operationID=UUID().uuidString
    let startTime=Date()

    // Create logging context for the operation
    let logContext=SecurityLogContext(
      operation: CoreSecurityTypes.SecurityOperation.decrypt.rawValue,
      component: "SecurityProviderImpl",
      operationID: operationID,
      correlationID: nil,
      source: "SecurityImplementation"
    )

    await logger.info("Starting decryption operation", context: logContext)

    do {
      // Extract data to decrypt from configuration
      guard
        let options=config.options,
        let inputDataBase64=options.metadata?["inputData"],
        let inputData=Data(base64Encoded: inputDataBase64)
      else {
        throw CoreSecurityTypes.SecurityError.invalidInputData
      }

      // Get encryption algorithm from config or use default
      let algorithm=config.encryptionAlgorithm

      // Create metadata for the operation
      var metadata=options.metadata ?? [:]
      metadata["algorithm"]=algorithm.rawValue

      // Perform decryption using crypto service
      let result=try await cryptoServiceInstance.decrypt(
        inputData,
        using: algorithm,
        options: options
      )

      // Calculate duration for metrics
      let duration=Date().timeIntervalSince(startTime) * 1000

      // Log success with privacy-aware metadata
      await logger.info(
        "Decryption operation completed successfully",
        context: logContext
      )

      // Return successful result
      return SecurityResultDTO.success(
        resultData: result.base64EncodedString(),
        executionTimeMs: duration,
        metadata: [
          "durationMs": String(format: "%.2f", duration),
          "algorithm": algorithm.rawValue
        ]
      )
    } catch {
      // Calculate duration before failure
      let duration=Date().timeIntervalSince(startTime) * 1000

      // Log failure with privacy-aware metadata
      let errorContext=logContext.adding(
        key: "errorType",
        value: "\(type(of: error))",
        privacy: .public
      ).adding(
        key: "errorMessage",
        value: error.localizedDescription,
        privacy: .private
      )

      await logger.error(
        "Decryption operation failed: \(error.localizedDescription)",
        context: errorContext
      )

      // Map to security error and re-throw
      if let secError=error as? CoreSecurityTypes.SecurityError {
        throw secError
      } else {
        throw CoreSecurityTypes.SecurityError.decryptionFailed(
          reason: "Operation failed: \(error.localizedDescription)"
        )
      }
    }
  }

  /**
   Generates a cryptographic key with the specified configuration.

   - Parameter config: Configuration for the key generation operation
   - Returns: Result containing key or error
   - Throws: SecurityError if key generation fails
   */
  public func generateKey(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let operationID=UUID().uuidString
    let startTime=Date()

    // Create logging context for the operation
    let logContext=SecurityLogContext(
      operation: CoreSecurityTypes.SecurityOperation.generateKey.rawValue,
      component: "SecurityProviderImpl",
      operationID: operationID,
      correlationID: nil,
      source: "SecurityImplementation"
    )

    await logger.info("Starting key generation operation", context: logContext)

    do {
      // Get key size from options or use default
      let keySize: Int=if
        let options=config.options, let keySizeStr=options.metadata?["keySize"],
        let size=Int(keySizeStr)
      {
        size
      } else {
        // Default to 256-bit key if not specified
        256
      }

      // Generate random data for key using crypto service
      let randomConfig=SecurityConfigDTO(
        encryptionAlgorithm: config.encryptionAlgorithm,
        hashAlgorithm: .sha256,
        providerType: .basic,
        options: SecurityConfigOptions(
          enableDetailedLogging: true,
          keyDerivationIterations: 10000,
          memoryLimitBytes: 65536,
          useHardwareAcceleration: true,
          operationTimeoutSeconds: 30,
          verifyOperations: true,
          metadata: [
            "bytes": "\(keySize / 8)",
            "purpose": "keyGeneration"
          ]
        )
      )

      // Generate key data
      let keyData=try await keyManager.generateKey(size: keySize)

      // Store the key if an identifier is provided
      let keyIdentifier: String?
      if let options=config.options, let identifier=options.metadata?["keyIdentifier"] {
        try await keyManager.storeKey(keyData, withIdentifier: identifier)
        keyIdentifier=identifier
      } else {
        keyIdentifier=nil
      }

      // Calculate duration for metrics
      let duration=Date().timeIntervalSince(startTime) * 1000

      // Log success with privacy-aware metadata
      await logger.info(
        "Key generation operation completed successfully",
        context: logContext
      )

      // Create metadata for result
      var resultMetadata=[
        "durationMs": String(format: "%.2f", duration),
        "keySize": "\(keySize)",
        "algorithm": config.encryptionAlgorithm.rawValue
      ]

      if let keyID=keyIdentifier {
        resultMetadata["keyIdentifier"]=keyID
      }

      // Return successful result
      return SecurityResultDTO.success(
        resultData: keyData.base64EncodedString(),
        executionTimeMs: duration,
        metadata: resultMetadata
      )
    } catch {
      // Calculate duration before failure
      let duration=Date().timeIntervalSince(startTime) * 1000

      // Log failure with privacy-aware metadata
      let errorContext=logContext.adding(
        key: "errorType",
        value: "\(type(of: error))",
        privacy: .public
      ).adding(
        key: "errorMessage",
        value: error.localizedDescription,
        privacy: .private
      )

      await logger.error(
        "Key generation operation failed: \(error.localizedDescription)",
        context: errorContext
      )

      // Map to security error and re-throw
      if let secError=error as? CoreSecurityTypes.SecurityError {
        throw secError
      } else {
        throw CoreSecurityTypes.SecurityError.keyGenerationFailed(
          reason: "Key generation failed: \(error.localizedDescription)"
        )
      }
    }
  }

  /**
   Signs data using the specified configuration

   - Parameter config: Configuration for the signing operation
   - Returns: Result of the signing operation
   */
  public func sign(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let operationID=UUID().uuidString
    let startTime=Date()

    // Create logging context for the operation
    let logContext=SecurityLogContext(
      operation: CoreSecurityTypes.SecurityOperation.sign.rawValue,
      component: "SecurityProviderImpl",
      operationID: operationID,
      correlationID: nil,
      source: "SecurityImplementation"
    )

    await logger.info("Starting digital signature operation", context: logContext)

    do {
      // Validate required inputs
      guard
        let options=config.options,
        let inputDataBase64=options.metadata?["inputData"],
        let inputData=Data(base64Encoded: inputDataBase64),
        let keyIdentifier=options.metadata?["keyIdentifier"]
      else {
        throw CoreSecurityTypes.SecurityError.invalidInputData
      }

      // Retrieve the key for signing
      let keyData=try await keyManager.retrieveKey(withIdentifier: keyIdentifier)

      // Perform signing operation
      let signatureData=try await cryptoServiceInstance.sign(
        data: inputData,
        withKey: keyData,
        options: options
      )

      // Calculate duration for metrics
      let duration=Date().timeIntervalSince(startTime) * 1000

      // Log success with privacy-aware metadata
      await logger.info(
        "Digital signature operation completed successfully",
        context: logContext.adding(
          key: "keyIdentifier",
          value: keyIdentifier,
          privacy: .private
        ).adding(
          key: "durationMs",
          value: String(format: "%.2f", duration),
          privacy: .public
        )
      )

      // Return successful result
      return SecurityResultDTO.success(
        resultData: signatureData.base64EncodedString(),
        executionTimeMs: duration,
        metadata: [
          "durationMs": String(format: "%.2f", duration),
          "keyIdentifier": keyIdentifier,
          "algorithm": config.hashAlgorithm.rawValue
        ]
      )
    } catch {
      // Calculate duration before failure
      let duration=Date().timeIntervalSince(startTime) * 1000

      // Log failure with privacy-aware metadata
      let errorContext=logContext.adding(
        key: "errorType",
        value: "\(type(of: error))",
        privacy: .public
      ).adding(
        key: "errorMessage",
        value: error.localizedDescription,
        privacy: .private
      )

      await logger.error(
        "Digital signature operation failed: \(error.localizedDescription)",
        context: errorContext
      )

      // Map to security error and re-throw
      if let secError=error as? CoreSecurityTypes.SecurityError {
        throw secError
      } else {
        throw CoreSecurityTypes.SecurityError.signatureOperationFailed(
          reason: "Signature operation failed: \(error.localizedDescription)"
        )
      }
    }
  }

  /**
   Verifies a digital signature with the specified configuration.

   - Parameter config: Configuration for the signature verification operation
   - Returns: Result containing verification status or error
   - Throws: SecurityError if verification fails
   */
  public func verify(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let operationID=UUID().uuidString
    let startTime=Date()

    // Create logging context for the operation
    let logContext=SecurityLogContext(
      operation: CoreSecurityTypes.SecurityOperation.verify.rawValue,
      component: "SecurityProviderImpl",
      operationID: operationID,
      correlationID: nil,
      source: "SecurityImplementation"
    )

    await logger.info("Starting signature verification operation", context: logContext)

    do {
      // Validate required inputs
      guard
        let options=config.options,
        let inputDataBase64=options.metadata?["inputData"],
        let inputData=Data(base64Encoded: inputDataBase64),
        let signatureBase64=options.metadata?["signature"],
        let signatureData=Data(base64Encoded: signatureBase64),
        let keyIdentifier=options.metadata?["keyIdentifier"]
      else {
        throw CoreSecurityTypes.SecurityError.invalidInputData
      }

      // Retrieve the key for verification
      let keyData=try await keyManager.retrieveKey(withIdentifier: keyIdentifier)

      // Perform verification operation
      let isValid=try await cryptoServiceInstance.verify(
        signature: signatureData,
        forData: inputData,
        withKey: keyData,
        options: options
      )

      // Calculate duration for metrics
      let duration=Date().timeIntervalSince(startTime) * 1000

      // Log success with privacy-aware metadata
      await logger.info(
        "Signature verification operation completed successfully",
        context: logContext.adding(
          key: "keyIdentifier",
          value: keyIdentifier,
          privacy: .private
        ).adding(
          key: "durationMs",
          value: String(format: "%.2f", duration),
          privacy: .public
        ).adding(
          key: "isValid",
          value: "\(isValid)",
          privacy: .public
        )
      )

      // Return successful result
      return SecurityResultDTO.success(
        resultData: nil,
        executionTimeMs: duration,
        metadata: [
          "durationMs": String(format: "%.2f", duration),
          "keyIdentifier": keyIdentifier,
          "algorithm": config.hashAlgorithm.rawValue,
          "isValid": "\(isValid)"
        ]
      )
    } catch {
      // Calculate duration before failure
      let duration=Date().timeIntervalSince(startTime) * 1000

      // Log failure with privacy-aware metadata
      let errorContext=logContext.adding(
        key: "errorType",
        value: "\(type(of: error))",
        privacy: .public
      ).adding(
        key: "errorMessage",
        value: error.localizedDescription,
        privacy: .private
      )

      await logger.error(
        "Signature verification operation failed: \(error.localizedDescription)",
        context: errorContext
      )

      // Map to security error and re-throw
      if let secError=error as? CoreSecurityTypes.SecurityError {
        throw secError
      } else {
        throw CoreSecurityTypes.SecurityError.verificationOperationFailed(
          reason: "Verification operation failed: \(error.localizedDescription)"
        )
      }
    }
  }

  /**
   Creates a hash of data using the specified algorithm

   - Parameter config: Configuration for the hashing operation
   - Returns: Result of the hash operation
   */
  public func hash(config: SecurityConfigDTO) async -> SecurityResultDTO {
    await hashingService.hash(config: config)
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
    operation: CoreSecurityTypes.SecurityOperation
  ) async throws -> [UInt8]? {
    let context=createOperationMetadata(operation, identifier)

    await logger.debug(
      "Retrieving key for operation",
      context: context
    )

    // Delegate to key manager
    let result=try await keyManager.retrieveKey(withIdentifier: identifier)
    switch result {
      case let .success(keyData):
        return keyData
      case let .failure(error):
        throw error
    }
  }

  /**
   Retrieves a key with the specified identifier

   - Parameter identifier: Identifier of the key to retrieve
   - Returns: The key data or nil if not found
   - Throws: SecurityError if key retrieval fails
   */
  private func retrieveKey(identifier: String) async throws -> Data? {
    // Delegate to key manager
    let result=try await keyManager.retrieveKey(withIdentifier: identifier)
    switch result {
      case let .success(keyData):
        return Data(keyData)
      case let .failure(error):
        throw error
    }
  }

  /**
   Performs a secure operation with the specified configuration

   This is a higher-level method that selects the appropriate operation based on the
   configuration provided.

   - Parameter config: Configuration for the operation
   - Returns: Result of the operation
   - Throws: SecurityError if the operation fails
   */
  public func performSecureOperation(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let operationID=UUID().uuidString
    let startTime=Date()

    // Extract the operation type from the configuration
    guard
      let operationTypeStr=config.options?.metadata?["operationType"],
      let operation=CoreSecurityTypes.SecurityOperation(rawValue: operationTypeStr)
    else {
      throw CoreSecurityError
        .configurationError("Missing or invalid operation type in configuration")
    }

    // Create operating context
    let context=createLogContext(for: config, operationID: operationID)

    await logger.debug(
      "Starting secure operation",
      context: context
    )

    do {
      // Process the operation based on type
      let result: SecurityResultDTO
      switch operation {
        case .encrypt:
          result=try await encrypt(config: config)
        case .decrypt:
          result=try await decrypt(config: config)
        case .hash:
          result=await hash(config: config)
        case .sign:
          result=try await sign(config: config)
        case .verify:
          result=try await verify(config: config)
        case .deriveKey:
          result=try await generateKey(config: config)
        case .storeKey:
          result=try await secureStore(config: config)
        case .retrieveKey:
          result=try await secureRetrieve(config: config)
        case .deleteKey:
          result=try await secureDelete(config: config)
        case .generateRandom:
          result=try await generateRandom(config: config)
        default:
          throw CoreSecurityError.unsupportedOperation(
            reason: "Operation \(operation.rawValue) is not supported by this provider"
          )
      }

      // Calculate duration for metrics
      let duration=Date().timeIntervalSince(startTime)

      // Create logging context with result metadata
      let resultMetadata=LogMetadataDTOCollection([
        "operationId": (value: operationID, privacy: .public),
        "operation": (value: "complete", privacy: .public),
        "durationMs": (value: String(Int(duration * 1000)), privacy: .public),
        "resultSize": (value: String(result.resultData?.count ?? 0), privacy: .public)
      ])

      // Log success
      await logger.debug(
        "Secure operation completed successfully",
        context: resultMetadata
      )

      return result
    } catch {
      // Calculate duration for metrics
      let duration=Date().timeIntervalSince(startTime)

      // Log failure
      let errorContext=createLogContext([
        "operationId": (value: operationID, privacy: .public),
        "operation": (value: "error", privacy: .public),
        "durationMs": (value: String(Int(duration * 1000)), privacy: .public),
        "errorType": (value: String(describing: type(of: error)), privacy: .public),
        "errorDescription": (value: error.localizedDescription, privacy: .private)
      ])

      await logger.error(
        "Secure operation failed",
        context: errorContext
      )

      // Map to security error and re-throw
      if let secError=error as? CoreSecurityTypes.SecurityError {
        throw secError
      } else {
        throw CoreSecurityTypes.SecurityError.unknownError(
          "Operation failed: \(error.localizedDescription)"
        )
      }
    }
  }

  /**
   Securely stores data with the specified configuration.

   - Parameter config: Configuration for the secure storage operation
   - Returns: Result containing storage confirmation or error
   - Throws: SecurityError if storage fails
   */
  public func secureStore(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let operationID=UUID().uuidString
    let startTime=Date()

    // Create logging context for the operation
    let logContext=SecurityLogContext(
      operation: CoreSecurityTypes.SecurityOperation.secureStore.rawValue,
      component: "SecurityProviderImpl",
      operationID: operationID,
      correlationID: nil,
      source: "SecurityImplementation"
    )

    await logger.info("Starting secure storage operation", context: logContext)

    do {
      // Validate required inputs
      guard
        let options=config.options,
        let identifier=options.metadata?["identifier"],
        let inputDataBase64=options.metadata?["data"],
        let inputData=Data(base64Encoded: inputDataBase64)
      else {
        throw CoreSecurityTypes.SecurityError.invalidInputData
      }

      // Store data securely using storage service - directly use bridge method that handles Data
      // type
      try await storageService.secureStore(data: inputData, identifier: identifier)

      // Calculate duration for metrics
      let duration=Date().timeIntervalSince(startTime) * 1000

      // Log success with privacy-aware metadata
      await logger.info(
        "Secure storage operation completed successfully",
        context: logContext.adding(
          key: "identifier",
          value: identifier,
          privacy: .private
        ).adding(
          key: "durationMs",
          value: String(format: "%.2f", duration),
          privacy: .public
        )
      )

      // Return successful result
      return SecurityResultDTO.success(
        resultData: nil,
        executionTimeMs: duration,
        metadata: [
          "durationMs": String(format: "%.2f", duration),
          "identifier": identifier,
          "status": "stored"
        ]
      )
    } catch {
      // Calculate duration before failure
      let duration=Date().timeIntervalSince(startTime) * 1000

      // Log failure with privacy-aware metadata
      let errorContext=logContext.adding(
        key: "errorType",
        value: "\(type(of: error))",
        privacy: .public
      ).adding(
        key: "errorMessage",
        value: error.localizedDescription,
        privacy: .private
      )

      await logger.error(
        "Secure storage operation failed: \(error.localizedDescription)",
        context: errorContext
      )

      // Map to security error and re-throw
      if let secError=error as? CoreSecurityTypes.SecurityError {
        throw secError
      } else {
        throw CoreSecurityTypes.SecurityError.storageOperationFailed(
          reason: "Storage operation failed: \(error.localizedDescription)"
        )
      }
    }
  }

  /**
   Retrieves securely stored data with the specified configuration.

   - Parameter config: Configuration for the secure retrieval operation
   - Returns: Result containing retrieved data or error
   - Throws: SecurityError if retrieval fails
   */
  public func secureRetrieve(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let operationID=UUID().uuidString
    let startTime=Date()

    // Create logging context for the operation
    let logContext=SecurityLogContext(
      operation: CoreSecurityTypes.SecurityOperation.secureRetrieve.rawValue,
      component: "SecurityProviderImpl",
      operationID: operationID,
      correlationID: nil,
      source: "SecurityImplementation"
    )

    await logger.info("Starting secure retrieval operation", context: logContext)

    do {
      // Validate required inputs
      guard
        let options=config.options,
        let identifier=options.metadata?["identifier"]
      else {
        throw CoreSecurityTypes.SecurityError.invalidInputData
      }

      // Retrieve data securely using storage service - use bridge method directly
      let data=try await storageService.secureRetrieve(identifier: identifier)

      // Calculate duration for metrics
      let duration=Date().timeIntervalSince(startTime) * 1000

      // Log success with privacy-aware metadata
      await logger.info(
        "Secure retrieval operation completed successfully",
        context: logContext.adding(
          key: "identifier",
          value: identifier,
          privacy: .private
        ).adding(
          key: "durationMs",
          value: String(format: "%.2f", duration),
          privacy: .public
        )
      )

      // Return successful result
      return SecurityResultDTO.success(
        resultData: data.base64EncodedString(),
        executionTimeMs: duration,
        metadata: [
          "durationMs": String(format: "%.2f", duration),
          "identifier": identifier,
          "status": "retrieved"
        ]
      )
    } catch {
      // Calculate duration before failure
      let duration=Date().timeIntervalSince(startTime) * 1000

      // Log failure with privacy-aware metadata
      let errorContext=logContext.adding(
        key: "errorType",
        value: "\(type(of: error))",
        privacy: .public
      ).adding(
        key: "errorMessage",
        value: error.localizedDescription,
        privacy: .private
      )

      await logger.error(
        "Secure retrieval operation failed: \(error.localizedDescription)",
        context: errorContext
      )

      // Map to security error and re-throw
      if let secError=error as? CoreSecurityTypes.SecurityError {
        throw secError
      } else {
        throw CoreSecurityTypes.SecurityError.retrievalOperationFailed(
          reason: "Retrieval operation failed: \(error.localizedDescription)"
        )
      }
    }
  }

  /**
   Deletes securely stored data with the specified configuration.

   - Parameter config: Configuration for the secure deletion operation
   - Returns: Result containing deletion confirmation or error
   - Throws: SecurityError if deletion fails
   */
  public func secureDelete(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let operationID=UUID().uuidString
    let startTime=Date()

    // Create logging context for the operation
    let logContext=SecurityLogContext(
      operation: CoreSecurityTypes.SecurityOperation.secureDelete.rawValue,
      component: "SecurityProviderImpl",
      operationID: operationID,
      correlationID: nil,
      source: "SecurityImplementation"
    )

    await logger.info("Starting secure deletion operation", context: logContext)

    do {
      // Validate required inputs
      guard
        let options=config.options,
        let identifier=options.metadata?["identifier"]
      else {
        throw CoreSecurityTypes.SecurityError.invalidInputData
      }

      // Delete data securely using storage service - use bridge method directly
      try await storageService.secureDelete(identifier: identifier)

      // Calculate duration for metrics
      let duration=Date().timeIntervalSince(startTime) * 1000

      // Log success with privacy-aware metadata
      await logger.info(
        "Secure deletion operation completed successfully",
        context: logContext.adding(
          key: "identifier",
          value: identifier,
          privacy: .private
        ).adding(
          key: "durationMs",
          value: String(format: "%.2f", duration),
          privacy: .public
        )
      )

      // Return successful result
      return SecurityResultDTO.success(
        resultData: nil,
        executionTimeMs: duration,
        metadata: [
          "durationMs": String(format: "%.2f", duration),
          "identifier": identifier,
          "status": "deleted"
        ]
      )
    } catch {
      // Calculate duration before failure
      let duration=Date().timeIntervalSince(startTime) * 1000

      // Log failure with privacy-aware metadata
      let errorContext=logContext.adding(
        key: "errorType",
        value: "\(type(of: error))",
        privacy: .public
      ).adding(
        key: "errorMessage",
        value: error.localizedDescription,
        privacy: .private
      )

      await logger.error(
        "Secure deletion operation failed: \(error.localizedDescription)",
        context: errorContext
      )

      // Map to security error and re-throw
      if let secError=error as? CoreSecurityTypes.SecurityError {
        throw secError
      } else {
        throw CoreSecurityTypes.SecurityError.deletionOperationFailed(
          reason: "Deletion operation failed: \(error.localizedDescription)"
        )
      }
    }
  }

  /**
   Performs a secure operation with the specified configuration.

   This method is part of the SecurityProviderProtocol and delegates to the appropriate
   specialised methods based on the operation type.

   - Parameters:
     - operation: The type of security operation to perform
     - config: Configuration for the operation
   - Returns: Result of the operation
   - Throws: SecurityError if the operation fails
   */
  public func performSecureOperation(
    operation: CoreSecurityTypes.SecurityOperation,
    config: CoreSecurityTypes.SecurityConfigDTO
  ) async throws -> CoreSecurityTypes.SecurityResultDTO {
    let operationID=UUID().uuidString
    let startTime=Date()

    // Create logging context for the operation
    let logContext=createOperationMetadata(operation, operationID)

    await logger.info("Starting secure operation: \(operation.rawValue)", context: logContext)

    do {
      // Route to the appropriate operation method
      let result: SecurityResultDTO

      switch operation {
        case .encrypt:
          result=try await encrypt(config: config)
        case .decrypt:
          result=try await decrypt(config: config)
        case .sign:
          result=try await sign(config: config)
        case .verify:
          result=try await verify(config: config)
        case .hash:
          result=try await hash(config: config)
        case .verifyHash:
          result=try await verifyHash(config: config)
        case .generateKey:
          result=try await generateKey(config: config)
        case .generateRandom:
          result=try await generateRandom(config: config)
        case .secureStore:
          result=try await secureStore(config: config)
        case .secureRetrieve:
          result=try await secureRetrieve(config: config)
        case .secureDelete:
          result=try await secureDelete(config: config)
        case .importKey:
          result=try await importKey(config: config)
        default:
          // For any unsupported operations
          throw CoreSecurityTypes.SecurityError.unsupportedOperation(
            reason: "Operation \(operation.rawValue) is not supported by this provider"
          )
      }

      // Calculate execution time
      let executionTime=Date().timeIntervalSince(startTime) * 1000

      // Log success with privacy-aware context
      let successContext=logContext
        .adding(key: "status", value: "success", privacy: .public)
        .adding(key: "durationMs", value: String(format: "%.2f", executionTime), privacy: .public)

      await logger.info(
        "Successfully completed \(operation.rawValue) operation",
        context: successContext
      )

      // If the result doesn't have execution time data, add it
      var updatedResult=result
      if result.executionTimeMs == 0 {
        // Create a new result with the actual execution time
        updatedResult=SecurityResultDTO.success(
          resultData: result.resultData,
          executionTimeMs: executionTime,
          metadata: result.metadata ?? [:]
        )
      }

      return updatedResult
    } catch let error as CoreSecurityTypes.SecurityError {
      // For known SecurityError types, log and rethrow
      let errorContext=logContext
        .adding(key: "status", value: "failed", privacy: .public)
        .adding(key: "errorType", value: "\(type(of: error))", privacy: .public)
        .adding(key: "errorDescription", value: error.localizedDescription, privacy: .private)
        .adding(
          key: "durationMs",
          value: String(format: "%.2f", Date().timeIntervalSince(startTime) * 1000),
          privacy: .public
        )

      await logger.error(
        "Security operation \(operation.rawValue) failed: \(error.localizedDescription)",
        context: errorContext
      )

      throw error
    } catch {
      // For generic errors, wrap in SecurityError
      let wrappedError=CoreSecurityTypes.SecurityError.generalError(
        reason: "Unexpected error during \(operation.rawValue) operation: \(error.localizedDescription)"
      )

      let errorContext=logContext
        .adding(key: "status", value: "failed", privacy: .public)
        .adding(key: "errorType", value: "generalError", privacy: .public)
        .adding(
          key: "errorDescription",
          value: wrappedError.localizedDescription,
          privacy: .private
        )
        .adding(
          key: "durationMs",
          value: String(format: "%.2f", Date().timeIntervalSince(startTime) * 1000),
          privacy: .public
        )

      await logger.error(
        "Security operation \(operation.rawValue) failed with unexpected error: \(error.localizedDescription)",
        context: errorContext
      )

      throw wrappedError
    }
  }

  /**
   Extracts the key identifier from the security configuration

   - Parameter config: The security configuration
   - Returns: The key identifier or nil if not found
   */
  private func extractKeyIdentifier(from config: SecurityConfigDTO) -> String? {
    config.options?.metadata?["keyIdentifier"] as? String
  }

  /**
   Generates a cryptographic key with the specified configuration

   - Parameter config: Configuration for the key generation
   - Returns: The result of the key generation operation
   */
  private func generateCryptoKey(config: SecurityConfigDTO) async -> SecurityResultDTO {
    let startTime=Date()
    let operationID=UUID().uuidString

    // Create success context
    let successContext=createLogContext([
      "operationId": (value: operationID, privacy: .public),
      "operation": (value: "generateKey", privacy: .public),
      "algorithm": (value: config.encryptionAlgorithm.rawValue, privacy: .public)
    ])

    // Log operation start
    await logger.debug(
      "Starting key generation operation",
      context: successContext
    )

    do {
      // Extract key size if provided
      let keyLength=32 // AES-256 key length
      var keyData=[UInt8](repeating: 0, count: keyLength)

      // Use secure random generation
      let status=SecRandomCopyBytes(kSecRandomDefault, keyLength, &keyData)

      if status != errSecSuccess {
        throw CoreSecurityError.cryptoError("Random generation failed with status code: \(status)")
      }

      // Log success
      await logger.debug(
        "Key generation completed successfully",
        context: successContext
      )

      // Return result
      return SecurityResultDTO.success(
        resultData: Data(keyData),
        executionTimeMs: Date().timeIntervalSince(startTime) * 1000,
        metadata: nil
      )
    } catch {
      // Calculate duration for metrics
      let duration=Date().timeIntervalSince(startTime)

      // Log failure with privacy-aware context
      let errorContext=createLogContext([
        "operationId": (value: operationID, privacy: .public),
        "operation": (value: "error", privacy: .public),
        "durationMs": (value: String(Int(duration * 1000)), privacy: .public),
        "errorType": (value: String(describing: type(of: error)), privacy: .public)
      ])

      await logger.error(
        "Key generation failed: \(error.localizedDescription)",
        context: errorContext
      )

      // Return failure result
      return SecurityResultDTO.failure(
        errorDetails: String(describing: error),
        executionTimeMs: Date().timeIntervalSince(startTime) * 1000,
        metadata: ["error": String(describing: error)]
      )
    }
  }

  /**
   Securely deletes a key with the specified identifier

   - Parameter config: Configuration for the deletion operation
   - Returns: Result of the deletion operation
   - Throws: SecurityError if deletion fails
   */
  public func secureDelete(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let operationID=UUID().uuidString
    let startTime=Date()

    // Extract key identifier from config
    guard let keyIdentifier=extractKeyIdentifier(from: config) else {
      throw CoreSecurityError.invalidInput("Key identifier is required for secure delete operation")
    }

    // Create log context
    let context=createLogContext(for: config, operationID: operationID)

    await logger.debug(
      "Starting secure delete operation",
      context: context
    )

    do {
      // Delegate to storage service
      let result=try await storageService.secureDelete(keyIdentifier: keyIdentifier)

      // Log success
      await logger.debug(
        "Key deletion completed successfully",
        context: context
      )

      return result
    } catch {
      // Calculate duration for metrics
      let duration=Date().timeIntervalSince(startTime)

      // Log failure
      let errorContext=createLogContext([
        "operationId": (value: operationID, privacy: .public),
        "operation": (value: "error", privacy: .public),
        "durationMs": (value: String(Int(duration * 1000)), privacy: .public),
        "errorType": (value: String(describing: type(of: error)), privacy: .public)
      ])

      await logger.error(
        "Key deletion failed: \(error.localizedDescription)",
        context: errorContext
      )

      // Return failure result
      return SecurityResultDTO.failure(
        errorDetails: String(describing: error),
        executionTimeMs: duration * 1000,
        metadata: ["error": String(describing: error)]
      )
    }
  }

  /**
   Generates random data with the specified configuration

   - Parameter config: Configuration for the random generation operation
   - Returns: Result containing the random data
   - Throws: SecurityError if generation fails
   */
  public func generateRandom(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let operationID=UUID().uuidString
    let startTime=Date()

    // Extract length from operation parameter or use default
    let length: Int=if
      case .generateRandom=CoreSecurityTypes
        .SecurityOperation(rawValue: config.options?.metadata?["operationType"] ?? "")
    {
      // Get the length from metadata
      if let lengthStr=config.options?.metadata?["length"], let parsedLength=Int(lengthStr) {
        parsedLength
      } else {
        32 // Default length for random generation
      }
    } else if let lengthStr=config.options?.metadata?["length"], let parsedLength=Int(lengthStr) {
      parsedLength
    } else {
      32 // Default to 32 bytes if no length specified
    }

    // Create log context
    let context=createLogContext(for: config, operationID: operationID)

    await logger.debug(
      "Starting random data generation operation",
      context: context
    )

    do {
      // Generate random bytes
      var randomData=[UInt8](repeating: 0, count: length)

      // Use secure random generation
      let status=SecRandomCopyBytes(kSecRandomDefault, length, &randomData)

      if status != errSecSuccess {
        throw CoreSecurityError.cryptoError("Random generation failed with status code: \(status)")
      }

      // Log success
      await logger.debug(
        "Random data generation completed successfully",
        context: context
      )

      // Return result
      return SecurityResultDTO.success(
        resultData: Data(randomData),
        executionTimeMs: Date().timeIntervalSince(startTime) * 1000,
        metadata: nil
      )
    } catch {
      // Calculate duration for metrics
      let duration=Date().timeIntervalSince(startTime)

      // Log failure
      let errorContext=createLogContext([
        "operationId": (value: operationID, privacy: .public),
        "operation": (value: "error", privacy: .public),
        "durationMs": (value: String(Int(duration * 1000)), privacy: .public),
        "errorType": (value: String(describing: type(of: error)), privacy: .public)
      ])

      await logger.error(
        "Random data generation failed: \(error.localizedDescription)",
        context: errorContext
      )

      // Return failure result
      return SecurityResultDTO.failure(
        errorDetails: String(describing: error),
        executionTimeMs: duration * 1000,
        metadata: ["error": String(describing: error)]
      )
    }
  }

  /**
   Generates a cryptographic key pair

   - Parameters:
     - algorithm: The algorithm to use for generation
     - keySize: The size of the key to generate
     - config: The configuration for the operation
   - Returns: The generated key pair as a security result
   - Throws: SecurityError if key generation fails
   */
  func generateKeyPair(
    algorithm: CoreSecurityTypes.EncryptionAlgorithm,
    keySize: Int,
    config: SecurityConfigDTO
  ) async throws -> SecurityResultDTO {
    let startTime=Date()
    let operationID=UUID().uuidString

    // Create privacy-aware metadata for logging
    let logContext=SecurityLogContext(
      operation: CoreSecurityTypes.SecurityOperation.generateKey.rawValue,
      component: "KeyManager",
      operationID: operationID,
      correlationID: nil,
      source: "SecurityImplementation"
    )

    await logger.info(
      "Starting key pair generation",
      context: logContext
    )

    do {
      // Create configuration for random generation
      let randomConfig=SecurityConfigDTO(
        encryptionAlgorithm: algorithm,
        hashAlgorithm: .sha256,
        providerType: .basic,
        options: SecurityConfigOptions(
          enableDetailedLogging: true,
          keyDerivationIterations: 10000,
          memoryLimitBytes: 65536,
          useHardwareAcceleration: true,
          operationTimeoutSeconds: 30,
          verifyOperations: true,
          metadata: [
            "bytes": "\(keySize / 8)",
            "purpose": "keyGeneration"
          ]
        )
      )

      // Generate random data for key
      let randomResult=try await generateRandom(config: randomConfig)

      // Extract the generated key data
      guard
        let base64KeyData=randomResult.resultData,
        let keyData=Data(base64Encoded: base64KeyData)
      else {
        throw CoreSecurityTypes.SecurityError.keyGenerationFailed(
          reason: "Failed to decode generated key data"
        )
      }

      // Calculate duration for metrics
      let duration=Date().timeIntervalSince(startTime) * 1000

      // Log success with privacy-aware metadata
      await logger.info(
        "Key pair generation completed successfully",
        context: logContext
      )

      // Store the key if an identifier is provided in the metadata
      if let options=config.options, let keyIdentifier=options.metadata?["keyIdentifier"] {
        try await keyManager.storeKey(keyData, withIdentifier: keyIdentifier)
      }

      // Return successful result
      return SecurityResultDTO.success(
        resultData: keyData.base64EncodedString(),
        executionTimeMs: duration,
        metadata: [
          "durationMs": String(format: "%.2f", duration),
          "algorithm": algorithm.rawValue,
          "keySize": "\(keySize)"
        ]
      )
    } catch {
      // Log failure with privacy-aware metadata
      await logger.error(
        "Key pair generation failed: \(error.localizedDescription)",
        context: logContext
      )

      // Rethrow as security error
      if let secError=error as? CoreSecurityTypes.SecurityError {
        throw secError
      } else {
        throw CoreSecurityTypes.SecurityError.keyGenerationFailed(
          reason: "Key generation failed: \(error.localizedDescription)"
        )
      }
    }
  }

  /**
   Performs a generic secure operation with appropriate error handling.

   - Parameters:
     - operation: The security operation to perform
     - config: Configuration options
   - Returns: Result of the operation
   - Throws: SecurityError if operation fails
   */
  public func performSecureOperation(
    operation: CoreSecurityTypes.SecurityOperation,
    config: SecurityConfigDTO
  ) async throws -> SecurityResultDTO {
    let operationID=UUID().uuidString
    let startTime=Date()

    // Create logging context for the operation
    let logContext=SecurityLogContext(
      operation: operation.rawValue,
      component: "SecurityProviderImpl",
      operationID: operationID,
      correlationID: nil,
      source: "SecurityImplementation"
    )

    await logger.info("Starting secure operation: \(operation.rawValue)", context: logContext)

    do {
      // Delegate to appropriate operation method based on operation type
      let result: SecurityResultDTO

      switch operation {
        case .encrypt:
          result=try await encrypt(config: config)
        case .decrypt:
          result=try await decrypt(config: config)
        case .generateKey:
          result=try await generateKey(config: config)
        case .generateRandom:
          result=try await generateRandom(config: config)
        case .hash:
          result=try await hash(config: config)
        case .sign:
          result=try await sign(config: config)
        case .verify:
          result=try await verify(config: config)
        case .secureStore:
          result=try await secureStore(config: config)
        case .secureRetrieve:
          result=try await secureRetrieve(config: config)
        case .secureDelete:
          result=try await secureDelete(config: config)
        default:
          // Handle unsupported operations
          throw CoreSecurityTypes.SecurityError.unsupportedOperation(
            reason: operation.rawValue
          )
      }

      // Calculate operation duration
      let duration=Date().timeIntervalSince(startTime) * 1000

      // Log operation completion
      await logger.info(
        "Completed secure operation: \(operation.rawValue)",
        context: logContext.adding(
          key: "durationMs",
          value: String(format: "%.2f", duration),
          privacyLevel: .public
        )
      )

      return result
    } catch {
      // Calculate duration before failure
      let duration=Date().timeIntervalSince(startTime) * 1000

      // Log failure with privacy-aware metadata
      let errorContext=logContext.adding(
        key: "errorType",
        value: "\(type(of: error))",
        privacyLevel: .public
      ).adding(
        key: "errorMessage",
        value: error.localizedDescription,
        privacyLevel: .private
      ).adding(
        key: "durationMs",
        value: String(format: "%.2f", duration),
        privacyLevel: .public
      )

      await logger.error(
        "Secure operation failed: \(operation.rawValue): \(error.localizedDescription)",
        context: errorContext
      )

      // Rethrow the error
      throw error
    }
  }

  /**
   Creates a secure configuration with type-safe, Sendable-compliant options.

   This method provides a Swift 6-compatible way to create security configurations
   that can safely cross actor boundaries.

   - Parameter options: Type-safe options structure that conforms to Sendable
   - Returns: A properly configured SecurityConfigDTO
   */
  public func createSecureConfig(options: SecurityConfigOptions) async -> SecurityConfigDTO {
    // Determine appropriate algorithm based on operation if specified
    let algorithm: CoreSecurityTypes.EncryptionAlgorithm
    let hashAlg: CoreSecurityTypes.HashAlgorithm

    if
      let operationStr=options.metadata?["operation"],
      let operation=CoreSecurityTypes.SecurityOperation(rawValue: operationStr)
    {
      // Select appropriate algorithms based on operation type
      switch operation {
        case .encrypt, .decrypt:
          algorithm = .aes256GCM // Prefer AES-GCM for authenticated encryption
          hashAlg = .sha256
        case .hash:
          algorithm = .aes256CBC // Algorithm won't be used for hashing
          hashAlg = .sha256
        case .sign, .verify:
          // Use ecdsaP256SHA256 for sign/verify as it provides better security characteristics
          algorithm = .chacha20Poly1305 // Using ChaCha20 which has good security properties
          hashAlg = .sha384 // Use stronger hash for signatures
        case .generateKey, .generateRandom:
          algorithm = .aes256GCM // Default for key generation
          hashAlg = .sha256
        case .secureStore, .secureRetrieve, .secureDelete,
             .storeKey, .retrieveKey, .deleteKey:
          algorithm = .aes256GCM // Storage operations use this for any internal encryption
          hashAlg = .sha256
        default:
          // Default algorithms for any unspecified operation
          algorithm = .aes256GCM
          hashAlg = .sha256
      }
    } else {
      // Default algorithms when no operation specified
      algorithm = .aes256GCM // Prefer AES-GCM for authenticated encryption as default
      hashAlg = .sha256 // SHA-256 provides good security with reasonable performance
    }

    // Create a well-structured configuration
    return SecurityConfigDTO(
      encryptionAlgorithm: algorithm,
      hashAlgorithm: hashAlg,
      providerType: .basic, // Default to basic provider
      options: options
    )
  }

  private func createDefaultConfig(options: SecurityConfigOptions?=nil) -> SecurityConfigDTO {
    // Create configuration with default values
    SecurityConfigDTO(
      encryptionAlgorithm: .aes256GCM,
      hashAlgorithm: .sha256,
      providerType: .basic,
      options: options
    )
  }

  /**
   Creates a configuration with metadata for an operation

   - Parameters:
     - operation: The security operation to configure
     - options: Optional configuration options
     - data: The operation data (e.g., plaintext)
     - key: Optional key data
   - Returns: A configuration ready for use with a security operation
   */
  private func createOperationConfig(
    operation: CoreSecurityTypes.SecurityOperation,
    options: SecurityConfigOptions?=nil,
    data: Data?=nil,
    key: Data?=nil
  ) -> SecurityConfigDTO {
    createSecurityConfig(operation: operation, options: options, data: data, key: key)
  }

  // MARK: - Service Access

  /**
   Access to cryptographic service implementation

   - Returns: The crypto service instance
   */
  public func cryptoService() async -> CryptoServiceProtocol {
    cryptoServiceInstance
  }

  /**
   Access to key management service implementation

   - Returns: The key manager instance
   */
  public func keyManager() async -> KeyManagementProtocol {
    keyManager
  }
}

extension SecurityProviderImpl {
  /**
   Verifies a hash against input data with the specified configuration

   - Parameter config: Configuration for the hash verification operation
   - Returns: Result indicating whether verification succeeded
   - Throws: SecurityError if verification fails
   */
  public func verifyHash(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let operationID=UUID().uuidString
    let startTime=Date()

    // Create logging context for the operation
    let logContext=SecurityLogContext(
      operation: CoreSecurityTypes.SecurityOperation.verifyHash.rawValue,
      component: "SecurityProviderImpl",
      operationID: operationID,
      correlationID: nil,
      source: "SecurityImplementation"
    )

    await logger.info("Starting hash verification operation", context: logContext)

    do {
      // Extract data and hash to verify from configuration
      guard
        let options=config.options,
        let inputDataBase64=options.metadata?["inputData"],
        let inputData=Data(base64Encoded: inputDataBase64),
        let existingHashBase64=options.metadata?["existingHash"],
        let existingHash=Data(base64Encoded: existingHashBase64)
      else {
        throw CoreSecurityTypes.SecurityError.invalidInputData
      }

      // Get hash algorithm from config or use default
      let algorithm=config.hashAlgorithm

      // Perform hash operation using crypto service
      let newHash=try await cryptoServiceInstance.hash(
        inputData,
        using: algorithm,
        options: options
      )

      // Verify the hash by comparing with existing hash
      let isValid=newHash.elementsEqual(existingHash)

      // Calculate duration for metrics
      let duration=Date().timeIntervalSince(startTime) * 1000

      // Create result with verification status
      var resultMetadata: [String: Any]=options.metadata ?? [:]
      resultMetadata["verified"]=isValid
      resultMetadata["hashAlgorithm"]=algorithm.rawValue

      // Log result with privacy-aware metadata
      var logMetadata=logContext.metadata
      logMetadata=logMetadata.withPublic(key: "algorithm", value: algorithm.rawValue)
      logMetadata=logMetadata.withPublic(key: "durationMs", value: String(format: "%.2f", duration))
      logMetadata=logMetadata.withPublic(key: "verified", value: String(isValid))

      let resultContext=SecurityLogContext(
        operation: CoreSecurityTypes.SecurityOperation.verifyHash.rawValue,
        component: "SecurityProviderImpl",
        operationID: operationID,
        correlationID: nil,
        source: "SecurityImplementation",
        metadata: logMetadata
      )

      await logger.info(
        "Hash verification completed with result: \(isValid)",
        context: resultContext
      )

      // Return result
      return SecurityResultDTO.success(
        resultData: Data(isValid ? [1] : [0]), // Convert boolean to data
        executionTimeMs: duration,
        metadata: resultMetadata
      )
    } catch {
      // Log failure with privacy-aware metadata
      let duration=Date().timeIntervalSince(startTime) * 1000

      var logMetadata=logContext.metadata
      logMetadata=logMetadata.withPublic(key: "durationMs", value: String(format: "%.2f", duration))
      logMetadata=logMetadata.withPublic(key: "status", value: "failed")
      logMetadata=logMetadata.withPublic(
        key: "errorType",
        value: String(describing: type(of: error))
      )
      logMetadata=logMetadata.withPrivate(key: "errorMessage", value: error.localizedDescription)

      let errorContext=SecurityLogContext(
        operation: CoreSecurityTypes.SecurityOperation.verifyHash.rawValue,
        component: "SecurityProviderImpl",
        operationID: operationID,
        correlationID: nil,
        source: "SecurityImplementation",
        metadata: logMetadata
      )

      await logger.error(
        "Hash verification failed: \(error.localizedDescription)",
        context: errorContext
      )

      // Rethrow appropriate error
      if let securityError=error as? CoreSecurityTypes.SecurityError {
        throw securityError
      } else {
        throw CoreSecurityTypes.SecurityError.hashingOperationFailed(
          reason: "Hash verification failed: \(error.localizedDescription)"
        )
      }
    }
  }

  /**
   Imports a cryptographic key with the specified configuration

   - Parameter config: Configuration for the key import operation
   - Returns: Result containing the imported key identifier
   - Throws: SecurityError if key import fails
   */
  public func importKey(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let operationID=UUID().uuidString
    let startTime=Date()

    // Create logging context for the operation
    let logContext=SecurityLogContext(
      operation: CoreSecurityTypes.SecurityOperation.importKey.rawValue,
      component: "SecurityProviderImpl",
      operationID: operationID,
      correlationID: nil,
      source: "SecurityImplementation"
    )

    await logger.info("Starting key import operation", context: logContext)

    do {
      // Extract key data and identifier from configuration
      guard
        let options=config.options,
        let keyDataBase64=options.metadata?["keyData"],
        let keyData=Data(base64Encoded: keyDataBase64),
        let keyIdentifier=options.metadata?["keyIdentifier"]
      else {
        throw CoreSecurityTypes.SecurityError.invalidInputData
      }

      // Additional options for key import
      let keyType=options.metadata?["keyType"] ?? "symmetric"
      let keyAlgorithm=options.metadata?["keyAlgorithm"] ?? config.encryptionAlgorithm.rawValue

      // Import the key using key manager
      let importResult=try await keyManager.importKey(
        keyData: keyData,
        identifier: keyIdentifier,
        additionalInfo: [
          "keyType": keyType,
          "algorithm": keyAlgorithm,
          "createdAt": "\(Date().timeIntervalSince1970)"
        ]
      )

      // Process import result
      switch importResult {
        case let .success(keyMetadata):
          // Calculate duration for metrics
          let duration=Date().timeIntervalSince(startTime) * 1000

          // Create result metadata
          var resultMetadata: [String: Any]=[
            "keyIdentifier": keyIdentifier,
            "keyType": keyType,
            "algorithm": keyAlgorithm
          ]

          // Add any additional metadata from key manager
          for (key, value) in keyMetadata {
            resultMetadata[key]=value
          }

          // Log success with privacy-aware metadata
          var logMetadata=logContext.metadata
          logMetadata=logMetadata.withPublic(
            key: "durationMs",
            value: String(format: "%.2f", duration),
            privacyLevel: .public
          )
          logMetadata=logMetadata.withPublic(key: "keyType", value: keyType)
          logMetadata=logMetadata.withPublic(key: "algorithm", value: keyAlgorithm)
          logMetadata=logMetadata.withPrivate(key: "keyIdentifier", value: keyIdentifier)

          let successContext=SecurityLogContext(
            operation: CoreSecurityTypes.SecurityOperation.importKey.rawValue,
            component: "SecurityProviderImpl",
            operationID: operationID,
            correlationID: nil,
            source: "SecurityImplementation",
            metadata: logMetadata
          )

          await logger.info(
            "Successfully imported key",
            context: successContext
          )

          // Return success with key identifier
          return SecurityResultDTO.success(
            resultData: keyIdentifier.data(using: .utf8) ?? Data(),
            executionTimeMs: duration,
            metadata: resultMetadata
          )

        case let .failure(error):
          throw error
      }
    } catch {
      // Log failure with privacy-aware metadata
      let duration=Date().timeIntervalSince(startTime) * 1000

      var logMetadata=logContext.metadata
      logMetadata=logMetadata.withPublic(key: "durationMs", value: String(format: "%.2f", duration))
      logMetadata=logMetadata.withPublic(key: "status", value: "failed")
      logMetadata=logMetadata.withPublic(
        key: "errorType",
        value: String(describing: type(of: error))
      )
      logMetadata=logMetadata.withPrivate(key: "errorMessage", value: error.localizedDescription)

      let errorContext=SecurityLogContext(
        operation: CoreSecurityTypes.SecurityOperation.importKey.rawValue,
        component: "SecurityProviderImpl",
        operationID: operationID,
        correlationID: nil,
        source: "SecurityImplementation",
        metadata: logMetadata
      )

      await logger.error(
        "Key import failed: \(error.localizedDescription)",
        context: errorContext
      )

      // Rethrow appropriate error
      if let securityError=error as? CoreSecurityTypes.SecurityError {
        throw securityError
      } else {
        throw CoreSecurityTypes.SecurityError.generalError(
          reason: "Key import failed: \(error.localizedDescription)"
        )
      }
    }
  }
}
