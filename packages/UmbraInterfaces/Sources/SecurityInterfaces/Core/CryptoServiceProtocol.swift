import Foundation
import CoreSecurityTypes

/**
 # Application Cryptographic Service Protocol

 The ApplicationCryptoServiceProtocol defines the interface for performing cryptographic operations
 at the application level, including encryption, decryption, hashing, and signing.

 ## Responsibilities

 * Providing secure encryption and decryption capabilities
 * Supporting various cryptographic algorithms
 * Generating and verifying digital signatures
 * Implementing secure hashing functions

 ## Usage

 The application crypto service should be accessed through the ApplicationSecurityProviderProtocol or
 directly through dependency injection when needed.
 */
public protocol ApplicationCryptoServiceProtocol: Sendable {
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
   Computes a hash of the input data using the specified algorithm.

   - Parameters:
     - data: The data to hash
     - algorithm: The hashing algorithm to use
   - Returns: The computed hash
   - Throws: CryptoError if hashing fails
   */
  func hash(
    data: Data,
    using algorithm: HashAlgorithm
  ) async throws -> Data

  /**
   Creates a digital signature for the input data using the specified key and algorithm.

   - Parameters:
     - data: The data to sign
     - key: The key identifier to use for signing
     - algorithm: The signature algorithm to use
   - Returns: The digital signature
   - Throws: CryptoError if signing fails
   */
  func sign(
    data: Data,
    using key: KeyIdentifier,
    algorithm: SignatureAlgorithm
  ) async throws -> Data

  /**
   Verifies a digital signature against the original data.

   - Parameters:
     - signature: The signature to verify
     - data: The original data that was signed
     - key: The key identifier to use for verification
     - algorithm: The signature algorithm that was used
   - Returns: True if the signature is valid, false otherwise
   - Throws: CryptoError if verification fails
   */
  func verify(
    signature: Data,
    for data: Data,
    using key: KeyIdentifier,
    algorithm: SignatureAlgorithm
  ) async throws -> Bool

  /**
   Generates random data of the specified length.

   - Parameter length: The number of bytes to generate
   - Returns: The generated random data
   - Throws: CryptoError if random generation fails
   */
  func generateRandomData(length: Int) async throws -> Data

  /**
   Derives a key from a password or passphrase.

   - Parameters:
     - password: The password to derive from
     - salt: Salt data for the derivation
     - iterations: Number of iterations to perform
     - keyLength: Length of the derived key
     - algorithm: The key derivation algorithm to use
   - Returns: The derived key material
   - Throws: CryptoError if key derivation fails
   */
  func deriveKey(
    from password: Data,
    salt: Data,
    iterations: Int,
    keyLength: Int,
    algorithm: KeyDerivationAlgorithm
  ) async throws -> Data
}
