import Foundation
import SecurityTypes

/**
 # Cryptographic Service Protocol

 The CryptoServiceProtocol defines the interface for performing cryptographic operations,
 including encryption, decryption, hashing, and signing.

 ## Responsibilities

 * Providing secure encryption and decryption capabilities
 * Supporting various cryptographic algorithms
 * Generating and verifying digital signatures
 * Implementing secure hashing functions

 ## Usage

 The crypto service should be accessed through the SecurityProviderProtocol or
 directly through dependency injection when needed.
 */
public protocol CryptoServiceProtocol: Sendable {
  /**
   Encrypts data using the specified key and algorithm.

   - Parameters:
     - data: The data to encrypt
     - key: The key identifier to use for encryption
     - algorithm: The encryption algorithm to use
   - Returns: The encrypted data
   - Throws: CryptoError if encryption fails
   */
  func encrypt(
    data: Data,
    using key: KeyIdentifier,
    algorithm: EncryptionAlgorithm
  ) async throws -> Data

  /**
   Decrypts data using the specified key and algorithm.

   - Parameters:
     - data: The encrypted data to decrypt
     - key: The key identifier to use for decryption
     - algorithm: The encryption algorithm that was used
   - Returns: The decrypted data
   - Throws: CryptoError if decryption fails
   */
  func decrypt(
    data: Data,
    using key: KeyIdentifier,
    algorithm: EncryptionAlgorithm
  ) async throws -> Data

  /**
   Computes a hash of the given data using the specified algorithm.

   - Parameters:
     - data: The data to hash
     - algorithm: The hashing algorithm to use
   - Returns: The computed hash value
   - Throws: CryptoError if hashing fails
   */
  func hash(
    data: Data,
    using algorithm: HashAlgorithm
  ) async throws -> Data

  /**
   Signs data using the specified key and algorithm.

   - Parameters:
     - data: The data to sign
     - key: The key identifier to use for signing
     - algorithm: The signing algorithm to use
   - Returns: The computed signature
   - Throws: CryptoError if signing fails
   */
  func sign(
    data: Data,
    using key: KeyIdentifier,
    algorithm: SigningAlgorithm
  ) async throws -> Data

  /**
   Verifies a signature for the given data.

   - Parameters:
     - signature: The signature to verify
     - data: The data that was signed
     - key: The key identifier to use for verification
     - algorithm: The signing algorithm that was used
   - Returns: True if the signature is valid, false otherwise
   - Throws: CryptoError if verification fails
   */
  func verify(
    signature: Data,
    for data: Data,
    using key: KeyIdentifier,
    algorithm: SigningAlgorithm
  ) async throws -> Bool

  /**
   Generates a random sequence of bytes of the specified length.

   - Parameter length: The number of random bytes to generate
   - Returns: The generated random bytes
   - Throws: CryptoError if random generation fails
   */
  func generateRandomBytes(length: Int) async throws -> Data

  /**
   Derives a key from the provided password using the specified parameters.

   - Parameters:
     - password: The password to derive the key from
     - salt: The salt to use in the derivation
     - iterations: The number of iterations to perform
     - keyLength: The desired length of the derived key in bytes
     - algorithm: The key derivation algorithm to use
   - Returns: The derived key
   - Throws: CryptoError if key derivation fails
   */
  func deriveKey(
    from password: String,
    salt: Data,
    iterations: Int,
    keyLength: Int,
    algorithm: KeyDerivationAlgorithm
  ) async throws -> Data
}
