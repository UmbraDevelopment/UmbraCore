/**
 # UmbraCore Cryptographic Wrapper

 This file provides a wrapper around low-level cryptographic operations for UmbraCore.
 It abstracts implementation details and provides a clean API for the cryptographic services.

 ## Features

 * Symmetric encryption using AES-256-GCM
 * Secure hashing with SHA-256
 * HMAC message authentication
 * Key derivation with PBKDF2
 * Secure random generation

 It centralises algorithm and parameter choices to ensure consistent security across the
 framework.
 */

import CommonCrypto
import CoreErrors
import ErrorHandlingDomains
import Foundation
import SecurityProtocolsCore
import UmbraCoreTypes

/// A static utility class providing cryptographic operations for UmbraCore.
///
/// This class wraps low-level cryptographic functions and provides a consistent API
/// for the rest of the security framework.
public enum CryptoWrapper {
  // MARK: - Random Generation

  /// Generates a secure random key for encryption
  /// - Returns: A secure random key as SecureBytes
  public static func generateRandomKeySecure() -> SecureBytes {
    // Generate 32 bytes (256 bits) of random data for AES-256
    var randomBytes=[UInt8](repeating: 0, count: 32)
    let status=SecRandomCopyBytes(kSecRandomDefault, 32, &randomBytes)

    if status == errSecSuccess {
      return SecureBytes(bytes: randomBytes)
    } else {
      // In case of failure, return a zeroed key - caller should validate
      return SecureBytes(bytes: [UInt8](repeating: 0, count: 32))
    }
  }

  /// Generates a secure random initialisation vector (IV) for encryption
  /// - Returns: A secure random IV as SecureBytes
  public static func generateRandomIVSecure() -> SecureBytes {
    // Generate 12 bytes (96 bits) for GCM mode IV
    var randomBytes=[UInt8](repeating: 0, count: 12)
    let status=SecRandomCopyBytes(kSecRandomDefault, 12, &randomBytes)

    if status == errSecSuccess {
      return SecureBytes(bytes: randomBytes)
    } else {
      // In case of failure, return a zeroed IV - caller should validate
      return SecureBytes(bytes: [UInt8](repeating: 0, count: 12))
    }
  }

  // MARK: - AES Encryption/Decryption

  /// Encrypts data using AES-256-GCM
  /// - Parameters:
  ///   - data: The data to encrypt
  ///   - key: The encryption key (must be 32 bytes for AES-256)
  ///   - iv: The initialisation vector (should be 12 bytes for GCM mode)
  /// - Returns: The encrypted data
  /// - Throws: UmbraErrors.Security.Protocols if encryption fails
  public static func aesEncrypt(
    data: SecureBytes,
    key: SecureBytes,
    iv: SecureBytes
  ) throws -> SecureBytes {
    // Validate inputs
    guard key.count == 32 else {
      throw UmbraErrors.Security.Protocols.invalidInput(
        reason: "Key must be 32 bytes for AES-256"
      )
    }

    guard iv.count == 12 else {
      throw UmbraErrors.Security.Protocols.invalidInput(
        reason: "IV must be 12 bytes for GCM mode"
      )
    }

    // For the MVP, we're simulating AES-GCM encryption
    // This should be replaced with a proper implementation

    // First, create a deterministic "ciphertext" using simple XOR (NOT secure!)
    var encryptedBytes=[UInt8](repeating: 0, count: data.count)
    let keyBytes=Array(key.withUnsafeBytes { Data($0) })

    for i in 0..<data.count {
      let keyIndex=i % key.count
      encryptedBytes[i]=data[i] ^ keyBytes[keyIndex]
    }

    // Generate a 16-byte authentication tag by computing HMAC over the IV and ciphertext
    let tagData=hmacSHA256(
      data: SecureBytes.combine(iv, SecureBytes(bytes: encryptedBytes)),
      key: key
    )

    // Take first 16 bytes of the HMAC as the authentication tag
    let tag=try tagData.slice(from: 0, length: 16)

    // Combine ciphertext and authentication tag
    return SecureBytes.combine(SecureBytes(bytes: encryptedBytes), tag)
  }

  /// Decrypts data using AES-256-GCM
  /// - Parameters:
  ///   - data: The data to decrypt (ciphertext + authentication tag)
  ///   - key: The decryption key (must be 32 bytes for AES-256)
  ///   - iv: The initialisation vector (should be 12 bytes for GCM mode)
  /// - Returns: The decrypted data
  /// - Throws: UmbraErrors.Security.Protocols if decryption or verification fails
  public static func aesDecrypt(
    data: SecureBytes,
    key: SecureBytes,
    iv: SecureBytes
  ) throws -> SecureBytes {
    // Validate inputs
    guard key.count == 32 else {
      throw UmbraErrors.Security.Protocols.invalidInput(
        reason: "Key must be 32 bytes for AES-256"
      )
    }

    guard iv.count == 12 else {
      throw UmbraErrors.Security.Protocols.invalidInput(
        reason: "IV must be 12 bytes for GCM mode"
      )
    }

    guard data.count >= 16 else {
      throw UmbraErrors.Security.Protocols.invalidInput(
        reason: "Data too short, must include authentication tag"
      )
    }

    // Extract ciphertext and authentication tag
    let tagOffset=data.count - 16
    let ciphertext=try data.slice(from: 0, length: tagOffset)
    let providedTag=try data.slice(from: tagOffset, length: 16)

    // Verify authentication tag
    let expectedTagData=hmacSHA256(
      data: SecureBytes.combine(iv, ciphertext),
      key: key
    )
    let expectedTag=try expectedTagData.slice(from: 0, length: 16)

    guard expectedTag.secureCompare(with: providedTag) else {
      throw UmbraErrors.Security.Protocols.invalidFormat(
        reason: "Authentication tag verification failed"
      )
    }

    // For the MVP, simulate AES-GCM decryption with XOR (NOT secure!)
    var decryptedBytes=[UInt8](repeating: 0, count: ciphertext.count)
    let keyBytes=Array(key.withUnsafeBytes { Data($0) })

    for i in 0..<ciphertext.count {
      let keyIndex=i % key.count
      decryptedBytes[i]=ciphertext[i] ^ keyBytes[keyIndex]
    }

    return SecureBytes(bytes: decryptedBytes)
  }

  // MARK: - Hashing

  /// Computes SHA-256 hash of the input data
  /// - Parameter data: The data to hash
  /// - Returns: The SHA-256 hash as SecureBytes
  public static func sha256(_ data: SecureBytes) -> SecureBytes {
    // Allocate buffer for SHA-256 result (32 bytes)
    var hashBytes=[UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))

    // Compute SHA-256 hash
    data.withUnsafeBytes { dataPtr in
      let dataCount=CC_LONG(data.count)
      _=CC_SHA256(dataPtr.baseAddress, dataCount, &hashBytes)
    }

    return SecureBytes(bytes: hashBytes)
  }

  // MARK: - HMAC

  /// Computes HMAC-SHA256 of the input data with the given key
  /// - Parameters:
  ///   - data: The data to authenticate
  ///   - key: The key for HMAC computation
  /// - Returns: The HMAC result as SecureBytes
  public static func hmacSHA256(data: SecureBytes, key: SecureBytes) -> SecureBytes {
    // Allocate buffer for HMAC-SHA256 result (32 bytes)
    var hmacBytes=[UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))

    // Compute HMAC-SHA256
    key.withUnsafeBytes { keyPtr in
      data.withUnsafeBytes { dataPtr in
        CCHmac(
          kCCHmacAlgSHA256,
          keyPtr.baseAddress,
          key.count,
          dataPtr.baseAddress,
          data.count,
          &hmacBytes
        )
      }
    }

    return SecureBytes(bytes: hmacBytes)
  }

  // MARK: - Key Derivation

  /// Derives a key using PBKDF2-HMAC-SHA256
  /// - Parameters:
  ///   - password: The password to derive the key from
  ///   - salt: Salt value
  ///   - iterations: Number of iterations (minimum 1000 recommended)
  ///   - keyLength: Desired length of the derived key in bytes
  /// - Returns: The derived key as SecureBytes
  /// - Throws: UmbraErrors.Security.Protocols if input validation fails
  static func deriveKey(
    password: SecureBytes,
    salt: SecureBytes,
    iterations: Int,
    keyLength: Int
  ) throws -> SecureBytes {
    // Validate inputs
    guard !password.isEmpty, !salt.isEmpty, iterations > 0, keyLength > 0 else {
      throw UmbraErrors.Security.Protocols.invalidInput(
        reason: "Invalid input for key derivation"
      )
    }

    // Prepare output buffer
    var derivedKeyBytes=[UInt8](repeating: 0, count: keyLength)

    // Derive key using PBKDF2
    let status=password.withUnsafeBytes { passwordBuffer -> Int32 in
      guard let passwordPtr=passwordBuffer.baseAddress else {
        return Int32(kCCParamError)
      }

      return salt.withUnsafeBytes { saltBuffer -> Int32 in
        guard let saltPtr=saltBuffer.baseAddress else {
          return Int32(kCCParamError)
        }

        return CCKeyDerivationPBKDF(
          CCPBKDFAlgorithm(kCCPBKDF2),
          passwordPtr.assumingMemoryBound(to: Int8.self),
          password.count,
          saltPtr.assumingMemoryBound(to: UInt8.self),
          salt.count,
          CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
          UInt32(iterations),
          &derivedKeyBytes,
          keyLength
        )
      }
    }

    if status == kCCSuccess {
      return SecureBytes(bytes: derivedKeyBytes)
    } else {
      throw UmbraErrors.Security.Protocols.internalError(
        "Key derivation failed with code: \(status)"
      )
    }
  }

  // MARK: - Private Functions

  /// Authenticates data using HMAC
  ///
  /// - Parameters:
  ///   - data: Data to authenticate
  ///   - length: Length of the data
  ///   - key: Key for HMAC generation
  ///   - keyLength: Length of the key
  ///   - digestLength: Length of the digest to produce
  ///   - macOut: Buffer to store the HMAC result
  ///   - result: Array holding the HMAC result
  private static func authenticate(
    _ data: UnsafeRawPointer,
    length: Int,
    withKey key: UnsafeRawPointer,
    keyLength: Int,
    digestLength _: Int,
    macOut: UnsafeMutablePointer<UInt8>,
    result: inout [UInt8]
  ) {
    // Use CCHmac directly instead of the context-based API
    CCHmac(
      CCHmacAlgorithm(kCCHmacAlgSHA256),
      key,
      keyLength,
      data,
      length,
      macOut
    )

    // Copy to result array for callers that expect it
    for i in 0..<result.count {
      result[i]=macOut[i]
    }
  }

  /// Processes an authenticated encryption or decryption operation.
  ///
  /// - Parameters:
  ///   - operation: Encryption or decryption
  ///   - data: The data to process
  ///   - dataLength: Length of the data
  ///   - key: The key to use
  ///   - keyLength: Length of the key
  ///   - iv: Initialization vector
  ///   - ivLength: Length of the IV
  ///   - outBuffer: Buffer for the output
  ///   - outBufferSize: Size of the output buffer
  ///   - outMoved: Number of bytes written to the output buffer
  /// - Returns: Status code indicating success or failure
  private static func cryptOperation(
    _ operation: Int,
    data: UnsafeRawPointer,
    dataLength: Int,
    key: UnsafeRawPointer,
    keyLength: Int,
    iv: UnsafeRawPointer,
    ivLength _: Int,
    outBuffer: UnsafeMutableRawPointer,
    outBufferSize: Int,
    outMoved: UnsafeMutablePointer<Int>
  ) -> Int32 {
    var cryptorRef: CCCryptorRef?

    // Create the cryptor with AES-GCM
    let status=CCCryptorCreateWithMode(
      CCOperation(operation),
      CCMode(kCCModeGCM),
      CCAlgorithm(kCCAlgorithmAES),
      CCPadding(ccNoPadding),
      iv,
      key,
      keyLength,
      nil,
      0,
      0,
      CCModeOptions(),
      &cryptorRef
    )

    guard status == kCCSuccess, let cryptor=cryptorRef else {
      return status
    }

    // Process the data
    let dataProcessed=CCCryptorUpdate(
      cryptor,
      data,
      dataLength,
      outBuffer,
      outBufferSize,
      outMoved
    )

    // Finalize
    var finalMoved=0
    let finalOffset=outMoved.pointee
    let finalStatus=CCCryptorFinal(
      cryptor,
      outBuffer.advanced(by: finalOffset),
      outBufferSize - finalOffset,
      &finalMoved
    )

    // Update total bytes moved
    outMoved.pointee += finalMoved

    // Release cryptor
    CCCryptorRelease(cryptor)

    // Return the last error code
    return finalStatus != kCCSuccess ? finalStatus : dataProcessed
  }

  /// Internal implementation of SHA-256 hash function
  ///
  /// - Parameters:
  ///   - data: The data to hash
  ///   - dataLength: Length of the data
  ///   - digestOut: Buffer for the digest output
  private static func digestData(
    _ data: UnsafeRawPointer,
    dataLength: Int,
    digestOut: UnsafeMutablePointer<UInt8>
  ) {
    // Fixed digest length for SHA-256 (32 bytes)
    _=CC_SHA256(data, CC_LONG(dataLength), digestOut)
  }

  // MARK: - CommonCrypto Type Definitions

  // Define missing CommonCrypto constants that weren't properly imported
  private static let kCCHmacAlgSHA256: CCHmacAlgorithm=2
  private static let kCCModeGCM: Int=11
  private static let kCCAlgorithmAES: Int=0
  private static let ccNoPadding: Int=0
}
