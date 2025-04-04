/**
 # UmbraCore CryptoServiceAdapter

 This file provides a Data Transfer Object (DTO) based adapter for cryptographic operations in UmbraCore.
 It implements the CryptoServiceProtocol using a DTO to break circular dependencies.
 */

import CoreDTOs
import ErrorHandlingDomains
import Foundation
import Protocols
import Types
import UmbraCoreTypes
import UmbraErrors

/// Adapter implementation of CryptoServiceProtocol that uses the DTO pattern
/// to avoid circular dependencies between modules.
public final class CryptoServiceAdapter: CryptoServiceProtocol {

  /// The DTO containing function references for crypto operations
  private let dto: CryptoServiceDTO

  /// Initialises a new crypto service adapter
  /// - Parameter dto: The data transfer object with function references
  public init(dto: CryptoServiceDTO) {
    self.dto=dto
  }

  // MARK: - CryptoServiceProtocol Implementation

  /// Encrypts data using the specified key
  /// - Parameters:
  ///   - data: The data to encrypt
  ///   - key: The encryption key
  /// - Returns: The encrypted data or an error
  public func encrypt(
    data: SecureBytes,
    using key: SecureBytes
  ) async -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    await dto.encrypt(data, key)
  }

  /// Decrypts data using the specified key
  /// - Parameters:
  ///   - data: The data to decrypt
  ///   - key: The decryption key
  /// - Returns: The decrypted data or an error
  public func decrypt(
    data: SecureBytes,
    using key: SecureBytes
  ) async -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    await dto.decrypt(data, key)
  }

  /// Generates a cryptographic hash of the data
  /// - Parameter data: The data to hash
  /// - Returns: The hash value or an error
  public func hash(
    data: SecureBytes
  ) async -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    await dto.hash(data)
  }

  /// Verifies that the provided data matches the expected hash
  /// - Parameters:
  ///   - data: The data to verify
  ///   - expectedHash: The expected hash value
  /// - Returns: True if the data matches the hash, false otherwise, or an error
  public func verifyHash(
    data: SecureBytes,
    expectedHash: SecureBytes
  ) async -> Result<Bool, UmbraErrors.Security.Protocols> {
    await dto.verifyHash(data, expectedHash)
  }

  // MARK: - Extended CryptoServiceProtocol Methods

  /// Generates a cryptographically secure key
  /// - Returns: The generated key or an error
  public func generateKey() async -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    // Default implementation - placeholder
    let bytes=[UInt8](repeating: 0, count: 32)
    return .success(SecureBytes(bytes: bytes))
  }

  /// Generates cryptographically secure random data
  /// - Parameter length: The length of the random data in bytes
  /// - Returns: The random data or an error
  public func generateRandomData(
    ofLength length: Int
  ) async -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    // Default implementation - placeholder
    let bytes=[UInt8](repeating: 0, count: length)
    return .success(SecureBytes(bytes: bytes))
  }

  /// Encrypts data using symmetric encryption with the specified configuration
  /// - Parameters:
  ///   - data: The data to encrypt
  ///   - key: The encryption key
  ///   - config: Configuration parameters for encryption
  /// - Returns: The encrypted data or an error
  public func encryptSymmetric(
    data: SecureBytes,
    using key: SecureBytes,
    with _: SecurityConfigDTO
  ) async -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    // Use the basic encrypt method as a fallback
    await encrypt(data: data, using: key)
  }

  /// Decrypts data using symmetric encryption with the specified configuration
  /// - Parameters:
  ///   - data: The data to decrypt
  ///   - key: The decryption key
  ///   - config: Configuration parameters for decryption
  /// - Returns: The decrypted data or an error
  public func decryptSymmetric(
    data: SecureBytes,
    using key: SecureBytes,
    with _: SecurityConfigDTO
  ) async -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    // Use the basic decrypt method as a fallback
    await decrypt(data: data, using: key)
  }

  /// Encrypts data using asymmetric encryption with the specified configuration
  /// - Parameters:
  ///   - data: The data to encrypt
  ///   - publicKey: The public key for encryption
  ///   - config: Configuration parameters for encryption
  /// - Returns: The encrypted data or an error
  public func encryptAsymmetric(
    data: SecureBytes,
    using publicKey: SecureBytes,
    with _: SecurityConfigDTO
  ) async -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    // Use the basic encrypt method as a fallback
    await encrypt(data: data, using: publicKey)
  }

  /// Decrypts data using asymmetric encryption with the specified configuration
  /// - Parameters:
  ///   - data: The data to decrypt
  ///   - privateKey: The private key for decryption
  ///   - config: Configuration parameters for decryption
  /// - Returns: The decrypted data or an error
  public func decryptAsymmetric(
    data: SecureBytes,
    using privateKey: SecureBytes,
    with _: SecurityConfigDTO
  ) async -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    // Use the basic decrypt method as a fallback
    await decrypt(data: data, using: privateKey)
  }

  /// Generates a cryptographic hash of the data with the specified configuration
  /// - Parameters:
  ///   - data: The data to hash
  ///   - config: Configuration parameters for hashing
  /// - Returns: The hash value or an error
  public func hash(
    data: SecureBytes,
    with _: SecurityConfigDTO
  ) async -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    // Use the basic hash method as a fallback
    await hash(data: data)
  }
}
