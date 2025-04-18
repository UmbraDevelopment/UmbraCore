import CoreSecurityTypes
import DomainSecurityTypes
import Foundation

/// Helper function to create LogMetadataDTOCollection from dictionary
private func createMetadataCollection(_ dict: [String: String]) -> LogMetadataDTOCollection {
  var collection=LogMetadataDTOCollection()
  for (key, value) in dict {
    collection=collection.withPublic(key: key, value: value)
  }
  return collection
}

// Helper function to convert LogMetadataDTOCollection to [String: String]
private func dictionaryFromMetadata(_: LogMetadataDTOCollection) -> [String: String] {
  // Instead of using publicItems which doesn't exist, we need to
  // implement a proper conversion or access the entries properly
  var result=[String: String]()
  // Since we can't directly access the items, we'll return an empty dictionary for now
  // This will need to be addressed based on the actual LogMetadataDTOCollection implementation
  return result
}

import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces

/**
 # SecurityProvider Operations Extension

 This extension adds specialised operations to the SecurityProviderService that
 combine multiple basic operations into higher-level functionality.

 ## Operations

 * Combined encrypt and store operations
 * Combined retrieve and decrypt operations
 * Batch encryption and decryption for collections of data
 */
extension SecurityProviderService {
  /**
   Encrypts data and then stores it securely.

   This method combines encryption and secure storage into a single operation,
   simplifying common use cases that require both operations.

   - Parameters:
     - data: The data to encrypt and store
     - config: Configuration for both operations
   - Returns: Result with storage metadata
   */
  public func encryptAndStore(
    data _: Data,
    config: SecurityConfigDTO
  ) async throws -> SecurityResultDTO {
    // First encrypt the data
    let encryptConfig=config
    let encryptResult=try await performSecureOperation(
      operation: .encrypt,
      config: encryptConfig
    )

    // If encryption failed, return that error immediately
    if !encryptResult.successful {
      return encryptResult
    }

    // Now store the encrypted data
    let storeConfig=SecurityConfigDTO(
      encryptionAlgorithm: config.encryptionAlgorithm,
      hashAlgorithm: config.hashAlgorithm,
      providerType: config.providerType,
      options: SecurityConfigOptions(
        enableDetailedLogging: config.options?.enableDetailedLogging ?? false,
        keyDerivationIterations: config.options?.keyDerivationIterations ?? 100_000,
        memoryLimitBytes: config.options?.memoryLimitBytes ?? 65536,
        useHardwareAcceleration: config.options?.useHardwareAcceleration ?? true,
        operationTimeoutSeconds: config.options?.operationTimeoutSeconds ?? 30.0,
        verifyOperations: config.options?.verifyOperations ?? true,
        metadata: [
          "location": config.options?.metadata?["storeLocation"] ?? "default",
          "identifier": config.options?.metadata?["storeIdentifier"] ?? UUID().uuidString,
          "data": encryptResult.resultData?.base64EncodedString() ?? ""
        ]
      )
    )

    let storeResult=try await performSecureOperation(
      operation: .storeKey,
      config: storeConfig
    )

    await logger.info(
      "Storing encrypted data in secure storage",
      context: LoggingTypes.BaseLogContextDTO(
        domainName: "SecurityImplementation",
        source: "SecurityProvider+Operations.encryptAndStore",
        metadata: createMetadataCollection([
          "location": config.options?.metadata?["storeLocation"] ?? "default"
        ])
      )
    )

    return storeResult
  }

  /**
   Retrieves encrypted data and decrypts it in a single operation.

   This method combines retrieval and decryption into a single operation,
   simplifying common use cases that require both operations.

   - Parameters:
     - identifier: The identifier for the stored data
     - config: Configuration for both operations
   - Returns: The decrypted data
   */
  public func retrieveAndDecrypt(
    identifier: String,
    config: SecurityConfigDTO
  ) async throws -> SecurityResultDTO {
    // First retrieve the encrypted data
    let retrieveConfig=SecurityConfigDTO(
      encryptionAlgorithm: config.encryptionAlgorithm,
      hashAlgorithm: config.hashAlgorithm,
      providerType: config.providerType,
      options: SecurityConfigOptions(
        enableDetailedLogging: config.options?.enableDetailedLogging ?? false,
        keyDerivationIterations: config.options?.keyDerivationIterations ?? 100_000,
        memoryLimitBytes: config.options?.memoryLimitBytes ?? 65536,
        useHardwareAcceleration: config.options?.useHardwareAcceleration ?? true,
        operationTimeoutSeconds: config.options?.operationTimeoutSeconds ?? 30.0,
        verifyOperations: config.options?.verifyOperations ?? true,
        metadata: [
          "location": config.options?.metadata?["storeLocation"] ?? "default",
          "identifier": identifier
        ]
      )
    )

    // Retrieve the encrypted data
    let retrieveResult=try await performSecureOperation(
      operation: .retrieveKey,
      config: retrieveConfig
    )

    await logger.info(
      "Retrieving encrypted data from secure storage",
      context: LoggingTypes.BaseLogContextDTO(
        domainName: "SecurityImplementation",
        source: "SecurityProvider+Operations.retrieveAndDecrypt",
        metadata: createMetadataCollection([
          "location": config.options?.metadata?["storeLocation"] ?? "default"
        ])
      )
    )

    // If retrieval failed, return that error immediately
    if !retrieveResult.successful {
      return retrieveResult
    }

    // Now decrypt the data
    guard let encryptedDataBase64=retrieveResult.resultData else {
      // Log and return error
      await logger.error(
        "Retrieved data was nil",
        context: LoggingTypes.BaseLogContextDTO(
          domainName: "SecurityImplementation",
          source: "SecurityProvider+Operations.retrieveAndDecrypt",
          metadata: createMetadataCollection([
            "identifier": identifier
          ])
        )
      )

      return SecurityResultDTO.failure(
        errorDetails: "Retrieved data was nil",
        executionTimeMs: 0,
        metadata: [
          "identifier": identifier
        ]
      )
    }

    // Create decrypt config
    let decryptConfig=SecurityConfigDTO(
      encryptionAlgorithm: config.encryptionAlgorithm,
      hashAlgorithm: config.hashAlgorithm,
      providerType: config.providerType,
      options: SecurityConfigOptions(
        enableDetailedLogging: config.options?.enableDetailedLogging ?? false,
        keyDerivationIterations: config.options?.keyDerivationIterations ?? 100_000,
        memoryLimitBytes: config.options?.memoryLimitBytes ?? 65536,
        useHardwareAcceleration: config.options?.useHardwareAcceleration ?? true,
        operationTimeoutSeconds: config.options?.operationTimeoutSeconds ?? 30.0,
        verifyOperations: config.options?.verifyOperations ?? true,
        metadata: config.options?.metadata ?? [:]
      )
    )

    // Decrypt the data
    let decryptResult=try await performSecureOperation(
      operation: .decrypt,
      config: decryptConfig
    )

    return decryptResult
  }

  /**
   Performs batch encryption on multiple data items.

   This method encrypts multiple data items in sequence using the same configuration
   but returning individual results for each item.

   - Parameters:
     - dataItems: Array of data items to encrypt
     - config: The encryption configuration to use
   - Returns: Array of encryption results corresponding to each input item
   */
  public func batchEncrypt(
    dataItems: [Data],
    config: SecurityConfigDTO
  ) async -> [SecurityResultDTO] {
    let operationID=UUID().uuidString
    let metadataCollection=LogMetadataDTOCollection()
      .withPublic(key: "itemCount", value: String(dataItems.count))
      .withPublic(key: "operationId", value: operationID)

    await logger.info(
      "Starting batch encryption operation",
      context: LoggingTypes.BaseLogContextDTO(
        domainName: "SecurityImplementation",
        source: "SecurityProvider+Operations.batchEncrypt",
        metadata: metadataCollection
      )
    )

    var results=[SecurityResultDTO]()
    for (index, data) in dataItems.enumerated() {
      // Create config with the current data item
      var itemConfig=config

      // Add the current data item to the config
      var metadata=config.options?.metadata ?? [:]
      metadata["data"]=data.base64EncodedString()
      metadata["itemIndex"]=String(index)

      let itemOptions=SecurityConfigOptions(
        enableDetailedLogging: config.options?.enableDetailedLogging ?? false,
        keyDerivationIterations: config.options?.keyDerivationIterations ?? 100_000,
        memoryLimitBytes: config.options?.memoryLimitBytes ?? 65536,
        useHardwareAcceleration: config.options?.useHardwareAcceleration ?? true,
        operationTimeoutSeconds: config.options?.operationTimeoutSeconds ?? 30.0,
        verifyOperations: config.options?.verifyOperations ?? true,
        metadata: metadata
      )

      itemConfig=SecurityConfigDTO(
        encryptionAlgorithm: config.encryptionAlgorithm,
        hashAlgorithm: config.hashAlgorithm,
        providerType: config.providerType,
        options: itemOptions
      )

      // Encrypt the current item
      do {
        let result=try await performSecureOperation(
          operation: .encrypt,
          config: itemConfig
        )
        results.append(result)
      } catch {
        // If encryption fails, add a failure result
        results.append(
          SecurityResultDTO.failure(
            errorDetails: "Encryption operation failed: \(error.localizedDescription)",
            executionTimeMs: 0,
            metadata: [
              "itemIndex": String(index)
            ]
          )
        )
      }

      await logger.debug(
        "Processing batch encryption item",
        context: LoggingTypes.BaseLogContextDTO(
          domainName: "SecurityImplementation",
          source: "SecurityProvider+Operations.batchEncrypt",
          metadata: createMetadataCollection([
            "itemIndex": String(index)
          ])
        )
      )
    }

    await logger.info(
      "Completed batch encryption operation",
      context: LoggingTypes.BaseLogContextDTO(
        domainName: "SecurityImplementation",
        source: "SecurityProvider+Operations.batchEncrypt",
        metadata: metadataCollection
      )
    )

    return results
  }

  /**
   Performs batch decryption on multiple encrypted data items.

   This method decrypts multiple data items in sequence using the same configuration
   but returning individual results for each item.

   - Parameters:
     - dataItems: Array of encrypted data items to decrypt
     - config: The decryption configuration to use
   - Returns: Array of decryption results corresponding to each input item
   */
  public func batchDecrypt(
    dataItems: [Data],
    config: SecurityConfigDTO
  ) async -> [SecurityResultDTO] {
    let operationID=UUID().uuidString
    let metadataCollection=LogMetadataDTOCollection()
      .withPublic(key: "itemCount", value: String(dataItems.count))
      .withPublic(key: "operationId", value: operationID)

    await logger.info(
      "Starting batch decryption operation",
      context: LoggingTypes.BaseLogContextDTO(
        domainName: "SecurityImplementation",
        source: "SecurityProvider+Operations.batchDecrypt",
        metadata: metadataCollection
      )
    )

    var results=[SecurityResultDTO]()
    for (index, data) in dataItems.enumerated() {
      // Create config with the current data item
      var itemConfig=config

      // Add the current data item to the config
      var metadata=config.options?.metadata ?? [:]
      metadata["data"]=data.base64EncodedString()
      metadata["itemIndex"]=String(index)

      let itemOptions=SecurityConfigOptions(
        enableDetailedLogging: config.options?.enableDetailedLogging ?? false,
        keyDerivationIterations: config.options?.keyDerivationIterations ?? 100_000,
        memoryLimitBytes: config.options?.memoryLimitBytes ?? 65536,
        useHardwareAcceleration: config.options?.useHardwareAcceleration ?? true,
        operationTimeoutSeconds: config.options?.operationTimeoutSeconds ?? 30.0,
        verifyOperations: config.options?.verifyOperations ?? true,
        metadata: metadata
      )

      itemConfig=SecurityConfigDTO(
        encryptionAlgorithm: config.encryptionAlgorithm,
        hashAlgorithm: config.hashAlgorithm,
        providerType: config.providerType,
        options: itemOptions
      )

      // Decrypt the current item
      do {
        let result=try await performSecureOperation(
          operation: .decrypt,
          config: itemConfig
        )
        results.append(result)
      } catch {
        // If decryption fails, add a failure result
        results.append(
          SecurityResultDTO.failure(
            errorDetails: "Decryption operation failed: \(error.localizedDescription)",
            executionTimeMs: 0,
            metadata: [
              "itemIndex": String(index)
            ]
          )
        )
      }

      await logger.debug(
        "Processing batch decryption item",
        context: LoggingTypes.BaseLogContextDTO(
          domainName: "SecurityImplementation",
          source: "SecurityProvider+Operations.batchDecrypt",
          metadata: createMetadataCollection([
            "itemIndex": String(index)
          ])
        )
      )
    }

    await logger.info(
      "Completed batch decryption operation",
      context: LoggingTypes.BaseLogContextDTO(
        domainName: "SecurityImplementation",
        source: "SecurityProvider+Operations.batchDecrypt",
        metadata: metadataCollection
      )
    )

    return results
  }

  /**
   Generates cryptographically secure random data.

   This method creates random data suitable for cryptographic operations like
   key generation, nonce creation, or salt generation.

   - Parameter config: Configuration specifying the length of random data needed
   - Returns: Result containing the generated random data
   */
  public func generateSecureRandom(
    config: SecurityConfigDTO
  ) async throws -> SecurityResultDTO {
    // Generate a unique operation ID
    let operationID=UUID().uuidString
    let startTime=Date()

    // Create metadata for logging
    let metadataCollection=LogMetadataDTOCollection()

    // Validate length parameter in config
    guard
      let metadata=config.options?.metadata,
      let lengthString=metadata["length"],
      let length=Int(lengthString)
    else {
      // Create log metadata
      let bytesRequested=32 // Default to 32 bytes if not specified
      let metadataItems=[
        "bytesRequested": String(bytesRequested),
        "operationId": UUID().uuidString,
        "source": "randomData"
      ]

      // Return error result with operation details
      return CoreSecurityTypes.SecurityResultDTO.failure(
        errorDetails: "Missing or invalid length parameter for random data generation",
        executionTimeMs: 0,
        metadata: metadataItems
      )
    }

    await logger.info(
      "Generating secure random data of \(length) bytes",
      context: LoggingTypes.BaseLogContextDTO(
        domainName: "SecurityImplementation",
        source: "SecurityProvider+Operations.generateSecureRandom",
        metadata: metadataCollection.withSensitive(key: "randomDataLength", value: String(length))
      )
    )

    // Generate random bytes directly
    var randomBytes=[UInt8](repeating: 0, count: length)
    let status=SecRandomCopyBytes(
      kSecRandomDefault,
      length,
      &randomBytes
    )

    // Calculate duration
    let duration=Date().timeIntervalSince(startTime) * 1000

    if status != errSecSuccess {
      await logger.error(
        "Failed to generate random data: Error \(status)",
        context: LoggingTypes.BaseLogContextDTO(
          domainName: "SecurityImplementation",
          source: "SecurityProvider+Operations.generateSecureRandom",
          metadata: metadataCollection.withPrivate(key: "errorStatus", value: String(status))
        )
      )

      return SecurityResultDTO.failure(
        errorDetails: "Random data generation failed with status \(status)",
        executionTimeMs: duration,
        metadata: metadata
      )
    }

    // Convert to Data
    let randomData=Data(randomBytes)

    // Add duration to result metadata
    var resultMetadata=metadata
    resultMetadata["durationMs"]=String(format: "%.2f", duration)

    await logger.info(
      "Random data generation completed successfully",
      context: LoggingTypes.BaseLogContextDTO(
        domainName: "SecurityImplementation",
        source: "SecurityProvider+Operations.generateSecureRandom",
        metadata: metadataCollection.withPublic(
          key: "durationMs",
          value: String(format: "%.2f", duration)
        )
      )
    )

    // Return success result
    return SecurityResultDTO.success(
      resultData: randomData,
      executionTimeMs: duration,
      metadata: resultMetadata
    )
  }
}
