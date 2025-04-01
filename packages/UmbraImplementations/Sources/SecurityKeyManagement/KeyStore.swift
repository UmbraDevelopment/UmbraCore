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

import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import SecurityCoreInterfaces
import SecurityKeyTypes
import UmbraErrors

/// KeyStorage factory
///
/// Provides a standard way to create key storage instances.
public enum KeyStorageFactory {
  /// Create a key storage implementation
  /// - Returns: An implementation of KeyStorage
  public static func createKeyStorage() -> KeyStorage {
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
  private var storage: [String: [UInt8]]=[:]

  // MARK: - Public Interface

  /// Store a key in memory
  /// - Parameters:
  ///   - key: The key to store as a byte array
  ///   - identifier: The identifier for the key
  /// - Throws: This implementation doesn't throw but conforms to protocol
  public func storeKey(_ key: [UInt8], identifier: String) async throws {
    storage[identifier]=key
  }

  /// Get a key from memory
  /// - Parameter identifier: The identifier for the key
  /// - Returns: The key as a byte array or nil if not found
  public func getKey(identifier: String) async -> [UInt8]? {
    storage[identifier]
  }

  /// Delete a key from memory
  /// - Parameter identifier: The identifier for the key
  /// - Throws: This implementation doesn't throw but conforms to protocol
  public func deleteKey(identifier: String) async throws {
    storage.removeValue(forKey: identifier)
  }

  /// Check if a key exists in memory
  /// - Parameter identifier: The identifier for the key
  /// - Returns: True if the key exists
  /// - Throws: This implementation doesn't throw but conforms to protocol
  public func containsKey(identifier: String) async throws -> Bool {
    storage[identifier] != nil
  }

  /// List all key identifiers
  /// - Returns: Array of key identifiers
  /// - Throws: This implementation doesn't throw but conforms to protocol
  public func listKeyIdentifiers() async throws -> [String] {
    Array(storage.keys)
  }
}

/// A secure storage mechanism for cryptographic keys
public final class KeyStore: KeyStorage, Sendable {
  // MARK: - Properties

  /// Thread-safe key storage
  private let keyStorage: KeyStorage

  // MARK: - Initialisation

  /// Initialise with a specific key storage implementation
  /// - Parameter keyStorage: The key storage to use
  public init(keyStorage: KeyStorage=KeyStorageFactory.createKeyStorage()) {
    self.keyStorage=keyStorage
  }

  // MARK: - KeyStorage Protocol Implementation

  /// Store a key with the given identifier
  /// - Parameters:
  ///   - key: The key to store as a byte array
  ///   - identifier: The identifier for the key
  /// - Throws: An error if storing the key fails
  public func storeKey(_ key: [UInt8], identifier: String) async throws {
    try await keyStorage.storeKey(key, identifier: identifier)
  }

  /// Get a key by its identifier
  /// - Parameter identifier: The identifier for the key
  /// - Returns: The key as a byte array or nil if not found
  /// - Throws: An error if retrieving the key fails
  public func getKey(identifier: String) async throws -> [UInt8]? {
    try await keyStorage.getKey(identifier: identifier)
  }

  /// Delete a key by its identifier
  /// - Parameter identifier: The identifier for the key
  /// - Throws: An error if deleting the key fails
  public func deleteKey(identifier: String) async throws {
    try await keyStorage.deleteKey(identifier: identifier)
  }

  /// Check if a key exists
  /// - Parameter identifier: The identifier for the key
  /// - Returns: True if the key exists
  /// - Throws: An error if checking for the key fails
  public func containsKey(identifier: String) async throws -> Bool {
    try await keyStorage.containsKey(identifier: identifier)
  }

  /// List all key identifiers
  /// - Returns: Array of key identifiers
  /// - Throws: An error if listing keys fails
  public func listKeyIdentifiers() async throws -> [String] {
    try await keyStorage.listKeyIdentifiers()
  }
}
