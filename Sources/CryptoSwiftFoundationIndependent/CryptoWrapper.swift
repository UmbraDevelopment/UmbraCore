import CryptoSwift
import UmbraCoreTypes

/// A Foundation-independent wrapper for CryptoSwift functionality
/// This helps break circular dependencies between Foundation and CryptoSwift
public enum CryptoWrapper {
  /// Custom error type for CryptoWrapper operations
  public enum CryptoWrapperError: Error {
    case invalidParameters
    case randomGenerationFailed
    case cryptoOperationFailed
  }

  // MARK: - AES-GCM Operations

  /// Encrypt data using AES-GCM
  /// - Parameters:
  ///   - data: Raw data to encrypt
  ///   - key: Encryption key
  ///   - iv: Initialization vector (should be 12 bytes for AES-GCM)
  /// - Returns: Encrypted data
  public static func encryptAES_GCM(data: [UInt8], key: [UInt8], iv: [UInt8]) throws -> [UInt8] {
    let gcm=GCM(iv: iv, mode: .combined)
    let aes=try AES(key: key, blockMode: gcm, padding: .noPadding)
    return try aes.encrypt(data)
  }

  /// Encrypt data using AES-GCM with SecureBytes
  /// - Parameters:
  ///   - data: SecureBytes data to encrypt
  ///   - key: SecureBytes encryption key
  ///   - iv: SecureBytes initialization vector (should be 12 bytes for AES-GCM)
  /// - Returns: SecureBytes containing encrypted data
  public static func encryptAES_GCM(
    data: SecureBytes,
    key: SecureBytes,
    iv: SecureBytes
  ) throws -> SecureBytes {
    let encryptedBytes=try encryptAES_GCM(
      data: data.bytes(),
      key: key.bytes(),
      iv: iv.bytes()
    )
    return SecureBytes(bytes: encryptedBytes)
  }

  /// Decrypt data using AES-GCM
  /// - Parameters:
  ///   - data: Encrypted data
  ///   - key: Decryption key
  ///   - iv: Initialization vector (should be 12 bytes for AES-GCM)
  /// - Returns: Decrypted data
  public static func decryptAES_GCM(data: [UInt8], key: [UInt8], iv: [UInt8]) throws -> [UInt8] {
    let gcm=GCM(iv: iv, mode: .combined)
    let aes=try AES(key: key, blockMode: gcm, padding: .noPadding)
    return try aes.decrypt(data)
  }

  /// Decrypt data using AES-GCM with SecureBytes
  /// - Parameters:
  ///   - data: SecureBytes encrypted data
  ///   - key: SecureBytes decryption key
  ///   - iv: SecureBytes initialization vector
  /// - Returns: SecureBytes containing decrypted data
  public static func decryptAES_GCM(
    data: SecureBytes,
    key: SecureBytes,
    iv: SecureBytes
  ) throws -> SecureBytes {
    let decryptedBytes=try decryptAES_GCM(
      data: data.bytes(),
      key: key.bytes(),
      iv: iv.bytes()
    )
    return SecureBytes(bytes: decryptedBytes)
  }

  // MARK: - Random Generation

  /// Generate a random initialization vector
  /// - Parameter size: Size of the IV in bytes. Default is 12 bytes (96 bits),
  ///                   which is the recommended size for AES-GCM.
  /// - Returns: Random IV bytes
  public static func generateRandomIV(size: Int=12) -> [UInt8] {
    // Use CryptoSwift's random method to generate IV
    (0..<size).map { _ in UInt8.random(in: 0...255) }
  }

  /// Generate a random initialization vector as SecureBytes
  /// - Parameter size: Size of the IV in bytes. Default is 12 bytes (96 bits),
  ///                   which is the recommended size for AES-GCM.
  /// - Returns: SecureBytes containing random IV
  public static func generateRandomIVSecure(size: Int=12) -> SecureBytes {
    SecureBytes(bytes: generateRandomIV(size: size))
  }

  /// Generate a random key
  /// - Parameter size: Size of the key in bytes (16, 24, or 32 for AES-128, AES-192, or AES-256)
  /// - Returns: Random key bytes
  public static func generateRandomKey(size: Int=32) -> [UInt8] {
    // Use CryptoSwift's random method to generate key
    (0..<size).map { _ in UInt8.random(in: 0...255) }
  }

  /// Generate a random key as SecureBytes
  /// - Parameter size: Size of the key in bytes (16, 24, or 32 for AES-128, AES-192, or AES-256)
  /// - Returns: SecureBytes containing random key
  public static func generateRandomKeySecure(size: Int=32) -> SecureBytes {
    SecureBytes(bytes: generateRandomKey(size: size))
  }

  /// Generate secure random bytes directly into a buffer
  /// - Parameters:
  ///   - buffer: Buffer to fill with random bytes
  ///   - length: Number of bytes to generate
  /// - Returns: True if successful, false otherwise
  /// - Throws: CryptoWrapperError if the parameters are invalid
  public static func generateSecureRandomBytes(
    _ buffer: inout [UInt8],
    length: Int
  ) throws -> Bool {
    guard length > 0, buffer.count >= length else {
      throw CryptoWrapperError.invalidParameters
    }

    // Fill buffer with secure random bytes
    for i in 0..<length {
      buffer[i]=UInt8.random(in: 0...255)
    }

    return true
  }

  // MARK: - Hashing Operations

  /// Calculate SHA-256 hash
  /// - Parameter data: Input data
  /// - Returns: SHA-256 hash
  public static func sha256(_ data: [UInt8]) -> [UInt8] {
    data.sha2(.sha256)
  }

  /// Calculate SHA-256 hash with SecureBytes
  /// - Parameter data: SecureBytes input data
  /// - Returns: SecureBytes containing SHA-256 hash
  public static func sha256(_ data: SecureBytes) -> SecureBytes {
    let hashBytes=sha256(data.bytes())
    return SecureBytes(bytes: hashBytes)
  }

  /// Calculate HMAC using SHA-256
  /// - Parameters:
  ///   - data: Input data
  ///   - key: HMAC key
  /// - Returns: HMAC result
  public static func hmacSHA256(data: [UInt8], key: [UInt8]) -> [UInt8] {
    try! HMAC(key: key, variant: .sha2(.sha256)).authenticate(data)
  }

  /// Calculate HMAC using SHA-256 with SecureBytes
  /// - Parameters:
  ///   - data: SecureBytes input data
  ///   - key: SecureBytes HMAC key
  /// - Returns: SecureBytes containing HMAC result
  public static func hmacSHA256(data: SecureBytes, key: SecureBytes) -> SecureBytes {
    let hmacBytes=hmacSHA256(data: data.bytes(), key: key.bytes())
    return SecureBytes(bytes: hmacBytes)
  }
}
