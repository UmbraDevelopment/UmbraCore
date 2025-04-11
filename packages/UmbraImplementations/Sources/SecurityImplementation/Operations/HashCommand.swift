import CoreSecurityTypes
import CryptoInterfaces
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 Command that executes hashing operations.

 This command encapsulates the cryptographic hashing logic in accordance with
 the command pattern, providing clean separation of concerns.
 */
public class HashCommand: BaseSecurityCommand, SecurityOperationCommand {
  /// The crypto service for performing the hashing
  private let cryptoService: CryptoServiceProtocol

  /**
   Initialises a new hash command.

   - Parameters:
      - config: Security configuration for the hashing
      - cryptoService: The service to perform the hashing
      - logger: Logger for operation tracking and auditing
   */
  public init(
    config: SecurityConfigDTO,
    cryptoService: CryptoServiceProtocol,
    logger: LoggingProtocol
  ) {
    self.cryptoService=cryptoService
    super.init(config: config, logger: logger)
  }

  /**
   Executes the hashing operation.

   - Parameters:
      - context: Logging context for the operation
      - operationID: Unique identifier for this operation instance
   - Returns: The hashing result
   - Throws: SecurityError if hashing fails
   */
  public func execute(
    context: LogContextDTO,
    operationID: String
  ) async throws -> SecurityResultDTO {
    await logDebug("Preparing to hash data", context: context)

    // Extract required data from configuration
    let extractor=metadataExtractor()

    do {
      // Extract input data
      let inputData=try extractor.requiredData(
        forKey: "inputData",
        errorMessage: "Input data is required for hashing"
      )

      // Log hashing details
      let enhancedContext=context.adding(
        key: "dataSize",
        value: "\(inputData.count) bytes",
        privacyLevel: .public
      ).adding(
        key: "algorithm",
        value: config.hashAlgorithm.rawValue,
        privacyLevel: .public
      )

      await logDebug(
        "Hashing data using \(config.hashAlgorithm.rawValue)",
        context: enhancedContext
      )

      // Perform the hashing
      let result=try await cryptoService.hash(
        data: [UInt8](inputData),
        algorithm: config.hashAlgorithm
      )

      // Process the result
      switch result {
        case let .success(hashBytes):
          // Convert result to Data
          let hashData=Data(hashBytes)

          // Record successful hashing
          await logInfo(
            "Successfully hashed \(inputData.count) bytes of data",
            context: enhancedContext.adding(
              key: "resultSize",
              value: "\(hashData.count) bytes",
              privacyLevel: .public
            )
          )

          // Create result metadata
          let resultMetadata: [String: String]=[
            "inputSize": "\(inputData.count)",
            "hashSize": "\(hashData.count)",
            "algorithm": config.hashAlgorithm.rawValue,
            "operationID": operationID
          ]

          // Return successful result
          return createSuccessResult(
            data: hashData,
            duration: 0, // Duration will be calculated by the operation handler
            metadata: resultMetadata
          )

        case let .failure(error):
          throw error
      }
    } catch let securityError as SecurityStorageError {
      // Log specific hashing errors
      await logError(
        "Hashing failed due to storage error: \(securityError)",
        context: context
      )
      throw securityError
    } catch {
      // Log unexpected errors
      await logError(
        "Hashing failed with unexpected error: \(error.localizedDescription)",
        context: context
      )
      throw CoreSecurityTypes.SecurityError.hashingFailed(
        reason: "Hashing operation failed: \(error.localizedDescription)"
      )
    }
  }
}
