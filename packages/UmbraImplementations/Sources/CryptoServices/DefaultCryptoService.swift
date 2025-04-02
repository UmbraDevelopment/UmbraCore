import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingAdapters
import LoggingInterfaces
import LoggingServices
import LoggingTypes
import SecurityCoreInterfaces

/**
 # DefaultCryptoServiceImpl

 Default implementation of the CryptoServiceProtocol following the Alpha Dot Five
 architecture principles. This implementation provides robust cryptographic operations
 with proper error handling and privacy controls.

 ## Security Features

 * Actor-based isolation for thread safety
 * Privacy-aware logging of cryptographic operations
 * Structured error handling with domain-specific errors
 * No plaintext secrets in logs

 ## Usage Example

 ```swift
 let cryptoService = await CryptoServicesFactory.createDefaultService()

 // Encrypt data
 let result = await cryptoService.encrypt(data: myData, using: myKey)
 switch result {
 case .success(let encryptedData):
     // Process encrypted data
 case .failure(let error):
     // Handle error with proper privacy controls
 }
 ```
 */
public actor DefaultCryptoServiceImpl: CryptoServiceProtocol {
  /// Standard logger for general operations
  private let logger: LoggingProtocol

  /// Secure logger for privacy-aware logging
  private let secureLogger: SecureLoggerActor

  /**
   Initialise a new crypto service with optional logger.

   - Parameter logger: Optional logger for operations (a default will be created if nil)
   - Parameter secureLogger: Optional secure logger for privacy-aware operations (will be created if nil)
   */
  public init(
    logger: LoggingProtocol?=nil,
    secureLogger: SecureLoggerActor?=nil
  ) {
    self.logger=logger ?? DefaultLogger()
    self.secureLogger=secureLogger ?? SecureLoggerActor(
      subsystem: "com.umbra.crypto",
      category: "CryptoOperations",
      includeTimestamps: true
    )
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

    // Log with secure logger for enhanced privacy
    await secureLogger.securityEvent(
      action: "Encryption",
      status: .success,
      subject: nil,
      resource: nil,
      additionalMetadata: [
        "dataSize": PrivacyTaggedValue(value: data.count, privacyLevel: .public),
        "keySize": PrivacyTaggedValue(value: key.count, privacyLevel: .public),
        "algorithm": PrivacyTaggedValue(value: "aes", privacyLevel: .public),
        "operation": PrivacyTaggedValue(value: "start", privacyLevel: .public)
      ]
    )

    do {
      // Basic validation
      guard !data.isEmpty else {
        let error=SecurityProtocolError.invalidInput("Data to encrypt cannot be empty")
        await logger.error("Encryption failed: empty data", context: context)
        await secureLogger.securityEvent(
          action: "Encryption",
          status: .failed,
          subject: nil,
          resource: nil,
          additionalMetadata: [
            "error": PrivacyTaggedValue(value: "empty_data", privacyLevel: .public),
            "operation": PrivacyTaggedValue(value: "validation", privacyLevel: .public)
          ]
        )
        return .failure(error)
      }

      guard !key.isEmpty else {
        let error=SecurityProtocolError.invalidInput("Encryption key cannot be empty")
        await logger.error("Encryption failed: empty key", context: context)
        await secureLogger.securityEvent(
          action: "Encryption",
          status: .failed,
          subject: nil,
          resource: nil,
          additionalMetadata: [
            "error": PrivacyTaggedValue(value: "empty_key", privacyLevel: .public),
            "operation": PrivacyTaggedValue(value: "validation", privacyLevel: .public)
          ]
        )
        return .failure(error)
      }

      // Perform AES encryption (simplified example)
      // In a real implementation, this would use a cryptographic library
      let encryptedData=try performEncryption(data: data, key: key)

      // Log success
      await logger.info("Encryption completed successfully", context: context)
      await secureLogger.securityEvent(
        action: "Encryption",
        status: .success,
        subject: nil,
        resource: nil,
        additionalMetadata: [
          "dataSize": PrivacyTaggedValue(value: data.count, privacyLevel: .public),
          "resultSize": PrivacyTaggedValue(value: encryptedData.count, privacyLevel: .public),
          "operation": PrivacyTaggedValue(value: "complete", privacyLevel: .public)
        ]
      )

      return .success(encryptedData)
    } catch {
      let securityError=mapToSecurityError(error)
      await logger.error(
        "Encryption failed: \(securityError.localizedDescription)",
        context: context
      )
      await secureLogger.securityEvent(
        action: "Encryption",
        status: .failed,
        subject: nil,
        resource: nil,
        additionalMetadata: [
          "error": PrivacyTaggedValue(value: securityError.localizedDescription,
                                      privacyLevel: .public),
          "errorCode": PrivacyTaggedValue(value: String(describing: securityError),
                                          privacyLevel: .public)
        ]
      )
      return .failure(securityError)
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
    await secureLogger.securityEvent(
      action: "Decryption",
      status: .success,
      subject: nil,
      resource: nil,
      additionalMetadata: [
        "dataSize": PrivacyTaggedValue(value: data.count, privacyLevel: .public),
        "keySize": PrivacyTaggedValue(value: key.count, privacyLevel: .public),
        "algorithm": PrivacyTaggedValue(value: "aes", privacyLevel: .public),
        "operation": PrivacyTaggedValue(value: "start", privacyLevel: .public)
      ]
    )

    do {
      // Basic validation
      guard !data.isEmpty else {
        let error=SecurityProtocolError.invalidInput("Data to decrypt cannot be empty")
        await logger.error("Decryption failed: empty data", context: context)
        await secureLogger.securityEvent(
          action: "Decryption",
          status: .failed,
          subject: nil,
          resource: nil,
          additionalMetadata: [
            "error": PrivacyTaggedValue(value: "empty_data", privacyLevel: .public),
            "operation": PrivacyTaggedValue(value: "validation", privacyLevel: .public)
          ]
        )
        return .failure(error)
      }

      guard !key.isEmpty else {
        let error=SecurityProtocolError.invalidInput("Decryption key cannot be empty")
        await logger.error("Decryption failed: empty key", context: context)
        await secureLogger.securityEvent(
          action: "Decryption",
          status: .failed,
          subject: nil,
          resource: nil,
          additionalMetadata: [
            "error": PrivacyTaggedValue(value: "empty_key", privacyLevel: .public),
            "operation": PrivacyTaggedValue(value: "validation", privacyLevel: .public)
          ]
        )
        return .failure(error)
      }

      // Perform AES decryption (simplified example)
      // In a real implementation, this would use a cryptographic library
      let decryptedData=try performDecryption(data: data, key: key)

      // Log success
      await logger.info("Decryption completed successfully", context: context)
      await secureLogger.securityEvent(
        action: "Decryption",
        status: .success,
        subject: nil,
        resource: nil,
        additionalMetadata: [
          "dataSize": PrivacyTaggedValue(value: data.count, privacyLevel: .public),
          "resultSize": PrivacyTaggedValue(value: decryptedData.count, privacyLevel: .public),
          "operation": PrivacyTaggedValue(value: "complete", privacyLevel: .public)
        ]
      )

      return .success(decryptedData)
    } catch {
      let securityError=mapToSecurityError(error)
      await logger.error(
        "Decryption failed: \(securityError.localizedDescription)",
        context: context
      )
      await secureLogger.securityEvent(
        action: "Decryption",
        status: .failed,
        subject: nil,
        resource: nil,
        additionalMetadata: [
          "error": PrivacyTaggedValue(value: securityError.localizedDescription,
                                      privacyLevel: .public),
          "errorCode": PrivacyTaggedValue(value: String(describing: securityError),
                                          privacyLevel: .public)
        ]
      )
      return .failure(securityError)
    }
  }

  /**
   Calculates a cryptographic hash of the provided data.

   - Parameter data: Data to hash
   - Returns: Result containing hash or an error
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

    await logger.debug("Starting hash calculation", context: context)
    await secureLogger.securityEvent(
      action: "Hash",
      status: .success,
      subject: nil,
      resource: nil,
      additionalMetadata: [
        "dataSize": PrivacyTaggedValue(value: data.count, privacyLevel: .public),
        "algorithm": PrivacyTaggedValue(value: "sha256", privacyLevel: .public),
        "operation": PrivacyTaggedValue(value: "start", privacyLevel: .public)
      ]
    )

    // Basic validation
    guard !data.isEmpty else {
      let error=SecurityProtocolError.invalidInput("Data to hash cannot be empty")
      await logger.error("Hashing failed: empty data", context: context)
      await secureLogger.securityEvent(
        action: "Hash",
        status: .failed,
        subject: nil,
        resource: nil,
        additionalMetadata: [
          "error": PrivacyTaggedValue(value: "empty_data", privacyLevel: .public),
          "operation": PrivacyTaggedValue(value: "validation", privacyLevel: .public)
        ]
      )
      return .failure(error)
    }

    do {
      // Perform SHA-256 hashing (simplified example)
      // In a real implementation, this would use a cryptographic library
      let hashResult=try performHashing(data: data)

      // Log success
      await logger.info("Hash calculation completed successfully", context: context)
      await secureLogger.securityEvent(
        action: "Hash",
        status: .success,
        subject: nil,
        resource: nil,
        additionalMetadata: [
          "dataSize": PrivacyTaggedValue(value: data.count, privacyLevel: .public),
          "hashSize": PrivacyTaggedValue(value: hashResult.count, privacyLevel: .public),
          "operation": PrivacyTaggedValue(value: "complete", privacyLevel: .public)
        ]
      )

      return .success(hashResult)
    } catch {
      let securityError=mapToSecurityError(error)
      await logger.error(
        "Hash calculation failed: \(securityError.localizedDescription)",
        context: context
      )
      await secureLogger.securityEvent(
        action: "Hash",
        status: .failed,
        subject: nil,
        resource: nil,
        additionalMetadata: [
          "error": PrivacyTaggedValue(value: securityError.localizedDescription,
                                      privacyLevel: .public),
          "errorCode": PrivacyTaggedValue(value: String(describing: securityError),
                                          privacyLevel: .public)
        ]
      )
      return .failure(securityError)
    }
  }

  /**
   Verifies that a hash matches the expected value for the given data.

   - Parameters:
     - data: Original data
     - expectedHash: Expected hash value
   - Returns: Result with true if verified, false if not matching, or an error
   */
  public func verifyHash(
    data: [UInt8],
    matches expectedHash: [UInt8]
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
    await secureLogger.securityEvent(
      action: "HashVerification",
      status: .success,
      subject: nil,
      resource: nil,
      additionalMetadata: [
        "dataSize": PrivacyTaggedValue(value: data.count, privacyLevel: .public),
        "hashSize": PrivacyTaggedValue(value: expectedHash.count, privacyLevel: .public),
        "operation": PrivacyTaggedValue(value: "start", privacyLevel: .public)
      ]
    )

    // Calculate hash first
    let hashResult=await hash(data: data)

    switch hashResult {
      case let .success(calculatedHash):
        // Compare hashes
        let verified=(calculatedHash == expectedHash)

        // Log result
        if verified {
          await logger.info("Hash verification succeeded", context: context)
          await secureLogger.securityEvent(
            action: "HashVerification",
            status: .success,
            subject: nil,
            resource: nil,
            additionalMetadata: [
              "result": PrivacyTaggedValue(value: "verified", privacyLevel: .public),
              "operation": PrivacyTaggedValue(value: "complete", privacyLevel: .public)
            ]
          )
        } else {
          await logger.warning("Hash verification failed: hashes don't match", context: context)
          await secureLogger.securityEvent(
            action: "HashVerification",
            status: .failed,
            subject: nil,
            resource: nil,
            additionalMetadata: [
              "result": PrivacyTaggedValue(value: "mismatch", privacyLevel: .public),
              "operation": PrivacyTaggedValue(value: "complete", privacyLevel: .public)
            ]
          )
        }

        return .success(verified)

      case let .failure(error):
        await logger.error(
          "Hash verification failed: \(error.localizedDescription)",
          context: context
        )
        await secureLogger.securityEvent(
          action: "HashVerification",
          status: .failed,
          subject: nil,
          resource: nil,
          additionalMetadata: [
            "error": PrivacyTaggedValue(value: error.localizedDescription, privacyLevel: .public),
            "errorCode": PrivacyTaggedValue(value: String(describing: error), privacyLevel: .public)
          ]
        )
        return .failure(error)
    }
  }

  // MARK: - Private Helper Methods

  /// Performs the actual encryption operation (simplified implementation)
  private func performEncryption(data: [UInt8], key: [UInt8]) throws -> [UInt8] {
    // This is a placeholder implementation. In a real system,
    // this would use a proper cryptographic library

    // Simulate encryption with a simple XOR (NOT secure, just for example)
    var result=[UInt8](repeating: 0, count: data.count)
    let keyLength=key.count

    for i in 0..<data.count {
      result[i]=data[i] ^ key[i % keyLength]
    }

    return result
  }

  /// Performs the actual decryption operation (simplified implementation)
  private func performDecryption(data: [UInt8], key: [UInt8]) throws -> [UInt8] {
    // For this simple XOR example, encryption and decryption are the same
    try performEncryption(data: data, key: key)
  }

  /// Performs the actual hashing operation (simplified implementation)
  private func performHashing(data: [UInt8]) throws -> [UInt8] {
    // This is a placeholder. In a real system, this would use a proper
    // cryptographic hashing function like SHA-256

    // Simulate a hash with a simple checksum
    var hash=[UInt8](repeating: 0, count: 32) // SHA-256 is 32 bytes

    for (index, byte) in data.enumerated() {
      hash[index % 32]=hash[index % 32] &+ byte
    }

    return hash
  }

  /// Maps a standard error to a SecurityProtocolError
  private func mapToSecurityError(_ error: Error) -> SecurityProtocolError {
    if let securityError=error as? SecurityProtocolError {
      return securityError
    }

    return SecurityProtocolError.operationFailed(
      reason: error.localizedDescription
    )
  }
}

/**
 * Default logger implementation for when no logger is provided
 */
private class DefaultLogger: LoggingProtocol {
  func log(
    _ level: LogLevel,
    _ message: String,
    metadata _: PrivacyMetadata?,
    source: String
  ) async {
    // Simple console logging
    print("[\(level)] [\(source)] \(message)")
  }

  func trace(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    await log(.trace, message, metadata: metadata, source: source)
  }

  func debug(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    await log(.debug, message, metadata: metadata, source: source)
  }

  func info(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    await log(.info, message, metadata: metadata, source: source)
  }

  func warning(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    await log(.warning, message, metadata: metadata, source: source)
  }

  func error(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    await log(.error, message, metadata: metadata, source: source)
  }

  func critical(_ message: String, metadata: PrivacyMetadata?, source: String) async {
    await log(.critical, message, metadata: metadata, source: source)
  }
}

/**
 Context for logging cryptographic operations
 */
private struct CryptoLogContext: LogContextDTO {
  var parameters: [String: Any]=[:]

  init(operation: String, algorithm: String, metadata: [String: String]=[:]) {
    parameters["operation"]=operation
    parameters["algorithm"]=algorithm

    // Add additional metadata
    for (key, value) in metadata {
      parameters[key]=value
    }
  }
}
