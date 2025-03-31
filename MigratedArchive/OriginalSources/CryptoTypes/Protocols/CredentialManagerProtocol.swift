import Foundation

/// Protocol defining the credential management operations
@preconcurrency
public protocol CredentialManagerProtocol: Sendable {
  /// Save a credential securely
  /// - Parameters:
  ///   - identifier: Identifier for the credential
  ///   - data: Data to store
  func save(_ data: Data, forIdentifier identifier: String) async throws

  /// Retrieve a credential
  /// - Parameter identifier: Identifier for the credential
  /// - Returns: Stored data
  func retrieve(forIdentifier identifier: String) async throws -> Data

  /// Delete a credential
  /// - Parameter identifier: Identifier for the credential
  func delete(forIdentifier identifier: String) async throws
}
