import CoreSecurityTypes
import CryptoKit
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import SecurityCoreInterfaces
import Security

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
    // Use the dedicated hash operation from CoreSecurityTypes
    let operation=CoreSecurityTypes.SecurityOperation.hash

    // Create a logging context
    let logContext=SecurityLogContext(
      operation: operation.rawValue,
      component: "HashingService",
      operationID: operationID,
      correlationID: nil,
      source: "HashingService"
    )

    await logger.info(
      "Starting hash operation",
      context: logContext
    )

    // Extract required parameters from configuration
    guard
      let dataString=config.options?.metadata?["data"],
      let inputData=Data(base64Encoded: dataString)
    else {
      // Calculate duration even for failed operations
      let duration=Date().timeIntervalSince(startTime)

      // Return failed result
      return SecurityResultDTO.failure(
        errorDetails: "Invalid input data for hashing",
        executionTimeMs: duration * 1000,
        metadata: [
          "durationMs": String(format: "%.2f", duration * 1000),
          "errorMessage": "Invalid input data for hashing",
          "operationID": operationID
        ]
      )
    }

    // Determine hash algorithm to use
    var hashAlgorithm=CoreSecurityTypes.HashAlgorithm.sha256
    if
      let algorithmString=config.options?.metadata?["algorithm"],
      let algorithm=CoreSecurityTypes.HashAlgorithm(rawValue: algorithmString)
    {
      hashAlgorithm=algorithm
    }

    // Create a proper logging context
    let logContext2=SecurityLogContext(
      operation: "hash",
      component: "HashingService",
      operationID: operationID,
      correlationID: nil,
      source: "HashingService"
    )

    await logger.info(
      "Processing hash operation",
      context: logContext2
    )

    // Process the input data through the appropriate hash function
    let hashResult=await performHashOperation(
      data: inputData,
      algorithm: hashAlgorithm,
      options: [:] // Pass an empty dictionary instead of SecurityConfigOptions
    )

    // Calculate duration for metrics
    let duration=Date().timeIntervalSince(startTime)

    switch hashResult {
      case let .success(hashData):
        // Return successful result
        return SecurityResultDTO.success(
          resultData: hashData,
          executionTimeMs: duration * 1000,
          metadata: [
            "durationMs": String(format: "%.2f", duration * 1000),
            "outputSize": "\(hashData.count)",
            "operationID": operationID
          ]
        )

      case let .failure(error):
        // Return failed result
        return SecurityResultDTO.failure(
          errorDetails: error.localizedDescription,
          executionTimeMs: duration * 1000,
          metadata: [
            "durationMs": String(format: "%.2f", duration * 1000),
            "errorMessage": error.localizedDescription,
            "operationID": operationID
          ]
        )
    }
  }

  /**
   Hashes the provided data using the specified algorithm.

   - Parameters:
     - data: The data to hash
     - algorithm: Hash algorithm to use (defaults to SHA-256)
   - Returns: Result containing the hashed data or an error
   */
  func hashData(
    _ data: SendableCryptoMaterial,
    algorithm: CoreSecurityTypes.HashAlgorithm = .sha256
  ) async -> Result<SendableCryptoMaterial, Error> {
    let operationID=UUID().uuidString
    let startTime=Date()

    // Create privacy-aware metadata for logging
    let logMetadataCollection=LogMetadataDTOCollection()
      .withPublic(key: "operationID", value: operationID)
      .withPublic(key: "algorithm", value: algorithm.rawValue)

    let logContext=SecurityLogContext(
      operation: "hashData",
      component: "HashingService",
      correlationID: operationID,
      source: "HashingService",
      metadata: logMetadataCollection
    )

    await logger.info(
      "Starting direct hash operation",
      context: logContext
    )

    do {
      // Perform the hashing operation using the proper CryptoServiceProtocol method
      let hashingOptions=HashingOptions(algorithm: algorithm)

      // First import the data into secure storage to get an identifier
      // Use toData() method instead of accessing private bytes
      let dataToImport=data.toData()
      let importResult=try await cryptoService.importData(
        dataToImport,
        customIdentifier: "hash-input-\(operationID)"
      )

      guard case let .success(dataIdentifier)=importResult else {
        throw CoreSecurityTypes.SecurityError
          .hashingFailed(reason: "Failed to import data for hashing")
      }

      // Now perform the hash operation using the dataIdentifier
      let hashResult=await cryptoService.hash(
        dataIdentifier: dataIdentifier,
        options: hashingOptions
      )

      // Handle the result
      guard case let .success(hashIdentifier)=hashResult else {
        throw CoreSecurityTypes.SecurityError.hashingFailed(reason: "Hashing operation failed")
      }

      // Retrieve the hashed data from secure storage
      let retrieveResult=await cryptoService.secureStorage
        .retrieveData(withIdentifier: hashIdentifier)

      guard case let .success(hashedBytes)=retrieveResult else {
        throw CoreSecurityTypes.SecurityError
          .hashingFailed(reason: "Failed to retrieve hashed data")
      }

      // Convert to Foundation.Data for return
      let resultData=Data(hashedBytes)

      // Create result using appropriate initializer for SendableCryptoMaterial
      let resultBytes=[UInt8](resultData)
      return .success(SendableCryptoMaterial(bytes: resultBytes))
    } catch {
      // Calculate duration for failed operation
      let duration=Date().timeIntervalSince(startTime)

      // Log error with updated context
      let errorContext=SecurityLogContext(
        operation: "hashData",
        component: "HashingService",
        correlationID: operationID,
        source: "HashingService",
        metadata: logMetadataCollection
          .withPublic(key: "durationMs", value: String(format: "%.2f", duration * 1000))
          .withPublic(key: "error", value: error.localizedDescription)
      )

      await logger.error(
        "Hash operation failed: \(error.localizedDescription)",
        context: errorContext
      )

      return .failure(error)
    }
  }

  /**
   Hashes the provided data using the specified algorithm.

   - Parameters:
     - data: The data to hash
     - algorithm: Hash algorithm to use (defaults to SHA-256)
   - Returns: Result containing the hashed data or an error
   */
  func performDirectHash(
    data: SendableCryptoMaterial,
    algorithm: CoreSecurityTypes.HashAlgorithm
  ) async -> Result<Data, Error> {
    let operationID=UUID().uuidString
    let startTime=Date()

    // Create privacy-aware metadata for logging
    let logMetadataCollection=LogMetadataDTOCollection()
      .withPublic(key: "operationID", value: operationID)
      .withPublic(key: "algorithm", value: algorithm.rawValue)

    let logContext=SecurityLogContext(
      operation: "performDirectHash",
      component: "HashingService",
      correlationID: operationID,
      source: "HashingService",
      metadata: logMetadataCollection
    )

    await logger.info(
      "Starting direct hash operation",
      context: logContext
    )

    do {
      // First import the data into secure storage to get an identifier
      let dataToImport=data.toData()
      let importResult=await cryptoService.importData(
        dataToImport,
        customIdentifier: "hash-input-\(operationID)"
      )

      guard case let .success(dataIdentifier)=importResult else {
        throw CoreSecurityTypes.SecurityError
          .hashingFailed(reason: "Failed to import data for hashing")
      }

      // Now perform the hash operation using the dataIdentifier
      // Map the algorithm to CoreSecurityTypes.HashAlgorithm
      var coreAlgorithm: CoreSecurityTypes.HashAlgorithm = .sha256

      switch algorithm {
        case .sha256:
          coreAlgorithm = .sha256
        case .sha512:
          coreAlgorithm = .sha512
        default:
          // Default to sha256 for unsupported algorithms
          coreAlgorithm = .sha256
      }

      let hashingOptions=HashingOptions(algorithm: coreAlgorithm)
      let hashResult=await cryptoService.hash(
        dataIdentifier: dataIdentifier,
        options: hashingOptions
      )

      // Handle the result
      guard case let .success(hashIdentifier)=hashResult else {
        throw CoreSecurityTypes.SecurityError.hashingFailed(reason: "Hashing operation failed")
      }

      // Retrieve the hashed data from secure storage
      let retrieveResult=await cryptoService.secureStorage
        .retrieveData(withIdentifier: hashIdentifier)

      guard case let .success(hashedBytes)=retrieveResult else {
        throw CoreSecurityTypes.SecurityError
          .hashingFailed(reason: "Failed to retrieve hashed data")
      }

      // Convert to Foundation.Data for return
      let resultData=Data(hashedBytes)

      // Calculate duration for metrics
      let duration=Date().timeIntervalSince(startTime)

      // Log successful operation with updated context
      let successContext=SecurityLogContext(
        operation: "performDirectHash",
        component: "HashingService",
        correlationID: operationID,
        source: "HashingService",
        metadata: logMetadataCollection
          .withPublic(key: "durationMs", value: String(format: "%.2f", duration * 1000))
      )

      await logger.info(
        "Direct hash operation completed successfully",
        context: successContext
      )

      return .success(resultData)
    } catch {
      // Calculate duration for failed operation
      let duration=Date().timeIntervalSince(startTime)

      // Log error with updated context
      let errorContext=SecurityLogContext(
        operation: "performDirectHash",
        component: "HashingService",
        correlationID: operationID,
        source: "HashingService",
        metadata: logMetadataCollection
          .withPublic(key: "durationMs", value: String(format: "%.2f", duration * 1000))
          .withPublic(key: "error", value: error.localizedDescription)
      )

      await logger.error(
        "Direct hash operation failed: \(error.localizedDescription)",
        context: errorContext
      )

      return .failure(error)
    }
  }

  /**
   Performs a hash operation with the specified parameters

   - Parameters:
     - data: The data to hash
     - algorithm: The hashing algorithm to use
     - options: Additional options for the hashing operation
   - Returns: A result containing the hashed data or an error
   */
  private func performHashOperation(
    data: Data,
    algorithm: CoreSecurityTypes.HashAlgorithm,
    options _: [String: String]
  ) async -> Result<Data, Error> {
    // In a real implementation, this would use different algorithms based on the parameters
    // For now, we'll implement a simple SHA-256 hash using CryptoKit
    switch algorithm {
      case .sha256:
        var hasher=SHA256()
        hasher.update(data: data)
        return .success(Data(hasher.finalize()))
      case .sha512:
        var hasher=SHA512()
        hasher.update(data: data)
        return .success(Data(hasher.finalize()))
      default:
        // Default to SHA-256 for unsupported algorithms
        var hasher=SHA256()
        hasher.update(data: data)
        return .success(Data(hasher.finalize()))
    }
  }
}

// Extension to bridge between SendableCryptoMaterial and Foundation.Data
extension SendableCryptoMaterial {
  /// Converts to Foundation.Data for use with APIs requiring Data
  fileprivate func toData() -> Data {
    Data(toByteArray())
  }
}

/**
 * This enum has been removed in favor of CoreSecurityTypes.HashAlgorithm
 */
