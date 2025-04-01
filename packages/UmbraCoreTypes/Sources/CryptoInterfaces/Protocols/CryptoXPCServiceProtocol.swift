import CryptoTypes
import DomainSecurityTypes
import UmbraErrors

/**
 # CryptoXPCServiceProtocol

 Protocol defining cryptographic operations available via XPC.

 This protocol provides a standardised interface for cryptographic
 operations that can be performed across process boundaries using
 XPC communication, following the Alpha Dot Five architecture.

 All methods are designed to work with Foundation-independent DTOs,
 use proper domain-specific errors, and follow Swift concurrency best practices.
 */
public protocol CryptoXPCServiceProtocol: Sendable {
  // MARK: - Encryption Operations

  /**
   Encrypts data using the specified key.

   - Parameters:
      - data: The data to encrypt as SecureBytes
      - keyIdentifier: The identifier of the key to use
      - options: Optional configuration options

   - Returns: Result with encrypted data as SecureBytes or error
   */
  func encrypt(
    data: SecureBytes,
    keyIdentifier: String,
    options: CryptoOperationOptionsDTO?
  ) async -> Result<SecureBytes, UmbraErrors.Crypto.Core>

  /**
   Decrypts data using the specified key.

   - Parameters:
      - encryptedData: The encrypted data as SecureBytes
      - keyIdentifier: The identifier of the key to use
      - options: Optional configuration options

   - Returns: Result with decrypted data as SecureBytes or error
   */
  func decrypt(
    encryptedData: SecureBytes,
    keyIdentifier: String,
    options: CryptoOperationOptionsDTO?
  ) async -> Result<SecureBytes, UmbraErrors.Crypto.Core>

  // MARK: - Key Management

  /**
   Generates a new cryptographic key.

   - Parameters:
      - options: Key generation options including strength and algorithm
      - metadata: Optional metadata to associate with the key

   - Returns: Result with key identifier or error
   */
  func generateKey(
    options: KeyGenerationOptionsDTO,
    metadata: KeyMetadataDTO?
  ) async -> Result<String, UmbraErrors.Crypto.Core>

  /**
   Exports a cryptographic key.

   - Parameter keyIdentifier: The identifier of the key to export

   - Returns: Result with the key material as SecureBytes or error
   */
  func exportKey(
    keyIdentifier: String
  ) async -> Result<SecureBytes, UmbraErrors.Crypto.Core>

  /**
   Imports a cryptographic key.

   - Parameters:
      - keyData: The key material as SecureBytes
      - metadata: Metadata for the imported key

   - Returns: Result with key identifier or error
   */
  func importKey(
    keyData: SecureBytes,
    metadata: KeyMetadataDTO
  ) async -> Result<String, UmbraErrors.Crypto.Core>

  /**
   Deletes a cryptographic key.

   - Parameter keyIdentifier: The identifier of the key to delete

   - Returns: Result with success flag or error
   */
  func deleteKey(
    keyIdentifier: String
  ) async -> Result<Bool, UmbraErrors.Crypto.Core>

  // MARK: - Signing and Verification

  /**
   Signs data using the specified key.

   - Parameters:
      - data: The data to sign
      - keyIdentifier: The identifier of the signing key
      - options: Optional signing options

   - Returns: Result with signature as SecureBytes or error
   */
  func sign(
    data: SecureBytes,
    keyIdentifier: String,
    options: SigningOptionsDTO?
  ) async -> Result<SecureBytes, UmbraErrors.Crypto.Core>

  /**
   Verifies a signature against data using the specified key.

   - Parameters:
      - signature: The signature to verify
      - data: The original data
      - keyIdentifier: The identifier of the verification key
      - options: Optional verification options

   - Returns: Result with verification result or error
   */
  func verify(
    signature: SecureBytes,
    data: SecureBytes,
    keyIdentifier: String,
    options: SigningOptionsDTO?
  ) async -> Result<Bool, UmbraErrors.Crypto.Core>

  // MARK: - Utility Functions

  /**
   Generates secure random bytes.

   - Parameter length: Number of random bytes to generate

   - Returns: Result with random bytes as SecureBytes or error
   */
  func generateRandomBytes(
    length: Int
  ) async -> Result<SecureBytes, UmbraErrors.Crypto.Core>

  /**
   Calculates a hash of the provided data.

   - Parameters:
      - data: The data to hash
      - algorithm: The hashing algorithm to use

   - Returns: Result with hash as SecureBytes or error
   */
  func hash(
    data: SecureBytes,
    algorithm: HashAlgorithm
  ) async -> Result<SecureBytes, UmbraErrors.Crypto.Core>
}
