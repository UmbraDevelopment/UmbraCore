import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import SecurityCoreTypes
import SecurityTypes

/**
 # SecurityProvider Operations Extension

 This extension adds specialised operations to the SecurityProviderImpl that
 combine multiple basic operations into higher-level functionality.

 ## Operations

 * Combined encrypt and store operations
 * Combined retrieve and decrypt operations
 * Batch encryption and decryption for collections of data
 */
extension SecurityProviderImpl {
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
    data: SecureBytes,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO {
    // Generate a unique operation ID
    let operationID=UUID().uuidString
    let startTime=Date()

    // Create descriptive operation name since this is a composite operation
    let operationName="encryptAndStore"

    // Create log metadata
    let logMetadata: LoggingInterfaces.LogMetadata=[
      "operationId": operationID,
      "operation": operationName
    ]

    await logger.info("Starting combined encrypt and store operation", metadata: logMetadata)

    do {
      // Start with encryption configuration
      var encryptionConfig=config

      // Convert SecureBytes to base64 string for options
      let dataString=data.base64EncodedString()
      var updatedOptions=encryptionConfig.options
      updatedOptions["inputData"]=dataString

      encryptionConfig=SecurityConfigDTO(
        algorithm: encryptionConfig.algorithm,
        keySize: encryptionConfig.keySize,
        hashAlgorithm: encryptionConfig.hashAlgorithm,
        options: updatedOptions
      )

      if encryptionConfig.options["keyIdentifier"] == nil {
        throw SecurityError.invalidKey("No key identifier provided for encryption")
      }
      // Encrypt the data
      let encryptResult=await encrypt(config: encryptionConfig)

      if encryptResult.status != SecurityResultDTO.Status.success {
        return encryptResult
      }

      // Create storage configuration
      var storageConfig=SecurityConfigDTO(
        algorithm: config.algorithm,
        keySize: config.keySize,
        hashAlgorithm: config.hashAlgorithm,
        options: config.options.merging([:]) { (_, new) in new }
      )

      // Use the encrypted data for storage
      if let encryptedData=encryptResult.data {
        var updatedOptions=storageConfig.options
        updatedOptions["storeData"]=encryptedData.base64EncodedString()
        storageConfig=SecurityConfigDTO(
          algorithm: storageConfig.algorithm,
          keySize: storageConfig.keySize,
          hashAlgorithm: storageConfig.hashAlgorithm,
          options: updatedOptions
        )
      } else {
        throw SecurityError.invalidData("No encrypted data available")
      }

      // Generate a storage identifier if not provided
      let storageIdentifier=config.options["storageIdentifier"] ?? UUID().uuidString

      // Create a new storage config with the identifier
      var storageOptions=storageConfig.options
      storageOptions["storageIdentifier"]=storageIdentifier
      storageConfig=SecurityConfigDTO(
        algorithm: storageConfig.algorithm,
        keySize: storageConfig.keySize,
        hashAlgorithm: storageConfig.hashAlgorithm,
        options: storageOptions
      )

      // Store the encrypted data
      let storeResult=await secureStore(config: storageConfig)

      if storeResult.status != SecurityResultDTO.Status.success {
        return storeResult
      }

      // Calculate duration
      let duration=Date().timeIntervalSince(startTime) * 1000

      // Log success
      var resultMetadata: LoggingInterfaces.LogMetadata=[
        "operationId": operationID,
        "storageIdentifier": storageIdentifier,
        "durationMs": String(format: "%.2f", duration)
      ]

      await logger.info(
        "Combined encrypt and store operation completed successfully",
        metadata: resultMetadata
      )

      // Return success result with metadata
      return SecurityResultDTO(
        status: .success,
        data: storeResult.data,
        metadata: resultMetadata
      )
    } catch {
      // Calculate duration
      let duration=Date().timeIntervalSince(startTime) * 1000

      // Create error handler
      let errorHandler=SecurityErrorHandler(logger: logger)

      // Map and log the error
      let securityError=await errorHandler.handleError(
        error,
        operation: .encrypt,
        context: [
          "operationId": operationID,
          "durationMs": String(format: "%.2f", duration),
          "combinedOperation": "encryptAndStore"
        ]
      )

      // Return failure result
      return SecurityResultDTO(
        status: .failure,
        error: securityError,
        metadata: [
          "operationId": operationID,
          "durationMs": String(format: "%.2f", duration)
        ]
      )
    }
  }

  /**
   Retrieves securely stored data and then decrypts it.

   This method combines secure retrieval and decryption into a single operation,
   simplifying common use cases that require both operations.

   - Parameters:
     - identifier: Identifier for the stored data
     - config: Configuration for both operations
   - Returns: Result with decrypted data
   */
  public func retrieveAndDecrypt(
    identifier: String,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO {
    let operationID=UUID().uuidString
    let startTime=Date()
    let operationName="retrieveAndDecrypt"

    let logMetadata: LoggingInterfaces.LogMetadata=[
      "operationId": operationID,
      "identifier": identifier,
      "operation": operationName
    ]

    await logger.info("Starting combined retrieve and decrypt operation", metadata: logMetadata)

    do {
      // Create retrieval config
      var retrievalConfig=SecurityConfigDTO(
        algorithm: config.algorithm,
        keySize: config.keySize,
        hashAlgorithm: config.hashAlgorithm,
        options: config.options.merging([:]) { (_, new) in new }
      )

      // Add storage identifier for retrieval
      var updatedOptions=retrievalConfig.options
      updatedOptions["storageIdentifier"]=identifier
      retrievalConfig=SecurityConfigDTO(
        algorithm: retrievalConfig.algorithm,
        keySize: retrievalConfig.keySize,
        hashAlgorithm: retrievalConfig.hashAlgorithm,
        options: updatedOptions
      )

      // Retrieve the encrypted data
      let retrieveResult=await secureRetrieve(config: retrievalConfig)

      if retrieveResult.status != SecurityResultDTO.Status.success {
        return retrieveResult
      }

      // Create decryption config
      let decryptionConfig=config

      // Use the retrieved encrypted data for decryption
      if let retrievedData=retrieveResult.data {
        var newOptions=decryptionConfig.options
        newOptions["encryptedData"]=retrievedData.base64EncodedString()

        let updatedConfig=SecurityConfigDTO(
          algorithm: decryptionConfig.algorithm,
          keySize: decryptionConfig.keySize,
          hashAlgorithm: decryptionConfig.hashAlgorithm,
          options: newOptions
        )

        return await decrypt(config: updatedConfig)
      } else {
        throw SecurityError.invalidData("No data retrieved")
      }
    } catch {
      // Calculate duration
      let duration=Date().timeIntervalSince(startTime) * 1000

      // Create error handler
      let errorHandler=SecurityErrorHandler(logger: logger)

      // Map and log the error
      let securityError=await errorHandler.handleError(
        error,
        operation: .decrypt,
        context: [
          "operationId": operationID,
          "durationMs": String(format: "%.2f", duration),
          "identifier": identifier,
          "combinedOperation": "retrieveAndDecrypt"
        ]
      )

      // Return failure result
      return SecurityResultDTO(
        status: .failure,
        error: securityError,
        metadata: [
          "operationId": operationID,
          "durationMs": String(format: "%.2f", duration),
          "identifier": identifier
        ]
      )
    }
  }

  /**
   Performs batch encryption on multiple data items.

   This method encrypts multiple data items in sequence using the same configuration
   but returning individual results for each item.

   - Parameters:
     - dataItems: Collection of data items to encrypt
     - config: Base configuration for encryption operations
   - Returns: Array of encryption results corresponding to each input item
   */
  public func batchEncrypt(
    dataItems: [SecureBytes],
    config: SecurityConfigDTO
  ) async -> [SecurityResultDTO] {
    let operationID=UUID().uuidString
    let logMetadata: LoggingInterfaces.LogMetadata=[
      "itemCount": String(dataItems.count),
      "operationId": operationID
    ]

    await logger.info(
      "Starting batch encryption of \(dataItems.count) items",
      metadata: logMetadata
    )

    var results: [SecurityResultDTO]=[]
    var successCount=0

    // Process each item sequentially
    for (index, item) in dataItems.enumerated() {
      // Clone the base config for this item
      var itemConfig=config

      // Convert SecureBytes to base64 string for options
      let dataString=item.base64EncodedString()
      var updatedOptions=itemConfig.options
      updatedOptions["inputData"]=dataString

      itemConfig=SecurityConfigDTO(
        algorithm: itemConfig.algorithm,
        keySize: itemConfig.keySize,
        hashAlgorithm: itemConfig.hashAlgorithm,
        options: updatedOptions
      )

      // Encrypt this item
      let encryptResult=await encrypt(config: itemConfig)
      results.append(encryptResult)

      if encryptResult.status == SecurityResultDTO.Status.success {
        successCount += 1
      } else {
        await logger.error("Batch encryption failed at item \(index + 1)", metadata: logMetadata)
      }
    }

    // Log batch summary
    let batchMetadata: LoggingInterfaces.LogMetadata=[
      "totalItems": String(dataItems.count),
      "successCount": String(successCount),
      "failureCount": String(dataItems.count - successCount),
      "operationId": operationID
    ]

    await logger.info(
      "Batch encryption completed: \(successCount)/\(dataItems.count) successful",
      metadata: batchMetadata
    )

    return results
  }

  /**
   Performs batch decryption on multiple data items.

   This method decrypts multiple data items in sequence using the same configuration
   but returning individual results for each item.

   - Parameters:
     - dataItems: Collection of encrypted data items to decrypt
     - config: Base configuration for decryption operations
   - Returns: Array of decryption results corresponding to each input item
   */
  public func batchDecrypt(
    dataItems: [SecureBytes],
    config: SecurityConfigDTO
  ) async -> [SecurityResultDTO] {
    let operationID=UUID().uuidString
    let logMetadata: LoggingInterfaces.LogMetadata=[
      "itemCount": String(dataItems.count),
      "operationId": operationID
    ]

    await logger.info(
      "Starting batch decryption of \(dataItems.count) items",
      metadata: logMetadata
    )

    var results: [SecurityResultDTO]=[]
    var successCount=0

    // Process each item sequentially
    for (index, item) in dataItems.enumerated() {
      // Clone the base config for this item
      var itemConfig=config

      // Convert SecureBytes to base64 string for options
      let dataString=item.base64EncodedString()
      var updatedOptions=itemConfig.options
      updatedOptions["encryptedData"]=dataString

      itemConfig=SecurityConfigDTO(
        algorithm: itemConfig.algorithm,
        keySize: itemConfig.keySize,
        hashAlgorithm: itemConfig.hashAlgorithm,
        options: updatedOptions
      )

      // Decrypt this item
      let decryptResult=await decrypt(config: itemConfig)
      results.append(decryptResult)

      if decryptResult.status == SecurityResultDTO.Status.success {
        successCount += 1
      } else {
        await logger.error("Batch decryption failed at item \(index + 1)", metadata: logMetadata)
      }
    }

    // Log batch summary
    let batchMetadata: LoggingInterfaces.LogMetadata=[
      "totalItems": String(dataItems.count),
      "successCount": String(successCount),
      "failureCount": String(dataItems.count - successCount),
      "operationId": operationID
    ]

    await logger.info(
      "Batch decryption completed: \(successCount)/\(dataItems.count) successful",
      metadata: batchMetadata
    )

    return results
  }

  /**
   Generates random secure data of the specified length.

   - Parameter config: Configuration containing length and other parameters
   - Returns: Result with random data
   */
  public func generateRandom(
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO {
    // Generate a unique operation ID
    let operationID=UUID().uuidString
    let startTime=Date()

    // Create metadata for logging
    let metadata: LoggingInterfaces.LogMetadata=[
      "operationId": operationID,
      "operation": SecurityOperation.generateRandom(length: 0).rawValue
    ]

    let logMetadata=metadata

    // Get the requested length
    guard
      let lengthString=config.options["length"],
      let length=Int(lengthString)
    else {
      return SecurityResultDTO(
        status: .failure,
        error: SecurityError
          .invalidInput("Missing or invalid length parameter for random data generation"),
        metadata: metadata
      )
    }

    await logger.info("Generating secure random data of \(length) bytes", metadata: logMetadata)

    // Generate random bytes directly
    var randomBytes=[UInt8](repeating: 0, count: length)
    _=SecRandomCopyBytes(kSecRandomDefault, length, &randomBytes)

    // Convert to secure bytes
    let secureBytes=SecureBytes(bytes: randomBytes)

    // Calculate duration
    let duration=Date().timeIntervalSince(startTime) * 1000

    await logger.info(
      "Random data generation completed successfully",
      metadata: logMetadata
    )

    // Add duration to metadata
    var resultMetadata: LoggingInterfaces.LogMetadata=metadata
    resultMetadata["durationMs"]=String(format: "%.2f", duration)

    // Return success result
    return SecurityResultDTO(
      status: .success,
      data: secureBytes,
      metadata: resultMetadata
    )
  }
}
