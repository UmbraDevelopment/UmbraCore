import LoggingInterfaces
import SecurityCoreInterfaces
import CoreSecurityTypes

/**
 # Hashing Service

 Handles cryptographic hashing operations for the security provider.
 This service encapsulates the logic specific to data hashing,
 reducing complexity in the main SecurityProviderImpl.

 ## Responsibilities

 - Perform hashing operations with various algorithms
 - Track performance and log operations
 - Handle hashing-specific errors
 */
final class HashingService: SecurityServiceBase {
  // MARK: - Properties

  /**
   The crypto service used for cryptographic operations
   */
  private let cryptoService: SecurityCoreInterfaces.CryptoServiceProtocol

  /**
   The logger for operation tracking
   */
  let logger: LoggingInterfaces.LoggingProtocol

  // MARK: - Initialisation

  /**
   Initialises a new hashing service

   - Parameters:
       - cryptoService: Service for cryptographic operations
       - logger: Logger for operation tracking
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
   Hashes data with the specified configuration

   - Parameter config: Configuration for the hashing operation
   - Returns: Result containing hashed data or error information
   */
  func hash(config: SecurityConfigDTO) async -> SecurityResultDTO {
    let operationID=UUID().uuidString
    let startTime=Date()
    // Use generateRandom as a placeholder operation since there's no specific hash case
    let operation=SecurityOperation.generateRandom(length: 0)

    // Create metadata for logging
    let logMetadata=createOperationMetadata(
      operationID: operationID,
      operation: operation,
      config: config
    )

    await logger.info("Starting hashing operation", metadata: logMetadata)

    do {
      // Extract required parameters from configuration
      guard
        let dataString=config.options["data"],
        let inputData=SecureBytes(base64Encoded: dataString)
      else {
        throw SecurityError.invalidInput("Missing or invalid input data for hashing")
      }

      // Determine hash algorithm to use
      let hashAlgorithm=HashAlgorithm(rawValue: config.algorithm) ?? HashAlgorithm.sha256

      // Perform the hashing operation
      let hashResult=try await cryptoService.hash(data: inputData)

      // Process the result
      switch hashResult {
        case let .success(hashedData):
          // Calculate duration for performance metrics
          let duration=Date().timeIntervalSince(startTime) * 1000

          // Create success metadata for logging
          let successMetadata: LoggingInterfaces.LogMetadata=[
            "operationId": operationID,
            "operation": "hash", // Use a specific string for the hash operation in the logs
            "hashAlgorithm": hashAlgorithm.rawValue,
            "durationMs": String(format: "%.2f", duration)
          ]

          await logger.info(
            "Hashing operation completed successfully",
            metadata: successMetadata
          )

          // Return successful result with hashed data
          return SecurityResultDTO(
            status: .success,
            data: hashedData,
            metadata: [
              "durationMs": String(format: "%.2f", duration),
              "hashAlgorithm": hashAlgorithm.rawValue
            ]
          )
        case let .failure(error):
          // Calculate duration before failure
          let duration=Date().timeIntervalSince(startTime) * 1000

          // Create failure metadata for logging
          let errorMetadata: LoggingInterfaces.LogMetadata=[
            "operationId": operationID,
            "operation": "hash", // Use a specific string for the hash operation in the logs
            "durationMs": String(format: "%.2f", duration),
            "errorType": "\(type(of: error))",
            "errorMessage": error.localizedDescription
          ]

          await logger.error(
            "Hashing operation failed: \(error.localizedDescription)",
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
        "operation": "hash", // Use a specific string for the hash operation in the logs
        "durationMs": String(format: "%.2f", duration),
        "errorType": "\(type(of: error))",
        "errorMessage": error.localizedDescription
      ]

      await logger.error(
        "Hashing operation failed: \(error.localizedDescription)",
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

/**
 Supported hash algorithms
 */
enum HashAlgorithm: String {
  case md5="MD5"
  case sha256="SHA256"
  case sha512="SHA512"
}
