/**
 # UmbraCore Key Manager

 This file provides the main implementation of the `KeyManagementProtocol`,
 serving as a facade for all key management operations in the UmbraCore security framework.

 ## Responsibilities

 * Coordinate between specialised key management components
 * Generate, store, retrieve, and delete cryptographic keys
 * Manage key lifecycle (rotation, expiration)
 * Ensure proper access controls for key operations

 ## Design Pattern

 This class follows the Facade design pattern, providing a simple interface to a complex
 subsystem of key management components:

 * KeyStore: Handles key storage and retrieval
 * KeyGenerator: Creates new cryptographic keys
 * KeyLifecycle: Manages key rotation and retirement
 * KeyUtils: Provides utility functions for key operations

 ## Security Considerations

 * Keys are stored in SecureBytes containers to minimise exposure
 * Key operations follow the principle of least privilege
 * Key lifecycle is managed to ensure keys are rotated appropriately
 * All operations include validation to prevent misuse
 */

import ErrorHandlingDomains
import Foundation
import SecurityProtocolsCore
import UmbraCoreTypes

public struct RotationConfig: Sendable {
  /// Identifier of the key to rotate
  public let keyIdentifier: String

  /// Optional data to re-encrypt with the new key
  public let dataToReencrypt: SecureBytes?

  /// Creates a new rotation configuration
  /// - Parameters:
  ///   - keyIdentifier: Identifier of the key to rotate
  ///   - dataToReencrypt: Optional data to re-encrypt with the new key
  public init(keyIdentifier: String, dataToReencrypt: SecureBytes?=nil) {
    self.keyIdentifier=keyIdentifier
    self.dataToReencrypt=dataToReencrypt
  }
}

/// Implementation of the KeyManagementProtocol that provides a unified interface
/// to key management services.
public final class KeyManager: KeyManagementProtocol {
  // MARK: - Properties

  /// The key store component for key storage and retrieval
  private let keyStore: SecureKeyStorage

  /// The key generator component for creating new keys
  private let keyGenerator: KeyGenerator

  /// The key utilities component for key operations
  private let keyUtils: KeyManager.SecurityUtilsProtocol

  // MARK: - Initialisation

  /// Creates a new KeyManager with default implementations
  public init() {
    keyStore=SecureKeyStorage()
    keyGenerator=KeyGenerator()

    // Create an adaptor to bridge between SecurityUtils and KeyManager.SecurityUtilsProtocol
    // This adaptor pattern allows KeyManager to use SecurityUtils while maintaining
    // its own protocol definition for better encapsulation
    keyUtils=SecurityUtilsAdapter()
  }

  /// Creates a new KeyManager with the specified components
  /// - Parameters:
  ///   - keyStore: The key storage to use
  ///   - keyGenerator: The key generator to use
  ///   - keyUtils: The key utilities to use
  public init(
    keyStore: SecureKeyStorage,
    keyGenerator: KeyGenerator,
    keyUtils: KeyManager.SecurityUtilsProtocol
  ) {
    self.keyStore=keyStore
    self.keyGenerator=keyGenerator
    self.keyUtils=keyUtils
  }

  // MARK: - KeyManagementProtocol Implementation

  /// Generates a key with the specified parameters
  /// - Parameters:
  ///   - bits: The key size in bits
  ///   - keyType: The type of key to generate
  ///   - purpose _: The purpose of the key
  /// - Returns: A result containing the generated key or an error
  public func generateKey(
    bits: Int,
    keyType: KeyType,
    purpose _: KeyPurpose
  ) async -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    // Determine the algorithm to use based on key type
    var algorithm: String

    switch keyType {
      case .symmetric:
        algorithm="AES"
      case .asymmetric:
        algorithm="RSA"
      case .hmac:
        algorithm="HMAC-SHA256"
      default:
        return .failure(.invalidInput("Unsupported key type: \(keyType)"))
    }

    // Generate the key
    let generateResult=await keyGenerator.generateKey(
      bits: bits,
      algorithm: algorithm
    )

    guard generateResult.success, let key=generateResult.data else {
      return .failure(.serviceError("Key generation failed (code: 500)"))
    }

    return .success(key)
  }

  /// Retrieves a key by its identifier
  /// - Parameter identifier: The identifier of the key to retrieve
  /// - Returns: The key if found, or an error if not found
  public func retrieveKey(withIdentifier identifier: String) async
  -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    await keyStore.retrieveKey(withIdentifier: identifier)
  }

  /// Stores a key with the specified identifier
  /// - Parameters:
  ///   - key: The key to store
  ///   - identifier: The identifier to associate with the key
  /// - Returns: A result indicating success or an error
  public func storeKey(
    _ key: SecureBytes,
    withIdentifier identifier: String
  ) async -> Result<Void, UmbraErrors.Security.Protocols> {
    // Validate the key before storing
    guard key.count >= 16 else {
      return .failure(
        .invalidInput("Key length (\(key.count) bytes) is less than minimum required (16 bytes)")
      )
    }

    return await keyStore.storeKey(key, withIdentifier: identifier)
  }

  /// Deletes a key by identifier
  /// - Parameter identifier: The identifier of the key to delete
  /// - Returns: Success or an error
  public func deleteKey(withIdentifier identifier: String) async
  -> Result<Void, UmbraErrors.Security.Protocols> {
    await keyStore.deleteSecurely(identifier: identifier)
  }

  /// Rotates a key, optionally re-encrypting data with the new key
  /// - Parameters:
  ///   - identifier: The identifier of the key to rotate
  ///   - dataToReencrypt: Optional data to re-encrypt with the new key
  /// - Returns: The new key and re-encrypted data (if provided) or an error
  public func rotateKey(
    withIdentifier identifier: String,
    dataToReencrypt: SecureBytes?
  ) async -> Result<(
    newKey: SecureBytes,
    reencryptedData: SecureBytes?
  ), UmbraErrors.Security.Protocols> {
    // First, retrieve the old key
    let retrieveResult=await keyStore.retrieveKey(withIdentifier: identifier)

    switch retrieveResult {
      case let .success(oldKey):
        // Generate a new key of the same size
        let keySize=oldKey.count * 8

        // Generate key using the internal key generator
        let generateResult=await keyGenerator.generateKey(
          bits: keySize,
          algorithm: "AES"
        )

        guard generateResult.success, let newKey=generateResult.data else {
          return .failure(.serviceError("Failed to generate new key for rotation (code: 500)"))
        }

        // Re-encrypt the data if provided
        var reencryptedData: SecureBytes?
        if let dataToReencrypt {
          // For re-encryption, we need to decrypt with the old key and encrypt with the new key
          let retrieveConfig=SecurityConfigDTO(algorithm: "AES-GCM", keySizeInBits: 256)
          let decryptResult=try? await keyUtils.decryptSymmetricDTO(
            data: dataToReencrypt,
            key: oldKey,
            config: retrieveConfig
          )

          guard let decryptResult else {
            return .failure(
              .decryptionFailed("Failed to decrypt data with old key during rotation")
            )
          }

          switch decryptResult {
            case let .success(decryptedData):
              reencryptedData=decryptedData
            case let .failure(error):
              return .failure(error)
          }

          let encryptResult=try? await keyUtils.encryptSymmetricDTO(
            data: reencryptedData!,
            key: newKey,
            config: retrieveConfig
          )

          guard let encryptResult else {
            return .failure(
              .encryptionFailed("Failed to encrypt data with new key during rotation")
            )
          }

          switch encryptResult {
            case let .success(encryptedData):
              reencryptedData=encryptedData
            case let .failure(error):
              return .failure(error)
          }
        }

        // Store the new key
        let storeResult=await keyStore.storeKey(newKey, withIdentifier: identifier)

        switch storeResult {
          case .success:
            return .success((newKey: newKey, reencryptedData: reencryptedData))
          case let .failure(error):
            return .failure(.keyStoreFailed(reason: "Failed to store rotated key: \(error)"))
        }

      case let .failure(error):
        return .failure(.keyNotFound(identifier: identifier, innerError: error))
    }
  }

  /// Internal implementation of the key rotation using the new RotationConfig
  /// Supports the updated interface while maintaining compatibility
  func rotateKeyInternal(
    config: RotationConfig,
    keyType _: KeyType,
    bits _: Int,
    purpose _: KeyPurpose
  ) async -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    // First retrieve the old key
    let retrieveResult=await retrieveKey(withIdentifier: config.keyIdentifier)

    switch retrieveResult {
      case let .success(oldKey):
        var reencryptedData: SecureBytes?
        if let dataToReencrypt=config.dataToReencrypt {
          // For re-encryption, we need to decrypt with the old key and encrypt with the new key
          let retrieveConfig=SecurityConfigDTO(algorithm: "AES-GCM", keySizeInBits: 256)
          let decryptResult=try? await keyUtils.decryptSymmetricDTO(
            data: dataToReencrypt,
            key: oldKey,
            config: retrieveConfig
          )

          guard let decryptResult else {
            return .failure(
              .decryptionFailed("Failed to decrypt data with old key during rotation")
            )
          }

          switch decryptResult {
            case let .success(decryptedData):
              reencryptedData=decryptedData
            case let .failure(error):
              return .failure(error)
          }
        }

        // Generate a new key of the same size
        let keySize=oldKey.count * 8
        let config=SecurityConfigDTO(algorithm: "AES", keySizeInBits: keySize)
        let generateResult=await keyGenerator.generateKey(
          bits: keySize,
          algorithm: "AES"
        )

        guard generateResult.success, let newKey=generateResult.data else {
          return .failure(.serviceError("Failed to generate new key for rotation (code: 500)"))
        }

        // Store the new key
        let storeResult=await keyStore.storeKey(newKey, withIdentifier: config.keyIdentifier!)

        switch storeResult {
          case .success:
            return .success(newKey)
          case let .failure(error):
            return .failure(.keyStoreFailed(reason: "Failed to store rotated key: \(error)"))
        }

      case let .failure(error):
        return .failure(.keyNotFound(identifier: config.keyIdentifier, innerError: error))
    }
  }

  /// Lists all available key identifiers
  /// - Returns: An array of key identifiers
  public func listKeyIdentifiers() async -> Result<[String], UmbraErrors.Security.Protocols> {
    await keyStore.listKeyIdentifiers()
  }

  /// Generate random data of specified length
  /// - Parameter length: Number of bytes to generate
  /// - Returns: The generated random data or an error
  public func generateRandomData(length: Int) async
  -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    // Validate length
    guard length > 0 else {
      return .failure(.invalidInput("Random data length must be greater than 0"))
    }

    // Use the key generator to produce random bytes
    return await keyGenerator.generateRandomData(length: length)
  }
}

// MARK: - Utility Adapters

/// Adapter to bridge between SecurityUtils and KeyManager.SecurityUtilsProtocol
private final class SecurityUtilsAdapter: KeyManager.SecurityUtilsProtocol {
  // Create a new instance of SecurityUtils with a CryptoServiceCore
  private let utils: SecurityUtils

  init() {
    // Create a CryptoServiceCore instance to pass to SecurityUtils
    let cryptoService=CryptoServiceCore()
    utils=SecurityUtils(cryptoService: cryptoService)
  }

  func decryptSymmetricDTO(
    data: SecureBytes,
    key: SecureBytes,
    config: SecurityConfigDTO
  ) async -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    let result=await utils.decryptSymmetricDTO(data: data, key: key, config: config)

    // Convert SecurityResultDTO to Result<SecureBytes, UmbraErrors.Security.Protocols>
    if result.success, let data=result.data {
      return .success(data)
    } else {
      return .failure(.serviceError(
        result
          .errorMessage ?? "Decryption failed with unknown error (code: \(result.errorCode ?? 500))"
      ))
    }
  }

  func encryptSymmetricDTO(
    data: SecureBytes,
    key: SecureBytes,
    config: SecurityConfigDTO
  ) async -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    let result=await utils.encryptSymmetricDTO(data: data, key: key, config: config)

    // Convert SecurityResultDTO to Result<SecureBytes, UmbraErrors.Security.Protocols>
    if result.success, let data=result.data {
      return .success(data)
    } else {
      return .failure(.serviceError(
        result
          .errorMessage ?? "Encryption failed with unknown error (code: \(result.errorCode ?? 500))"
      ))
    }
  }
}

// MARK: - Error extensions

/// Extension to add key management specific errors
extension UmbraErrors.Security.Protocols {
  /// Error indicating a key was not found
  /// - Parameters:
  ///   - identifier: The identifier that was searched for
  ///   - innerError: Optional underlying error
  /// - Returns: A keyNotFound error
  static func keyNotFound(identifier: String, innerError: Error?=nil) -> Self {
    let details="Key with identifier '\(identifier)' not found"
    if let innerError {
      return .internalError("Key retrieval failed: \(details). Error: \(innerError)")
    } else {
      return .invalidInput(details)
    }
  }

  /// Error indicating key store operation failed
  /// - Parameter reason: The reason for the failure
  /// - Returns: A keyStoreFailed error
  static func keyStoreFailed(reason: String) -> Self {
    .storageOperationFailed(reason)
  }
}

extension KeyManager {
  public protocol SecurityUtilsProtocol: Sendable {
    func decryptSymmetricDTO(
      data: SecureBytes,
      key: SecureBytes,
      config: SecurityConfigDTO
    ) async -> Result<SecureBytes, UmbraErrors.Security.Protocols>

    func encryptSymmetricDTO(
      data: SecureBytes,
      key: SecureBytes,
      config: SecurityConfigDTO
    ) async -> Result<SecureBytes, UmbraErrors.Security.Protocols>
  }
}
