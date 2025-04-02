import Foundation

/// Protocol defining secure credential management operations for Restic repositories
public protocol ResticCredentialManager: Sendable {
  /// Retrieves stored credentials for a specific repository
  ///
  /// - Parameter repository: The repository identifier to retrieve credentials for
  /// - Returns: The stored credentials for the repository
  /// - Throws: SecurityError if credentials cannot be retrieved
  func getCredentials(for repository: String) async throws -> ResticCredentials

  /// Stores credentials for a specific repository
  ///
  /// - Parameters:
  ///   - credentials: The credentials to store
  ///   - repository: The repository identifier to associate with these credentials
  /// - Throws: SecurityError if credentials cannot be stored
  func storeCredentials(_ credentials: ResticCredentials, for repository: String) async throws

  /// Removes stored credentials for a specific repository
  ///
  /// - Parameter repository: The repository identifier to remove credentials for
  /// - Throws: SecurityError if credentials cannot be removed
  func removeCredentials(for repository: String) async throws

  /// Checks if credentials exist for a specific repository
  ///
  /// - Parameter repository: The repository identifier to check
  /// - Returns: True if credentials exist, false otherwise
  func hasCredentials(for repository: String) async -> Bool
}
