import CommonCrypto
import Foundation
import SecurityCoreInterfaces
import SecurityCoreTypes
import SecurityTypes

/**
 # BasicSecurityProvider

 Basic security provider implementation using CommonCrypto for AES-CBC.

 This provider offers a fallback implementation using standard cryptographic primitives
 available on most platforms. It implements AES-CBC encryption with PKCS#7 padding,
 providing a baseline level of security.

 ## Security Features

 - Uses AES-CBC for encryption
 - PKCS#7 padding for block alignment
 - Secure random number generation for keys and IVs
 - Multiple key sizes supported (128, 192, 256 bits)

 ## Platform Support

 This provider works on any platform with CommonCrypto support:
 - macOS
 - iOS
 - tvOS
 - watchOS
 */
public struct BasicSecurityProvider: EncryptionProviderProtocol {
  /// The type of provider implementation
  public let providerType: SecurityProviderType = .basic

  /// Initialises a new basic security provider
  public init() {}

  /**
   Encrypts plaintext using AES-CBC with PKCS#7 padding.

   - Parameters:
      - plaintext: Data to encrypt
      - key: Encryption key
      - iv: Initialisation vector (must be 16 bytes for AES-CBC)
      - config: Additional configuration options
   - Returns: Encrypted data
   - Throws: CryptoError if encryption fails
   */
  public func encrypt(
    plaintext: Data,
    key: Data,
    iv: Data,
    config: SecurityConfigDTO
  ) throws -> Data {
    guard let algorithm=getAlgorithm(config: config) else {
      throw SecurityProtocolError.invalidInput("Invalid or unsupported algorithm")
    }

    // Validate key size
    guard validateKeySize(key.count, algorithm: config.algorithm) != nil else {
      throw SecurityProtocolError.invalidInput("Invalid key size for algorithm \(config.algorithm)")
    }

    // Validate IV
    guard iv.count == kCCBlockSizeAES128 else {
      throw SecurityProtocolError.invalidInput("Invalid IV size, must be 16 bytes for AES-CBC")
    }

    // Create cryptor
    var cryptorRef: CCCryptorRef?
    var status=CCCryptorCreate(
      CCOperation(kCCEncrypt),
      algorithm,
      CCOptions(kCCOptionPKCS7Padding),
      (key as NSData).bytes,
      key.count,
      (iv as NSData).bytes,
      &cryptorRef
    )

    guard status == kCCSuccess, let cryptorRef else {
      throw SecurityProtocolError
        .cryptographicError("Failed to create encryption context with status \(status)")
    }

    defer {
      CCCryptorRelease(cryptorRef)
    }

    // Determine buffer size
    let outputLength=CCCryptorGetOutputLength(cryptorRef, plaintext.count, true)
    var outputBuffer=[UInt8](repeating: 0, count: outputLength)

    // Process the data
    var bytesProcessed=0
    status=plaintext.withUnsafeBytes { plaintextBytes -> CCCryptorStatus in
      guard let plaintextPtr=plaintextBytes.baseAddress else {
        return CCCryptorStatus(kCCMemoryFailure)
      }

      return CCCryptorUpdate(
        cryptorRef,
        plaintextPtr,
        plaintext.count,
        &outputBuffer,
        outputLength,
        &bytesProcessed
      )
    }

    guard status == kCCSuccess else {
      throw SecurityProtocolError
        .cryptographicError("Encryption update failed with status \(status)")
    }

    var finalBytesProcessed=0

    // Use proper pointer arithmetic with withUnsafeMutableBytes
    status=outputBuffer.withUnsafeMutableBytes { outputBufferBytes -> CCCryptorStatus in
      guard let basePtr=outputBufferBytes.baseAddress else {
        return CCCryptorStatus(kCCMemoryFailure)
      }

      // Advance the pointer by bytesProcessed
      let advancedPtr=basePtr.advanced(by: bytesProcessed)

      return CCCryptorFinal(
        cryptorRef,
        advancedPtr,
        outputLength - bytesProcessed,
        &finalBytesProcessed
      )
    }

    guard status == kCCSuccess else {
      throw SecurityProtocolError
        .cryptographicError("Encryption finalization failed with status \(status)")
    }

    return Data(outputBuffer.prefix(bytesProcessed + finalBytesProcessed))
  }

  /**
   Decrypts ciphertext using AES-CBC with PKCS#7 padding.

   - Parameters:
      - ciphertext: Data to decrypt
      - key: Decryption key
      - iv: Initialisation vector (must be 16 bytes)
      - config: Additional configuration options
   - Returns: Decrypted plaintext
   - Throws: CryptoError if decryption fails
   */
  public func decrypt(
    ciphertext: Data,
    key: Data,
    iv: Data,
    config: SecurityConfigDTO
  ) throws -> Data {
    guard let algorithm=getAlgorithm(config: config) else {
      throw SecurityProtocolError.invalidInput("Invalid or unsupported algorithm")
    }

    // Validate key size
    guard validateKeySize(key.count, algorithm: config.algorithm) != nil else {
      throw SecurityProtocolError.invalidInput("Invalid key size for algorithm \(config.algorithm)")
    }

    // Validate IV
    guard iv.count == kCCBlockSizeAES128 else {
      throw SecurityProtocolError.invalidInput("Invalid IV size, must be 16 bytes for AES-CBC")
    }

    // Create cryptor
    var cryptorRef: CCCryptorRef?
    var status=CCCryptorCreate(
      CCOperation(kCCDecrypt),
      algorithm,
      CCOptions(kCCOptionPKCS7Padding),
      (key as NSData).bytes,
      key.count,
      (iv as NSData).bytes,
      &cryptorRef
    )

    guard status == kCCSuccess, let cryptorRef else {
      throw SecurityProtocolError
        .cryptographicError("Failed to create decryption context with status \(status)")
    }

    defer {
      CCCryptorRelease(cryptorRef)
    }

    // Determine buffer size
    let outputLength=CCCryptorGetOutputLength(cryptorRef, ciphertext.count, true)
    var outputBuffer=[UInt8](repeating: 0, count: outputLength)

    // Process the data
    var bytesProcessed=0
    status=ciphertext.withUnsafeBytes { ciphertextBytes -> CCCryptorStatus in
      guard let ciphertextPtr=ciphertextBytes.baseAddress else {
        return CCCryptorStatus(kCCMemoryFailure)
      }

      return CCCryptorUpdate(
        cryptorRef,
        ciphertextPtr,
        ciphertext.count,
        &outputBuffer,
        outputLength,
        &bytesProcessed
      )
    }

    guard status == kCCSuccess else {
      throw SecurityProtocolError
        .cryptographicError("Decryption update failed with status \(status)")
    }

    var finalBytesProcessed=0

    // Use proper pointer arithmetic with withUnsafeMutableBytes
    status=outputBuffer.withUnsafeMutableBytes { outputBufferBytes -> CCCryptorStatus in
      guard let basePtr=outputBufferBytes.baseAddress else {
        return CCCryptorStatus(kCCMemoryFailure)
      }

      // Advance the pointer by bytesProcessed
      let advancedPtr=basePtr.advanced(by: bytesProcessed)

      return CCCryptorFinal(
        cryptorRef,
        advancedPtr,
        outputLength - bytesProcessed,
        &finalBytesProcessed
      )
    }

    guard status == kCCSuccess else {
      throw SecurityProtocolError
        .cryptographicError("Decryption finalization failed with status \(status)")
    }

    return Data(outputBuffer.prefix(bytesProcessed + finalBytesProcessed))
  }

  /**
   Generates a cryptographic key of the specified size.

   - Parameters:
      - size: Key size in bits (128, 192, or 256 for AES)
      - config: Additional configuration options
   - Returns: Generated key data
   - Throws: CryptoError if key generation fails
   */
  public func generateKey(size: Int, config _: SecurityConfigDTO) throws -> Data {
    // Validate key size
    guard size == 128 || size == 192 || size == 256 else {
      throw SecurityProtocolError.invalidInput("Invalid key size, must be 128, 192, or 256 bits")
    }

    let keyBytes=size / 8
    var keyData=Data(count: keyBytes)

    let result=keyData.withUnsafeMutableBytes { bytes in
      guard let baseAddress=bytes.baseAddress else { return Int32(errSecAllocate) }
      return SecRandomCopyBytes(kSecRandomDefault, keyBytes, baseAddress)
    }

    guard result == errSecSuccess else {
      throw SecurityProtocolError.cryptographicError("Key generation failed with status \(result)")
    }

    return keyData
  }

  /**
   Generates a random initialisation vector of the specified size.

   - Parameters:
      - size: IV size in bytes (typically 16 for AES-CBC)
   - Returns: Generated IV data
   - Throws: CryptoError if IV generation fails
   */
  public func generateIV(size: Int) throws -> Data {
    guard size > 0 else {
      throw SecurityProtocolError.invalidInput("IV size must be greater than 0")
    }

    var ivData=Data(count: size)

    let result=ivData.withUnsafeMutableBytes { bytes in
      guard let baseAddress=bytes.baseAddress else { return Int32(errSecAllocate) }
      return SecRandomCopyBytes(kSecRandomDefault, size, baseAddress)
    }

    guard result == errSecSuccess else {
      throw SecurityProtocolError.cryptographicError("IV generation failed with status \(result)")
    }

    return ivData
  }

  /**
   Creates a cryptographic hash of the input data.

   - Parameters:
      - data: Data to hash
      - algorithm: Hash algorithm to use (SHA256, SHA384, SHA512)
   - Returns: Hash value
   - Throws: CryptoError if hashing fails
   */
  public func hash(data: Data, algorithm: String) throws -> Data {
    switch algorithm.uppercased() {
      case "SHA256":
        var hashBytes=[UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { dataBytes in
          guard let baseAddress=dataBytes.baseAddress else { return }
          CC_SHA256(baseAddress, CC_LONG(data.count), &hashBytes)
        }
        return Data(hashBytes)

      case "SHA384":
        var hashBytes=[UInt8](repeating: 0, count: Int(CC_SHA384_DIGEST_LENGTH))
        data.withUnsafeBytes { dataBytes in
          guard let baseAddress=dataBytes.baseAddress else { return }
          CC_SHA384(baseAddress, CC_LONG(data.count), &hashBytes)
        }
        return Data(hashBytes)

      case "SHA512":
        var hashBytes=[UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
        data.withUnsafeBytes { dataBytes in
          guard let baseAddress=dataBytes.baseAddress else { return }
          CC_SHA512(baseAddress, CC_LONG(data.count), &hashBytes)
        }
        return Data(hashBytes)

      default:
        throw SecurityProtocolError.unsupportedOperation(name: "Hash algorithm \(algorithm)")
    }
  }

  // MARK: - Private Helpers

  private func validateKeySize(_ keySize: Int, algorithm: String) -> Int? {
    let keySizeBits=keySize * 8

    switch algorithm.uppercased() {
      case "AES":
        if keySizeBits == 128 || keySizeBits == 192 || keySizeBits == 256 {
          return keySizeBits
        }
      default:
        break
    }

    return nil
  }

  private func getAlgorithm(config: SecurityConfigDTO) -> CCAlgorithm? {
    switch config.algorithm.uppercased() {
      case "AES":
        CCAlgorithm(kCCAlgorithmAES)
      default:
        nil
    }
  }
}
