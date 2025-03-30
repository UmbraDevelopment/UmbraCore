import Foundation
import SecurityCoreTypes

/**
 # EncryptionProviderProtocol

 Defines the core encryption capabilities required for all security provider implementations.

 This protocol establishes the minimum set of cryptographic operations that each security
 provider must implement, regardless of whether it's using CryptoKit, Ring FFI, or the
 basic fallback implementation.

 Each concrete implementation will provide these operations using different underlying
 cryptographic libraries while maintaining a consistent interface.
 */
public protocol EncryptionProviderProtocol: Sendable {
  /**
   The type of security provider implementation.

   This allows clients to determine which provider they're using programmatically
   for debugging, logging, or feature detection.
   */
  var providerType: SecurityProviderType { get }

  /**
   Encrypts plaintext data using the specified key and initialisation vector.

   - Parameters:
      - plaintext: The data to encrypt
      - key: The encryption key
      - iv: The initialisation vector/nonce
      - config: Additional configuration options
   - Returns: The encrypted data
   - Throws: CryptoError if encryption fails
   */
  func encrypt(plaintext: Data, key: Data, iv: Data, config: SecurityConfigDTO) throws -> Data

  /**
   Decrypts ciphertext using the specified key and initialisation vector.

   - Parameters:
      - ciphertext: The data to decrypt
      - key: The encryption key
      - iv: The initialisation vector/nonce
      - config: Additional configuration options
   - Returns: The decrypted plaintext
   - Throws: CryptoError if decryption fails
   */
  func decrypt(ciphertext: Data, key: Data, iv: Data, config: SecurityConfigDTO) throws -> Data

  /**
   Generates a cryptographic key of the specified size.

   - Parameters:
      - size: The key size in bits
      - config: Additional configuration options
   - Returns: The generated key data
   - Throws: CryptoError if key generation fails
   */
  func generateKey(size: Int, config: SecurityConfigDTO) throws -> Data

  /**
   Generates a random initialisation vector/nonce of the specified size.

   - Parameters:
      - size: The IV/nonce size in bytes
   - Returns: The generated IV/nonce data
   - Throws: CryptoError if IV generation fails
   */
  func generateIV(size: Int) throws -> Data

  /**
   Creates a cryptographic hash of the input data.

   - Parameters:
      - data: The data to hash
      - algorithm: The hash algorithm to use
   - Returns: The resulting hash value
   - Throws: CryptoError if hashing fails
   */
  func hash(data: Data, algorithm: String) throws -> Data
}
