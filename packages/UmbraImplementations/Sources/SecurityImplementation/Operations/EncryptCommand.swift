import CoreSecurityTypes
import CryptoInterfaces
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes

/// Command that executes encryption operations.
///
/// This command encapsulates the encryption logic, separating it from
/// the core SecurityProvider implementation while maintaining the same
/// functionality and standards.
public class EncryptCommand: BaseSecurityCommand, SecurityOperationCommand {
  /// The crypto service for performing the encryption
  private let cryptoService: CryptoServiceProtocol

  /// Initialises a new encrypt command.
  ///
  /// - Parameters:
  ///   - config: Security configuration for the encryption
  ///   - cryptoService: The service to perform the encryption
  ///   - logger: Logger for operation tracking and auditing
  public init(
    config: SecurityConfigDTO,
    cryptoService: CryptoServiceProtocol,
    logger: LoggingProtocol
  ) {
    self.cryptoService=cryptoService
    super.init(config: config, logger: logger)
  }

  /// Executes the encryption operation.
  ///
  /// - Parameters:
  ///   - context: Logging context for the operation
  ///   - operationID: Unique identifier for this operation instance
  /// - Returns: The encryption result
  /// - Throws: SecurityError if encryption fails
  public func execute(
    context: LogContextDTO,
    operationID: String
  ) async throws -> SecurityResultDTO {
    await logDebug("Preparing to encrypt data", context: context)

    // Extract required data from configuration
    let extractor=metadataExtractor()

    do {
      // Extract input data
      let inputData=try extractor.requiredData(
        forKey: "inputData",
        errorMessage: "Input data is required for encryption"
      )

      // Extract key identifier
      let keyIdentifier=try extractor.requiredIdentifier(
        forKey: "keyIdentifier",
        errorMessage: "Key identifier is required for encryption"
      )

      // Log encryption details
      let enhancedContext=context.adding(
        key: "dataSize",
        value: "\(inputData.count) bytes",
        privacyLevel: .public
      ).adding(
        key: "algorithm",
        value: config.encryptionAlgorithm.rawValue,
        privacyLevel: .public
      )

      await logDebug(
        "Encrypting data using \(config.encryptionAlgorithm.rawValue)",
        context: enhancedContext
      )

      // Perform the encryption
      let result=try await cryptoService.encrypt(
        data: [UInt8](inputData),
        keyIdentifier: keyIdentifier,
        algorithm: config.encryptionAlgorithm
      )

      // Process the result
      switch result {
        case let .success(encryptedBytes):
          // Convert result to Data
          let encryptedData=Data(encryptedBytes)

          // Record successful encryption
          await logInfo(
            "Successfully encrypted \(inputData.count) bytes of data",
            context: enhancedContext.adding(
              key: "resultSize",
              value: "\(encryptedData.count) bytes",
              privacyLevel: .public
            )
          )

          // Create result metadata with the encrypted data
          let resultMetadata=MetadataCollection()
            .with(key: "encryptedData", value: encryptedData)
            .with(key: "operationID", value: operationID)
            .with(key: "algorithm", value: config.encryptionAlgorithm.rawValue)
            .with(key: "timestamp", value: Date())

          // Return successful result
          return SecurityResultDTO(
            success: true,
            metadata: resultMetadata,
            errorCode: nil,
            errorMessage: nil
          )

        case let .failure(error):
          // Log encryption failure
          await logError(
            "Encryption failed: \(error.localizedDescription)",
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
        "Failed to extract required encryption parameters: \(error.localizedDescription)",
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
        "Unexpected error during encryption: \(error.localizedDescription)",
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
