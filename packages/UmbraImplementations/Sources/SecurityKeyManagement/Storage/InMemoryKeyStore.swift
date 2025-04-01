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
public final class InMemoryKeyStore: KeyStorage, Sendable {
  /// Thread-safe storage for keys
  private let storage: StorageActor

  /// Actor to provide thread-safe access to the keys
  private actor StorageActor {
    /// Dictionary to store keys by their identifier
    var keys: [String: [UInt8]]=[:]

    /// Initialises an empty storage
    init() {}

    /// Store a key with an identifier
    func storeKey(_ key: [UInt8], identifier: String) {
      keys[identifier]=key
    }

    /// Retrieve a key by identifier
    func getKey(identifier: String) -> [UInt8]? {
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
      - key: The key to store as a byte array
      - identifier: The identifier for the key
   - Throws: This implementation does not throw errors but confirms to protocol
   */
  public func storeKey(_ key: [UInt8], identifier: String) async throws {
    await storage.storeKey(key, identifier: identifier)
  }

  /**
   Retrieve a key by its identifier.

   - Parameter identifier: The identifier for the key
   - Returns: The key as a byte array if found, nil otherwise
   - Throws: This implementation does not throw errors but confirms to protocol
   */
  public func getKey(identifier: String) async -> [UInt8]? {
    await storage.getKey(identifier: identifier)
  }

  /**
   Delete a key with the specified identifier.

   - Parameter identifier: The identifier for the key
   - Throws: This implementation does not throw errors but confirms to protocol
   */
  public func deleteKey(identifier: String) async throws {
    await storage.deleteKey(identifier: identifier)
  }

  /**
   Check if a key exists.

   - Parameter identifier: The identifier for the key
   - Returns: True if the key exists, false otherwise
   - Throws: This implementation does not throw errors but confirms to protocol
   */
  public func containsKey(identifier: String) async throws -> Bool {
    await storage.containsKey(identifier: identifier)
  }

  /**
   List all key identifiers.

   - Returns: An array of all key identifiers
   - Throws: This implementation does not throw errors but confirms to protocol
   */
  public func listKeyIdentifiers() async throws -> [String] {
    await storage.listKeyIdentifiers()
  }
}
