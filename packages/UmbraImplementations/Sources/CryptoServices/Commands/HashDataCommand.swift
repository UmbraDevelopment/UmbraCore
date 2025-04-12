import CommonCrypto
import CoreSecurityTypes
import CryptoInterfaces
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import LoggingTypes
import Security
import SecurityCoreInterfaces

/**
 Command for computing cryptographic hashes.

 This command implements high-security hashing operations with multiple algorithm
 options. It follows the Alpha Dot Five architecture principles with privacy-aware
 logging and strong error handling.
 */
public class HashDataCommand: BaseCryptoCommand, CryptoCommand {
  /// The type of result returned by this command
  public typealias ResultType = [UInt8]

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
    salt: [UInt8]? = nil,
    secureStorage: SecureStorageProtocol,
    logger: LoggingProtocol? = nil
  ) {
    self.data = data
    self.algorithm = algorithm
    self.salt = salt
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
    context: LogContextDTO,
    operationID: String
  ) async -> Result<[UInt8], SecurityStorageError> {
    // Create an enhanced log context with proper privacy classification
    let logContext = CryptoLogContext(
      operation: "hash",
      algorithm: algorithm.rawValue,
      correlationID: operationID,
      additionalMetadata: [
        "dataSize": (value: "\(data.count)", privacyLevel: PrivacyLevel.public),
        "saltUsed": (value: salt != nil ? "true" : "false", privacyLevel: PrivacyLevel.public)
      ]
    )

    await logDebug("Starting hash operation", context: logContext)

    do {
      // Compute the hash based on the selected algorithm
      var hashResult: [UInt8]

      switch algorithm {
        case .sha256:
          // Apply salt if provided, otherwise use standard SHA-256
          if let salt, !salt.isEmpty {
            hashResult = try computeHMACSHA256Hash(data: data, key: salt)
          } else {
            hashResult = try computeSHA256Hash(data: data, salt: nil)
          }

        case .sha512:
          // Apply salt if provided, otherwise use standard SHA-512
          if let salt, !salt.isEmpty {
            hashResult = try computeHMACSHA512Hash(data: data, key: salt)
          } else {
            hashResult = try computeSHA512Hash(data: data, salt: nil)
          }
          
        case .blake2b:
          // Blake2b can incorporate a key (salt) directly
          hashResult = try computeBlake2bHash(data: data, key: salt)
          
        @unknown default:
          // Fallback to SHA-256 for any future algorithms
          await logWarning(
            "Unsupported hash algorithm '\(algorithm.rawValue)'. Falling back to SHA-256",
            context: logContext
          )
          hashResult = try computeSHA256Hash(data: data, salt: salt)
      }

      // Generate a unique identifier for the hash result
      let hashIdentifier = UUID().uuidString

      // Store the hash result in secure storage
      let storeResult = await secureStorage.storeData(
        hashResult,
        withIdentifier: hashIdentifier
      )

      switch storeResult {
        case .success:
          await logInfo(
            "Hash computation successful",
            context: logContext.withMetadata(
              LogMetadataDTOCollection().withPrivate(
                key: "hashIdentifier",
                value: hashIdentifier
              )
            )
          )
          return .success(hashResult)

        case let .failure(error):
          await logError(
            "Failed to store hash result: \(error.localizedDescription)",
            context: logContext
          )
          return .failure(error)
      }
    } catch {
      await logError(
        "Hash computation failed: \(error.localizedDescription)",
        context: logContext
      )
      return .failure(.operationFailed(error.localizedDescription))
    }
  }

  // MARK: - Hash Computation Implementations

  /**
   Computes a SHA-256 hash of the data.

   - Parameters:
      - data: The data to hash
      - salt: Optional salt to apply
   - Returns: The computed hash
   - Throws: Error if hashing fails
   */
  private func computeSHA256Hash(data: [UInt8], salt: [UInt8]?) throws -> [UInt8] {
    // Create a mutable data object
    var hashData = Data()

    // Apply salt if provided (prepend to data)
    if let salt {
      hashData.append(contentsOf: salt)
    }

    // Add the main data
    hashData.append(contentsOf: data)

    // Compute SHA-256 hash
    var hashBytes = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    hashData.withUnsafeBytes { dataBuffer in
      _ = CC_SHA256(dataBuffer.baseAddress, CC_LONG(hashData.count), &hashBytes)
    }

    return hashBytes
  }

  /**
   Computes a SHA-512 hash of the data.

   - Parameters:
      - data: The data to hash
      - salt: Optional salt to apply
   - Returns: The computed hash
   - Throws: Error if hashing fails
   */
  private func computeSHA512Hash(data: [UInt8], salt: [UInt8]?) throws -> [UInt8] {
    // Create a mutable data object
    var hashData = Data()

    // Apply salt if provided (prepend to data)
    if let salt {
      hashData.append(contentsOf: salt)
    }

    // Add the main data
    hashData.append(contentsOf: data)

    // Compute SHA-512 hash
    var hashBytes = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
    hashData.withUnsafeBytes { dataBuffer in
      _ = CC_SHA512(dataBuffer.baseAddress, CC_LONG(hashData.count), &hashBytes)
    }

    return hashBytes
  }

  /**
   Computes an HMAC-SHA256 hash of the data.

   - Parameters:
      - data: The data to hash
      - key: The key to use for HMAC
   - Returns: The computed HMAC hash
   - Throws: Error if HMAC computation fails
   */
  private func computeHMACSHA256Hash(data: [UInt8], key: [UInt8]) throws -> [UInt8] {
    var macOut = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    
    // Compute HMAC-SHA256
    CCHmac(
      CCHmacAlgorithm(kCCHmacAlgSHA256),
      key, key.count,
      data, data.count,
      &macOut
    )
    
    return macOut
  }

  /**
   Computes an HMAC-SHA512 hash of the data.

   - Parameters:
      - data: The data to hash
      - key: The key to use for HMAC
   - Returns: The computed HMAC hash
   - Throws: Error if HMAC computation fails
   */
  private func computeHMACSHA512Hash(data: [UInt8], key: [UInt8]) throws -> [UInt8] {
    var macOut = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
    
    // Compute HMAC-SHA512
    CCHmac(
      CCHmacAlgorithm(kCCHmacAlgSHA512),
      key, key.count,
      data, data.count,
      &macOut
    )
    
    return macOut
  }
  
  /**
   Computes a BLAKE2b hash of the data.

   - Parameters:
      - data: The data to hash
      - key: Optional key for keyed hashing
   - Returns: The computed hash
   - Throws: Error if hashing fails
   */
  private func computeBlake2bHash(data: [UInt8], key: [UInt8]?) throws -> [UInt8] {
    // Note: This is a placeholder. BLAKE2b is not natively supported in CommonCrypto.
    // In a real implementation, you'd use a library like CryptoSwift or call to a C library.
    
    // For now, simulate BLAKE2b with SHA-512 for the prototype
    if let key, !key.isEmpty {
      return try computeHMACSHA512Hash(data: data, key: key)
    } else {
      return try computeSHA512Hash(data: data, salt: nil)
    }
    
    // TODO: Replace with actual BLAKE2b implementation
  }
}
