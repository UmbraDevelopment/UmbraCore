import CoreSecurityTypes
import DomainSecurityTypes
import Foundation

/**
 # Application Security Provider Protocol

 The ApplicationSecurityProviderProtocol defines the primary interface for accessing all security-related
 functionality in UmbraCore applications. It serves as the main entry point for the security subsystem,
 coordinating cryptographic operations, key management, and secure storage for application-level security needs.

 ## Responsibilities

 * Providing access to cryptographic operations
 * Managing security keys and certificates
 * Handling secure data storage and retrieval
 * Coordinating security-related services

 ## Usage

 The application security provider should be created through the `SecurityProviderFactory` and
 accessed through dependency injection in client code.
 */
public protocol ApplicationSecurityProviderProtocol: Sendable {
  /// Access to the cryptographic service implementation
  var cryptoService: any ApplicationCryptoServiceProtocol { get }

  /// Access to the key management service implementation
  var keyManager: any KeyManagementProtocol { get }

  /// Access to the secure storage service implementation
  var secureStorage: any SecureStorageProtocol { get }

  /**
   Encrypts data using the specified configuration.

   - Parameters:
     - data: The data to encrypt
     - config: Configuration for the encryption operation
   - Returns: Result containing the encrypted data or an error
   */
  func encrypt(data: Data, with config: EncryptionConfig) async throws -> EncryptionResult

  /**
   Decrypts data using the specified configuration.

   - Parameters:
     - data: The encrypted data to decrypt
     - config: Configuration for the decryption operation
   - Returns: Result containing the decrypted data or an error
   */
  func decrypt(data: Data, with config: DecryptionConfig) async throws -> DecryptionResult

  /**
   Signs data using the specified key and algorithm.

   - Parameters:
     - data: The data to sign
     - key: The key identifier to use for signing
     - algorithm: The signing algorithm to use
   - Returns: Result containing the signature or an error
   */
  func sign(
    data: Data,
    using key: KeyIdentifier,
    algorithm: SigningAlgorithm
  ) async throws -> SignatureResult

  /**
   Verifies a signature for the given data.

   - Parameters:
     - signature: The signature to verify
     - data: The data that was signed
     - key: The key identifier to use for verification
     - algorithm: The signing algorithm that was used
   - Returns: Result indicating if the signature is valid
   */
  func verify(
    signature: Data,
    for data: Data,
    using key: KeyIdentifier,
    algorithm: SigningAlgorithm
  ) async throws -> VerificationResult

  /**
   Securely stores data using the specified identifier and configuration.

   - Parameters:
     - data: The data to store securely
     - identifier: The identifier to associate with the data
     - config: Configuration for the storage operation
   - Returns: Result indicating success or failure
   */
  func storeSecurely(
    data: Data,
    identifier: String,
    config: SecureStorageConfig
  ) async throws -> StorageResult

  /**
   Retrieves securely stored data using the specified identifier.

   - Parameters:
     - identifier: The identifier associated with the data
     - config: Configuration for the retrieval operation
   - Returns: Result containing the retrieved data or an error
   */
  func retrieveSecurely(
    identifier: String,
    config: SecureStorageConfig
  ) async throws -> RetrievalResult

  /**
   Deletes securely stored data using the specified identifier.

   - Parameters:
     - identifier: The identifier associated with the data
     - config: Configuration for the deletion operation
   - Returns: Result indicating success or failure
   */
  func deleteSecurely(
    identifier: String,
    config: SecureStorageConfig
  ) async throws -> DeletionResult
}
