import UmbraErrors
import UmbraErrorsCore
import CryptoSwiftFoundationIndependent


import SecurityProtocolsCore

/// Error types for security operations
public enum SecurityCryptoError: Error, Sendable {
  case invalidData(String)
  case cryptoOperationFailed(String)
}

/// Provides cryptographic operations using CryptoSwift
public final class SecurityCryptoService: Sendable {
  public init() {}

  /// Encrypt data using AES-GCM
  /// - Parameters:
  ///   - data: Raw data to encrypt
  ///   - key: Encryption key
  /// - Returns: Encrypted data with IV prepended
  public func encrypt(data: [UInt8], key: [UInt8]) throws -> [UInt8] {
    let iv=CryptoWrapper.generateRandomIV()
    let encrypted=try CryptoWrapper.encryptAES_GCM(data: data, key: key, iv: iv)

    // Prepend IV to the encrypted data
    return iv + encrypted
  }

  /// Decrypt data using AES-GCM
  /// - Parameters:
  ///   - data: Encrypted data with IV prepended
  ///   - key: Decryption key
  /// - Returns: Decrypted data
  public func decrypt(data: [UInt8], key: [UInt8]) throws -> [UInt8] {
    guard data.count > 12 else {
      throw SecurityCryptoError.invalidData("Encrypted data too short")
    }

    // Extract IV from the beginning of the data
    let iv=Array(data.prefix(12))
    let encryptedData=Array(data.dropFirst(12))

    return try CryptoWrapper.decryptAES_GCM(data: encryptedData, key: key, iv: iv)
  }

  /// Generate a random key
  /// - Parameter size: Size of the key in bytes
  /// - Returns: Random key bytes
  public func generateKey(size: Int=32) -> [UInt8] {
    CryptoWrapper.generateRandomKey(size: size)
  }

  /// Calculate SHA-256 hash
  /// - Parameter data: Input data
  /// - Returns: SHA-256 hash
  public func hash(data: [UInt8]) -> [UInt8] {
    CryptoWrapper.sha256(data)
  }

  /// Calculate HMAC using SHA-256
  /// - Parameters:
  ///   - data: Input data
  ///   - key: HMAC key
  /// - Returns: HMAC result
  public func hmac(data: [UInt8], key: [UInt8]) -> [UInt8] {
    CryptoWrapper.hmacSHA256(data: data, key: key)
  }
}
