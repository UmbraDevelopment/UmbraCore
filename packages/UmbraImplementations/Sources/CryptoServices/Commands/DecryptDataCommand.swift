import CommonCrypto
import CoreSecurityTypes
import CryptoInterfaces
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import Security

/**
 Command for decrypting data using a specified key.

 This command implements high-security decryption operations. It follows the
 Alpha Dot Five architecture principles with privacy-aware logging and strong
 error handling.
 */
public class DecryptDataCommand: BaseCryptoCommand, CryptoCommand {
  /// The type of result returned by this command
  public typealias ResultType=[UInt8]

  /// The identifier of the encrypted data
  private let encryptedDataIdentifier: String

  /// The encryption algorithm to use (must match the one used for encryption)
  private let algorithm: EncryptionAlgorithm

  /**
   Initialises a new decrypt data command.

   - Parameters:
      - encryptedDataIdentifier: The identifier of the encrypted data
      - algorithm: The encryption algorithm used (must match encryption)
      - secureStorage: Secure storage for cryptographic materials
      - logger: Optional logger for operation tracking and auditing
   */
  public init(
    encryptedDataIdentifier: String,
    algorithm: EncryptionAlgorithm = .aes256GCM,
    secureStorage: SecureStorageProtocol,
    logger: LoggingProtocol?=nil
  ) {
    self.encryptedDataIdentifier=encryptedDataIdentifier
    self.algorithm=algorithm
    super.init(secureStorage: secureStorage, logger: logger)
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
        "dataIdentifier": (value: encryptedDataIdentifier, privacyLevel: .private)
      ]
    )

    await logDebug("Starting decryption operation", context: logContext)

    // Retrieve the encrypted data
    let dataResult=await secureStorage.retrieveSecureData(identifier: encryptedDataIdentifier)

    switch dataResult {
      case let .success(encryptedDataBytes):
        // Verify the encrypted data has the minimum required size
        // [IV (16 bytes)][Encrypted Data (at least 1 byte)][Key ID Length (1 byte)][Key ID (at
        // least 1 byte)]
        guard encryptedDataBytes.count > 18 else {
          await logError(
            "Invalid encrypted data format: insufficient data length",
            context: logContext
          )
          return .failure(.operationFailed("Invalid encrypted data format"))
        }

        // Extract the IV (first 16 bytes)
        let iv=[UInt8](encryptedDataBytes[0..<16])

        // Extract the Key ID length (1 byte at the end minus the key ID itself)
        let keyIDLengthIndex=encryptedDataBytes.count - 1
        guard keyIDLengthIndex >= 16 else {
          await logError(
            "Invalid encrypted data format: cannot extract key ID length",
            context: logContext
          )
          return .failure(.operationFailed("Invalid encrypted data format"))
        }

        let keyIDLength=Int(encryptedDataBytes[encryptedDataBytes.count - 1])

        // Validate the key ID length is within acceptable range and the data has enough bytes
        guard keyIDLength > 0, encryptedDataBytes.count >= (17 + keyIDLength) else {
          await logError(
            "Invalid encrypted data format: invalid key ID length",
            context: logContext
          )
          return .failure(.operationFailed("Invalid encrypted data format"))
        }

        // Extract the key ID
        let keyIDStartIndex=encryptedDataBytes.count - 1 - keyIDLength
        let keyIDBytes=[UInt8](encryptedDataBytes[keyIDStartIndex..<(encryptedDataBytes.count - 1)])

        guard let keyIdentifier=String(bytes: keyIDBytes, encoding: .utf8) else {
          await logError(
            "Invalid encrypted data format: cannot decode key ID",
            context: logContext
          )
          return .failure(.operationFailed("Cannot decode key identifier"))
        }

        // Extract the actual encrypted data (between IV and Key ID)
        let encryptedContentEndIndex=keyIDStartIndex
        let encryptedContent=[UInt8](encryptedDataBytes[16..<encryptedContentEndIndex])

        // Update log context with key identifier
        let updatedContext=logContext.adding(
          key: "keyIdentifier",
          value: keyIdentifier,
          privacyLevel: .private
        ).adding(
          key: "dataSize",
          value: "\(encryptedContent.count)",
          privacyLevel: .public
        )

        // Retrieve the key using the extracted key identifier
        let keyResult=await secureStorage.retrieveSecureData(identifier: keyIdentifier)

        switch keyResult {
          case let .success(keyData):
            do {
              // Decrypt the data based on the algorithm
              let decryptedData: [UInt8]

              switch algorithm {
                case .aes256GCM:
                  guard keyData.count == 32 else { // 256 bits = 32 bytes
                    await logError(
                      "Invalid key size for AES-256-GCM",
                      context: updatedContext
                    )
                    return .failure(.operationFailed("Key size mismatch for AES-256-GCM"))
                  }

                  decryptedData=try aesGCMDecrypt(data: encryptedContent, key: keyData, iv: iv)

                case .aes256CBC:
                  guard keyData.count == 32 else { // 256 bits = 32 bytes
                    await logError(
                      "Invalid key size for AES-256-CBC",
                      context: updatedContext
                    )
                    return .failure(.operationFailed("Key size mismatch for AES-256-CBC"))
                  }

                  decryptedData=try aesCBCDecrypt(data: encryptedContent, key: keyData, iv: iv)

                case .chacha20Poly1305:
                  guard keyData.count == 32 else { // 256 bits = 32 bytes
                    await logError(
                      "Invalid key size for ChaCha20-Poly1305",
                      context: updatedContext
                    )
                    return .failure(.operationFailed("Key size mismatch for ChaCha20-Poly1305"))
                  }

                  decryptedData=try chacha20Poly1305Decrypt(
                    data: encryptedContent,
                    key: keyData,
                    iv: iv
                  )
              }

              await logInfo(
                "Successfully decrypted \(encryptedContent.count) bytes of data",
                context: updatedContext.adding(
                  key: "resultSize",
                  value: "\(decryptedData.count)",
                  privacyLevel: .public
                )
              )

              return .success(decryptedData)

            } catch {
              await logError(
                "Decryption operation failed: \(error.localizedDescription)",
                context: updatedContext
              )
              return .failure(.operationFailed("Decryption failed: \(error.localizedDescription)"))
            }

          case let .failure(error):
            await logError(
              "Failed to retrieve decryption key: \(error)",
              context: updatedContext
            )
            return .failure(error)
        }

      case let .failure(error):
        await logError(
          "Failed to retrieve encrypted data: \(error)",
          context: logContext
        )
        return .failure(error)
    }
  }

  // MARK: - Decryption Implementations

  /**
   Decrypts data using AES-GCM.

   - Parameters:
      - data: The encrypted data
      - key: The decryption key
      - iv: The initialisation vector
   - Returns: The decrypted data
   - Throws: Error if decryption fails
   */
  private func aesGCMDecrypt(data _: [UInt8], key _: [UInt8], iv _: [UInt8]) throws -> [UInt8] {
    // AES-GCM would typically be implemented with CryptoKit or CommonCrypto
    // This is a simplified placeholder for the implementation

    // In a real implementation, this would:
    // 1. Set up the AES-GCM cipher for decryption
    // 2. Verify the authentication tag
    // 3. Decrypt the data if authenticated

    // For now, we'll throw an error to indicate this needs implementation
    throw SecurityStorageError.operationFailed("AES-GCM decryption not implemented")
  }

  /**
   Decrypts data using AES-CBC.

   - Parameters:
      - data: The encrypted data
      - key: The decryption key
      - iv: The initialisation vector
   - Returns: The decrypted data
   - Throws: Error if decryption fails
   */
  private func aesCBCDecrypt(data: [UInt8], key: [UInt8], iv: [UInt8]) throws -> [UInt8] {
    guard iv.count == kCCBlockSizeAES128 else {
      throw SecurityStorageError.operationFailed("Invalid IV size for AES-CBC")
    }

    // Create output buffer with enough space for the decrypted data
    let outputLength=data.count
    var outputBuffer=[UInt8](repeating: 0, count: outputLength)
    var resultLength=0

    // Perform decryption
    let status=CCCrypt(
      CCOperation(kCCDecrypt),
      CCAlgorithm(kCCAlgorithmAES),
      CCOptions(kCCOptionPKCS7Padding),
      key, key.count,
      iv,
      data, data.count,
      &outputBuffer, outputLength,
      &resultLength
    )

    guard status == kCCSuccess else {
      throw SecurityStorageError.operationFailed("AES-CBC decryption failed with status \(status)")
    }

    // Return only the actual decrypted bytes
    return [UInt8](outputBuffer[0..<resultLength])
  }

  /**
   Decrypts data using ChaCha20-Poly1305.

   - Parameters:
      - data: The encrypted data
      - key: The decryption key
      - iv: The initialisation vector
   - Returns: The decrypted data
   - Throws: Error if decryption fails
   */
  private func chacha20Poly1305Decrypt(
    data _: [UInt8],
    key _: [UInt8],
    iv _: [UInt8]
  ) throws -> [UInt8] {
    // ChaCha20-Poly1305 would typically be implemented with CryptoKit or CommonCrypto
    // This is a simplified placeholder for the implementation

    // In a real implementation, this would:
    // 1. Set up the ChaCha20-Poly1305 cipher for decryption
    // 2. Verify the authentication tag
    // 3. Decrypt the data if authenticated

    // For now, we'll throw an error to indicate this needs implementation
    throw SecurityStorageError.operationFailed("ChaCha20-Poly1305 decryption not implemented")
  }
}
