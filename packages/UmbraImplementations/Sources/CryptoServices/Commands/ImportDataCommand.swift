import CoreSecurityTypes
import CryptoInterfaces
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces

/**
 Command for importing external data into secure storage.

 This command implements secure import operations for cryptographic materials.
 It follows the Alpha Dot Five architecture principles with privacy-aware
 logging and strong error handling.
 */
public class ImportDataCommand: BaseCryptoCommand, CryptoCommand {
  /// The type of result returned by this command
  public typealias ResultType=String

  /// The data to import
  private let data: [UInt8]

  /// Optional predefined identifier for the imported data
  private let identifier: String?

  /**
   Initialises a new import data command.

   - Parameters:
      - data: The data to import
      - identifier: Optional predefined identifier for the imported data
      - secureStorage: Secure storage for cryptographic materials
      - logger: Optional logger for operation tracking and auditing
   */
  public init(
    data: [UInt8],
    identifier: String?=nil,
    secureStorage: SecureStorageProtocol,
    logger: LoggingProtocol?=nil
  ) {
    self.data=data
    self.identifier=identifier
    super.init(secureStorage: secureStorage, logger: logger)
  }

  /**
   Executes the import operation.

   - Parameters:
      - context: Logging context for the operation
      - operationID: Unique identifier for this operation instance
   - Returns: The identifier of the imported data
   */
  public func execute(
    context _: LogContextDTO,
    operationID: String
  ) async -> Result<String, SecurityStorageError> {
    // Create a log context with proper privacy classification
    let logContext=createLogContext(
      operation: "importData",
      correlationID: operationID,
      additionalMetadata: [
        "dataSize": (value: "\(data.count)", privacyLevel: .public)
      ]
    )

    await logDebug("Starting data import operation", context: logContext)

    // Generate a unique identifier if not provided
    let dataIdentifier=identifier ?? UUID().uuidString

    // Store the data in secure storage
    let storeResult=await secureStorage.storeData(data, withIdentifier: dataIdentifier)

    switch storeResult {
      case .success:
        let updatedContext = logContext.withMetadata(
          LogMetadataDTOCollection().withPrivate(
            key: "dataIdentifier", 
            value: dataIdentifier
          )
        )
        
        await logInfo(
          "Successfully imported \(data.count) bytes of data",
          context: updatedContext
        )

        return .success(dataIdentifier)

      case let .failure(error):
        await logError(
          "Failed to import data: \(error)",
          context: logContext
        )
        return .failure(error)
    }
  }
}
