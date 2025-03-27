import SecurityTypes

/// Protocol defining the core cryptographic operations
@preconcurrency
public protocol CryptoServiceProtocol: Sendable {
  /// Encrypts data using AES-GCM
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - key: Encryption key
  ///   - iv: Initialization vector
  /// - Returns: Encrypted data
  func encrypt(_ data: SecureBytes, using key: SecureBytes, iv: SecureBytes) async throws -> SecureBytes

  /// Decrypts data using AES-GCM
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - key: Decryption key
  ///   - iv: Initialization vector
  /// - Returns: Decrypted data
  func decrypt(_ data: SecureBytes, using key: SecureBytes, iv: SecureBytes) async throws -> SecureBytes

  /// Derives a key from a password using PBKDF2
  /// - Parameters:
  ///   - password: Password to derive key from
  ///   - salt: Salt for key derivation
  ///   - iterations: Number of iterations for key derivation
  /// - Returns: Derived key
  func deriveKey(from password: String, salt: SecureBytes, iterations: Int) async throws -> SecureBytes

  /// Generates a cryptographically secure random key
  /// - Parameter length: Length of the key in bytes
  /// - Returns: The generated key
  func generateSecureRandomKey(length: Int) async throws -> SecureBytes

  /// Generates a message authentication code (HMAC) using SHA-256
  /// - Parameters:
  ///   - data: Data to authenticate
  ///   - key: The authentication key
  /// - Returns: The authentication code
  func generateHMAC(for data: SecureBytes, using key: SecureBytes) async throws -> SecureBytes
}
