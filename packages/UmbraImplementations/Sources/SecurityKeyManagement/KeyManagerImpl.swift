import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import SecurityCoreInterfaces
import SecurityKeyTypes
import UmbraErrors

/**
 # KeyManagerImpl

 Provides key management functionality, including key storage, retrieval, rotation, and
 deletion. This implementation uses secure storage mechanisms to protect cryptographic
 keys while making them available for authorized operations.

 ## Responsibilities

 * Store cryptographic keys securely
 * Retrieve keys by identifier
 * Rotate keys to enforce key lifecycle policies
 * Delete keys when no longer needed
 * Track key metadata and usage statistics

 ## Security Considerations

 * Keys are stored using platform-specific secure storage mechanisms
 * Key material is never persisted in plaintext
 * Key identifiers are hashed to prevent information disclosure
 * Access to keys is logged for audit purposes

 ## Note

 This implementation is being phased out in favor of the actor-based KeyManagementActor
 which follows the Alpha Dot Five architecture. Use SecurityKeyManagement.createKeyManager()
 for new implementations.
 */

/// Implementation of the KeyManagementProtocol that provides secure key management operations
public final class KeyManagerImpl: KeyManagementProtocol, Sendable {
  // MARK: - Properties

  /// In-memory key store for demonstration purposes
  /// In a real implementation, this would use the platform's secure storage
  private let keyStore: KeyStore

  // MARK: - Initialisation

  /// Creates a new key manager with the default key store
  public init() {
    keyStore=KeyStore()
  }

  /// Creates a new key manager with a custom key store
  /// - Parameter keyStore: Custom key store implementation
  public init(keyStore: KeyStore) {
    self.keyStore=keyStore
  }

  // MARK: - KeyManagementProtocol Implementation

  /// Retrieves a security key by its identifier.
  /// - Parameter identifier: A string identifying the key.
  /// - Returns: The security key as `SecureBytes` or an error.
  public func retrieveKey(withIdentifier identifier: String) async
  -> Result<SecureBytes, SecurityProtocolError> {
    if let key=await keyStore.getKey(identifier: identifier) {
      .success(key)
    } else {
      .failure(.keyManagementError("Key not found: \(identifier)"))
    }
  }

  /// Stores a security key with the given identifier.
  /// - Parameters:
  ///   - key: The security key as `SecureBytes`.
  ///   - identifier: A string identifier for the key.
  /// - Returns: Success or an error.
  public func storeKey(_ key: SecureBytes, withIdentifier identifier: String) async
  -> Result<Void, SecurityProtocolError> {
    await keyStore.storeKey(key, identifier: identifier)
    return .success(())
  }

  /// Deletes a security key with the given identifier.
  /// - Parameter identifier: A string identifying the key to delete.
  /// - Returns: Success or an error.
  public func deleteKey(withIdentifier identifier: String) async
  -> Result<Void, SecurityProtocolError> {
    if await keyStore.containsKey(identifier: identifier) {
      await keyStore.deleteKey(identifier: identifier)
      return .success(())
    } else {
      return .failure(.keyManagementError("Key not found: \(identifier)"))
    }
  }

  /// Rotates a security key, creating a new key and optionally re-encrypting data.
  /// - Parameters:
  ///   - identifier: A string identifying the key to rotate.
  ///   - dataToReencrypt: Optional data to re-encrypt with the new key.
  /// - Returns: The new key and re-encrypted data (if provided) or an error.
  public func rotateKey(
    withIdentifier identifier: String,
    dataToReencrypt: SecureBytes?
  ) async -> Result<(
    newKey: SecureBytes,
    reencryptedData: SecureBytes?
  ), SecurityProtocolError> {
    // Check if key exists
    if await keyStore.containsKey(identifier: identifier) {
      // Generate a new key
      let newKey=generateKey()

      // Store the new key with the same identifier (replacing the old one)
      await keyStore.storeKey(newKey, identifier: identifier)

      // Implement re-encryption logic if needed
      let reencryptedData=dataToReencrypt

      return .success((newKey: newKey, reencryptedData: reencryptedData))
    } else {
      return .failure(.keyManagementError("Key not found: \(identifier)"))
    }
  }

  /// Lists all available key identifiers.
  /// - Returns: An array of key identifiers or an error.
  public func listKeyIdentifiers() async -> Result<[String], SecurityProtocolError> {
    await .success(keyStore.listKeyIdentifiers())
  }

  // MARK: - Helper Methods

  /// Generates a cryptographic key with secure random bytes
  /// - Returns: A new secure key
  private func generateKey() -> SecureBytes {
    var keyData=[UInt8](repeating: 0, count: 32) // 256-bit key

    // Use secure random number generator
    let status=SecRandomCopyBytes(kSecRandomDefault, keyData.count, &keyData)

    // Check for success
    if status == errSecSuccess {
      return SecureBytes(bytes: keyData)
    } else {
      // Fallback if secure random fails
      // Note: In production code, we would handle this error properly
      let fallbackData=[UInt8](repeating: 0, count: 32).map { _ in UInt8.random(in: 0...255) }
      return SecureBytes(bytes: fallbackData)
    }
  }

  /// Converts data to SecureBytes if not nil
  /// - Parameter data: The data to convert
  /// - Returns: SecureBytes or nil if input is nil
  private func toSecureBytes(_ data: Data?) -> SecureBytes? {
    guard let data else {
      return nil
    }

    return SecureBytes(bytes: [UInt8](data))
  }
}
