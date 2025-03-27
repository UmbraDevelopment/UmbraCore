import Foundation

/// Secure storage provider protocol
public protocol SecureStorageProvider: Sendable {
  /// Store data securely
  /// - Parameters:
  ///   - data: Data to store
  ///   - key: Key to store data under
  /// - Returns: Success or failure
  func storeData(_ data: Data, forKey key: String) async -> Result<Void, SecurityErrorDTO>

  /// Retrieve data securely
  /// - Parameter key: Key to retrieve data for
  /// - Returns: Retrieved data or error
  func retrieveData(forKey key: String) async -> Result<Data, SecurityErrorDTO>

  /// Delete data securely
  /// - Parameter key: Key to delete data for
  /// - Returns: Success or failure
  func deleteData(forKey key: String) async -> Result<Void, SecurityErrorDTO>
  
  /// Check if a key exists in secure storage
  /// - Parameter key: Key to check
  /// - Returns: True if the key exists, false otherwise
  func hasKey(_ key: String) async -> Result<Bool, SecurityErrorDTO>
  
  /// List all available keys in secure storage
  /// - Returns: Array of keys or error
  func listKeys() async -> Result<[String], SecurityErrorDTO>
}
