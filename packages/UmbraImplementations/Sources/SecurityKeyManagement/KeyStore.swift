/**
 # KeyStore

 Provides secure storage for cryptographic keys. The KeyStore is responsible for
 persisting keys securely and providing access to them when needed for cryptographic
 operations.

 ## Responsibilities

 * Store keys securely
 * Retrieve keys by identifier
 * Maintain key metadata
 * Delete keys when no longer needed
 * Support key rotation policies
 */

import Foundation
import SecurityCoreInterfaces
import SecurityCoreTypes
import SecurityTypes
import UmbraErrors

// MARK: - Key Storage Protocol

/// Protocol for key storage functionality
public protocol KeyStorage: Sendable {
  /// Store a key
  /// - Parameters:
  ///   - key: The key to store
  ///   - identifier: The identifier for the key
  func storeKey(_ key: SecureBytes, identifier: String) async
  
  /// Get a key
  /// - Parameter identifier: The identifier for the key
  /// - Returns: The key or nil if not found
  func getKey(identifier: String) async -> SecureBytes?
  
  /// Delete a key
  /// - Parameter identifier: The identifier for the key
  func deleteKey(identifier: String) async
  
  /// Check if a key exists
  /// - Parameter identifier: The identifier for the key
  /// - Returns: True if the key exists
  func containsKey(identifier: String) async -> Bool
  
  /// List all key identifiers
  /// - Returns: Array of key identifiers
  func listKeyIdentifiers() async -> [String]
}

/// KeyStorage factory
///
/// Provides a standard way to create key storage instances.
public enum KeyStorageFactory {
  /// Create a key storage implementation
  /// - Returns: An implementation of KeyStorage
  public static func createKeyStorage() -> any KeyStorage {
    KeyStorageManager()
  }
}

/// Manages storage of keys in memory
///
/// This is a simple in-memory implementation for testing and development.
/// In a production environment, this would be backed by a secure storage mechanism.
actor KeyStorageManager: KeyStorage {
  // MARK: - Properties
  
  /// Dictionary for storing keys by identifier
  private var storage: [String: SecureBytes] = [:]
  
  // MARK: - Public Interface
  
  /// Store a key in memory
  /// - Parameters:
  ///   - key: The key to store
  ///   - identifier: The identifier for the key
  func storeKey(_ key: SecureBytes, identifier: String) async {
    storage[identifier] = key
  }
  
  /// Get a key from memory
  /// - Parameter identifier: The identifier for the key
  /// - Returns: The key or nil if not found
  func getKey(identifier: String) async -> SecureBytes? {
    storage[identifier]
  }
  
  /// Delete a key from memory
  /// - Parameter identifier: The identifier for the key
  func deleteKey(identifier: String) async {
    storage.removeValue(forKey: identifier)
  }
  
  /// Check if a key exists in memory
  /// - Parameter identifier: The identifier for the key
  /// - Returns: True if the key exists
  func containsKey(identifier: String) async -> Bool {
    storage[identifier] != nil
  }
  
  /// List all key identifiers
  /// - Returns: Array of key identifiers
  func listKeyIdentifiers() async -> [String] {
    Array(storage.keys)
  }
}

/// A secure storage mechanism for cryptographic keys
public final class KeyStore: Sendable {
  // MARK: - Properties
  
  /// Thread-safe key storage
  private let keyStorage: any KeyStorage
  
  // MARK: - Initialisation
  
  /// Initialise with a specific key storage implementation
  /// - Parameter keyStorage: The key storage to use
  public init(keyStorage: any KeyStorage = KeyStorageFactory.createKeyStorage()) {
    self.keyStorage = keyStorage
  }
  
  // MARK: - Public Methods
  
  /// Store a key with the given identifier
  /// - Parameters:
  ///   - key: The key to store
  ///   - identifier: The identifier for the key
  public func storeKey(_ key: SecureBytes, identifier: String) async {
    await keyStorage.storeKey(key, identifier: identifier)
  }
  
  /// Retrieve a key by its identifier
  /// - Parameter identifier: The identifier for the key
  /// - Returns: The key if found, nil otherwise
  public func getKey(identifier: String) async -> SecureBytes? {
    await keyStorage.getKey(identifier: identifier)
  }
  
  /// Delete a key by its identifier
  /// - Parameter identifier: The identifier of the key to delete
  public func deleteKey(identifier: String) async {
    await keyStorage.deleteKey(identifier: identifier)
  }
  
  /// Check if a key exists with the given identifier
  /// - Parameter identifier: The identifier to check
  /// - Returns: True if a key exists with the identifier, false otherwise
  public func containsKey(identifier: String) async -> Bool {
    await keyStorage.containsKey(identifier: identifier)
  }
  
  /// Get all key identifiers
  /// - Returns: Array of all key identifiers
  public func getAllIdentifiers() async -> [String] {
    await keyStorage.listKeyIdentifiers()
  }
}
