import CoreSecurityTypes
import CryptoInterfaces
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 Command for exporting data from secure storage.

 This command implements secure export operations for cryptographic materials.
 It follows the Alpha Dot Five architecture principles with privacy-aware
 logging and strong error handling.
 */
public class ExportDataCommand: BaseCryptoCommand, CryptoCommand {
  /// The type of result returned by this command
  public typealias ResultType=[UInt8]

  /// The identifier of the data to export
  private let identifier: String

  /**
   Initialises a new export data command.

   - Parameters:
      - identifier: The identifier of the data to export
      - secureStorage: Secure storage for cryptographic materials
      - logger: Optional logger for operation tracking and auditing
   */
  public init(
    identifier: String,
    secureStorage: SecureStorageProtocol,
    logger: LoggingProtocol?=nil
  ) {
    self.identifier=identifier
    super.init(secureStorage: secureStorage, logger: logger)
  }

  /**
   Executes the export operation.

   - Parameters:
      - context: Logging context for the operation
      - operationID: Unique identifier for this operation instance
   - Returns: The exported data
   */
  public func execute(
    context _: LogContextDTO,
    operationID: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    // Create a log context with proper privacy classification
    let logContext=createLogContext(
      operation: "exportData",
      correlationID: operationID,
      additionalMetadata: [
        "dataIdentifier": (value: identifier, privacyLevel: .private)
      ]
    )

    await logDebug("Starting data export operation", context: logContext)

    // Retrieve the data from secure storage
    let retrieveResult=await secureStorage.retrieveSecureData(identifier: identifier)

    switch retrieveResult {
      case let .success(data):
        await logInfo(
          "Successfully exported \(data.count) bytes of data",
          context: logContext.adding(
            key: "dataSize",
            value: "\(data.count)",
            privacyLevel: .public
          )
        )

        return .success(data)

      case let .failure(error):
        await logError(
          "Failed to export data: \(error)",
          context: logContext
        )
        return .failure(error)
    }
  }
}
