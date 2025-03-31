import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import UmbraErrors

/// Protocol defining cryptographic service operations in a Foundation-independent manner.
/// All operations use only primitive types and Foundation-independent custom types.
public protocol CryptoServiceProtocol: Sendable {
  /// Encrypts binary data using the provided key.
  /// - Parameters:
  ///   - data: Data to encrypt as byte array.
  ///   - key: Encryption key as byte array.
  /// - Returns: The encrypted data as byte array or an error.
  func encrypt(data: [UInt8], using key: [UInt8]) async
    -> Result<[UInt8], SecurityProtocolError>

  /// Decrypts binary data using the provided key.
  /// - Parameters:
  ///   - data: Data to decrypt as byte array.
  ///   - key: Decryption key as byte array.
  /// - Returns: The decrypted data as byte array or an error.
  func decrypt(data: [UInt8], using key: [UInt8]) async
    -> Result<[UInt8], SecurityProtocolError>

  /// Computes a cryptographic hash of binary data.
  /// - Parameter data: Data to hash as byte array.
  /// - Returns: The hash as byte array or an error.
  func hash(data: [UInt8]) async
    -> Result<[UInt8], SecurityProtocolError>

  /// Verifies a cryptographic hash against the expected value.
  /// - Parameters:
  ///   - data: Data to verify as byte array.
  ///   - expectedHash: Expected hash value as byte array.
  /// - Returns: `true` if the hash matches, `false` if not, or an error.
  func verifyHash(data: [UInt8], expectedHash: [UInt8]) async
    -> Result<Bool, SecurityProtocolError>
}

/// Data transfer object for cryptographic operations.
/// Used to pass crypto functionality between modules without requiring direct dependencies.
public struct CryptoServiceDto: Sendable {
  /// Type alias for encrypt function
  public typealias EncryptFunction = @Sendable (
    [UInt8], [UInt8]
  ) async -> Result<[UInt8], SecurityProtocolError>
  
  /// Type alias for decrypt function
  public typealias DecryptFunction = @Sendable (
    [UInt8], [UInt8]
  ) async -> Result<[UInt8], SecurityProtocolError>
  
  /// Type alias for hash function
  public typealias HashFunction = @Sendable (
    [UInt8]
  ) async -> Result<[UInt8], SecurityProtocolError>
  
  /// Type alias for verify hash function
  public typealias VerifyHashFunction = @Sendable (
    [UInt8], [UInt8]
  ) async -> Result<Bool, SecurityProtocolError>
  
  /// Function to encrypt data
  public let encrypt: EncryptFunction
  
  /// Function to decrypt data
  public let decrypt: DecryptFunction
  
  /// Function to hash data
  public let hash: HashFunction
  
  /// Function to verify a hash
  public let verifyHash: VerifyHashFunction
  
  /// Initialise a new CryptoServiceDto
  /// - Parameters:
  ///   - encrypt: Function to encrypt data
  ///   - decrypt: Function to decrypt data
  ///   - hash: Function to hash data
  ///   - verifyHash: Function to verify a hash
  public init(
    encrypt: @escaping EncryptFunction,
    decrypt: @escaping DecryptFunction,
    hash: @escaping HashFunction,
    verifyHash: @escaping VerifyHashFunction
  ) {
    self.encrypt = encrypt
    self.decrypt = decrypt
    self.hash = hash
    self.verifyHash = verifyHash
  }
}

/// Extension to convert CryptoServiceProtocol to a DTO
extension CryptoServiceProtocol {
  /// Converts this protocol implementation to a CryptoServiceDto
  /// - Returns: A CryptoServiceDto representing this service
  public func toDTO() -> CryptoServiceDto {
    CryptoServiceDto(
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
extension CryptoServiceDto {
  /// Creates a protocol-conforming object from this DTO
  /// - Returns: An object that conforms to CryptoServiceProtocol
  public func toProtocol() -> some CryptoServiceProtocol {
    struct ProtocolAdapter: CryptoServiceProtocol {
      let dto: CryptoServiceDto

      func encrypt(
        data: [UInt8],
        using key: [UInt8]
      ) async -> Result<[UInt8], SecurityProtocolError> {
        await dto.encrypt(data, key)
      }

      func decrypt(
        data: [UInt8],
        using key: [UInt8]
      ) async -> Result<[UInt8], SecurityProtocolError> {
        await dto.decrypt(data, key)
      }

      func hash(data: [UInt8]) async -> Result<[UInt8], SecurityProtocolError> {
        await dto.hash(data)
      }

      func verifyHash(
        data: [UInt8],
        expectedHash: [UInt8]
      ) async -> Result<Bool, SecurityProtocolError> {
        await dto.verifyHash(data, expectedHash)
      }
    }

    return ProtocolAdapter(dto: self)
  }
}
