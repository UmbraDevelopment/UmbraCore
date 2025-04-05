import Foundation
import ResticInterfaces

/// An in-memory implementation of ResticCredentialManager for testing purposes.
///
/// This implementation stores credentials in memory, making it suitable for
/// testing and development environments where secure storage is not required.
public actor InMemoryResticCredentialManager: ResticCredentialManager {
  /// In-memory storage for credentials
  private var credentials: [String: ResticCredentials]=[:]

  /// Creates a new in-memory credential manager
  public init() {
    // No initialisation required
  }

  /// Retrieves stored credentials for a specific repository
  ///
  /// - Parameter repository: The repository identifier to retrieve credentials for
  /// - Returns: The stored credentials for the repository
  /// - Throws: ResticError if credentials cannot be retrieved
  public func getCredentials(for repository: String) async throws -> ResticCredentials {
    guard let storedCredentials=credentials[repository] else {
      throw ResticError.credentialError("No credentials found for repository")
    }

    return storedCredentials
  }

  /// Stores credentials for a specific repository
  ///
  /// - Parameters:
  ///   - credentials: The credentials to store
  ///   - repository: The repository identifier to store credentials for
  /// - Throws: ResticError if credentials cannot be stored
  public func storeCredentials(
    _ credentials: ResticCredentials,
    for repository: String
  ) async throws {
    self.credentials[repository]=credentials
  }

  /// Removes credentials for a specific repository
  ///
  /// - Parameter repository: The repository identifier to remove credentials for
  /// - Throws: ResticError if credentials cannot be removed
  public func removeCredentials(for repository: String) async throws {
    credentials.removeValue(forKey: repository)
  }

  /// Checks if credentials exist for a specific repository
  ///
  /// - Parameter repository: The repository identifier to check
  /// - Returns: True if credentials exist, false otherwise
  public func hasCredentials(for repository: String) async -> Bool {
    credentials[repository] != nil
  }
}
