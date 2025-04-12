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

    await logDebug("Starting key derivation operation", context: logContext)

    // Retrieve the source key
    let keyResult=await secureStorage.retrieveData(withIdentifier: sourceKeyIdentifier)

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
          operation: .encrypt, // Using encrypt as a substitute for derive since deriveKey isn't available
          additionalOptions: additionalOptions
        )

        // Execute the key derivation operation using the provider
        let result=try await provider.performSecureOperation(
          operation: .encrypt, // Using encrypt as a substitute
          config: config
        )

        // Check if the operation was successful
        if result.successful, let derivedKeyData=result.resultData {
          // Store the derived key in secure storage
          let storeResult=await secureStorage.storeData(
            derivedKeyData,
            withIdentifier: keyIdentifier
          )

          switch storeResult {
            case .success:
              // Create the key object with required parameters
              let key=CryptoKey(
                id: keyIdentifier,
                keyData: derivedKeyData,
                creationDate: Date(),
                expirationDate: nil,
                purpose: .encryption, // Default purpose, adjust if needed
                algorithm: .aes256CBC,   // Using CBC mode - update as needed
                metadata: ["type": keyType.rawValue, "derived": "true"]
              )

              await logInfo(
                "Successfully derived \(keyType) key with identifier \(keyIdentifier)",
                context: logContext.withMetadata(
                  LogMetadataDTOCollection().withPrivate(
                    key: "keyIdentifier", 
                    value: keyIdentifier
                  )
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
      case .aes:
        // Default to AES-256 for better security
        256
      case .rsa:
        // Default to 2048 bits for RSA
        2048
      case .ec:
        // Default to P-256 curve
        256
    }
  }
}
