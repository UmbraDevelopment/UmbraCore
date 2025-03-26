import Errors
import Types
import UmbraCoreTypes

/// Protocol defining cryptographic service operations in a FoundationIndependent manner.
/// All operations use only primitive types and FoundationIndependent custom types.
public protocol CryptoServiceProtocol: Sendable {
  /// Encrypts binary data using the provided key.
  /// - Parameters:
  ///   - data: Data to encrypt as `SecureBytes`.
  ///   - key: Encryption key as `SecureBytes`.
  /// - Returns: The encrypted data as `SecureBytes` or an error.
  func encrypt(data: SecureBytes, using key: SecureBytes) async
    -> Result<SecureBytes, SecurityProtocolError>

  /// Decrypts binary data using the provided key.
  /// - Parameters:
  ///   - data: Data to decrypt as `SecureBytes`.
  ///   - key: Decryption key as `SecureBytes`.
  /// - Returns: The decrypted data as `SecureBytes` or an error.
  func decrypt(data: SecureBytes, using key: SecureBytes) async
    -> Result<SecureBytes, SecurityProtocolError>

  /// Computes a cryptographic hash of binary data.
  /// - Parameter data: Data to hash as `SecureBytes`.
  /// - Returns: The hash as `SecureBytes` or an error.
  func hash(data: SecureBytes) async
    -> Result<SecureBytes, SecurityProtocolError>

  /// Verifies a cryptographic hash against the expected value.
  /// - Parameters:
  ///   - data: Data to verify as `SecureBytes`.
  ///   - expectedHash: Expected hash value as `SecureBytes`.
  /// - Returns: `true` if the hash matches, `false` if not, or an error.
  func verifyHash(data: SecureBytes, expectedHash: SecureBytes) async
    -> Result<Bool, SecurityProtocolError>
}

/// Extension to convert CryptoServiceProtocol to a DTO
extension CryptoServiceProtocol {
  /// Converts this protocol implementation to a CryptoServiceDTO
  /// - Returns: A CryptoServiceDTO representing this service
  public func toDTO() -> CryptoServiceDTO {
    CryptoServiceDTO(
      encrypt: { data, key in
        await self.encrypt(data: data, using: key)
      },
      decrypt: { data, key in
        await self.decrypt(data: data, using: key)
      },
      hash: { data in
        await self.hash(data: data)
      },
      verifyHash: { data, expectedHash in
        await self.verifyHash(data: data, expectedHash: expectedHash)
      }
    )
  }
}

/// Extension to create a CryptoServiceProtocol from a DTO
extension CryptoServiceDTO {
  /// Creates a protocol-conforming object from this DTO
  /// - Returns: An object that conforms to CryptoServiceProtocol
  public func toProtocol() -> some CryptoServiceProtocol {
    struct ProtocolAdapter: CryptoServiceProtocol {
      let dto: CryptoServiceDTO

      func encrypt(
        data: SecureBytes,
        using key: SecureBytes
      ) async -> Result<SecureBytes, SecurityProtocolError> {
        await dto.encrypt(data, key)
      }

      func decrypt(
        data: SecureBytes,
        using key: SecureBytes
      ) async -> Result<SecureBytes, SecurityProtocolError> {
        await dto.decrypt(data, key)
      }

      func hash(data: SecureBytes) async -> Result<SecureBytes, SecurityProtocolError> {
        await dto.hash(data)
      }

      func verifyHash(
        data: SecureBytes,
        expectedHash: SecureBytes
      ) async -> Result<Bool, SecurityProtocolError> {
        await dto.verifyHash(data, expectedHash)
      }
    }

    return ProtocolAdapter(dto: self)
  }
}
