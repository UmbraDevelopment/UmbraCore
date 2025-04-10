import CoreSecurityTypes
import Foundation
import SecurityCoreInterfaces
import SecurityKeyTypes
import UmbraErrors

/**
 # InMemoryKeyStore

 A simple in-memory implementation of the KeyStorage protocol for testing purposes.
 This implementation does not provide any persistence and is not suitable for
 production use, but is useful for unit tests and prototyping.

 ## Security Considerations

 This implementation stores all keys in memory without any encryption. It should
 only be used in controlled test environments and never in production code
 that handles real sensitive data.

 ## Example Usage

 ```swift
 // Create an in-memory key store
 let keyStore = InMemoryKeyStore()

 // Create a key manager with the in-memory store
 let keyManager = await KeyManagementActor(
     keyStore: keyStore,
     logger: myLogger
 )

 // Use for testing
 let testResult = await keyManager.storeKey(testKey, withIdentifier: "test-key")
 ```
 */
public actor InMemoryKeyStore: KeyStorage {
  /// Dictionary to store keys by their identifier
  private var keys: [String: [UInt8]] = [:]

  /// Initialises an empty storage
  public init() {}

  /// Store a key with an identifier
  public func storeKey(_ key: [UInt8], identifier: String) async -> Result<Void, KeyStorageError> {
    keys[identifier] = key
    return .success(())
  }

  /// Retrieve a key by identifier
  public func retrieveKey(identifier: String) async -> Result<[UInt8], KeyStorageError> {
    if let key = keys[identifier] {
      return .success(key)
    } else {
      return .failure(.keyNotFound(identifier: identifier))
    }
  }

  /// Delete a key by identifier
  public func deleteKey(identifier: String) async -> Result<Void, KeyStorageError> {
    if keys[identifier] != nil {
      keys.removeValue(forKey: identifier)
      return .success(())
    } else {
      return .failure(.keyNotFound(identifier: identifier))
    }
  }

  /// List all key identifiers
  public func listKeyIdentifiers() async -> Result<[String], KeyStorageError> {
    return .success(Array(keys.keys))
  }

  /// Rotates a key, generating a new key and returning both the new key and re-encrypted data
  public func rotateKey(
    identifier: String,
    dataToReencrypt: [UInt8]?
  ) async -> Result<(newKey: [UInt8], reencryptedData: [UInt8]?), KeyStorageError> {
    // Check if the key exists
    guard keys[identifier] != nil else {
      return .failure(.keyNotFound(identifier: identifier))
    }

    // Generate a new key (32 bytes for AES-256)
    var newKey = [UInt8](repeating: 0, count: 32)
    let status = SecRandomCopyBytes(kSecRandomDefault, newKey.count, &newKey)
    
    guard status == errSecSuccess else {
      return .failure(.generalError(reason: "Failed to generate secure random bytes"))
    }
    
    // Store the new key, replacing the old one
    keys[identifier] = newKey
    
    // In a real implementation, this would re-encrypt the data with the new key
    // For this simple implementation, we just return the original data
    return .success((newKey: newKey, reencryptedData: dataToReencrypt))
  }
}
