import Foundation
import UmbraCoreTypes
import Errors
import Types

/// Secure storage provider protocol
/// Defines operations for securely storing, retrieving, and managing sensitive data
public protocol SecureStorageProvider: Sendable {
  /// Store data securely
  /// - Parameters:
  ///   - data: Data to store
  ///   - key: Key to store data under
  /// - Returns: Success or security protocol error
  func storeData(_ data: SecureBytes, forKey key: String) async -> Result<Void, SecurityProtocolError>

  /// Retrieve data securely
  /// - Parameter key: Key to retrieve data for
  /// - Returns: Retrieved data or security protocol error
  func retrieveData(forKey key: String) async -> Result<SecureBytes, SecurityProtocolError>

  /// Delete data securely
  /// - Parameter key: Key to delete data for
  /// - Returns: Success or security protocol error
  func deleteData(forKey key: String) async -> Result<Void, SecurityProtocolError>
  
  /// Check if data exists for a key
  /// - Parameter key: Key to check
  /// - Returns: True if data exists, false otherwise
  func hasData(forKey key: String) async -> Bool
  
  /// List all keys in the secure storage
  /// - Returns: List of keys or security protocol error
  func listKeys() async -> Result<[String], SecurityProtocolError>
}
