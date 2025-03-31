import CoreSecurityTypes
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
  ///   - key: The key to store as a byte array
  ///   - identifier: The identifier for the key
  /// - Throws: An error if storing the key fails
  func storeKey(_ key: [UInt8], identifier: String) async throws

  /// Get a key
  /// - Parameter identifier: The identifier for the key
  /// - Returns: The key as a byte array or nil if not found
  /// - Throws: An error if retrieving the key fails
  func getKey(identifier: String) async throws -> [UInt8]?

  /// Delete a key
  /// - Parameter identifier: The identifier for the key
  /// - Throws: An error if deleting the key fails
  func deleteKey(identifier: String) async throws

  /// Check if a key exists
  /// - Parameter identifier: The identifier for the key
  /// - Returns: True if the key exists
  /// - Throws: An error if checking the key fails
  func containsKey(identifier: String) async throws -> Bool

  /// List all key identifiers
  /// - Returns: Array of key identifiers
  /// - Throws: An error if listing keys fails
  func listKeyIdentifiers() async throws -> [String]
}
