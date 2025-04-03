import CryptoTypes
import DomainSecurityTypes
import UmbraErrors
import UmbraErrorsDTOs

/**
 # CryptoXPCServiceProtocol

 Protocol defining cryptographic operations available via XPC.

 This protocol provides a standardised interface for cryptographic
 operations that can be performed across process boundaries using
 XPC communication, following the Alpha Dot Five architecture.

 All methods are designed to work with secure identifier-based data access,
 use proper domain-specific errors, and follow Swift concurrency best practices.
 */
public protocol CryptoXPCServiceProtocol: Sendable {
  // MARK: - Encryption Operations

  /**
   Encrypts data using the specified key.

   - Parameters:
      - dataIdentifier: Identifier for the data to encrypt in secure storage
      - keyIdentifier: The identifier of the key to use
      - options: Optional configuration options

   - Returns: Result with identifier for the encrypted data or error
   */
  func encrypt(
    dataIdentifier: String,
    keyIdentifier: String,
    options: CryptoOperationOptionsDTO?
  ) async -> Result<String, UmbraErrorsDTOs.ErrorDTO>

  /**
   Decrypts data using the specified key.

   - Parameters:
      - encryptedDataIdentifier: Identifier for the encrypted data in secure storage
      - keyIdentifier: The identifier of the key to use
      - options: Optional configuration options

   - Returns: Result with identifier for the decrypted data or error
   */
  func decrypt(
    encryptedDataIdentifier: String,
    keyIdentifier: String,
    options: CryptoOperationOptionsDTO?
  ) async -> Result<String, UmbraErrorsDTOs.ErrorDTO>

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
  ) async -> Result<String, UmbraErrorsDTOs.ErrorDTO>

  /**
   Exports a cryptographic key.

   - Parameter keyIdentifier: The identifier of the key to export

   - Returns: Result with the data identifier for key material or error
   */
  func exportKey(
    keyIdentifier: String
  ) async -> Result<String, UmbraErrorsDTOs.ErrorDTO>

  /**
   Imports a cryptographic key.

   - Parameters:
      - keyDataIdentifier: Identifier for the key material in secure storage
      - metadata: Metadata for the imported key

   - Returns: Result with key identifier or error
   */
  func importKey(
    keyDataIdentifier: String,
    metadata: KeyMetadataDTO
  ) async -> Result<String, UmbraErrorsDTOs.ErrorDTO>

  /**
   Deletes a cryptographic key.

   - Parameter keyIdentifier: The identifier of the key to delete

   - Returns: Result with success flag or error
   */
  func deleteKey(
    keyIdentifier: String
  ) async -> Result<Bool, UmbraErrorsDTOs.ErrorDTO>

  // MARK: - Signing and Verification

  /**
   Signs data using the specified key.

   - Parameters:
      - dataIdentifier: Identifier for the data to sign in secure storage
      - keyIdentifier: The identifier of the signing key
      - options: Optional signing options

   - Returns: Result with identifier for the signature data or error
   */
  func sign(
    dataIdentifier: String,
    keyIdentifier: String,
    options: SigningOptionsDTO?
  ) async -> Result<String, UmbraErrorsDTOs.ErrorDTO>

  /**
   Verifies a signature against data using the specified key.

   - Parameters:
      - signatureIdentifier: Identifier for the signature in secure storage
      - dataIdentifier: Identifier for the original data in secure storage
      - keyIdentifier: The identifier of the verification key
      - options: Optional verification options

   - Returns: Result with verification result or error
   */
  func verify(
    signatureIdentifier: String,
    dataIdentifier: String,
    keyIdentifier: String,
    options: SigningOptionsDTO?
  ) async -> Result<Bool, UmbraErrorsDTOs.ErrorDTO>

  // MARK: - Utility Functions

  /**
   Generates secure random bytes.

   - Parameter length: Number of random bytes to generate

   - Returns: Result with identifier for the random data or error
   */
  func generateRandomBytes(
    length: Int
  ) async -> Result<String, UmbraErrorsDTOs.ErrorDTO>

  /**
   Computes a cryptographic hash of the provided data.

   - Parameters:
     - dataIdentifier: Identifier for the data to hash in secure storage
     - algorithm: Hash algorithm to use
   - Returns: Result with identifier for the hash data or error
   */
  func hash(
    dataIdentifier: String,
    algorithm: CoreSecurityTypes.HashAlgorithm
  ) async -> Result<String, UmbraErrorsDTOs.ErrorDTO>
}
