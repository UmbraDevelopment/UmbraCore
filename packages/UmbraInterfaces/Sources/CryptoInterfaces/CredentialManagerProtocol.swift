import Foundation
import DomainSecurityTypes

/// Protocol defining the credential management operations
///
/// This protocol is used in conjunction with SecureStorageProvider to securely store and manage
/// credentials.
@preconcurrency
public protocol CredentialManagerProtocol: Sendable {
  /// Save a credential securely
  /// - Parameters:
  ///   - identifier: Identifier for the credential
  ///   - data: Data to store
  func save(_ data: DomainSecurityTypes.SecureBytes, forIdentifier identifier: String) async throws

  /// Retrieve a credential
  /// - Parameter identifier: Identifier for the credential
  /// - Returns: Stored data
  func retrieve(forIdentifier identifier: String) async throws -> DomainSecurityTypes.SecureBytes

  /// Delete a credential
  /// - Parameter identifier: Identifier for the credential
  func delete(forIdentifier identifier: String) async throws
}
