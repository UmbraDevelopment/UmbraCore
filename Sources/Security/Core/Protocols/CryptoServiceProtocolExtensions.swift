/**
 # UmbraCore CryptoServiceProtocol Extensions

 This file provides extensions to the CryptoServiceProtocol to standardise common operations
 and simplify implementation of the protocol.
 */

import CoreDTOs
import ErrorHandlingDomains
import SecurityProtocolsCore
import Types
import UmbraCoreTypes
import UmbraErrors

// MARK: - DTO Extensions for CryptoServiceProtocol

/// These extensions provide DTO-based versions of the CryptoServiceProtocol methods
/// to provide a consistent interface with SecurityProvider
extension CryptoServiceProtocol {
  // MARK: - Encryption and Decryption

  /// Encrypt data using symmetric encryption (SecurityResultDTO version)
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - key: Key to use for encryption
  ///   - config: Configuration options
  /// - Returns: Result as SecurityResultDTO
  public func encryptWithConfigurationDto(
    data: SecureBytes,
    key: SecureBytes,
    config _: SecurityConfigDTO
  ) async -> SecurityResultDTO {
    // Use the simplified encrypt method instead of the removed encryptWithConfiguration
    let result=await encrypt(
      data: data,
      using: key
    )

    switch result {
      case let .success(encryptedData):
        return SecurityResultDTO(status: .success, data: encryptedData)
      case let .failure(error):
        return SecurityResultDTO(status: .failure, error: error)
    }
  }

  /// Decrypt data using symmetric encryption (SecurityResultDTO version)
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - key: Key to use for decryption
  ///   - config: Configuration options
  /// - Returns: Result as SecurityResultDTO
  public func decryptWithConfigurationDto(
    data: SecureBytes,
    key: SecureBytes,
    config _: SecurityConfigDTO
  ) async -> SecurityResultDTO {
    // Use the simplified decrypt method instead of the removed decryptWithConfiguration
    let result=await decrypt(
      data: data,
      using: key
    )

    switch result {
      case let .success(decryptedData):
        return SecurityResultDTO(status: .success, data: decryptedData)
      case let .failure(error):
        return SecurityResultDTO(status: .failure, error: error)
    }
  }

  // MARK: - Hashing

  /// Generate a hash of data (SecurityResultDTO version)
  /// - Parameters:
  ///   - data: Data to hash
  ///   - config: Configuration options
  /// - Returns: Result as SecurityResultDTO
  public func hashDto(
    data: SecureBytes,
    config _: SecurityConfigDTO
  ) async -> SecurityResultDTO {
    let result=await hash(data: data)

    switch result {
      case let .success(hashData):
        return SecurityResultDTO(status: .success, data: hashData)
      case let .failure(error):
        return SecurityResultDTO(status: .failure, error: error)
    }
  }

  /// Verify a hash against expected value (SecurityResultDTO version)
  /// - Parameters:
  ///   - data: Data to verify
  ///   - expectedHash: Expected hash value
  ///   - config: Configuration options
  /// - Returns: Result as SecurityResultDTO
  public func verifyHashDto(
    data: SecureBytes,
    expectedHash: SecureBytes,
    config _: SecurityConfigDTO
  ) async -> SecurityResultDTO {
    let result=await verifyHash(data: data, expectedHash: expectedHash)

    switch result {
      case .success:
        return SecurityResultDTO(status: .success, data: SecureBytes(bytes: []))
      case let .failure(error):
        return SecurityResultDTO(status: .failure, error: error)
    }
  }

  // MARK: - Deprecated Compatibility Methods

  /// Encrypt data using symmetric encryption (Legacy DTO method)
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - key: Key to use for encryption
  ///   - config: Configuration options
  /// - Returns: Result as SecurityResultDTO
  @available(*, deprecated, message: "Use encryptWithConfigurationDto instead")
  public func encryptWithConfigurationDTO(
    data: SecureBytes,
    key: SecureBytes,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO {
    await encryptWithConfigurationDto(data: data, key: key, config: config)
  }

  /// Decrypt data using symmetric encryption (Legacy DTO method)
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - key: Key to use for decryption
  ///   - config: Configuration options
  /// - Returns: Result as SecurityResultDTO
  @available(*, deprecated, message: "Use decryptWithConfigurationDto instead")
  public func decryptWithConfigurationDTO(
    data: SecureBytes,
    key: SecureBytes,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO {
    await decryptWithConfigurationDto(data: data, key: key, config: config)
  }

  /// Generate a hash of data (Legacy DTO method)
  /// - Parameters:
  ///   - data: Data to hash
  ///   - config: Configuration options
  /// - Returns: Result as SecurityResultDTO
  @available(*, deprecated, message: "Use hashDto instead")
  public func hashDTO(
    data: SecureBytes,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO {
    await hashDto(data: data, config: config)
  }

  /// Verify a hash against expected value (Legacy DTO method)
  /// - Parameters:
  ///   - data: Data to verify
  ///   - expectedHash: Expected hash value
  ///   - config: Configuration options
  /// - Returns: Result as SecurityResultDTO
  @available(*, deprecated, message: "Use verifyHashDto instead")
  public func verifyHashDTO(
    data: SecureBytes,
    expectedHash: SecureBytes,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO {
    await verifyHashDto(data: data, expectedHash: expectedHash, config: config)
  }
}
