/**
 # UmbraCore Key Store

 This file provides key storage and retrieval functionality for the UmbraCore security framework.
 It implements secure key storage operations with appropriate memory protection and access controls.

 ## Responsibilities

 * Secure storage of cryptographic keys
 * Key retrieval by identifier
 * Key metadata management
 * Access control for key operations

 ## Security Considerations

 * Keys are stored in SecureBytes containers to provide memory protection
 * In a production implementation, keys would be stored in a secure enclave or hardware security module
 * This implementation is for demonstration purposes and is not suitable for production use without
   further security enhancements
 */

import ErrorHandlingDomains
import Foundation
import SecurityProtocolsCore
import UmbraCoreTypes

/// Provides key storage and retrieval functionality
///
/// KeyStore is responsible for storing and retrieving cryptographic keys in a secure manner.
/// It manages the mapping between key identifiers and the actual key material, as well as
/// metadata about the keys such as creation date and purpose.
final class KeyStore {
  // MARK: - Types

  /// Represents a stored key with its metadata
  private struct StoredKey {
    /// The key data
    let key: SecureBytes

    /// When the key was created
    let createdAt: Date

    /// The type of the key (symmetric, asymmetric, hmac)
    let keyType: KeyType

    /// The purpose of the key
    let purpose: KeyPurpose
  }

  // MARK: - Properties

  /// Dictionary mapping key identifiers to stored keys
  private var keyStore: [String: StoredKey]

  /// Queue for thread-safe access to the key store
  private let queue: DispatchQueue

  // MARK: - Initialisation

  /// Creates a new KeyStore
  init() {
    keyStore=[:]
    queue=DispatchQueue(label: "com.umbra.keystore", attributes: .concurrent)
  }

  // MARK: - Key Store Operations

  /// Stores a key in the key store
  /// - Parameters:
  ///   - key: The key to store
  ///   - identifier: The identifier for the key
  /// - Returns: Success if the key was stored, failure otherwise
  func storeKey(
    _ key: SecureBytes,
    withIdentifier identifier: String
  ) -> Result<Void, UmbraErrors.Security.Protocols> {
    // Validate inputs
    guard !identifier.isEmpty else {
      return .failure(.invalidInput("Key identifier cannot be empty"))
    }

    var result: Result<Void, UmbraErrors.Security.Protocols> = .success(())

    queue.sync(flags: .barrier) {
      // Check if the key already exists
      if self.keyStore[identifier] != nil {
        result = .failure(.invalidInput("Key with identifier \(identifier) already exists"))
        return
      }

      // Store the key
      self.keyStore[identifier]=StoredKey(
        key: key,
        createdAt: Date(),
        keyType: .unknown,
        purpose: .unknown
      )
    }

    return result
  }

  /// Retrieves a key from the key store
  /// - Parameter identifier: The identifier for the key
  /// - Returns: The key if found, or an error if the key doesn't exist
  func retrieveKey(withIdentifier identifier: String)
  -> Result<SecureBytes, UmbraErrors.Security.Protocols> {
    var result: Result<SecureBytes, UmbraErrors.Security.Protocols> = .failure(
      .keyNotFound(identifier: identifier, innerError: nil)
    )

    queue.sync {
      // Look up the key
      if let storedKey=self.keyStore[identifier] {
        result = .success(storedKey.key)
      }
    }

    return result
  }

  /// Deletes a key from the key store
  /// - Parameter identifier: The identifier for the key
  /// - Returns: Success if the key was deleted, failure otherwise
  func deleteKey(withIdentifier identifier: String)
  -> Result<Void, UmbraErrors.Security.Protocols> {
    var result: Result<Void, UmbraErrors.Security.Protocols> = .failure(
      .keyNotFound(identifier: identifier, innerError: nil)
    )

    queue.sync(flags: .barrier) {
      // Check if the key exists
      if self.keyStore[identifier] != nil {
        // Remove the key
        self.keyStore.removeValue(forKey: identifier)
        result = .success(())
      }
    }

    return result
  }

  /// Lists all key identifiers stored in the key store
  /// - Returns: An array of key identifiers
  func listKeyIdentifiers() -> Result<[String], UmbraErrors.Security.Protocols> {
    var identifiers: [String]=[]

    queue.sync {
      identifiers=Array(self.keyStore.keys)
    }

    return .success(identifiers)
  }

  /// Checks if a key with the specified identifier exists
  /// - Parameter identifier: The identifier to check
  /// - Returns: True if the key exists, false otherwise
  func hasKey(withIdentifier identifier: String) -> Bool {
    var exists=false

    queue.sync {
      exists=keyStore[identifier] != nil
    }

    return exists
  }
}
