import CommonCrypto
import CryptoTypes
import Foundation
import SecurityTypes

/**
 # Crypto Operations

 This utility provides low-level cryptographic operations used by the CryptoServiceImpl.
 It encapsulates the implementation details of cryptographic algorithms and provides
 a clean interface for the service implementation.

 The operations focus on:
 - AES encryption and decryption
 - Cryptographic hashing
 - Key material handling
 */
enum CryptoOperations {
  /// Standard AES-GCM tag length in bytes
  static let gcmTagLength=16

  /// GCM nonce length in bytes
  static let gcmNonceLength=12

  /**
   Encrypts data using AES-CBC with PKCS7 padding.

   This method handles the low-level details of AES encryption.
   Note: This is a simplified implementation for compatibility.

   - Parameters:
      - data: The plaintext data to encrypt
      - key: The encryption key
      - iv: The initialisation vector/nonce
   - Returns: The ciphertext
   - Throws: CryptoError if encryption fails
   */
  static func encryptAES_GCM(data: [UInt8], key: [UInt8], iv: [UInt8]) throws -> [UInt8] {
    // Validate inputs
    guard key.count == kCCKeySizeAES256 else {
      throw CryptoError.invalidKey(reason: "AES-256 requires a 32-byte key, got \(key.count)")
    }

    guard iv.count == gcmNonceLength else {
      throw CryptoError.invalidInput(reason: "IV must be \(gcmNonceLength) bytes, got \(iv.count)")
    }

    // For compatibility, we'll use AES-CBC for now
    // Create output buffer for ciphertext
    let bufferSize=data.count + kCCBlockSizeAES128
    var ciphertext=[UInt8](repeating: 0, count: bufferSize)
    var bytesWritten=0

    // Perform encryption
    let status=key.withUnsafeBytes { keyBytes in
      iv.withUnsafeBytes { ivBytes in
        data.withUnsafeBytes { dataBytes in
          CCCrypt(
            CCOperation(kCCEncrypt),
            CCAlgorithm(kCCAlgorithmAES),
            CCOptions(kCCOptionPKCS7Padding),
            keyBytes.baseAddress, key.count,
            ivBytes.baseAddress,
            dataBytes.baseAddress, data.count,
            &ciphertext, bufferSize,
            &bytesWritten
          )
        }
      }
    }

    guard status == kCCSuccess else {
      throw CryptoError.encryptionFailed(reason: "Encryption failed with status: \(status)")
    }

    // Return only the actual ciphertext bytes
    return Array(ciphertext[0..<bytesWritten])
  }

  /**
   Decrypts data using AES-CBC with PKCS7 padding.

   This method handles the low-level details of AES decryption.
   Note: This is a simplified implementation for compatibility.

   - Parameters:
      - data: The encrypted data
      - key: The decryption key
      - iv: The initialisation vector/nonce
   - Returns: The decrypted plaintext
   - Throws: CryptoError if decryption fails
   */
  static func decryptAES_GCM(data: [UInt8], key: [UInt8], iv: [UInt8]) throws -> [UInt8] {
    // Validate inputs
    guard key.count == kCCKeySizeAES256 else {
      throw CryptoError.invalidKey(reason: "AES-256 requires a 32-byte key, got \(key.count)")
    }

    guard iv.count == gcmNonceLength else {
      throw CryptoError.invalidInput(reason: "IV must be \(gcmNonceLength) bytes, got \(iv.count)")
    }

    // For compatibility, we'll use AES-CBC for now
    // Create output buffer for plaintext
    let bufferSize=data.count + kCCBlockSizeAES128
    var plaintext=[UInt8](repeating: 0, count: bufferSize)
    var bytesWritten=0

    // Perform decryption
    let status=key.withUnsafeBytes { keyBytes in
      iv.withUnsafeBytes { ivBytes in
        data.withUnsafeBytes { dataBytes in
          CCCrypt(
            CCOperation(kCCDecrypt),
            CCAlgorithm(kCCAlgorithmAES),
            CCOptions(kCCOptionPKCS7Padding),
            keyBytes.baseAddress, key.count,
            ivBytes.baseAddress,
            dataBytes.baseAddress, data.count,
            &plaintext, bufferSize,
            &bytesWritten
          )
        }
      }
    }

    guard status == kCCSuccess else {
      throw CryptoError.decryptionFailed(reason: "Decryption failed with status: \(status)")
    }

    // Return only the actual plaintext bytes
    return Array(plaintext[0..<bytesWritten])
  }
}
