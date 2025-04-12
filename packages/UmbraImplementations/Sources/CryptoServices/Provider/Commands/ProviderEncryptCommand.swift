import CoreSecurityTypes
import CryptoInterfaces
import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces

/**
 Command for encrypting data using a security provider.

 This command follows the Alpha Dot Five architecture principles with privacy-aware
 logging and strong error handling. It delegates the actual encryption work to a
 SecurityProviderProtocol implementation.
 */
public class ProviderEncryptCommand: BaseProviderCommand, ProviderCommand {
  /// The type of result returned by this command
  public typealias ResultType=[UInt8]

  /// The data to encrypt
  private let data: [UInt8]

  /// The identifier of the encryption key
  private let keyIdentifier: String

  /// The encryption algorithm to use
  private let algorithm: EncryptionAlgorithm

  /**
   Initialises a new provider encrypt command.

   - Parameters:
      - data: The data to encrypt
      - keyIdentifier: Identifier for the encryption key
      - algorithm: The encryption algorithm to use
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
   Executes the encryption operation.

   - Parameters:
      - context: Logging context for the operation
      - operationID: Unique identifier for this operation instance
   - Returns: The encrypted data
   */
  public func execute(
    context _: LogContextDTO,
    operationID: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    // Create a log context with proper privacy classification
    let logContext=createLogContext(
      operation: "encrypt",
      algorithm: algorithm.rawValue,
      correlationID: operationID,
      additionalMetadata: [
        ("dataSize", (value: "\(data.count) bytes", privacyLevel: PrivacyLevel.public)),
        ("keyIdentifier", (value: keyIdentifier, privacyLevel: PrivacyLevel.private))
      ]
    )

    await logDebug("Starting provider encryption operation", context: logContext)

    // Retrieve the encryption key
    let keyResult=await secureStorage.retrieveData(withIdentifier: keyIdentifier)

    switch keyResult {
      case let .success(keyData):
        // Perform the encryption operation using the security provider

        // Create configuration for the encryption operation
        let config=createSecurityConfig(
          operation: .encrypt,
          algorithm: algorithm.rawValue,
          additionalOptions: [
            "inputData": data,
            "key": keyData,
            "keyIdentifier": keyIdentifier
          ]
        )

        do {
          // Execute the encryption operation using the provider
          let result=try await provider.performSecureOperation(
            operation: .encrypt,
            config: config
          )

          // Check if the operation was successful
          if result.successful, let encryptedData=result.resultData {
            await logInfo(
              "Successfully encrypted \(data.count) bytes of data",
              context: logContext
            )

            return .success(encryptedData)
          } else {
            let error=createError(from: result)

            await logError(
              "Encryption operation failed: \(error)",
              context: logContext
            )

            return .failure(error)
          }
        } catch {
          await logError(
            "Encryption operation failed with exception: \(error.localizedDescription)",
            context: logContext
          )

          if let securityError=error as? SecurityStorageError {
            return .failure(securityError)
          } else {
            return .failure(.operationFailed("Encryption failed: \(error.localizedDescription)"))
          }
        }

      case let .failure(error):
        await logError(
          "Failed to retrieve encryption key: \(error)",
          context: logContext
        )

        return .failure(error)
    }
  }
}
