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
    -> Result<SecureBytes, SecurityProtocolError>

  /// Decrypts binary data using the provided key.
  /// - Parameters:
  ///   - data: The data to decrypt as `SecureBytes`.
  ///   - key: The decryption key as `SecureBytes`.
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
  ///   - hash: Expected hash as `SecureBytes`.
  /// - Returns: Boolean indicating if verification passed or an error.
  func verifyHash(data: SecureBytes, against hash: SecureBytes) async
    -> Result<Bool, SecurityProtocolError>

  /// Generates secure random bytes.
  /// - Parameter length: Length of random data to generate.
  /// - Returns: Random bytes as `SecureBytes` or an error.
  func generateRandomBytes(length: Int) async
    -> Result<SecureBytes, SecurityProtocolError>

  // MARK: - Symmetric Encryption

  /// Encrypt data using a symmetric key
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - key: Symmetric key for encryption
  ///   - config: Configuration options
  /// - Returns: Result containing encrypted data or error
  func encryptSymmetric(
    data: SecureBytes,
    key: SecureBytes,
    config: SecurityConfigDTO
  ) async -> Result<SecureBytes, SecurityProtocolError>

  /// Decrypt data using a symmetric key
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - key: Symmetric key for decryption
  ///   - config: Configuration options
  /// - Returns: Result containing decrypted data or error
  func decryptSymmetric(
    data: SecureBytes,
    key: SecureBytes,
    config: SecurityConfigDTO
  ) async -> Result<SecureBytes, SecurityProtocolError>

  // MARK: - Asymmetric Encryption

  /// Encrypt data using an asymmetric public key
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - publicKey: Public key for encryption
  ///   - config: Configuration options
  /// - Returns: Result containing encrypted data or error
  func encryptAsymmetric(
    data: SecureBytes,
    publicKey: SecureBytes,
    config: SecurityConfigDTO
  ) async -> Result<SecureBytes, SecurityProtocolError>

  /// Decrypt data using an asymmetric private key
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - privateKey: Private key for decryption
  ///   - config: Configuration options
  /// - Returns: Result containing decrypted data or error
  func decryptAsymmetric(
    data: SecureBytes,
    privateKey: SecureBytes,
    config: SecurityConfigDTO
  ) async -> Result<SecureBytes, SecurityProtocolError>

  // MARK: - Hashing

  /// Generate a cryptographic hash of data
  /// - Parameters:
  ///   - data: Data to hash
  ///   - config: Configuration options including algorithm selection
  /// - Returns: Result containing hash or error
  func hash(
    data: SecureBytes,
    config: SecurityConfigDTO
  ) async -> Result<SecureBytes, SecurityProtocolError>

  // MARK: - Random Data Generation

  /// Generate cryptographically secure random data
  /// - Parameter length: The length of random data to generate in bytes
  /// - Returns: Result containing random data or error
  func generateRandomData(length: Int) async -> Result<SecureBytes, SecurityProtocolError>
}
