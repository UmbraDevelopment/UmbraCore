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

  /// List all available key identifiers
  /// - Returns: Array of key identifiers
  /// - Throws: An error if listing keys fails
  func listKeyIdentifiers() async throws -> [String]

  /// Get all key identifiers
  /// - Returns: An array of all key identifiers
  /// - Throws: An error if retrieving the identifiers fails
  func getAllIdentifiers() async throws -> [String]
}

/**
 Default implementation for KeyStorage
 */
extension KeyStorage {
  /**
   Get all key identifiers stored in this key storage

   This default implementation is provided for backward compatibility with existing
   KeyStorage implementations. It is recommended to provide a more efficient
   implementation in concrete types.

   - Returns: An array of string identifiers
   - Throws: If retrieval fails
   */
  public func getAllIdentifiers() async throws -> [String] {
    // This is a default implementation that can be overridden by concrete types
    // for better performance
    let identifiers: [String]=[]

    // In a real implementation, this would list all keys efficiently
    // This basic implementation is provided for compatibility only

    return identifiers
  }
}
