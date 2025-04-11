import CommonCrypto
import CoreSecurityTypes
import CryptoTypes
import DomainSecurityTypes
import Foundation
import KeyManagementTypes
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import UmbraErrors

/**
 # SecurityProviderImpl

 Standard implementation of the SecurityProviderProtocol that provides secure
 cryptographic operations, key management, and security configurations.
 */
public actor SecurityProviderImpl: SecurityProviderProtocol {
  // MARK: - Dependencies

  /// Underlying cryptographic service
  private let cryptoServiceInstance: any CryptoServiceProtocol

  /// Key management service for certificate and key operations
  private let keyManagerInstance: any KeyManagementProtocol

  /// Logger for recording security operations with proper privacy controls
  private let logger: any LoggingProtocol

  /// Performance metrics tracker for measuring operation durations
  private let metrics: PerformanceMetricsTracker

  /// Flag indicating whether the provider has been properly initialized
  private var isInitialized: Bool=false

  // MARK: - Initialization

  /**
   Initialises a new SecurityProviderImpl with the specified dependencies.

   - Parameters:
      - cryptoService: Service for cryptographic operations
      - keyManager: Service for key management
      - logger: Logger for recording operations
   */
  public init(
    cryptoService: any CryptoServiceProtocol,
    keyManager: any KeyManagementProtocol,
    logger: any LoggingProtocol
  ) {
    cryptoServiceInstance=cryptoService
    keyManagerInstance=keyManager
    self.logger=logger
    metrics=PerformanceMetricsTracker()
  }

  /**
   Asynchronously initialises the provider, ensuring all dependencies are ready.

   - Throws: SecurityProviderError if initialization fails
   */
  public func initialize() async throws {
    var metadata=PrivacyMetadata()
    metadata["operation"]=PrivacyMetadataValue(value: "initialize", privacy: .public)

    let debugContext=BaseLogContextDTO(
      domainName: "SecurityProvider",
      operation: "initialize",
      category: "Security",
      source: "SecurityProviderImpl",
      metadata: metadata.toLogMetadataDTOCollection()
    )
    await logger.debug(
      "Initializing SecurityProviderImpl",
      context: debugContext
    )

    do {
      // Initialize key manager if needed
      if let asyncInitializable=keyManagerInstance as? AsyncServiceInitializable {
        try await asyncInitializable.initialize()
      }

      // Initialize crypto service if needed
      if let asyncInitializable=cryptoServiceInstance as? AsyncServiceInitializable {
        try await asyncInitializable.initialize()
      }

      isInitialized=true

      let infoContext=BaseLogContextDTO(
        domainName: "SecurityProvider",
        operation: "initialize",
        category: "Security",
        source: "SecurityProviderImpl",
        metadata: LogMetadataDTOCollection().merging(with: metadata.toLogMetadataDTOCollection())
      )
      await logger.info(
        "SecurityProviderImpl initialized successfully",
        context: infoContext
      )
    } catch {
      let errorContext=ErrorLogContext(
        error: error,
        domain: "SecurityProvider",
        source: "SecurityProviderImpl",
        additionalContext: metadata.toLogMetadataDTOCollection()
      )
      await logger.error(
        "Failed to initialize SecurityProviderImpl: \(error.localizedDescription)",
        context: errorContext
      )
      throw SecurityProviderError.initializationFailed(reason: error.localizedDescription)
    }
  }

  /**
   Ensures the provider is initialized before performing operations.

   - Throws: Error if the provider is not initialized
   */
  private func ensureInitialized() async throws {
    if !isInitialized {
      var metadata=PrivacyMetadata()
      metadata["error"]=PrivacyMetadataValue(value: "Provider not initialized", privacy: .public)

      let errorContext=BaseLogContextDTO(
        domainName: "SecurityProvider",
        operation: "initialize",
        category: "Security",
        source: "SecurityProviderImpl",
        metadata: metadata.toLogMetadataDTOCollection()
      )
      await logger.error(
        "Security provider not properly initialized",
        context: errorContext
      )
      throw SecurityProviderError.notInitialized
    }
  }

  /**
   Maps CoreSecurityTypes algorithm to CryptoServices algorithm.

   - Parameter algorithm: The CoreSecurityTypes algorithm
   - Returns: Equivalent algorithm identifier as string
   */
  private func mapToCryptoServicesAlgorithm(_ algorithm: EncryptionAlgorithm) -> String {
    switch algorithm {
      case .aes256CBC:
        "AES-256-CBC"
      case .aes256GCM:
        "AES-256-GCM"
      case .chacha20Poly1305:
        "ChaCha20-Poly1305"
    }
  }

  /**
   Stores data securely with the given identifier.

   - Parameters:
      - data: The data to store
      - identifier: Unique identifier for the data
   - Returns: Success or error result
   */
  private func storeData(
    _ data: [UInt8],
    withIdentifier identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    let secureStorage=cryptoServiceInstance.secureStorage
    return await secureStorage.storeData(data, withIdentifier: identifier)
  }

  /**
   Retrieves data securely by its identifier.

   - Parameter identifier: Unique identifier for the data
   - Returns: The retrieved data or an error
   */
  private func retrieveData(withIdentifier identifier: String) async
  -> Result<[UInt8], SecurityStorageError> {
    let secureStorage=cryptoServiceInstance.secureStorage
    return await secureStorage.retrieveData(withIdentifier: identifier)
  }

  /**
   Deletes data securely by its identifier.

   - Parameter identifier: Unique identifier for the data
   - Returns: Success or error result
   */
  private func deleteData(withIdentifier identifier: String) async
  -> Result<Void, SecurityStorageError> {
    let secureStorage=cryptoServiceInstance.secureStorage
    return await secureStorage.deleteData(withIdentifier: identifier)
  }

  /**
   Stores a cryptographic key with the given parameters.

   - Parameters:
      - key: The key data to store
      - identifier: Unique identifier for the key
      - purpose: Purpose of the key
      - algorithm _: Algorithm the key is intended for
   - Throws: SecurityProviderError if storage fails
   */
  private func storeKey(
    _ key: Data,
    identifier: String,
    purpose: KeyPurpose,
    algorithm _: EncryptionAlgorithm
  ) async throws {
    // Convert Data to [UInt8]
    let keyBytes=[UInt8](key)

    let result=await keyManagerInstance.storeKey(keyBytes, withIdentifier: identifier)

    switch result {
      case .success:
        var metadata=PrivacyMetadata()
        metadata["operation"]=PrivacyMetadataValue(value: "storeKey", privacy: .public)
        metadata["purpose"]=PrivacyMetadataValue(value: purpose.rawValue, privacy: .public)
        metadata["identifier"]=PrivacyMetadataValue(value: identifier, privacy: .private)

        let debugContext=BaseLogContextDTO(
          domainName: "SecurityProvider",
          operation: "storeKey",
          category: "Security",
          source: "SecurityProviderImpl",
          metadata: metadata.toLogMetadataDTOCollection()
        )
        await logger.debug(
          "Successfully stored key",
          context: debugContext
        )

      case let .failure(error):
        throw SecurityProviderError.storageError(error.localizedDescription)
    }
  }

  // MARK: - Service Access

  /// Provides access to the cryptographic service
  public func cryptoService() async -> CryptoServiceProtocol {
    cryptoServiceInstance
  }

  /// Provides access to the key management service
  public func keyManager() async -> KeyManagementProtocol {
    keyManagerInstance
  }

  // MARK: - Core Cryptographic Operations

  /**
   Encrypts data using the configured encryption algorithm.

   - Parameter config: Configuration for the encryption operation
   - Returns: SecurityResultDTO with encrypted data or error details
   */
  public func encrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let startTime=Date().timeIntervalSince1970

    do {
      // Validate initialization
      try await ensureInitialized()

      // Validate input data
      guard
        let inputDataString=config.options?.metadata?["inputData"],
        let dataToEncrypt=Data(base64Encoded: inputDataString)
      else {
        throw SecurityProviderError.invalidInput("Missing or empty input data for encryption")
      }

      // Get or generate key
      let key: [UInt8]
      if
        let keyString=config.options?.metadata?["keyData"],
        let keyData=Data(base64Encoded: keyString)
      {
        key=[UInt8](keyData)
      } else if let keyIdentifier=config.options?.metadata?["keyIdentifier"] {
        // Try to retrieve the key from the key manager
        let keyResult=await keyManagerInstance.retrieveKey(withIdentifier: keyIdentifier)
        switch keyResult {
          case let .success(retrievedKey):
            key=retrievedKey
          case let .failure(error):
            throw SecurityProviderError.keyNotFound(keyIdentifier, error.localizedDescription)
        }
      } else {
        // Generate a temporary key for encryption
        let keyResult=await generateKey(algorithm: config.encryptionAlgorithm)
        switch keyResult {
          case let .success(generatedKey):
            key=generatedKey
          case let .failure(error):
            throw error
        }
      }

      // Basic encryption implementation (this should be replaced with proper algorithm-specific
      // encryption)
      // This is a placeholder implementation
      var encryptedData=[UInt8](dataToEncrypt)
      for i in 0..<encryptedData.count {
        encryptedData[i]=encryptedData[i] ^ key[i % key.count]
      }

      let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000

      // Log the successful operation
      var metadata=PrivacyMetadata()
      metadata["operation"]=PrivacyMetadataValue(value: "encrypt", privacy: .public)
      metadata["algorithm"]=PrivacyMetadataValue(value: config.encryptionAlgorithm.rawValue,
                                                 privacy: .public)
      metadata["execution_time_ms"]=PrivacyMetadataValue(value: String(format: "%.2f",
                                                                       executionTime),
                                                         privacy: .public)

      let debugContext=BaseLogContextDTO(
        domainName: "SecurityProvider",
        operation: "encrypt",
        category: "Security",
        source: "SecurityProviderImpl",
        metadata: metadata.toLogMetadataDTOCollection()
      )
      await logger.debug(
        "Data encrypted successfully",
        context: debugContext
      )

      return SecurityResultDTO.success(
        resultData: Data(encryptedData),
        executionTimeMs: executionTime,
        metadata: [
          "operation": "encrypt",
          "algorithm": config.encryptionAlgorithm.rawValue
        ]
      )

    } catch let error as SecurityProviderError {
      let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000

      var metadata=PrivacyMetadata()
      metadata["operation"]=PrivacyMetadataValue(value: "encrypt", privacy: .public)
      metadata["error"]=PrivacyMetadataValue(value: error.localizedDescription, privacy: .private)

      let errorContext=BaseLogContextDTO(
        domainName: "SecurityProvider",
        operation: "encrypt",
        category: "Security",
        source: "SecurityProviderImpl",
        metadata: metadata.toLogMetadataDTOCollection()
      )
      await logger.error(
        "Encryption operation failed: \(error.localizedDescription)",
        context: errorContext
      )

      return SecurityResultDTO.failure(
        errorDetails: error.localizedDescription,
        executionTimeMs: executionTime
      )

    } catch {
      let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000

      var metadata=PrivacyMetadata()
      metadata["operation"]=PrivacyMetadataValue(value: "encrypt", privacy: .public)
      metadata["error"]=PrivacyMetadataValue(value: "Unexpected error", privacy: .private)

      let errorContext=BaseLogContextDTO(
        domainName: "SecurityProvider",
        operation: "encrypt",
        category: "Security",
        source: "SecurityProviderImpl",
        metadata: metadata.toLogMetadataDTOCollection()
      )
      await logger.error(
        "Unexpected error during encryption: \(error.localizedDescription)",
        context: errorContext
      )

      return SecurityResultDTO.failure(
        errorDetails: "Unexpected error during encryption: \(error.localizedDescription)",
        executionTimeMs: executionTime
      )
    }
  }

  /**
   Decrypts data using the configured encryption algorithm.

   - Parameter config: Configuration for the decryption operation
   - Returns: SecurityResultDTO with decrypted data or error details
   */
  public func decrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let startTime=Date().timeIntervalSince1970

    do {
      // Validate initialization
      try await ensureInitialized()

      // Validate input data
      guard
        let inputDataString=config.options?.metadata?["inputData"],
        let dataToDecrypt=Data(base64Encoded: inputDataString)
      else {
        throw SecurityProviderError.invalidInput("Missing or empty input data for decryption")
      }

      // Get key
      let key: [UInt8]
      if
        let keyString=config.options?.metadata?["keyData"],
        let keyData=Data(base64Encoded: keyString)
      {
        key=[UInt8](keyData)
      } else if let keyIdentifier=config.options?.metadata?["keyIdentifier"] {
        // Try to retrieve the key from the key manager
        let keyResult=await keyManagerInstance.retrieveKey(withIdentifier: keyIdentifier)
        switch keyResult {
          case let .success(retrievedKey):
            key=retrievedKey
          case let .failure(error):
            throw SecurityProviderError.keyNotFound(keyIdentifier, error.localizedDescription)
        }
      } else {
        throw SecurityProviderError
          .invalidParameters("Missing key data or key identifier for decryption")
      }

      // Basic decryption implementation (this should be replaced with proper algorithm-specific
      // decryption)
      // This is a placeholder implementation and matches the encryption method
      var decryptedData=[UInt8](dataToDecrypt)
      for i in 0..<decryptedData.count {
        decryptedData[i]=decryptedData[i] ^ key[i % key.count]
      }

      let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000

      // Log the successful operation
      var metadata=PrivacyMetadata()
      metadata["operation"]=PrivacyMetadataValue(value: "decrypt", privacy: .public)
      metadata["algorithm"]=PrivacyMetadataValue(value: config.encryptionAlgorithm.rawValue,
                                                 privacy: .public)
      metadata["execution_time_ms"]=PrivacyMetadataValue(value: String(format: "%.2f",
                                                                       executionTime),
                                                         privacy: .public)

      let debugContext=BaseLogContextDTO(
        domainName: "SecurityProvider",
        operation: "decrypt",
        category: "Security",
        source: "SecurityProviderImpl",
        metadata: metadata.toLogMetadataDTOCollection()
      )
      await logger.debug(
        "Data decrypted successfully",
        context: debugContext
      )

      return SecurityResultDTO.success(
        resultData: Data(decryptedData),
        executionTimeMs: executionTime,
        metadata: [
          "operation": "decrypt",
          "algorithm": config.encryptionAlgorithm.rawValue
        ]
      )

    } catch let error as SecurityProviderError {
      let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000

      var metadata=PrivacyMetadata()
      metadata["operation"]=PrivacyMetadataValue(value: "decrypt", privacy: .public)
      metadata["error"]=PrivacyMetadataValue(value: error.localizedDescription, privacy: .private)

      let errorContext=BaseLogContextDTO(
        domainName: "SecurityProvider",
        operation: "decrypt",
        category: "Security",
        source: "SecurityProviderImpl",
        metadata: metadata.toLogMetadataDTOCollection()
      )
      await logger.error(
        "Decryption operation failed: \(error.localizedDescription)",
        context: errorContext
      )

      return SecurityResultDTO.failure(
        errorDetails: error.localizedDescription,
        executionTimeMs: executionTime
      )

    } catch {
      let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000

      var metadata=PrivacyMetadata()
      metadata["operation"]=PrivacyMetadataValue(value: "decrypt", privacy: .public)
      metadata["error"]=PrivacyMetadataValue(value: "Unexpected error", privacy: .private)

      let errorContext=BaseLogContextDTO(
        domainName: "SecurityProvider",
        operation: "decrypt",
        category: "Security",
        source: "SecurityProviderImpl",
        metadata: metadata.toLogMetadataDTOCollection()
      )
      await logger.error(
        "Unexpected error during decryption: \(error.localizedDescription)",
        context: errorContext
      )

      return SecurityResultDTO.failure(
        errorDetails: "Unexpected error during decryption: \(error.localizedDescription)",
        executionTimeMs: executionTime
      )
    }
  }

  /**
   Creates a digital signature for data with the specified configuration.

   - Parameter config: Configuration for the digital signature operation
   - Returns: Result containing signature data or error
   - Throws: SecurityProviderError if the operation fails
   */
  public func sign(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let startTime=Date().timeIntervalSince1970

    do {
      // Validate initialization
      try await ensureInitialized()

      // Validate input data
      guard
        let inputDataString=config.options?.metadata?["inputData"],
        let dataToSign=Data(base64Encoded: inputDataString)
      else {
        throw SecurityProviderError.invalidInput("Missing or empty input data for signing")
      }

      // Validate key
      let key: [UInt8]
      if
        let keyString=config.options?.metadata?["keyData"],
        let keyData=Data(base64Encoded: keyString)
      {
        key=[UInt8](keyData)
      } else if let keyIdentifier=config.options?.metadata?["keyIdentifier"] {
        // Try to retrieve the key from the key manager
        let keyResult=await keyManagerInstance.retrieveKey(withIdentifier: keyIdentifier)
        switch keyResult {
          case let .success(retrievedKey):
            key=retrievedKey
          case let .failure(error):
            throw SecurityProviderError.keyNotFound(keyIdentifier, error.localizedDescription)
        }
      } else {
        throw SecurityProviderError
          .invalidParameters("Missing key data or key identifier for signing")
      }

      // Perform HMAC-SHA256 signing
      let signature=hmacSHA256(data: [UInt8](dataToSign), key: key)

      let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000

      // Log the successful operation
      var metadata=PrivacyMetadata()
      metadata["operation"]=PrivacyMetadataValue(value: "sign", privacy: .public)
      metadata["algorithm"]=PrivacyMetadataValue(value: "HMAC-SHA256", privacy: .public)
      metadata["execution_time_ms"]=PrivacyMetadataValue(value: String(format: "%.2f",
                                                                       executionTime),
                                                         privacy: .public)

      let debugContext=BaseLogContextDTO(
        domainName: "SecurityProvider",
        operation: "sign",
        category: "Security",
        source: "SecurityProviderImpl",
        metadata: metadata.toLogMetadataDTOCollection()
      )
      await logger.debug(
        "Data signed successfully using HMAC-SHA256",
        context: debugContext
      )

      return SecurityResultDTO.success(
        resultData: Data(signature),
        executionTimeMs: executionTime,
        metadata: [
          "operation": "sign",
          "algorithm": "HMAC-SHA256"
        ]
      )

    } catch let error as SecurityProviderError {
      let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000

      var metadata=PrivacyMetadata()
      metadata["operation"]=PrivacyMetadataValue(value: "sign", privacy: .public)
      metadata["error"]=PrivacyMetadataValue(value: error.localizedDescription, privacy: .private)

      let errorContext=BaseLogContextDTO(
        domainName: "SecurityProvider",
        operation: "sign",
        category: "Security",
        source: "SecurityProviderImpl",
        metadata: metadata.toLogMetadataDTOCollection()
      )
      await logger.error(
        "Signing operation failed: \(error.localizedDescription)",
        context: errorContext
      )

      return SecurityResultDTO.failure(
        errorDetails: error.localizedDescription,
        executionTimeMs: executionTime
      )

    } catch {
      let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000

      var metadata=PrivacyMetadata()
      metadata["operation"]=PrivacyMetadataValue(value: "sign", privacy: .public)
      metadata["error"]=PrivacyMetadataValue(value: "Unexpected error", privacy: .private)

      let errorContext=BaseLogContextDTO(
        domainName: "SecurityProvider",
        operation: "sign",
        category: "Security",
        source: "SecurityProviderImpl",
        metadata: metadata.toLogMetadataDTOCollection()
      )
      await logger.error(
        "Unexpected error during signing: \(error.localizedDescription)",
        context: errorContext
      )

      return SecurityResultDTO.failure(
        errorDetails: "Unexpected error during signing: \(error.localizedDescription)",
        executionTimeMs: executionTime
      )
    }
  }

  /**
   Verifies a digital signature with the specified configuration.

   - Parameter config: Configuration for the signature verification operation
   - Returns: Result containing verification status or error
   */
  public func verify(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let startTime=Date().timeIntervalSince1970

    do {
      // Validate initialization
      try await ensureInitialized()

      // Validate input data
      guard
        let inputDataString=config.options?.metadata?["inputData"],
        let dataToVerify=Data(base64Encoded: inputDataString)
      else {
        throw SecurityProviderError.invalidInput("Missing or empty input data for verification")
      }

      // Validate signature
      guard
        let signatureString=config.options?.metadata?["signature"],
        let providedSignature=Data(base64Encoded: signatureString)
      else {
        throw SecurityProviderError.invalidInput("Missing or empty signature for verification")
      }

      // Validate key
      let key: [UInt8]
      if
        let keyString=config.options?.metadata?["keyData"],
        let keyData=Data(base64Encoded: keyString)
      {
        key=[UInt8](keyData)
      } else if let keyIdentifier=config.options?.metadata?["keyIdentifier"] {
        // Try to retrieve the key from the key manager
        let keyResult=await keyManagerInstance.retrieveKey(withIdentifier: keyIdentifier)
        switch keyResult {
          case let .success(retrievedKey):
            key=retrievedKey
          case let .failure(error):
            throw SecurityProviderError.keyNotFound(keyIdentifier, error.localizedDescription)
        }
      } else {
        throw SecurityProviderError
          .invalidParameters("Missing key data or key identifier for verification")
      }

      // Generate expected signature using HMAC-SHA256
      let expectedSignature=hmacSHA256(data: [UInt8](dataToVerify), key: key)

      // Compare provided signature with expected signature
      let signatureIsValid=constantTimeEqual(
        expectedSignature,
        [UInt8](providedSignature)
      )

      let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000

      // Log the verification result
      var metadata=PrivacyMetadata()
      metadata["operation"]=PrivacyMetadataValue(value: "verify", privacy: .public)
      metadata["algorithm"]=PrivacyMetadataValue(value: "HMAC-SHA256", privacy: .public)
      metadata["result"]=PrivacyMetadataValue(value: signatureIsValid ? "valid" : "invalid",
                                              privacy: .public)
      metadata["execution_time_ms"]=PrivacyMetadataValue(value: String(format: "%.2f",
                                                                       executionTime),
                                                         privacy: .public)

      let debugContext=BaseLogContextDTO(
        domainName: "SecurityProvider",
        operation: "verify",
        category: "Security",
        source: "SecurityProviderImpl",
        metadata: metadata.toLogMetadataDTOCollection()
      )
      await logger.debug(
        "Signature verification result: \(signatureIsValid ? "valid" : "invalid")",
        context: debugContext
      )

      return SecurityResultDTO.success(
        resultData: Data([UInt8(signatureIsValid ? 1 : 0)]),
        executionTimeMs: executionTime,
        metadata: [
          "operation": "verify",
          "algorithm": "HMAC-SHA256",
          "signature_valid": String(signatureIsValid)
        ]
      )

    } catch let error as SecurityProviderError {
      let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000

      var metadata=PrivacyMetadata()
      metadata["operation"]=PrivacyMetadataValue(value: "verify", privacy: .public)
      metadata["error"]=PrivacyMetadataValue(value: error.localizedDescription, privacy: .private)

      let errorContext=BaseLogContextDTO(
        domainName: "SecurityProvider",
        operation: "verify",
        category: "Security",
        source: "SecurityProviderImpl",
        metadata: metadata.toLogMetadataDTOCollection()
      )
      await logger.error(
        "Verification operation failed: \(error.localizedDescription)",
        context: errorContext
      )

      return SecurityResultDTO.failure(
        errorDetails: error.localizedDescription,
        executionTimeMs: executionTime
      )

    } catch {
      let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000

      var metadata=PrivacyMetadata()
      metadata["operation"]=PrivacyMetadataValue(value: "verify", privacy: .public)
      metadata["error"]=PrivacyMetadataValue(value: "Unexpected error", privacy: .private)

      let errorContext=BaseLogContextDTO(
        domainName: "SecurityProvider",
        operation: "verify",
        category: "Security",
        source: "SecurityProviderImpl",
        metadata: metadata.toLogMetadataDTOCollection()
      )
      await logger.error(
        "Unexpected error during verification: \(error.localizedDescription)",
        context: errorContext
      )

      return SecurityResultDTO.failure(
        errorDetails: "Unexpected error during verification: \(error.localizedDescription)",
        executionTimeMs: executionTime
      )
    }
  }

  /**
   Computes a cryptographic hash with the specified configuration.

   - Parameter config: Configuration for the hashing operation
   - Returns: Result containing hash data or error
   */
  public func hash(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let startTime=Date().timeIntervalSince1970

    do {
      // Validate initialization
      try await ensureInitialized()

      // Extract hash algorithm from configuration
      let algorithm=config.hashAlgorithm

      // Create context for logging
      var metadata=PrivacyMetadata()
      metadata["operation"]=PrivacyMetadataValue(value: "hash", privacy: .public)
      metadata["algorithm"]=PrivacyMetadataValue(value: algorithm.rawValue, privacy: .public)

      let logContext=BaseLogContextDTO(
        domainName: "SecurityProvider",
        operation: "hash",
        category: "Security",
        source: "SecurityProviderImpl",
        metadata: metadata.toLogMetadataDTOCollection()
      )

      await logger.debug(
        "Computing hash using algorithm: \(algorithm.rawValue)",
        context: logContext
      )

      // Get data identifier from options
      guard let dataIdentifier=config.options?.metadata?["dataIdentifier"] as? String else {
        throw SecurityProtocolError.inputError("Missing data identifier")
      }

      // Create hashing options
      let hashingOptions=HashingOptions(
        algorithm: algorithm
      )

      // Delegate to the crypto service
      let hashResult=await cryptoServiceInstance.hash(
        dataIdentifier: dataIdentifier,
        options: hashingOptions
      )

      // Map result to SecurityResultDTO
      let resultDTO: SecurityResultDTO
      switch hashResult {
        case let .success(hashIdentifier):
          // Successful hash operation
          let executionTime=Date().timeIntervalSince1970 - startTime
          let hashData=hashIdentifier.data(using: String.Encoding.utf8)

          resultDTO=SecurityResultDTO.success(
            resultData: hashData,
            executionTimeMs: executionTime * 1000,
            metadata: ["hashIdentifier": hashIdentifier]
          )

          // Log success
          let successContext=logContext.withUpdatedMetadata(
            logContext.metadata
              .withPublic(
                key: "executionTimeMs",
                value: String(format: "%.2f", executionTime * 1000)
              )
              .withPrivate(key: "hashIdentifier", value: hashIdentifier)
          )

          await logger.info(
            "Successfully computed hash",
            context: successContext
          )
        case let .failure(error):
          // Failed hash operation
          let executionTime=Date().timeIntervalSince1970 - startTime
          resultDTO=SecurityResultDTO.failure(
            errorDetails: error.localizedDescription,
            executionTimeMs: executionTime * 1000
          )

          // Log error
          let errorContext=logContext.withUpdatedMetadata(
            logContext.metadata.withPublic(key: "error", value: error.localizedDescription)
          )

          await logger.error(
            "Hash operation failed: \(error.localizedDescription)",
            context: errorContext
          )

          throw mapToProtocolError(error)
      }

      return resultDTO
    } catch {
      // Log and rethrow
      var metadata=PrivacyMetadata()
      metadata["operation"]=PrivacyMetadataValue(value: "hash", privacy: .public)
      metadata["error"]=PrivacyMetadataValue(value: error.localizedDescription, privacy: .public)

      let errorContext=BaseLogContextDTO(
        domainName: "SecurityProvider",
        operation: "hash",
        category: "Security",
        source: "SecurityProviderImpl",
        metadata: metadata.toLogMetadataDTOCollection()
      )

      await logger.error(
        "Hash operation failed with error: \(error.localizedDescription)",
        context: errorContext
      )

      throw mapToProtocolError(error)
    }
  }

  /**
   Verifies a hash against data with the specified configuration.

   - Parameter config: Configuration for the hash verification operation
   - Returns: Result containing verification status or error
   */
  public func verifyHash(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let startTime=Date().timeIntervalSince1970

    do {
      // Validate initialization
      try await ensureInitialized()

      // Extract hash algorithm from configuration
      let algorithm=config.hashAlgorithm

      // Create context for logging
      var metadata=PrivacyMetadata()
      metadata["operation"]=PrivacyMetadataValue(value: "verifyHash", privacy: .public)
      metadata["algorithm"]=PrivacyMetadataValue(value: algorithm.rawValue, privacy: .public)

      let logContext=BaseLogContextDTO(
        domainName: "SecurityProvider",
        operation: "verifyHash",
        category: "Security",
        source: "SecurityProviderImpl",
        metadata: metadata.toLogMetadataDTOCollection()
      )

      await logger.debug(
        "Verifying hash using algorithm: \(algorithm.rawValue)",
        context: logContext
      )

      // Get identifiers from options
      guard
        let dataIdentifier=config.options?.metadata?["dataIdentifier"] as? String,
        let hashIdentifier=config.options?.metadata?["hashIdentifier"] as? String
      else {
        throw SecurityProtocolError.inputError("Missing data or hash identifier")
      }

      // Create hashing options
      let hashingOptions=HashingOptions(
        algorithm: algorithm
      )

      // Delegate to the crypto service
      let verifyResult=await cryptoServiceInstance.verifyHash(
        dataIdentifier: dataIdentifier,
        hashIdentifier: hashIdentifier,
        options: hashingOptions
      )

      // Map result to SecurityResultDTO
      let resultDTO: SecurityResultDTO
      switch verifyResult {
        case let .success(isValid):
          // Successful verification
          let executionTime=Date().timeIntervalSince1970 - startTime
          let resultByte: UInt8=isValid ? 1 : 0
          let resultData=Data([resultByte])

          resultDTO=SecurityResultDTO.success(
            resultData: resultData,
            executionTimeMs: executionTime * 1000,
            metadata: ["isValid": isValid ? "true" : "false"]
          )

          // Log success
          let successContext=logContext.withUpdatedMetadata(
            logContext.metadata
              .withPublic(
                key: "executionTimeMs",
                value: String(format: "%.2f", executionTime * 1000)
              )
              .withPublic(key: "isValid", value: "\(isValid)")
          )

          await logger.info(
            "Hash verification result: \(isValid ? "Valid" : "Invalid")",
            context: successContext
          )
        case let .failure(error):
          // Failed verification
          let executionTime=Date().timeIntervalSince1970 - startTime
          resultDTO=SecurityResultDTO.failure(
            errorDetails: error.localizedDescription,
            executionTimeMs: executionTime * 1000
          )

          // Log error
          let errorContext=logContext.withUpdatedMetadata(
            logContext.metadata.withPublic(key: "error", value: error.localizedDescription)
          )

          await logger.error(
            "Hash verification failed: \(error.localizedDescription)",
            context: errorContext
          )

          throw mapToProtocolError(error)
      }

      return resultDTO
    } catch {
      // Log and rethrow
      var metadata=PrivacyMetadata()
      metadata["operation"]=PrivacyMetadataValue(value: "verifyHash", privacy: .public)
      metadata["error"]=PrivacyMetadataValue(value: error.localizedDescription, privacy: .public)

      let errorContext=BaseLogContextDTO(
        domainName: "SecurityProvider",
        operation: "verifyHash",
        category: "Security",
        source: "SecurityProviderImpl",
        metadata: metadata.toLogMetadataDTOCollection()
      )

      await logger.error(
        "Hash verification failed with error: \(error.localizedDescription)",
        context: errorContext
      )

      throw mapToProtocolError(error)
    }
  }

  /**
   Maps internal errors to standardised protocol errors.

   - Parameter error: The internal error to map
   - Returns: A SecurityProtocolError representing the error
   */
  private func mapToProtocolError(_ error: Error) -> SecurityProtocolError {
    if let protocolError=error as? SecurityProtocolError {
      protocolError
    } else if let storageError=error as? SecurityStorageError {
      // Convert storage errors to protocol errors directly
      switch storageError {
        case .storageUnavailable:
          .operationFailed(reason: "Secure storage is not available")
        case .dataNotFound:
          .operationFailed(reason: "Data not found in secure storage")
        case .keyNotFound:
          .operationFailed(reason: "Key not found in secure storage")
        case .hashNotFound:
          .operationFailed(reason: "Hash not found in secure storage")
        case .encryptionFailed:
          .operationFailed(reason: "Encryption operation failed")
        case .decryptionFailed:
          .operationFailed(reason: "Decryption operation failed")
        case .hashingFailed:
          .operationFailed(reason: "Hash operation failed")
        case .hashVerificationFailed:
          .operationFailed(reason: "Hash verification failed")
        case .keyGenerationFailed:
          .operationFailed(reason: "Key generation failed")
        case let .invalidIdentifier(reason):
          .operationFailed(reason: "Invalid identifier: \(reason)")
        case let .identifierNotFound(identifier):
          .operationFailed(reason: "Identifier not found: \(identifier)")
        case let .storageFailure(reason):
          .operationFailed(reason: "Storage failure: \(reason)")
        case let .generalError(reason):
          .operationFailed(reason: "General error: \(reason)")
        case .unsupportedOperation:
          .operationFailed(reason: "The operation is not supported")
        case .implementationUnavailable:
          .operationFailed(reason: "The protocol implementation is not available")
        case let .operationFailed(message):
          .operationFailed(reason: message)
        case let .invalidInput(message):
          .inputError(message)
        case .operationRateLimited:
          .operationFailed(reason: "Operation was rate limited for security purposes")
        case .storageError:
          .operationFailed(reason: "Generic storage error occurred")
      }
    } else if let securityError=error as? SecurityError {
      switch securityError {
        case let .encryptionFailed(reason):
          .operationFailed(reason: "Encryption failed: \(reason ?? "Unknown reason")")
        case let .decryptionFailed(reason):
          .operationFailed(reason: "Decryption failed: \(reason ?? "Unknown reason")")
        case let .hashingFailed(reason):
          .operationFailed(reason: "Hashing failed: \(reason ?? "Unknown reason")")
        case let .keyGenerationFailed(reason):
          .operationFailed(reason: "Key generation failed: \(reason ?? "Unknown reason")")
        case let .keyStorageFailed(reason):
          .operationFailed(reason: "Key storage failed: \(reason ?? "Unknown reason")")
        case let .keyRetrievalFailed(reason):
          .operationFailed(reason: "Key retrieval failed: \(reason ?? "Unknown reason")")
        case let .keyDeletionFailed(reason):
          .operationFailed(reason: "Key deletion failed: \(reason ?? "Unknown reason")")
        case let .signingFailed(reason):
          .operationFailed(reason: "Signing failed: \(reason ?? "Unknown reason")")
        case let .verificationFailed(reason):
          .operationFailed(reason: "Verification failed: \(reason ?? "Unknown reason")")
        case let .invalidInputData(reason):
          .inputError("Invalid input data: \(reason ?? "Unknown reason")")
        case let .invalidConfiguration(reason):
          .operationFailed(reason: "Invalid configuration: \(reason ?? "Unknown reason")")
        case let .algorithmNotSupported(reason):
          .operationFailed(reason: "Algorithm not supported: \(reason ?? "Unknown reason")")
        case .secureEnclaveUnavailable:
          .operationFailed(reason: "Secure Enclave is not available")
        case .operationCancelled:
          .operationFailed(reason: "Operation was cancelled")
        case let .underlyingError(underlyingError):
          .operationFailed(reason: "Internal error: \(underlyingError.localizedDescription)")
        case let .unknownError(message):
          .operationFailed(reason: "Unknown error: \(message ?? "No details")")
        case let .generalError(reason):
          .operationFailed(reason: reason)
        case let .unsupportedOperation(reason):
          .operationFailed(reason: "Unsupported operation: \(reason)")
        case let .deletionOperationFailed(reason):
          .operationFailed(reason: "Deletion failed: \(reason)")
        case let .hashingOperationFailed(reason):
          .operationFailed(reason: "Hashing operation failed: \(reason)")
      }
    } else {
      .operationFailed(reason: error.localizedDescription)
    }
  }

  /**
   Performs a generic secure operation with appropriate error handling.

   - Parameters:
      - operation: The security operation to perform
      - config: Configuration options
   - Returns: Result of the operation
   */
  public func performSecureOperation(
    operation: SecurityOperation,
    config: SecurityConfigDTO
  ) async throws -> SecurityResultDTO {
    // Verify initialization
    try await ensureInitialized()

    // Log operation with privacy metadata
    var metadata=PrivacyMetadata()
    metadata["operation"]=PrivacyMetadataValue(value: operation.rawValue, privacy: .public)
    metadata["provider"]=PrivacyMetadataValue(value: "basic", privacy: .public)

    let debugContext=BaseLogContextDTO(
      domainName: "SecurityProvider",
      operation: "performSecureOperation",
      category: "Security",
      source: "SecurityProviderImpl",
      metadata: metadata.toLogMetadataDTOCollection()
    )
    await logger.debug(
      "Performing security operation: \(operation.rawValue)",
      context: debugContext
    )

    let startTime=Date().timeIntervalSince1970

    switch operation {
      case .encrypt:
        return try await encrypt(config: config)
      case .decrypt:
        return try await decrypt(config: config)
      case .sign:
        return try await sign(config: config)
      case .verify:
        return try await verify(config: config)
      case .hash:
        return try await hash(config: config)
      case .verifyHash:
        return try await verifyHash(config: config)
      case .deriveKey:
        // Implementation for deriveKey operation
        let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000
        return SecurityResultDTO.failure(
          errorDetails: "Key derivation not implemented",
          executionTimeMs: executionTime
        )
      case .generateRandom:
        // Implementation for generateRandom operation
        let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000
        return SecurityResultDTO.failure(
          errorDetails: "Random generation not implemented",
          executionTimeMs: executionTime
        )
      case .storeKey:
        // Implementation for storeKey operation
        let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000
        return SecurityResultDTO.failure(
          errorDetails: "Key storage not implemented",
          executionTimeMs: executionTime
        )
      case .retrieveKey:
        // Implementation for retrieveKey operation
        let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000
        return SecurityResultDTO.failure(
          errorDetails: "Key retrieval not implemented",
          executionTimeMs: executionTime
        )
      case .deleteKey:
        // Implementation for deleteKey operation
        let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000
        return SecurityResultDTO.failure(
          errorDetails: "Key deletion not implemented",
          executionTimeMs: executionTime
        )
    }
  }

  /**
   Performs a security operation with given options.

   - Parameters:
      - operation: The security operation to perform
      - options: Configuration options
   - Returns: Result of the operation
   */
  public func performOperationWithOptions(
    operation: SecurityOperation,
    options: SecurityConfigOptions
  ) async throws -> SecurityResultDTO {
    // Log operation with privacy metadata
    var metadata=PrivacyMetadata()
    metadata["operation"]=PrivacyMetadataValue(value: operation.rawValue, privacy: .public)
    metadata["provider_type"]=PrivacyMetadataValue(value: "basic", privacy: .public)

    let debugContext=BaseLogContextDTO(
      domainName: "SecurityProvider",
      operation: "performOperationWithOptions",
      category: "Security",
      source: "SecurityProviderImpl",
      metadata: metadata.toLogMetadataDTOCollection()
    )
    await logger.debug(
      "Performing security operation with options: \(operation.rawValue)",
      context: debugContext
    )

    let config=SecurityConfigDTO(
      encryptionAlgorithm: .aes256GCM, // Default algorithm
      hashAlgorithm: .sha256, // Default algorithm
      providerType: .basic, // Basic provider type
      options: options
    )

    return try await performSecureOperation(operation: operation, config: config)
  }

  /**
   Generates an appropriate key for a given encryption algorithm.

   This method follows the Alpha Dot Five Architecture principles for key management
   by generating cryptographically secure keys with appropriate size for the algorithm.

   - Parameters:
      - algorithm: The encryption algorithm to generate a key for
   - Returns: The generated key as a Result type
   */
  public func generateKey(
    algorithm: EncryptionAlgorithm
  ) async -> Result<[UInt8], SecurityProviderError> {
    // Log operation with privacy metadata
    var metadata=PrivacyMetadata()
    metadata["operation"]=PrivacyMetadataValue(value: "generateKey", privacy: .public)
    metadata["algorithm"]=PrivacyMetadataValue(value: algorithm.rawValue, privacy: .public)

    let debugContext=BaseLogContextDTO(
      domainName: "SecurityProvider",
      operation: "generateKey",
      category: "Security",
      source: "SecurityProviderImpl",
      metadata: metadata.toLogMetadataDTOCollection()
    )
    await logger.debug(
      "Generating key for algorithm: \(algorithm.rawValue)",
      context: debugContext
    )

    // Determine key size based on the encryption algorithm
    let keySize=switch algorithm {
      case .aes256CBC, .aes256GCM:
        32 // 256 bits = 32 bytes
      case .chacha20Poly1305:
        32 // 256 bits = 32 bytes
    }

    // Create a buffer to hold the key data
    var keyData=[UInt8](repeating: 0, count: keySize)

    // Generate random bytes using CommonCrypto
    let result=CCRandomGenerateBytes(&keyData, keySize)
    if result == kCCSuccess {
      return .success(keyData)
    } else {
      var metadata=PrivacyMetadata()
      metadata["error"]=PrivacyMetadataValue(value: "Failed to generate key", privacy: .public)

      let errorContext=BaseLogContextDTO(
        domainName: "SecurityProvider",
        operation: "generateKey",
        category: "Security",
        source: "SecurityProviderImpl",
        metadata: metadata.toLogMetadataDTOCollection()
      )
      await logger.error(
        "Failed to generate key: CCRandomGenerateBytes error code \(result)",
        context: errorContext
      )
      return .failure(.keyGenerationFailed("Failed to generate secure random key data"))
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
    var metadata=PrivacyMetadata()
    metadata["operation"]=PrivacyMetadataValue(value: "createSecureConfig", privacy: .public)

    let debugContext=BaseLogContextDTO(
      domainName: "SecurityProvider",
      operation: "createSecureConfig",
      category: "Security",
      source: "SecurityProviderImpl",
      metadata: metadata.toLogMetadataDTOCollection()
    )
    await logger.debug(
      "Creating secure configuration",
      context: debugContext
    )

    // Create a security config with the provided options
    let config=SecurityConfigDTO(
      encryptionAlgorithm: .aes256GCM,
      hashAlgorithm: .sha256,
      providerType: .basic,
      options: options
    )

    return config
  }

  /**
   Executes a security operation with the provided configuration options.

   - Parameters:
      - operation: Type of security operation to perform
      - options: Configuration options
   - Returns: Result of the operation
   */
  public func performOperationWithOptions(
    _ operation: SecurityOperation,
    options: SecurityConfigOptions
  ) async throws -> SecurityResultDTO {
    // Log operation with privacy metadata
    var metadata=PrivacyMetadata()
    metadata["operation"]=PrivacyMetadataValue(value: operation.rawValue, privacy: .public)
    metadata["provider_type"]=PrivacyMetadataValue(value: "basic", privacy: .public)

    let debugContext=BaseLogContextDTO(
      domainName: "SecurityProvider",
      operation: "performOperationWithOptions",
      category: "Security",
      source: "SecurityProviderImpl",
      metadata: metadata.toLogMetadataDTOCollection()
    )
    await logger.debug(
      "Performing security operation with options: \(operation.rawValue)",
      context: debugContext
    )

    // Create a security config with the provided options
    let config=SecurityConfigDTO(
      encryptionAlgorithm: .aes256GCM, // Default algorithm
      hashAlgorithm: .sha256, // Default algorithm
      providerType: .basic, // Standard provider type
      options: options
    )

    return try await performSecureOperation(operation: operation, config: config)
  }

  /**
   Generates a cryptographic key with the specified configuration.

   - Parameter config: Configuration for the key generation operation
   - Returns: Result containing key identifier or error
   */
  public func generateKey(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let startTime=Date().timeIntervalSince1970

    do {
      // Validate initialization
      try await ensureInitialized()

      // Generate a unique identifier for this key
      let keyIdentifier=UUID().uuidString

      // Determine key size based on the encryption algorithm
      let keySize=switch config.encryptionAlgorithm {
        case .aes256CBC, .aes256GCM:
          32 // 256 bits = 32 bytes
        case .chacha20Poly1305:
          32 // 256 bits = 32 bytes
      }

      // Create a buffer to hold the key data
      var keyData=[UInt8](repeating: 0, count: keySize)

      // Generate random bytes using CommonCrypto
      let result=CCRandomGenerateBytes(&keyData, keySize)

      if result != kCCSuccess {
        throw SecurityProviderError.keyGenerationFailed("Failed to generate secure random key data")
      }

      // Store the key if metadata indicates it should be persisted
      if let shouldPersist=config.options?.metadata?["persistKey"], shouldPersist == "true" {
        let storeResult=await keyManagerInstance.storeKey(keyData, withIdentifier: keyIdentifier)

        if case let .failure(error)=storeResult {
          throw SecurityProviderError
            .storageError("Failed to store generated key: \(error.localizedDescription)")
        }
      }

      let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000

      // Log the successful operation
      var metadata=PrivacyMetadata()
      metadata["operation"]=PrivacyMetadataValue(value: "generateKey", privacy: .public)
      metadata["algorithm"]=PrivacyMetadataValue(value: config.encryptionAlgorithm.rawValue,
                                                 privacy: .public)
      metadata["key_identifier"]=PrivacyMetadataValue(value: keyIdentifier, privacy: .private)

      let debugContext=BaseLogContextDTO(
        domainName: "SecurityProvider",
        operation: "generateKey",
        category: "Security",
        source: "SecurityProviderImpl",
        metadata: metadata.toLogMetadataDTOCollection()
      )
      await logger.debug(
        "Key generated successfully",
        context: debugContext
      )

      // Return success with key data
      return SecurityResultDTO.success(
        resultData: Data(keyData),
        executionTimeMs: executionTime,
        metadata: [
          "operation": "generateKey",
          "algorithm": config.encryptionAlgorithm.rawValue,
          "key_identifier": keyIdentifier
        ]
      )

    } catch let error as SecurityProviderError {
      let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000

      var metadata=PrivacyMetadata()
      metadata["operation"]=PrivacyMetadataValue(value: "generateKey", privacy: .public)
      metadata["error"]=PrivacyMetadataValue(value: error.localizedDescription, privacy: .private)

      let errorContext=BaseLogContextDTO(
        domainName: "SecurityProvider",
        operation: "generateKey",
        category: "Security",
        source: "SecurityProviderImpl",
        metadata: metadata.toLogMetadataDTOCollection()
      )
      await logger.error(
        "Key generation failed: \(error.localizedDescription)",
        context: errorContext
      )

      return SecurityResultDTO.failure(
        errorDetails: error.localizedDescription,
        executionTimeMs: executionTime
      )

    } catch {
      let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000

      var metadata=PrivacyMetadata()
      metadata["operation"]=PrivacyMetadataValue(value: "generateKey", privacy: .public)
      metadata["error"]=PrivacyMetadataValue(value: "Unexpected error", privacy: .private)

      let errorContext=BaseLogContextDTO(
        domainName: "SecurityProvider",
        operation: "generateKey",
        category: "Security",
        source: "SecurityProviderImpl",
        metadata: metadata.toLogMetadataDTOCollection()
      )
      await logger.error(
        "Unexpected error during key generation: \(error.localizedDescription)",
        context: errorContext
      )

      return SecurityResultDTO.failure(
        errorDetails: "Unexpected error during key generation: \(error.localizedDescription)",
        executionTimeMs: executionTime
      )
    }
  }

  /**
   Securely stores data with the specified configuration.

   - Parameter config: Configuration for the secure storage operation
   - Returns: Result containing storage confirmation or error
   */
  public func secureStore(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    try await ensureInitialized()

    let startTime=Date().timeIntervalSince1970

    var metadata=PrivacyMetadata()
    metadata["operation"]=PrivacyMetadataValue(value: "secureStore", privacy: .public)

    do {
      guard
        let inputDataStr=config.options?.metadata?["inputData"],
        let inputData=Data(base64Encoded: inputDataStr)
      else {
        throw SecurityProviderError.invalidInput("Input data is required for secure storage")
      }

      guard let identifier=config.options?.metadata?["identifier"] else {
        throw SecurityProviderError.invalidInput("Identifier is required for secure storage")
      }

      let secureStorage=cryptoServiceInstance.secureStorage
      let storeResult=await secureStorage.storeData(Array(inputData), withIdentifier: identifier)

      guard case .success=storeResult else {
        throw SecurityProviderError.operationFailed(
          operation: "secureStore",
          reason: "Storage operation failed"
        )
      }

      let endTime=Date().timeIntervalSince1970
      let executionTime=(endTime - startTime) * 1000

      let debugContext=BaseLogContextDTO(
        domainName: "SecurityProvider",
        operation: "secureStore",
        category: "Security",
        source: "SecurityProviderImpl",
        metadata: metadata.toLogMetadataDTOCollection()
      )
      await logger.debug(
        "Secure storage completed successfully",
        context: debugContext
      )

      return SecurityResultDTO.success(
        executionTimeMs: executionTime,
        metadata: [
          "operation": "secureStore",
          "identifier": identifier
        ]
      )
    } catch {
      let endTime=Date().timeIntervalSince1970
      let executionTime=(endTime - startTime) * 1000

      let errorContext=BaseLogContextDTO(
        domainName: "SecurityProvider",
        operation: "secureStore",
        category: "Security",
        source: "SecurityProviderImpl",
        metadata: metadata.toLogMetadataDTOCollection()
      )
      await logger.error(
        "Secure storage failed: \(error.localizedDescription)",
        context: errorContext
      )

      return SecurityResultDTO.failure(
        errorDetails: error.localizedDescription,
        executionTimeMs: executionTime,
        metadata: [
          "operation": "secureStore"
        ]
      )
    }
  }

  /**
   Retrieves securely stored data with the specified configuration.

   - Parameter config: Configuration for the secure retrieval operation
   - Returns: Result containing retrieved data or error
   */
  public func secureRetrieve(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    try await ensureInitialized()

    let startTime=Date().timeIntervalSince1970

    var metadata=PrivacyMetadata()
    metadata["operation"]=PrivacyMetadataValue(value: "secureRetrieve", privacy: .public)

    do {
      guard let identifier=config.options?.metadata?["identifier"] else {
        throw SecurityProviderError.invalidInput("Identifier is required for secure retrieval")
      }

      let secureStorage=cryptoServiceInstance.secureStorage
      let dataResult=await secureStorage.retrieveData(withIdentifier: identifier)

      switch dataResult {
        case let .success(data):
          let endTime=Date().timeIntervalSince1970
          let executionTime=(endTime - startTime) * 1000

          let debugContext=BaseLogContextDTO(
            domainName: "SecurityProvider",
            operation: "secureRetrieve",
            category: "Security",
            source: "SecurityProviderImpl",
            metadata: metadata.toLogMetadataDTOCollection()
          )
          await logger.debug(
            "Secure retrieval completed successfully",
            context: debugContext
          )

          return SecurityResultDTO.success(
            resultData: Data(data),
            executionTimeMs: executionTime,
            metadata: [
              "operation": "secureRetrieve",
              "identifier": identifier
            ]
          )
        case let .failure(error):
          throw SecurityProviderError.operationFailed(
            operation: "secureRetrieve",
            reason: error.localizedDescription
          )
      }
    } catch {
      let endTime=Date().timeIntervalSince1970
      let executionTime=(endTime - startTime) * 1000

      let errorContext=BaseLogContextDTO(
        domainName: "SecurityProvider",
        operation: "secureRetrieve",
        category: "Security",
        source: "SecurityProviderImpl",
        metadata: metadata.toLogMetadataDTOCollection()
      )
      await logger.error(
        "Secure retrieval failed: \(error.localizedDescription)",
        context: errorContext
      )

      return SecurityResultDTO.failure(
        errorDetails: error.localizedDescription,
        executionTimeMs: executionTime,
        metadata: [
          "operation": "secureRetrieve"
        ]
      )
    }
  }

  /**
   Deletes securely stored data with the specified configuration.

   - Parameter config: Configuration for the secure deletion operation
   - Returns: Result containing deletion confirmation or error
   */
  public func secureDelete(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    try await ensureInitialized()

    let startTime=Date().timeIntervalSince1970

    var metadata=PrivacyMetadata()
    metadata["operation"]=PrivacyMetadataValue(value: "secureDelete", privacy: .public)

    do {
      guard let identifier=config.options?.metadata?["identifier"] else {
        throw SecurityProviderError.invalidInput("Identifier is required for secure deletion")
      }

      let secureStorage=cryptoServiceInstance.secureStorage
      let deleteResult=await secureStorage.deleteData(withIdentifier: identifier)

      switch deleteResult {
        case .success:
          let endTime=Date().timeIntervalSince1970
          let executionTime=(endTime - startTime) * 1000

          let debugContext=BaseLogContextDTO(
            domainName: "SecurityProvider",
            operation: "secureDelete",
            category: "Security",
            source: "SecurityProviderImpl",
            metadata: metadata.toLogMetadataDTOCollection()
          )
          await logger.debug(
            "Secure deletion completed successfully",
            context: debugContext
          )

          return SecurityResultDTO.success(
            executionTimeMs: executionTime,
            metadata: [
              "operation": "secureDelete",
              "identifier": identifier
            ]
          )
        case let .failure(error):
          throw SecurityProviderError.operationFailed(
            operation: "secureDelete",
            reason: error.localizedDescription
          )
      }
    } catch {
      let endTime=Date().timeIntervalSince1970
      let executionTime=(endTime - startTime) * 1000

      let errorContext=BaseLogContextDTO(
        domainName: "SecurityProvider",
        operation: "secureDelete",
        category: "Security",
        source: "SecurityProviderImpl",
        metadata: metadata.toLogMetadataDTOCollection()
      )
      await logger.error(
        "Secure deletion failed: \(error.localizedDescription)",
        context: errorContext
      )

      return SecurityResultDTO.failure(
        errorDetails: error.localizedDescription,
        executionTimeMs: executionTime,
        metadata: [
          "operation": "secureDelete"
        ]
      )
    }
  }

  /**
   Simple performance metrics tracker for measuring operation durations.
   */
  private class PerformanceMetricsTracker {
    /// Records the start time of an operation
    func startOperation() -> Date {
      Date()
    }

    /// Calculates the duration of an operation in milliseconds
    func endOperation(startTime: Date) -> Double {
      let endTime=Date()
      return endTime.timeIntervalSince(startTime) * 1000
    }
  }

  // MARK: - SHA256 Helper

  /// Simple implementation of SHA256 hashing to avoid external dependencies
  private func sha256Hash(data: Data) -> Data {
    var hashBytes=[UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    data.withUnsafeBytes { dataBuffer in
      _=CC_SHA256(dataBuffer.baseAddress, CC_LONG(data.count), &hashBytes)
    }
    return Data(hashBytes)
  }

  /**
   Performs an HMAC-SHA256 operation on the provided data with the given key.

   - Parameters:
     - data: The data to generate a MAC for
     - key: The key to use for the HMAC
   - Returns: An array of bytes representing the HMAC
   */
  private func hmacSHA256(data: [UInt8], key: [UInt8]) -> [UInt8] {
    var digest=[UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))

    CCHmac(
      CCHmacAlgorithm(kCCHmacAlgSHA256),
      key, key.count,
      data, data.count,
      &digest
    )

    return digest
  }

  /**
   Performs a constant-time comparison of two byte arrays.

   - Parameters:
     - lhs: First byte array
     - rhs: Second byte array
   - Returns: True if the arrays are equal, false otherwise
   */
  private func constantTimeEqual(_ lhs: [UInt8], _ rhs: [UInt8]) -> Bool {
    // Check if the arrays have the same length
    guard lhs.count == rhs.count else {
      return false
    }

    // Perform constant-time comparison
    var result: UInt8=0
    for i in 0..<lhs.count {
      result |= lhs[i] ^ rhs[i]
    }

    return result == 0
  }
}

extension PrivacyMetadata {
  func toLogMetadataDTOCollection() -> LogMetadataDTOCollection {
    var collection=LogMetadataDTOCollection()

    // Use entriesArray() which is a public method to get the entries
    for entry in entriesArray {
      switch entry.privacy {
        case .public:
          collection=collection.withPublic(key: entry.key, value: entry.value)
        case .private:
          collection=collection.withPrivate(key: entry.key, value: entry.value)
        case .hash:
          collection=collection.withHashed(key: entry.key, value: entry.value)
        case .sensitive:
          collection=collection.withSensitive(key: entry.key, value: entry.value)
        case .auto:
          // Default to private for auto
          collection=collection.withPrivate(key: entry.key, value: entry.value)
      }
    }

    return collection
  }
}
