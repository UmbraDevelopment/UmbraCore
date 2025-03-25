import UmbraCoreTypes
import Errors

/// Protocol defining secure storage operations in a FoundationIndependent manner.
/// All operations use only primitive types and FoundationIndependent custom types.
public protocol SecureStorageProtocol: Sendable {
  /// Stores data securely with the given identifier.
  /// - Parameters:
  ///   - data: The data to store as `SecureBytes`.
  ///   - identifier: A string identifier for the stored data.
  /// - Returns: Success or an error.
  func storeData(_ data: SecureBytes, withIdentifier identifier: String) async
    -> Result<Void, SecurityProtocolError>

  /// Retrieves data securely by its identifier.
  /// - Parameter identifier: A string identifying the data to retrieve.
  /// - Returns: The retrieved data as `SecureBytes` or an error.
  func retrieveData(withIdentifier identifier: String) async
    -> Result<SecureBytes, SecurityProtocolError>

  /// Deletes data securely by its identifier.
  /// - Parameter identifier: A string identifying the data to delete.
  /// - Returns: Success or an error.
  func deleteData(withIdentifier identifier: String) async
    -> Result<Void, SecurityProtocolError>

  /// Lists all available data identifiers.
  /// - Returns: An array of data identifiers or an error.
  func listDataIdentifiers() async -> Result<[String], SecurityProtocolError>
}
