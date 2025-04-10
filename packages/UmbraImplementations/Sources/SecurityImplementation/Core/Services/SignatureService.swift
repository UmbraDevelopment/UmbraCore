import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces

/// Helper function to create LogMetadataDTOCollection from dictionary
private func createMetadataCollection(_ dict: [String: String]) -> LogMetadataDTOCollection {
  var collection=LogMetadataDTOCollection()
  for (key, value) in dict {
    collection=collection.withPublic(key: key, value: value)
  }
  return collection
}

/**
 # Signature Service

 Handles digital signature operations for the security provider.
 This service encapsulates the logic specific to signing and verification,
 reducing complexity in the main SecurityProviderImpl.

 ## Responsibilities

 - Create digital signatures for data
 - Verify digital signatures
 - Track performance and log operations
 - Handle signature-specific errors
 */
final class SignatureService: SecurityServiceBase {
  // MARK: - Properties

  /**
   The crypto service used for cryptographic operations
   */
  private let cryptoService: CryptoServiceProtocol

  /**
   The key manager used for key storage and retrieval
   */
  private let keyManagementService: KeyManagementProtocol

  /**
   The logger instance for recording operation details
   */
  let logger: LoggingProtocol

  // MARK: - Initialisation

  /**
   Initialises the signature service with required dependencies

   - Parameters:
       - cryptoService: Service for performing cryptographic operations
       - keyManagementService: Service for key storage and retrieval
       - logger: Service for logging operations
   */
  init(
    cryptoService: CryptoServiceProtocol,
    keyManagementService: KeyManagementProtocol,
    logger: LoggingProtocol
  ) {
    self.cryptoService=cryptoService
    self.keyManagementService=keyManagementService
    self.logger=logger
  }

  /**
   Initialises the service with just a logger

   This initializer is required to conform to SecurityServiceBase protocol,
   but it's not intended for direct use.

   - Parameter logger: The logging service to use
   */
  override init(logger _: LoggingProtocol) {
    fatalError(
      "This initializer is not supported. Use init(cryptoService:keyManagementService:logger:) instead."
    )
  }

  // MARK: - Public Methods

  /**
   Signs data with the specified configuration

   - Parameter config: Configuration for the signing operation
   - Returns: Result containing the signature or error information
   */
  func sign(config: SecurityConfigDTO) async -> SecurityResultDTO {
    let operationID=UUID().uuidString
    let startTime=Date()
    let operation=SecurityOperation.sign

    // Create metadata for logging
    let logMetadataCollection=LogMetadataDTOCollection()
      .withPublic(key: "operationId", value: operationID)
      .withPublic(key: "operation", value: operation.rawValue)
      .withPublic(key: "algorithm", value: config.algorithm)

    await logger.info(
      "Starting signing operation",
      metadata: logMetadataCollection,
      source: "SecurityImplementation",
      source: "SecurityImplementation"
    )

    do {
      // Extract required parameters from configuration
      guard let inputData=SendableCryptoMaterial.fromBase64(config.options["data"] ?? "") else {
        throw SignatureError.invalidInput("Missing input data for signing")
      }

      // Handle different key acquisition strategies
      do {
        let signature: SendableCryptoMaterial

        // If keyID is provided, retrieve the key from key management
        if let keyID=config.options["keyId"] {
          // Retrieve the key from the key management service
          let keyResult=await keyManagementService.secureStorage
            .retrieveMaterial(withIdentifier: keyID)

          switch keyResult {
            case let .success(keyMaterial):
              // Use the retrieved key to sign the data
              signature=try await performSignature(
                data: inputData,
                key: keyMaterial,
                algorithm: config.algorithm
              )

            case let .failure(error):
              throw SignatureError
                .keyManagementError("Failed to retrieve key with ID: \(keyID), error: \(error)")
          }
        }
        // If direct key is provided, use it
        else if let key=SendableCryptoMaterial.fromBase64(config.options["key"] ?? "") {
          // Use encrypt as a substitute for signature generation
          signature=try await performSignature(
            data: inputData,
            key: key,
            algorithm: config.algorithm
          )
        }
        // Neither keyID nor key was provided
        else {
          throw SignatureError.invalidInput("Neither key nor keyId provided for signing")
        }

        // Calculate duration for performance metrics
        let duration=Date().timeIntervalSince(startTime)

        // Create success metadata for logging
        let successMetadataCollection=LogMetadataDTOCollection()
          .withPublic(key: "duration", value: String(format: "%.3f s", duration))
          .withPublic(key: "signatureSize", value: String(signature.count))

        await logger.info(
          "Signing operation completed successfully", metadata: successMetadataCollection,
          source: "SecurityImplementation", source: "SecurityImplementation"
        )

        // Return successful result with signature
        return SecurityResultDTO(
          status: .success,
          data: signature.toBase64(),
          metadata: createMetadataCollection([
            "durationMs": String(format: "%.2f", duration * 1000),
            "algorithm": config.algorithm,
            "signatureSize": "\(signature.count)"
          ])
        )
      } catch {
        // Calculate duration before failure
        let duration=Date().timeIntervalSince(startTime)

        // Create failure metadata for logging
        let errorMetadataCollection=LogMetadataDTOCollection()
          .withPrivate(key: "error", value: error.localizedDescription)
          .withPublic(key: "duration", value: String(format: "%.3f s", duration))

        await logger.error(
          "Signing operation failed: \(error.localizedDescription)",
          metadata: errorMetadataCollection,
          source: "SecurityImplementation"
        )

        // Return failure result
        return SecurityResultDTO(
          status: .failure,
          error: error,
          metadata: createMetadataCollection([
            "durationMs": String(format: "%.2f", duration * 1000),
            "errorMessage": error.localizedDescription
          ])
        )
      }
    } catch {
      // Calculate duration before failure
      let duration=Date().timeIntervalSince(startTime)

      // Create failure metadata for logging
      let errorMetadataCollection=LogMetadataDTOCollection()
        .withPrivate(key: "error", value: error.localizedDescription)
        .withPublic(key: "duration", value: String(format: "%.3f s", duration))

      await logger.error(
        "Signing operation failed: \(error.localizedDescription)",
        metadata: errorMetadataCollection,
        source: "SecurityImplementation"
      )

      // Return failure result
      return SecurityResultDTO(
        status: .failure,
        error: error,
        metadata: createMetadataCollection([
          "durationMs": String(format: "%.2f", duration * 1000),
          "errorMessage": error.localizedDescription
        ])
      )
    }
  }

  /**
   Verifies a signature with the specified configuration

   - Parameter config: Configuration for the verification operation
   - Returns: Result containing verification status or error information
   */
  func verify(config: SecurityConfigDTO) async -> SecurityResultDTO {
    let operationID=UUID().uuidString
    let startTime=Date()
    let operation=SecurityOperation.verify

    // Create metadata for logging
    let logMetadataCollection=LogMetadataDTOCollection()
      .withPublic(key: "operationId", value: operationID)
      .withPublic(key: "operation", value: operation.rawValue)
      .withPublic(key: "algorithm", value: config.algorithm)

    await logger.info(
      "Starting signature verification operation",
      metadata: logMetadataCollection,
      source: "SecurityImplementation",
      source: "SecurityImplementation"
    )

    do {
      // Extract required parameters from configuration
      guard let inputData=SendableCryptoMaterial.fromBase64(config.options["data"] ?? "") else {
        throw SignatureError.invalidInput("Missing input data for verification")
      }

      guard let signature=SendableCryptoMaterial.fromBase64(config.options["signature"] ?? "")
      else {
        throw SignatureError.invalidInput("Missing signature to verify")
      }

      // Check if key is provided directly in the options
      if let key=SendableCryptoMaterial.fromBase64(config.options["key"] ?? "") {
        // Try to verify the signature using the provided key
        let isValid=try await performVerification(
          data: inputData,
          signature: signature,
          key: key,
          algorithm: config.algorithm
        )

        // Calculate duration for performance metrics
        let duration=Date().timeIntervalSince(startTime)

        // Create result metadata
        let verificationMetadataCollection=LogMetadataDTOCollection()
          .withPublic(key: "duration", value: String(format: "%.3f s", duration))
          .withPublic(key: "isValid", value: String(isValid))

        if isValid {
          await logger.info(
            "Signature verification completed: Valid signature",
            metadata: verificationMetadataCollection,
            source: "SecurityImplementation", source: "SecurityImplementation"
          )
        } else {
          await logger.warning(
            "Signature verification completed: Invalid signature",
            metadata: verificationMetadataCollection,
            source: "SecurityImplementation", source: "SecurityImplementation"
          )
        }

        // Return verification result
        return SecurityResultDTO(
          status: .success,
          metadata: createMetadataCollection([
            "verified": "\(isValid)",
            "algorithm": config.algorithm
          ])
        )
      } else {
        // If key not provided directly, try to retrieve from key manager

        // Attempt to get key ID from config
        guard let keyID=config.options["keyId"] else {
          throw SignatureError.invalidInput("Neither key nor keyId provided for verification")
        }

        // Request key from key manager
        let keyResult=await keyManagementService.secureStorage
          .retrieveMaterial(withIdentifier: keyID)

        switch keyResult {
          case let .success(keyMaterial):
            // Try to verify the signature using the retrieved key
            let isValid=try await performVerification(
              data: inputData,
              signature: signature,
              key: keyMaterial,
              algorithm: config.algorithm
            )

            // Calculate duration for performance metrics
            let duration=Date().timeIntervalSince(startTime)

            // Create result metadata
            let verificationMetadataCollection=LogMetadataDTOCollection()
              .withPublic(key: "duration", value: String(format: "%.3f s", duration))
              .withPublic(key: "isValid", value: String(isValid))

            if isValid {
              await logger.info(
                "Signature verification completed: Valid signature",
                metadata: verificationMetadataCollection,
                source: "SecurityImplementation", source: "SecurityImplementation"
              )
            } else {
              await logger.warning(
                "Signature verification completed: Invalid signature",
                metadata: verificationMetadataCollection,
                source: "SecurityImplementation", source: "SecurityImplementation"
              )
            }

            // Return verification result
            return SecurityResultDTO(
              status: .success,
              metadata: createMetadataCollection([
                "verified": "\(isValid)",
                "algorithm": config.algorithm
              ])
            )

          case let .failure(error):
            throw SignatureError.keyManagementError("Failed to retrieve key, error: \(error)")
        }
      }
    } catch {
      // Calculate duration before failure
      let duration=Date().timeIntervalSince(startTime)

      // Create failure metadata for logging
      let errorMetadataCollection=LogMetadataDTOCollection()
        .withPrivate(key: "error", value: error.localizedDescription)
        .withPublic(key: "duration", value: String(format: "%.3f s", duration))

      await logger.error(
        "Signature verification operation failed: \(error.localizedDescription)",
        metadata: errorMetadataCollection,
        source: "SecurityImplementation"
      )

      // Return failure result
      return SecurityResultDTO(
        status: .failure,
        error: error,
        metadata: createMetadataCollection([
          "durationMs": String(format: "%.2f", duration * 1000),
          "errorMessage": error.localizedDescription
        ])
      )
    }
  }

  // MARK: - Helper Methods

  /**
   Performs signature generation using the appropriate algorithm.

   - Parameters:
     - data: Data to sign
     - key: Key to use for signing
     - algorithm: Signature algorithm to use
   - Returns: The generated signature
   */
  private func performSignature(
    data _: SendableCryptoMaterial,
    key _: SendableCryptoMaterial,
    algorithm _: String
  ) async throws -> SendableCryptoMaterial {
    // Implement actual signature generation using cryptoService
    // For now, this is a placeholder that would be replaced with actual implementation
    try secureRandomMaterial(byteCount: 64) // Example 512-bit signature
  }

  /**
   Performs signature verification using the appropriate algorithm.

   - Parameters:
     - data: Data to verify
     - signature: Signature to verify
     - key: Key to use for verification
     - algorithm: Signature algorithm to use
   - Returns: Whether the signature is valid
   */
  private func performVerification(
    data _: SendableCryptoMaterial,
    signature _: SendableCryptoMaterial,
    key _: SendableCryptoMaterial,
    algorithm _: String
  ) async throws -> Bool {
    // Implement actual signature verification using cryptoService
    // For now, this is a placeholder that would be replaced with actual implementation
    true // Example successful verification
  }

  // MARK: - Migration Helpers

  private func secureRandomMaterial(byteCount _: Int) throws -> SendableCryptoMaterial {
    // Implement secure random material generation
    // For now, this is a placeholder that would be replaced with actual implementation
    SendableCryptoMaterial(base64Encoded: "random-material")
  }
}

// Define the SignatureError enum
enum SignatureError: Error {
  case invalidInput(String)
  case keyManagementError(String)
  case cryptoError(String)
}
