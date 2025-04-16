import CoreSecurityTypes
import CryptoInterfaces
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes

/// Command that executes decryption operations.
///
/// This command encapsulates the decryption logic, separating it from
/// the core SecurityProvider implementation while maintaining the same
/// functionality and standards.
public class DecryptCommand: BaseSecurityCommand, SecurityOperationCommand {
  /// The crypto service for performing the decryption
  private let cryptoService: CryptoServiceProtocol

  /// Initialises a new decrypt command.
  ///
  /// - Parameters:
  ///   - config: Security configuration for the decryption
  ///   - cryptoService: The service to perform the decryption
  ///   - logger: Logger for operation tracking and auditing
  public init(
    config: SecurityConfigDTO,
    cryptoService: CryptoServiceProtocol,
    logger: LoggingProtocol
  ) {
    self.cryptoService=cryptoService
    super.init(config: config, logger: logger)
  }

  /// Executes the decryption operation.
  ///
  /// - Parameters:
  ///   - context: Logging context for the operation
  ///   - operationID: Unique identifier for this operation instance
  /// - Returns: The decryption result
  /// - Throws: SecurityError if decryption fails
  public func execute(
    context: LogContextDTO,
    operationID: String
  ) async throws -> SecurityResultDTO {
    await logDebug("Preparing to decrypt data", context: context)

    // Extract required data from configuration
    let extractor=metadataExtractor()

    do {
      // Extract encrypted data
      let encryptedData=try extractor.requiredData(
        forKey: "encryptedData",
        errorMessage: "Encrypted data is required for decryption"
      )

      // Extract key identifier
      let keyIdentifier=try extractor.requiredIdentifier(
        forKey: "keyIdentifier",
        errorMessage: "Key identifier is required for decryption"
      )

      // Log decryption details
      let enhancedContext=context.adding(
        key: "dataSize",
        value: "\(encryptedData.count) bytes",
        privacyLevel: .public
      ).adding(
        key: "algorithm",
        value: config.encryptionAlgorithm.rawValue,
        privacyLevel: .public
      )

      await logDebug(
        "Decrypting data using \(config.encryptionAlgorithm.rawValue)",
        context: enhancedContext
      )

      // Perform the decryption
      let result=try await cryptoService.decrypt(
        data: [UInt8](encryptedData),
        keyIdentifier: keyIdentifier,
        algorithm: config.encryptionAlgorithm
      )

      // Process the result
      switch result {
        case let .success(decryptedBytes):
          // Convert result to Data
          let decryptedData=Data(decryptedBytes)

          // Record successful decryption
          await logInfo(
            "Successfully decrypted \(encryptedData.count) bytes of data",
            context: enhancedContext.adding(
              key: "resultSize",
              value: "\(decryptedData.count) bytes",
              privacyLevel: .public
            )
          )

          // Create result metadata with the decrypted data
          let resultMetadata=MetadataCollection()
            .with(key: "decryptedData", value: decryptedData)
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
          // Log decryption failure
          await logError(
            "Decryption failed: \(error.localizedDescription)",
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
        "Failed to extract required decryption parameters: \(error.localizedDescription)",
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
        "Unexpected error during decryption: \(error.localizedDescription)",
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
