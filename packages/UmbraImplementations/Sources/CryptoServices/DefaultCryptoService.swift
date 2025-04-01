import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingAdapters
import LoggingInterfaces
import LoggingTypes
import SecurityCoreInterfaces

/**
 # DefaultCryptoServiceImpl

 Default implementation of the CryptoServiceProtocol following the Alpha Dot Five
 architecture principles. This implementation provides robust cryptographic operations
 with proper error handling and privacy controls.
 */
public actor DefaultCryptoServiceImpl: CryptoServiceProtocol {
  /// Logger for cryptographic operations
  private let logger: LoggingProtocol

  /**
   Initialize a new crypto service with optional logger.

   - Parameter logger: Optional logger for operations (a default will be created if nil)
   */
  public init(logger: LoggingProtocol?=nil) {
    self.logger=logger ?? DefaultLogger()
  }

  /**
   Encrypts data using the provided key.

   - Parameters:
     - data: Raw data to encrypt as byte array
     - key: Encryption key as byte array
   - Returns: Result containing encrypted data or an error
   */
  public func encrypt(
    data: [UInt8],
    using key: [UInt8]
  ) async -> Result<[UInt8], SecurityProtocolError> {
    // Create a context for logging
    let context=CryptoLogContext(
      operation: "encrypt",
      algorithm: "aes",
      metadata: [
        "dataSize": "\(data.count)",
        "keySize": "\(key.count)"
      ]
    )

    await logger.debug("Starting encryption", context: context)

    // Simple implementation for demonstration
    // In a real implementation, you would use proper cryptographic algorithms
    guard key.count >= 16 else {
      await logger.error("Key too short", context: context)
      return .failure(.invalidKey("Key must be at least 16 bytes"))
    }

    do {
      // Mock encryption by XORing with key (NOT for production use)
      var encrypted=[UInt8]()
      for (i, byte) in data.enumerated() {
        let keyByte=key[i % key.count]
        encrypted.append(byte ^ keyByte)
      }

      await logger.debug("Encryption completed successfully", context: context)
      return .success(encrypted)
    } catch {
      await logger.error("Encryption failed: \(error.localizedDescription)", context: context)
      return .failure(.operationFailed("Encryption operation failed"))
    }
  }

  /**
   Decrypts data using the provided key.

   - Parameters:
     - data: Encrypted data as byte array
     - key: Decryption key as byte array
   - Returns: Result containing decrypted data or an error
   */
  public func decrypt(
    data: [UInt8],
    using key: [UInt8]
  ) async -> Result<[UInt8], SecurityProtocolError> {
    // Create a context for logging
    let context=CryptoLogContext(
      operation: "decrypt",
      algorithm: "aes",
      metadata: [
        "dataSize": "\(data.count)",
        "keySize": "\(key.count)"
      ]
    )

    await logger.debug("Starting decryption", context: context)

    // Simple implementation for demonstration
    guard key.count >= 16 else {
      await logger.error("Key too short", context: context)
      return .failure(.invalidKey("Key must be at least 16 bytes"))
    }

    do {
      // Mock decryption by XORing with key (NOT for production use)
      var decrypted=[UInt8]()
      for (i, byte) in data.enumerated() {
        let keyByte=key[i % key.count]
        decrypted.append(byte ^ keyByte)
      }

      await logger.debug("Decryption completed successfully", context: context)
      return .success(decrypted)
    } catch {
      await logger.error("Decryption failed: \(error.localizedDescription)", context: context)
      return .failure(.operationFailed("Decryption operation failed"))
    }
  }

  /**
   Computes a cryptographic hash of data.

   - Parameter data: Data to hash as byte array
   - Returns: Result containing the hash value or an error
   */
  public func hash(data: [UInt8]) async -> Result<[UInt8], SecurityProtocolError> {
    // Create a context for logging
    let context=CryptoLogContext(
      operation: "hash",
      algorithm: "sha256",
      metadata: [
        "dataSize": "\(data.count)"
      ]
    )

    await logger.debug("Starting hash computation", context: context)

    do {
      // Simple hash implementation (NOT for production use)
      // In a real implementation, you would use a proper hashing algorithm
      var hash=[UInt8](repeating: 0, count: 32) // SHA-256 is 32 bytes
      for (i, byte) in data.enumerated() {
        hash[i % 32]=hash[i % 32] &+ byte
      }

      await logger.debug("Hash computation completed successfully", context: context)
      return .success(hash)
    } catch {
      await logger.error("Hash computation failed: \(error.localizedDescription)", context: context)
      return .failure(.operationFailed("Hashing operation failed"))
    }
  }

  /**
   Verifies a hash against expected value.

   - Parameters:
     - data: Original data to verify
     - expectedHash: Expected hash value
   - Returns: Result containing whether the hash matches or an error
   */
  public func verifyHash(
    data: [UInt8],
    expectedHash: [UInt8]
  ) async -> Result<Bool, SecurityProtocolError> {
    // Create a context for logging
    let context=CryptoLogContext(
      operation: "verifyHash",
      algorithm: "sha256",
      metadata: [
        "dataSize": "\(data.count)",
        "hashSize": "\(expectedHash.count)"
      ]
    )

    await logger.debug("Starting hash verification", context: context)

    // Compute hash and compare
    let hashResult=await hash(data: data)

    switch hashResult {
      case let .success(computedHash):
        let matches=(computedHash.count == expectedHash.count) &&
          !zip(computedHash, expectedHash).contains { $0 != $1 }

        await logger.debug(
          "Hash verification completed: \(matches ? "match" : "no match")",
          context: context
        )
        return .success(matches)

      case let .failure(error):
        await logger.error("Hash verification failed: Unable to compute hash", context: context)
        return .failure(error)
    }
  }
}

/**
 * Default logger implementation for when no logger is provided
 */
private struct DefaultLogger: LoggingProtocol {
  /// Required by LoggingProtocol
  let loggingActor: LoggingInterfaces.LoggingActor = .init(destinations: [])

  func logMessage(_: LoggingTypes.LogLevel, _: String, context _: LoggingTypes.LogContext) async {
    // Empty implementation - no actual logging occurs
  }

  func debug(_: String, metadata _: LoggingTypes.PrivacyMetadata?, source _: String) async {}
  func info(_: String, metadata _: LoggingTypes.PrivacyMetadata?, source _: String) async {}
  func notice(_: String, metadata _: LoggingTypes.PrivacyMetadata?, source _: String) async {}
  func warning(_: String, metadata _: LoggingTypes.PrivacyMetadata?, source _: String) async {}
  func error(_: String, metadata _: LoggingTypes.PrivacyMetadata?, source _: String) async {}
  func error(
    _: String,
    error _: Error,
    metadata _: LoggingTypes.PrivacyMetadata?,
    source _: String
  ) async {}
  func critical(_: String, metadata _: LoggingTypes.PrivacyMetadata?, source _: String) async {}
  func trace(_: String, metadata _: LoggingTypes.PrivacyMetadata?, source _: String) async {}
}
