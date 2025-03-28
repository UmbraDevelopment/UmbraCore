/**
 # CryptoServiceImpl

 Provides core cryptographic service implementation that coordinates between specialised
 services. It delegates operations to the appropriate specialised components while
 providing a simplified interface to callers.

 ## Responsibilities

 * Route cryptographic operations to the appropriate specialised service
 * Provide a simplified interface for common operations
 * Handle error normalisation
 */

import Foundation
import SecurityCoreInterfaces
import SecurityCoreTypes
import SecurityTypes
import UmbraErrors

/// Implementation of CryptoServiceProtocol that provides cryptographic operations
/// including encryption, decryption, hashing, and key generation.
public final class CryptoServiceImpl: CryptoServiceProtocol, Sendable {
  // MARK: - Properties

  /// Service for symmetric encryption operations
  private let symmetricCrypto: SymmetricCryptoService

  /// Service for hashing operations
  private let hashingService: HashingService

  // MARK: - Initialisation

  /// Private initializer with dependencies
  /// - Parameters:
  ///   - symmetricCrypto: Service for symmetric encryption operations
  ///   - hashingService: Service for hashing operations
  private init(
    symmetricCrypto: SymmetricCryptoService,
    hashingService: HashingService
  ) {
    self.symmetricCrypto=symmetricCrypto
    self.hashingService=hashingService
  }

  /// Factory method to create a CryptoServiceImpl instance
  /// - Returns: A new CryptoServiceImpl instance
  public static func createDefault() -> CryptoServiceImpl {
    CryptoServiceImpl(
      symmetricCrypto: SymmetricCryptoService(),
      hashingService: HashingService()
    )
  }

  // MARK: - CryptoServiceProtocol Implementation

  /// Encrypt data using the provided key
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - key: Key to use for encryption
  /// - Returns: Encrypted data or error
  public func encrypt(
    data: SecureBytes,
    using key: SecureBytes
  ) async -> Result<SecureBytes, SecurityProtocolError> {
    let config=SecurityConfigDTO(
      algorithm: .aes,
      mode: .gcm
    )
    return symmetricCrypto.encrypt(data: data, key: key, config: config)
  }

  /// Decrypt data using the provided key
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - key: Key to use for decryption
  /// - Returns: Decrypted data or error
  public func decrypt(
    data: SecureBytes,
    using key: SecureBytes
  ) async -> Result<SecureBytes, SecurityProtocolError> {
    let config=SecurityConfigDTO(
      algorithm: .aes,
      mode: .gcm
    )
    return symmetricCrypto.decrypt(data: data, key: key, config: config)
  }

  /// Hash data using the default algorithm (SHA-256)
  /// - Parameter data: Data to hash
  /// - Returns: Hashed data or error
  public func hash(
    data: SecureBytes
  ) async -> Result<SecureBytes, SecurityProtocolError> {
    // Use SHA-256 as the default algorithm
    hashingService.hash(data: data, algorithm: .sha256)
  }

  /// Verifies the integrity of data against a known hash.
  /// - Parameters:
  ///   - data: The data to verify as `SecureBytes`.
  ///   - expectedHash: The expected hash value as `SecureBytes`.
  /// - Returns: Boolean indicating whether the hash matches.
  public func verifyHash(data: SecureBytes, expectedHash: SecureBytes) async
  -> Result<Bool, SecurityProtocolError> {
    // Hash the data using SHA-256
    let hashResult=await hash(data: data)

    switch hashResult {
      case let .success(computedHash):
        // Compare the computed hash with the expected hash
        let match=(computedHash.count == expectedHash.count) &&
          (0..<computedHash.count).allSatisfy { computedHash[$0] == expectedHash[$0] }
        return .success(match)
      case let .failure(error):
        return .failure(error)
    }
  }
}
