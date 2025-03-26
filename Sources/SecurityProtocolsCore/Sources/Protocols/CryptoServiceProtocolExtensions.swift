import Errors
import SecurityProtocolsCore.DTOs
import UmbraCoreTypes
import UmbraErrors

// MARK: - DTO Extensions for CryptoServiceProtocol

/// These extensions provide DTO-based versions of the CryptoServiceProtocol methods
/// to provide a consistent interface with SecurityProvider
extension CryptoServiceProtocol {
  /// Encrypt data using symmetric encryption (SecurityResultDTO version)
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - key: Key to use for encryption
  ///   - config: Configuration options
  /// - Returns: Result as SecurityResultDTO
  public func encryptSymmetricDTO(
    data: SecureBytes,
    key: SecureBytes,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO {
    let result=await encryptSymmetric(
      data: data,
      key: key,
      algorithm: config.algorithm,
      nonce: config.nonce
    )

    switch result {
      case let .success(encryptedData):
        return SecurityResultDTO(data: encryptedData)
      case let .failure(error):
        return SecurityResultDTO(success: false, error: error)
    }
  }

  /// Decrypt data using symmetric encryption (SecurityResultDTO version)
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - key: Key to use for decryption
  ///   - config: Configuration options
  /// - Returns: Result as SecurityResultDTO
  public func decryptSymmetricDTO(
    data: SecureBytes,
    key: SecureBytes,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO {
    let result=await decryptSymmetric(
      data: data,
      key: key,
      algorithm: config.algorithm,
      nonce: config.nonce
    )

    switch result {
      case let .success(decryptedData):
        return SecurityResultDTO(data: decryptedData)
      case let .failure(error):
        return SecurityResultDTO(success: false, error: error)
    }
  }

  /// Encrypts data using an asymmetric key (SecurityResultDTO version)
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - publicKey: Public key for encryption
  ///   - config: Configuration options
  /// - Returns: Result as SecurityResultDTO
  public func encryptAsymmetricDTO(
    data: SecureBytes,
    publicKey: SecureBytes,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO {
    let result=await encryptAsymmetric(
      data: data,
      publicKey: publicKey,
      algorithm: config.algorithm
    )

    switch result {
      case let .success(encryptedData):
        return SecurityResultDTO(data: encryptedData)
      case let .failure(error):
        return SecurityResultDTO(success: false, error: error)
    }
  }
}
