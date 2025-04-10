import CoreSecurityTypes
import CryptoInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import UmbraErrors

/**
 # DefaultCryptoServiceWithProviderImpl

 Default implementation of CryptoServiceProtocol that uses a SecurityProviderProtocol.

 This implementation delegates cryptographic operations to a security provider,
 which allows for different cryptographic backends to be used without changing
 the client code.

 ## Privacy Controls

 This implementation ensures proper privacy classification of sensitive information:
 - Cryptographic keys are treated as private information
 - Data identifiers are generally treated as public information
 - Error details are appropriately classified based on sensitivity
 - Metadata is structured using LogMetadataDTOCollection for privacy-aware logging

 ## Thread Safety

 As an actor, this implementation guarantees thread safety when used from multiple
 concurrent contexts, preventing data races in cryptographic operations.
 */
public actor DefaultCryptoServiceWithProviderImpl: CryptoServiceProtocol {
  /// The security provider to use for cryptographic operations
  private let provider: SecurityProviderProtocol

  /// The secure storage to use
  public let secureStorage: SecureStorageProtocol

  /// Logger for operations
  private let logger: LoggingProtocol

  /**
   Initialises a new crypto service with a security provider.

   - Parameters:
     - provider: The security provider to use
     - secureStorage: The secure storage to use
     - logger: The logger to use
   */
  public init(
    provider: SecurityProviderProtocol,
    secureStorage: SecureStorageProtocol,
    logger: LoggingProtocol
  ) {
    self.provider=provider
    self.secureStorage=secureStorage
    self.logger=logger
  }

  // MARK: - CryptoServiceProtocol Implementation

  /**
   Encrypts data with the specified key using the security provider.

   - Parameters:
     - dataIdentifier: Identifier for the data to encrypt
     - keyIdentifier: Identifier for the encryption key
     - options: Optional encryption options
   - Returns: Result containing the identifier for the encrypted data or an error
   */
  public func encrypt(
    dataIdentifier: String,
    keyIdentifier: String,
    options: CoreSecurityTypes.EncryptionOptions?=nil
  ) async -> Result<String, SecurityStorageError> {
    // Create a log context with proper privacy classification
    let context=CryptoLogContext(
      operation: "encrypt",
      algorithm: options?.algorithm.rawValue,
      correlationID: UUID().uuidString,
      source: "DefaultCryptoServiceWithProviderImpl",
      additionalContext: LogMetadataDTOCollection()
        .withPublic(key: "dataIdentifier", value: dataIdentifier)
        .withPrivate(key: "keyIdentifier", value: keyIdentifier)
        .withPublic(key: "status", value: "started")
    )

    // Add algorithm information if available
    let contextWithOptions=context

    await logger.info(
      "Encrypting data with identifier: \(dataIdentifier)",
      context: contextWithOptions
    )

    // Retrieve the data to encrypt
    let dataResult=await secureStorage.retrieveData(withIdentifier: dataIdentifier)

    guard case .success=dataResult else {
      if case let .failure(error)=dataResult {
        let errorContext=contextWithOptions.withUpdatedMetadata(
          contextWithOptions.metadata.withPublic(
            key: "errorDescription",
            value: error.localizedDescription
          )
        )

        await logger.error(
          "Failed to retrieve data for encryption: \(error)",
          context: errorContext
        )
        return .failure(error)
      }

      let errorContext=contextWithOptions.withUpdatedMetadata(
        contextWithOptions.metadata.withPublic(
          key: "errorDescription",
          value: "Data not found"
        )
      )

      await logger.error(
        "Failed to retrieve data for encryption: data not found",
        context: errorContext
      )
      return .failure(.dataNotFound)
    }

    // Create security configuration
    let configOptions=SecurityConfigOptions(
      enableDetailedLogging: false,
      keyDerivationIterations: 10000,
      memoryLimitBytes: 65536,
      useHardwareAcceleration: true,
      operationTimeoutSeconds: 30,
      verifyOperations: true
    )

    // Add the key identifier and algorithm to the metadata
    var metadata: [String: String]=["keyIdentifier": keyIdentifier]
    if let options {
      metadata["algorithm"]=options.algorithm.rawValue
    }
    configOptions.metadata=metadata

    // Create the security config
    let securityConfig=await provider.createSecureConfig(options: configOptions)

    // Perform the encryption using the provider
    let resultDTO: SecurityResultDTO
    do {
      resultDTO=try await provider.encrypt(config: securityConfig)
    } catch {
      let errorContext=contextWithOptions.withUpdatedMetadata(
        contextWithOptions.metadata.withPublic(
          key: "errorDescription",
          value: "Encryption operation failed: \(error.localizedDescription)"
        )
      )

      await logger.error(
        "Encryption failed with error: \(error)",
        context: errorContext
      )
      return .failure(.operationFailed("Encryption operation failed: \(error)"))
    }

    // Check if the result is successful and contains data
    if resultDTO.successful, let resultData=resultDTO.resultData {
      // Store the encrypted data
      let encryptedID="encrypted_\(UUID().uuidString)"
      let storeResult=await secureStorage.storeData(resultData, withIdentifier: encryptedID)

      guard case .success=storeResult else {
        if case let .failure(error)=storeResult {
          let errorContext=contextWithOptions.withUpdatedMetadata(
            contextWithOptions.metadata.withPublic(
              key: "errorDescription",
              value: error.localizedDescription
            )
          )

          await logger.error(
            "Failed to store encrypted data: \(error)",
            context: errorContext
          )
          return .failure(error)
        }

        let errorContext=contextWithOptions.withUpdatedMetadata(
          contextWithOptions.metadata.withPublic(key: "errorDescription", value: "Storage error")
        )

        await logger.error(
          "Failed to store encrypted data: storage error",
          context: errorContext
        )
        return .failure(.storageError)
      }

      let successContext=contextWithOptions.withUpdatedMetadata(
        contextWithOptions.metadata.withPublic(key: "encryptedIdentifier", value: encryptedID)
      )

      await logger.info(
        "Successfully encrypted data with identifier: \(encryptedID)",
        context: successContext
      )
      return .success(encryptedID)
    } else {
      let errorContext=contextWithOptions.withUpdatedMetadata(
        contextWithOptions.metadata.withPublic(
          key: "errorDescription",
          value: "Encryption operation failed - invalid result data"
        )
      )

      await logger.error(
        "Encryption failed - invalid result data",
        context: errorContext
      )
      return .failure(.operationFailed("Encryption operation failed - invalid result data"))
    }
  }

  /**
   Decrypts data with the specified key using the security provider.

   - Parameters:
     - encryptedDataIdentifier: Identifier for the encrypted data
     - keyIdentifier: Identifier for the decryption key
     - options: Optional decryption options
   - Returns: Result containing the identifier for the decrypted data or an error
   */
  public func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options: CoreSecurityTypes.EncryptionOptions?=nil
  ) async -> Result<String, SecurityStorageError> {
    // Create a log context with proper privacy classification
    let context=CryptoLogContext(
      operation: "decrypt",
      algorithm: options?.algorithm.rawValue,
      correlationID: UUID().uuidString,
      source: "DefaultCryptoServiceWithProviderImpl",
      additionalContext: LogMetadataDTOCollection()
        .withPublic(key: "encryptedDataIdentifier", value: encryptedDataIdentifier)
        .withPrivate(key: "keyIdentifier", value: keyIdentifier)
        .withPublic(key: "status", value: "started")
    )

    // Add algorithm information if available
    let contextWithOptions=context

    await logger.info(
      "Decrypting data with identifier: \(encryptedDataIdentifier)",
      context: contextWithOptions
    )

    // Retrieve the encrypted data from secure storage
    let encryptedDataResult=await secureStorage
      .retrieveData(withIdentifier: encryptedDataIdentifier)

    guard case let .success(encryptedData)=encryptedDataResult else {
      if case let .failure(error)=encryptedDataResult {
        let errorContext=contextWithOptions.withUpdatedMetadata(
          contextWithOptions.metadata.withPublic(
            key: "errorDescription",
            value: error.localizedDescription
          )
        )

        await logger.error(
          "Failed to retrieve encrypted data for decryption: \(error.localizedDescription)",
          context: errorContext
        )
        return .failure(error)
      }

      let errorContext=contextWithOptions.withUpdatedMetadata(
        contextWithOptions.metadata.withPublic(
          key: "errorDescription",
          value: "Encrypted data not found"
        )
      )

      await logger.error(
        "Failed to retrieve encrypted data: not found",
        context: errorContext
      )
      return .failure(.dataNotFound)
    }

    // Create security configuration for decryption
    let configOptions=SecurityConfigOptions(
      enableDetailedLogging: false,
      keyDerivationIterations: 10000,
      memoryLimitBytes: 65536,
      useHardwareAcceleration: true,
      operationTimeoutSeconds: 30,
      verifyOperations: true
    )

    // Add the necessary metadata for the security provider
    var metadata: [String: String]=[
      "keyIdentifier": keyIdentifier,
      "inputData": Data(encryptedData).base64EncodedString()
    ]
    if let options {
      metadata["algorithm"]=options.algorithm.rawValue
    }
    configOptions.metadata=metadata

    // Create the security config
    let securityConfig=await provider.createSecureConfig(options: configOptions)

    // Perform decryption using the provider
    let resultDTO: SecurityResultDTO
    do {
      resultDTO=try await provider.decrypt(config: securityConfig)
    } catch {
      let errorContext=contextWithOptions.withUpdatedMetadata(
        contextWithOptions.metadata.withPublic(
          key: "errorDescription",
          value: "Decryption operation failed: \(error.localizedDescription)"
        )
      )

      await logger.error(
        "Decryption failed with error: \(error.localizedDescription)",
        context: errorContext
      )
      return .failure(.operationFailed("Decryption operation failed: \(error)"))
    }

    // Check if the result is successful and contains data
    if resultDTO.successful, let resultData=resultDTO.resultData {
      // Store the decrypted data
      let decryptedID="decrypted_\(UUID().uuidString)"
      let storeResult=await secureStorage.storeData(resultData, withIdentifier: decryptedID)

      guard case .success=storeResult else {
        if case let .failure(error)=storeResult {
          let errorContext=contextWithOptions.withUpdatedMetadata(
            contextWithOptions.metadata.withPublic(
              key: "errorDescription",
              value: error.localizedDescription
            )
          )

          await logger.error(
            "Failed to store decrypted data: \(error.localizedDescription)",
            context: errorContext
          )
          return .failure(error)
        }

        let errorContext=contextWithOptions.withUpdatedMetadata(
          contextWithOptions.metadata.withPublic(key: "errorDescription", value: "Storage error")
        )

        await logger.error(
          "Failed to store decrypted data: storage error",
          context: errorContext
        )
        return .failure(.storageError)
      }

      // Create success context with decrypted identifier
      let successContext=contextWithOptions.withUpdatedMetadata(
        contextWithOptions.metadata.withPublic(key: "decryptedIdentifier", value: decryptedID)
          .withPublic(
            key: "executionTimeMs",
            value: String(format: "%.2f", resultDTO.executionTimeMs)
          )
      )

      await logger.info(
        "Successfully decrypted data with identifier: \(decryptedID)",
        context: successContext
      )

      return .success(decryptedID)
    } else {
      let errorContext=contextWithOptions.withUpdatedMetadata(
        contextWithOptions.metadata.withPublic(
          key: "errorDescription",
          value: "Decryption operation failed - invalid result data"
        )
      )

      await logger.error(
        "Decryption failed - invalid result data",
        context: errorContext
      )
      return .failure(.operationFailed("Decryption operation failed - invalid result data"))
    }
  }

  /**
   Computes a cryptographic hash of the specified data using the security provider.

   - Parameters:
     - dataIdentifier: Identifier for the data to hash
     - options: Optional hashing options
   - Returns: Result containing the identifier for the hash or an error
   */
  public func hash(
    dataIdentifier: String,
    options: CoreSecurityTypes.HashingOptions?=nil
  ) async -> Result<String, SecurityStorageError> {
    // Create a log context with proper privacy classification
    let context=CryptoLogContext(
      operation: "hash",
      algorithm: options?.algorithm.rawValue,
      correlationID: UUID().uuidString,
      source: "DefaultCryptoServiceWithProviderImpl",
      additionalContext: LogMetadataDTOCollection()
        .withPublic(key: "dataIdentifier", value: dataIdentifier)
        .withPublic(key: "status", value: "started")
    )

    // Add algorithm information if available
    let contextWithOptions=context

    await logger.info(
      "Hashing data with identifier: \(dataIdentifier)",
      context: contextWithOptions
    )

    // Retrieve the data to hash from secure storage
    let dataResult=await secureStorage.retrieveData(withIdentifier: dataIdentifier)

    guard case let .success(dataToHash)=dataResult else {
      if case let .failure(error)=dataResult {
        let errorContext=contextWithOptions.withUpdatedMetadata(
          contextWithOptions.metadata.withPublic(
            key: "errorDescription",
            value: error.localizedDescription
          )
        )

        await logger.error(
          "Failed to retrieve data for hashing: \(error.localizedDescription)",
          context: errorContext
        )
        return .failure(error)
      }

      let errorContext=contextWithOptions.withUpdatedMetadata(
        contextWithOptions.metadata.withPublic(key: "errorDescription", value: "Data not found")
      )

      await logger.error(
        "Failed to retrieve data for hashing: data not found",
        context: errorContext
      )
      return .failure(.dataNotFound)
    }

    // Create security configuration for hashing
    let configOptions=SecurityConfigOptions(
      enableDetailedLogging: false,
      keyDerivationIterations: 10000,
      memoryLimitBytes: 65536,
      useHardwareAcceleration: true,
      operationTimeoutSeconds: 30,
      verifyOperations: true
    )

    // Add the necessary metadata for the security provider
    var metadata: [String: String]=[
      "inputData": Data(dataToHash).base64EncodedString(),
      "inputDataSize": String(dataToHash.count)
    ]

    // Add the hash algorithm if specified in options
    if let options {
      metadata["algorithm"]=options.algorithm.rawValue
    }
    configOptions.metadata=metadata

    // Create the security config
    let securityConfig=await provider.createSecureConfig(options: configOptions)

    // Create a new security config with the desired hash algorithm
    let securityConfigWithAlgorithm = SecurityConfigDTO(
      encryptionAlgorithm: securityConfig.encryptionAlgorithm,
      hashAlgorithm: options?.algorithm ?? .sha256,
      providerType: securityConfig.providerType,
      options: SecurityConfigOptions(
        enableDetailedLogging: securityConfig.options.enableDetailedLogging,
        keyDerivationIterations: securityConfig.options.keyDerivationIterations,
        memoryLimitBytes: securityConfig.options.memoryLimitBytes,
        useHardwareAcceleration: securityConfig.options.useHardwareAcceleration,
        operationTimeoutSeconds: securityConfig.options.operationTimeoutSeconds,
        verifyOperations: securityConfig.options.verifyOperations
      )
    )

    // Perform hashing using the provider
    let resultDTO: SecurityResultDTO
    do {
      resultDTO=try await provider.hash(config: securityConfigWithAlgorithm)
    } catch {
      let errorContext=contextWithOptions.withUpdatedMetadata(
        contextWithOptions.metadata.withPublic(
          key: "errorDescription",
          value: "Hashing operation failed: \(error.localizedDescription)"
        )
      )

      await logger.error(
        "Hashing failed with error: \(error.localizedDescription)",
        context: errorContext
      )
      return .failure(.operationFailed("Hashing operation failed: \(error)"))
    }

    // Check if the result is successful and contains data
    if resultDTO.successful, let hashData=resultDTO.resultData {
      // Store the hash data
      let hashID="hash_\(UUID().uuidString)"
      let storeResult=await secureStorage.storeData(hashData, withIdentifier: hashID)

      guard case .success=storeResult else {
        if case let .failure(error)=storeResult {
          let errorContext=contextWithOptions.withUpdatedMetadata(
            contextWithOptions.metadata.withPublic(
              key: "errorDescription",
              value: error.localizedDescription
            )
          )

          await logger.error(
            "Failed to store hash data: \(error.localizedDescription)",
            context: errorContext
          )
          return .failure(error)
        }

        let errorContext=contextWithOptions.withUpdatedMetadata(
          contextWithOptions.metadata.withPublic(key: "errorDescription", value: "Storage error")
        )

        await logger.error(
          "Failed to store hash data: storage error",
          context: errorContext
        )
        return .failure(.storageError)
      }

      // Create success context with hash identifier
      let successContext=contextWithOptions.withUpdatedMetadata(
        contextWithOptions.metadata
          .withHashed(key: "hashIdentifier", value: hashID)
          .withPublic(
            key: "hashAlgorithm",
            value: securityConfigWithAlgorithm.hashAlgorithm.rawValue
          )
          .withPublic(key: "hashSize", value: String(hashData.count))
          .withPublic(
            key: "executionTimeMs",
            value: String(format: "%.2f", resultDTO.executionTimeMs)
          )
      )

      await logger.info(
        "Successfully hashed data, stored with identifier: \(hashID)",
        context: successContext
      )

      return .success(hashID)
    } else {
      let errorContext=contextWithOptions.withUpdatedMetadata(
        contextWithOptions.metadata.withPublic(
          key: "errorDescription",
          value: "Hashing operation failed - invalid result data"
        )
      )

      await logger.error(
        "Hashing failed - invalid result data",
        context: errorContext
      )
      return .failure(.operationFailed("Hashing operation failed - invalid result data"))
    }
  }

  /**
   Verifies that a hash matches the expected value for the specified data.

   - Parameters:
     - dataIdentifier: Identifier for the data to verify
     - hashIdentifier: Identifier for the expected hash
     - options: Optional hashing options
   - Returns: Result containing a boolean indicating if the hash is valid or an error
   */
  public func verifyHash(
    dataIdentifier: String,
    hashIdentifier: String,
    options: CoreSecurityTypes.HashingOptions?=nil
  ) async -> Result<Bool, SecurityStorageError> {
    // Create a log context with proper privacy classification
    let context=CryptoLogContext(
      operation: "verifyHash",
      algorithm: options?.algorithm.rawValue,
      correlationID: UUID().uuidString,
      source: "DefaultCryptoServiceWithProviderImpl",
      additionalContext: LogMetadataDTOCollection()
        .withPublic(key: "dataIdentifier", value: dataIdentifier)
        .withPublic(key: "hashIdentifier", value: hashIdentifier)
        .withPublic(key: "status", value: "started")
    )

    // Add algorithm information if available
    let contextWithOptions=context

    await logger.info(
      "Verifying hash for data with identifier: \(dataIdentifier)",
      context: contextWithOptions
    )

    // Retrieve the data to verify
    let dataResult=await secureStorage.retrieveData(withIdentifier: dataIdentifier)

    guard case let .success(dataToVerify)=dataResult else {
      if case let .failure(error)=dataResult {
        let errorContext=contextWithOptions.withUpdatedMetadata(
          contextWithOptions.metadata.withPublic(
            key: "errorDescription",
            value: error.localizedDescription
          )
        )

        await logger.error(
          "Failed to retrieve data for hash verification: \(error.localizedDescription)",
          context: errorContext
        )
        return .failure(error)
      }

      let errorContext=contextWithOptions.withUpdatedMetadata(
        contextWithOptions.metadata.withPublic(key: "errorDescription", value: "Data not found")
      )

      await logger.error(
        "Failed to retrieve data for hash verification: data not found",
        context: errorContext
      )
      return .failure(.dataNotFound)
    }

    // Retrieve the stored hash
    let hashResult=await secureStorage.retrieveData(withIdentifier: hashIdentifier)

    guard case let .success(existingHash)=hashResult else {
      if case let .failure(error)=hashResult {
        let errorContext=contextWithOptions.withUpdatedMetadata(
          contextWithOptions.metadata.withPublic(
            key: "errorDescription",
            value: error.localizedDescription
          )
        )

        await logger.error(
          "Failed to retrieve hash for verification: \(error.localizedDescription)",
          context: errorContext
        )
        return .failure(error)
      }

      let errorContext=contextWithOptions.withUpdatedMetadata(
        contextWithOptions.metadata.withPublic(key: "errorDescription", value: "Hash not found")
      )

      await logger.error(
        "Failed to retrieve hash for verification: hash not found",
        context: errorContext
      )
      return .failure(.dataNotFound)
    }

    // Create security configuration for hash verification
    let configOptions=SecurityConfigOptions(
      enableDetailedLogging: false,
      keyDerivationIterations: 10000,
      memoryLimitBytes: 65536,
      useHardwareAcceleration: true,
      operationTimeoutSeconds: 30,
      verifyOperations: true
    )

    // Add the necessary metadata for the security provider
    var metadata: [String: String]=[
      "inputData": Data(dataToVerify).base64EncodedString(),
      "existingHash": Data(existingHash).base64EncodedString(),
      "inputDataSize": String(dataToVerify.count)
    ]

    // Add the hash algorithm if specified in options
    if let options {
      metadata["algorithm"]=options.algorithm.rawValue
    }
    configOptions.metadata=metadata

    // Create the security config
    let securityConfig=await provider.createSecureConfig(options: configOptions)

    // Create a new security config with the desired hash algorithm
    let securityConfigWithAlgorithm = SecurityConfigDTO(
      encryptionAlgorithm: securityConfig.encryptionAlgorithm,
      hashAlgorithm: options?.algorithm ?? .sha256,
      providerType: securityConfig.providerType,
      options: SecurityConfigOptions(
        enableDetailedLogging: securityConfig.options.enableDetailedLogging,
        keyDerivationIterations: securityConfig.options.keyDerivationIterations,
        memoryLimitBytes: securityConfig.options.memoryLimitBytes,
        useHardwareAcceleration: securityConfig.options.useHardwareAcceleration,
        operationTimeoutSeconds: securityConfig.options.operationTimeoutSeconds,
        verifyOperations: securityConfig.options.verifyOperations
      )
    )

    // Perform hash verification using the provider
    let resultDTO: SecurityResultDTO
    do {
      resultDTO=try await provider.verifyHash(config: securityConfigWithAlgorithm)
    } catch {
      let errorContext=contextWithOptions.withUpdatedMetadata(
        contextWithOptions.metadata.withPublic(
          key: "errorDescription",
          value: "Hash verification operation failed: \(error.localizedDescription)"
        )
      )

      await logger.error(
        "Hash verification failed with error: \(error.localizedDescription)",
        context: errorContext
      )
      return .failure(.operationFailed("Hash verification operation failed: \(error)"))
    }

    // Check if the result is successful and contains data
    if resultDTO.successful, let resultData=resultDTO.resultData {
      // Check verification result (typically a single byte: 1 for true, 0 for false)
      let isValid=resultData.first == 1

      // Create success context with verification result
      let successContext=contextWithOptions.withUpdatedMetadata(
        contextWithOptions.metadata
          .withPublic(key: "isValid", value: isValid ? "true" : "false")
          .withPublic(
            key: "hashAlgorithm",
            value: securityConfigWithAlgorithm.hashAlgorithm.rawValue
          )
          .withPublic(
            key: "executionTimeMs",
            value: String(format: "%.2f", resultDTO.executionTimeMs)
          )
      )

      await logger.info(
        "Hash verification result: \(isValid ? "Valid" : "Invalid")",
        context: successContext
      )

      return .success(isValid)
    } else {
      let errorContext=contextWithOptions.withUpdatedMetadata(
        contextWithOptions.metadata.withPublic(
          key: "errorDescription",
          value: "Hash verification operation failed - invalid result data"
        )
      )

      await logger.error(
        "Hash verification failed - invalid result data",
        context: errorContext
      )
      return .failure(.operationFailed("Hash verification operation failed - invalid result data"))
    }
  }

  /**
   Generates a cryptographic key with the specified parameters using the security provider.

   - Parameters:
     - length: Length of the key to generate in bytes
     - options: Optional key generation options
   - Returns: Result containing the identifier for the generated key or an error
   */
  public func generateKey(
    length: Int,
    options: CoreSecurityTypes.KeyGenerationOptions?=nil
  ) async -> Result<String, SecurityStorageError> {
    // Create a log context with proper privacy classification
    let context=CryptoLogContext(
      operation: "generateKey",
      algorithm: nil,
      correlationID: UUID().uuidString,
      source: "DefaultCryptoServiceWithProviderImpl",
      additionalContext: LogMetadataDTOCollection()
        .withPublic(key: "keyLength", value: "\(length)")
        .withPublic(key: "status", value: "started")
    )

    // Add algorithm information if available
    let contextWithOptions=context

    await logger.info(
      "Generating key of length \(length) bytes",
      context: contextWithOptions
    )

    // Create security configuration for key generation
    let configOptions=SecurityConfigOptions(
      enableDetailedLogging: false,
      keyDerivationIterations: 10000,
      memoryLimitBytes: 65536,
      useHardwareAcceleration: true,
      operationTimeoutSeconds: 30,
      verifyOperations: true
    )

    // Set key generation parameters
    var metadata: [String: String]=[
      "keyLength": String(length),
      "keyType": options?.keyType.rawValue ?? "symmetric"
    ]

    // Add additional options if provided
    if let options {
      metadata["useSecureEnclave"] = String(options.useSecureEnclave)
      metadata["isExtractable"] = String(options.isExtractable)
      // Add key type metadata
      metadata["keyTypeName"] = options.keyType.rawValue
    }
    configOptions.metadata=metadata

    // Create the security config
    let securityConfig=await provider.createSecureConfig(options: configOptions)

    // Perform key generation using the provider
    let resultDTO: SecurityResultDTO
    do {
      resultDTO=try await provider.generateKey(config: securityConfig)
    } catch {
      let errorContext=contextWithOptions.withUpdatedMetadata(
        contextWithOptions.metadata.withPublic(
          key: "errorDescription",
          value: "Key generation operation failed: \(error.localizedDescription)"
        )
      )

      await logger.error(
        "Key generation failed with error: \(error.localizedDescription)",
        context: errorContext
      )
      return .failure(.operationFailed("Key generation operation failed: \(error)"))
    }

    // Check if the result is successful and contains data
    if resultDTO.successful, let keyData=resultDTO.resultData {
      // Generate a key identifier
      let keyID="key_\(UUID().uuidString)"

      // Store the key data
      let storeResult=await secureStorage.storeData(keyData, withIdentifier: keyID)

      guard case .success=storeResult else {
        if case let .failure(error)=storeResult {
          let errorContext=contextWithOptions.withUpdatedMetadata(
            contextWithOptions.metadata.withPublic(
              key: "errorDescription",
              value: error.localizedDescription
            )
          )

          await logger.error(
            "Failed to store generated key: \(error.localizedDescription)",
            context: errorContext
          )
          return .failure(error)
        }

        let errorContext=contextWithOptions.withUpdatedMetadata(
          contextWithOptions.metadata.withPublic(key: "errorDescription", value: "Storage error")
        )

        await logger.error(
          "Failed to store generated key: storage error",
          context: errorContext
        )
        return .failure(.storageError)
      }

      // Store key metadata if provided
      if let resultMetadata=resultDTO.metadata, !resultMetadata.isEmpty {
        // We would typically store this metadata alongside the key
        // but for now we'll just log it
        let metadataContext=contextWithOptions.withUpdatedMetadata(
          contextWithOptions.metadata.withPublic(
            key: "metadataSize",
            value: String(resultMetadata.count)
          )
        )

        await logger.debug(
          "Key generated with \(resultMetadata.count) metadata items",
          context: metadataContext
        )
      }

      // Create success context with key identifier
      // Note: We use private for the keyID as it's sensitive information
      let successContext=contextWithOptions.withUpdatedMetadata(
        contextWithOptions.metadata
          .withPrivate(key: "keyIdentifier", value: keyID)
          .withPublic(key: "keyLength", value: String(keyData.count))
          .withPublic(
            key: "executionTimeMs",
            value: String(format: "%.2f", resultDTO.executionTimeMs)
          )
      )

      await logger.info(
        "Successfully generated key with identifier: \(keyID)",
        context: successContext
      )

      return .success(keyID)
    } else {
      let errorContext=contextWithOptions.withUpdatedMetadata(
        contextWithOptions.metadata.withPublic(
          key: "errorDescription",
          value: "Key generation operation failed - invalid result data"
        )
      )

      await logger.error(
        "Key generation failed - invalid result data",
        context: errorContext
      )
      return .failure(.operationFailed("Key generation operation failed - invalid result data"))
    }
  }

  /**
   Stores data in the secure storage.

   - Parameters:
     - data: Data to store
     - identifier: Identifier for the data
   - Returns: Result containing void or an error
   */
  public func storeData(
    data: Data,
    identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    // Create a log context with proper privacy classification
    let context=CryptoLogContext(
      operation: "storeData",
      algorithm: nil,
      correlationID: UUID().uuidString,
      source: "DefaultCryptoServiceWithProviderImpl",
      additionalContext: LogMetadataDTOCollection()
        .withPublic(key: "identifier", value: identifier)
        .withPrivate(key: "dataSize", value: "\(data.count)")
        .withPublic(key: "status", value: "started")
    )

    await logger.info(
      "Storing data with identifier: \(identifier)",
      context: context
    )

    let result=await secureStorage.storeData(Array(data), withIdentifier: identifier)

    switch result {
      case .success:
        let successContext=context.withUpdatedMetadata(
          context.metadata.withPublic(key: "status", value: "success")
        )

        await logger.info(
          "Successfully stored data with identifier: \(identifier)",
          context: successContext
        )

      case let .failure(error):
        let errorContext=context.withUpdatedMetadata(
          context.metadata.withPublic(key: "errorDescription", value: error.localizedDescription)
        )

        await logger.error(
          "Failed to store data: \(error)",
          context: errorContext
        )
    }

    return result
  }

  /**
   Retrieves data from the secure storage.

   - Parameter identifier: Identifier for the data to retrieve
   - Returns: Result containing the data or an error
   */
  public func retrieveData(
    identifier: String
  ) async -> Result<Data, SecurityStorageError> {
    // Create a log context with proper privacy classification
    let context=CryptoLogContext(
      operation: "retrieveData",
      algorithm: nil,
      correlationID: UUID().uuidString,
      source: "DefaultCryptoServiceWithProviderImpl",
      additionalContext: LogMetadataDTOCollection()
        .withPublic(key: "identifier", value: identifier)
        .withPublic(key: "status", value: "started")
    )

    await logger.info(
      "Retrieving data with identifier: \(identifier)",
      context: context
    )

    let result=await secureStorage.retrieveData(withIdentifier: identifier)

    switch result {
      case let .success(bytes):
        let data=Data(bytes)
        let successContext=context.withUpdatedMetadata(
          context.metadata.withPublic(key: "status", value: "success")
            .withPublic(key: "dataSize", value: "\(data.count)")
        )

        await logger.info(
          "Successfully retrieved data (\(data.count) bytes) with identifier: \(identifier)",
          context: successContext
        )

        return .success(data)

      case let .failure(error):
        let errorContext=context.withUpdatedMetadata(
          context.metadata.withPublic(key: "errorDescription", value: error.localizedDescription)
        )

        await logger.error(
          "Failed to retrieve data: \(error)",
          context: errorContext
        )

        return .failure(error)
    }
  }

  /**
   Deletes data from the secure storage.

   - Parameter identifier: Identifier for the data to delete
   - Returns: Result containing void or an error
   */
  public func deleteData(
    identifier: String
  ) async -> Result<Void, SecurityStorageError> {
    // Create a log context with proper privacy classification
    let context=CryptoLogContext(
      operation: "deleteData",
      algorithm: nil,
      correlationID: UUID().uuidString,
      source: "DefaultCryptoServiceWithProviderImpl",
      additionalContext: LogMetadataDTOCollection()
        .withPublic(key: "identifier", value: identifier)
        .withPublic(key: "status", value: "started")
    )

    await logger.info(
      "Deleting data with identifier: \(identifier)",
      context: context
    )

    let result=await secureStorage.deleteData(withIdentifier: identifier)

    switch result {
      case .success:
        let successContext=context.withUpdatedMetadata(
          context.metadata.withPublic(key: "status", value: "success")
        )

        await logger.info(
          "Successfully deleted data with identifier: \(identifier)",
          context: successContext
        )

      case let .failure(error):
        let errorContext=context.withUpdatedMetadata(
          context.metadata.withPublic(key: "errorDescription", value: error.localizedDescription)
        )

        await logger.error(
          "Failed to delete data: \(error)",
          context: errorContext
        )
    }

    return result
  }

  // MARK: - Data Import/Export Operations

  /**
   Imports raw byte array data into the secure storage.

   - Parameters:
     - data: Raw byte array to import
     - customIdentifier: Optional custom identifier for the data
   - Returns: Result containing the identifier for the imported data or an error
   */
  public func importData(
    _ data: [UInt8],
    customIdentifier: String?
  ) async -> Result<String, SecurityStorageError> {
    // Create a log context with proper privacy classification
    let context=CryptoLogContext(
      operation: "importData",
      algorithm: nil,
      correlationID: UUID().uuidString,
      source: "DefaultCryptoServiceWithProviderImpl",
      additionalContext: LogMetadataDTOCollection()
        .withPublic(key: "dataSize", value: "\(data.count)")
        .withPublic(key: "hasCustomIdentifier", value: customIdentifier != nil ? "true" : "false")
        .withPublic(key: "status", value: "started")
    )

    await logger.info(
      "Importing byte array data (\(data.count) bytes)",
      context: context
    )

    let actualIdentifier=customIdentifier ?? "imported_\(UUID().uuidString)"
    let result=await secureStorage.storeData(data, withIdentifier: actualIdentifier)

    switch result {
      case .success:
        let successContext=context.withUpdatedMetadata(
          context.metadata.withPublic(key: "status", value: "success")
            .withPublic(key: "identifier", value: actualIdentifier)
        )

        await logger.info(
          "Successfully imported data with identifier: \(actualIdentifier)",
          context: successContext
        )

        return .success(actualIdentifier)

      case let .failure(error):
        let errorContext=context.withUpdatedMetadata(
          context.metadata.withPublic(key: "errorDescription", value: error.localizedDescription)
        )

        await logger.error(
          "Failed to import data: \(error)",
          context: errorContext
        )

        return .failure(error)
    }
  }

  /**
   Imports raw data into the secure storage.

   - Parameters:
     - data: Raw data to import
     - customIdentifier: Custom identifier for the data
   - Returns: Result containing the identifier for the imported data or an error
   */
  public func importData(
    _ data: Data,
    customIdentifier: String
  ) async -> Result<String, SecurityStorageError> {
    // Create a log context with proper privacy classification
    let context=CryptoLogContext(
      operation: "importData",
      algorithm: nil,
      correlationID: UUID().uuidString,
      source: "DefaultCryptoServiceWithProviderImpl",
      additionalContext: LogMetadataDTOCollection()
        .withPublic(key: "customIdentifier", value: customIdentifier)
        .withPublic(key: "dataSize", value: "\(data.count)")
        .withPublic(key: "status", value: "started")
    )

    await logger.info(
      "Importing data with custom identifier: \(customIdentifier)",
      context: context
    )

    return await importData(Array(data), customIdentifier: customIdentifier)
  }

  /**
   Exports data from the secure storage as a byte array.

   - Parameter identifier: Identifier for the data to export
   - Returns: Result containing the raw byte array or an error
   */
  public func exportData(
    identifier: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    // Create a log context with proper privacy classification
    let context=CryptoLogContext(
      operation: "exportData",
      algorithm: nil,
      correlationID: UUID().uuidString,
      source: "DefaultCryptoServiceWithProviderImpl",
      additionalContext: LogMetadataDTOCollection()
        .withPublic(key: "identifier", value: identifier)
        .withPublic(key: "status", value: "started")
    )

    await logger.info(
      "Exporting data with identifier: \(identifier)",
      context: context
    )

    let result=await secureStorage.retrieveData(withIdentifier: identifier)

    switch result {
      case let .success(data):
        let successContext=context.withUpdatedMetadata(
          context.metadata.withPublic(key: "status", value: "success")
            .withPublic(key: "dataSize", value: "\(data.count)")
        )

        await logger.info(
          "Successfully exported data (\(data.count) bytes) with identifier: \(identifier)",
          context: successContext
        )

        return .success(data)

      case let .failure(error):
        let errorContext=context.withUpdatedMetadata(
          context.metadata.withPublic(key: "errorDescription", value: error.localizedDescription)
        )

        await logger.error(
          "Failed to export data: \(error)",
          context: errorContext
        )

        return .failure(error)
    }
  }

  /**
   For protocol compatibility with other implementations.

   - Parameters:
     - dataIdentifier: Identifier for the data to hash
     - options: Optional hashing options
   - Returns: Result containing the identifier for the hash or an error
   */
  public func generateHash(
    dataIdentifier: String,
    options: CoreSecurityTypes.HashingOptions?=nil
  ) async -> Result<String, SecurityStorageError> {
    // Simply delegate to the hash method
    await hash(dataIdentifier: dataIdentifier, options: options)
  }
}
