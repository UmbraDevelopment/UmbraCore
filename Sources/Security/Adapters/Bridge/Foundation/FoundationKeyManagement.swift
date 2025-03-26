/**
 # UmbraCore Foundation Bridge

 This file defines protocols for interfacing UmbraCore security types
 with Foundation data types, providing a clear bridge between core types
 and Foundation framework.
 */

import Foundation
import UmbraCoreTypes

/// Protocol for Foundation-based key management services
public protocol FoundationKeyManagement: Sendable {
  // MARK: - Key Management Operations

  /// Retrieve a key by identifier
  /// - Parameter identifier: Key identifier
  /// - Returns: Result containing key data or error
  func retrieveKey(withIdentifier identifier: String) async -> Result<SecureBytes, Error>

  /// Store a key with the given identifier
  /// - Parameters:
  ///   - key: Key data to store
  ///   - identifier: Key identifier
  /// - Returns: Result indicating success or error
  func storeKey(_ key: SecureBytes, withIdentifier identifier: String) async -> Result<Void, Error>

  /// Delete a key by identifier
  /// - Parameter identifier: Key identifier
  /// - Returns: Result indicating success or error
  func deleteKey(withIdentifier identifier: String) async -> Result<Void, Error>

  /// Rotate a key by generating a new key and re-encrypting data
  /// - Parameters:
  ///   - identifier: Key identifier
  ///   - dataToReencrypt: Optional data to re-encrypt with the new key
  /// - Returns: Result containing the new key and re-encrypted data
  func rotateKey(
    withIdentifier identifier: String,
    dataToReencrypt: SecureBytes?
  ) async -> Result<(newKey: SecureBytes, reencryptedData: SecureBytes?), Error>

  /// List all key identifiers
  /// - Returns: Result containing array of key identifiers
  func listKeyIdentifiers() async -> Result<[String], Error>

  // MARK: - Foundation Data Conversion Helpers

  /// Converts SecureBytes to Foundation Data
  /// - Parameter secureBytes: The secure bytes to convert
  /// - Returns: Foundation Data representation
  func toFoundationData(_ secureBytes: SecureBytes) -> Foundation.Data

  /// Converts Foundation Data to SecureBytes
  /// - Parameter data: The Foundation Data to convert
  /// - Returns: SecureBytes representation
  func toSecureBytes(_ data: Foundation.Data) -> SecureBytes
}
