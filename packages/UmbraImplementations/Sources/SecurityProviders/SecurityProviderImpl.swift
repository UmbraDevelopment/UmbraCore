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

  /// Flag indicating whether the provider has been properly initialised
  private var isInitialized: Bool=false

  /// The type of security provider being used
  private let providerType: SecurityProviderType

  // MARK: - Initialization

  /**
   Initialises a new SecurityProviderImpl with the specified dependencies.

   - Parameters:
      - cryptoService: Service for cryptographic operations
      - keyManager: Service for key management
      - logger: Logger for recording operations
      - providerType: The type of security provider to use
   */
  public init(
    cryptoService: any CryptoServiceProtocol,
    keyManager: any KeyManagementProtocol,
    logger: any LoggingProtocol,
    providerType: SecurityProviderType = .basic
  ) {
    cryptoServiceInstance=cryptoService
    keyManagerInstance=keyManager
    self.logger=logger
    metrics=PerformanceMetricsTracker()
    self.providerType=providerType
  }

  /**
   Asynchronously initialises the provider, ensuring all dependencies are ready.

   - Throws: SecurityProviderError if initialization fails
   */
  public func initialize() async throws {
    let metadata=LogMetadataDTOCollection()
      .withPublic(key: "operation", value: "initialize")
      .withPublic(key: "provider_type", value: providerType.rawValue)

    let debugContext=BaseLogContextDTO(
      domainName: "SecurityProvider",
      operation: "initialize",
      category: "Security",
      source: "SecurityProviderImpl",
      metadata: metadata
    )
    await logger.debug(
      "Initialising SecurityProviderImpl",
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
        metadata: metadata
      )
      await logger.info(
        "SecurityProviderImpl initialised successfully",
        context: infoContext
      )
    } catch {
      let errorMetadata=LogMetadataDTOCollection()
        .withPublic(key: "operation", value: "initialize")
        .withPublic(key: "provider_type", value: providerType.rawValue)
        .withPrivate(key: "error", value: error.localizedDescription)

      let errorContext=ErrorLogContext(
        error: error,
        domain: "SecurityProvider",
        source: "SecurityProviderImpl",
        additionalContext: errorMetadata
      )
      await logger.error(
        "Failed to initialise SecurityProviderImpl: \(error.localizedDescription)",
        context: errorContext
      )
      throw SecurityProviderError.initializationFailed(reason: error.localizedDescription)
    }
  }

  /**
   Ensures the provider is initialised before performing operations.

   - Throws: Error if the provider is not initialised
   */
  private func ensureInitialized() async throws {
    if !isInitialized {
      let errorMetadata=LogMetadataDTOCollection()
        .withPublic(key: "error", value: "Provider not initialised")

      let errorContext=BaseLogContextDTO(
        domainName: "SecurityProvider",
        operation: "ensureInitialized",
        category: "Security",
        source: "SecurityProviderImpl",
        metadata: errorMetadata
      )
      await logger.error(
        "Security provider not properly initialised",
        context: errorContext
      )
      throw SecurityProviderError.notInitialized
    }
  }

  /**
   Maps CoreSecurityTypes algorithm to algorithm identifier string.

   - Parameter algorithm: The CoreSecurityTypes algorithm
   - Returns: Equivalent algorithm identifier as string
   */
  private func mapToAlgorithmString(_ algorithm: CoreSecurityTypes.EncryptionAlgorithm) -> String {
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
    let result=await cryptoServiceInstance.secureStorage.storeData(data, withIdentifier: identifier)
    return result
  }

  /**
   Retrieves data securely by its identifier.

   - Parameter identifier: Unique identifier for the data
   - Returns: The retrieved data or an error
   */
  private func retrieveData(withIdentifier identifier: String) async
  -> Result<[UInt8], SecurityStorageError> {
    let result=await cryptoServiceInstance.secureStorage.retrieveData(withIdentifier: identifier)
    return result
  }

  /**
   Deletes data securely by its identifier.

   - Parameter identifier: Unique identifier for the data
   - Returns: Success or error result
   */
  private func deleteData(withIdentifier identifier: String) async
  -> Result<Void, SecurityStorageError> {
    let result=await cryptoServiceInstance.secureStorage.deleteData(withIdentifier: identifier)
    return result
  }

  /**
   Stores a cryptographic key with the given parameters.

   - Parameters:
      - key: The key data to store
      - identifier: Unique identifier for the key
      - purpose: Purpose of the key
      - algorithm: Algorithm the key is intended for
   - Throws: SecurityProviderError if storage fails
   */
  private func storeKey(
    _ key: Data,
    identifier: String,
    purpose: KeyPurpose,
    algorithm _: CoreSecurityTypes.EncryptionAlgorithm
  ) async throws {
    // Convert Data to [UInt8]
    let keyBytes=[UInt8](key)

    let result=await keyManagerInstance.storeKey(keyBytes, withIdentifier: identifier)

    switch result {
      case .success:
        let metadata=LogMetadataDTOCollection()
          .withPublic(key: "operation", value: "storeKey")
          .withPublic(key: "purpose", value: purpose.rawValue)
          .withPrivate(key: "identifier", value: identifier)

        let debugContext=BaseLogContextDTO(
          domainName: "SecurityProvider",
          operation: "storeKey",
          category: "Security",
          source: "SecurityProviderImpl",
          metadata: metadata
        )
        await logger.debug(
          "Successfully stored key",
          context: debugContext
        )

      case let .failure(error):
        throw SecurityProviderError.storageError(error.localizedDescription)
    }
  }

  // MARK: - Error Handling

  /**
   Maps internal errors to SecurityProtocolError.

   - Parameter error: The internal error
   - Returns: The mapped SecurityProtocolError
   */
  private func mapToProtocolError(_ error: Error) -> SecurityProtocolError {
    if let protocolError=error as? SecurityProtocolError {
      protocolError
    } else if let storageError=error as? SecurityStorageError {
      // Convert storage errors to protocol errors
      switch storageError {
        case let .identifierNotFound(identifier):
          SecurityProtocolError.operationFailed(reason: "Item not found: \(identifier)")
        case .storageUnavailable:
          SecurityProtocolError.operationFailed(reason: "Secure storage unavailable")
        case let .invalidIdentifier(reason):
          SecurityProtocolError.inputError("Invalid identifier: \(reason)")
        case .invalidInput:
          SecurityProtocolError.inputError("Invalid data format")
        case let .operationFailed(message):
          SecurityProtocolError.operationFailed(reason: message)
        case .encryptionFailed, .decryptionFailed, .hashingFailed:
          SecurityProtocolError.operationFailed(reason: "Cryptographic operation failed")
        case .unsupportedOperation:
          SecurityProtocolError.operationFailed(reason: "Operation not supported")
        case let .storageFailure(reason):
          SecurityProtocolError.operationFailed(reason: "Storage failure: \(reason)")
        case let .generalError(reason):
          SecurityProtocolError.operationFailed(reason: reason)
        default:
          SecurityProtocolError.operationFailed(reason: storageError.localizedDescription)
      }
    } else if let providerError=error as? SecurityProviderError {
      // Convert provider errors to protocol errors
      switch providerError {
        case .notInitialized:
          SecurityProtocolError.operationFailed(reason: "Provider not initialised")
        case let .initializationFailed(reason):
          SecurityProtocolError.operationFailed(reason: "Initialisation failed: \(reason)")
        case let .invalidInput(message):
          SecurityProtocolError.inputError(message)
        case let .operationFailed(operation, reason):
          SecurityProtocolError.operationFailed(reason: "\(operation) failed: \(reason)")
        case .operationNotSupported:
          SecurityProtocolError.operationFailed(reason: "Operation not supported")
        case let .keyNotFound(id, _):
          SecurityProtocolError.operationFailed(reason: "Key not found: \(id)")
        case let .storageError(message):
          SecurityProtocolError.operationFailed(reason: message)
        default:
          SecurityProtocolError.operationFailed(reason: providerError.localizedDescription)
      }
    } else {
      // Default mapping for unknown errors
      SecurityProtocolError.operationFailed(reason: error.localizedDescription)
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

      // Get or generate key identifier
      let keyIdentifier: String
      if let providedKeyID=config.options?.metadata?["keyIdentifier"] {
        keyIdentifier=providedKeyID
      } else {
        throw SecurityProviderError.invalidInput("Missing required key identifier for encryption")
      }

      // Import data if not already in secure storage
      let dataIdentifier=UUID().uuidString
      let importResult=await cryptoServiceInstance.importData(
        [UInt8](dataToEncrypt),
        customIdentifier: dataIdentifier
      )

      guard case .success=importResult else {
        if case let .failure(error)=importResult {
          throw SecurityProviderError.operationFailed(
            operation: "encrypt",
            reason: "Failed to import data: \(error.localizedDescription)"
          )
        }
        throw SecurityProviderError.operationFailed(
          operation: "encrypt",
          reason: "Failed to import data"
        )
      }

      // Create encryption options
      let encryptionOptions=CoreSecurityTypes.EncryptionOptions(
        algorithm: config.encryptionAlgorithm,
        mode: .cbc, // Default mode, can be overridden from config
        padding: .pkcs7 // Default padding, can be overridden from config
      )

      // Delegate encryption to the crypto service
      let encryptionResult=await cryptoServiceInstance.encrypt(
        dataIdentifier: dataIdentifier,
        keyIdentifier: keyIdentifier,
        options: encryptionOptions
      )

      switch encryptionResult {
        case let .success(encryptedDataID):
          let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000

          // Retrieve the encrypted data
          let exportResult=await cryptoServiceInstance.exportData(identifier: encryptedDataID)

          guard case let .success(encryptedBytes)=exportResult else {
            if case let .failure(error)=exportResult {
              throw SecurityProviderError.operationFailed(
                operation: "encrypt",
                reason: "Failed to export encrypted data: \(error.localizedDescription)"
              )
            }
            throw SecurityProviderError.operationFailed(
              operation: "encrypt",
              reason: "Failed to export encrypted data"
            )
          }

          // Log the successful operation
          let metadata=LogMetadataDTOCollection()
            .withPublic(key: "operation", value: "encrypt")
            .withPublic(key: "algorithm", value: config.encryptionAlgorithm.rawValue)
            .withPublic(key: "execution_time_ms", value: String(format: "%.2f", executionTime))

          let debugContext=BaseLogContextDTO(
            domainName: "SecurityProvider",
            operation: "encrypt",
            category: "Security",
            source: "SecurityProviderImpl",
            metadata: metadata
          )
          await logger.debug(
            "Data encrypted successfully",
            context: debugContext
          )

          return SecurityResultDTO.success(
            resultData: Data(encryptedBytes),
            executionTimeMs: executionTime,
            metadata: [
              "operation": "encrypt",
              "algorithm": config.encryptionAlgorithm.rawValue,
              "encryptedDataId": encryptedDataID
            ]
          )

        case let .failure(error):
          let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000

          let metadata=LogMetadataDTOCollection()
            .withPublic(key: "operation", value: "encrypt")
            .withPrivate(key: "error", value: error.localizedDescription)

          let errorContext=BaseLogContextDTO(
            domainName: "SecurityProvider",
            operation: "encrypt",
            category: "Security",
            source: "SecurityProviderImpl",
            metadata: metadata
          )
          await logger.error(
            "Encryption operation failed: \(error.localizedDescription)",
            context: errorContext
          )

          return SecurityResultDTO.failure(
            errorDetails: error.localizedDescription,
            executionTimeMs: executionTime
          )
      }

    } catch {
      let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000

      let metadata=LogMetadataDTOCollection()
        .withPublic(key: "operation", value: "encrypt")
        .withPrivate(key: "error", value: error.localizedDescription)

      let errorContext=BaseLogContextDTO(
        domainName: "SecurityProvider",
        operation: "encrypt",
        category: "Security",
        source: "SecurityProviderImpl",
        metadata: metadata
      )
      await logger.error(
        "Encryption operation failed: \(error.localizedDescription)",
        context: errorContext
      )

      return SecurityResultDTO.failure(
        errorDetails: error.localizedDescription,
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

      // Get key identifier
      guard let keyIdentifier=config.options?.metadata?["keyIdentifier"] else {
        throw SecurityProviderError.invalidInput("Missing required key identifier for decryption")
      }

      // Import encrypted data to secure storage
      let encryptedDataID=UUID().uuidString
      let importResult=await cryptoServiceInstance.importData(
        [UInt8](dataToDecrypt),
        customIdentifier: encryptedDataID
      )

      guard case .success=importResult else {
        if case let .failure(error)=importResult {
          throw SecurityProviderError.operationFailed(
            operation: "decrypt",
            reason: "Failed to import encrypted data: \(error.localizedDescription)"
          )
        }
        throw SecurityProviderError.operationFailed(
          operation: "decrypt",
          reason: "Failed to import encrypted data"
        )
      }

      // Create decryption options
      let decryptionOptions=CoreSecurityTypes.DecryptionOptions(
        algorithm: config.encryptionAlgorithm,
        mode: .cbc, // Default mode, can be overridden from config
        padding: .pkcs7 // Default padding, can be overridden from config
      )

      // Delegate decryption to the crypto service
      let decryptionResult=await cryptoServiceInstance.decrypt(
        encryptedDataIdentifier: encryptedDataID,
        keyIdentifier: keyIdentifier,
        options: decryptionOptions
      )

      switch decryptionResult {
        case let .success(decryptedDataID):
          let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000

          // Retrieve the decrypted data
          let exportResult=await cryptoServiceInstance.exportData(identifier: decryptedDataID)

          guard case let .success(decryptedBytes)=exportResult else {
            if case let .failure(error)=exportResult {
              throw SecurityProviderError.operationFailed(
                operation: "decrypt",
                reason: "Failed to export decrypted data: \(error.localizedDescription)"
              )
            }
            throw SecurityProviderError.operationFailed(
              operation: "decrypt",
              reason: "Failed to export decrypted data"
            )
          }

          // Log the successful operation
          let metadata=LogMetadataDTOCollection()
            .withPublic(key: "operation", value: "decrypt")
            .withPublic(key: "algorithm", value: config.encryptionAlgorithm.rawValue)
            .withPublic(key: "execution_time_ms", value: String(format: "%.2f", executionTime))

          let debugContext=BaseLogContextDTO(
            domainName: "SecurityProvider",
            operation: "decrypt",
            category: "Security",
            source: "SecurityProviderImpl",
            metadata: metadata
          )
          await logger.debug(
            "Data decrypted successfully",
            context: debugContext
          )

          return SecurityResultDTO.success(
            resultData: Data(decryptedBytes),
            executionTimeMs: executionTime,
            metadata: [
              "operation": "decrypt",
              "algorithm": config.encryptionAlgorithm.rawValue
            ]
          )

        case let .failure(error):
          let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000

          let metadata=LogMetadataDTOCollection()
            .withPublic(key: "operation", value: "decrypt")
            .withPrivate(key: "error", value: error.localizedDescription)

          let errorContext=BaseLogContextDTO(
            domainName: "SecurityProvider",
            operation: "decrypt",
            category: "Security",
            source: "SecurityProviderImpl",
            metadata: metadata
          )
          await logger.error(
            "Decryption operation failed: \(error.localizedDescription)",
            context: errorContext
          )

          return SecurityResultDTO.failure(
            errorDetails: error.localizedDescription,
            executionTimeMs: executionTime
          )
      }

    } catch {
      let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000

      let metadata=LogMetadataDTOCollection()
        .withPublic(key: "operation", value: "decrypt")
        .withPrivate(key: "error", value: error.localizedDescription)

      let errorContext=BaseLogContextDTO(
        domainName: "SecurityProvider",
        operation: "decrypt",
        category: "Security",
        source: "SecurityProviderImpl",
        metadata: metadata
      )
      await logger.error(
        "Decryption operation failed: \(error.localizedDescription)",
        context: errorContext
      )

      return SecurityResultDTO.failure(
        errorDetails: error.localizedDescription,
        executionTimeMs: executionTime
      )
    }
  }

  /**
   Computes a cryptographic hash with the specified configuration.

   - Parameter config: Configuration for the hashing operation
   - Returns: SecurityResultDTO with hash or error details
   */
  public func hash(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let startTime=Date().timeIntervalSince1970

    do {
      // Validate initialization
      try await ensureInitialized()

      // Validate input data
      guard
        let inputDataString=config.options?.metadata?["inputData"],
        let dataToHash=Data(base64Encoded: inputDataString)
      else {
        throw SecurityProviderError.invalidInput("Missing or empty input data for hashing")
      }

      // Import data to secure storage
      let dataIdentifier=UUID().uuidString
      let importResult=await cryptoServiceInstance.importData(
        [UInt8](dataToHash),
        customIdentifier: dataIdentifier
      )

      guard case .success=importResult else {
        if case let .failure(error)=importResult {
          throw SecurityProviderError.operationFailed(
            operation: "hash",
            reason: "Failed to import data: \(error.localizedDescription)"
          )
        }
        throw SecurityProviderError.operationFailed(
          operation: "hash",
          reason: "Failed to import data"
        )
      }

      // Create hash options
      let hashingOptions=CoreSecurityTypes.HashingOptions(
        algorithm: config.hashAlgorithm
      )

      // Delegate hashing to the crypto service
      let hashResult=await cryptoServiceInstance.hash(
        dataIdentifier: dataIdentifier,
        options: hashingOptions
      )

      switch hashResult {
        case let .success(hashIdentifier):
          let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000

          // Retrieve the hash data
          let exportResult=await cryptoServiceInstance.exportData(identifier: hashIdentifier)

          guard case let .success(hashBytes)=exportResult else {
            if case let .failure(error)=exportResult {
              throw SecurityProviderError.operationFailed(
                operation: "hash",
                reason: "Failed to export hash: \(error.localizedDescription)"
              )
            }
            throw SecurityProviderError.operationFailed(
              operation: "hash",
              reason: "Failed to export hash"
            )
          }

          // Log the successful operation
          let metadata=LogMetadataDTOCollection()
            .withPublic(key: "operation", value: "hash")
            .withPublic(key: "algorithm", value: config.hashAlgorithm.rawValue)
            .withPublic(key: "execution_time_ms", value: String(format: "%.2f", executionTime))

          let debugContext=BaseLogContextDTO(
            domainName: "SecurityProvider",
            operation: "hash",
            category: "Security",
            source: "SecurityProviderImpl",
            metadata: metadata
          )
          await logger.debug(
            "Data hashed successfully",
            context: debugContext
          )

          return SecurityResultDTO.success(
            resultData: Data(hashBytes),
            executionTimeMs: executionTime,
            metadata: [
              "operation": "hash",
              "algorithm": config.hashAlgorithm.rawValue,
              "hashIdentifier": hashIdentifier
            ]
          )

        case let .failure(error):
          let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000

          let metadata=LogMetadataDTOCollection()
            .withPublic(key: "operation", value: "hash")
            .withPrivate(key: "error", value: error.localizedDescription)

          let errorContext=BaseLogContextDTO(
            domainName: "SecurityProvider",
            operation: "hash",
            category: "Security",
            source: "SecurityProviderImpl",
            metadata: metadata
          )
          await logger.error(
            "Hash operation failed: \(error.localizedDescription)",
            context: errorContext
          )

          return SecurityResultDTO.failure(
            errorDetails: error.localizedDescription,
            executionTimeMs: executionTime
          )
      }

    } catch {
      let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000

      let metadata=LogMetadataDTOCollection()
        .withPublic(key: "operation", value: "hash")
        .withPrivate(key: "error", value: error.localizedDescription)

      let errorContext=BaseLogContextDTO(
        domainName: "SecurityProvider",
        operation: "hash",
        category: "Security",
        source: "SecurityProviderImpl",
        metadata: metadata
      )
      await logger.error(
        "Hash operation failed: \(error.localizedDescription)",
        context: errorContext
      )

      return SecurityResultDTO.failure(
        errorDetails: error.localizedDescription,
        executionTimeMs: executionTime
      )
    }
  }

  /**
   Generates a cryptographic key with the specified parameters.

   - Parameter config: Configuration for key generation
   - Returns: SecurityResultDTO with the generated key or error details
   */
  public func generateKey(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let startTime=Date().timeIntervalSince1970

    do {
      // Validate initialization
      try await ensureInitialized()

      // Determine key size from algorithm or config
      let keySize=config.options?.metadata?["keySize"].flatMap { Int($0) } ??
        config.encryptionAlgorithm.recommendedKeySize()

      // Map encryption algorithm to key type
      let keyType: KeyType=switch config.encryptionAlgorithm {
        case .aes256CBC, .aes256GCM:
          .aes
        case .chacha20Poly1305:
          // ChaCha20 uses similar key structure to AES
          .aes
      }

      // Generate key using CryptoService
      let keyResult=await cryptoServiceInstance.generateKey(
        length: keySize,
        options: CoreSecurityTypes.KeyGenerationOptions(
          keyType: keyType,
          keySizeInBits: keySize,
          isExtractable: config.options?.metadata?["extractable"] == "true"
        )
      )

      switch keyResult {
        case let .success(keyIdentifier):
          let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000

          // Retrieve the key for the result if requested
          let keyData: Data
          if config.options?.metadata?["returnKeyData"] == "true" {
            let retrieveResult=await cryptoServiceInstance.exportData(identifier: keyIdentifier)
            guard case let .success(keyBytes)=retrieveResult else {
              throw SecurityProviderError.operationFailed(
                operation: "generateKey",
                reason: "Failed to retrieve generated key"
              )
            }
            keyData=Data(keyBytes)
          } else {
            // Just return a placeholder - the key remains secure in storage
            keyData=Data()
          }

          // Log the successful operation
          let metadata=LogMetadataDTOCollection()
            .withPublic(key: "operation", value: "generateKey")
            .withPublic(key: "algorithm", value: config.encryptionAlgorithm.rawValue)
            .withPublic(key: "execution_time_ms", value: String(format: "%.2f", executionTime))

          let debugContext=BaseLogContextDTO(
            domainName: "SecurityProvider",
            operation: "generateKey",
            category: "Security",
            source: "SecurityProviderImpl",
            metadata: metadata
          )
          await logger.debug(
            "Key generated successfully",
            context: debugContext
          )

          return SecurityResultDTO.success(
            resultData: keyData,
            executionTimeMs: executionTime,
            metadata: [
              "operation": "generateKey",
              "algorithm": config.encryptionAlgorithm.rawValue,
              "keySize": "\(keySize)",
              "keyIdentifier": keyIdentifier
            ]
          )

        case let .failure(error):
          let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000

          let metadata=LogMetadataDTOCollection()
            .withPublic(key: "operation", value: "generateKey")
            .withPrivate(key: "error", value: error.localizedDescription)

          let errorContext=BaseLogContextDTO(
            domainName: "SecurityProvider",
            operation: "generateKey",
            category: "Security",
            source: "SecurityProviderImpl",
            metadata: metadata
          )
          await logger.error(
            "Key generation failed: \(error.localizedDescription)",
            context: errorContext
          )

          return SecurityResultDTO.failure(
            errorDetails: error.localizedDescription,
            executionTimeMs: executionTime
          )
      }

    } catch {
      let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000

      let metadata=LogMetadataDTOCollection()
        .withPublic(key: "operation", value: "generateKey")
        .withPrivate(key: "error", value: error.localizedDescription)

      let errorContext=BaseLogContextDTO(
        domainName: "SecurityProvider",
        operation: "generateKey",
        category: "Security",
        source: "SecurityProviderImpl",
        metadata: metadata
      )
      await logger.error(
        "Key generation failed: \(error.localizedDescription)",
        context: errorContext
      )

      return SecurityResultDTO.failure(
        errorDetails: error.localizedDescription,
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
    let startTime=Date().timeIntervalSince1970

    do {
      // Validate initialization
      try await ensureInitialized()

      // Validate input data
      guard
        let inputDataString=config.options?.metadata?["inputData"],
        let dataToStore=Data(base64Encoded: inputDataString)
      else {
        throw SecurityProviderError.invalidInput("Missing or empty input data for secure storage")
      }

      // Get identifier
      let identifier=config.options?.metadata?["identifier"] ?? UUID().uuidString

      // Store data using secureStorage
      let storeResult=await storeData([UInt8](dataToStore), withIdentifier: identifier)

      switch storeResult {
        case .success:
          let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000

          // Log the successful operation
          let metadata=LogMetadataDTOCollection()
            .withPublic(key: "operation", value: "secureStore")
            .withPublic(key: "execution_time_ms", value: String(format: "%.2f", executionTime))

          let debugContext=BaseLogContextDTO(
            domainName: "SecurityProvider",
            operation: "secureStore",
            category: "Security",
            source: "SecurityProviderImpl",
            metadata: metadata
          )
          await logger.debug(
            "Data stored securely",
            context: debugContext
          )

          return SecurityResultDTO.success(
            resultData: identifier.data(using: .utf8) ?? Data(),
            executionTimeMs: executionTime,
            metadata: [
              "operation": "secureStore",
              "identifier": identifier
            ]
          )

        case let .failure(error):
          let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000

          let metadata=LogMetadataDTOCollection()
            .withPublic(key: "operation", value: "secureStore")
            .withPrivate(key: "error", value: error.localizedDescription)

          let errorContext=BaseLogContextDTO(
            domainName: "SecurityProvider",
            operation: "secureStore",
            category: "Security",
            source: "SecurityProviderImpl",
            metadata: metadata
          )
          await logger.error(
            "Secure storage operation failed: \(error.localizedDescription)",
            context: errorContext
          )

          return SecurityResultDTO.failure(
            errorDetails: error.localizedDescription,
            executionTimeMs: executionTime
          )
      }
    } catch {
      let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000

      let metadata=LogMetadataDTOCollection()
        .withPublic(key: "operation", value: "secureStore")
        .withPrivate(key: "error", value: error.localizedDescription)

      let errorContext=BaseLogContextDTO(
        domainName: "SecurityProvider",
        operation: "secureStore",
        category: "Security",
        source: "SecurityProviderImpl",
        metadata: metadata
      )
      await logger.error(
        "Secure storage operation failed: \(error.localizedDescription)",
        context: errorContext
      )

      return SecurityResultDTO.failure(
        errorDetails: error.localizedDescription,
        executionTimeMs: executionTime
      )
    }
  }

  /**
   Retrieves securely stored data with the specified configuration.

   - Parameter config: Configuration for the secure retrieval operation
   - Returns: Result containing retrieved data or error
   */
  public func secureRetrieve(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let startTime=Date().timeIntervalSince1970

    do {
      // Validate initialization
      try await ensureInitialized()

      // Validate identifier
      guard let identifier=config.options?.metadata?["identifier"] else {
        throw SecurityProviderError.invalidInput("Missing identifier for secure retrieval")
      }

      // Retrieve data using secureStorage
      let retrieveResult=await retrieveData(withIdentifier: identifier)

      switch retrieveResult {
        case let .success(retrievedData):
          let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000

          // Log the successful operation
          let metadata=LogMetadataDTOCollection()
            .withPublic(key: "operation", value: "secureRetrieve")
            .withPublic(key: "execution_time_ms", value: String(format: "%.2f", executionTime))

          let debugContext=BaseLogContextDTO(
            domainName: "SecurityProvider",
            operation: "secureRetrieve",
            category: "Security",
            source: "SecurityProviderImpl",
            metadata: metadata
          )
          await logger.debug(
            "Data retrieved securely",
            context: debugContext
          )

          return SecurityResultDTO.success(
            resultData: Data(retrievedData),
            executionTimeMs: executionTime,
            metadata: [
              "operation": "secureRetrieve",
              "identifier": identifier
            ]
          )

        case let .failure(error):
          let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000

          let metadata=LogMetadataDTOCollection()
            .withPublic(key: "operation", value: "secureRetrieve")
            .withPrivate(key: "error", value: error.localizedDescription)

          let errorContext=BaseLogContextDTO(
            domainName: "SecurityProvider",
            operation: "secureRetrieve",
            category: "Security",
            source: "SecurityProviderImpl",
            metadata: metadata
          )
          await logger.error(
            "Secure retrieval operation failed: \(error.localizedDescription)",
            context: errorContext
          )

          return SecurityResultDTO.failure(
            errorDetails: error.localizedDescription,
            executionTimeMs: executionTime
          )
      }
    } catch {
      let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000

      let metadata=LogMetadataDTOCollection()
        .withPublic(key: "operation", value: "secureRetrieve")
        .withPrivate(key: "error", value: error.localizedDescription)

      let errorContext=BaseLogContextDTO(
        domainName: "SecurityProvider",
        operation: "secureRetrieve",
        category: "Security",
        source: "SecurityProviderImpl",
        metadata: metadata
      )
      await logger.error(
        "Secure retrieval operation failed: \(error.localizedDescription)",
        context: errorContext
      )

      return SecurityResultDTO.failure(
        errorDetails: error.localizedDescription,
        executionTimeMs: executionTime
      )
    }
  }

  /**
   Deletes securely stored data with the specified configuration.

   - Parameter config: Configuration for the secure deletion operation
   - Returns: Result containing deletion confirmation or error
   */
  public func secureDelete(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let startTime=Date().timeIntervalSince1970

    do {
      // Validate initialization
      try await ensureInitialized()

      // Validate identifier
      guard let identifier=config.options?.metadata?["identifier"] else {
        throw SecurityProviderError.invalidInput("Missing identifier for secure deletion")
      }

      // Delete data using secureStorage
      let deleteResult=await deleteData(withIdentifier: identifier)

      switch deleteResult {
        case .success:
          let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000

          // Log the successful operation
          let metadata=LogMetadataDTOCollection()
            .withPublic(key: "operation", value: "secureDelete")
            .withPublic(key: "execution_time_ms", value: String(format: "%.2f", executionTime))

          let debugContext=BaseLogContextDTO(
            domainName: "SecurityProvider",
            operation: "secureDelete",
            category: "Security",
            source: "SecurityProviderImpl",
            metadata: metadata
          )
          await logger.debug(
            "Data deleted securely",
            context: debugContext
          )

          return SecurityResultDTO.success(
            resultData: Data(),
            executionTimeMs: executionTime,
            metadata: [
              "operation": "secureDelete",
              "identifier": identifier
            ]
          )

        case let .failure(error):
          let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000

          let metadata=LogMetadataDTOCollection()
            .withPublic(key: "operation", value: "secureDelete")
            .withPrivate(key: "error", value: error.localizedDescription)

          let errorContext=BaseLogContextDTO(
            domainName: "SecurityProvider",
            operation: "secureDelete",
            category: "Security",
            source: "SecurityProviderImpl",
            metadata: metadata
          )
          await logger.error(
            "Secure deletion operation failed: \(error.localizedDescription)",
            context: errorContext
          )

          return SecurityResultDTO.failure(
            errorDetails: error.localizedDescription,
            executionTimeMs: executionTime
          )
      }
    } catch {
      let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000

      let metadata=LogMetadataDTOCollection()
        .withPublic(key: "operation", value: "secureDelete")
        .withPrivate(key: "error", value: error.localizedDescription)

      let errorContext=BaseLogContextDTO(
        domainName: "SecurityProvider",
        operation: "secureDelete",
        category: "Security",
        source: "SecurityProviderImpl",
        metadata: metadata
      )
      await logger.error(
        "Secure deletion operation failed: \(error.localizedDescription)",
        context: errorContext
      )

      return SecurityResultDTO.failure(
        errorDetails: error.localizedDescription,
        executionTimeMs: executionTime
      )
    }
  }

  /**
   Creates a digital signature for data with the specified configuration.

   - Parameter config: Configuration for the digital signature operation
   - Returns: Result containing signature data or error
   */
  public func sign(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let startTime=Date().timeIntervalSince1970

    do {
      // Validate initialization
      try await ensureInitialized()

      // Extract required parameters from config
      guard
        let dataString=config.options?.metadata?["data"],
        let dataToSign=Data(base64Encoded: dataString)
      else {
        throw SecurityProviderError.invalidInput("No data provided for signing operation")
      }

      // Get key identifier from config
      let keyIdentifier=config.options?.metadata?["keyIdentifier"] ??
        config.options?.metadata?["signatureKeyIdentifier"]

      guard let keyID=keyIdentifier else {
        throw SecurityProviderError.invalidInput("No key identifier provided for signing operation")
      }

      // Determine signature algorithm from config
      let signatureAlgorithm=config.options?.metadata?["signatureAlgorithm"].flatMap {
        SignAlgorithm(rawValue: $0)
      } ?? .ecdsaP256SHA256 // Default to ECDSA P-256 with SHA-256

      // Log the operation with metadata
      let metadata=LogMetadataDTOCollection()
        .withPublic(key: "operation", value: "sign")
        .withPublic(key: "algorithm", value: signatureAlgorithm.rawValue)
        .withPublic(key: "keyIdentifier", value: keyID)
        .withPrivate(key: "dataLength", value: "\(dataToSign.count)")

      let debugContext=BaseLogContextDTO(
        domainName: "SecurityProvider",
        operation: "sign",
        category: "Security",
        source: "SecurityProviderImpl",
        metadata: metadata
      )
      await logger.debug(
        "Starting signature generation with algorithm: \(signatureAlgorithm.rawValue)",
        context: debugContext
      )

      // First, store the data to sign in secure storage
      let inputDataID="sign_input_\(UUID().uuidString)"
      let storeResult=await cryptoServiceInstance.storeData(
        data: dataToSign,
        identifier: inputDataID
      )

      guard case .success=storeResult else {
        throw SecurityProviderError.storageError("Failed to store input data for signing")
      }

      // For cleanup at the end
      defer {
        Task {
          _=await cryptoServiceInstance.deleteData(identifier: inputDataID)
        }
      }

      // Generate hash of the data as part of the signing process
      let hashResult=await cryptoServiceInstance.generateHash(
        dataIdentifier: inputDataID,
        options: CoreSecurityTypes.HashingOptions(
          algorithm: signatureAlgorithm == .ecdsaP256SHA256 ? .sha256 : .sha256
        )
      )

      guard case let .success(hashID)=hashResult else {
        throw SecurityProviderError.operationFailed(
          operation: "sign",
          reason: "Failed to hash data for signing"
        )
      }

      // For cleanup at the end
      defer {
        Task {
          _=await cryptoServiceInstance.deleteData(identifier: hashID)
        }
      }

      // Encrypt the hash using the private key (this simulates signing)
      // Note: In a real implementation, we would use a dedicated signing operation
      // but we are simulating it using the encryption operation with the private key
      let encryptOptions=CoreSecurityTypes.EncryptionOptions(
        algorithm: .aes256GCM,
        mode: .gcm, // Using GCM mode for authenticated encryption
        padding: .pkcs7, // Using PKCS#7 padding
        additionalAuthenticatedData: nil
      )

      let signResult=await cryptoServiceInstance.encrypt(
        dataIdentifier: hashID,
        keyIdentifier: keyID,
        options: encryptOptions
      )

      guard case let .success(signatureID)=signResult else {
        throw SecurityProviderError.operationFailed(
          operation: "sign",
          reason: "Failed to generate signature"
        )
      }

      // Retrieve the signature
      let signatureDataResult=await cryptoServiceInstance.retrieveData(
        identifier: signatureID
      )

      guard case let .success(signatureData)=signatureDataResult else {
        throw SecurityProviderError.operationFailed(
          operation: "sign",
          reason: "Failed to retrieve signature data"
        )
      }

      // Clean up the signature ID from storage
      Task {
        _=await cryptoServiceInstance.deleteData(identifier: signatureID)
      }

      let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000

      // Log successful operation
      let successMetadata=LogMetadataDTOCollection()
        .withPublic(key: "operation", value: "sign")
        .withPublic(key: "algorithm", value: signatureAlgorithm.rawValue)
        .withPublic(key: "execution_time_ms", value: String(format: "%.2f", executionTime))
        .withPublic(key: "signature_length", value: "\(signatureData.count)")

      let successContext=BaseLogContextDTO(
        domainName: "SecurityProvider",
        operation: "sign",
        category: "Security",
        source: "SecurityProviderImpl",
        metadata: successMetadata
      )
      await logger.debug(
        "Signature generated successfully",
        context: successContext
      )

      return SecurityResultDTO.success(
        resultData: signatureData,
        executionTimeMs: executionTime,
        metadata: [
          "operation": "sign",
          "algorithm": signatureAlgorithm.rawValue,
          "signature_length": "\(signatureData.count)"
        ]
      )

    } catch {
      let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000

      // Log error
      let errorMetadata=LogMetadataDTOCollection()
        .withPublic(key: "operation", value: "sign")
        .withPrivate(key: "error", value: error.localizedDescription)

      let errorContext=BaseLogContextDTO(
        domainName: "SecurityProvider",
        operation: "sign",
        category: "Security",
        source: "SecurityProviderImpl",
        metadata: errorMetadata
      )
      await logger.error(
        "Signature generation failed: \(error.localizedDescription)",
        context: errorContext
      )

      return SecurityResultDTO.failure(
        errorDetails: error.localizedDescription,
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

      // Extract required parameters from config
      guard
        let dataString=config.options?.metadata?["data"],
        let originalData=Data(base64Encoded: dataString)
      else {
        throw SecurityProviderError.invalidInput("No original data provided for verification")
      }

      guard
        let signatureString=config.options?.metadata?["signature"],
        let signatureData=Data(base64Encoded: signatureString)
      else {
        throw SecurityProviderError.invalidInput("No signature data provided for verification")
      }

      // Get key identifier from config
      let keyIdentifier=config.options?.metadata?["keyIdentifier"] ??
        config.options?.metadata?["signatureKeyIdentifier"]

      guard let keyID=keyIdentifier else {
        throw SecurityProviderError.invalidInput("No key identifier provided for verification")
      }

      // Determine signature algorithm from config
      let signatureAlgorithm=config.options?.metadata?["signatureAlgorithm"].flatMap {
        SignAlgorithm(rawValue: $0)
      } ?? .ecdsaP256SHA256 // Default to ECDSA P-256 with SHA-256

      // Log the operation with metadata
      let metadata=LogMetadataDTOCollection()
        .withPublic(key: "operation", value: "verify")
        .withPublic(key: "algorithm", value: signatureAlgorithm.rawValue)
        .withPublic(key: "keyIdentifier", value: keyID)
        .withPrivate(key: "dataLength", value: "\(originalData.count)")
        .withPrivate(key: "signatureLength", value: "\(signatureData.count)")

      let debugContext=BaseLogContextDTO(
        domainName: "SecurityProvider",
        operation: "verify",
        category: "Security",
        source: "SecurityProviderImpl",
        metadata: metadata
      )
      await logger.debug(
        "Starting signature verification with algorithm: \(signatureAlgorithm.rawValue)",
        context: debugContext
      )

      // Store the original data and signature in secure storage
      let originalDataID="verify_original_\(UUID().uuidString)"
      let signatureDataID="verify_signature_\(UUID().uuidString)"

      let storeOriginalResult=await cryptoServiceInstance.storeData(
        data: originalData,
        identifier: originalDataID
      )

      guard case .success=storeOriginalResult else {
        throw SecurityProviderError.storageError("Failed to store original data for verification")
      }

      let storeSignatureResult=await cryptoServiceInstance.storeData(
        data: signatureData,
        identifier: signatureDataID
      )

      guard case .success=storeSignatureResult else {
        throw SecurityProviderError.storageError("Failed to store signature data for verification")
      }

      // For cleanup at the end
      defer {
        Task {
          _=await cryptoServiceInstance.deleteData(identifier: originalDataID)
          _=await cryptoServiceInstance.deleteData(identifier: signatureDataID)
        }
      }

      // Generate hash of the original data
      let hashResult=await cryptoServiceInstance.generateHash(
        dataIdentifier: originalDataID,
        options: CoreSecurityTypes.HashingOptions(
          algorithm: signatureAlgorithm == .ecdsaP256SHA256 ? .sha256 : .sha256
        )
      )

      guard case let .success(hashID)=hashResult else {
        throw SecurityProviderError.operationFailed(
          operation: "verify",
          reason: "Failed to hash data for verification"
        )
      }

      defer {
        Task {
          _=await cryptoServiceInstance.deleteData(identifier: hashID)
        }
      }

      // Decrypt the signature using the public key (this simulates signature verification)
      // Note: In a real implementation, we would use a dedicated verification operation
      let decryptOptions=CoreSecurityTypes.DecryptionOptions(
        algorithm: .aes256GCM,
        mode: .gcm, // Using GCM mode for authenticated encryption
        padding: .pkcs7, // Using PKCS#7 padding
        additionalAuthenticatedData: nil
      )

      let decryptResult=await cryptoServiceInstance.decrypt(
        encryptedDataIdentifier: signatureDataID,
        keyIdentifier: keyID,
        options: decryptOptions
      )

      // If decryption fails, the signature is invalid
      guard case let .success(decryptedHashID)=decryptResult else {
        // Log verification result - invalid signature
        let resultMetadata=LogMetadataDTOCollection()
          .withPublic(key: "operation", value: "verify")
          .withPublic(key: "algorithm", value: signatureAlgorithm.rawValue)
          .withPublic(
            key: "execution_time_ms",
            value: String(format: "%.2f", (Date().timeIntervalSince1970 - startTime) * 1000)
          )
          .withPublic(key: "verification_result", value: "invalid")

        let resultContext=BaseLogContextDTO(
          domainName: "SecurityProvider",
          operation: "verify",
          category: "Security",
          source: "SecurityProviderImpl",
          metadata: resultMetadata
        )
        await logger.debug(
          "Signature verification failed, invalid signature",
          context: resultContext
        )

        return SecurityResultDTO.success(
          resultData: Data([0]), // Boolean false as Data
          executionTimeMs: (Date().timeIntervalSince1970 - startTime) * 1000,
          metadata: [
            "operation": "verify",
            "algorithm": signatureAlgorithm.rawValue,
            "is_valid": "false"
          ]
        )
      }

      defer {
        Task {
          _=await cryptoServiceInstance.deleteData(identifier: decryptedHashID)
        }
      }

      // Compare the decrypted hash with the computed hash
      let verifyResult=await cryptoServiceInstance.verifyHash(
        dataIdentifier: decryptedHashID,
        hashIdentifier: hashID,
        options: nil
      )

      let isValid: Bool=switch verifyResult {
        case let .success(valid):
          valid
        case .failure:
          false
      }

      let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000

      // Log verification result
      let resultMetadata=LogMetadataDTOCollection()
        .withPublic(key: "operation", value: "verify")
        .withPublic(key: "algorithm", value: signatureAlgorithm.rawValue)
        .withPublic(key: "execution_time_ms", value: String(format: "%.2f", executionTime))
        .withPublic(key: "verification_result", value: isValid ? "valid" : "invalid")

      let resultContext=BaseLogContextDTO(
        domainName: "SecurityProvider",
        operation: "verify",
        category: "Security",
        source: "SecurityProviderImpl",
        metadata: resultMetadata
      )
      await logger.debug(
        "Signature verification completed, result: \(isValid ? "valid" : "invalid")",
        context: resultContext
      )

      return SecurityResultDTO.success(
        resultData: isValid ? Data([1]) : Data([0]), // Boolean representation as Data
        executionTimeMs: executionTime,
        metadata: [
          "operation": "verify",
          "algorithm": signatureAlgorithm.rawValue,
          "is_valid": isValid ? "true" : "false"
        ]
      )

    } catch {
      let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000

      // Log error
      let errorMetadata=LogMetadataDTOCollection()
        .withPublic(key: "operation", value: "verify")
        .withPrivate(key: "error", value: error.localizedDescription)

      let errorContext=BaseLogContextDTO(
        domainName: "SecurityProvider",
        operation: "verify",
        category: "Security",
        source: "SecurityProviderImpl",
        metadata: errorMetadata
      )
      await logger.error(
        "Signature verification failed: \(error.localizedDescription)",
        context: errorContext
      )

      return SecurityResultDTO.failure(
        errorDetails: error.localizedDescription,
        executionTimeMs: executionTime
      )
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

      // Validate data identifier
      guard let dataIdentifier=config.options?.metadata?["dataIdentifier"] else {
        throw SecurityProviderError.invalidInput("Missing data identifier for hash verification")
      }

      // Validate hash identifier
      guard let hashIdentifier=config.options?.metadata?["hashIdentifier"] else {
        throw SecurityProviderError.invalidInput("Missing hash identifier for hash verification")
      }

      // Create hash options
      let hashingOptions=CoreSecurityTypes.HashingOptions(
        algorithm: config.hashAlgorithm
      )

      // Delegate verification to the crypto service
      let verifyResult=await cryptoServiceInstance.verifyHash(
        dataIdentifier: dataIdentifier,
        hashIdentifier: hashIdentifier,
        options: hashingOptions
      )

      switch verifyResult {
        case let .success(isValid):
          let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000

          // Log the successful operation
          let metadata=LogMetadataDTOCollection()
            .withPublic(key: "operation", value: "verifyHash")
            .withPublic(key: "algorithm", value: config.hashAlgorithm.rawValue)
            .withPublic(key: "result", value: isValid ? "valid" : "invalid")
            .withPublic(key: "execution_time_ms", value: String(format: "%.2f", executionTime))

          let debugContext=BaseLogContextDTO(
            domainName: "SecurityProvider",
            operation: "verifyHash",
            category: "Security",
            source: "SecurityProviderImpl",
            metadata: metadata
          )
          await logger.debug(
            "Hash verification result: \(isValid ? "valid" : "invalid")",
            context: debugContext
          )

          return SecurityResultDTO.success(
            resultData: Data([UInt8(isValid ? 1 : 0)]),
            executionTimeMs: executionTime,
            metadata: [
              "operation": "verifyHash",
              "algorithm": config.hashAlgorithm.rawValue,
              "isValid": isValid ? "true" : "false"
            ]
          )

        case let .failure(error):
          let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000

          let metadata=LogMetadataDTOCollection()
            .withPublic(key: "operation", value: "verifyHash")
            .withPrivate(key: "error", value: error.localizedDescription)

          let errorContext=BaseLogContextDTO(
            domainName: "SecurityProvider",
            operation: "verifyHash",
            category: "Security",
            source: "SecurityProviderImpl",
            metadata: metadata
          )
          await logger.error(
            "Hash verification operation failed: \(error.localizedDescription)",
            context: errorContext
          )

          return SecurityResultDTO.failure(
            errorDetails: error.localizedDescription,
            executionTimeMs: executionTime
          )
      }
    } catch {
      let executionTime=(Date().timeIntervalSince1970 - startTime) * 1000

      let metadata=LogMetadataDTOCollection()
        .withPublic(key: "operation", value: "verifyHash")
        .withPrivate(key: "error", value: error.localizedDescription)

      let errorContext=BaseLogContextDTO(
        domainName: "SecurityProvider",
        operation: "verifyHash",
        category: "Security",
        source: "SecurityProviderImpl",
        metadata: metadata
      )
      await logger.error(
        "Hash verification operation failed: \(error.localizedDescription)",
        context: errorContext
      )

      return SecurityResultDTO.failure(
        errorDetails: error.localizedDescription,
        executionTimeMs: executionTime
      )
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
    // Log the operation
    let metadata=LogMetadataDTOCollection()
      .withPublic(key: "operation", value: operation.rawValue)
      .withPublic(key: "provider", value: providerType.rawValue)

    let debugContext=BaseLogContextDTO(
      domainName: "SecurityProvider",
      operation: "performSecureOperation",
      category: "Security",
      source: "SecurityProviderImpl",
      metadata: metadata
    )
    await logger.debug(
      "Performing security operation: \(operation.rawValue)",
      context: debugContext
    )

    // Route to appropriate method based on operation
    switch operation {
      case .encrypt:
        return try await encrypt(config: config)
      case .decrypt:
        return try await decrypt(config: config)
      case .hash:
        return try await hash(config: config)
      case .verifyHash:
        return try await verifyHash(config: config)
      case .sign:
        return try await sign(config: config)
      case .verify:
        return try await verify(config: config)
      case .storeKey:
        // Map to secureStore with appropriate options
        var storageOptions=config.options ?? SecurityConfigOptions()
        if let keyData=config.options?.metadata?["keyData"] {
          storageOptions.metadata?["inputData"]=keyData
        }
        return try await secureStore(config: SecurityConfigDTO(
          encryptionAlgorithm: config.encryptionAlgorithm,
          hashAlgorithm: config.hashAlgorithm,
          providerType: config.providerType,
          options: storageOptions
        ))
      case .retrieveKey:
        // Map to secureRetrieve with appropriate options
        return try await secureRetrieve(config: config)
      case .deleteKey:
        // Map to secureDelete with appropriate options
        return try await secureDelete(config: config)
      case .deriveKey, .generateRandom:
        // These operations aren't directly supported yet
        return SecurityResultDTO.failure(
          errorDetails: "Operation \(operation.rawValue) not implemented",
          executionTimeMs: 0
        )
    }
  }

  /**
   Creates a secure configuration with type-safe, Sendable-compliant options.

   - Parameter options: Type-safe options structure that conforms to Sendable
   - Returns: A properly configured SecurityConfigDTO
   */
  public func createSecureConfig(options: SecurityConfigOptions) async -> SecurityConfigDTO {
    // Log the operation
    let metadata=LogMetadataDTOCollection()
      .withPublic(key: "operation", value: "createSecureConfig")

    let debugContext=BaseLogContextDTO(
      domainName: "SecurityProvider",
      operation: "createSecureConfig",
      category: "Security",
      source: "SecurityProviderImpl",
      metadata: metadata
    )
    await logger.debug(
      "Creating secure configuration",
      context: debugContext
    )

    // Default algorithm based on provider type
    let algorithm: EncryptionAlgorithm=switch providerType {
      case .cryptoKit, .appleCryptoKit, .platform:
        .aes256GCM
      case .ring:
        .chacha20Poly1305
      default:
        .aes256CBC
    }

    // Create a configuration with the options and defaults
    let config=SecurityConfigDTO(
      encryptionAlgorithm: algorithm,
      hashAlgorithm: .sha256,
      providerType: providerType,
      options: options
    )

    return config
  }
}

/// Extension to EncryptionAlgorithm to provide key size recommendations
extension EncryptionAlgorithm {
  /// Returns the recommended key size in bits for this algorithm
  func recommendedKeySize() -> Int {
    switch self {
      case .aes256CBC, .aes256GCM:
        256
      case .chacha20Poly1305:
        256
    }
  }
}

// MARK: - Helper Types

/// Tracks performance metrics for security operations
private struct PerformanceMetricsTracker {
  /// Records start time and returns elapsed time in milliseconds
  func recordOperation(name _: String, closure: () async throws -> Void) async rethrows -> Double {
    let startTime=Date().timeIntervalSince1970
    try await closure()
    let endTime=Date().timeIntervalSince1970
    return (endTime - startTime) * 1000
  }
}
