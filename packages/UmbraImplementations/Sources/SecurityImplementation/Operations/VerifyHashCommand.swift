import CoreSecurityTypes
import CryptoInterfaces
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes

/// Command that executes hash verification operations.
///
/// This command encapsulates the hash verification logic, separating it from
/// the core SecurityProvider implementation while maintaining the same
/// functionality and standards.
public class VerifyHashCommand: BaseSecurityCommand, SecurityOperationCommand {
  /// The crypto service for performing the hash verification
  private let cryptoService: CryptoServiceProtocol

  /// Initialises a new verify hash command.
  ///
  /// - Parameters:
  ///   - config: Security configuration for the hash verification
  ///   - cryptoService: The service to perform the hash verification
  ///   - logger: Logger for operation tracking and auditing
  public init(
    config: SecurityConfigDTO,
    cryptoService: CryptoServiceProtocol,
    logger: LoggingProtocol
  ) {
    self.cryptoService=cryptoService
    super.init(config: config, logger: logger)
  }

  /// Executes the hash verification operation.
  ///
  /// - Parameters:
  ///   - context: Logging context for the operation
  ///   - operationID: Unique identifier for this operation instance
  /// - Returns: The verification result
  /// - Throws: SecurityError if verification fails
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

      // Extract expected hash value
      let expectedHash=try extractor.requiredData(
        forKey: "expectedHash",
        errorMessage: "Expected hash value is required for verification"
      )

      // Log verification details
      let enhancedContext=context.adding(
        key: "dataSize",
        value: "\(inputData.count) bytes",
        privacyLevel: .public
      ).adding(
        key: "hashSize",
        value: "\(expectedHash.count) bytes",
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

      // Perform the hash operation on the input data
      let hashResult=try await cryptoService.hash(
        data: [UInt8](inputData),
        algorithm: config.hashAlgorithm
      )

      // Process the hash result
      switch hashResult {
        case let .success(computedHashBytes):
          // Convert computed hash to Data for comparison
          let computedHash=Data(computedHashBytes)

          // Compare computed hash with expected hash
          let hashesMatch=(computedHash == expectedHash)

          // Log verification result
          if hashesMatch {
            await logInfo(
              "Hash verification succeeded",
              context: enhancedContext
            )
          } else {
            await logWarning(
              "Hash verification failed - hashes do not match",
              context: enhancedContext.adding(
                key: "computedHashSize",
                value: "\(computedHash.count) bytes",
                privacyLevel: .public
              )
            )
          }

          // Create result metadata with verification result
          let resultMetadata=MetadataCollection()
            .with(key: "verified", value: hashesMatch)
            .with(key: "operationID", value: operationID)
            .with(key: "algorithm", value: config.hashAlgorithm.rawValue)
            .with(key: "timestamp", value: Date())

          // Return successful verification result
          return SecurityResultDTO(
            success: true,
            metadata: resultMetadata,
            errorCode: nil,
            errorMessage: nil
          )

        case let .failure(error):
          // Log hash computation failure
          await logError(
            "Hash computation failed during verification: \(error.localizedDescription)",
            context: enhancedContext
          )

          // Return failure result
          return SecurityResultDTO(
            success: false,
            metadata: MetadataCollection()
              .with(key: "operationID", value: operationID)
              .with(key: "errorType", value: String(describing: type(of: error))),
            errorCode: error.errorCode,
            errorMessage: error.localizedDescription
          )
      }
    } catch let error as MetadataExtractionError {
      // Log extraction failure
      await logError(
        "Failed to extract required verification parameters: \(error.localizedDescription)",
        context: context
      )

      // Return extraction failure result
      return SecurityResultDTO(
        success: false,
        metadata: MetadataCollection()
          .with(key: "operationID", value: operationID)
          .with(key: "errorType", value: String(describing: type(of: error))),
        errorCode: SecurityError.invalidInputData.errorCode,
        errorMessage: error.localizedDescription
      )
    } catch {
      // Log unexpected failure
      await logError(
        "Unexpected error during hash verification: \(error.localizedDescription)",
        context: context
      )

      // Return unexpected failure result
      return SecurityResultDTO(
        success: false,
        metadata: MetadataCollection()
          .with(key: "operationID", value: operationID)
          .with(key: "errorType", value: String(describing: type(of: error))),
        errorCode: SecurityError.operationFailed.errorCode,
        errorMessage: error.localizedDescription
      )
    }
  }
}
