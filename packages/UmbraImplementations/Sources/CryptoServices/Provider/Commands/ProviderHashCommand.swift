import CoreSecurityTypes
import CryptoInterfaces
import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces

/**
 Command for hashing data using a security provider.

 This command follows the Alpha Dot Five architecture principles with privacy-aware
 logging and strong error handling. It delegates the actual hashing work to a
 SecurityProviderProtocol implementation.
 */
public class ProviderHashCommand: BaseProviderCommand, ProviderCommand {
  /// The type of result returned by this command
  public typealias ResultType=[UInt8]

  /// The data to hash
  private let data: [UInt8]

  /// The hash algorithm to use
  private let algorithm: HashAlgorithm

  /**
   Initialises a new provider hash command.

   - Parameters:
      - data: The data to hash
      - algorithm: The hash algorithm to use
      - provider: The security provider to use
      - secureStorage: The secure storage to use
      - logger: Optional logger for operation tracking
   */
  public init(
    data: [UInt8],
    algorithm: HashAlgorithm,
    provider: SecurityProviderProtocol,
    secureStorage: SecureStorageProtocol,
    logger: LoggingProtocol?=nil
  ) {
    self.data=data
    self.algorithm=algorithm
    super.init(provider: provider, secureStorage: secureStorage, logger: logger)
  }

  /**
   Executes the hash operation.

   - Parameters:
      - context: Logging context for the operation
      - operationID: Unique identifier for this operation instance
   - Returns: The hash result
   */
  public func execute(
    context _: LogContextDTO,
    operationID: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    // Create a log context with proper privacy classification
    let logContext=createLogContext(
      operation: "hash",
      algorithm: algorithm.rawValue,
      correlationID: operationID,
      additionalMetadata: [
        ("dataSize", (value: "\(data.count) bytes", privacyLevel: .public))
      ]
    )

    await logDebug("Starting provider hash operation", context: logContext)

    // Perform the hash operation using the security provider

    // Create configuration for the hash operation
    let config=createSecurityConfig(
      operation: .hash,
      algorithm: algorithm.rawValue,
      additionalOptions: [
        "inputData": data
      ]
    )

    do {
      // Execute the hash operation using the provider
      let result=try await provider.performSecureOperation(
        operation: .hash,
        config: config
      )

      // Check if the operation was successful
      if result.successful, let hashData=result.resultData {
        await logInfo(
          "Successfully hashed \(data.count) bytes of data",
          context: logContext
        )

        // Convert Data to [UInt8] for the result
        return .success([UInt8](hashData))
      } else {
        let error=createError(from: result)

        await logError(
          "Hash operation failed: \(error)",
          context: logContext
        )

        return .failure(error)
      }
    } catch {
      await logError(
        "Hash operation failed with exception: \(error.localizedDescription)",
        context: logContext
      )

      if let securityError=error as? SecurityStorageError {
        return .failure(securityError)
      } else {
        return .failure(.operationFailed("Hash operation failed: \(error.localizedDescription)"))
      }
    }
  }
}
