import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import LoggingTypes

/// Helper function to create LogMetadataDTOCollection from dictionary
private func createMetadataCollection(_ dict: [String: String]) -> LogMetadataDTOCollection {
  var collection = LogMetadataDTOCollection()
  for (key, value) in dict {
    collection = collection.withPublic(key: key, value: value)
  }
  return collection
}

import LoggingInterfaces
import SecurityCoreInterfaces

/**
 # Key Management Service

 Handles cryptographic key operations for the security provider.
 This service encapsulates the logic specific to key generation, storage,
 and management, reducing complexity in the main SecurityProviderImpl.

 ## Responsibilities

 - Generate cryptographic keys
 - Manage key lifecycle
 - Track performance and log operations
 - Handle key-specific errors
 */
final class KeyManagementService: SecurityServiceBase {
  // MARK: - Properties

  /**
   The crypto service used for cryptographic operations
   */
  private let cryptoService: SecurityCoreInterfaces.CryptoServiceProtocol

  /**
   The key manager used for key storage and retrieval
   */
  private let keyManager: KeyManagementProtocol

  /**
   The logger for recording key management operations
   */
  let logger: LoggingInterfaces.LoggingProtocol

  // MARK: - Initialisation

  /**
   Initialises the key management service with required dependencies

   - Parameters:
       - cryptoService: Service for performing cryptographic operations
       - keyManager: Service for key storage and retrieval
       - logger: The logger for operation details
   */
  init(
    cryptoService: SecurityCoreInterfaces.CryptoServiceProtocol,
    keyManager: KeyManagementProtocol,
    logger: LoggingInterfaces.LoggingProtocol
  ) {
    self.cryptoService=cryptoService
    self.keyManager=keyManager
    self.logger=logger
  }

  /**
   Initialises the service with just a logger

   This initialiser is required to conform to SecurityServiceBase protocol,
   but is not intended to be used directly.

   - Parameter logger: The logging service to use
   */
  init(logger _: LoggingInterfaces.LoggingProtocol) {
    fatalError(
      "This initialiser is not supported. Use init(cryptoService:keyManager:logger:) instead."
    )
  }

  // MARK: - Public Methods

  /**
   Generates a new cryptographic key with the specified configuration

   - Parameter config: Configuration for the key generation operation
   - Returns: Result containing the generated key or error information
   */
  func generateKey(config: SecurityConfigDTO) async -> SecurityResultDTO {
    let operationID=UUID().uuidString
    let startTime=Date()
    let operation="generateKey"

    // Create metadata for logging with privacy annotations
    let logMetadata = LogMetadataDTOCollection()
      .withPublic(key: "operationId", value: operationID)
      .withPublic(key: "operation", value: operation)
      .withPublic(key: "config", value: "\(config)")

    // Create a proper context with privacy-aware metadata
    let context = SecurityLogContext(
      operation: operation,
      source: "SecurityImplementation",
      metadata: logMetadata
    )

    await logger.info("Starting key generation operation", context: context)

    do {
      // Extract key parameters from configuration
      let keySize=config.keySize > 0 ? config.keySize : 256 // Default to 256 bits if not specified
      let algorithm=config.algorithm.isEmpty ? "AES" : config.algorithm // Default to AES

      // Use SendableCryptoMaterial instead of SecureBytes
      // In a production implementation, this would use a secure random generator
      let keyMaterial: SendableCryptoMaterial=if keySize > 0 {
        try secureRandomMaterial(byteCount: keySize / 8)
      } else {
        SendableCryptoMaterial.zeros(count: 32) // Default to 256 bits (32 bytes)
      }

      // Store the key if an identifier is provided
      if let keyIdentifier=config.options["keyIdentifier"] {
        let storageResult=await keyManager.secureStorage.storeMaterial(
          keyMaterial,
          withIdentifier: keyIdentifier
        )
        if case let .failure(error)=storageResult {
          throw SecurityError.keyStorage(error.description)
        }
      }

      // Calculate duration for performance metrics
      let duration=Date().timeIntervalSince(startTime) * 1000

      // Create success metadata for logging
      let successMetadata=createMetadataCollection([
        "durationMs": String(format: "%.2f", duration),
        "keySize": "\(keySize)",
        "algorithm": algorithm
      ])

      // Create a proper context with privacy-aware metadata
      let successContext = SecurityLogContext(
        operation: operation,
        source: "KeyManagementService.generateKey",
        metadata: successMetadata
      )

      await logger.info(
        "Key generation completed successfully",
        context: successContext
      )

      // Return successful result with the generated key metadata
      return SecurityResultDTO(
        status: .success,
        data: keyMaterial,
        metadata: successMetadata
      )
    } catch {
      // Calculate duration before failure
      let duration=Date().timeIntervalSince(startTime) * 1000

      // Create failure metadata for logging
      let errorMetadata=createMetadataCollection([
        "durationMs": String(format: "%.2f", duration),
        "errorMessage": error.localizedDescription
      ])

      // Create a proper context with privacy-aware metadata
      let errorContext = SecurityLogContext(
        operation: operation,
        source: "KeyManagementService.generateKey",
        metadata: errorMetadata
      )

      await logger.error(
        "Key generation failed: \(error.localizedDescription)",
        context: errorContext
      )

      // Return failure result
      return SecurityResultDTO(
        status: .failure,
        error: error,
        metadata: errorMetadata
      )
    }
  }

  /**
   Generates random data with the specified length

   - Parameters:
       - length: Length of random data to generate in bytes
       - config: Additional configuration parameters
   - Returns: Result containing the generated random data or error information
   */
  func generateRandomData(length: Int, config _: SecurityConfigDTO) async -> SecurityResultDTO {
    let operationID = UUID().uuidString
    let startTime = Date()

    // Create metadata for logging with privacy annotations
    let logMetadata = LogMetadataDTOCollection()
      .withPublic(key: "operationId", value: operationID)
      .withPublic(key: "operation", value: "generateRandomData")
      .withPublic(key: "length", value: "\(length)")
      .withPublic(key: "timestamp", value: "\(Date())")

    // Create a proper context with privacy-aware metadata
    let context = SecurityLogContext(
      operation: "generateRandomData",
      source: "SecurityImplementation",
      metadata: logMetadata
    )

    await logger.info("Starting random data generation operation", context: context)

    do {
      // Validate parameters
      if length <= 0 {
        throw SecurityError.invalidInput("Invalid length for random data generation: \(length)")
      }

      // Use SendableCryptoMaterial instead of SecureBytes
      // In a production implementation, this would use a secure random generator
      let randomMaterial=try secureRandomMaterial(byteCount: length)

      // Calculate duration for performance metrics
      let duration=Date().timeIntervalSince(startTime) * 1000

      // Create success metadata for logging
      let successMetadata=createMetadataCollection([
        "durationMs": String(format: "%.2f", duration),
        "length": "\(length)"
      ])

      // Create a proper context with privacy-aware metadata
      let successContext = SecurityLogContext(
        operation: "generateRandomData",
        source: "KeyManagementService.generateRandomData",
        metadata: successMetadata
      )

      await logger.info(
        "Random data generation completed successfully",
        context: successContext
      )

      // Return successful result with the generated random data
      return SecurityResultDTO(
        status: .success,
        data: randomMaterial,
        metadata: successMetadata
      )
    } catch {
      // Calculate duration before failure
      let duration=Date().timeIntervalSince(startTime) * 1000

      // Create failure metadata for logging
      let errorMetadata=createMetadataCollection([
        "durationMs": String(format: "%.2f", duration),
        "errorMessage": error.localizedDescription
      ])

      // Create a proper context with privacy-aware metadata
      let errorContext = SecurityLogContext(
        operation: "generateRandomData",
        source: "KeyManagementService.generateRandomData",
        metadata: errorMetadata
      )

      await logger.error(
        "Random data generation failed: \(error.localizedDescription)",
        context: errorContext
      )

      // Return failure result
      return SecurityResultDTO(
        status: .failure,
        error: error,
        metadata: errorMetadata
      )
    }
  }
}

extension CoreSecurityError {
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
