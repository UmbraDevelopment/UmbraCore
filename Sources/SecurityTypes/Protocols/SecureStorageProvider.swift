import Foundation

/// Secure storage provider protocol
public protocol SecureStorageProvider {
  /// Store data securely
  /// - Parameters:
  ///   - data: Data to store
  ///   - key: Key to store data under
  /// - Returns: Success or failure
  func storeData(_ data: Data, forKey key: String) -> Result<Void, Error>

  /// Retrieve data securely
  /// - Parameter key: Key to retrieve data for
  /// - Returns: Retrieved data or error
  func retrieveData(forKey key: String) -> Result<Data, Error>

  /// Delete data securely
  /// - Parameter key: Key to delete data for
  /// - Returns: Success or failure
  func deleteData(forKey key: String) -> Result<Void, Error>
}
