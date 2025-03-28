import CryptoInterfaces
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces
import SecurityCoreTypes
import SecurityKeyManagement
import SecurityTypes

/**
 # SecurityProviderImpl

 Primary implementation of the SecurityProviderProtocol, offering all required
 security operations with proper error handling and logging.

 ## Dependencies

 This implementation relies on three key dependencies:
 - CryptoServiceProtocol: Provides low-level cryptographic functions
 - KeyManagementProtocol: Manages secure key storage and retrieval
 - LoggingProtocol: Provides logging capabilities
 */
@preconcurrency
public actor SecurityProviderImpl: SecurityProviderProtocol {
  // MARK: - Dependencies

  public let cryptoService: SecurityCoreInterfaces.CryptoServiceProtocol
  public let keyManager: KeyManagementProtocol
  internal let logger: LoggingProtocol

  // MARK: - Properties

  // Map of active operations by ID
  private var activeOperations = [String: SecurityOperation]()

  // MARK: - Initialisation

  /**
   Initialises a new SecurityProviderImpl with the specified dependencies.

   - Parameters:
     - cryptoService: Cryptographic service implementation
     - keyManager: Key management service implementation
     - logger: Logger for recording operations
   */
  public init(
    cryptoService: SecurityCoreInterfaces.CryptoServiceProtocol,
    keyManager: KeyManagementProtocol,
    logger: LoggingProtocol
  ) {
    self.cryptoService = cryptoService
    self.keyManager = keyManager
    self.logger = logger
  }

  // MARK: - Protocol Methods

  /**
   Encrypts data with the specified configuration.

   - Parameter config: Configuration for the encryption operation
   - Returns: Result containing encrypted data or error
   */
  public func encrypt(config: SecurityConfigDTO) async -> SecurityResultDTO {
    let operationID = UUID().uuidString
    let startTime = Date()
    let operation = SecurityOperation.encrypt

    activeOperations[operationID] = operation
    defer { activeOperations.removeValue(forKey: operationID) }

    // Log operation start
    let logMetadata = LogMetadata([
      "operationId": operationID,
      "operation": operation.rawValue,
      "algorithm": config.algorithm
    ])
    await logger.info("Starting security operation: \(operation.description)", metadata: logMetadata)

    do {
      // Get the input data from configuration
      guard
        let dataString = config.options["inputData"],
        let inputData = Data(base64Encoded: dataString)
      else {
        throw SecurityError.invalidInput("No valid data provided for encryption")
      }

      // Convert Data to SecureBytes
      let secureInputBytes = SecureBytes(data: inputData)

      // Get the key identifier
      guard let keyIdentifier = config.options["keyIdentifier"] else {
        throw SecurityError.invalidKey("No key identifier provided for encryption")
      }

      // Get the key from identifier first
      let keyBytes = try await keyManager.retrieveKey(withIdentifier: keyIdentifier).get()

      // Encrypt the data
      let encryptionResult = await cryptoService.encrypt(
        data: secureInputBytes,
        using: keyBytes
      )
      
      // Handle the result
      let encryptedData: SecureBytes
      switch encryptionResult {
      case .success(let data):
        encryptedData = data
      case .failure(let error):
        throw SecurityError.operationFailed("Encryption failed: \(error.localizedDescription)")
      }

      // Calculate duration
      let duration = Date().timeIntervalSince(startTime) * 1000

      // Log success
      let successMetadata = LogMetadata([
        "operationId": operationID,
        "operation": operation.rawValue,
        "algorithm": config.algorithm,
        "durationMs": String(format: "%.2f", duration)
      ])
      await logger.info(
        "Successfully completed security operation: \(operation.description)",
        metadata: successMetadata
      )

      // Return successful result
      return SecurityResultDTO(
        status: .success,
        data: encryptedData,
        metadata: successMetadata.asDictionary.mapValues { "\($0)" }
      )
    } catch {
      // Calculate duration
      let duration = Date().timeIntervalSince(startTime) * 1000

      // Create error handler
      let errorHandler = SecurityErrorHandler(logger: logger)

      // Map and log the error
      let securityError = await errorHandler.handleError(
        error,
        operation: operation,
        context: [
          "operationId": operationID,
          "durationMs": String(format: "%.2f", duration)
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
   Decrypts data with the specified configuration.

   - Parameter config: Configuration for the decryption operation
   - Returns: Result containing decrypted data or error
   */
  public func decrypt(config: SecurityConfigDTO) async -> SecurityResultDTO {
    let operationID = UUID().uuidString
    let startTime = Date()
    let operation = SecurityOperation.decrypt

    activeOperations[operationID] = operation
    defer { activeOperations.removeValue(forKey: operationID) }

    do {
      // Log operation start
      let logMetadata = LogMetadata([
        "operationId": operationID,
        "operation": operation.rawValue,
        "algorithm": config.algorithm
      ])
      await logger.info("Starting security operation: \(operation.description)", metadata: logMetadata)

      // Get the input data from the config
      guard
        let inputDataString = config.options["inputData"],
        let inputData = Data(base64Encoded: inputDataString)
      else {
        throw SecurityError.invalidInput("Invalid input data format")
      }

      // Convert Data to SecureBytes
      let secureInputBytes = SecureBytes(data: inputData)

      // Get the key identifier
      guard let keyIdentifier = config.options["keyIdentifier"] else {
        throw SecurityError.invalidInput("Missing key identifier")
      }

      // Perform the decryption
      let keyBytes = try await keyManager.retrieveKey(withIdentifier: keyIdentifier).get()
      
      let decryptionResult = await cryptoService.decrypt(
        data: secureInputBytes,
        using: keyBytes
      )
      
      // Handle the result
      let decryptedBytes: SecureBytes
      switch decryptionResult {
      case .success(let data):
        decryptedBytes = data
      case .failure(let error):
        throw SecurityError.operationFailed("Decryption failed: \(error.localizedDescription)")
      }

      // Calculate duration
      let duration = Date().timeIntervalSince(startTime) * 1000

      // Log success
      let successMetadata = LogMetadata([
        "operationId": operationID,
        "operation": operation.rawValue,
        "algorithm": config.algorithm,
        "durationMs": String(format: "%.2f", duration)
      ])
      await logger.info(
        "Successfully completed security operation: \(operation.description)",
        metadata: successMetadata
      )

      // Return successful result
      return SecurityResultDTO(
        status: .success,
        data: decryptedBytes,
        metadata: successMetadata.asDictionary.mapValues { "\($0)" }
      )
    } catch {
      // Calculate duration
      let duration = Date().timeIntervalSince(startTime) * 1000

      // Create error handler
      let errorHandler = SecurityErrorHandler(logger: logger)

      // Map and log the error
      let securityError = await errorHandler.handleError(
        error,
        operation: operation,
        context: [
          "operationId": operationID,
          "durationMs": String(format: "%.2f", duration)
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
   Generates a new cryptographic key with the specified configuration.

   - Parameter config: Configuration for the key generation operation
   - Returns: Result containing key identifier or error
   */
  public func generateKey(config: SecurityConfigDTO) async -> SecurityResultDTO {
    let operationID = UUID().uuidString
    let startTime = Date()
    let operation = SecurityOperation.generateKey

    activeOperations[operationID] = operation
    defer { activeOperations.removeValue(forKey: operationID) }

    do {
      // Log operation start
      let logMetadata = LogMetadata([
        "operationId": operationID,
        "operation": operation.rawValue,
        "algorithm": config.algorithm
      ])
      await logger.info("Starting security operation: \(operation.description)", metadata: logMetadata)

      // Generate a custom identifier if provided, otherwise use a UUID
      let keyIdentifier = config.options["keyIdentifier"] ?? UUID().uuidString

      // Generate and store the key
      let keyBytes = try await generateAndStoreKey(
        identifier: keyIdentifier,
        algorithm: config.algorithm,
        size: config.keySize
      )

      // Store the generated key for later use
      _ = keyBytes

      // Calculate duration
      let duration = Date().timeIntervalSince(startTime) * 1000

      // Log success
      let successMetadata = LogMetadata([
        "operationId": operationID,
        "operation": operation.rawValue,
        "algorithm": config.algorithm,
        "durationMs": String(format: "%.2f", duration)
      ])
      await logger.info(
        "Successfully completed security operation: \(operation.description)",
        metadata: successMetadata
      )

      // Return successful result with the key identifier
      guard let successMessage = stringToSecureBytes("Key generated and stored securely with identifier: \(keyIdentifier)") else {
        throw SecurityError.systemError("Failed to create success message")
      }
      
      return SecurityResultDTO(
        status: .success,
        data: successMessage,
        metadata: successMetadata.asDictionary.mapValues { "\($0)" }
      )
    } catch {
      // Calculate duration
      let duration = Date().timeIntervalSince(startTime) * 1000

      // Create error handler
      let errorHandler = SecurityErrorHandler(logger: logger)

      // Map and log the error
      let securityError = await errorHandler.handleError(
        error,
        operation: operation,
        context: [
          "operationId": operationID,
          "durationMs": String(format: "%.2f", duration)
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
   Securely stores data with the specified configuration.

   - Parameter config: Configuration for the secure storage operation
   - Returns: Result containing success status or error
   */
  public func secureStore(config: SecurityConfigDTO) async -> SecurityResultDTO {
    let operationID = UUID().uuidString
    let startTime = Date()
    let operation = SecurityOperation.secureStore

    activeOperations[operationID] = operation
    defer { activeOperations.removeValue(forKey: operationID) }

    do {
      // Log operation start
      let logMetadata = LogMetadata([
        "operationId": operationID,
        "operation": operation.rawValue,
        "algorithm": config.algorithm
      ])
      await logger.info("Starting security operation: \(operation.description)", metadata: logMetadata)

      // Get the data to store
      guard
        let dataString = config.options["storeData"],
        let inputData = Data(base64Encoded: dataString)
      else {
        throw SecurityError.invalidInput("Invalid data format for secure storage")
      }

      // Convert Data to SecureBytes
      let secureBytes = SecureBytes(data: inputData)

      // Get the storage identifier
      guard let identifier = config.options["storageIdentifier"] else {
        throw SecurityError.invalidInput("Missing storage identifier")
      }

      // Store the data securely
      try await keyManager.storeKey(
        secureBytes,
        withIdentifier: identifier
      ).get()

      // Calculate duration
      let duration = Date().timeIntervalSince(startTime) * 1000

      // Log success
      let successMetadata = LogMetadata([
        "operationId": operationID,
        "operation": operation.rawValue,
        "algorithm": config.algorithm,
        "durationMs": String(format: "%.2f", duration)
      ])
      await logger.info(
        "Successfully completed security operation: \(operation.description)",
        metadata: successMetadata
      )

      // Return successful result
      guard let successMessage = stringToSecureBytes("Data stored securely with identifier: \(identifier)") else {
        throw SecurityError.systemError("Failed to create success message")
      }
      
      return SecurityResultDTO(
        status: .success,
        data: successMessage,
        metadata: successMetadata.asDictionary.mapValues { "\($0)" }
      )
    } catch {
      // Calculate duration
      let duration = Date().timeIntervalSince(startTime) * 1000

      // Create error handler
      let errorHandler = SecurityErrorHandler(logger: logger)

      // Map and log the error
      let securityError = await errorHandler.handleError(
        error,
        operation: operation,
        context: [
          "operationId": operationID,
          "durationMs": String(format: "%.2f", duration)
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
   Securely retrieves data with the specified configuration.

   - Parameter config: Configuration for the secure retrieval operation
   - Returns: Result containing retrieved data or error
   */
  public func secureRetrieve(config: SecurityConfigDTO) async -> SecurityResultDTO {
    let operationID = UUID().uuidString
    let startTime = Date()
    let operation = SecurityOperation.secureRetrieve

    activeOperations[operationID] = operation
    defer { activeOperations.removeValue(forKey: operationID) }

    do {
      // Log operation start
      let logMetadata = LogMetadata([
        "operationId": operationID,
        "operation": operation.rawValue,
        "algorithm": config.algorithm
      ])
      await logger.info("Starting security operation: \(operation.description)", metadata: logMetadata)

      // Get the storage identifier
      guard let identifier = config.options["storageIdentifier"] else {
        throw SecurityError.invalidInput("Missing storage identifier")
      }

      // Retrieve the data securely
      let retrievedBytes = try await keyManager.retrieveKey(withIdentifier: identifier).get()

      // Calculate duration
      let duration = Date().timeIntervalSince(startTime) * 1000

      // Log success
      let successMetadata = LogMetadata([
        "operationId": operationID,
        "operation": operation.rawValue,
        "algorithm": config.algorithm,
        "durationMs": String(format: "%.2f", duration)
      ])
      await logger.info(
        "Successfully completed security operation: \(operation.description)",
        metadata: successMetadata
      )

      // Return successful result
      return SecurityResultDTO(
        status: .success,
        data: retrievedBytes,
        metadata: successMetadata.asDictionary.mapValues { "\($0)" }
      )
    } catch {
      // Calculate duration
      let duration = Date().timeIntervalSince(startTime) * 1000

      // Create error handler
      let errorHandler = SecurityErrorHandler(logger: logger)

      // Map and log the error
      let securityError = await errorHandler.handleError(
        error,
        operation: operation,
        context: [
          "operationId": operationID,
          "durationMs": String(format: "%.2f", duration)
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
   Securely deletes data with the specified configuration.

   - Parameter config: Configuration for the secure deletion operation
   - Returns: Result containing success status or error
   */
  public func secureDelete(config: SecurityConfigDTO) async -> SecurityResultDTO {
    let operationID = UUID().uuidString
    let startTime = Date()
    let operation = SecurityOperation.secureDelete

    activeOperations[operationID] = operation
    defer { activeOperations.removeValue(forKey: operationID) }

    do {
      // Log operation start
      let logMetadata = LogMetadata([
        "operationId": operationID,
        "operation": operation.rawValue,
        "algorithm": config.algorithm
      ])
      await logger.info("Starting security operation: \(operation.description)", metadata: logMetadata)

      // Get the storage identifier
      guard let identifier = config.options["storageIdentifier"] else {
        throw SecurityError.invalidInput("Missing storage identifier")
      }

      // Delete the stored data
      try await keyManager.deleteKey(withIdentifier: identifier).get()

      // Calculate duration
      let duration = Date().timeIntervalSince(startTime) * 1000

      // Log success
      let successMetadata = LogMetadata([
        "operationId": operationID,
        "operation": operation.rawValue,
        "algorithm": config.algorithm,
        "durationMs": String(format: "%.2f", duration)
      ])
      await logger.info(
        "Successfully completed security operation: \(operation.description)",
        metadata: successMetadata
      )

      // Return successful result
      guard let confirmedMessage = stringToSecureBytes("Data with identifier \(identifier) securely deleted") else {
        throw SecurityError.systemError("Failed to create confirmation message")
      }
      
      return SecurityResultDTO(
        status: .success,
        data: confirmedMessage,
        metadata: successMetadata.asDictionary.mapValues { "\($0)" }
      )
    } catch {
      // Calculate duration
      let duration = Date().timeIntervalSince(startTime) * 1000

      // Create error handler
      let errorHandler = SecurityErrorHandler(logger: logger)

      // Map and log the error
      let securityError = await errorHandler.handleError(
        error,
        operation: operation,
        context: [
          "operationId": operationID,
          "durationMs": String(format: "%.2f", duration)
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
   Signs data with the specified configuration.

   - Parameter config: Configuration for the signing operation
   - Returns: Result containing signature or error
   */
  public func sign(config: SecurityConfigDTO) async -> SecurityResultDTO {
    let operationID = UUID().uuidString
    let startTime = Date()
    let operation = SecurityOperation.sign

    activeOperations[operationID] = operation
    defer { activeOperations.removeValue(forKey: operationID) }

    do {
      // Log operation start
      let logMetadata = LogMetadata([
        "operationId": operationID,
        "operation": operation.rawValue,
        "algorithm": config.algorithm
      ])
      await logger.info("Starting security operation: \(operation.description)", metadata: logMetadata)

      // Get the input data from the config
      guard
        let inputDataString = config.options["inputData"],
        let inputData = Data(base64Encoded: inputDataString)
      else {
        throw SecurityError.invalidInput("Invalid input data format")
      }

      // Convert Data to SecureBytes
      let secureInputBytes = SecureBytes(data: inputData)

      // Get the key identifier
      guard let keyIdentifier = config.options["keyIdentifier"] else {
        throw SecurityError.invalidInput("Missing key identifier")
      }

      // Get the key from identifier first
      let keyBytes = try await keyManager.retrieveKey(withIdentifier: keyIdentifier).get()

      // Generate a hash as the signature 
      let hashResult = await cryptoService.hash(data: secureInputBytes)
      
      // Handle the result
      let signature: SecureBytes
      switch hashResult {
      case .success(let data):
        signature = data
      case .failure(let error):
        throw SecurityError.operationFailed("Signing failed: \(error.localizedDescription)")
      }

      // Calculate duration
      let duration = Date().timeIntervalSince(startTime) * 1000

      // Log success
      let successMetadata = LogMetadata([
        "operationId": operationID,
        "operation": operation.rawValue,
        "algorithm": config.algorithm,
        "durationMs": String(format: "%.2f", duration)
      ])
      await logger.info(
        "Successfully completed security operation: \(operation.description)",
        metadata: successMetadata
      )

      // Return successful result
      return SecurityResultDTO(
        status: .success,
        data: signature,
        metadata: successMetadata.asDictionary.mapValues { "\($0)" }
      )
    } catch {
      // Calculate duration
      let duration = Date().timeIntervalSince(startTime) * 1000

      // Create error handler
      let errorHandler = SecurityErrorHandler(logger: logger)

      // Map and log the error
      let securityError = await errorHandler.handleError(
        error,
        operation: operation,
        context: [
          "operationId": operationID,
          "durationMs": String(format: "%.2f", duration)
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
   Verifies a signature with the specified configuration.

   - Parameter config: Configuration for the verification operation
   - Returns: Result containing verification status or error
   */
  public func verify(config: SecurityConfigDTO) async -> SecurityResultDTO {
    let operationID = UUID().uuidString
    let startTime = Date()
    let operation = SecurityOperation.verify

    activeOperations[operationID] = operation
    defer { activeOperations.removeValue(forKey: operationID) }

    do {
      // Log operation start
      let logMetadata = LogMetadata([
        "operationId": operationID,
        "operation": operation.rawValue,
        "algorithm": config.algorithm
      ])
      await logger.info("Starting security operation: \(operation.description)", metadata: logMetadata)

      // Get the input data from the config
      guard
        let inputDataString = config.options["inputData"],
        let inputData = Data(base64Encoded: inputDataString)
      else {
        throw SecurityError.invalidInput("Invalid input data format")
      }

      // Convert Data to SecureBytes
      let secureInputBytes = SecureBytes(data: inputData)

      // Get the signature
      guard
        let signatureBase64 = config.options["signature"],
        let signatureData = Data(base64Encoded: signatureBase64)
      else {
        throw SecurityError.invalidInput("Invalid signature format")
      }

      // Convert signature Data to SecureBytes
      let signatureBytes = SecureBytes(data: signatureData)

      // Perform hash verification
      // The key is not needed since we're just verifying a hash
      let hashResult = await cryptoService.verifyHash(data: secureInputBytes, expectedHash: signatureBytes)
      
      let isVerified: Bool
      switch hashResult {
      case .success(let verified):
        isVerified = verified
      case .failure(let error):
        throw SecurityError.operationFailed("Signature verification failed: \(error.localizedDescription)")
      }

      // Calculate duration
      let duration = Date().timeIntervalSince(startTime) * 1000

      // Log success
      let successMetadata = LogMetadata([
        "operationId": operationID,
        "operation": operation.rawValue,
        "algorithm": config.algorithm,
        "durationMs": String(format: "%.2f", duration)
      ])
      await logger.info(
        "Successfully completed security operation: \(operation.description)",
        metadata: successMetadata
      )

      // Return result based on verification status
      if isVerified {
        guard let message = stringToSecureBytes("Signature verified successfully") else {
          throw SecurityError.systemError("Failed to create verification message")
        }
        
        return SecurityResultDTO(
          status: .success,
          data: message,
          metadata: successMetadata.asDictionary.mapValues { "\($0)" }
        )
      } else {
        return SecurityResultDTO(
          status: .failure,
          error: SecurityError.invalidInput("Signature verification failed"),
          metadata: successMetadata.asDictionary.mapValues { "\($0)" }
        )
      }
    } catch {
      // Calculate duration
      let duration = Date().timeIntervalSince(startTime) * 1000

      // Create error handler
      let errorHandler = SecurityErrorHandler(logger: logger)

      // Map and log the error
      let securityError = await errorHandler.handleError(
        error,
        operation: operation,
        context: [
          "operationId": operationID,
          "durationMs": String(format: "%.2f", duration)
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
   Performs a security operation with proper error handling.

   - Parameters:
     - operation: The operation to perform
     - config: Configuration for the operation
   - Returns: Result of the operation
   */
  public nonisolated func performSecureOperation(
    operation: SecurityOperation,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO {
    // Generate an operation ID for tracking
    let operationID = UUID().uuidString
    
    // Create metadata for logging
    let logMetadata = LogMetadata([
      "operationId": operationID,
      "operation": operation.rawValue,
      "algorithm": config.algorithm
    ])
    
    // Using Task to bridge between nonisolated and actor-isolated contexts
    return await Task {
      await logger.info("Starting security operation: \(operation.description)", metadata: logMetadata)
      
      // Perform the operation based on its type
      switch operation {
      case .encrypt:
        return await encrypt(config: config)
      case .decrypt:
        return await decrypt(config: config)
      case .generateKey:
        return await generateKey(config: config)
      case .secureStore:
        return await secureStore(config: config)
      case .secureRetrieve:
        return await secureRetrieve(config: config)
      case .secureDelete:
        return await secureDelete(config: config)
      case .sign:
        return await sign(config: config)
      case .verify:
        return await verify(config: config)
      case .generateRandom(let length):
        var updatedConfig = config
        if updatedConfig.options["length"] == nil {
          var options = updatedConfig.options
          options["length"] = String(length)
          updatedConfig = SecurityConfigDTO(
            algorithm: updatedConfig.algorithm,
            keySize: updatedConfig.keySize,
            hashAlgorithm: updatedConfig.hashAlgorithm,
            options: options
          )
        }
        return await generateRandom(config: updatedConfig)
      }
    }.value
  }

  /**
   Creates a secure configuration with appropriate defaults.
   
   - Parameter options: Optional dictionary of configuration options
   - Returns: A properly configured SecurityConfigDTO
   */
  public nonisolated func createSecureConfig(options: [String: Any]?) -> SecurityConfigDTO {
    // Create a default configuration
    let algorithm = (options?["algorithm"] as? String) ?? "AES"
    let keySize = (options?["keySize"] as? Int) ?? 256
    let hashAlgorithm = options?["hashAlgorithm"] as? String
    
    // Convert options to string dictionary
    var stringOptions: [String: String] = [:]
    options?.forEach { key, value in
      if let stringValue = value as? String {
        stringOptions[key] = stringValue
      } else if let intValue = value as? Int {
        stringOptions[key] = String(intValue)
      } else if let boolValue = value as? Bool {
        stringOptions[key] = String(boolValue)
      }
    }
    
    return SecurityConfigDTO(
      algorithm: algorithm,
      keySize: keySize,
      hashAlgorithm: hashAlgorithm,
      options: stringOptions
    )
  }
  
  /**
   Converts SecureBytes to Data
   
   - Parameter secureBytes: The SecureBytes to convert
   - Returns: Data representation
   */
  private func secureToData(_ secureBytes: SecureBytes) -> Data {
    // Access the underlying data from SecureBytes
    return secureBytes.withUnsafeBytes { bytes in
      return Data(bytes)
    }
  }
  
  /**
   Generates a key and stores it using the key manager
   
   - Parameters:
     - identifier: The identifier for the key
     - algorithm: The algorithm to use
     - size: The key size
   */
  private func generateAndStoreKey(
    identifier: String,
    algorithm: String,
    size: Int
  ) async throws -> SecureBytes {
    // Generate a random key of the specified size
    let byteCount = size / 8
    var keyData = Data(count: byteCount)
    _ = keyData.withUnsafeMutableBytes { bytes in
      SecRandomCopyBytes(kSecRandomDefault, byteCount, bytes.baseAddress!)
    }
    
    // Create a SecureBytes instance
    let keyBytes = SecureBytes(data: keyData)
    
    // Store the key with the manager
    try await keyManager.storeKey(keyBytes, withIdentifier: identifier).get()
    
    return keyBytes
  }
  
  // Helper method to convert string to SecureBytes safely
  private func stringToSecureBytes(_ string: String) -> SecureBytes? {
    guard let data = string.data(using: .utf8) else {
      return nil
    }
    return SecureBytes(data: data)
  }
}
