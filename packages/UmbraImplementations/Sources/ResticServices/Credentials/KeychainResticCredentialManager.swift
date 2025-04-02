import Foundation
import KeychainServices
import KeychainInterfaces
import LoggingInterfaces
import LoggingTypes
import ResticInterfaces
import UmbraErrors

/// A secure implementation of ResticCredentialManager that stores credentials in the system
/// keychain
public actor KeychainResticCredentialManager: ResticCredentialManager {
  /// Service identifier used for keychain storage
  private let serviceIdentifier: String

  /// Keychain security provider used for secure storage
  private let keychain: any KeychainSecurityProtocol

  /// Logger for security-related operations
  private let logger: any LoggingProtocol

  /// Creates a new keychain-based credential manager for Restic repositories
  ///
  /// - Parameters:
  ///   - serviceIdentifier: The service identifier to use for keychain entries
  ///   - keychain: The keychain security provider to use for storage
  ///   - logger: Logger for security operations
  public init(
    serviceIdentifier: String="com.umbra.restic-repositories",
    keychain: any KeychainSecurityProtocol,
    logger: any LoggingProtocol
  ) {
    self.serviceIdentifier=serviceIdentifier
    self.keychain=keychain
    self.logger=logger
  }

  /// Retrieves stored credentials for a specific repository
  ///
  /// - Parameter repository: The repository identifier to retrieve credentials for
  /// - Returns: The stored credentials for the repository
  /// - Throws: SecurityError if credentials cannot be retrieved
  public func getCredentials(for repository: String) async throws -> ResticCredentials {
    await logger.debug(
      "Retrieving credentials for repository",
      metadata: PrivacyMetadata([
        "repository": (value: repository, privacy: .private)
      ]),
      source: "KeychainResticCredentialManager"
    )
    
    do {
      let secret = try await keychain.retrieveEncryptedSecret(
        forAccount: makeAccountIdentifier(for: repository),
        serviceIdentifier: serviceIdentifier
      )
      
      await logger.debug(
        "Successfully retrieved credentials",
        metadata: PrivacyMetadata([
          "repository": (value: repository, privacy: .private)
        ]),
        source: "KeychainResticCredentialManager"
      )
      
      return ResticCredentials(
        repositoryIdentifier: repository,
        password: secret
      )
    } catch {
      await logger.error(
        "Failed to retrieve credentials: \(error.localizedDescription)",
        metadata: PrivacyMetadata([
          "repository": (value: repository, privacy: .private),
          "error": (value: error.localizedDescription, privacy: .private)
        ]),
        source: "KeychainResticCredentialManager"
      )
      throw ResticError.credentialError("Could not retrieve credentials for repository")
    }
  }
  
  /// Stores credentials for a specific repository
  ///
  /// - Parameters:
  ///   - credentials: The credentials to store
  ///   - repository: The repository identifier to store credentials for
  /// - Throws: SecurityError if credentials cannot be stored
  public func storeCredentials(
    _ credentials: ResticCredentials,
    for repository: String
  ) async throws {
    await logger.debug(
      "Storing credentials for repository",
      metadata: PrivacyMetadata([
        "repository": (value: repository, privacy: .private)
      ]),
      source: "KeychainResticCredentialManager"
    )
    
    do {
      try await keychain.storeEncryptedSecret(
        credentials.password,
        forAccount: makeAccountIdentifier(for: repository),
        keyIdentifier: nil,
        accessOptions: nil
      )
      
      await logger.info(
        "Successfully stored credentials",
        metadata: PrivacyMetadata([
          "repository": (value: repository, privacy: .private)
        ]),
        source: "KeychainResticCredentialManager"
      )
    } catch {
      await logger.error(
        "Failed to store credentials: \(error.localizedDescription)",
        metadata: PrivacyMetadata([
          "repository": (value: repository, privacy: .private),
          "error": (value: error.localizedDescription, privacy: .private)
        ]),
        source: "KeychainResticCredentialManager"
      )
      throw ResticError.credentialError("Failed to store credentials for repository")
    }
  }
  
  /// Removes credentials for a specific repository
  ///
  /// - Parameter repository: The repository identifier to remove credentials for
  /// - Throws: SecurityError if credentials cannot be removed
  public func removeCredentials(for repository: String) async throws {
    await logger.debug(
      "Removing credentials for repository",
      metadata: PrivacyMetadata([
        "repository": (value: repository, privacy: .private)
      ]),
      source: "KeychainResticCredentialManager"
    )
    
    do {
      try await keychain.removeItem(
        forAccount: makeAccountIdentifier(for: repository),
        serviceIdentifier: serviceIdentifier
      )
      
      await logger.info(
        "Successfully removed credentials for repository",
        metadata: PrivacyMetadata([
          "repository": (value: repository, privacy: .private)
        ]),
        source: "KeychainResticCredentialManager"
      )
    } catch {
      await logger.error(
        "Failed to remove credentials: \(error.localizedDescription)",
        metadata: PrivacyMetadata([
          "repository": (value: repository, privacy: .private),
          "error": (value: error.localizedDescription, privacy: .private)
        ]),
        source: "KeychainResticCredentialManager"
      )
      throw ResticError.credentialError("Failed to remove credentials for repository")
    }
  }

  /// Checks if credentials exist for a specific repository
  ///
  /// - Parameter repository: The repository identifier to check
  /// - Returns: True if credentials exist, false otherwise
  public func hasCredentials(for repository: String) async -> Bool {
    do {
      _=try await keychain.retrieveEncryptedSecret(
        forAccount: makeAccountIdentifier(for: repository),
        serviceIdentifier: serviceIdentifier
      )
      return true
    } catch {
      return false
    }
  }

  // MARK: - Private Methods

  /// Creates a standardised account identifier format for keychain storage
  ///
  /// - Parameter repository: The repository identifier to format
  /// - Returns: A standardised account identifier
  private func makeAccountIdentifier(for repository: String) -> String {
    // Normalise repository paths/URLs for consistent storage
    // This handles variations in how repositories might be specified (trailing slashes, etc.)
    repository.trimmingCharacters(in: .whitespacesAndNewlines)
      .replacingOccurrences(of: "//", with: "/")
  }
}
