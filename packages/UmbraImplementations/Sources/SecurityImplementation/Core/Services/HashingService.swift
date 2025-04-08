import CoreSecurityTypes
import DomainSecurityTypes
import LoggingInterfaces
import SecurityCoreInterfaces

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

    await logger.info("Starting hashing operation", metadata: logMetadata, source: "SecurityImplementation", source: "SecurityImplementation")

    do {
      // Extract required parameters from configuration
      guard
        let dataString=config.options["data"],
        let inputData=SendableCryptoMaterial.fromBase64(dataString)
      else {
        throw SecurityError.invalidInput("Missing or invalid input data for hashing")
      }

      // Determine hash algorithm to use
      let hashAlgorithm=HashAlgorithm(rawValue: config.algorithm) ?? HashAlgorithm.sha256

      // Perform the hashing operation
      let hashResult=try await cryptoService.hash(inputData, algorithm: hashAlgorithm.rawValue)

      // Calculate duration for performance metrics
      let duration=Date().timeIntervalSince(startTime)

      // Log successful operation
      await logger.info(
        "Completed hashing operation successfully", metadata: logMetadata.merging([
          "duration": "\(duration, source: "SecurityImplementation", source: "SecurityImplementation")",
          "hashAlgorithm": hashAlgorithm.rawValue
        ])
      )

      // Return successful result
      return SecurityResultDTO(
        success: true,
        processedData: hashResult,
        operationID: operationID,
        duration: duration
      )

    } catch {
      // Calculate duration even for failed operations
      let duration=Date().timeIntervalSince(startTime)

      // Log the error
      await logger.error("Hashing operation failed: \(error.localizedDescription)", metadata: logMetadata.merging([
          "duration": "\(duration, source: \"SecurityImplementation\")",
          "error": error.localizedDescription
        ])
      )

      // Return failed result
      return SecurityResultDTO(
        success: false,
        error: error.localizedDescription,
        operationID: operationID,
        duration: duration
      )
    }
  }

  /**
   Creates a hash of the provided data

   This is a dedicated method for hashing plain data without the need for a
   full configuration object.

   - Parameters:
     - data: The data to hash
     - algorithm: The hashing algorithm to use
   - Returns: Result containing hashed data or error information
   */
  func hashData(
    _ data: SendableCryptoMaterial,
    algorithm: HashAlgorithm = .sha256
  ) async -> Result<SendableCryptoMaterial, Error> {
    let operationID=UUID().uuidString
    let startTime=Date()

    // Create basic logging metadata
    let logMetadata: [String: String]=[
      "operationID": operationID,
      "algorithm": algorithm.rawValue
    ]

    await logger.info("Starting direct hash operation", metadata: logMetadata, source: "SecurityImplementation", source: "SecurityImplementation")

    do {
      // Perform the hashing operation
      let hashedData=try await cryptoService.hash(data, algorithm: algorithm.rawValue)

      // Log successful operation
      let duration=Date().timeIntervalSince(startTime)
      await logger.info(
        "Completed direct hash operation", metadata: logMetadata.merging(["duration": "\(duration, source: "SecurityImplementation", source: "SecurityImplementation")"])
      )

      return .success(hashedData)
    } catch {
      // Log error
      let duration=Date().timeIntervalSince(startTime)
      await logger.error("Direct hash operation failed: \(error.localizedDescription)", metadata: logMetadata.merging([
          "duration": "\(duration, source: \"SecurityImplementation\")",
          "error": error.localizedDescription
        ])
      )

      return .failure(error)
    }
  }
}

/**
 Supported hash algorithms
 */
enum HashAlgorithm: String {
  case md5="MD5"
  case sha1="SHA1"
  case sha256="SHA256"
  case sha384="SHA384"
  case sha512="SHA512"
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



