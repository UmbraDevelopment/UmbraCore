import UmbraCoreTypes
import UmbraErrorsCore
import UmbraErrors
import Errors

/// Protocol defining secure key management operations in a FoundationIndependent manner.
/// All operations use only primitive types and FoundationIndependent custom types.
public protocol KeyManagementProtocol: Sendable {
  /// Retrieves a security key by its identifier.
  /// - Parameter identifier: A string identifying the key.
  /// - Returns: The security key as `SecureBytes` or an error.
  func retrieveKey(withIdentifier identifier: String) async
    -> Result<SecureBytes, Errors.SecurityProtocolError>

  /// Stores a security key with the given identifier.
  /// - Parameters:
  ///   - key: The security key as `SecureBytes`.
  ///   - identifier: A string identifier for the key.
  /// - Returns: Success or an error.
  func storeKey(_ key: SecureBytes, withIdentifier identifier: String) async
    -> Result<Void, Errors.SecurityProtocolError>

  /// Deletes a security key by its identifier.
  /// - Parameter identifier: A string identifying the key to delete.
  /// - Returns: Success or an error.
  func deleteKey(withIdentifier identifier: String) async
    -> Result<Void, Errors.SecurityProtocolError>
    
  /// Gets the type of a stored key
  /// - Parameter identifier: A string identifying the key
  /// - Returns: Key type information or error
  func getKeyType(withIdentifier identifier: String) async -> Result<(
    keyType: String, 
    algorithm: String, 
    size: Int
  ), Errors.SecurityProtocolError>
  
  /// Lists all available key identifiers
  /// - Returns: Array of identifier strings or error
  func listKeyIdentifiers() async -> Result<[String], Errors.SecurityProtocolError>
}
