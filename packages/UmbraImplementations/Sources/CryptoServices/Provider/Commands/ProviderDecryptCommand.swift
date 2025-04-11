import CoreSecurityTypes
import CryptoInterfaces
import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces

/**
 Command for decrypting data using a security provider.

 This command follows the Alpha Dot Five architecture principles with privacy-aware
 logging and strong error handling. It delegates the actual decryption work to a
 SecurityProviderProtocol implementation.
 */
public class ProviderDecryptCommand: BaseProviderCommand, ProviderCommand {
  /// The type of result returned by this command
  public typealias ResultType=[UInt8]

  /// The encrypted data to decrypt
  private let data: [UInt8]

  /// The identifier of the decryption key
  private let keyIdentifier: String

  /// The encryption algorithm used
  private let algorithm: EncryptionAlgorithm

  /**
   Initialises a new provider decrypt command.

   - Parameters:
      - data: The encrypted data to decrypt
      - keyIdentifier: Identifier for the decryption key
      - algorithm: The encryption algorithm used
      - provider: The security provider to use
      - secureStorage: The secure storage to use
      - logger: Optional logger for operation tracking
   */
  public init(
    data: [UInt8],
    keyIdentifier: String,
    algorithm: EncryptionAlgorithm,
    provider: SecurityProviderProtocol,
    secureStorage: SecureStorageProtocol,
    logger: LoggingProtocol?=nil
  ) {
    self.data=data
    self.keyIdentifier=keyIdentifier
    self.algorithm=algorithm
    super.init(provider: provider, secureStorage: secureStorage, logger: logger)
  }

  /**
   Executes the decryption operation.

   - Parameters:
      - context: Logging context for the operation
      - operationID: Unique identifier for this operation instance
   - Returns: The decrypted data
   */
  public func execute(
    context _: LogContextDTO,
    operationID: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    // Create a log context with proper privacy classification
    let logContext=createLogContext(
      operation: "decrypt",
      algorithm: algorithm.rawValue,
      correlationID: operationID,
      additionalMetadata: [
        ("dataSize", (value: "\(data.count) bytes", privacyLevel: .public)),
        ("keyIdentifier", (value: keyIdentifier, privacyLevel: .private))
      ]
    )

    await logDebug("Starting provider decryption operation", context: logContext)

    // Retrieve the decryption key
    let keyResult=await secureStorage.retrieveSecureData(identifier: keyIdentifier)

    switch keyResult {
      case let .success(keyData):
        // Perform the decryption operation using the security provider

        // Create configuration for the decryption operation
        let config=createSecurityConfig(
          operation: .decrypt,
          algorithm: algorithm.rawValue,
          additionalOptions: [
            "inputData": data,
            "key": keyData,
            "keyIdentifier": keyIdentifier
          ]
        )

        do {
          // Execute the decryption operation using the provider
          let result=try await provider.decrypt(config: config)

          // Check if the operation was successful
          if result.successful, let decryptedData=result.resultData {
            await logInfo(
              "Successfully decrypted \(data.count) bytes of data",
              context: logContext
            )

            return .success(decryptedData)
          } else {
            let error=createError(from: result)

            await logError(
              "Decryption operation failed: \(error)",
              context: logContext
            )

            return .failure(error)
          }
        } catch {
          await logError(
            "Decryption operation failed with exception: \(error.localizedDescription)",
            context: logContext
          )

          if let securityError=error as? SecurityStorageError {
            return .failure(securityError)
          } else {
            return .failure(.operationFailed("Decryption failed: \(error.localizedDescription)"))
          }
        }

      case let .failure(error):
        await logError(
          "Failed to retrieve decryption key: \(error)",
          context: logContext
        )

        return .failure(error)
    }
  }
}
