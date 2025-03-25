import UmbraCoreTypes
import Errors
import Types

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

  /// Generates a random cryptographic key.
  /// - Parameter size: Size of the key in bytes.
  /// - Returns: The generated key as `SecureBytes` or an error.
  func generateKey(size: Int) async -> Result<SecureBytes, SecurityProtocolError>

  /// Calculates a cryptographic hash of data.
  /// - Parameter data: Data to hash as `SecureBytes`.
  /// - Returns: The hash value as `SecureBytes` or an error.
  func hash(data: SecureBytes) async -> Result<SecureBytes, SecurityProtocolError>

  /// Verifies that data matches a hash.
  /// - Parameters:
  ///   - data: Data to verify as `SecureBytes`.
  ///   - hash: Hash to check against as `SecureBytes`.
  /// - Returns: Boolean indicating if verification passed or an error.
  func verifyHash(data: SecureBytes, against hash: SecureBytes) async
    -> Result<Bool, SecurityProtocolError>

  /// Generates secure random bytes.
  /// - Parameter length: Number of bytes to generate.
  /// - Returns: Random bytes as `SecureBytes` or an error.
  func generateRandomBytes(length: Int) async
    -> Result<SecureBytes, SecurityProtocolError>

  // MARK: - Symmetric Encryption

  /// Encrypts data using authenticated encryption with associated data (AEAD).
  /// - Parameters:
  ///   - data: Data to encrypt as `SecureBytes`.
  ///   - key: Encryption key as `SecureBytes`.
  ///   - config: Encryption configuration.
  /// - Returns: Encrypted data as `SecureBytes` or an error.
  func encryptWithConfiguration(
    data: SecureBytes,
    key: SecureBytes,
    config: SecurityConfigDTO
  ) async -> Result<SecureBytes, SecurityProtocolError>

  /// Decrypts data using authenticated encryption with associated data (AEAD).
  /// - Parameters:
  ///   - data: Data to decrypt as `SecureBytes`.
  ///   - key: Decryption key as `SecureBytes`.
  ///   - config: Decryption configuration.
  /// - Returns: Decrypted data as `SecureBytes` or an error.
  func decryptWithConfiguration(
    data: SecureBytes,
    key: SecureBytes,
    config: SecurityConfigDTO
  ) async -> Result<SecureBytes, SecurityProtocolError>
}
