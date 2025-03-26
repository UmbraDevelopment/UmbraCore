import Errors // Import Errors module for SecurityProtocolError
import Protocols // Import for CryptoServiceProtocol
import SecurityProtocolsCore
import Types
import UmbraCoreTypes

/// Type-erased wrapper for CryptoServiceProtocol
/// This allows for cleaner interfaces without exposing implementation details
public final class AnyCryptoService: CryptoServiceProtocol {
  // MARK: - Private Properties

  private let dto: CryptoServiceDto

  // MARK: - Initialization

  /// Initializes a new instance with a DTO
  /// - Parameter dto: The data transfer object containing crypto operations
  public init(dto: CryptoServiceDto) {
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
  ) async -> Result<SecureBytes, SecurityProtocolError> {
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
  ) async -> Result<SecureBytes, SecurityProtocolError> {
    await dto.decrypt(data, key)
  }

  /// Generates a cryptographic hash of the data
  /// - Parameter data: The data to hash
  /// - Returns: The hash value or an error
  public func hash(
    data: SecureBytes
  ) async -> Result<SecureBytes, SecurityProtocolError> {
    await dto.hash(data)
  }

  /// Verifies a hash against the expected value
  /// - Parameters:
  ///   - data: The data to verify
  ///   - expectedHash: The expected hash value
  /// - Returns: True if the hash matches, false otherwise, or an error
  public func verifyHash(
    data: SecureBytes,
    expectedHash: SecureBytes
  ) async -> Result<Bool, SecurityProtocolError> {
    await dto.verifyHash(data, expectedHash)
  }
}
