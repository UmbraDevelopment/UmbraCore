import CoreSecurityTypes
import CryptoInterfaces
import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces

/**
 Command for deriving a cryptographic key using a security provider.

 This command follows the Alpha Dot Five architecture principles with privacy-aware
 logging and strong error handling. It delegates the actual key derivation work to a
 SecurityProviderProtocol implementation.
 */
public class ProviderDeriveKeyCommand: BaseProviderCommand, ProviderCommand {
  /// The type of result returned by this command
  public typealias ResultType=CryptoKey

  /// The identifier of the source key
  private let sourceKeyIdentifier: String

  /// Optional salt for key derivation
  private let salt: [UInt8]?

  /// Optional context information for key derivation
  private let info: [UInt8]?

  /// The type of key to derive
  private let keyType: KeyType

  /// Optional identifier for the derived key
  private let targetIdentifier: String?

  /**
   Initialises a new provider derive key command.

   - Parameters:
      - sourceKeyIdentifier: The identifier of the source key
      - salt: Optional salt for key derivation
      - info: Optional context information for key derivation
      - keyType: The type of key to derive
      - targetIdentifier: Optional identifier for the derived key
      - provider: The security provider to use
      - secureStorage: The secure storage to use
      - logger: Optional logger for operation tracking
   */
  public init(
    sourceKeyIdentifier: String,
    salt: [UInt8]?=nil,
    info: [UInt8]?=nil,
    keyType: KeyType,
    targetIdentifier: String?=nil,
    provider: SecurityProviderProtocol,
    secureStorage: SecureStorageProtocol,
    logger: LoggingProtocol?=nil
  ) {
    self.sourceKeyIdentifier=sourceKeyIdentifier
    self.salt=salt
    self.info=info
    self.keyType=keyType
    self.targetIdentifier=targetIdentifier
    super.init(provider: provider, secureStorage: secureStorage, logger: logger)
  }

  /**
   Executes the key derivation operation.

   - Parameters:
      - context: Logging context for the operation
      - operationID: Unique identifier for this operation instance
   - Returns: The derived cryptographic key
   */
  public func execute(
    context _: LogContextDTO,
    operationID: String
  ) async -> Result<CryptoKey, SecurityStorageError> {
    // Create a log context with proper privacy classification
    let logContext=createLogContext(
      operation: "deriveKey",
      correlationID: operationID,
      additionalMetadata: [
        ("sourceKeyIdentifier", (value: sourceKeyIdentifier, privacyLevel: .private)),
        ("keyType", (value: keyType.rawValue, privacyLevel: .public)),
        ("saltProvided", (value: salt != nil ? "true" : "false", privacyLevel: .public)),
        ("infoProvided", (value: info != nil ? "true" : "false", privacyLevel: .public))
      ]
    )

    await logDebug("Starting provider key derivation operation", context: logContext)

    // Retrieve the source key
    let keyResult=await secureStorage.retrieveSecureData(identifier: sourceKeyIdentifier)

    switch keyResult {
      case let .success(sourceKeyData):
        // Generate a unique identifier if not provided
        let keyIdentifier=targetIdentifier ?? UUID().uuidString

        // Create configuration for the key derivation operation
        var additionalOptions: [String: Any]=[
          "sourceKey": sourceKeyData,
          "keyType": keyType.rawValue,
          "keyIdentifier": keyIdentifier
        ]

        // Add salt if provided
        if let salt {
          additionalOptions["salt"]=salt
        }

        // Add info if provided
        if let info {
          additionalOptions["info"]=info
        }

        let config=createSecurityConfig(
          operation: .deriveKey,
          additionalOptions: additionalOptions
        )

        do {
          // Execute the key derivation operation using the provider
          let result=try await provider.performSecureOperation(config: config)

          // Check if the operation was successful
          if result.successful, let derivedKeyData=result.resultData {
            // Store the derived key in secure storage
            let storeResult=await secureStorage.storeSecureData(
              derivedKeyData,
              identifier: keyIdentifier
            )

            switch storeResult {
              case .success:
                // Create the key object
                let key=CryptoKey(
                  identifier: keyIdentifier,
                  type: keyType,
                  size: defaultSizeForKeyType(keyType),
                  creationDate: Date()
                )

                await logInfo(
                  "Successfully derived \(keyType.rawValue) key",
                  context: logContext.adding(
                    key: "keyIdentifier",
                    value: keyIdentifier,
                    privacyLevel: .private
                  )
                )

                return .success(key)

              case let .failure(error):
                await logError(
                  "Failed to store derived key: \(error)",
                  context: logContext
                )
                return .failure(error)
            }
          } else {
            let error=createError(from: result)

            await logError(
              "Key derivation operation failed: \(error)",
              context: logContext
            )

            return .failure(error)
          }
        } catch {
          await logError(
            "Key derivation operation failed with exception: \(error.localizedDescription)",
            context: logContext
          )

          if let securityError=error as? SecurityStorageError {
            return .failure(securityError)
          } else {
            return .failure(
              .operationFailed("Key derivation failed: \(error.localizedDescription)")
            )
          }
        }

      case let .failure(error):
        await logError(
          "Failed to retrieve source key: \(error)",
          context: logContext
        )

        return .failure(error)
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
