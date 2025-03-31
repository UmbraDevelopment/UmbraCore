import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import UmbraErrors

/// Protocol defining secure key management operations in a Foundation-independent manner.
/// All operations use only primitive types and Foundation-independent custom types.
public protocol KeyManagementProtocol: Sendable {
  /// Retrieves a security key by its identifier.
  /// - Parameter identifier: A string identifying the key.
  /// - Returns: The security key as a byte array or an error.
  func retrieveKey(withIdentifier identifier: String) async
    -> Result<[UInt8], SecurityProtocolError>

  /// Stores a security key with the given identifier.
  /// - Parameters:
  ///   - key: The security key as a byte array.
  ///   - identifier: A string identifier for the key.
  /// - Returns: Success or an error.
  func storeKey(_ key: [UInt8], withIdentifier identifier: String) async
    -> Result<Void, SecurityProtocolError>

  /// Deletes a security key with the given identifier.
  /// - Parameter identifier: A string identifying the key to delete.
  /// - Returns: Success or an error.
  func deleteKey(withIdentifier identifier: String) async
    -> Result<Void, SecurityProtocolError>

  /// Rotates a security key, creating a new key and optionally re-encrypting data.
  /// - Parameters:
  ///   - identifier: A string identifying the key to rotate.
  ///   - dataToReencrypt: Optional data to re-encrypt with the new key.
  /// - Returns: The new key and re-encrypted data (if provided) or an error.
  func rotateKey(
    withIdentifier identifier: String,
    dataToReencrypt: [UInt8]?
  ) async -> Result<(
    newKey: [UInt8],
    reencryptedData: [UInt8]?
  ), SecurityProtocolError>

  /// Lists all available key identifiers.
  /// - Returns: An array of key identifiers or an error.
  func listKeyIdentifiers() async -> Result<[String], SecurityProtocolError>
}
