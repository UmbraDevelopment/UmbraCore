import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import SecurityCoreInterfaces

/**
 # Encryption Service

 Handles encryption and decryption operations for the security provider.
 This service encapsulates the logic specific to data encryption and decryption,
 reducing complexity in the main CoreSecurityProviderService.

 ## Responsibilities

 - Perform encryption operations
 - Perform decryption operations
 - Track performance and log operations
 - Handle encryption-specific errors
 */
final class EncryptionService: SecurityServiceBase {
  // MARK: - Properties

  /**
   The crypto service used for cryptographic operations
   */
  private let cryptoService: SecurityCoreInterfaces.CryptoServiceProtocol

  /**
   The logger instance for recording operation details
   */
  let logger: LoggingInterfaces.LoggingProtocol

  /**
   The secure storage for handling sensitive data
   */
  private let secureStorage: SecureStorage

  // MARK: - Initialisation

  /**
   Initialises a new encryption service with the specified dependencies

   - Parameters:
       - cryptoService: Service for cryptographic operations
       - logger: Logger for operation details
   */
  init(
    cryptoService: SecurityCoreInterfaces.CryptoServiceProtocol,
    logger: LoggingInterfaces.LoggingProtocol
  ) {
    self.cryptoService=cryptoService
    self.logger=logger
    secureStorage=SecureStorage()
  }

  /**
   Initialises the service with just a logger

   This initialiser is required to conform to SecurityServiceBase protocol,
   but is not intended to be used directly.

   - Parameter logger: The logging service to use
   */
  init(logger _: LoggingInterfaces.LoggingProtocol) {
    fatalError("This initialiser is not supported. Use init(cryptoService:logger:) instead.")
  }

  // MARK: - Public Methods

  /**
   Encrypts data with the specified configuration

   - Parameter config: Configuration for the encryption operation
   - Returns: Result containing encrypted data or error information
   */
  func encrypt(config: SecurityConfigDTO) async -> SecurityResultDTO {
    let operationID=UUID().uuidString
    let startTime=Date()
    let operation=SecurityOperation.encrypt

    // Create metadata for logging
    let logMetadata=createOperationMetadata(
      operationID: operationID,
      operation: operation,
      config: config
    )

    await logger.info("Starting encryption operation", metadata: logMetadata)

    do {
      // Extract required parameters from configuration
      guard
        let inputDataString=config.options["data"],
        let inputData=Data(base64Encoded: inputDataString)
      else {
        throw EncryptionServiceError.invalidInput("Missing or invalid input data for encryption")
      }

      // Store the input data securely
      let inputID=UUID().uuidString
      try await secureStorage.store(data: inputData, withIdentifier: inputID)

      guard
        let keyString=config.options["key"],
        let keyData=Data(base64Encoded: keyString)
      else {
        throw EncryptionServiceError.invalidInput("Missing or invalid encryption key")
      }

      // Store the key securely
      let keyID=UUID().uuidString
      try await secureStorage.store(data: keyData, withIdentifier: keyID)

      // Generate IV if not provided
      let ivID=UUID().uuidString
      if
        let ivString=config.options["iv"],
        let ivData=Data(base64Encoded: ivString)
      {
        try await secureStorage.store(data: ivData, withIdentifier: ivID)
      } else {
        // Generate a random IV for this encryption
        let ivLength=16 // AES block size
        let ivData=Data((0..<ivLength).map { _ in UInt8.random(in: 0...255) })
        try await secureStorage.store(data: ivData, withIdentifier: ivID)
      }

      // Perform the encryption using the crypto service
      let encryptedDataID=try await performEncryption(dataID: inputID, keyID: keyID, ivID: ivID)

      // Retrieve the encrypted data
      let encryptedData=try await secureStorage.retrieve(withIdentifier: encryptedDataID)

      // Clean up temporary secure storage
      await secureStorage.delete(withIdentifier: inputID)
      await secureStorage.delete(withIdentifier: keyID)
      await secureStorage.delete(withIdentifier: ivID)
      await secureStorage.delete(withIdentifier: encryptedDataID)

      // Calculate duration for performance metrics
      let duration=Date().timeIntervalSince(startTime) * 1000

      // Create success metadata for logging
      let successMetadata: LoggingInterfaces.LogMetadata=[
        "operationId": operationID,
        "operation": operation.rawValue,
        "durationMs": String(format: "%.2f", duration)
      ]

      await logger.info(
        "Encryption operation completed successfully",
        metadata: successMetadata
      )

      // Return successful result with encrypted data
      return SecurityResultDTO.success(
        resultData: encryptedData,
        executionTimeMs: duration,
        metadata: [
          "algorithm": config.algorithm,
          "mode": config.options["mode"] ?? "unknown"
        ]
      )
    } catch {
      // Calculate duration before failure
      let duration=Date().timeIntervalSince(startTime) * 1000

      // Create failure metadata for logging
      let errorMetadata: LoggingInterfaces.LogMetadata=[
        "operationId": operationID,
        "operation": operation.rawValue,
        "durationMs": String(format: "%.2f", duration),
        "errorType": "\(type(of: error))"
      ]

      await logger.error(
        "Encryption operation failed: \(error.localizedDescription)",
        metadata: errorMetadata
      )

      // Return failure result
      return SecurityResultDTO.failure(
        errorDetails: error.localizedDescription,
        executionTimeMs: duration,
        metadata: [
          "errorMessage": error.localizedDescription
        ]
      )
    }
  }

  /**
   Decrypts data with the specified configuration

   - Parameter config: Configuration for the decryption operation
   - Returns: Result containing decrypted data or error information
   */
  func decrypt(config: SecurityConfigDTO) async -> SecurityResultDTO {
    let operationID=UUID().uuidString
    let startTime=Date()
    let operation=SecurityOperation.decrypt

    // Create metadata for logging
    let logMetadata=createOperationMetadata(
      operationID: operationID,
      operation: operation,
      config: config
    )

    await logger.info("Starting decryption operation", metadata: logMetadata)

    do {
      // Extract required parameters from configuration
      guard
        let inputDataString=config.options["data"],
        let inputData=Data(base64Encoded: inputDataString)
      else {
        throw EncryptionServiceError.invalidInput("Missing or invalid input data for decryption")
      }

      // Store the input data securely
      let inputID=UUID().uuidString
      try await secureStorage.store(data: inputData, withIdentifier: inputID)

      guard
        let keyString=config.options["key"],
        let keyData=Data(base64Encoded: keyString)
      else {
        throw EncryptionServiceError.invalidInput("Missing or invalid decryption key")
      }

      // Store the key securely
      let keyID=UUID().uuidString
      try await secureStorage.store(data: keyData, withIdentifier: keyID)

      guard
        let ivString=config.options["iv"],
        let ivData=Data(base64Encoded: ivString)
      else {
        throw EncryptionServiceError.invalidInput("Missing initialization vector (IV)")
      }

      // Store the IV securely
      let ivID=UUID().uuidString
      try await secureStorage.store(data: ivData, withIdentifier: ivID)

      // Perform the decryption
      let decryptedDataID=try await performDecryption(dataID: inputID, keyID: keyID, ivID: ivID)

      // Retrieve the decrypted data
      let decryptedData=try await secureStorage.retrieve(withIdentifier: decryptedDataID)

      // Clean up temporary secure storage
      await secureStorage.delete(withIdentifier: inputID)
      await secureStorage.delete(withIdentifier: keyID)
      await secureStorage.delete(withIdentifier: ivID)
      await secureStorage.delete(withIdentifier: decryptedDataID)

      // Calculate duration for performance metrics
      let duration=Date().timeIntervalSince(startTime) * 1000

      // Create success metadata for logging
      let successMetadata: LoggingInterfaces.LogMetadata=[
        "operationId": operationID,
        "operation": operation.rawValue,
        "durationMs": String(format: "%.2f", duration)
      ]

      await logger.info(
        "Decryption operation completed successfully",
        metadata: successMetadata
      )

      // Return successful result with decrypted data
      return SecurityResultDTO.success(
        resultData: decryptedData,
        executionTimeMs: duration,
        metadata: [
          "algorithm": config.algorithm,
          "mode": config.options["mode"] ?? "unknown"
        ]
      )
    } catch {
      // Calculate duration before failure
      let duration=Date().timeIntervalSince(startTime) * 1000

      // Create failure metadata for logging
      let errorMetadata: LoggingInterfaces.LogMetadata=[
        "operationId": operationID,
        "operation": operation.rawValue,
        "durationMs": String(format: "%.2f", duration),
        "errorType": "\(type(of: error))"
      ]

      await logger.error(
        "Decryption operation failed: \(error.localizedDescription)",
        metadata: errorMetadata
      )

      // Return failure result
      return SecurityResultDTO.failure(
        errorDetails: error.localizedDescription,
        executionTimeMs: duration,
        metadata: [
          "errorMessage": error.localizedDescription
        ]
      )
    }
  }

  private func performEncryption(
    dataID: String,
    keyID: String,
    ivID: String
  ) async throws -> String {
    // Perform the encryption using the crypto service
    do {
      // Retrieve the data from secure storage
      let data=try await secureStorage.retrieve(withIdentifier: dataID)
      let key=try await secureStorage.retrieve(withIdentifier: keyID)
      let iv=try await secureStorage.retrieve(withIdentifier: ivID)

      // Convert to arrays of UInt8 if needed by the crypto service
      let dataArray=[UInt8](data)
      let keyArray=[UInt8](key)

      // If the crypto service uses Data-based methods
      if let dataMethod=cryptoService as? HasDataEncryption {
        let result=try await dataMethod.encrypt(
          data: data,
          key: key
        )

        // Store the result in secure storage
        let resultID=UUID().uuidString
        try await secureStorage.store(data: result, withIdentifier: resultID)
        return resultID
      }

      // Try the standard protocol method signature which returns a Result type
      let encryptResult=await cryptoService.encrypt(data: dataArray, using: keyArray)

      // Handle the Result type
      switch encryptResult {
        case let .success(encryptedData):
          // Convert back to Data and store in secure storage
          let resultData=Data(encryptedData)
          let resultID=UUID().uuidString
          try await secureStorage.store(data: resultData, withIdentifier: resultID)
          return resultID
        case let .failure(error):
          throw EncryptionServiceError.encryptionFailed("Encryption failed: \(error)")
      }
    } catch {
      throw EncryptionServiceError.encryptionFailed("Encryption failed: \(error)")
    }
  }

  private func performDecryption(
    dataID: String,
    keyID: String,
    ivID: String
  ) async throws -> String {
    // Perform the decryption using the crypto service
    do {
      // Retrieve the data from secure storage
      let data=try await secureStorage.retrieve(withIdentifier: dataID)
      let key=try await secureStorage.retrieve(withIdentifier: keyID)
      let iv=try await secureStorage.retrieve(withIdentifier: ivID)

      // Convert to arrays of UInt8 if needed by the crypto service
      let dataArray=[UInt8](data)
      let keyArray=[UInt8](key)

      // If the crypto service uses Data-based methods
      if let dataMethod=cryptoService as? HasDataEncryption {
        let result=try await dataMethod.decrypt(
          data: data,
          key: key
        )

        // Store the result in secure storage
        let resultID=UUID().uuidString
        try await secureStorage.store(data: result, withIdentifier: resultID)
        return resultID
      }

      // Try the standard protocol method signature which returns a Result type
      let decryptResult=await cryptoService.decrypt(data: dataArray, using: keyArray)

      // Handle the Result type
      switch decryptResult {
        case let .success(decryptedData):
          // Convert back to Data and store in secure storage
          let resultData=Data(decryptedData)
          let resultID=UUID().uuidString
          try await secureStorage.store(data: resultData, withIdentifier: resultID)
          return resultID
        case let .failure(error):
          throw EncryptionServiceError.decryptionFailed("Decryption failed: \(error)")
      }
    } catch {
      throw EncryptionServiceError.decryptionFailed("Decryption failed: \(error)")
    }
  }
}

// Protocol to check if the crypto service uses Data-based methods
private protocol HasDataEncryption {
  func encrypt(data: Data, key: Data) async throws -> Data
  func decrypt(data: Data, key: Data) async throws -> Data
}

/**
 Security-specific errors for encryption operations
 */
enum EncryptionServiceError: Error {
  case invalidInput(String)
  case operationFailed(String)
  case encryptionFailed(String)
  case decryptionFailed(String)
  case algorithmNotSupported(String)
  case cryptoError(String)
}

/**
 A secure storage actor for handling sensitive data in memory.
 This replaces the deprecated SecureBytes type with an actor-based approach
 for better memory safety and concurrency control.
 */
actor SecureStorage {
  private var storage: [String: Data]=[:]

  func store(data: Data, withIdentifier identifier: String) throws {
    storage[identifier]=data
  }

  func retrieve(withIdentifier identifier: String) throws -> Data {
    guard let data=storage[identifier] else {
      throw SecurityProtocolError.keyNotFound
    }
    return data
  }

  func delete(withIdentifier identifier: String) {
    storage.removeValue(forKey: identifier)
  }
}
