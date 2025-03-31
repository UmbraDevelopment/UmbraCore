import Foundation

/// Protocol defining the core cryptographic operations
@preconcurrency
@objc
public protocol CryptoServiceProtocol: Sendable {
  /// Encrypts data using AES-GCM
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - key: Encryption key
  ///   - iv: Initialization vector
  /// - Returns: Encrypted data
  func encrypt(_ data: Data, using key: Data, iv: Data) async throws -> Data

  /// Decrypts data using AES-GCM
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - key: Decryption key
  ///   - iv: Initialization vector
  /// - Returns: Decrypted data
  func decrypt(_ data: Data, using key: Data, iv: Data) async throws -> Data

  /// Derives a key from a password using PBKDF2
  /// - Parameters:
  ///   - password: Password to derive key from
  ///   - salt: Salt for key derivation
  ///   - iterations: Number of iterations for key derivation
  /// - Returns: Derived key
  func deriveKey(from password: String, salt: Data, iterations: Int) async throws -> Data

  /// Generates a cryptographically secure random key
  /// - Parameter length: Length of the key in bytes
  /// - Returns: The generated key
  func generateSecureRandomKey(length: Int) async throws -> Data

  /// Generates a message authentication code (HMAC) using SHA-256
  /// - Parameters:
  ///   - data: Data to authenticate
  ///   - key: The authentication key
  /// - Returns: The authentication code
  func generateHMAC(for data: Data, using key: Data) async throws -> Data
}
