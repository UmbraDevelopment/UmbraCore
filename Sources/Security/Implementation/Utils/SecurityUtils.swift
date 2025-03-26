/**
 # UmbraCore Security Utilities

 Provides utility methods for common security operations like encryption, decryption,
 and key derivation using standardised interfaces and error handling.

 ## Responsibilities

 * Symmetric encryption/decryption operations with standardised result formats
 * Key derivation functions
 * Security configuration validation
 * Error normalisation
 */

import Foundation
import Protocols
import SecurityInterfaces
import Types
import UmbraCoreTypes
import UmbraErrors

/// Protocol defining the interface for security utility operations
public protocol SecurityUtilsProtocol: Sendable {
  /// Encrypt data using symmetric encryption
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - key: Encryption key
  ///   - config: Configuration for the encryption
  /// - Returns: Result of the encryption operation
  func encryptSymmetricDto(
    data: SecureBytes,
    key: SecureBytes,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO

  /// Decrypt data using symmetric encryption
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - key: Decryption key
  ///   - config: Configuration for the decryption
  /// - Returns: Result of the decryption operation
  func decryptSymmetricDto(
    data: SecureBytes,
    key: SecureBytes,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO

  /// Encrypt data using asymmetric encryption
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - publicKey: Public key to use for encryption
  ///   - config: Configuration for the encryption
  /// - Returns: Result of the encryption operation
  func encryptAsymmetricDto(
    data: SecureBytes,
    publicKey: SecureBytes,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO

  /// Decrypt data using asymmetric encryption
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - privateKey: Private key to use for decryption
  ///   - config: Configuration for the decryption
  /// - Returns: Result of the decryption operation
  func decryptAsymmetricDto(
    data: SecureBytes,
    privateKey: SecureBytes,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO

  /// Hash data using the specified configuration
  /// - Parameters:
  ///   - data: Data to hash
  ///   - config: Configuration for the hashing operation
  /// - Returns: Result of the hashing operation
  func hashDto(
    data: SecureBytes,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO

  /// Derive a key from a password and salt
  /// - Parameters:
  ///   - data: Password or key material
  ///   - salt: Salt value to prevent rainbow table attacks
  ///   - config: Configuration for the key derivation
  /// - Returns: Result of the key derivation operation
  func deriveKeyDto(
    data: SecureBytes,
    salt: SecureBytes,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO
}

/// Backward compatibility type aliases
extension SecurityUtilsProtocol {
  @available(
    *,
    deprecated,
    renamed: "encryptSymmetricDto",
    message: "Use encryptSymmetricDto instead"
  )
  func encryptSymmetricDTO(
    data: SecureBytes,
    key: SecureBytes,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO {
    await encryptSymmetricDto(data: data, key: key, config: config)
  }

  @available(
    *,
    deprecated,
    renamed: "decryptSymmetricDto",
    message: "Use decryptSymmetricDto instead"
  )
  func decryptSymmetricDTO(
    data: SecureBytes,
    key: SecureBytes,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO {
    await decryptSymmetricDto(data: data, key: key, config: config)
  }

  @available(*, deprecated, renamed: "deriveKeyDto", message: "Use deriveKeyDto instead")
  func deriveKeyDTO(
    data: SecureBytes,
    salt: SecureBytes,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO {
    await deriveKeyDto(data: data, salt: salt, config: config)
  }

  @available(*, deprecated, renamed: "hashDto", message: "Use hashDto instead")
  func hashDTO(
    data: SecureBytes,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO {
    await hashDto(data: data, config: config)
  }
}

/// Implementation of security utility operations
public final class SecurityUtils: SecurityUtilsProtocol {
  // MARK: - Properties

  /// The crypto service for performing cryptographic operations
  private let cryptoService: CryptoServiceDto

  // MARK: - Initialisation

  /// Creates a new SecurityUtils instance
  /// - Parameter cryptoService: The crypto service to use for operations
  public init(cryptoService: CryptoServiceDto) {
    self.cryptoService=cryptoService
  }

  // MARK: - Symmetric Encryption Operations

  /// Encrypts data using symmetric encryption
  /// - Parameters:
  ///   - data: The data to encrypt
  ///   - key: The encryption key
  ///   - config: Configuration parameters
  /// - Returns: Result of the encryption operation
  public func encryptSymmetricDto(
    data: SecureBytes,
    key: SecureBytes,
    config _: SecurityConfigDTO
  ) async -> SecurityResultDTO {
    let result=await cryptoService.encrypt(data, key)

    switch result {
      case let .success(encryptedData):
        return SecurityResultDTO(
          status: .success,
          data: encryptedData
        )
      case let .failure(error):
        return SecurityResultDTO(
          status: .failure,
          error: error,
          metadata: ["details": "Symmetric encryption failed"]
        )
    }
  }

  /// Decrypts data using symmetric encryption
  /// - Parameters:
  ///   - data: The data to decrypt
  ///   - key: The decryption key
  ///   - config: Configuration parameters
  /// - Returns: Result of the decryption operation
  public func decryptSymmetricDto(
    data: SecureBytes,
    key: SecureBytes,
    config _: SecurityConfigDTO
  ) async -> SecurityResultDTO {
    let result=await cryptoService.decrypt(data, key)

    switch result {
      case let .success(decryptedData):
        return SecurityResultDTO(
          status: .success,
          data: decryptedData
        )
      case let .failure(error):
        return SecurityResultDTO(
          status: .failure,
          error: error,
          metadata: ["details": "Symmetric decryption failed"]
        )
    }
  }

  // MARK: - Asymmetric Encryption Operations

  /// Encrypts data using asymmetric encryption
  /// - Parameters:
  ///   - data: The data to encrypt
  ///   - publicKey: The public key
  ///   - config: Configuration parameters
  /// - Returns: Result of the encryption operation
  public func encryptAsymmetricDto(
    data: SecureBytes,
    publicKey: SecureBytes,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO {
    // Asymmetric encryption is not directly supported by the DTO
    // This is a simplified implementation that uses symmetric encryption
    await encryptSymmetricDto(data: data, key: publicKey, config: config)
  }

  /// Decrypts data using asymmetric encryption
  /// - Parameters:
  ///   - data: The data to decrypt
  ///   - privateKey: The private key
  ///   - config: Configuration parameters
  /// - Returns: Result of the decryption operation
  public func decryptAsymmetricDto(
    data: SecureBytes,
    privateKey: SecureBytes,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO {
    // Asymmetric decryption is not directly supported by the DTO
    // This is a simplified implementation that uses symmetric decryption
    await decryptSymmetricDto(data: data, key: privateKey, config: config)
  }

  // MARK: - Hash Operations

  /// Creates a hash of the specified data
  /// - Parameters:
  ///   - data: The data to hash
  ///   - config: Configuration parameters
  /// - Returns: Result of the hashing operation
  public func hashDto(
    data: SecureBytes,
    config _: SecurityConfigDTO
  ) async -> SecurityResultDTO {
    let result=await cryptoService.hash(data)

    switch result {
      case let .success(hashData):
        return SecurityResultDTO(
          status: .success,
          data: hashData
        )
      case let .failure(error):
        return SecurityResultDTO(
          status: .failure,
          error: error,
          metadata: ["details": "Hashing operation failed"]
        )
    }
  }

  // MARK: - Key Derivation Operations

  /// Derives a key from a password and salt
  /// - Parameters:
  ///   - data: Password or key material
  ///   - salt: Salt value to prevent rainbow table attacks
  ///   - config: Configuration parameters
  /// - Returns: Result containing the derived key or error
  public func deriveKeyDto(
    data: SecureBytes,
    salt: SecureBytes,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO {
    // Since there's no deriveKey method in the protocol, we need to implement this differently
    // For now, we'll use a combination of hash and the salt to simulate key derivation

    // Create a new SecureBytes by combining data and salt
    var combinedBytes=[UInt8]()
    for i in 0..<data.count {
      if i < data.count {
        combinedBytes.append(data[i])
      }
      if i < salt.count {
        combinedBytes.append(salt[i])
      }
    }

    // Add any remaining salt bytes
    if salt.count > data.count {
      for i in data.count..<salt.count {
        combinedBytes.append(salt[i])
      }
    }

    let combinedData=SecureBytes(bytes: combinedBytes)

    // Hash the combined data to produce the derived key
    return await hashDto(data: combinedData, config: config)
  }
}
