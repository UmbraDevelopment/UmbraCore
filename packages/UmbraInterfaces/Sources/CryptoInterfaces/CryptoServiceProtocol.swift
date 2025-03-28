import SecurityTypes

/**
 # Crypto Service Protocol

 Defines the core cryptographic operations required by the system.
 This protocol ensures a standard interface for all cryptographic
 service implementations, providing:

 - Secure encryption and decryption
 - Password-based key derivation
 - Secure random key generation
 - Message authentication

 All implementations must provide thread safety and proper error handling.
 */
public protocol CryptoServiceProtocol: Sendable {
  /**
   Encrypts data using AES encryption.

   This method encrypts the provided data using the specified key and initialisation vector.
   The implementation must ensure data confidentiality and integrity.

   - Parameters:
     - data: Data to encrypt
     - key: Encryption key
     - iv: Initialisation vector
   - Returns: Encrypted data as SecureBytes
   - Throws: CryptoError if encryption fails
   */
  func encrypt(_ data: SecureBytes, using key: SecureBytes, iv: SecureBytes) async throws
    -> SecureBytes

  /**
   Decrypts data using AES encryption.

   This method decrypts the provided data using the specified key and initialisation vector.
   The implementation must verify data integrity before returning decrypted content.

   - Parameters:
     - data: Data to decrypt
     - key: Decryption key
     - iv: Initialisation vector
   - Returns: Decrypted data as SecureBytes
   - Throws: CryptoError if decryption fails or authentication fails
   */
  func decrypt(_ data: SecureBytes, using key: SecureBytes, iv: SecureBytes) async throws
    -> SecureBytes

  /**
   Derives a key from a password using PBKDF2.

   This method performs key derivation to transform a user password into a cryptographic key
   using a secure key derivation function with the provided salt and iteration count.

   - Parameters:
     - password: Password to derive key from
     - salt: Salt for key derivation
     - iterations: Number of iterations for key derivation (higher is more secure)
   - Returns: Derived key as SecureBytes
   - Throws: CryptoError if key derivation fails
   */
  func deriveKey(from password: String, salt: SecureBytes, iterations: Int) async throws
    -> SecureBytes

  /**
   Generates a cryptographically secure random key.

   This method creates a random key using a cryptographically secure random number generator
   with sufficient entropy to ensure key security.

   - Parameter length: Length of the key in bytes
   - Returns: The generated key as SecureBytes
   - Throws: CryptoError if key generation fails
   */
  func generateSecureRandomKey(length: Int) async throws -> SecureBytes

  /**
   Generates a message authentication code (HMAC) using SHA-256.

   This method creates an authentication code for the provided data using the specified key,
   which can be used to verify data integrity and authenticity.

   - Parameters:
     - data: Data to authenticate
     - key: The authentication key
   - Returns: The authentication code as SecureBytes
   - Throws: CryptoError if HMAC generation fails
   */
  func generateHMAC(for data: SecureBytes, using key: SecureBytes) async throws -> SecureBytes
}
