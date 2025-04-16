import CoreSecurityTypes
import CryptoInterfaces
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes

/// Command that executes key derivation operations.
///
/// This command encapsulates the key derivation logic, separating it from
/// the core SecurityProvider implementation while maintaining the same
/// functionality and standards.
public class DeriveKeyCommand: BaseSecurityCommand, SecurityOperationCommand {
  /// The crypto service for performing the key derivation
  private let cryptoService: CryptoServiceProtocol

  /// Initialises a new key derivation command.
  ///
  /// - Parameters:
  ///   - config: Security configuration for the key derivation
  ///   - cryptoService: The service to perform the key derivation
  ///   - logger: Logger for operation tracking and auditing
  public init(
    config: SecurityConfigDTO,
    cryptoService: CryptoServiceProtocol,
    logger: LoggingProtocol
  ) {
    self.cryptoService=cryptoService
    super.init(config: config, logger: logger)
  }

  /// Executes the key derivation operation.
  ///
  /// - Parameters:
  ///   - context: Logging context for the operation
  ///   - operationID: Unique identifier for this operation instance
  /// - Returns: The key derivation result
  /// - Throws: SecurityError if key derivation fails
  public func execute(
    context: LogContextDTO,
    operationID: String
  ) async throws -> SecurityResultDTO {
    await logDebug("Preparing to derive key", context: context)

    // Extract required data from configuration
    let extractor=metadataExtractor()

    do {
      // Extract base key material
      let baseKeyData=try extractor.requiredData(
        forKey: "baseKeyMaterial",
        errorMessage: "Base key material is required for key derivation"
      )

      // Extract salt (if provided)
      let salt=try extractor.optionalData(forKey: "salt") ?? Data()

      // Extract info (if provided)
      let info=try extractor.optionalData(forKey: "info") ?? Data()

      // Extract key length (defaults to 32 bytes for AES-256)
      let keyLength=try extractor.optionalInteger(forKey: "keyLength") ?? 32

      // Log key derivation details
      let enhancedContext=context
        .adding(key: "baseKeySize", value: "\(baseKeyData.count) bytes", privacyLevel: .public)
        .adding(key: "saltSize", value: "\(salt.count) bytes", privacyLevel: .public)
        .adding(key: "infoSize", value: "\(info.count) bytes", privacyLevel: .public)
        .adding(key: "targetKeyLength", value: "\(keyLength) bytes", privacyLevel: .public)
        .adding(
          key: "algorithm",
          value: config.keyDerivationAlgorithm.rawValue,
          privacyLevel: .public
        )

      await logDebug(
        "Deriving key using \(config.keyDerivationAlgorithm.rawValue)",
        context: enhancedContext
      )

      // Create key derivation options
      let options=KeyDerivationOptions(
        algorithm: config.keyDerivationAlgorithm.rawValue,
        salt: [UInt8](salt),
        info: [UInt8](info),
        iterations: extractor.optionalInteger(forKey: "iterations") ?? 10000,
        keyLength: keyLength
      )

      // Prepare storage identifiers
      let baseKeyID=UUID().uuidString
      let storeResult=await cryptoService.storeData([UInt8](baseKeyData), identifier: baseKeyID)

      guard case .success=storeResult else {
        if case let .failure(error)=storeResult {
          throw error
        }
        throw SecurityStorageError.operationFailed("Failed to store base key material")
      }

      // Perform the key derivation
      let result=await cryptoService.deriveKey(
        baseKeyIdentifier: baseKeyID,
        options: options
      )

      // Process the result
      switch result {
        case let .success(derivedKeyID):
          // Export the derived key safely
          let keyDataResult=await cryptoService.exportData(identifier: derivedKeyID)

          switch keyDataResult {
            case let .success(keyBytes):
              // Create result metadata with the key identifier
              let resultMetadata=MetadataCollection()
                .with(key: "derivedKeyIdentifier", value: derivedKeyID)
                .with(key: "derivedKeyLength", value: keyBytes.count)
                .with(key: "operationID", value: operationID)
                .with(key: "algorithm", value: config.keyDerivationAlgorithm.rawValue)
                .with(key: "timestamp", value: Date())

              // Record successful key derivation
              await logInfo(
                "Successfully derived key of \(keyBytes.count) bytes",
                context: enhancedContext
              )

              // Return successful result
              return SecurityResultDTO(
                success: true,
                metadata: resultMetadata,
                errorCode: nil,
                errorMessage: nil
              )

            case let .failure(exportError):
              throw exportError
          }

        case let .failure(error):
          // Log key derivation failure
          await logError(
            "Key derivation failed: \(error.localizedDescription)",
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
        "Failed to extract required key derivation parameters: \(error.localizedDescription)",
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
        "Unexpected error during key derivation: \(error.localizedDescription)",
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
