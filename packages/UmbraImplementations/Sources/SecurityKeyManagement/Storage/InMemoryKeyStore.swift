import Foundation
import SecurityCoreInterfaces
import SecurityCoreTypes
import SecurityKeyTypes
import SecurityTypes
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
public final class InMemoryKeyStore: KeyStorage, Sendable {
  /// Thread-safe storage for keys
  private let storage: StorageActor

  /// Actor to provide thread-safe access to the keys
  private actor StorageActor {
    /// Dictionary to store keys by their identifier
    var keys: [String: SecureBytes]=[:]

    /// Initialises an empty storage
    init() {}

    /// Store a key with an identifier
    func storeKey(_ key: SecureBytes, identifier: String) {
      keys[identifier]=key
    }

    /// Retrieve a key by identifier
    func getKey(identifier: String) -> SecureBytes? {
      keys[identifier]
    }

    /// Delete a key by identifier
    func deleteKey(identifier: String) {
      keys.removeValue(forKey: identifier)
    }

    /// Check if key exists
    func containsKey(identifier: String) -> Bool {
      keys[identifier] != nil
    }

    /// Get all key identifiers
    func listKeyIdentifiers() -> [String] {
      Array(keys.keys)
    }
  }

  /**
   Creates a new empty in-memory key store.
   */
  public init() {
    storage=StorageActor()
  }

  /**
   Store a key with the specified identifier.

   - Parameters:
      - key: The key to store
      - identifier: The identifier for the key
   */
  public func storeKey(_ key: SecureBytes, identifier: String) async {
    await storage.storeKey(key, identifier: identifier)
  }

  /**
   Retrieve a key by its identifier.

   - Parameter identifier: The identifier for the key
   - Returns: The key if found, nil otherwise
   */
  public func getKey(identifier: String) async -> SecureBytes? {
    await storage.getKey(identifier: identifier)
  }

  /**
   Delete a key with the specified identifier.

   - Parameter identifier: The identifier of the key to delete
   */
  public func deleteKey(identifier: String) async {
    await storage.deleteKey(identifier: identifier)
  }

  /**
   Check if a key with the specified identifier exists.

   - Parameter identifier: The identifier to check
   - Returns: True if the key exists, false otherwise
   */
  public func containsKey(identifier: String) async -> Bool {
    await storage.containsKey(identifier: identifier)
  }

  /**
   Get a list of all key identifiers in the store.

   - Returns: Array of key identifiers
   */
  public func listKeyIdentifiers() async -> [String] {
    await storage.listKeyIdentifiers()
  }
}
