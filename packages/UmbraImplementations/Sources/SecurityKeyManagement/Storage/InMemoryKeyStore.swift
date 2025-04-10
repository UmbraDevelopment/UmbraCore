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
  /// - Parameters:
  ///   - key: The key to store as a byte array
  ///   - identifier: The identifier for the key
  /// - Throws: An error if storing the key fails
  public func storeKey(_ key: [UInt8], identifier: String) async throws {
    keys[identifier] = key
  }

  /// Get a key by identifier
  /// - Parameter identifier: The identifier for the key
  /// - Returns: The key as a byte array or nil if not found
  /// - Throws: An error if retrieving the key fails
  public func getKey(identifier: String) async throws -> [UInt8]? {
    keys[identifier]
  }

  /// Delete a key by identifier
  /// - Parameter identifier: The identifier for the key
  /// - Throws: An error if deleting the key fails
  public func deleteKey(identifier: String) async throws {
    keys.removeValue(forKey: identifier)
  }

  /// Check if a key exists
  /// - Parameter identifier: The identifier for the key
  /// - Returns: True if the key exists
  /// - Throws: An error if checking the key fails
  public func containsKey(identifier: String) async throws -> Bool {
    keys.keys.contains(identifier)
  }

  /// List all available key identifiers
  /// - Returns: Array of key identifiers
  /// - Throws: An error if listing keys fails
  public func listKeyIdentifiers() async throws -> [String] {
    Array(keys.keys)
  }
  
  /// Get all key identifiers
  /// - Returns: An array of all key identifiers
  /// - Throws: An error if retrieving the identifiers fails
  public func getAllIdentifiers() async throws -> [String] {
    Array(keys.keys)
  }
}
