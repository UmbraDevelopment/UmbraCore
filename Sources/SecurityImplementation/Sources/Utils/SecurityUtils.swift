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

import ErrorHandlingDomains
import Foundation
import SecurityProtocolsCore
import UmbraCoreTypes

/// Protocol defining the interface for security utility operations
public protocol SecurityUtilsProtocol: Sendable {
  /// Encrypt data using symmetric encryption
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - key: Encryption key
  ///   - config: Configuration for the encryption
  /// - Returns: Result of the encryption operation
  func encryptSymmetricDTO(
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
  func decryptSymmetricDTO(
    data: SecureBytes,
    key: SecureBytes,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO

  /// Encrypt data using asymmetric encryption
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - key: Encryption key
  ///   - config: Configuration for the encryption
  /// - Returns: Result of the encryption operation
  func encryptAsymmetricDTO(
    data: SecureBytes,
    key: SecureBytes,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO

  /// Decrypt data using asymmetric encryption
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - key: Decryption key
  ///   - config: Configuration for the decryption
  /// - Returns: Result of the decryption operation
  func decryptAsymmetricDTO(
    data: SecureBytes,
    key: SecureBytes,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO

  /// Generate a cryptographic hash of the input data
  /// - Parameters:
  ///   - data: Data to hash
  ///   - config: Configuration for the hashing operation
  /// - Returns: Result of the hashing operation
  func hashDataDTO(
    data: SecureBytes,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO

  /// Derive a key from input data
  /// - Parameters:
  ///   - data: Input data for key derivation
  ///   - salt: Salt value to use in derivation
  ///   - config: Configuration for the key derivation
  /// - Returns: Result of the key derivation operation
  func deriveKeyDTO(
    data: SecureBytes,
    salt: SecureBytes,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO
}

/// Provides utility methods for security operations
public final class SecurityUtils: SecurityUtilsProtocol {
  // MARK: - Properties

  /// The crypto service for performing cryptographic operations
  private let cryptoService: CryptoServiceProtocol

  // MARK: - Initialisation

  /// Creates a new security utilities service
  public init(cryptoService: CryptoServiceProtocol) {
    self.cryptoService=cryptoService
  }

  // MARK: - SecurityUtilsProtocol Implementation

  /// Encrypt data using symmetric encryption
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - key: Encryption key
  ///   - config: Configuration for the encryption
  /// - Returns: Result of the encryption operation
  public func encryptSymmetricDTO(
    data: SecureBytes,
    key: SecureBytes,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO {
    let result=await cryptoService.encryptSymmetric(
      data: data,
      key: key,
      config: config
    )

    switch result {
      case let .success(encryptedData):
        return SecurityResultDTO(success: true, data: encryptedData)
      case let .failure(error):
        return SecurityResultDTO(
          success: false,
          error: error,
          errorDetails: "Symmetric encryption failed"
        )
    }
  }

  /// Decrypt data using symmetric encryption
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - key: Decryption key
  ///   - config: Configuration for the decryption
  /// - Returns: Result of the decryption operation
  public func decryptSymmetricDTO(
    data: SecureBytes,
    key: SecureBytes,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO {
    let result=await cryptoService.decryptSymmetric(
      data: data,
      key: key,
      config: config
    )

    switch result {
      case let .success(decryptedData):
        return SecurityResultDTO(success: true, data: decryptedData)
      case let .failure(error):
        return SecurityResultDTO(
          success: false,
          error: error,
          errorDetails: "Symmetric decryption failed"
        )
    }
  }

  /// Encrypt data using asymmetric encryption
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - key: Encryption key
  ///   - config: Configuration for the encryption
  /// - Returns: Result of the encryption operation
  public func encryptAsymmetricDTO(
    data: SecureBytes,
    key: SecureBytes,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO {
    let result=await cryptoService.encryptAsymmetric(
      data: data,
      publicKey: key,
      config: config
    )

    switch result {
      case let .success(encryptedData):
        return SecurityResultDTO(success: true, data: encryptedData)
      case let .failure(error):
        return SecurityResultDTO(
          success: false,
          error: error,
          errorDetails: "Asymmetric encryption failed"
        )
    }
  }

  /// Decrypt data using asymmetric encryption
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - key: Decryption key
  ///   - config: Configuration for the decryption
  /// - Returns: Result of the decryption operation
  public func decryptAsymmetricDTO(
    data: SecureBytes,
    key: SecureBytes,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO {
    let result=await cryptoService.decryptAsymmetric(
      data: data,
      privateKey: key,
      config: config
    )

    switch result {
      case let .success(decryptedData):
        return SecurityResultDTO(success: true, data: decryptedData)
      case let .failure(error):
        return SecurityResultDTO(
          success: false,
          error: error,
          errorDetails: "Asymmetric decryption failed"
        )
    }
  }

  /// Generate a cryptographic hash of the input data
  /// - Parameters:
  ///   - data: Data to hash
  ///   - config: Configuration for the hashing operation
  /// - Returns: Result of the hashing operation
  public func hashDataDTO(
    data: SecureBytes,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO {
    let result=await cryptoService.hash(
      data: data,
      config: config
    )

    switch result {
      case let .success(hashData):
        return SecurityResultDTO(success: true, data: hashData)
      case let .failure(error):
        return SecurityResultDTO(
          success: false,
          error: error,
          errorDetails: "Hashing operation failed"
        )
    }
  }

  /// Derive a key from input data
  /// - Parameters:
  ///   - data: Input data for key derivation
  ///   - salt: Salt value to use in derivation
  ///   - config: Configuration for the key derivation
  /// - Returns: Result of the key derivation operation
  public func deriveKeyDTO(
    data: SecureBytes,
    salt: SecureBytes,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO {
    // Since there's no deriveKey method in the protocol, we need to implement this differently
    // For now, we'll use a combination of hash and the salt to simulate key derivation

    // Get raw bytes from SecureBytes objects
    var dataBytes=[UInt8]()
    for i in 0..<data.count {
      dataBytes.append(data[i])
    }

    var saltBytes=[UInt8]()
    for i in 0..<salt.count {
      saltBytes.append(salt[i])
    }

    // Combine the bytes
    var combinedBytes=dataBytes
    combinedBytes.append(contentsOf: saltBytes)

    // Create a new SecureBytes object with the combined data
    let saltedData=SecureBytes(bytes: combinedBytes)

    // Hash the combined data
    let result=await cryptoService.hash(
      data: saltedData,
      config: config
    )

    switch result {
      case let .success(derivedKey):
        return SecurityResultDTO(success: true, data: derivedKey)
      case let .failure(error):
        return SecurityResultDTO(
          success: false,
          error: error,
          errorDetails: "Key derivation failed"
        )
    }
  }
}
