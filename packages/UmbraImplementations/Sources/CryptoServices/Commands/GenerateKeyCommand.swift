import CommonCrypto
import CoreSecurityTypes
import CryptoInterfaces
import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import Security
import SecurityCoreInterfaces

/**
 Command for generating cryptographic keys.

 This command handles secure key generation with proper entropy sourcing,
 logging and strong error handling.
 */
public class GenerateKeyCommand: BaseCryptoCommand, CryptoCommand {
  /// The type of result returned by this command
  public typealias ResultType=CryptoKey

  /// Custom error types for key generation operations
  public enum GenerationError: Error {
    case operationFailed(String)
    case invalidParameters(String)
  }

  // Inputs
  private let keyType: KeyType
  private let size: Int?
  private let identifier: String?

  /**
   Initialises a new key generation command.

   - Parameters:
     - keyType: The type of key to generate
     - size: Optional size of the key in bytes
     - identifier: Optional identifier for the generated key
     - secureStorage: Secure storage for the generated key
     - logger: Optional logger for operation tracking
   */
  public init(
    keyType: KeyType,
    size: Int?=nil,
    identifier: String?=nil,
    secureStorage: SecureStorageProtocol,
    logger: LoggingProtocol?=nil
  ) {
    self.keyType=keyType
    self.size=size
    self.identifier=identifier
    super.init(secureStorage: secureStorage, logger: logger)
  }

  /**
   Executes the key generation operation.

   - Parameters:
     - context: The logging context for this operation
     - operationID: Correlation ID for tracking the operation
   - Returns: The generated key or an error
   */
  public func execute(
    context _: LogContextDTO,
    operationID: String
  ) async -> Result<CryptoKey, SecurityStorageError> {
    let enhancedContext=CryptoLogContext(
      operation: "generateKey",
      correlationID: operationID,
      additionalMetadata: [
        "keyType": (keyType.rawValue, PrivacyLevel.public),
        "keySize": (size != nil ? "\(size!)" : "default", PrivacyLevel.public)
      ]
    )

    await logDebug("Generating new \(keyType.rawValue) key", context: enhancedContext)

    do {
      // Determine the appropriate key size based on key type
      let keySize: Int

      switch keyType {
        case .aes:
          keySize=size ?? 32 // Default to 256-bit (32 bytes)

          // Validate key size for AES (must be 16, 24, or 32 bytes)
          if ![16, 24, 32].contains(keySize) {
            await logError(
              "Invalid AES key size. Must be 128, 192, or 256 bits",
              context: enhancedContext
            )
            return .failure(.invalidParameters(
              "Invalid key size. AES keys must be 128, 192, or 256 bits"
            ))
          }

        case .rsa:
          // RSA key sizes are in bits, not bytes
          keySize=size ?? 256 // Default to 2048 bits (256 bytes)

          // Validate key size for RSA (minimum 2048 bits recommended)
          if keySize * 8 < 2048 {
            await logWarning(
              "RSA key size below recommended minimum of 2048 bits",
              context: enhancedContext
            )
          }

        case .ed25519:
          // Ed25519 has a fixed key size
          keySize=32

          if size != nil && size != 32 {
            await logWarning(
              "Ed25519 has a fixed key size of 32 bytes. Ignoring requested size",
              context: enhancedContext
            )
          }

        case .chacha20:
          keySize=size ?? 32 // Default to 256-bit (32 bytes)

          // Validate key size for ChaCha20
          if keySize != 32 {
            await logError(
              "Invalid ChaCha20 key size. Must be 256 bits",
              context: enhancedContext
            )
            return .failure(.invalidParameters(
              "Invalid key size. ChaCha20 keys must be 256 bits"
            ))
          }

        case .generic:
          keySize=size ?? 32 // Default to 256 bits
      }

      // Generate the key data with secure random source
      let keyData=try generateRandomBytes(count: keySize)

      // Create a unique identifier for the key if not provided
      let keyIdentifier=identifier ?? UUID().uuidString

      // Store the key in secure storage
      let storeResult=await secureStorage.storeData(keyData, withIdentifier: keyIdentifier)

      switch storeResult {
        case .success:
          let key=CryptoKey(
            id: keyIdentifier,
            type: keyType,
            size: keySize * 8, // Convert bytes to bits for the key size
            created: Date()
          )

          await logInfo(
            "Successfully generated \(keyType.rawValue) key with ID: \(keyIdentifier)",
            context: enhancedContext
          )

          return .success(key)

        case let .failure(error):
          await logError(
            "Failed to store generated key: \(error.localizedDescription)",
            context: enhancedContext
          )

          return .failure(error)
      }
    } catch {
      await logError(
        "Key generation error: \(error.localizedDescription)",
        context: enhancedContext
      )

      return .failure(.operationFailed(error.localizedDescription))
    }
  }

  // MARK: - Helper Methods

  /**
   Generates cryptographically secure random bytes.

   - Parameter count: Number of random bytes to generate
   - Returns: Array of random bytes
   - Throws: Error if random generation fails
   */
  private func generateRandomBytes(count: Int) throws -> [UInt8] {
    var randomBytes=[UInt8](repeating: 0, count: count)
    let result=SecRandomCopyBytes(kSecRandomDefault, count, &randomBytes)

    guard result == errSecSuccess else {
      throw GenerationError.operationFailed("Failed to generate secure random bytes")
    }

    return randomBytes
  }
}
