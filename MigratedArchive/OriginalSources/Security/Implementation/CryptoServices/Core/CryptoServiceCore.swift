/**
 # CryptoServiceCore

 Provides core cryptographic service implementation that coordinates between specialised
 services. It delegates operations to the appropriate specialised components while
 providing a simplified interface to callers.

 ## Responsibilities

 * Route cryptographic operations to the appropriate specialised service
 * Provide a simplified interface for common operations
 * Handle error normalisation
 */

import ErrorHandlingDomains
import Foundation
import Protocols
import SecurityInterfaces
import UmbraCoreTypes
import UmbraErrors
import UmbraErrorsCore

/// Core service provider for cryptographic operations that coordinates specialised
/// services. It delegates operations to the appropriate specialised components while
/// providing a simplified interface to callers.
public final class CryptoServiceCore: CryptoServiceProtocol, Sendable {
  // MARK: - Properties

  /// Service for symmetric encryption operations
  private let symmetricCrypto: SymmetricCrypto

  /// Service for asymmetric encryption operations
  private let asymmetricCrypto: AsymmetricCrypto

  /// Service for hashing operations
  private let hashingService: HashingService

  /// Service for key generation
  private let keyGenerator: KeyGenerator

  // MARK: - Initialisation

  /// Creates a new crypto service coordinator
  init(
    symmetricCrypto: SymmetricCrypto=SymmetricCrypto(),
    asymmetricCrypto: AsymmetricCrypto=AsymmetricCrypto(),
    hashingService: HashingService=HashingService(),
    keyGenerator: KeyGenerator=KeyGenerator()
  ) {
    self.symmetricCrypto=symmetricCrypto
    self.asymmetricCrypto=asymmetricCrypto
    self.hashingService=hashingService
    self.keyGenerator=keyGenerator
  }

  // MARK: - CryptoServiceProtocol Implementation

  /// Encrypt data using the provided key
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - key: Encryption key
  /// - Returns: Encrypted data or error
  public func encrypt(
    data: SecureBytes,
    using key: SecureBytes
  ) async -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    // Use the symmetric crypto service with default configuration
    let result=await symmetricCrypto.encryptData(
      data: data,
      key: key,
      algorithm: "AES-GCM",
      iv: nil as SecureBytes?
    )
    if result.success, let encryptedData=result.data {
      return .success(encryptedData)
    } else {
      return .failure(
        UmbraErrors.Security.Protocols
          .encryptionFailed(result.errorMessage ?? "Unknown encryption error")
      )
    }
  }

  /// Decrypt data using the provided key
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - key: Decryption key
  /// - Returns: Decrypted data or error
  public func decrypt(
    data: SecureBytes,
    using key: SecureBytes
  ) async -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    // Use the symmetric crypto service with default configuration
    let result=await symmetricCrypto.decryptData(
      data: data,
      key: key,
      algorithm: "AES-GCM",
      iv: nil as SecureBytes?
    )
    if result.success, let decryptedData=result.data {
      return .success(decryptedData)
    } else {
      return .failure(
        UmbraErrors.Security.Protocols
          .decryptionFailed(result.errorMessage ?? "Unknown decryption error")
      )
    }
  }

  /// Generate a cryptographic key suitable for encryption/decryption operations.
  /// - Returns: A new cryptographic key as `SecureBytes` or an error.
  public func generateKey() async
  -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    // Generate a 256-bit AES key
    var keyBytes=[UInt8](repeating: 0, count: 32)
    let status=SecRandomCopyBytes(kSecRandomDefault, keyBytes.count, &keyBytes)

    guard status == errSecSuccess else {
      return .failure(
        UmbraErrors.Security.Protocols
          .internalError("Failed to generate random bytes: \(status)")
      )
    }

    return .success(SecureBytes(bytes: keyBytes))
  }

  /// Hashes the provided data using a cryptographically strong algorithm.
  /// - Parameter data: The data to hash as `SecureBytes`.
  /// - Returns: The resulting hash as `SecureBytes` or an error.
  public func hash(data: SecureBytes) async
  -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    // Use SHA-256 as the default algorithm
    await hash(data: data, config: Types.SecurityConfigDTO(algorithm: .aes, keySize: 256))
  }

  /// Verifies the integrity of data against a known hash.
  /// - Parameters:
  ///   - data: The data to verify as `SecureBytes`.
  ///   - hash: The expected hash value as `SecureBytes`.
  /// - Returns: Boolean indicating whether the hash matches.
  public func verify(data: SecureBytes, against hash: SecureBytes) async
  -> Result<Bool, UmbraErrors.Security.Protocols> {
    // Hash the data using SHA-256
    let hashResult=await self.hash(
      data: data,
      config: Types.SecurityConfigDTO(algorithm: .aes, keySize: 256)
    )

    switch hashResult {
      case let .success(computedHash):
        // Compare byte by byte since SecureBytes doesn't have a bytes property
        let match=(0..<min(computedHash.count, hash.count))
          .allSatisfy { computedHash[$0] == hash[$0] }
          && computedHash.count == hash.count
        return .success(match)
      case let .failure(error):
        return .failure(error)
    }
  }

  // MARK: - Extended API

  /// Encrypt data using symmetric encryption
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - key: Encryption key
  ///   - config: Configuration for the encryption
  /// - Returns: Result of the encryption operation
  public func encryptSymmetric(
    data: SecureBytes,
    key: SecureBytes,
    config: Types.SecurityConfigDTO
  ) async -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    let result=await symmetricCrypto.encryptData(
      data: data,
      key: key,
      algorithm: config.algorithm,
      iv: nil as SecureBytes?
    )

    if result.success, let encryptedData=result.data {
      return .success(encryptedData)
    } else {
      return .failure(
        UmbraErrors.Security.Protocols
          .encryptionFailed(result.errorMessage ?? "Unknown encryption error")
      )
    }
  }

  /// Decrypt data using symmetric encryption
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - key: Decryption key
  ///   - config: Configuration for the decryption
  /// - Returns: Result of the decryption operation
  public func decryptSymmetric(
    data: SecureBytes,
    key: SecureBytes,
    config: Types.SecurityConfigDTO
  ) async -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    let result=await symmetricCrypto.decryptData(
      data: data,
      key: key,
      algorithm: config.algorithm,
      iv: nil as SecureBytes?
    )

    if result.success, let decryptedData=result.data {
      return .success(decryptedData)
    } else {
      return .failure(
        UmbraErrors.Security.Protocols
          .decryptionFailed(result.errorMessage ?? "Unknown decryption error")
      )
    }
  }

  /// Hashes the provided data using a cryptographically strong algorithm.
  /// - Parameters:
  ///   - data: The data to hash as `SecureBytes`.
  ///   - config: Configuration options including algorithm selection
  /// - Returns: The resulting hash as `SecureBytes` or an error.
  public func hash(
    data: SecureBytes,
    config: Types.SecurityConfigDTO
  ) async -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    // Use the dedicated HashingService to hash the data
    let result=await hashingService.hashData(
      data: data,
      algorithm: config.algorithm
    )

    // Convert SecurityResultDTO to Result<SecureBytes,
    // UmbraErrors.Security.Protocols>
    if result.success, let hashedData=result.data {
      return .success(hashedData)
    } else {
      return .failure(
        UmbraErrors.Security.Protocols
          .internalError(result.errorMessage ?? "Unknown hashing error")
      )
    }
  }

  /// Encrypt data using asymmetric encryption
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - publicKey: Public key for encryption
  ///   - config: Encryption configuration
  /// - Returns: Result of the encryption operation
  func encryptAsymmetric(
    data: SecureBytes,
    publicKey: SecureBytes,
    config: Types.SecurityConfigDTO
  ) async -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    let result=await asymmetricCrypto.encrypt(
      data: data,
      publicKey: publicKey,
      algorithm: config.algorithm
    )

    // Convert SecurityResultDTO to Result<SecureBytes,
    // UmbraErrors.Security.Protocols>
    if result.success, let resultData=result.data {
      return .success(resultData)
    } else {
      return .failure(
        UmbraErrors.Security.Protocols
          .encryptionFailed(result.errorMessage ?? "Unknown encryption error")
      )
    }
  }

  /// Decrypt data using asymmetric encryption
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - privateKey: Private key for decryption
  ///   - config: Decryption configuration
  /// - Returns: Result of the decryption operation
  func decryptAsymmetric(
    data: SecureBytes,
    privateKey: SecureBytes,
    config: Types.SecurityConfigDTO
  ) async -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    let result=await asymmetricCrypto.decrypt(
      data: data,
      privateKey: privateKey,
      algorithm: config.algorithm
    )

    // Convert SecurityResultDTO to Result<SecureBytes,
    // UmbraErrors.Security.Protocols>
    if result.success, let resultData=result.data {
      return .success(resultData)
    } else {
      return .failure(
        UmbraErrors.Security.Protocols
          .decryptionFailed(result.errorMessage ?? "Unknown decryption error")
      )
    }
  }

  /// Generate a symmetric key
  /// - Returns: Generated key or error
  func generateSymmetricKey() async
  -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    do {
      // Generate a 256-bit AES key
      var keyBytes=[UInt8](repeating: 0, count: 32)
      let status=SecRandomCopyBytes(kSecRandomDefault, keyBytes.count, &keyBytes)

      guard status == errSecSuccess else {
        return .failure(
          UmbraErrors.Security.Protocols
            .internalError("Failed to generate random bytes: \(status)")
        )
      }
  }

  /// Verify a hash
  /// - Parameters:
  ///   - data: Data to verify
  ///   - hash: Hash to verify against
  /// - Returns: True if hash matches, false otherwise
  func verifyHash(
    data: SecureBytes,
    hash: SecureBytes
  ) async -> Result<Bool, UmbraErrors.Security.Protocols> {
    let hashResult=await self.hash(
      data: data,
      config: Types.SecurityConfigDTO(algorithm: .aes, keySize: 256)
    )

    switch hashResult {
      case let .success(computedHash):
        // Compare byte by byte since SecureBytes doesn't have a bytes property
        let match=(0..<min(computedHash.count, hash.count))
          .allSatisfy { computedHash[$0] == hash[$0] }
          && computedHash.count == hash.count
        return .success(match)
      case let .failure(error):
        return .failure(error)
    }
  }

  /// Generate random data
  /// - Parameter length: Length of random data in bytes
  /// - Returns: Random data or error
  func generateRandomData(length: Int) async
  -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    do {
      // Use SecRandomCopyBytes directly instead of CryptoWrapper
      var randomBytes=[UInt8](repeating: 0, count: length)
      let status=SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)

      guard status == errSecSuccess else {
        return .failure(
          UmbraErrors.Security.Protocols
            .internalError("Failed to generate random bytes: \(status)")
        )
      }
  }
}
