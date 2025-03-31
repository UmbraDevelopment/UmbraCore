import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import SecurityCoreInterfaces
import UmbraErrors

/**
 # KeyStorage Protocol

 This protocol defines the interface for secure key storage implementations.
 It provides methods for storing, retrieving, and managing cryptographic keys
 in a secure manner.

 Implementations of this protocol should focus on ensuring that:

 * Keys are stored securely (using appropriate encryption)
 * Keys are retrievable only through authorised channels
 * Key identifiers are protected from information disclosure
 * All operations maintain proper isolation and thread safety

 ## Implementation Recommendations

 * Use platform-specific secure storage mechanisms where available
 * Ensure proper error handling and validation for all operations
 * Implement proper access controls around key storage
 * Consider key rotation and versioning policies
 */
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
