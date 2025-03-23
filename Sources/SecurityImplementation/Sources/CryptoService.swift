/**
 # UmbraCore Crypto Service

 This file provides a concrete implementation of the CryptoServiceProtocol
 that serves as a facade for specialized cryptographic services.

 ## Design Pattern

 This class follows the Facade design pattern, providing a simplified interface for
 cryptographic operations by coordinating between specialized components:

 * CryptoServiceCore: Core coordinator between different cryptographic services
 * SymmetricCrypto: Handles symmetric encryption and decryption
 * HashingService: Handles hashing operations

 ## Security Considerations

 * All cryptographic operations use secure algorithms with proper parameters
 * Sensitive data is stored in SecureBytes containers to protect memory
 * Errors are reported with appropriate context but without sensitive details
 * Cryptographic operations follow relevant standards and best practices
 */

import CoreErrors
import ErrorHandlingDomains
import Foundation
import SecurityProtocolsCore
import UmbraCoreTypes

/// Implementation of the CryptoServiceProtocol that coordinates between specialized
/// cryptographic service components.
public final class CryptoService: CryptoServiceProtocol {
  // MARK: - Properties

  /// Core implementation that coordinates between specialized services
  private let serviceCore: CryptoServiceCore

  // MARK: - Initialisation

  /// Creates a new CryptoService with default configuration
  public init() {
    serviceCore=CryptoServiceCore()
  }

  /// Creates a new CryptoService with a custom service core (for testing)
  /// - Parameter serviceCore: The custom service core to use
  init(serviceCore: CryptoServiceCore) {
    self.serviceCore=serviceCore
  }

  // MARK: - Basic CryptoServiceProtocol Implementation

  /// Encrypts binary data using the provided key.
  /// - Parameters:
  ///   - data: The data to encrypt as `SecureBytes`.
  ///   - key: The encryption key as `SecureBytes`.
  /// - Returns: The encrypted data as `SecureBytes` or an error.
  public func encrypt(data: SecureBytes, using key: SecureBytes) async
  -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    // Use the default AES-GCM algorithm
    let config=SecurityConfigDTO(algorithm: "AES-GCM", keySizeInBits: 256)
    let result=await encryptSymmetricDTO(data: data, key: key, config: config)

    if result.success, let encryptedData=result.data {
      return .success(encryptedData)
    } else {
      return .failure(.encryptionFailed(result.errorMessage ?? "Unknown error"))
    }
  }

  /// Decrypts binary data using the provided key.
  /// - Parameters:
  ///   - data: The encrypted data as `SecureBytes`.
  ///   - key: The decryption key as `SecureBytes`.
  /// - Returns: The decrypted data as `SecureBytes` or an error.
  public func decrypt(data: SecureBytes, using key: SecureBytes) async
  -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    // Use the default AES-GCM algorithm
    let config=SecurityConfigDTO(algorithm: "AES-GCM", keySizeInBits: 256)
    let result=await decryptSymmetricDTO(data: data, key: key, config: config)

    if result.success, let decryptedData=result.data {
      return .success(decryptedData)
    } else {
      return .failure(.decryptionFailed(result.errorMessage ?? "Unknown error"))
    }
  }

  /// Generates a cryptographic key suitable for encryption/decryption operations.
  /// - Returns: A new cryptographic key as `SecureBytes` or an error.
  public func generateKey() async -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    // Generate a 256-bit AES key by default
    let config=SecurityConfigDTO(algorithm: "AES", keySizeInBits: 256)
    let result=await generateKeyDTO(config: config)

    if result.success, let key=result.data {
      return .success(key)
    } else {
      return .failure(.serviceError(
        result
          .errorMessage ?? "Unknown error (code: \(result.errorCode ?? -1))"
      ))
    }
  }

  /// Hashes the provided data using a cryptographically strong algorithm.
  /// - Parameter data: The data to hash as `SecureBytes`.
  /// - Returns: The resulting hash as `SecureBytes` or an error.
  public func hash(data: SecureBytes) async -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    // Use SHA-256 by default
    let config=SecurityConfigDTO(algorithm: "SHA-256", keySizeInBits: 256)
    let result=await hashDTO(data: data, config: config)

    if result.success, let hash=result.data {
      return .success(hash)
    } else {
      return .failure(.serviceError(
        result
          .errorMessage ?? "Unknown error (code: \(result.errorCode ?? -1))"
      ))
    }
  }

  /// Verifies the integrity of data against a known hash.
  /// - Parameters:
  ///   - data: The data to verify as `SecureBytes`.
  ///   - hash: The expected hash value as `SecureBytes`.
  /// - Returns: Boolean indicating whether the hash matches.
  public func verify(data: SecureBytes, against hash: SecureBytes) async
  -> Result<Bool, UmbraErrors.Security.Protocols> {
    // Hash the data
    let hashResult=await self.hash(data: data)

    switch hashResult {
      case let .success(computedHash):
        // Compare the computed hash with the provided hash
        let match=computedHash == hash
        return .success(match)
      case let .failure(error):
        return .failure(error)
    }
  }

  // MARK: - CryptoServiceProtocol Implementation

  /// Encrypts data using symmetric encryption with default configuration.
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - key: Encryption key
  /// - Returns: Result containing encrypted data or error
  public func encryptSymmetric(
    data: SecureBytes,
    key: SecureBytes
  ) async -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    await encryptSymmetric(
      data: data,
      key: key,
      config: SecurityConfigDTO(algorithm: "AES-GCM", keySizeInBits: 256)
    )
  }

  /// Encrypts data using symmetric encryption with the specified configuration.
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - key: Encryption key
  ///   - config: Encryption configuration
  /// - Returns: Result containing encrypted data or error
  public func encryptSymmetric(
    data: SecureBytes,
    key: SecureBytes,
    config: SecurityConfigDTO
  ) async -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    let dto=await encryptSymmetricDTO(data: data, key: key, config: config)

    if dto.success, let encryptedData=dto.data {
      return .success(encryptedData)
    } else {
      return .failure(.encryptionFailed(dto.errorMessage ?? "Unknown error"))
    }
  }

  /// Decrypts data using symmetric encryption with default configuration.
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - key: Decryption key
  /// - Returns: Result containing decrypted data or error
  public func decryptSymmetric(
    data: SecureBytes,
    key: SecureBytes
  ) async -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    await decryptSymmetric(
      data: data,
      key: key,
      config: SecurityConfigDTO(algorithm: "AES-GCM", keySizeInBits: 256)
    )
  }

  /// Decrypts data using symmetric encryption with the specified configuration.
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - key: Decryption key
  ///   - config: Decryption configuration
  /// - Returns: Result containing decrypted data or error
  public func decryptSymmetric(
    data: SecureBytes,
    key: SecureBytes,
    config: SecurityConfigDTO
  ) async -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    let dto=await decryptSymmetricDTO(data: data, key: key, config: config)

    if dto.success, let decryptedData=dto.data {
      return .success(decryptedData)
    } else {
      return .failure(.decryptionFailed(dto.errorMessage ?? "Unknown error"))
    }
  }

  /// Hashes data with specific configuration.
  /// - Parameters:
  ///   - data: Data to hash
  ///   - config: Configuration options including algorithm selection
  /// - Returns: Result containing hash or error
  public func hash(
    data: SecureBytes,
    config: SecurityConfigDTO
  ) async -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    let dto=await hashDTO(data: data, config: config)

    if dto.success, let hashData=dto.data {
      return .success(hashData)
    } else {
      return .failure(.serviceError(dto.errorMessage ?? "Unknown error"))
    }
  }

  /// Encrypts data using asymmetric encryption.
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - publicKey: Public key to use for encryption
  ///   - config: Configuration options
  /// - Returns: Result containing encrypted data or error
  public func encryptAsymmetric(
    data: SecureBytes,
    publicKey: SecureBytes,
    config: SecurityConfigDTO
  ) async -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    let dto=await encryptAsymmetricDTO(data: data, publicKey: publicKey, config: config)

    if dto.success, let encryptedData=dto.data {
      return .success(encryptedData)
    } else {
      return .failure(.encryptionFailed(dto.errorMessage ?? "Unknown error"))
    }
  }

  /// Decrypts data using asymmetric encryption.
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - privateKey: Private key to use for decryption
  ///   - config: Configuration options
  /// - Returns: Result containing decrypted data or error
  public func decryptAsymmetric(
    data: SecureBytes,
    privateKey: SecureBytes,
    config: SecurityConfigDTO
  ) async -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    let dto=await decryptAsymmetricDTO(data: data, privateKey: privateKey, config: config)

    if dto.success, let decryptedData=dto.data {
      return .success(decryptedData)
    } else {
      return .failure(.decryptionFailed(dto.errorMessage ?? "Unknown error"))
    }
  }

  /// Generates cryptographically secure random data.
  /// - Parameter length: The length of random data to generate in bytes
  /// - Returns: Result containing random data or error
  public func generateRandomData(length: Int) async
  -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    // Implement random data generation
    guard length > 0 else {
      return .failure(.invalidInput("Random data length must be greater than 0"))
    }

    var randomBytes=[UInt8](repeating: 0, count: length)
    let status=SecRandomCopyBytes(kSecRandomDefault, length, &randomBytes)

    if status == errSecSuccess {
      return .success(SecureBytes(bytes: randomBytes))
    } else {
      return .failure(.randomGenerationFailed("Failed to generate random data: \(status)"))
    }
  }

  // MARK: - Extended Cryptographic Operations

  /// Generate a cryptographic key with the specified configuration
  /// - Parameter config: Configuration for key generation
  /// - Returns: The generated key or error information
  public func generateKeyDTO(config _: SecurityConfigDTO) async -> SecurityResultDTO {
    // Generate a key using the core service
    let result=await serviceCore.generateKey()

    // Convert the result to SecurityResultDTO
    switch result {
      case let .success(key):
        return SecurityResultDTO(success: true, data: key)
      case let .failure(error):
        return SecurityResultDTO(errorCode: 500, errorMessage: "Key generation failed: \(error)")
    }
  }

  // MARK: - DTO Methods

  /// Encrypts data using symmetric encryption with DTO.
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - key: Encryption key
  ///   - config: Encryption configuration
  /// - Returns: DTO containing encrypted data or error information
  public func encryptSymmetricDTO(
    data: SecureBytes,
    key: SecureBytes,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO {
    await serviceCore.encryptSymmetricDTO(data: data, key: key, config: config)
  }

  /// Decrypts data using symmetric encryption with DTO.
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - key: Decryption key
  ///   - config: Decryption configuration
  /// - Returns: DTO containing decrypted data or error information
  public func decryptSymmetricDTO(
    data: SecureBytes,
    key: SecureBytes,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO {
    await serviceCore.decryptSymmetricDTO(data: data, key: key, config: config)
  }

  /// Hashes data with DTO.
  /// - Parameters:
  ///   - data: Data to hash
  ///   - config: Configuration options including algorithm selection
  /// - Returns: DTO containing hash or error
  public func hashDTO(
    data: SecureBytes,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO {
    // Convert Result to SecurityResultDTO
    let result=await serviceCore.hash(data: data, config: config)

    switch result {
      case let .success(hashData):
        return SecurityResultDTO(data: hashData)
      case let .failure(error):
        return SecurityResultDTO(
          success: false,
          error: error
        )
    }
  }

  /// Encrypts data using asymmetric encryption with DTO.
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - publicKey: Public key for encryption
  ///   - config: Configuration options
  /// - Returns: DTO containing encrypted data or error
  public func encryptAsymmetricDTO(
    data: SecureBytes,
    publicKey: SecureBytes,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO {
    // Convert Result to SecurityResultDTO
    let result=await serviceCore.encryptAsymmetric(data: data, publicKey: publicKey, config: config)

    switch result {
      case let .success(encryptedData):
        return SecurityResultDTO(data: encryptedData)
      case let .failure(error):
        return SecurityResultDTO(
          success: false,
          error: error
        )
    }
  }

  /// Decrypts data using asymmetric encryption with DTO.
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - privateKey: Private key for decryption
  ///   - config: Configuration options
  /// - Returns: DTO containing decrypted data or error
  public func decryptAsymmetricDTO(
    data: SecureBytes,
    privateKey: SecureBytes,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO {
    // Convert Result to SecurityResultDTO
    let result=await serviceCore.decryptAsymmetric(
      data: data,
      privateKey: privateKey,
      config: config
    )

    switch result {
      case let .success(decryptedData):
        return SecurityResultDTO(data: decryptedData)
      case let .failure(error):
        return SecurityResultDTO(
          success: false,
          error: error
        )
    }
  }
}
