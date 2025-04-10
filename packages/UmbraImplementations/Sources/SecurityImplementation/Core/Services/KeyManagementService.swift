import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import LoggingTypes

/// Helper function to create LogMetadataDTOCollection from dictionary
private func createMetadataCollection(_ dict: [String: String]) -> LogMetadataDTOCollection {
  var collection=LogMetadataDTOCollection()
  for (key, value) in dict {
    collection=collection.withPublic(key: key, value: value)
  }
  return collection
}

import LoggingInterfaces
import SecurityCoreInterfaces
import Security

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
    let logMetadata=LogMetadataDTOCollection()
      .withPublic(key: "operationId", value: operationID)
      .withPublic(key: "operation", value: operation)
      .withPublic(key: "config", value: "\(config)")

    // Create a proper context with privacy-aware metadata
    let context=SecurityLogContext(
      operation: operation,
      component: "KeyManagementService",
      correlationID: operationID,
      source: "SecurityImplementation",
      metadata: logMetadata
    )

    await logger.info("Starting key generation operation", context: context)

    do {
      // Extract key parameters from configuration
      let keySizeString = config.options?.metadata?["keySize"] ?? "256"
      let keySize = Int(keySizeString) ?? 256 // Default to 256 bits if not specified or invalid
      let algorithm = config.options?.metadata?["algorithm"] ?? "AES" // Default to AES

      // Generate random key material
      // In a production implementation, this would use a secure random generator
      let keyMaterial: Data
      if keySize > 0 {
        // Create a buffer of the appropriate size
        var bytes = [UInt8](repeating: 0, count: keySize / 8)
        // Use system's secure random number generator
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard status == errSecSuccess else {
          throw NSError(domain: "SecurityImplementation", code: Int(status), 
                       userInfo: [NSLocalizedDescriptionKey: "Failed to generate secure random bytes"])
        }
        keyMaterial = Data(bytes)
      } else {
        // Default to 256 bits (32 bytes) of zeroes (for testing only, not secure)
        keyMaterial = Data(repeating: 0, count: 32)
      }

      // Store the key if an identifier is provided
      if let keyIdentifier = config.options?.metadata?["keyIdentifier"] {
        let storageResult = await cryptoService.secureStorage.storeData(
          keyMaterial,
          withIdentifier: keyIdentifier
        )
        if case let .failure(error) = storageResult {
          throw CoreSecurityTypes.SecurityError.keyStorageFailed(reason: error.localizedDescription)
        }
      }

      // Calculate duration for performance metrics
      let duration=Date().timeIntervalSince(startTime)

      // Return successful result with metrics
      let successMetadata = [
        "durationMs": String(format: "%.2f", duration * 1000),
        "algorithm": algorithm,
        "keySize": "\(keySize)",
        "operationID": operationID
      ]
      
      return SecurityResultDTO.success(
        resultData: Data(keyMaterial),
        executionTimeMs: duration * 1000,
        metadata: successMetadata
      )
    } catch {
      // Calculate duration before failure
      let duration=Date().timeIntervalSince(startTime)

      // Return error result with metrics
      let errorMetadata = [
        "durationMs": String(format: "%.2f", duration * 1000),
        "error": error.localizedDescription,
        "operationID": operationID
      ]
      
      return SecurityResultDTO.failure(
        errorDetails: error.localizedDescription,
        executionTimeMs: duration * 1000,
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
    let operationID=UUID().uuidString
    let startTime=Date()

    // Create metadata for logging with privacy annotations
    let logMetadata=LogMetadataDTOCollection()
      .withPublic(key: "operationId", value: operationID)
      .withPublic(key: "operation", value: "generateRandomData")
      .withPublic(key: "length", value: "\(length)")
      .withPublic(key: "timestamp", value: "\(Date())")

    // Create a proper context with privacy-aware metadata
    let context=SecurityLogContext(
      operation: "generateRandomData",
      component: "KeyManagementService",
      correlationID: operationID,
      source: "SecurityImplementation",
      metadata: logMetadata
    )

    await logger.info("Starting random data generation operation", context: context)

    do {
      // Validate parameters
      if length <= 0 {
        throw CoreSecurityTypes.SecurityError.invalidInputData
      }
      
      // Generate secure random bytes
      var randomBytes = [UInt8](repeating: 0, count: length)
      let status = SecRandomCopyBytes(kSecRandomDefault, length, &randomBytes)
      
      if status != errSecSuccess {
        throw CoreSecurityTypes.SecurityError.keyGenerationFailed(reason: "Failed to generate secure random bytes: \(status)")
      }
      
      let randomMaterial = Data(randomBytes)

      // Calculate duration for performance metrics
      let duration=Date().timeIntervalSince(startTime)

      // Return successful result with metrics
      let successMetadata = [
        "durationMs": String(format: "%.2f", duration * 1000),
        "length": "\(length)",
        "operationID": operationID
      ]
      
      return SecurityResultDTO.success(
        resultData: Data(randomMaterial),
        executionTimeMs: duration * 1000,
        metadata: successMetadata
      )
    } catch {
      // Calculate duration before failure
      let duration=Date().timeIntervalSince(startTime)

      // Return error result with metrics
      let errorMetadata = [
        "durationMs": String(format: "%.2f", duration * 1000),
        "error": error.localizedDescription,
        "operationID": operationID
      ]
      
      return SecurityResultDTO.failure(
        errorDetails: error.localizedDescription,
        executionTimeMs: duration * 1000,
        metadata: errorMetadata
      )
    }
  }
}

// Note: CoreSecurityError extension has been moved to SecurityProvider+Validation.swift
