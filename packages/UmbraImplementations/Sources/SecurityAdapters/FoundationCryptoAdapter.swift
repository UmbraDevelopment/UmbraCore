/**
 # FoundationCryptoAdapter

 This adapter provides integration between UmbraCore's security interfaces and
 Foundation's cryptographic functionality. It allows Foundation-based applications
 to use UmbraCore security services with minimal integration effort.

 ## Responsibilities

 * Adapt UmbraCore security interfaces to Foundation types and patterns
 * Convert between Foundation data types and UmbraCore secure types
 * Handle error translation between systems
 * Provide convenience methods for common Foundation-based security operations
 */

import Foundation
import SecurityCoreInterfaces
import SecurityCoreTypes
import SecurityProviders
import SecurityTypes
import SecurityUtils
import UmbraErrors

/// Adapter that integrates UmbraCore's security interfaces with Foundation
public final class FoundationCryptoAdapter: Sendable {
  // MARK: - Properties

  /// The underlying security provider
  private let securityProvider: SecurityProviderProtocol

  // MARK: - Initialisation

  /// Create a new adapter with the specified security provider
  /// - Parameter securityProvider: The security provider to adapt
  public init(securityProvider: SecurityProviderProtocol=SecurityProviderImpl()) {
    self.securityProvider=securityProvider
  }

  // MARK: - Public API

  /// Encrypt data using the provided key
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - key: Key to use for encryption
  /// - Returns: Encrypted data
  public func encrypt(_ data: Data, using key: Data) async throws -> Data {
    let secureData=data.toSecureBytes()
    let secureKey=key.toSecureBytes()

    // Use defer to ensure secure data is zeroed after use
    defer {
      var keyCopy=secureKey
      MemoryProtection.secureZero(&keyCopy)
    }

    let resultDTO=await securityProvider.performSecureOperation(
      operation: .encrypt(data: secureData, key: secureKey),
      config: SecurityConfigDTO(
        keySize: 256,
        algorithm: .aes,
        mode: .gcm
      )
    )

    // Handle the result
    guard resultDTO.status == .success, let encryptedData=resultDTO.data else {
      throw CryptoError.encryptionFailed(
        resultDTO.error?.localizedDescription ?? "Encryption failed",
        context: CryptoErrorContext(
          operation: "encrypt",
          details: ["data": data.description, "key": key.description]
        )
      )
    }

    return encryptedData.toDataEfficient()
  }

  /// Decrypt data using the provided key
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - key: Key to use for decryption
  /// - Returns: Decrypted data
  public func decrypt(_ data: Data, using key: Data) async throws -> Data {
    let secureData=data.toSecureBytes()
    let secureKey=key.toSecureBytes()

    // Use defer to ensure secure data is zeroed after use
    defer {
      var keyCopy=secureKey
      MemoryProtection.secureZero(&keyCopy)
    }

    let resultDTO=await securityProvider.performSecureOperation(
      operation: .decrypt(data: secureData, key: secureKey),
      config: SecurityConfigDTO(
        keySize: 256,
        algorithm: .aes,
        mode: .gcm
      )
    )

    // Handle the result
    guard resultDTO.status == .success, let decryptedData=resultDTO.data else {
      throw CryptoError.decryptionFailed(
        resultDTO.error?.localizedDescription ?? "Decryption failed",
        context: CryptoErrorContext(
          operation: "decrypt",
          details: ["data": data.description, "key": key.description]
        )
      )
    }

    return decryptedData.toDataEfficient()
  }

  /// Computes a hash of the input data
  /// - Parameter data: Data to hash
  /// - Returns: Hash value of the data
  public func hash(_ data: Data) async throws -> Data {
    let secureData=data.toSecureBytes()

    let resultDTO=await securityProvider.performSecureOperation(
      operation: .hash(data: secureData, algorithm: .sha256),
      config: SecurityConfigDTO(
        keySize: 256,
        algorithm: .aes,
        hashAlgorithm: .sha256
      )
    )

    // Handle the result
    guard resultDTO.status == .success, let hashedData=resultDTO.data else {
      throw CryptoError.hashingFailed(
        resultDTO.error?.localizedDescription ?? "Hashing failed",
        context: CryptoErrorContext(operation: "hash", details: ["data": data.description])
      )
    }

    return hashedData.toDataEfficient()
  }

  /// Generates a random cryptographic key of the specified length
  /// - Parameter bitLength: Length of the key in bits
  /// - Returns: Generated key as Data
  public func generateKey(bitLength: Int=256) async throws -> Data {
    let resultDTO=await securityProvider.performSecureOperation(
      operation: .generateKey(size: bitLength),
      config: SecurityConfigDTO(
        keySize: bitLength,
        algorithm: .aes,
        mode: .gcm
      )
    )

    // Handle the result
    guard resultDTO.status == .success, let keyData=resultDTO.data else {
      throw CryptoError.keyGenerationFailed(
        resultDTO.error?.localizedDescription ?? "Key generation failed",
        context: CryptoErrorContext(
          operation: "generateKey",
          details: ["bitLength": "\(bitLength)"]
        )
      )
    }

    // Use memory protection to handle the key securely
    return MemoryProtection.withSecureTemporaryData([UInt8](keyData.toDataEfficient())) { bytes in
      Data(bytes)
    }
  }
}

/**
 * Context information for cryptographic operations
 */
public struct CryptoErrorContext: Sendable {
  public let operation: String
  public let details: [String: String]

  public init(operation: String, details: [String: String]=[:]) {
    self.operation=operation
    self.details=details
  }

  public var description: String {
    var result="Operation: \(operation)"
    if !details.isEmpty {
      result += ", Details: \(details)"
    }
    return result
  }
}

/**
 * Errors that can occur during cryptographic operations
 */
public enum CryptoError: Error, LocalizedError {
  case encryptionFailed(String, context: CryptoErrorContext?=nil)
  case decryptionFailed(String, context: CryptoErrorContext?=nil)
  case hashingFailed(String, context: CryptoErrorContext?=nil)
  case keyGenerationFailed(String, context: CryptoErrorContext?=nil)

  public var errorDescription: String? {
    switch self {
      case let .encryptionFailed(message, _):
        "Encryption failed: \(message)"
      case let .decryptionFailed(message, _):
        "Decryption failed: \(message)"
      case let .hashingFailed(message, _):
        "Hashing failed: \(message)"
      case let .keyGenerationFailed(message, _):
        "Key generation failed: \(message)"
    }
  }

  public var failureReason: String? {
    switch self {
      case let .encryptionFailed(_, context),
           let .decryptionFailed(_, context),
           let .hashingFailed(_, context),
           let .keyGenerationFailed(_, context):
        context?.description
    }
  }
}
