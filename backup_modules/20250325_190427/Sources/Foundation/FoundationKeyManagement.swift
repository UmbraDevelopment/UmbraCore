import Foundation

/// Protocol for Foundation-based key management services
public protocol FoundationKeyManagement: Sendable {
  /// Retrieve a key by identifier
  /// - Parameter identifier: Key identifier
  /// - Returns: Result containing key data or error
  func retrieveKey(withIdentifier identifier: String) async -> Result<Data, Error>

  /// Store a key with the given identifier
  /// - Parameters:
  ///   - key: Key data to store
  ///   - identifier: Key identifier
  /// - Returns: Result indicating success or error
  func storeKey(_ key: Data, withIdentifier identifier: String) async -> Result<Void, Error>

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
    dataToReencrypt: Data?
  ) async -> Result<(newKey: Data, reencryptedData: Data?), Error>

  /// List all key identifiers
  /// - Returns: Result containing array of key identifiers
  func listKeyIdentifiers() async -> Result<[String], Error>
}
