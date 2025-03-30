import Foundation
import LoggingInterfaces
import SecurityCoreInterfaces
import SecurityCoreTypes
import SecurityTypes

/**
 # Encryption Service

 Handles encryption and decryption operations for the security provider.
 This service encapsulates the logic specific to data encryption and decryption,
 reducing complexity in the main SecurityProviderImpl.

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
        let inputData=SecureBytes(base64Encoded: inputDataString)
      else {
        throw EncryptionServiceError.invalidInput("Missing or invalid input data for encryption")
      }

      guard
        let keyString=config.options["key"],
        let key=SecureBytes(base64Encoded: keyString)
      else {
        throw EncryptionServiceError.invalidInput("Missing or invalid encryption key")
      }

      // Generate IV if not provided
      let iv: SecureBytes
      if
        let ivString=config.options["iv"],
        let providedIV=SecureBytes(base64Encoded: ivString)
      {
        iv=providedIV
      } else {
        // Generate a random IV for this encryption
        let ivLength=16 // AES block size
        let ivData=Data((0..<ivLength).map { _ in UInt8.random(in: 0...255) })
        iv=SecureBytes(data: ivData)
      }

      // Perform the encryption using the crypto service
      let encryptedData=try await performEncryption(data: inputData, key: key, iv: iv)

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
      return SecurityResultDTO(
        status: .success,
        data: encryptedData,
        metadata: [
          "durationMs": String(format: "%.2f", duration),
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
      return SecurityResultDTO(
        status: .failure,
        error: error,
        metadata: [
          "durationMs": String(format: "%.2f", duration),
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
        let inputData=SecureBytes(base64Encoded: inputDataString)
      else {
        throw EncryptionServiceError.invalidInput("Missing or invalid input data for decryption")
      }

      guard
        let keyString=config.options["key"],
        let key=SecureBytes(base64Encoded: keyString)
      else {
        throw EncryptionServiceError.invalidInput("Missing or invalid decryption key")
      }

      guard
        let ivString=config.options["iv"],
        let iv=SecureBytes(base64Encoded: ivString)
      else {
        throw EncryptionServiceError.invalidInput("Missing initialization vector (IV)")
      }

      // Perform the decryption
      let decryptedData=try await performDecryption(data: inputData, key: key, iv: iv)

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
      return SecurityResultDTO(
        status: .success,
        data: decryptedData,
        metadata: [
          "durationMs": String(format: "%.2f", duration),
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
      return SecurityResultDTO(
        status: .failure,
        error: error,
        metadata: [
          "durationMs": String(format: "%.2f", duration),
          "errorMessage": error.localizedDescription
        ]
      )
    }
  }

  private func performEncryption(
    data: SecureBytes,
    key: SecureBytes,
    iv _: SecureBytes
  ) async throws -> SecureBytes {
    // Perform the encryption using the crypto service
    do {
      // Convert SecureBytes to Data if necessary based on the crypto service implementation
      if let dataMethod=cryptoService as? HasDataEncryption {
        let result=try await dataMethod.encrypt(
          data: data.extractUnderlyingData(),
          key: key.extractUnderlyingData()
        )
        return SecureBytes(data: result)
      }

      // Try the standard protocol method signature which returns a Result type
      let encryptResult=await cryptoService.encrypt(data: data, using: key)

      // Handle the Result type
      switch encryptResult {
        case let .success(encryptedData):
          return encryptedData
        case let .failure(error):
          throw EncryptionServiceError.encryptionFailed("Encryption failed: \(error)")
      }
    } catch {
      throw EncryptionServiceError.encryptionFailed("Encryption failed: \(error)")
    }
  }

  private func performDecryption(
    data: SecureBytes,
    key: SecureBytes,
    iv _: SecureBytes
  ) async throws -> SecureBytes {
    // Perform the decryption using the crypto service
    do {
      // Convert SecureBytes to Data if necessary based on the crypto service implementation
      if let dataMethod=cryptoService as? HasDataEncryption {
        let result=try await dataMethod.decrypt(
          data: data.extractUnderlyingData(),
          key: key.extractUnderlyingData()
        )
        return SecureBytes(data: result)
      }

      // Try the standard protocol method signature which returns a Result type
      let decryptResult=await cryptoService.decrypt(data: data, using: key)

      // Handle the Result type
      switch decryptResult {
        case let .success(decryptedData):
          return decryptedData
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

// Extension to convert SecureBytes to Data
extension SecureBytes {
  fileprivate func extractUnderlyingData() -> Data {
    // Implementation dependent on the actual SecureBytes type
    // This is just a placeholder - actual implementation will depend on SecureBytes internals
    data() // Directly return the data as it's not optional
  }
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
