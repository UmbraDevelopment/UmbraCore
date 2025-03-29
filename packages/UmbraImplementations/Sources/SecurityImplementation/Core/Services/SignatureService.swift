import Foundation
import LoggingInterfaces
import SecurityCoreInterfaces
import SecurityCoreTypes
import SecurityTypes

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
  let logger: LoggingInterfaces.LoggingProtocol

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
    logger: LoggingInterfaces.LoggingProtocol
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
  init(logger _: LoggingInterfaces.LoggingProtocol) {
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
    let logMetadata=createOperationMetadata(
      operationID: operationID,
      operation: operation,
      config: config
    )

    await logger.info("Starting signing operation", metadata: logMetadata)

    do {
      // Extract required parameters from configuration
      guard let inputData=config.options["data"].flatMap({ SecureBytes(base64Encoded: $0) }) else {
        throw SignatureError.invalidInput("Missing input data for signing")
      }

      // Handle different key acquisition strategies
      do {
        let signature: SecureBytes

        // If keyID is provided, retrieve the key from key management
        if let keyID=config.options["keyId"] {
          // Retrieve the key from the key management service
          let keyResult=await keyManagementService.retrieveKey(withIdentifier: keyID)

          switch keyResult {
            case .success:
              // Use the retrieved key to sign the data
              let signatureResult=await cryptoService.encrypt(
                data: inputData,
                using: config.options["key"]
                  .flatMap { SecureBytes(base64Encoded: $0) } ?? SecureBytes()
              )

              switch signatureResult {
                case let .success(generatedSignature):
                  signature=generatedSignature
                case let .failure(error):
                  throw SignatureError.cryptoError("Failed to encrypt data for signing: \(error)")
              }

            case let .failure(error):
              throw SignatureError
                .keyManagementError("Failed to retrieve key with ID: \(keyID), error: \(error)")
          }
        }
        // If direct key is provided, use it
        else if let key=config.options["key"].flatMap({ SecureBytes(base64Encoded: $0) }) {
          // Use encrypt as a substitute for signature generation
          let signatureResult=await cryptoService.encrypt(data: inputData, using: key)

          switch signatureResult {
            case let .success(generatedSignature):
              signature=generatedSignature
            case let .failure(error):
              throw SignatureError.cryptoError("Failed to generate signature: \(error)")
          }
        }
        // Neither keyID nor key was provided
        else {
          throw SignatureError.invalidInput("Neither key nor keyId provided for signing")
        }

        // Calculate duration for performance metrics
        let duration=Date().timeIntervalSince(startTime) * 1000

        // Create success metadata for logging
        let successMetadata: LoggingInterfaces.LogMetadata=[
          "operationId": operationID,
          "operation": String(describing: operation),
          "algorithm": config.algorithm,
          "durationMs": String(format: "%.2f", duration)
        ]

        await logger.info(
          "Signing operation completed successfully",
          metadata: successMetadata
        )

        // Return successful result with signature
        return SecurityResultDTO(
          status: .success,
          data: signature,
          metadata: [
            "durationMs": String(format: "%.2f", duration),
            "algorithm": config.algorithm
          ]
        )
      } catch {
        // Calculate duration before failure
        let duration=Date().timeIntervalSince(startTime) * 1000

        // Create failure metadata for logging
        let errorMetadata: LoggingInterfaces.LogMetadata=[
          "operationId": operationID,
          "operation": String(describing: operation),
          "durationMs": String(format: "%.2f", duration),
          "errorType": "\(type(of: error))",
          "errorMessage": error.localizedDescription
        ]

        await logger.error(
          "Signing operation failed: \(error.localizedDescription)",
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
    } catch {
      // Calculate duration before failure
      let duration=Date().timeIntervalSince(startTime) * 1000

      // Create failure metadata for logging
      let errorMetadata: LoggingInterfaces.LogMetadata=[
        "operationId": operationID,
        "operation": String(describing: operation),
        "durationMs": String(format: "%.2f", duration),
        "errorType": "\(type(of: error))",
        "errorMessage": error.localizedDescription
      ]

      await logger.error(
        "Signing operation failed: \(error.localizedDescription)",
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
   Verifies a signature with the specified configuration

   - Parameter config: Configuration for the verification operation
   - Returns: Result containing verification status or error information
   */
  func verify(config: SecurityConfigDTO) async -> SecurityResultDTO {
    let operationID=UUID().uuidString
    let startTime=Date()
    let operation=SecurityOperation.verify

    // Create metadata for logging
    let logMetadata=createOperationMetadata(
      operationID: operationID,
      operation: operation,
      config: config
    )

    await logger.info("Starting signature verification operation", metadata: logMetadata)

    do {
      // Extract required parameters from configuration
      guard let inputData=config.options["data"].flatMap({ SecureBytes(base64Encoded: $0) }) else {
        throw SignatureError.invalidInput("Missing input data for verification")
      }

      guard let signature=config.options["signature"].flatMap({ SecureBytes(base64Encoded: $0) })
      else {
        throw SignatureError.invalidInput("Missing signature to verify")
      }

      // Check if key is provided directly in the options
      if config.options["key"].flatMap({ SecureBytes(base64Encoded: $0) }) != nil {
        // Try to verify the signature using the provided key
        let calculatedSignatureResult=await cryptoService.encrypt(
          data: inputData,
          using: config.options["key"].flatMap { SecureBytes(base64Encoded: $0) } ?? SecureBytes()
        )

        switch calculatedSignatureResult {
          case let .success(calculatedSignature):
            // Compare the calculated signature with the provided signature
            let isValid=(calculatedSignature == signature)

            // Calculate duration for performance metrics
            let duration=Date().timeIntervalSince(startTime) * 1000

            // Create result metadata
            let verificationMetadata: LoggingInterfaces.LogMetadata=[
              "operationId": operationID,
              "operation": String(describing: operation),
              "algorithm": config.algorithm,
              "durationMs": String(format: "%.2f", duration),
              "isValid": "\(isValid)"
            ]

            if isValid {
              await logger.info(
                "Signature verification completed: Valid signature",
                metadata: [
                  "operationId": operationID,
                  "durationMs": String(format: "%.2f", duration),
                  "algorithm": config.algorithm,
                  "verification": "valid"
                ]
              )
            } else {
              await logger.warning(
                "Signature verification completed: Invalid signature",
                metadata: verificationMetadata
              )
            }

            // Return verification result
            return SecurityResultDTO(
              status: .success,
              metadata: [
                "verified": "\(isValid)",
                "algorithm": config.algorithm
              ]
            )

          case let .failure(error):
            throw SignatureError
              .cryptoError("Failed to calculate signature for verification: \(error)")
        }
      } else {
        // If key not provided directly, try to retrieve from key manager

        // Attempt to get key ID from config
        guard let keyID=config.options["keyId"] else {
          throw SignatureError.invalidInput("Neither key nor keyId provided for verification")
        }

        // Request key from key manager
        let keyResult=await keyManagementService.retrieveKey(withIdentifier: keyID)

        switch keyResult {
          case .success:
            // Try to verify the signature using the retrieved key
            let calculatedSignatureResult=await cryptoService.encrypt(
              data: inputData,
              using: config.options["key"]
                .flatMap { SecureBytes(base64Encoded: $0) } ?? SecureBytes()
            )

            switch calculatedSignatureResult {
              case let .success(calculatedSignature):
                // Compare the calculated signature with the provided signature
                let isValid=(calculatedSignature == signature)

                // Calculate duration for performance metrics
                let duration=Date().timeIntervalSince(startTime) * 1000

                // Create result metadata
                let verificationMetadata: LoggingInterfaces.LogMetadata=[
                  "operationId": operationID,
                  "operation": String(describing: operation),
                  "algorithm": config.algorithm,
                  "durationMs": String(format: "%.2f", duration),
                  "isValid": "\(isValid)"
                ]

                if isValid {
                  await logger.info(
                    "Signature verification completed: Valid signature",
                    metadata: [
                      "operationId": operationID,
                      "durationMs": String(format: "%.2f", duration),
                      "algorithm": config.algorithm,
                      "verification": "valid"
                    ]
                  )
                } else {
                  await logger.warning(
                    "Signature verification completed: Invalid signature",
                    metadata: verificationMetadata
                  )
                }

                // Return verification result
                return SecurityResultDTO(
                  status: .success,
                  metadata: [
                    "verified": "\(isValid)",
                    "algorithm": config.algorithm
                  ]
                )

              case let .failure(error):
                throw SignatureError
                  .cryptoError("Failed to calculate signature for verification: \(error)")
            }

          case let .failure(error):
            throw SignatureError.keyManagementError("Failed to retrieve key, error: \(error)")
        }
      }
    } catch {
      // Calculate duration before failure
      let duration=Date().timeIntervalSince(startTime) * 1000

      // Create failure metadata for logging
      let errorMetadata: LoggingInterfaces.LogMetadata=[
        "operationId": operationID,
        "operation": String(describing: operation),
        "durationMs": String(format: "%.2f", duration),
        "errorType": "\(type(of: error))",
        "errorMessage": error.localizedDescription
      ]

      await logger.error(
        "Signature verification operation failed: \(error.localizedDescription)",
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
}

// Define the SignatureError enum
enum SignatureError: Error {
  case invalidInput(String)
  case keyManagementError(String)
  case cryptoError(String)
}
