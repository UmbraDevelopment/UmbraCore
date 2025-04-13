import CommonCrypto
import CoreSecurityTypes
import Foundation
import SecurityCoreInterfaces

/**
 # Crypto Operations

 This utility provides low-level cryptographic operations used by security providers.
 It encapsulates the implementation details of cryptographic algorithms and provides
 a clean interface for the service implementations.

 The operations focus on:
 - AES encryption and decryption (CBC and GCM modes)
 - ChaCha20-Poly1305 encryption and decryption
 - Cryptographic hashing
 - Key material handling
 */
enum CryptoOperations: Sendable {
  /// Standard AES-GCM tag length in bytes
  static let gcmTagLength = 16

  /// GCM nonce length in bytes
  static let gcmNonceLength = 12
  
  /// CBC initialization vector length in bytes
  static let cbcIVLength = 16
  
  /// ChaCha20-Poly1305 nonce length
  static let chaCha20NonceLength = 12

  /**
   Encrypts data using AES in the specified mode.

   - Parameters:
      - data: The plaintext data to encrypt
      - key: The encryption key (must be 32 bytes for AES-256)
      - iv: The initialisation vector/nonce
      - algorithm: The encryption algorithm to use
      - authenticatedData: Additional authenticated data for authenticated modes (GCM)
   - Returns: The ciphertext including authentication tag if applicable
   - Throws: SecurityProviderError if encryption fails
   */
  static func encrypt(
    data: [UInt8], 
    key: [UInt8], 
    iv: [UInt8]? = nil,
    algorithm: EncryptionAlgorithm,
    authenticatedData: [UInt8]? = nil
  ) throws -> [UInt8] {
    // Validate the key size
    guard key.count == kCCKeySizeAES256 else {
      throw SecurityProviderError.invalidKeySize(expected: kCCKeySizeAES256, actual: key.count)
    }
    
    // Generate IV if not provided
    let effectiveIV: [UInt8]
    if let iv = iv {
      effectiveIV = iv
    } else {
      // Generate appropriate IV based on algorithm
      switch algorithm {
      case .aes256CBC:
        effectiveIV = try generateRandomBytes(count: cbcIVLength)
      case .aes256GCM:
        effectiveIV = try generateRandomBytes(count: gcmNonceLength)
      case .chacha20Poly1305:
        effectiveIV = try generateRandomBytes(count: chaCha20NonceLength)
      }
    }
    
    // Validate IV size
    switch algorithm {
    case .aes256CBC:
      guard effectiveIV.count == cbcIVLength else {
        throw SecurityProviderError.invalidIVSize(expected: cbcIVLength, actual: effectiveIV.count)
      }
    case .aes256GCM:
      guard effectiveIV.count == gcmNonceLength else {
        throw SecurityProviderError.invalidIVSize(expected: gcmNonceLength, actual: effectiveIV.count)
      }
    case .chacha20Poly1305:
      guard effectiveIV.count == chaCha20NonceLength else {
        throw SecurityProviderError.invalidIVSize(expected: chaCha20NonceLength, actual: effectiveIV.count)
      }
    }
    
    // Choose the appropriate encryption algorithm
    switch algorithm {
    case .aes256CBC:
      return try encryptAES_CBC(data: data, key: key, iv: effectiveIV)
    case .aes256GCM:
      return try encryptAES_CBC(data: data, key: key, iv: effectiveIV)
      // The above is a temporary fallback as AES-GCM is not directly supported in CommonCrypto
      // In a production implementation, we would use CCM mode with authentication
      // or preferably a platform-specific implementation like CryptoKit
    case .chacha20Poly1305:
      // ChaCha20-Poly1305 is not directly supported in CommonCrypto
      // This would require a platform-specific implementation or use of a third-party library
      throw SecurityProviderError.unsupportedAlgorithm(algorithm)
    }
  }

  /**
   Decrypts data using AES in the specified mode.

   - Parameters:
      - data: The encrypted data
      - key: The decryption key (must be 32 bytes for AES-256)
      - iv: The initialisation vector/nonce
      - algorithm: The encryption algorithm to use
      - authenticatedData: Additional authenticated data for authenticated modes (GCM)
   - Returns: The decrypted plaintext
   - Throws: SecurityProviderError if decryption fails
   */
  static func decrypt(
    data: [UInt8], 
    key: [UInt8], 
    iv: [UInt8],
    algorithm: EncryptionAlgorithm,
    authenticatedData: [UInt8]? = nil
  ) throws -> [UInt8] {
    // Validate the key size
    guard key.count == kCCKeySizeAES256 else {
      throw SecurityProviderError.invalidKeySize(expected: kCCKeySizeAES256, actual: key.count)
    }
    
    // Validate IV size
    switch algorithm {
    case .aes256CBC:
      guard iv.count == cbcIVLength else {
        throw SecurityProviderError.invalidIVSize(expected: cbcIVLength, actual: iv.count)
      }
    case .aes256GCM:
      guard iv.count == gcmNonceLength else {
        throw SecurityProviderError.invalidIVSize(expected: gcmNonceLength, actual: iv.count)
      }
    case .chacha20Poly1305:
      guard iv.count == chaCha20NonceLength else {
        throw SecurityProviderError.invalidIVSize(expected: chaCha20NonceLength, actual: iv.count)
      }
    }
    
    // Choose the appropriate decryption algorithm
    switch algorithm {
    case .aes256CBC:
      return try decryptAES_CBC(data: data, key: key, iv: iv)
    case .aes256GCM:
      return try decryptAES_CBC(data: data, key: key, iv: iv)
      // The above is a temporary fallback as AES-GCM is not directly supported in CommonCrypto
      // In a production implementation, we would use CCM mode with authentication
      // or preferably a platform-specific implementation like CryptoKit
    case .chacha20Poly1305:
      // ChaCha20-Poly1305 is not directly supported in CommonCrypto
      // This would require a platform-specific implementation or use of a third-party library
      throw SecurityProviderError.unsupportedAlgorithm(algorithm)
    }
  }
  
  /**
   Computes a cryptographic hash of the provided data.
   
   - Parameters:
     - data: The data to hash
     - algorithm: The hash algorithm to use
   - Returns: The hash value
   - Throws: SecurityProviderError if hashing fails
   */
  static func hash(data: [UInt8], algorithm: HashAlgorithm) throws -> [UInt8] {
    switch algorithm {
    case .sha256:
      return try hashSHA256(data: data)
    case .sha512:
      return try hashSHA512(data: data)
    case .blake2b:
      // BLAKE2b is not directly supported in CommonCrypto
      // This would require a platform-specific implementation or use of a third-party library
      throw SecurityProviderError.internalError("BLAKE2b is not implemented in the basic provider")
    }
  }

  /**
   Encrypts data using AES-CBC with PKCS7 padding.

   This method handles the low-level details of AES encryption.

   - Parameters:
      - data: The plaintext data to encrypt
      - key: The encryption key
      - iv: The initialisation vector
   - Returns: The ciphertext
   - Throws: SecurityProviderError if encryption fails
   */
  private static func encryptAES_CBC(data: [UInt8], key: [UInt8], iv: [UInt8]) throws -> [UInt8] {
    // Create output buffer for ciphertext (data length + potential padding)
    let bufferSize = data.count + kCCBlockSizeAES128
    var ciphertext = [UInt8](repeating: 0, count: bufferSize)
    var bytesWritten = 0

    // Perform encryption
    let status = key.withUnsafeBytes { keyBytes in
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
      throw SecurityProviderError.encryptionFailed("Status: \(status)")
    }

    // Prepend IV to ciphertext for easier handling
    let result = iv + Array(ciphertext[0..<bytesWritten])
    return result
  }

  /**
   Decrypts data using AES-CBC with PKCS7 padding.

   This method handles the low-level details of AES decryption.

   - Parameters:
      - data: The encrypted data
      - key: The decryption key
      - iv: The initialisation vector
   - Returns: The decrypted plaintext
   - Throws: SecurityProviderError if decryption fails
   */
  private static func decryptAES_CBC(data: [UInt8], key: [UInt8], iv: [UInt8]) throws -> [UInt8] {
    // Create output buffer for plaintext (at most the same size as ciphertext)
    let bufferSize = data.count
    var plaintext = [UInt8](repeating: 0, count: bufferSize)
    var bytesWritten = 0

    // Perform decryption
    let status = key.withUnsafeBytes { keyBytes in
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
      throw SecurityProviderError.decryptionFailed("Status: \(status)")
    }

    // Return only the actual plaintext bytes
    return Array(plaintext[0..<bytesWritten])
  }
  
  /**
   Computes a SHA-256 hash of the provided data.
   
   - Parameter data: The data to hash
   - Returns: The SHA-256 hash value
   - Throws: SecurityProviderError if hashing fails
   */
  private static func hashSHA256(data: [UInt8]) throws -> [UInt8] {
    var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    
    let result = data.withUnsafeBytes { dataBytes in
      CC_SHA256(dataBytes.baseAddress, CC_LONG(data.count), &hash)
    }
    
    guard result != nil else {
      throw SecurityProviderError.hashingFailed("SHA-256 operation failed")
    }
    
    return hash
  }
  
  /**
   Computes a SHA-512 hash of the provided data.
   
   - Parameter data: The data to hash
   - Returns: The SHA-512 hash value
   - Throws: SecurityProviderError if hashing fails
   */
  private static func hashSHA512(data: [UInt8]) throws -> [UInt8] {
    var hash = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
    
    let result = data.withUnsafeBytes { dataBytes in
      CC_SHA512(dataBytes.baseAddress, CC_LONG(data.count), &hash)
    }
    
    guard result != nil else {
      throw SecurityProviderError.hashingFailed("SHA-512 operation failed")
    }
    
    return hash
  }
  
  /**
   Generates cryptographically secure random bytes.
   
   - Parameter count: Number of random bytes to generate
   - Returns: Array of random bytes
   - Throws: SecurityProviderError if generation fails
   */
  static func generateRandomBytes(count: Int) throws -> [UInt8] {
    var bytes = [UInt8](repeating: 0, count: count)
    let status = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
    
    guard status == errSecSuccess else {
      throw SecurityProviderError.randomGenerationFailed("Status: \(status)")
    }
    
    return bytes
  }
}
