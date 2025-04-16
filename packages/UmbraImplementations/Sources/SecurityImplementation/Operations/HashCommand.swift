import CoreSecurityTypes
import CryptoInterfaces
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes

/// Command that executes cryptographic hash operations.
///
/// This command encapsulates the hashing logic, separating it from
/// the core SecurityProvider implementation while maintaining the same
/// functionality and standards.
public class HashCommand: BaseSecurityCommand, SecurityOperationCommand {
  /// The crypto service for performing the hashing
  private let cryptoService: CryptoServiceProtocol

  /// Initialises a new hash command.
  ///
  /// - Parameters:
  ///   - config: Security configuration for the hashing operation
  ///   - cryptoService: The service to perform the hash
  ///   - logger: Logger for operation tracking and auditing
  public init(
    config: SecurityConfigDTO,
    cryptoService: CryptoServiceProtocol,
    logger: LoggingProtocol
  ) {
    self.cryptoService=cryptoService
    super.init(config: config, logger: logger)
  }

  /// Executes the hash operation.
  ///
  /// - Parameters:
  ///   - context: Logging context for the operation
  ///   - operationID: Unique identifier for this operation instance
  /// - Returns: The hash result
  /// - Throws: SecurityError if hashing fails
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

      // Log hash operation details
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

      // Perform the hash operation
      let result=try await cryptoService.hash(
        data: [UInt8](inputData),
        algorithm: config.hashAlgorithm
      )

      // Process the result
      switch result {
        case let .success(hashBytes):
          // Convert result to Data and hexadecimal string for display
          let hashData=Data(hashBytes)
          let hashHex=hashBytes.hexString

          // Record successful hash
          await logInfo(
            "Successfully hashed \(inputData.count) bytes of data",
            context: enhancedContext.adding(
              key: "hashSize",
              value: "\(hashData.count) bytes",
              privacyLevel: .public
            )
          )

          // Create result metadata with the hash value
          let resultMetadata=MetadataCollection()
            .with(key: "hashValue", value: hashData)
            .with(key: "hashHex", value: hashHex)
            .with(key: "operationID", value: operationID)
            .with(key: "algorithm", value: config.hashAlgorithm.rawValue)
            .with(key: "timestamp", value: Date())

          // Return successful result
          return SecurityResultDTO(
            success: true,
            metadata: resultMetadata,
            errorCode: nil,
            errorMessage: nil
          )

        case let .failure(error):
          // Log hash failure
          await logError(
            "Hash operation failed: \(error.localizedDescription)",
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
        "Failed to extract required hash parameters: \(error.localizedDescription)",
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
        "Unexpected error during hash operation: \(error.localizedDescription)",
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
