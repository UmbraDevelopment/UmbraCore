import CommonCrypto
import CoreSecurityTypes
import Foundation
import SecurityCoreInterfaces

/// Crypto Operations
///
/// This utility provides low-level cryptographic operations used by security providers.
/// It encapsulates the implementation details of cryptographic algorithms and provides
/// a clean interface for the service implementations.
///
/// The operations focus on:
/// - AES encryption and decryption (CBC and GCM modes)
/// - ChaCha20-Poly1305 encryption and decryption
/// - Cryptographic hashing
/// - Key material handling
enum CryptoOperations: Sendable {
  /// Standard AES-GCM tag length in bytes
  static let gcmTagLength = 16

  /// GCM nonce length in bytes
  static let gcmNonceLength = 12

  /// CBC initialisation vector length in bytes
  static let cbcIVLength = 16

  /// ChaCha20-Poly1305 nonce length
  static let chaCha20NonceLength = 12

  /// Encrypts data using AES in the specified mode.
  ///
  /// - Parameters:
  ///   - data: The plaintext data to encrypt
  ///   - key: The encryption key (must be 32 bytes for AES-256)
  ///   - iv: The initialisation vector/nonce
  ///   - algorithm: The encryption algorithm to use
  ///   - authenticatedData: Additional authenticated data for authenticated modes (GCM)
  /// - Returns: The ciphertext including authentication tag if applicable
  /// - Throws: SecurityProviderError if encryption fails
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
    let effectiveIV: [UInt8] = if let iv {
      iv
    } else {
      // Generate appropriate IV based on algorithm
      switch algorithm {
        case .aes256CBC:
          try generateRandomBytes(count: cbcIVLength)
        case .aes256GCM:
          try generateRandomBytes(count: gcmNonceLength)
        case .chacha20Poly1305:
          try generateRandomBytes(count: chaCha20NonceLength)
      }
    }

    // Validate IV size
    switch algorithm {
      case .aes256CBC:
        guard effectiveIV.count == cbcIVLength else {
          throw SecurityProviderError.invalidIVSize(
            expected: cbcIVLength,
            actual: effectiveIV.count
          )
        }
      case .aes256GCM:
        guard effectiveIV.count == gcmNonceLength else {
          throw SecurityProviderError.invalidIVSize(
            expected: gcmNonceLength,
            actual: effectiveIV.count
          )
        }
      case .chacha20Poly1305:
        guard effectiveIV.count == chaCha20NonceLength else {
          throw SecurityProviderError.invalidIVSize(
            expected: chaCha20NonceLength,
            actual: effectiveIV.count
          )
        }
    }

    // Perform encryption based on algorithm
    var result: [UInt8]
    switch algorithm {
      case .aes256CBC:
        result = try encryptAES_CBC(
          data: data,
          key: key,
          iv: effectiveIV
        )
      case .aes256GCM:
        result = try encryptAES_GCM(
          data: data,
          key: key,
          iv: effectiveIV,
          authenticatedData: authenticatedData
        )
      case .chacha20Poly1305:
        // Call ChaCha20-Poly1305 implementation
        throw SecurityProviderError.unsupportedAlgorithm(algorithm)
    }

    return result
  }

  /// Decrypts data using AES in the specified mode.
  ///
  /// - Parameters:
  ///   - data: The ciphertext to decrypt
  ///   - key: The encryption key
  ///   - iv: The initialisation vector/nonce
  ///   - algorithm: The encryption algorithm to use
  ///   - authenticatedData: Additional authenticated data for authenticated modes (GCM)
  /// - Returns: The decrypted plaintext
  /// - Throws: SecurityProviderError if decryption fails
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
          throw SecurityProviderError.invalidIVSize(
            expected: chaCha20NonceLength,
            actual: iv.count
          )
        }
    }

    // Perform decryption based on algorithm
    var result: [UInt8]
    switch algorithm {
      case .aes256CBC:
        result = try decryptAES_CBC(
          data: data,
          key: key,
          iv: iv
        )
      case .aes256GCM:
        result = try decryptAES_GCM(
          data: data,
          key: key,
          iv: iv,
          authenticatedData: authenticatedData
        )
      case .chacha20Poly1305:
        // Call ChaCha20-Poly1305 implementation
        throw SecurityProviderError.unsupportedAlgorithm(algorithm)
    }

    return result
  }

  /// Generate cryptographically secure random bytes.
  ///
  /// - Parameter count: The number of random bytes to generate
  /// - Returns: An array of random bytes
  /// - Throws: SecurityProviderError if random generation fails
  static func generateRandomBytes(count: Int) throws -> [UInt8] {
    var bytes = [UInt8](repeating: 0, count: count)
    let status = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
    
    guard status == errSecSuccess else {
      throw SecurityProviderError.randomGenerationFailed("Status code: \(status)")
    }
    
    return bytes
  }

  /// Performs AES-GCM encryption.
  ///
  /// - Parameters:
  ///   - data: The plaintext to encrypt
  ///   - key: The encryption key
  ///   - iv: The initialisation vector/nonce
  ///   - authenticatedData: Additional authenticated data
  /// - Returns: The ciphertext with appended authentication tag
  /// - Throws: SecurityProviderError if encryption fails
  private static func encryptAES_GCM(
    data: [UInt8],
    key: [UInt8],
    iv: [UInt8],
    authenticatedData: [UInt8]? = nil
  ) throws -> [UInt8] {
    // Create cryptor reference
    var cryptorRef: CCCryptorRef?
    
    // Use withUnsafeBytes for key and IV to avoid pointer arithmetic issues
    let status = key.withUnsafeBytes { keyBytes in
      iv.withUnsafeBytes { ivBytes in
        CCCryptorCreateWithMode(
          CCOperation(kCCEncrypt),
          CCMode(kCCModeGCM),
          CCAlgorithm(kCCAlgorithmAES),
          CCPadding(ccNoPadding),
          ivBytes.baseAddress,
          keyBytes.baseAddress,
          key.count,
          nil,
          0,
          0,
          0,
          &cryptorRef
        )
      }
    }

    guard status == kCCSuccess, let cryptor = cryptorRef else {
      throw SecurityProviderError.cryptorCreationFailed(status)
    }
    
    // Process additional authenticated data if provided
    if let aad = authenticatedData, !aad.isEmpty {
      let aadStatus = CCCryptorGCMAddAAD(cryptor, aad, aad.count)
      guard aadStatus == kCCSuccess else {
        throw SecurityProviderError.aadProcessingFailed(aadStatus)
      }
    }

    // Prepare ciphertext buffer (same size as plaintext)
    var ciphertext = [UInt8](repeating: 0, count: data.count)
    var bytesWritten = 0
    
    // Encrypt the data
    let ciphertextCount = ciphertext.count // Create a local copy
    let encStatus = data.withUnsafeBytes { dataBytes in
      return ciphertext.withUnsafeMutableBytes { ciphertextBytes in
        CCCryptorUpdate(
          cryptor,
          dataBytes.baseAddress,
          data.count,
          ciphertextBytes.baseAddress,
          ciphertextCount, // Use the local copy
          &bytesWritten
        )
      }
    }

    guard encStatus == kCCSuccess else {
      throw SecurityProviderError.encryptionFailed("CCCryptorUpdate failed with status \(encStatus)")
    }

    // Finalize encryption
    var finalBytesWritten = 0
    let remainingCiphertextCount = ciphertextCount - bytesWritten // Calculate remaining space
    
    // Store a local copy of the ciphertext pointer offset
    let finalStatus = ciphertext.withUnsafeMutableBytes { ciphertextBytes in
      let baseAddress = ciphertextBytes.baseAddress!.advanced(by: bytesWritten)
      return CCCryptorFinal(
        cryptor,
        baseAddress,
        remainingCiphertextCount, // Use the calculated remaining space
        &finalBytesWritten
      )
    }

    guard finalStatus == kCCSuccess else {
      throw SecurityProviderError.encryptionFinalisationFailed(finalStatus)
    }

    // Get the authentication tag
    var tagBuffer = [UInt8](repeating: 0, count: gcmTagLength)
    let tagStatus = CCCryptorGCMFinal(
      cryptor,
      &tagBuffer,
      gcmTagLength
    )

    guard tagStatus == kCCSuccess else {
      throw SecurityProviderError.authenticationTagGenerationFailed(tagStatus)
    }

    // Clean up
    CCCryptorRelease(cryptor)

    // Return ciphertext with authentication tag
    return ciphertext[0..<bytesWritten + finalBytesWritten] + tagBuffer
  }

  /// Performs AES-GCM decryption.
  ///
  /// - Parameters:
  ///   - data: The ciphertext with authentication tag
  ///   - key: The encryption key
  ///   - iv: The initialisation vector/nonce
  ///   - authenticatedData: Additional authenticated data
  /// - Returns: The decrypted plaintext
  /// - Throws: SecurityProviderError if decryption fails
  private static func decryptAES_GCM(
    data: [UInt8],
    key: [UInt8],
    iv: [UInt8],
    authenticatedData: [UInt8]? = nil
  ) throws -> [UInt8] {
    // Validate data length (must include tag)
    guard data.count >= gcmTagLength else {
      throw SecurityProviderError.invalidDataFormat
    }

    // Extract ciphertext and tag
    let ciphertextLength = data.count - gcmTagLength
    let ciphertext = Array(data[0..<ciphertextLength])
    let tag = Array(data[ciphertextLength..<data.count])

    // Create cryptor reference
    var cryptorRef: CCCryptorRef?
    
    // Use withUnsafeBytes for key and IV to avoid pointer arithmetic issues
    let status = key.withUnsafeBytes { keyBytes in
      iv.withUnsafeBytes { ivBytes in
        CCCryptorCreateWithMode(
          CCOperation(kCCDecrypt),
          CCMode(kCCModeGCM),
          CCAlgorithm(kCCAlgorithmAES),
          CCPadding(ccNoPadding),
          ivBytes.baseAddress,
          keyBytes.baseAddress,
          key.count,
          nil,
          0,
          0,
          0,
          &cryptorRef
        )
      }
    }

    guard status == kCCSuccess, let cryptor = cryptorRef else {
      throw SecurityProviderError.cryptorCreationFailed(status)
    }
    
    // Process additional authenticated data if provided
    if let aad = authenticatedData, !aad.isEmpty {
      let aadStatus = CCCryptorGCMAddAAD(cryptor, aad, aad.count)
      guard aadStatus == kCCSuccess else {
        throw SecurityProviderError.aadProcessingFailed(aadStatus)
      }
    }

    // Prepare plaintext buffer (same size as ciphertext)
    var plaintext = [UInt8](repeating: 0, count: ciphertext.count)
    var bytesWritten = 0
    
    // Decrypt the data
    let plaintextCount = plaintext.count // Create a local copy
    let decStatus = ciphertext.withUnsafeBytes { ciphertextBytes in
      return plaintext.withUnsafeMutableBytes { plaintextBytes in
        CCCryptorUpdate(
          cryptor,
          ciphertextBytes.baseAddress,
          ciphertext.count,
          plaintextBytes.baseAddress,
          plaintextCount, // Use the local copy
          &bytesWritten
        )
      }
    }

    guard decStatus == kCCSuccess else {
      throw SecurityProviderError.decryptionFailed("CCCryptorUpdate failed with status \(decStatus)")
    }

    // Finalize decryption
    var finalBytesWritten = 0
    let remainingPlaintextCount = plaintextCount - bytesWritten // Calculate remaining space
    
    let finalStatus = plaintext.withUnsafeMutableBytes { plaintextBytes in
      let baseAddress = plaintextBytes.baseAddress!.advanced(by: bytesWritten)
      return CCCryptorFinal(
        cryptor,
        baseAddress,
        remainingPlaintextCount, // Use the calculated remaining space
        &finalBytesWritten
      )
    }

    guard finalStatus == kCCSuccess else {
      throw SecurityProviderError.decryptionFinalisationFailed(finalStatus)
    }

    // Verify the authentication tag
    var expectedTag = [UInt8](repeating: 0, count: gcmTagLength)
    let tagStatus = CCCryptorGCMFinal(
      cryptor,
      &expectedTag,
      gcmTagLength
    )

    guard tagStatus == kCCSuccess else {
      throw SecurityProviderError.authenticationTagVerificationFailed(tagStatus)
    }

    // Compare tags
    guard tag.count == expectedTag.count && zip(tag, expectedTag).allSatisfy({ $0 == $1 }) else {
      throw SecurityProviderError.authenticationTagMismatch
    }

    // Clean up
    CCCryptorRelease(cryptor)

    // Return plaintext
    return Array(plaintext[0..<bytesWritten + finalBytesWritten])
  }

  /// Performs AES-CBC encryption.
  ///
  /// - Parameters:
  ///   - data: The plaintext to encrypt
  ///   - key: The encryption key
  ///   - iv: The initialisation vector
  /// - Returns: The ciphertext
  /// - Throws: SecurityProviderError if encryption fails
  private static func encryptAES_CBC(
    data: [UInt8],
    key: [UInt8],
    iv: [UInt8]
  ) throws -> [UInt8] {
    // Create output buffer (includes potential padding)
    let bufferSize = data.count + kCCBlockSizeAES128
    var ciphertext = [UInt8](repeating: 0, count: bufferSize)
    var bytesWritten = 0
    
    // Use withUnsafeBytes for key, IV, and data to avoid pointer arithmetic issues
    let status = key.withUnsafeBytes { keyBytes in
      iv.withUnsafeBytes { ivBytes in
        data.withUnsafeBytes { dataBytes in
          return ciphertext.withUnsafeMutableBytes { ciphertextBytes in
            CCCrypt(
              CCOperation(kCCEncrypt),
              CCAlgorithm(kCCAlgorithmAES),
              CCOptions(kCCOptionPKCS7Padding),
              keyBytes.baseAddress,
              key.count,
              ivBytes.baseAddress,
              dataBytes.baseAddress,
              data.count,
              ciphertextBytes.baseAddress,
              bufferSize,
              &bytesWritten
            )
          }
        }
      }
    }

    guard status == kCCSuccess else {
      throw SecurityProviderError.encryptionFailed("CCCrypt failed with status \(status)")
    }

    // Return actual ciphertext (trim buffer)
    return Array(ciphertext[0..<bytesWritten])
  }

  /// Performs AES-CBC decryption.
  ///
  /// - Parameters:
  ///   - data: The ciphertext to decrypt
  ///   - key: The encryption key
  ///   - iv: The initialisation vector
  /// - Returns: The decrypted plaintext
  /// - Throws: SecurityProviderError if decryption fails
  private static func decryptAES_CBC(
    data: [UInt8],
    key: [UInt8],
    iv: [UInt8]
  ) throws -> [UInt8] {
    // Validate sizes
    guard key.count == kCCKeySizeAES256 else {
      throw SecurityProviderError.invalidKeySize(expected: kCCKeySizeAES256, actual: key.count)
    }
    
    guard iv.count == cbcIVLength else {
      throw SecurityProviderError.invalidIVSize(expected: cbcIVLength, actual: iv.count)
    }
    
    // Create output buffer
    var plaintext = [UInt8](repeating: 0, count: data.count)
    var bytesWritten = 0
    let plaintextCount = plaintext.count // Create local copy to avoid overlapping access
    
    // Use withUnsafeBytes for key, IV, and data to avoid pointer arithmetic issues
    let status = key.withUnsafeBytes { keyBytes in
      iv.withUnsafeBytes { ivBytes in
        data.withUnsafeBytes { dataBytes in
          return plaintext.withUnsafeMutableBytes { plaintextBytes in
            CCCrypt(
              CCOperation(kCCDecrypt),
              CCAlgorithm(kCCAlgorithmAES),
              CCOptions(kCCOptionPKCS7Padding),
              keyBytes.baseAddress,
              key.count,
              ivBytes.baseAddress,
              dataBytes.baseAddress,
              data.count,
              plaintextBytes.baseAddress,
              plaintextCount, // Use local copy instead of plaintext.count
              &bytesWritten
            )
          }
        }
      }
    }

    guard status == kCCSuccess else {
      throw SecurityProviderError.decryptionFailed("CCCrypt failed with status \(status)")
    }

    // Return the decrypted bytes, truncated to the actual size
    return Array(plaintext[0..<bytesWritten])
  }

  /// Convert a hash algorithm to its CCHmacAlgorithm equivalent.
  ///
  /// - Parameter algorithm: The hash algorithm to convert
  /// - Returns: The CCHmacAlgorithm equivalent
  /// - Throws: SecurityProviderError if the algorithm is unsupported
  static func toCCHmacAlgorithm(
    algorithm: HashAlgorithm
  ) throws -> CCHmacAlgorithm {
    switch algorithm {
        case .sha256:
            return CCHmacAlgorithm(kCCHmacAlgSHA256)
        case .sha512:
            return CCHmacAlgorithm(kCCHmacAlgSHA512)
        case .blake2b:
            // CommonCrypto doesn't support BLAKE2b directly
            // We'll use a related encryption algorithm to represent the error
            throw SecurityProviderError.hashingFailed("BLAKE2b algorithm is not supported by CommonCrypto")
    }
  }
}
