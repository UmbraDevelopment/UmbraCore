import CoreSecurityTypes
import CryptoInterfaces
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 Command that executes hash verification operations.

 This command encapsulates the hash verification logic in accordance with
 the command pattern, providing clean separation of concerns.
 */
public class VerifyHashCommand: BaseSecurityCommand, SecurityOperationCommand {
  /// The crypto service for performing the verification
  private let cryptoService: CryptoServiceProtocol

  /**
   Initialises a new hash verification command.

   - Parameters:
      - config: Security configuration for the verification
      - cryptoService: The service to perform the verification
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
   Executes the hash verification operation.

   - Parameters:
      - context: Logging context for the operation
      - operationID: Unique identifier for this operation instance
   - Returns: The verification result
   - Throws: SecurityError if verification fails
   */
  public func execute(
    context: LogContextDTO,
    operationID: String
  ) async throws -> SecurityResultDTO {
    await logDebug("Preparing to verify hash", context: context)

    // Extract required data from configuration
    let extractor=metadataExtractor()

    do {
      // Extract input data
      let inputData=try extractor.requiredData(
        forKey: "inputData",
        errorMessage: "Input data is required for hash verification"
      )

      // Extract expected hash
      let expectedHash=try extractor.requiredData(
        forKey: "expectedHash",
        errorMessage: "Expected hash is required for verification"
      )

      // Log verification details
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
        "Verifying hash using \(config.hashAlgorithm.rawValue)",
        context: enhancedContext
      )

      // Perform the verification by:
      // 1. Computing the hash of the input data
      // 2. Comparing with the expected hash

      // First compute the hash
      let hashResult=try await cryptoService.hash(
        data: [UInt8](inputData),
        algorithm: config.hashAlgorithm
      )

      // Process the hash result
      switch hashResult {
        case let .success(computedHashBytes):
          // Convert to Data for comparison
          let computedHash=Data(computedHashBytes)

          // Compare computed hash with expected hash
          let verified=computedHash == expectedHash

          // Log the verification result
          if verified {
            await logInfo(
              "Hash verification successful",
              context: enhancedContext
            )
          } else {
            await logWarning(
              "Hash verification failed: computed hash does not match expected hash",
              context: enhancedContext
            )
          }

          // Create result metadata
          let resultMetadata: [String: String]=[
            "verified": verified ? "true" : "false",
            "inputSize": "\(inputData.count)",
            "hashSize": "\(expectedHash.count)",
            "algorithm": config.hashAlgorithm.rawValue,
            "operationID": operationID
          ]

          // Return the verification result
          // For hash verification, the result data is a boolean as Data
          let resultData=Data([verified ? 1 : 0])

          return createSuccessResult(
            data: resultData,
            duration: 0, // Duration will be calculated by the operation handler
            metadata: resultMetadata
          )

        case let .failure(error):
          throw error
      }
    } catch let securityError as SecurityStorageError {
      // Log specific verification errors
      await logError(
        "Hash verification failed due to storage error: \(securityError)",
        context: context
      )
      throw securityError
    } catch {
      // Log unexpected errors
      await logError(
        "Hash verification failed with unexpected error: \(error.localizedDescription)",
        context: context
      )
      throw CoreSecurityTypes.SecurityError.verificationFailed(
        reason: "Hash verification operation failed: \(error.localizedDescription)"
      )
    }
  }
}
