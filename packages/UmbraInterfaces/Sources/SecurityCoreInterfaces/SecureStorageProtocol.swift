import CoreSecurityTypes
import DomainSecurityTypes
import Foundation
import UmbraErrors

/// Protocol defining secure storage operations in a Foundation-independent manner.
/// All operations use only primitive types and Foundation-independent custom types.
public protocol SecureStorageProtocol: Sendable {
  /// Stores data securely with the given identifier.
  /// - Parameters:
  ///   - data: The data to store as a byte array.
  ///   - identifier: A string identifier for the stored data.
  /// - Returns: Success or an error.
  func storeData(_ data: [UInt8], withIdentifier identifier: String) async
    -> Result<Void, SecurityProtocolError>

  /// Retrieves data securely by its identifier.
  /// - Parameter identifier: A string identifying the data to retrieve.
  /// - Returns: The retrieved data as a byte array or an error.
  func retrieveData(withIdentifier identifier: String) async
    -> Result<[UInt8], SecurityProtocolError>

  /// Deletes data securely by its identifier.
  /// - Parameter identifier: A string identifying the data to delete.
  /// - Returns: Success or an error.
  func deleteData(withIdentifier identifier: String) async
    -> Result<Void, SecurityProtocolError>

  /// Lists all available data identifiers.
  /// - Returns: An array of data identifiers or an error.
  func listDataIdentifiers() async -> Result<[String], SecurityProtocolError>
}
