import Errors
import UmbraCoreTypes

/// Protocol defining cryptographic operations in a FoundationIndependent manner.
/// This protocol uses only primitive types and FoundationIndependent custom types.
public protocol CryptoServiceProtocol: Sendable {
  /// Encrypts binary data using the provided key.
  /// - Parameters:
  ///   - data: The data to encrypt as `SecureBytes`.
  ///   - key: The encryption key as `SecureBytes`.
  /// - Returns: The encrypted data as `SecureBytes` or an error.
  func encrypt(data: SecureBytes, using key: SecureBytes) async
    -> Result<SecureBytes, Errors.SecurityProtocolError>

  /// Decrypts binary data using the provided key.
  /// - Parameters:
  ///   - data: The data to decrypt as `SecureBytes`.
  ///   - key: The decryption key as `SecureBytes`.
  /// - Returns: The decrypted data as `SecureBytes` or an error.
  func decrypt(data: SecureBytes, using key: SecureBytes) async
    -> Result<SecureBytes, Errors.SecurityProtocolError>

  /// Generates a random cryptographic key.
  /// - Parameter size: Size of the key in bytes.
  /// - Returns: The generated key as `SecureBytes` or an error.
  func generateKey(size: Int) async -> Result<SecureBytes, Errors.SecurityProtocolError>

  /// Calculates a cryptographic hash of data.
  /// - Parameter data: Data to hash as `SecureBytes`.
  /// - Returns: The hash value as `SecureBytes` or an error.
  func hash(data: SecureBytes) async -> Result<SecureBytes, Errors.SecurityProtocolError>

  /// Verifies that data matches a hash.
  /// - Parameters:
  ///   - data: Data to verify as `SecureBytes`.
  ///   - hash: Expected hash as `SecureBytes`.
  /// - Returns: Boolean indicating if verification passed or an error.
  func verifyHash(data: SecureBytes, against hash: SecureBytes) async
    -> Result<Bool, Errors.SecurityProtocolError>

  /// Generates secure random bytes.
  /// - Parameter length: Length of random data to generate.
  /// - Returns: Random bytes as `SecureBytes` or an error.
  func generateRandomBytes(length: Int) async
    -> Result<SecureBytes, Errors.SecurityProtocolError>

  // MARK: - Symmetric Encryption

  /// Encrypt data using a symmetric key
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - key: Symmetric key for encryption
  ///   - algorithm: Encryption algorithm identifier
  ///   - nonce: Optional initialization vector or nonce
  /// - Returns: Encrypted data or error
  func encryptSymmetric(
    data: SecureBytes,
    key: SecureBytes,
    algorithm: String,
    nonce: SecureBytes?
  ) async -> Result<SecureBytes, Errors.SecurityProtocolError>

  /// Decrypt data using a symmetric key
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - key: Symmetric key for decryption
  ///   - algorithm: Decryption algorithm identifier
  ///   - nonce: Optional initialization vector or nonce
  /// - Returns: Decrypted data or error
  func decryptSymmetric(
    data: SecureBytes,
    key: SecureBytes,
    algorithm: String,
    nonce: SecureBytes?
  ) async -> Result<SecureBytes, Errors.SecurityProtocolError>

  // MARK: - Asymmetric Encryption

  /// Encrypt data using an asymmetric public key
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - publicKey: Public key for encryption
  ///   - algorithm: Encryption algorithm identifier
  /// - Returns: Encrypted data or error
  func encryptAsymmetric(
    data: SecureBytes,
    publicKey: SecureBytes,
    algorithm: String
  ) async -> Result<SecureBytes, Errors.SecurityProtocolError>

  /// Decrypt data using an asymmetric private key
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - privateKey: Private key for decryption
  ///   - algorithm: Decryption algorithm identifier
  /// - Returns: Decrypted data or error
  func decryptAsymmetric(
    data: SecureBytes,
    privateKey: SecureBytes,
    algorithm: String
  ) async -> Result<SecureBytes, Errors.SecurityProtocolError>

  /// Sign data using an asymmetric private key
  /// - Parameters:
  ///   - data: Data to sign
  ///   - privateKey: Private key for signing
  ///   - algorithm: Signing algorithm identifier
  /// - Returns: Signature or error
  func sign(
    data: SecureBytes,
    privateKey: SecureBytes,
    algorithm: String
  ) async -> Result<SecureBytes, Errors.SecurityProtocolError>

  /// Generate random data of specified length
  /// - Parameter length: Number of random bytes to generate
  /// - Returns: Random bytes or error
  func generateRandomData(length: Int) async -> Result<SecureBytes, Errors.SecurityProtocolError>
}
