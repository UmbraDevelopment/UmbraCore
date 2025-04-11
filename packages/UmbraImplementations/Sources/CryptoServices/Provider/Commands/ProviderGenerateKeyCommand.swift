import CoreSecurityTypes
import CryptoInterfaces
import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces

/**
 Command for generating a cryptographic key using a security provider.

 This command follows the Alpha Dot Five architecture principles with privacy-aware
 logging and strong error handling. It delegates the actual key generation work to a
 SecurityProviderProtocol implementation.
 */
public class ProviderGenerateKeyCommand: BaseProviderCommand, ProviderCommand {
  /// The type of result returned by this command
  public typealias ResultType=CryptoKey

  /// The type of key to generate
  private let keyType: KeyType

  /// Optional key size in bits
  private let size: Int?

  /// Optional predefined identifier for the key
  private let identifier: String?

  /**
   Initialises a new provider generate key command.

   - Parameters:
      - keyType: The type of key to generate
      - size: Optional key size in bits
      - identifier: Optional predefined identifier for the key
      - provider: The security provider to use
      - secureStorage: The secure storage to use
      - logger: Optional logger for operation tracking
   */
  public init(
    keyType: KeyType,
    size: Int?=nil,
    identifier: String?=nil,
    provider: SecurityProviderProtocol,
    secureStorage: SecureStorageProtocol,
    logger: LoggingProtocol?=nil
  ) {
    self.keyType=keyType
    self.size=size
    self.identifier=identifier
    super.init(provider: provider, secureStorage: secureStorage, logger: logger)
  }

  /**
   Executes the key generation operation.

   - Parameters:
      - context: Logging context for the operation
      - operationID: Unique identifier for this operation instance
   - Returns: The generated cryptographic key
   */
  public func execute(
    context _: LogContextDTO,
    operationID: String
  ) async -> Result<CryptoKey, SecurityStorageError> {
    // Create a log context with proper privacy classification
    let logContext=createLogContext(
      operation: "generateKey",
      correlationID: operationID,
      additionalMetadata: [
        ("keyType", (value: keyType.rawValue, privacyLevel: .public)),
        ("keySize", (value: size != nil ? "\(size!)" : "default", privacyLevel: .public)),
        ("identifierProvided", (value: identifier != nil ? "true" : "false", privacyLevel: .public))
      ]
    )

    await logDebug("Starting provider key generation operation", context: logContext)

    // Generate a unique identifier if not provided
    let keyIdentifier=identifier ?? UUID().uuidString

    // Create configuration for the key generation operation
    let config=createSecurityConfig(
      operation: .generateKey,
      additionalOptions: [
        "keyType": keyType.rawValue,
        "keyIdentifier": keyIdentifier
      ]
    )

    // Add key size if provided
    if let size {
      var options=config.options
      options.metadata?["keySize"]=size
      _=SecurityConfigDTO(options: options)
    }

    do {
      // Execute the key generation operation using the provider
      let result=try await provider.performSecureOperation(config: config)

      // Check if the operation was successful
      if result.successful, let keyData=result.resultData {
        // Store the generated key in secure storage
        let storeResult=await secureStorage.storeSecureData(keyData, identifier: keyIdentifier)

        switch storeResult {
          case .success:
            // Create the key object
            let actualSize=size ?? defaultSizeForKeyType(keyType)
            let key=CryptoKey(
              identifier: keyIdentifier,
              type: keyType,
              size: actualSize,
              creationDate: Date()
            )

            await logInfo(
              "Successfully generated \(keyType.rawValue) key",
              context: logContext.adding(
                key: "keyIdentifier",
                value: keyIdentifier,
                privacyLevel: .private
              )
            )

            return .success(key)

          case let .failure(error):
            await logError(
              "Failed to store generated key: \(error)",
              context: logContext
            )
            return .failure(error)
        }
      } else {
        let error=createError(from: result)

        await logError(
          "Key generation operation failed: \(error)",
          context: logContext
        )

        return .failure(error)
      }
    } catch {
      await logError(
        "Key generation operation failed with exception: \(error.localizedDescription)",
        context: logContext
      )

      if let securityError=error as? SecurityStorageError {
        return .failure(securityError)
      } else {
        return .failure(.operationFailed("Key generation failed: \(error.localizedDescription)"))
      }
    }
  }

  /**
   Returns the default size for a key type if not specified.

   - Parameter keyType: The type of key
   - Returns: The default size in bits
   */
  private func defaultSizeForKeyType(_ keyType: KeyType) -> Int {
    switch keyType {
      case .aes128:
        128
      case .aes256:
        256
      case .hmacSHA256:
        256
      case .hmacSHA512:
        512
      case .ecdsaP256:
        256
      case .ecdsaP384:
        384
      case .ecdsaP521:
        521
      case .rsaEncryption, .rsaSignature:
        2048
    }
  }
}
