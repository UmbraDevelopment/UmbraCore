/**
 # UmbraCore Secure Key Storage

 This file provides a simple in-memory secure storage mechanism for cryptographic keys.

 ## Features

 * Thread-safe access to keys using Swift actors
 * Keys are stored in SecureBytes containers to protect memory
 * Methods for storing, retrieving, and deleting keys

 ## Security Considerations

 * This implementation stores keys in memory only and does not persist them to disk
 * For production use, consider implementing a secure persistent storage solution
 */

import ErrorHandlingDomains
import Foundation
import SecurityProtocolsCore
import UmbraCoreTypes

/// Protocol defining secure storage operations for cryptographic keys
public protocol SafeStorage {
  /// Get a key by identifier
  func get(identifier: String) async -> SecureBytes?

  /// Store a key with the given identifier
  func set(key: SecureBytes, identifier: String) async

  /// Delete a key with the given identifier
  func delete(identifier: String) async

  /// Check if a key exists with the given identifier
  func contains(identifier: String) async -> Bool

  /// List all key identifiers
  func allIdentifiers() async -> [String]
}

/// Thread-safe in-memory storage for cryptographic keys
public final class SecureKeyStorage: SafeStorage, Sendable {
  /// Actor to provide thread-safe access to the underlying storage
  private actor StorageActor {
    /// The internal storage, mapping identifiers to keys
    private var storage: [String: SecureBytes]=[:]

    /// Get a key by identifier
    func get(identifier: String) -> SecureBytes? {
      storage[identifier]
    }

    /// Store a key with the given identifier
    func set(key: SecureBytes, identifier: String) {
      storage[identifier]=key
    }

    /// Delete a key with the given identifier
    func delete(identifier: String) {
      storage.removeValue(forKey: identifier)
    }

    /// Check if a key exists with the given identifier
    func contains(identifier: String) -> Bool {
      storage[identifier] != nil
    }

    /// List all key identifiers
    func allIdentifiers() -> [String] {
      Array(storage.keys)
    }
  }

  /// The actor that manages storage access
  private let actor=StorageActor()

  /// Create a new instance of SecureKeyStorage
  public init() {}

  // MARK: - SafeStorage Protocol Implementation

  /// Get a key by identifier
  /// - Parameter identifier: The identifier to look up
  /// - Returns: The key, or nil if not found
  public func get(identifier: String) async -> SecureBytes? {
    await actor.get(identifier: identifier)
  }

  /// Store a key with the given identifier
  /// - Parameters:
  ///   - key: The key to store
  ///   - identifier: The identifier to associate with the key
  public func set(key: SecureBytes, identifier: String) async {
    await actor.set(key: key, identifier: identifier)
  }

  /// Delete a key with the given identifier
  /// - Parameter identifier: The identifier of the key to delete
  public func delete(identifier: String) async {
    await actor.delete(identifier: identifier)
  }

  /// Check if a key exists with the given identifier
  /// - Parameter identifier: The identifier to check
  /// - Returns: True if the key exists, false otherwise
  public func contains(identifier: String) async -> Bool {
    await actor.contains(identifier: identifier)
  }

  /// List all key identifiers
  /// - Returns: An array of all key identifiers in the storage
  public func allIdentifiers() async -> [String] {
    await actor.allIdentifiers()
  }

  // MARK: - Methods for KeyManager

  /// Retrieve a key securely
  /// - Parameter identifier: The identifier of the key to retrieve
  /// - Returns: A result containing the key or an error
  public func retrieveKey(withIdentifier identifier: String) async
  -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    if let key=await get(identifier: identifier) {
      .success(key)
    } else {
      .failure(.keyNotFound(identifier: identifier, innerError: nil))
    }
  }

  /// Store a key securely
  /// - Parameters:
  ///   - data: The key to store
  ///   - identifier: The identifier to associate with the key
  /// - Returns: A result indicating success or an error
  public func storeSecurely(
    data: SecureBytes,
    identifier: String
  ) async -> Result<Void, UmbraErrors.Security.Protocols> {
    // Check if key already exists
    if await contains(identifier: identifier) {
      return .failure(.invalidInput("Key with identifier \(identifier) already exists"))
    }

    await set(key: data, identifier: identifier)
    return .success(())
  }

  /// Delete a key securely
  /// - Parameter identifier: The identifier of the key to delete
  /// - Returns: A result indicating success or an error
  public func deleteSecurely(identifier: String) async
  -> Result<Void, UmbraErrors.Security.Protocols> {
    if await contains(identifier: identifier) {
      await delete(identifier: identifier)
      return .success(())
    } else {
      return .failure(.keyNotFound(identifier: identifier, innerError: nil))
    }
  }

  /// List all key identifiers
  /// - Returns: A result containing an array of key identifiers or an error
  public func listKeyIdentifiers() async -> Result<[String], UmbraErrors.Security.Protocols> {
    let identifiers=await allIdentifiers()
    return .success(identifiers)
  }

  /// Retrieve data securely from storage
  /// - Parameter identifier: The identifier of the data to retrieve
  /// - Returns: The data or an error
  public func retrieveSecurely(identifier: String) async
  -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    await retrieveKey(withIdentifier: identifier)
  }

  // MARK: - Additional Methods for KeyManager compatibility

  /// Store a key in the key store
  /// - Parameters:
  ///   - key: The key to store
  ///   - identifier: The identifier to associate with the key
  /// - Returns: A result indicating success or failure
  public func storeKey(
    _ key: SecureBytes,
    withIdentifier identifier: String
  ) async -> Result<Void, UmbraErrors.Security.Protocols> {
    await storeSecurely(data: key, identifier: identifier)
  }
}
