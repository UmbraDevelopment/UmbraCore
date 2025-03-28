import CommonCrypto
import CryptoInterfaces
import CryptoTypes
import Foundation
import SecurityTypes

/**
 # Crypto Service Implementation

 This actor provides cryptographic operations with proper thread safety using Swift concurrency.
 It implements the CryptoServiceProtocol with support for:

 - Secure random key generation
 - AES-GCM encryption and decryption
 - Password-based key derivation
 - HMAC generation

 All operations are properly isolated through Swift's actor system to ensure thread safety.

 This implementation follows the Alpha Dot Five architecture with:
 - Domain-specific error types
 - Proper British spelling in documentation
 - Actor-based concurrency protection
 - Modular organisation of functionality
 */
public actor CryptoServiceImpl: CryptoServiceProtocol {
  /// Configuration options for this service instance
  private let options: CryptoServiceOptions

  /// The key size for AES-256 keys in bytes
  private let defaultKeySize: Int

  /// The IV size for AES-GCM in bytes
  private let ivSize: Int

  /// Standard PBKDF2 iteration count for key derivation
  private let defaultIterations: Int

  /// Initialises a new CryptoServiceImpl instance with default options.
  public init() {
    options = .default
    defaultKeySize=32
    ivSize=12
    defaultIterations=10000
  }

  /// Initialises a new CryptoServiceImpl instance with the specified options.
  /// - Parameter options: Configuration options for cryptographic operations
  public init(options: CryptoServiceOptions) {
    self.options=options
    defaultKeySize=options.preferredKeySize
    ivSize=options.ivSize
    defaultIterations=options.defaultIterations
  }

  /**
   Generates a cryptographically secure random key.

   This method leverages the secure random generator provided by the system
   to create a cryptographically strong random key for encryption operations.

   - Parameter length: The length of the key to generate in bytes
   - Returns: A SecureBytes instance containing the generated key
   - Throws: CryptoError if key generation fails
   */
  public func generateSecureRandomKey(length: Int) async throws -> SecureBytes {
    var bytes=[UInt8](repeating: 0, count: length)
    let status=SecRandomCopyBytes(kSecRandomDefault, length, &bytes)

    guard status == errSecSuccess else {
      throw CryptoError
        .keyGenerationFailed(reason: "Random generation failed with status: \(status)")
    }

    return SecureBytes(bytes: bytes)
  }

  /**
   Encrypts data using AES-GCM.

   This method provides authenticated encryption with the AES-GCM algorithm.
   Both the plaintext and any associated data are authenticated, ensuring
   data integrity and confidentiality.

   - Parameters:
     - data: The data to encrypt
     - key: The encryption key
     - iv: The initialisation vector
   - Returns: The encrypted data as SecureBytes
   - Throws: CryptoError if encryption fails
   */
  public func encrypt(
    _ data: SecureBytes,
    using key: SecureBytes,
    iv: SecureBytes
  ) async throws -> SecureBytes {
    // Validate inputs
    guard !key.isEmpty else {
      throw CryptoError.invalidKey(reason: "Encryption key cannot be empty")
    }

    guard !data.isEmpty else {
      throw CryptoError.invalidInput(reason: "Data to encrypt cannot be empty")
    }

    guard iv.count == ivSize else {
      throw CryptoError.invalidInput(reason: "IV must be \(ivSize) bytes, got \(iv.count)")
    }

    do {
      let dataBytes=data.bytes()
      let keyBytes=key.bytes()
      let ivBytes=iv.bytes()

      // Perform AES-GCM encryption using our utility
      let encryptedBytes=try CryptoOperations.encryptAES_GCM(
        data: dataBytes,
        key: keyBytes,
        iv: ivBytes
      )

      return SecureBytes(bytes: encryptedBytes)
    } catch let error as CryptoError {
      throw error
    } catch {
      throw CryptoError.encryptionFailed(reason: error.localizedDescription)
    }
  }

  /**
   Decrypts data using AES-GCM.

   This method provides authenticated decryption with the AES-GCM algorithm.
   It verifies the authenticity of the ciphertext before decryption.

   - Parameters:
     - data: The data to decrypt
     - key: The decryption key
     - iv: The initialisation vector
   - Returns: The decrypted data as SecureBytes
   - Throws: CryptoError if decryption fails
   */
  public func decrypt(
    _ data: SecureBytes,
    using key: SecureBytes,
    iv: SecureBytes
  ) async throws -> SecureBytes {
    // Validate inputs
    guard !key.isEmpty else {
      throw CryptoError.invalidKey(reason: "Decryption key cannot be empty")
    }

    guard !data.isEmpty else {
      throw CryptoError.invalidInput(reason: "Data to decrypt cannot be empty")
    }

    guard iv.count == ivSize else {
      throw CryptoError.invalidInput(reason: "IV must be \(ivSize) bytes, got \(iv.count)")
    }

    do {
      let dataBytes=data.bytes()
      let keyBytes=key.bytes()
      let ivBytes=iv.bytes()

      // Perform AES-GCM decryption using our utility
      let decryptedBytes=try CryptoOperations.decryptAES_GCM(
        data: dataBytes,
        key: keyBytes,
        iv: ivBytes
      )

      return SecureBytes(bytes: decryptedBytes)
    } catch let error as CryptoError {
      throw error
    } catch {
      throw CryptoError.decryptionFailed(reason: error.localizedDescription)
    }
  }

  /**
   Derives a key from a password using PBKDF2.

   This method uses the PBKDF2 algorithm to derive a cryptographic key from a password.
   The derived key is suitable for use in encryption and decryption operations.

   - Parameters:
     - password: The password to derive the key from
     - salt: The salt to use for key derivation
     - iterations: The number of iterations to use for key derivation
   - Returns: The derived key as SecureBytes
   - Throws: CryptoError if key derivation fails
   */
  public func deriveKey(
    from password: String,
    salt: SecureBytes,
    iterations: Int=10000
  ) async throws -> SecureBytes {
    guard !password.isEmpty else {
      throw CryptoError.invalidInput(reason: "Password cannot be empty")
    }

    guard !salt.isEmpty else {
      throw CryptoError.invalidInput(reason: "Salt cannot be empty")
    }

    guard iterations > 0 else {
      throw CryptoError.invalidInput(reason: "Iterations must be greater than 0")
    }

    // Convert password to data
    guard let passwordData=password.data(using: .utf8) else {
      throw CryptoError.invalidInput(reason: "Could not convert password to UTF-8 data")
    }

    // Allocate output buffer for the derived key
    var derivedKeyData=[UInt8](repeating: 0, count: defaultKeySize)

    // Get salt bytes
    let saltBytes=salt.bytes()

    // Perform PBKDF2 key derivation using CommonCrypto
    let result=CCKeyDerivationPBKDF(
      CCPBKDFAlgorithm(kCCPBKDF2),
      password, passwordData.count,
      saltBytes, saltBytes.count,
      CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
      UInt32(iterations),
      &derivedKeyData, derivedKeyData.count
    )

    guard result == kCCSuccess else {
      throw CryptoError
        .keyGenerationFailed(reason: "PBKDF2 key derivation failed with status: \(result)")
    }

    return SecureBytes(bytes: derivedKeyData)
  }

  /**
   Generates a message authentication code (HMAC) using SHA-256.

   This method creates an HMAC for the provided data using the specified key.
   The resulting authentication code can be used to verify data integrity.

   - Parameters:
     - data: The data to authenticate
     - key: The authentication key
   - Returns: The HMAC as SecureBytes
   - Throws: CryptoError if HMAC generation fails
   */
  public func generateHMAC(
    for data: SecureBytes,
    using key: SecureBytes
  ) async throws -> SecureBytes {
    guard !key.isEmpty else {
      throw CryptoError.invalidKey(reason: "HMAC key cannot be empty")
    }

    guard !data.isEmpty else {
      throw CryptoError.invalidInput(reason: "Data for HMAC cannot be empty")
    }

    let dataBytes=data.bytes()
    let keyBytes=key.bytes()

    // Create output buffer for the HMAC
    var macOut=[UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))

    // Compute HMAC-SHA256
    CCHmac(
      CCHmacAlgorithm(kCCHmacAlgSHA256),
      keyBytes, keyBytes.count,
      dataBytes, dataBytes.count,
      &macOut
    )

    return SecureBytes(bytes: macOut)
  }
}

// MARK: - Utility Extensions for SecureBytes

extension SecureBytes {
  /// Returns the contained bytes as a standard array
  /// Note: This breaks the secure containment and should be used carefully
  func bytes() -> [UInt8] {
    var result: [UInt8]=[]
    for i in 0..<count {
      result.append(self[i])
    }
    return result
  }
}
