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
      correlationID: operationID,
      additionalMetadata: [
        ("encryptedDataIdentifier", (value: encryptedDataIdentifier, privacyLevel: .public)),
        ("algorithm", (value: algorithm.rawValue, privacyLevel: .public))
      ]
    )

    await logDebug("Starting data decryption operation", context: logContext)

    // Retrieve the encrypted data
    let dataResult=await secureStorage.retrieveData(withIdentifier: encryptedDataIdentifier)

    switch dataResult {
      case let .success(encryptedData):
        // Verify the encrypted data has the minimum required size
        // [IV (16 bytes)][Encrypted Data (at least 1 byte)][Key ID Length (1 byte)][Key ID (at
        // least 1 byte)]
        guard encryptedData.count > 18 else {
          await logError(
            "Invalid encrypted data format: insufficient data length",
            context: logContext
          )
          return .failure(.operationFailed("Invalid encrypted data format"))
        }

        // Extract the IV (first 16 bytes)
        let iv=[UInt8](encryptedData[0..<16])

        // Extract the Key ID length (1 byte at the end minus the key ID itself)
        let keyIDLengthIndex=encryptedData.count - 1
        guard keyIDLengthIndex >= 16 else {
          await logError(
            "Invalid encrypted data format: cannot extract key ID length",
            context: logContext
          )
          return .failure(.operationFailed("Invalid encrypted data format"))
        }

        let keyIDLength=Int(encryptedData[encryptedData.count - 1])

        // Validate the key ID length is within acceptable range and the data has enough bytes
        guard keyIDLength > 0, encryptedData.count >= (17 + keyIDLength) else {
          await logError(
            "Invalid encrypted data format: invalid key ID length",
            context: logContext
          )
          return .failure(.operationFailed("Invalid encrypted data format"))
        }

        // Extract the key ID
        let keyIDStartIndex=encryptedData.count - 1 - keyIDLength
        let keyIDBytes=[UInt8](encryptedData[keyIDStartIndex..<(encryptedData.count - 1)])

        guard let keyIdentifier=String(bytes: keyIDBytes, encoding: .utf8) else {
          await logError(
            "Invalid encrypted data format: cannot decode key ID",
            context: logContext
          )
          return .failure(.operationFailed("Cannot decode key identifier"))
        }

        // Extract the actual encrypted data (between IV and Key ID)
        let encryptedContentEndIndex=keyIDStartIndex
        let encryptedContent=[UInt8](encryptedData[16..<encryptedContentEndIndex])

        // Update log context with key identifier
        let updatedContext=logContext.withMetadata(
          LogMetadataDTOCollection().withPrivate(
            key: "keyIdentifier",
            value: keyIdentifier
          ).withPublic(
            key: "dataSize",
            value: "\(encryptedContent.count)"
          )
        )

        // Retrieve the key using the extracted key identifier
        let keyResult=await secureStorage.retrieveData(withIdentifier: keyIdentifier)

        switch keyResult {
          case let .success(keyData):
            do {
              let decryptedData=try decryptData(
                data: encryptedContent,
                key: keyData,
                algorithm: algorithm
              )

              await logInfo(
                "Successfully decrypted \(encryptedContent.count) bytes of data",
                context: updatedContext.withMetadata(
                  LogMetadataDTOCollection().withPublic(
                    key: "resultSize",
                    value: "\(decryptedData.count)"
                  )
                )
              )

              return .success(decryptedData)

            } catch {
              await logError(
                "Data decryption failed: \(error.localizedDescription)",
                context: updatedContext
              )
              if let securityError=error as? SecurityStorageError {
                return .failure(securityError)
              } else {
                return .failure(.operationFailed("Decryption failed: \(error.localizedDescription)"))
              }
            }

          case let .failure(error):
            await logError(
              "Failed to retrieve key: \(error.localizedDescription)",
              context: updatedContext
            )
            return .failure(error)
        }

      case let .failure(error):
        await logError(
          "Failed to retrieve encrypted data: \(error.localizedDescription)",
          context: logContext
        )
        return .failure(error)
    }
  }

  // MARK: - Decryption Implementations

  /**
   Decrypts data using the specified algorithm.

   - Parameters:
      - data: The encrypted data
      - key: The decryption key
      - algorithm: The encryption algorithm used
   - Returns: The decrypted data
   - Throws: Error if decryption fails
   */
  private func decryptData(data: [UInt8], key: [UInt8], algorithm: EncryptionAlgorithm) throws -> [UInt8] {
    switch algorithm {
      case .aes256GCM:
        return try aesGCMDecrypt(data: data, key: key, iv: [UInt8]())

      case .aes256CBC:
        return try aesCBCDecrypt(data: data, key: key, iv: [UInt8]())

      case .chacha20Poly1305:
        return try chaCha20Poly1305Decrypt(data: data, key: key, nonce: [UInt8]())
    }
  }

  /**
   Decrypts data using AES-GCM algorithm.
   
   - Parameters:
     - data: Encrypted data
     - key: Decryption key
     - iv: Initialization vector
   - Returns: Decrypted data
   - Throws: Error if decryption fails
   */
  private func aesGCMDecrypt(data: [UInt8], key: [UInt8], iv: [UInt8]) throws -> [UInt8] {
    // For now, we'll throw an error to indicate this needs implementation
    throw SecurityStorageError.operationFailed("AES-GCM decryption not implemented")
  }

  /**
   Decrypts data using AES-CBC algorithm.
   
   - Parameters:
     - data: Encrypted data
     - key: Decryption key
     - iv: Initialization vector
   - Returns: Decrypted data
   - Throws: Error if decryption fails
   */
  private func aesCBCDecrypt(data: [UInt8], key: [UInt8], iv: [UInt8]) throws -> [UInt8] {
    guard iv.count == kCCBlockSizeAES128 else {
      throw SecurityStorageError.operationFailed("Invalid IV size for AES-CBC")
    }

    // Set up decryption parameters
    let dataLength=data.count
    let bufferSize=dataLength + kCCBlockSizeAES128
    var outputBuffer=[UInt8](repeating: 0, count: bufferSize)
    var outputLength=0

    // Perform AES-CBC decryption
    let status=CCCrypt(
      CCOperation(kCCDecrypt),
      CCAlgorithm(kCCAlgorithmAES),
      CCOptions(kCCOptionPKCS7Padding),
      key,
      min(key.count, kCCKeySizeAES256),
      iv,
      data,
      dataLength,
      &outputBuffer,
      bufferSize,
      &outputLength
    )

    guard status == kCCSuccess else {
      throw SecurityStorageError.operationFailed("AES-CBC decryption failed with status \(status)")
    }

    return Array(outputBuffer.prefix(outputLength))
  }

  /**
   Decrypts data using ChaCha20-Poly1305 algorithm.
   
   - Parameters:
     - data: Encrypted data
     - key: Decryption key
     - nonce: Nonce for the operation
   - Returns: Decrypted data
   - Throws: Error if decryption fails
   */
  private func chaCha20Poly1305Decrypt(data: [UInt8], key: [UInt8], nonce: [UInt8]) throws -> [UInt8] {
    // For now, we'll throw an error to indicate this needs implementation
    throw SecurityStorageError.operationFailed("ChaCha20-Poly1305 decryption not implemented")
  }
}
