import CryptoKit
import Foundation
import LoggingInterfaces

/**
 * Protocol defining the security service operations.
 * Provides cryptographic operations and key management functions.
 */
public protocol SecurityProviderProtocol {
  /**
   * Encrypts data using the specified key and algorithm.
   *
   * @param data The data to encrypt
   * @param key The encryption key
   * @param algorithm The encryption algorithm to use
   * @return The encrypted data
   * @throws If encryption fails
   */
  func encryptData(
    _ data: Data,
    with key: SendableCryptoMaterial,
    using algorithm: EncryptionAlgorithm
  ) async throws -> Data

  /**
   * Decrypts data using the specified key and algorithm.
   *
   * @param data The data to decrypt
   * @param key The decryption key
   * @param algorithm The decryption algorithm to use
   * @return The decrypted data
   * @throws If decryption fails
   */
  func decryptData(
    _ data: Data,
    with key: SendableCryptoMaterial,
    using algorithm: EncryptionAlgorithm
  ) async throws -> Data

  /**
   * Generates a cryptographic key of the specified type.
   *
   * @param config The key generation configuration
   * @return The generated key
   * @throws If key generation fails
   */
  func generateKey(config: KeyGenConfig) async throws -> SendableCryptoMaterial

  /**
   * Computes a hash of the provided data using the specified algorithm.
   *
   * @param data The data to hash
   * @param algorithm The hash algorithm to use
   * @return The hash string
   * @throws If hashing fails
   */
  func hashData(data: Data, algorithm: HashAlgorithm) async throws -> String

  /**
   * Stores a key with the specified identifier.
   *
   * @param key The key to store
   * @param identifier The optional identifier for the key
   * @return The identifier of the stored key
   * @throws If storing the key fails
   */
  func storeKey(key: SendableCryptoMaterial, identifier: String?) async throws -> String

  /**
   * Retrieves a key with the specified identifier.
   *
   * @param identifier The identifier of the key to retrieve
   * @return The retrieved key
   * @throws If retrieving the key fails
   */
  func retrieveKey(identifier: String) async throws -> SendableCryptoMaterial

  /**
   * Deletes a key with the specified identifier.
   *
   * @param identifier The identifier of the key to delete
   * @throws If deleting the key fails
   */
  func deleteKey(identifier: String) async throws

  /**
   * Stores a secret with the specified identifier.
   *
   * @param secret The secret to store
   * @param identifier The optional identifier for the secret
   * @return The identifier of the stored secret
   * @throws If storing the secret fails
   */
  func saveSecret(secret: SendableCryptoMaterial, identifier: String?) async throws -> String

  /**
   * Retrieves a secret with the specified identifier.
   *
   * @param identifier The identifier of the secret to retrieve
   * @return The retrieved secret
   * @throws If retrieving the secret fails
   */
  func getSecret(identifier: String) async throws -> SendableCryptoMaterial

  /**
   * Deletes a secret with the specified identifier.
   *
   * @param identifier The identifier of the secret to delete
   * @throws If deleting the secret fails
   */
  func removeSecret(identifier: String) async throws
}

/**
 * Alias for SecurityProviderProtocol that makes it clearer this is a service.
 */
public typealias SecurityServiceProtocol=SecurityProviderProtocol

/**
 * Configuration for key generation.
 */
public struct KeyGenConfig {
  public let algorithm: String?
  public let metadata: [String: String]

  public init(algorithm: String?=nil, metadata: [String: String]=[:]) {
    self.algorithm=algorithm
    self.metadata=metadata
  }
}

/**
 * Enumeration of supported encryption algorithms.
 */
public enum EncryptionAlgorithm: String {
  case aes256="AES-256"
  case chacha20="ChaCha20"
}

/**
 * Enumeration of supported hash algorithms.
 */
public enum HashAlgorithm: String {
  case sha256="SHA-256"
  case sha512="SHA-512"
  case sha1="SHA-1" // Included for legacy compatibility, not recommended for new code
}

/**
 * Protocol for sendable cryptographic material.
 */
public protocol SendableCryptoMaterial: Sendable {
  var algorithm: String { get }
  var keyData: Data { get }
}

/**
 * Basic implementation of SendableCryptoMaterial.
 */
public struct BasicCryptoMaterial: SendableCryptoMaterial {
  public let algorithm: String
  public let keyData: Data

  public init(algorithm: String, keyData: Data) {
    self.algorithm=algorithm
    self.keyData=keyData
  }
}
