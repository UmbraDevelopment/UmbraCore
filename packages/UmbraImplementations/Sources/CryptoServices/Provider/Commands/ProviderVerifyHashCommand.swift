import CoreSecurityTypes
import CryptoInterfaces
import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces

/**
 Command for verifying a hash using a security provider.

 This command follows the Alpha Dot Five architecture principles with privacy-aware
 logging and strong error handling. It delegates the actual hash verification work to a
 SecurityProviderProtocol implementation.
 */
public class ProviderVerifyHashCommand: BaseProviderCommand, ProviderCommand {
  /// The type of result returned by this command
  public typealias ResultType=Bool

  /// The data to verify
  private let data: [UInt8]

  /// The expected hash value
  private let expectedHash: [UInt8]

  /// The hash algorithm to use
  private let algorithm: HashAlgorithm

  /**
   Initialises a new provider verify hash command.

   - Parameters:
      - data: The data to verify
      - expectedHash: The expected hash value
      - algorithm: The hash algorithm to use
      - provider: The security provider to use
      - secureStorage: The secure storage to use
      - logger: Optional logger for operation tracking
   */
  public init(
    data: [UInt8],
    expectedHash: [UInt8],
    algorithm: HashAlgorithm,
    provider: SecurityProviderProtocol,
    secureStorage: SecureStorageProtocol,
    logger: LoggingProtocol?=nil
  ) {
    self.data=data
    self.expectedHash=expectedHash
    self.algorithm=algorithm
    super.init(provider: provider, secureStorage: secureStorage, logger: logger)
  }

  /**
   Executes the hash verification operation.

   - Parameters:
      - context: Logging context for the operation
      - operationID: Unique identifier for this operation instance
   - Returns: The verification result (true if the hash matches, false otherwise)
   */
  public func execute(
    context _: LogContextDTO,
    operationID: String
  ) async -> Result<Bool, SecurityStorageError> {
    // Create a log context with proper privacy classification
    let logContext=createLogContext(
      operation: "verifyHash",
      algorithm: algorithm.rawValue,
      correlationID: operationID,
      additionalMetadata: [
        ("dataSize", (value: "\(data.count) bytes", privacyLevel: .public)),
        ("hashSize", (value: "\(expectedHash.count) bytes", privacyLevel: .public))
      ]
    )

    await logDebug("Starting provider hash verification operation", context: logContext)

    // Perform the hash verification operation using the security provider

    // Create configuration for the hash verification operation
    let config=createSecurityConfig(
      operation: .verify,
      algorithm: algorithm.rawValue,
      additionalOptions: [
        "inputData": data,
        "expectedHash": Data(expectedHash).base64EncodedString()
      ]
    )

    do {
      // Execute the hash verification operation using the provider
      let result=try await provider.performSecureOperation(
        operation: .verify,
        config: config
      )

      // Check if the operation was successful
      if result.successful {
        // For verification, the success flag is in the result data
        if
          let verificationData=result.resultData,
          let verificationString=String(data: Data(verificationData), encoding: .utf8),
          verificationString.lowercased() == "true"
        {

          await logInfo(
            "Hash verification succeeded",
            context: logContext
          )

          return .success(true)
        } else {
          await logInfo(
            "Hash verification failed - hash does not match",
            context: logContext
          )

          return .success(false)
        }
      } else {
        let error=createError(from: result)

        await logError(
          "Hash verification operation failed: \(error)",
          context: logContext
        )

        return .failure(error)
      }
    } catch {
      await logError(
        "Hash verification operation failed with exception: \(error.localizedDescription)",
        context: logContext
      )

      if let securityError=error as? SecurityStorageError {
        return .failure(securityError)
      } else {
        return .failure(.operationFailed("Hash verification failed: \(error.localizedDescription)"))
      }
    }
  }
}
