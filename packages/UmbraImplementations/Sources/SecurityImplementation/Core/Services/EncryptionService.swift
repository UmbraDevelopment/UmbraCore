import CoreSecurityTypes
import DomainSecurityTypes
import Foundation

/// Helper function to create LogMetadataDTOCollection from dictionary
private func createMetadataCollection(_ dict: [String: String]) -> LogMetadataDTOCollection {
  var collection = LogMetadataDTOCollection()
  for (key, value) in dict {
    collection = collection.withPublic(key: key, value: value)
  }
  return collection
}

import LoggingInterfaces
import LoggingServices
import LoggingTypes
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

 ## Privacy-Aware Logging

 Uses SecureLoggerActor to ensure all sensitive data is properly tagged with privacy
 levels in accordance with the Alpha Dot Five architecture principles.
 */
final class EncryptionService: SecurityServiceBase {
  // MARK: - Properties

  /**
   The crypto service used for cryptographic operations
   */
  private let cryptoService: SecurityCoreInterfaces.CryptoServiceProtocol

  /**
   The logger instance for recording general operation details
   */
  let logger: LoggingInterfaces.LoggingProtocol

  /**
   The secure logger for privacy-aware logging of sensitive encryption operations

   This logger ensures proper privacy tagging for all security-sensitive information
   in accordance with Alpha Dot Five architecture principles.
   */
  private let secureLogger: SecureLoggerActor

  /**
   The secure storage for handling sensitive data
   */
  private let secureStorage: SecureStorage

  // MARK: - Initialisation

  /**
   Initialises a new encryption service with the specified dependencies

   - Parameters:
       - cryptoService: Service for cryptographic operations
       - logger: Logger for general operation details
       - secureLogger: Secure logger for privacy-aware logging (optional)
   */
  init(
    cryptoService: SecurityCoreInterfaces.CryptoServiceProtocol,
    logger: LoggingInterfaces.LoggingProtocol,
    secureLogger: SecureLoggerActor?=nil
  ) {
    self.cryptoService=cryptoService
    self.logger=logger
    self.secureLogger=secureLogger ?? SecureLoggerActor(
      subsystem: "com.umbra.security",
      category: "EncryptionService",
      includeTimestamps: true
    )
    secureStorage=SecureStorage()
  }

  /**
   Initialises the service with just a logger

   This initialiser is required to conform to SecurityServiceBase protocol,
   but is not intended to be used directly.

   - Parameter logger: The logging service to use
   */
  init(logger _: LoggingInterfaces.LoggingProtocol) {
    fatalError(
      "This initialiser is not supported. Use init(cryptoService:logger:secureLogger:) instead."
    )
  }

  // MARK: - Public Methods

  /**
   Encrypts data with the specified configuration

   - Parameter config: Configuration for the encryption operation
   - Returns: Result containing encrypted data or error information
   */
  func encrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let operationID=UUID().uuidString
    let startTime=Date()
    let operation=SecurityOperation.encrypt

    // Create metadata for logging
    let logMetadata=createOperationMetadata(
      operationID: operationID,
      operation: operation,
      config: config
    )

    await logger.info("Starting encryption operation", metadata: logMetadata, source: "SecurityImplementation", source: "SecurityImplementation")

    // Log with secure logger for enhanced privacy awareness
    await secureLogger.securityEvent(
      action: "Encryption",
      status: .success,
      subject: nil,
      resource: nil,
      additionalMetadata: [
        "operationId": PrivacyTaggedValue(value: PrivacyMetadataValue.string(operationID), privacyLevel: .public),
        "operation": PrivacyTaggedValue(value: PrivacyMetadataValue.string("start"), privacyLevel: .public),
        "operationType": PrivacyTaggedValue(value: PrivacyMetadataValue.string(config.operationType.rawValue), privacyLevel: .public),
        "algorithm": PrivacyTaggedValue(value: PrivacyMetadataValue.string(config.options["algorithm"] ?? "unknown"), privacyLevel: .public)
      ]
    )

    do {
      // Extract required parameters from configuration
      guard
        let inputDataString=config.options["data"],
        let inputData=Data(base64Encoded: inputDataString)
      else {
        let error=EncryptionServiceError
          .invalidInput("Missing or invalid input data for encryption")

        // Log failure with secure logger
        await secureLogger.securityEvent(
          action: "Encryption",
          status: .failed,
          subject: nil,
          resource: nil,
          additionalMetadata: [
            "operationId": PrivacyTaggedValue(value: PrivacyMetadataValue.string(operationID), privacyLevel: .public),
            "operation": PrivacyTaggedValue(value: PrivacyMetadataValue.string("error"), privacyLevel: .public),
            "errorType": PrivacyTaggedValue(value: PrivacyMetadataValue.string(String(describing: type(of: error))), privacyLevel: .public),
            "errorDescription": PrivacyTaggedValue(value: PrivacyMetadataValue.string(error.localizedDescription), privacyLevel: .public)
          ]
        )

        throw error
      }

      // Store the input data securely
      let inputID=UUID().uuidString
      try await secureStorage.store(data: inputData, withIdentifier: inputID)

      // Choose encryption key
      let keyIdentifier: String
      if let configKeyID=config.keyIdentifier {
        keyIdentifier=configKeyID
      } else {
        let error=EncryptionServiceError.invalidInput("Missing key identifier for encryption")

        // Log failure with secure logger
        await secureLogger.securityEvent(
          action: "Encryption",
          status: .failed,
          subject: nil,
          resource: nil,
          additionalMetadata: [
            "operationId": PrivacyTaggedValue(value: PrivacyMetadataValue.string(operationID), privacyLevel: .public),
            "operation": PrivacyTaggedValue(value: PrivacyMetadataValue.string("error"), privacyLevel: .public),
            "errorType": PrivacyTaggedValue(value: PrivacyMetadataValue.string(String(describing: type(of: error))), privacyLevel: .public),
            "errorDescription": PrivacyTaggedValue(value: PrivacyMetadataValue.string(error.localizedDescription), privacyLevel: .public)
          ]
        )

        throw error
      }

      // Perform the actual encryption
      let resultID=try await encryptData(
        dataID: inputID,
        keyID: keyIdentifier,
        operationID: operationID
      )

      // Retrieve the resulting encrypted data
      let encryptedData=try await secureStorage.retrieve(withIdentifier: resultID)

      // Calculate performance metrics
      let duration=Date().timeIntervalSince(startTime)

      // Create result object
      let result=SecurityResultDTO(
        status: .success,
        data: encryptedData,
        metadata: createPrivacyMetadata(["operation": operation.rawValue,
          "operationID": operationID,
          "durationMs": String(Int(duration * 1000))
        ])
      )

      // Log success with secure logger
      await secureLogger.securityEvent(
        action: "Encryption",
        status: .success,
        subject: nil,
        resource: nil,
        additionalMetadata: [
          "operationId": PrivacyTaggedValue(value: PrivacyMetadataValue.string(operationID), privacyLevel: .public),
          "operation": PrivacyTaggedValue(value: PrivacyMetadataValue.string("complete"), privacyLevel: .public),
          "durationMs": PrivacyTaggedValue(value: PrivacyMetadataValue.int(Int(duration * 1000)), privacyLevel: .public),
          "resultSize": PrivacyTaggedValue(value: PrivacyMetadataValue.int(encryptedData.count), privacyLevel: .public)
        ]
      )

      // Log success
      await logger.info(
        "Encryption completed successfully", metadata: createPrivacyMetadata(["operationID": operationID,
          "durationMs": String(Int(duration * 1000, source: "SecurityImplementation", source: "SecurityImplementation"))
        ])
      )

      // Clean up temporary data
      try await secureStorage.remove(withIdentifier: inputID)
      try await secureStorage.remove(withIdentifier: resultID)

      return result
    } catch {
      // Calculate duration for metrics
      let duration=Date().timeIntervalSince(startTime)

      // Log failure with secure logger
      await secureLogger.securityEvent(
        action: "Encryption",
        status: .failed,
        subject: nil,
        resource: nil,
        additionalMetadata: [
          "operationId": PrivacyTaggedValue(value: PrivacyMetadataValue.string(operationID), privacyLevel: .public),
          "operation": PrivacyTaggedValue(value: PrivacyMetadataValue.string("error"), privacyLevel: .public),
          "durationMs": PrivacyTaggedValue(value: PrivacyMetadataValue.int(Int(duration * 1000)), privacyLevel: .public),
          "errorType": PrivacyTaggedValue(value: PrivacyMetadataValue.string(String(describing: type(of: error))), privacyLevel: .public),
          "errorDescription": PrivacyTaggedValue(value: PrivacyMetadataValue.string(error.localizedDescription), privacyLevel: .public)
        ]
      )

      // Log error
      await logger.error(
        "Encryption failed: \(error.localizedDescription)",
        metadata: createPrivacyMetadata(["operationID": operationID,
          "durationMs": String(Int(duration * 1000)),
          "error": error.localizedDescription
        ])
      )

      // Create failure result
      let result=SecurityResultDTO(
        status: .failure,
        data: nil,
        metadata: createPrivacyMetadata(["operation": operation.rawValue,
          "operationID": operationID,
          "durationMs": String(Int(duration * 1000)),
          "error": error.localizedDescription
        ])
      )

      return result
    }
  }

  /**
   Decrypts data with the specified configuration

   - Parameter config: Configuration for the decryption operation
   - Returns: Result containing decrypted data or error information
   */
  func decrypt(config: SecurityConfigDTO) async throws -> SecurityResultDTO {
    let operationID=UUID().uuidString
    let startTime=Date()
    let operation=SecurityOperation.decrypt

    // Create metadata for logging
    let logMetadata=createOperationMetadata(
      operationID: operationID,
      operation: operation,
      config: config
    )

    await logger.info("Starting decryption operation", metadata: logMetadata, source: "SecurityImplementation", source: "SecurityImplementation")

    // Log with secure logger for enhanced privacy awareness
    await secureLogger.securityEvent(
      action: "Decryption",
      status: .success,
      subject: nil,
      resource: nil,
      additionalMetadata: [
        "operationId": PrivacyTaggedValue(value: PrivacyMetadataValue.string(operationID), privacyLevel: .public),
        "operation": PrivacyTaggedValue(value: PrivacyMetadataValue.string("start"), privacyLevel: .public),
        "operationType": PrivacyTaggedValue(value: PrivacyMetadataValue.string(config.operationType.rawValue), privacyLevel: .public),
        "algorithm": PrivacyTaggedValue(value: PrivacyMetadataValue.string(config.options["algorithm"] ?? "unknown"), privacyLevel: .public)
      ]
    )

    do {
      // Extract required parameters from configuration
      guard
        let inputDataString=config.options["data"],
        let inputData=Data(base64Encoded: inputDataString)
      else {
        let error=EncryptionServiceError
          .invalidInput("Missing or invalid input data for decryption")

        // Log failure with secure logger
        await secureLogger.securityEvent(
          action: "Decryption",
          status: .failed,
          subject: nil,
          resource: nil,
          additionalMetadata: [
            "operationId": PrivacyTaggedValue(value: PrivacyMetadataValue.string(operationID), privacyLevel: .public),
            "operation": PrivacyTaggedValue(value: PrivacyMetadataValue.string("error"), privacyLevel: .public),
            "errorType": PrivacyTaggedValue(value: PrivacyMetadataValue.string(String(describing: type(of: error))), privacyLevel: .public),
            "errorDescription": PrivacyTaggedValue(value: PrivacyMetadataValue.string(error.localizedDescription), privacyLevel: .public)
          ]
        )

        throw error
      }

      // Store the input data securely
      let inputID=UUID().uuidString
      try await secureStorage.store(data: inputData, withIdentifier: inputID)

      // Choose decryption key
      let keyIdentifier: String
      if let configKeyID=config.keyIdentifier {
        keyIdentifier=configKeyID
      } else {
        let error=EncryptionServiceError.invalidInput("Missing key identifier for decryption")

        // Log failure with secure logger
        await secureLogger.securityEvent(
          action: "Decryption",
          status: .failed,
          subject: nil,
          resource: nil,
          additionalMetadata: [
            "operationId": PrivacyTaggedValue(value: PrivacyMetadataValue.string(operationID), privacyLevel: .public),
            "operation": PrivacyTaggedValue(value: PrivacyMetadataValue.string("error"), privacyLevel: .public),
            "errorType": PrivacyTaggedValue(value: PrivacyMetadataValue.string(String(describing: type(of: error))), privacyLevel: .public),
            "errorDescription": PrivacyTaggedValue(value: PrivacyMetadataValue.string(error.localizedDescription), privacyLevel: .public)
          ]
        )

        throw error
      }

      // Perform the actual decryption
      let resultID=try await decryptData(
        dataID: inputID,
        keyID: keyIdentifier,
        operationID: operationID
      )

      // Retrieve the resulting decrypted data
      let decryptedData=try await secureStorage.retrieve(withIdentifier: resultID)

      // Calculate performance metrics
      let duration=Date().timeIntervalSince(startTime)

      // Create result object
      let result=SecurityResultDTO(
        status: .success,
        data: decryptedData,
        metadata: createPrivacyMetadata(["operation": operation.rawValue,
          "operationID": operationID,
          "durationMs": String(Int(duration * 1000))
        ])
      )

      // Log success with secure logger
      await secureLogger.securityEvent(
        action: "Decryption",
        status: .success,
        subject: nil,
        resource: nil,
        additionalMetadata: [
          "operationId": PrivacyTaggedValue(value: PrivacyMetadataValue.string(operationID), privacyLevel: .public),
          "operation": PrivacyTaggedValue(value: PrivacyMetadataValue.string("complete"), privacyLevel: .public),
          "durationMs": PrivacyTaggedValue(value: PrivacyMetadataValue.int(Int(duration * 1000)), privacyLevel: .public),
          "resultSize": PrivacyTaggedValue(value: PrivacyMetadataValue.int(decryptedData.count), privacyLevel: .public)
        ]
      )

      // Log success
      await logger.info(
        "Decryption completed successfully", metadata: createPrivacyMetadata(["operationID": operationID,
          "durationMs": String(Int(duration * 1000, source: "SecurityImplementation", source: "SecurityImplementation"))
        ])
      )

      // Clean up temporary data
      try await secureStorage.remove(withIdentifier: inputID)
      try await secureStorage.remove(withIdentifier: resultID)

      return result
    } catch {
      // Calculate duration for metrics
      let duration=Date().timeIntervalSince(startTime)

      // Log failure with secure logger
      await secureLogger.securityEvent(
        action: "Decryption",
        status: .failed,
        subject: nil,
        resource: nil,
        additionalMetadata: [
          "operationId": PrivacyTaggedValue(value: PrivacyMetadataValue.string(operationID), privacyLevel: .public),
          "operation": PrivacyTaggedValue(value: PrivacyMetadataValue.string("error"), privacyLevel: .public),
          "durationMs": PrivacyTaggedValue(value: PrivacyMetadataValue.int(Int(duration * 1000)), privacyLevel: .public),
          "errorType": PrivacyTaggedValue(value: PrivacyMetadataValue.string(String(describing: type(of: error))), privacyLevel: .public),
          "errorDescription": PrivacyTaggedValue(value: PrivacyMetadataValue.string(error.localizedDescription), privacyLevel: .public)
        ]
      )

      // Log error
      await logger.error(
        "Decryption failed: \(error.localizedDescription)",
        metadata: createPrivacyMetadata(["operationID": operationID,
          "durationMs": String(Int(duration * 1000)),
          "error": error.localizedDescription
        ])
      )

      // Create failure result
      let result=SecurityResultDTO(
        status: .failure,
        data: nil,
        metadata: createPrivacyMetadata(["operation": operation.rawValue,
          "operationID": operationID,
          "durationMs": String(Int(duration * 1000)),
          "error": error.localizedDescription
        ])
      )

      return result
    }
  }

  private func encryptData(
    dataID: String,
    keyID: String,
    operationID _: String
  ) async throws -> String {
    // Perform the encryption using the crypto service
    do {
      // Retrieve the data from secure storage
      let data=try await secureStorage.retrieve(withIdentifier: dataID)
      let key=try await secureStorage.retrieve(withIdentifier: keyID)

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

  private func decryptData(
    dataID: String,
    keyID: String,
    operationID _: String
  ) async throws -> String {
    // Perform the decryption using the crypto service
    do {
      // Retrieve the data from secure storage
      let data=try await secureStorage.retrieve(withIdentifier: dataID)
      let key=try await secureStorage.retrieve(withIdentifier: keyID)

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

  func remove(withIdentifier identifier: String) {
    storage.removeValue(forKey: identifier)
  }
}



  
  static func invalidVerificationMethod(reason: String) -> CoreSecurityError {
    return .general(code: "INVALID_VERIFICATION_METHOD", message: reason)
  }
  
  static func verificationFailed(reason: String) -> CoreSecurityError {
    return .general(code: "VERIFICATION_FAILED", message: reason)
  }
  
  static func notImplemented(reason: String) -> CoreSecurityError {
    return .general(code: "NOT_IMPLEMENTED", message: reason)
  }
}



