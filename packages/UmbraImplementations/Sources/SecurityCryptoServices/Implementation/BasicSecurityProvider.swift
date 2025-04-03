import CommonCrypto
import Foundation
import SecurityCoreInterfaces
import CoreSecurityTypes
import DomainSecurityTypes
import UmbraErrors

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
    guard let algorithm = getAlgorithm(config: config) else {
      throw CoreSecurityError.invalidInput("Invalid or unsupported algorithm")
    }

    // Validate key size
    guard validateKeySize(key.count, algorithm: config.encryptionAlgorithm) != nil else {
      throw CoreSecurityError.invalidInput("Invalid key size for algorithm \(config.encryptionAlgorithm)")
    }

    // Validate IV size (must be 16 bytes for AES-CBC)
    guard iv.count == 16 else {
      throw CoreSecurityError.invalidInput("Invalid IV size, must be 16 bytes for AES-CBC")
    }

    // Calculate buffer sizes for encryption
    let dataLength = plaintext.count
    let bufferSize = dataLength + kCCBlockSizeAES128
    var encryptedBytes = [UInt8](repeating: 0, count: bufferSize)
    var encryptedLength = 0

    // Setup encryption context
    var cryptorRef: CCCryptorRef? = nil
    var status = CCCryptorCreate(
      CCOperation(kCCEncrypt),
      algorithm,
      CCOptions(kCCOptionPKCS7Padding),
      (key as NSData).bytes,
      key.count,
      (iv as NSData).bytes,
      &cryptorRef
    )

    // Check context creation
    guard status == kCCSuccess, cryptorRef != nil else {
      throw CoreSecurityError.cryptoError("Failed to create encryption context with status \(status)")
    }

    defer {
      // Always release the cryptor when done
      CCCryptorRelease(cryptorRef)
    }

    // Process the data in chunks
    let chunkSize = 64 * 1024 // 64KB chunks
    var offset = 0

    while offset < dataLength {
      let chunkLength = min(chunkSize, dataLength - offset)
      var bytesEncrypted = 0

      // Create a pointer to the current position in the output buffer
      let outputPos = offset + Int(encryptedLength)
      let outputBuffer = UnsafeMutableRawPointer(&encryptedBytes).bindMemory(
        to: UInt8.self,
        capacity: bufferSize
      ) + outputPos

      // Update with the current chunk
      status = plaintext.withUnsafeBytes { plainBytes in
        let plainBuffer = plainBytes.baseAddress!.bindMemory(
          to: UInt8.self,
          capacity: dataLength
        ) + offset

        return CCCryptorUpdate(
          cryptorRef,
          plainBuffer,
          chunkLength,
          outputBuffer,
          bufferSize - outputPos,
          &bytesEncrypted
        )
      }

      guard status == kCCSuccess else {
        throw CoreSecurityError.cryptoError("Encryption update failed with status \(status)")
      }

      encryptedLength += bytesEncrypted
      offset += chunkLength
    }

    // Finalize encryption
    var finalSize = 0
    let finalizePos = Int(encryptedLength)
    let finalizeBuffer = UnsafeMutableRawPointer(&encryptedBytes).bindMemory(
      to: UInt8.self,
      capacity: bufferSize
    ) + finalizePos

    status = CCCryptorFinal(
      cryptorRef,
      finalizeBuffer,
      bufferSize - finalizePos,
      &finalSize
    )

    guard status == kCCSuccess else {
      throw CoreSecurityError.cryptoError("Encryption finalization failed with status \(status)")
    }

    // Create final encrypted data
    encryptedLength += finalSize
    return Data(bytes: encryptedBytes, count: encryptedLength)
  }

  /**
   Decrypts ciphertext using AES-CBC with PKCS#7 padding.

   - Parameters:
      - ciphertext: Data to decrypt
      - key: Decryption key
      - iv: Initialisation vector (must match the one used for encryption)
      - config: Additional configuration options
   - Returns: Decrypted data
   - Throws: CryptoError if decryption fails
   */
  public func decrypt(
    ciphertext: Data,
    key: Data,
    iv: Data,
    config: SecurityConfigDTO
  ) throws -> Data {
    guard let algorithm = getAlgorithm(config: config) else {
      throw CoreSecurityError.invalidInput("Invalid or unsupported algorithm")
    }

    // Validate key size
    guard validateKeySize(key.count, algorithm: config.encryptionAlgorithm) != nil else {
      throw CoreSecurityError.invalidInput("Invalid key size for algorithm \(config.encryptionAlgorithm)")
    }

    // Validate IV size (must be 16 bytes for AES-CBC)
    guard iv.count == 16 else {
      throw CoreSecurityError.invalidInput("Invalid IV size, must be 16 bytes for AES-CBC")
    }

    // Calculate buffer sizes for decryption
    let dataLength = ciphertext.count
    let bufferSize = dataLength + kCCBlockSizeAES128
    var decryptedBytes = [UInt8](repeating: 0, count: bufferSize)
    var decryptedLength = 0

    // Setup decryption context
    var cryptorRef: CCCryptorRef? = nil
    var status = CCCryptorCreate(
      CCOperation(kCCDecrypt),
      algorithm,
      CCOptions(kCCOptionPKCS7Padding),
      (key as NSData).bytes,
      key.count,
      (iv as NSData).bytes,
      &cryptorRef
    )

    // Check context creation
    guard status == kCCSuccess, cryptorRef != nil else {
      throw CoreSecurityError.cryptoError("Failed to create decryption context with status \(status)")
    }

    defer {
      // Always release the cryptor when done
      CCCryptorRelease(cryptorRef)
    }

    // Process the data in chunks
    let chunkSize = 64 * 1024 // 64KB chunks
    var offset = 0

    while offset < dataLength {
      let chunkLength = min(chunkSize, dataLength - offset)
      var bytesDecrypted = 0

      // Create a pointer to the current position in the output buffer
      let outputPos = offset + Int(decryptedLength)
      let outputBuffer = UnsafeMutableRawPointer(&decryptedBytes).bindMemory(
        to: UInt8.self,
        capacity: bufferSize
      ) + outputPos

      // Update with the current chunk
      status = ciphertext.withUnsafeBytes { cipherBytes in
        let cipherBuffer = cipherBytes.baseAddress!.bindMemory(
          to: UInt8.self,
          capacity: dataLength
        ) + offset

        return CCCryptorUpdate(
          cryptorRef,
          cipherBuffer,
          chunkLength,
          outputBuffer,
          bufferSize - outputPos,
          &bytesDecrypted
        )
      }

      guard status == kCCSuccess else {
        throw CoreSecurityError.cryptoError("Decryption update failed with status \(status)")
      }

      decryptedLength += bytesDecrypted
      offset += chunkLength
    }

    // Finalize decryption
    var finalSize = 0
    let finalizePos = Int(decryptedLength)
    let finalizeBuffer = UnsafeMutableRawPointer(&decryptedBytes).bindMemory(
      to: UInt8.self,
      capacity: bufferSize
    ) + finalizePos

    status = CCCryptorFinal(
      cryptorRef,
      finalizeBuffer,
      bufferSize - finalizePos,
      &finalSize
    )

    guard status == kCCSuccess else {
      throw CoreSecurityError.cryptoError("Decryption finalization failed with status \(status)")
    }

    // Create final decrypted data
    decryptedLength += finalSize
    return Data(bytes: decryptedBytes, count: decryptedLength)
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
      throw CoreSecurityError.invalidInput("Invalid key size, must be 128, 192, or 256 bits")
    }

    let keyBytes = size / 8
    var keyData = Data(count: keyBytes)

    let result = keyData.withUnsafeMutableBytes { bytes in
      guard let baseAddress = bytes.baseAddress else { return Int32(errSecAllocate) }
      return SecRandomCopyBytes(kSecRandomDefault, keyBytes, baseAddress)
    }

    guard result == errSecSuccess else {
      throw CoreSecurityError.cryptoError("Key generation failed with status \(result)")
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
      throw CoreSecurityError.invalidInput("IV size must be greater than 0")
    }

    var ivData = Data(count: size)

    let result = ivData.withUnsafeMutableBytes { bytes in
      guard let baseAddress = bytes.baseAddress else { return Int32(errSecAllocate) }
      return SecRandomCopyBytes(kSecRandomDefault, size, baseAddress)
    }

    guard result == errSecSuccess else {
      throw CoreSecurityError.cryptoError("IV generation failed with status \(result)")
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
        var hashBytes = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { dataBytes in
          _ = CC_SHA256(dataBytes.baseAddress, CC_LONG(data.count), &hashBytes)
        }
        return Data(hashBytes)

      case "SHA384":
        var hashBytes = [UInt8](repeating: 0, count: Int(CC_SHA384_DIGEST_LENGTH))
        data.withUnsafeBytes { dataBytes in
          _ = CC_SHA384(dataBytes.baseAddress, CC_LONG(data.count), &hashBytes)
        }
        return Data(hashBytes)

      case "SHA512":
        var hashBytes = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
        data.withUnsafeBytes { dataBytes in
          _ = CC_SHA512(dataBytes.baseAddress, CC_LONG(data.count), &hashBytes)
        }
        return Data(hashBytes)

      default:
        throw CoreSecurityError.invalidInput("Unsupported hash algorithm: \(algorithm)")
    }
  }

  // MARK: - Private Helpers

  private func validateKeySize(_ keySize: Int, algorithm: String) -> Int? {
    let keySizeBits = keySize * 8

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
    switch config.encryptionAlgorithm {
      case .aes128CBC, .aes192CBC, .aes256CBC:
        return CCAlgorithm(kCCAlgorithmAES)
      default:
        return nil
    }
  }
}
