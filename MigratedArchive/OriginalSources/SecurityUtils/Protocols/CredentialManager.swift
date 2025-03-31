import Foundation

/// Protocol for managing secure credentials
public protocol CredentialManager: Sendable {
  /// Save a credential
  /// - Parameters:
  ///   - data: Data to save
  ///   - identifier: Unique identifier for the credential
  /// - Throws: Error if saving fails
  func save(_ data: Data, forIdentifier identifier: String) async throws

  /// Load a credential
  /// - Parameter identifier: Unique identifier for the credential
  /// - Returns: The stored credential data
  /// - Throws: Error if loading fails
  func load(forIdentifier identifier: String) async throws -> Data

  /// Delete a credential
  /// - Parameter identifier: Unique identifier for the credential
  /// - Throws: Error if deletion fails
  func delete(forIdentifier identifier: String) async throws
}
