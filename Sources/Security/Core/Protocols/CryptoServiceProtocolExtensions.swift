import UmbraCoreTypes
import UmbraErrors
import Types

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
  public func encryptWithConfigurationDTO(
    data: SecureBytes,
    key: SecureBytes,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO {
    let result = await encryptWithConfiguration(
      data: data,
      key: key,
      config: config
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
  public func decryptWithConfigurationDTO(
    data: SecureBytes,
    key: SecureBytes,
    config: SecurityConfigDTO
  ) async -> SecurityResultDTO {
    let result = await decryptWithConfiguration(
      data: data,
      key: key,
      config: config
    )

    switch result {
      case let .success(decryptedData):
        return SecurityResultDTO(status: .success, data: decryptedData)
      case let .failure(error):
        return SecurityResultDTO(status: .failure, error: error)
    }
  }

  /// Hash data (SecurityResultDTO version)
  /// - Parameters:
  ///   - data: Data to hash
  /// - Returns: Result as SecurityResultDTO
  public func hashDTO(
    data: SecureBytes
  ) async -> SecurityResultDTO {
    let result = await hash(data: data)

    switch result {
      case let .success(hashValue):
        return SecurityResultDTO(status: .success, data: hashValue)
      case let .failure(error):
        return SecurityResultDTO(status: .failure, error: error)
    }
  }
}
