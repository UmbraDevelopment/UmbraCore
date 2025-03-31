import CoreSecurityTypes
import Foundation

/**
 Defines the core functionality required for a security provider.

 This protocol follows the architecture pattern for actor-isolated interfaces
 with async methods for thread safety. All implementations must be actor-based
 to ensure proper state isolation.
 */
public protocol SecurityProvider: Sendable {
  /**
   Encrypts data using the specified algorithm.

   - Parameters:
     - data: Data to encrypt
     - key: Encryption key
     - algorithm: Encryption algorithm to use

   - Returns: Encrypted data
   - Throws: CoreSecurityError if encryption fails
   */
  func encrypt(
    data: Data,
    key: Data,
    algorithm: EncryptionAlgorithm
  ) async throws -> Data

  /**
   Decrypts data using the specified algorithm.

   - Parameters:
     - data: Data to decrypt
     - key: Decryption key
     - algorithm: Encryption algorithm to use

   - Returns: Decrypted data
   - Throws: CoreSecurityError if decryption fails
   */
  func decrypt(
    data: Data,
    key: Data,
    algorithm: EncryptionAlgorithm
  ) async throws -> Data

  /**
   Hashes data using the specified algorithm.

   - Parameters:
     - data: Data to hash
     - algorithm: Hash algorithm to use

   - Returns: Hashed data
   - Throws: CoreSecurityError if hashing fails
   */
  func hash(
    data: Data,
    algorithm: HashAlgorithm
  ) async throws -> Data

  /**
   Generates a cryptographically secure random key.

   - Parameters:
     - byteCount: Number of bytes to generate

   - Returns: Random key data
   - Throws: CoreSecurityError if key generation fails
   */
  func generateRandomKey(byteCount: Int) async throws -> Data

  /**
   Verifies that a hash matches the expected data.

   - Parameters:
     - data: Original data
     - hash: Hash to verify
     - algorithm: Hash algorithm used

   - Returns: True if the hash matches, false otherwise
   - Throws: CoreSecurityError if verification fails
   */
  func verifyHash(
    data: Data,
    hash: Data,
    algorithm: HashAlgorithm
  ) async throws -> Bool
}
