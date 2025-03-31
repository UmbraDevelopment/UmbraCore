import Foundation

/// Protocol for secure storage providers
public protocol SecureStorageProvider: Actor {
  /// Stores data securely
  /// - Parameters:
  ///   - data: The data to store
  ///   - key: Key to identify the stored data
  /// - Throws: Implementation-specific errors
  func set(_ data: Data, key: String) async throws

  /// Retrieves stored data
  /// - Parameter key: Key identifying the data to retrieve
  /// - Returns: The stored data, or nil if not found
  /// - Throws: Implementation-specific errors
  func getData(_ key: String) async throws -> Data?

  /// Removes stored data
  /// - Parameter key: Key identifying the data to remove
  /// - Throws: Implementation-specific errors
  func remove(_ key: String) async throws

  /// Checks if data exists for a key
  /// - Parameter key: Key to check
  /// - Returns: True if data exists for the key
  /// - Throws: Implementation-specific errors
  func contains(_ key: String) async throws -> Bool
}
