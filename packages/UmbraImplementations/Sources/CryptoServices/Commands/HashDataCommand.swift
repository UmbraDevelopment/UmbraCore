import CommonCrypto
import CoreSecurityTypes
import CryptoInterfaces
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import Security

/**
 Command for computing cryptographic hashes.

 This command implements high-security hashing operations with multiple algorithm
 options. It follows the Alpha Dot Five architecture principles with privacy-aware
 logging and strong error handling.
 */
public class HashDataCommand: BaseCryptoCommand, CryptoCommand {
  /// The type of result returned by this command
  public typealias ResultType=[UInt8]

  /// The data to hash
  private let data: [UInt8]

  /// The hash algorithm to use
  private let algorithm: HashAlgorithm

  /// Optional salt for the hash
  private let salt: [UInt8]?

  /**
   Initialises a new hash data command.

   - Parameters:
      - data: The data to hash
      - algorithm: The hash algorithm to use
      - salt: Optional salt to apply to the hash
      - secureStorage: Secure storage for cryptographic materials
      - logger: Optional logger for operation tracking and auditing
   */
  public init(
    data: [UInt8],
    algorithm: HashAlgorithm = .sha256,
    salt: [UInt8]?=nil,
    secureStorage: SecureStorageProtocol,
    logger: LoggingProtocol?=nil
  ) {
    self.data=data
    self.algorithm=algorithm
    self.salt=salt
    super.init(secureStorage: secureStorage, logger: logger)
  }

  /**
   Executes the hash computation operation.

   - Parameters:
      - context: Logging context for the operation
      - operationID: Unique identifier for this operation instance
   - Returns: The computed hash
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
        "dataSize": (value: "\(data.count)", privacyLevel: .public),
        "saltUsed": (value: salt != nil ? "true" : "false", privacyLevel: .public)
      ]
    )

    await logDebug("Starting hash operation", context: logContext)

    do {
      // Compute the hash based on the selected algorithm
      var hashResult: [UInt8]

      switch algorithm {
        case .sha256:
          hashResult=try computeSHA256Hash(data: data, salt: salt)

        case .sha512:
          hashResult=try computeSHA512Hash(data: data, salt: salt)

        case .hmacSHA256:
          guard let salt, !salt.isEmpty else {
            await logError(
              "HMAC-SHA256 requires a key (salt)",
              context: logContext
            )
            return .failure(.operationFailed("HMAC-SHA256 requires a key"))
          }

          hashResult=try computeHMACSHA256Hash(data: data, key: salt)

        case .hmacSHA512:
          guard let salt, !salt.isEmpty else {
            await logError(
              "HMAC-SHA512 requires a key (salt)",
              context: logContext
            )
            return .failure(.operationFailed("HMAC-SHA512 requires a key"))
          }

          hashResult=try computeHMACSHA512Hash(data: data, key: salt)
      }

      await logInfo(
        "Successfully computed \(algorithm.rawValue) hash",
        context: logContext.adding(
          key: "hashSize",
          value: "\(hashResult.count)",
          privacyLevel: .public
        )
      )

      return .success(hashResult)

    } catch {
      await logError(
        "Hash operation failed: \(error.localizedDescription)",
        context: logContext
      )
      return .failure(.operationFailed("Hash operation failed: \(error.localizedDescription)"))
    }
  }

  // MARK: - Hash Implementations

  /**
   Computes a SHA-256 hash of the data.

   - Parameters:
      - data: The data to hash
      - salt: Optional salt to apply before hashing
   - Returns: The computed hash
   - Throws: Error if hashing fails
   */
  private func computeSHA256Hash(data: [UInt8], salt: [UInt8]?) throws -> [UInt8] {
    // Combine data with salt if provided
    let dataToHash: [UInt8]=if let salt, !salt.isEmpty {
      salt + data
    } else {
      data
    }

    // Allocate space for the hash result
    var hashBytes=[UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))

    // Compute SHA-256 hash
    _=dataToHash.withUnsafeBytes { dataBuffer in
      CC_SHA256(dataBuffer.baseAddress, CC_LONG(dataBuffer.count), &hashBytes)
    }

    return hashBytes
  }

  /**
   Computes a SHA-512 hash of the data.

   - Parameters:
      - data: The data to hash
      - salt: Optional salt to apply before hashing
   - Returns: The computed hash
   - Throws: Error if hashing fails
   */
  private func computeSHA512Hash(data: [UInt8], salt: [UInt8]?) throws -> [UInt8] {
    // Combine data with salt if provided
    let dataToHash: [UInt8]=if let salt, !salt.isEmpty {
      salt + data
    } else {
      data
    }

    // Allocate space for the hash result
    var hashBytes=[UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))

    // Compute SHA-512 hash
    _=dataToHash.withUnsafeBytes { dataBuffer in
      CC_SHA512(dataBuffer.baseAddress, CC_LONG(dataBuffer.count), &hashBytes)
    }

    return hashBytes
  }

  /**
   Computes an HMAC-SHA256 hash of the data.

   - Parameters:
      - data: The data to hash
      - key: The HMAC key
   - Returns: The computed hash
   - Throws: Error if hashing fails
   */
  private func computeHMACSHA256Hash(data: [UInt8], key: [UInt8]) throws -> [UInt8] {
    // Allocate space for the hash result
    var hashBytes=[UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))

    // Compute HMAC-SHA256
    _=key.withUnsafeBytes { keyBuffer in
      data.withUnsafeBytes { dataBuffer in
        CCHmac(
          CCHmacAlgorithm(kCCHmacAlgSHA256),
          keyBuffer.baseAddress,
          keyBuffer.count,
          dataBuffer.baseAddress,
          dataBuffer.count,
          &hashBytes
        )
      }
    }

    return hashBytes
  }

  /**
   Computes an HMAC-SHA512 hash of the data.

   - Parameters:
      - data: The data to hash
      - key: The HMAC key
   - Returns: The computed hash
   - Throws: Error if hashing fails
   */
  private func computeHMACSHA512Hash(data: [UInt8], key: [UInt8]) throws -> [UInt8] {
    // Allocate space for the hash result
    var hashBytes=[UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))

    // Compute HMAC-SHA512
    _=key.withUnsafeBytes { keyBuffer in
      data.withUnsafeBytes { dataBuffer in
        CCHmac(
          CCHmacAlgorithm(kCCHmacAlgSHA512),
          keyBuffer.baseAddress,
          keyBuffer.count,
          dataBuffer.baseAddress,
          dataBuffer.count,
          &hashBytes
        )
      }
    }

    return hashBytes
  }
}
