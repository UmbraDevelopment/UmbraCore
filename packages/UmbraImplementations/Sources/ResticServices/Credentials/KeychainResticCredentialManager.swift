import Foundation
import KeychainInterfaces
import LoggingInterfaces
import LoggingTypes
import ResticInterfaces

/// Implementation of credential management for Restic using the Keychain
public actor KeychainResticCredentialManager: ResticCredentialManager {
  private let keychain: any KeychainServiceProtocol
  private let logger: ResticLogger

  /// Initialise the credential manager
  ///
  /// - Parameters:
  ///   - keychain: The keychain implementation to use
  ///   - logger: Logger for credential operations
  public init(keychain: any KeychainServiceProtocol, logger: ResticLogger) {
    self.keychain=keychain
    self.logger=logger
  }

  /// Checks if credentials exist for a specific repository
  ///
  /// - Parameter repository: The repository identifier to check
  /// - Returns: True if credentials exist, false otherwise
  public func hasCredentials(for repository: String) async -> Bool {
    do {
      _=try await getCredentials(for: repository)
      return true
    } catch {
      return false
    }
  }

  /// Gets the credentials for a repository
  ///
  /// - Parameter repository: Repository path or identifier
  /// - Returns: The credentials including repository and password
  public func getCredentials(
    for repository: String
  ) async throws -> ResticCredentials {
    await logger.debug(
      "Retrieving credentials for repository",
      metadata: PrivacyMetadata([
        "repository": (value: repository, privacy: .private)
      ]),
      source: "KeychainResticCredentialManager"
    )

    do {
      // Try to get password from the keychain
      let password=try await keychain.retrievePassword(
        for: keychainKey(for: repository),
        keychainOptions: KeychainOptions.standard
      )

      // Create and return credentials
      let credentials=ResticCredentials(
        repositoryIdentifier: repository,
        password: password
      )

      await logger.debug(
        "Successfully retrieved credentials",
        metadata: PrivacyMetadata([
          "repository": (value: repository, privacy: .private),
          "hasPassword": (value: !password.isEmpty, privacy: .public)
        ]),
        source: "KeychainResticCredentialManager"
      )

      return credentials
    } catch {
      // Map keychain errors to more specific security errors
      await logger.error(
        "Failed to retrieve credentials: \(error.localizedDescription)",
        metadata: PrivacyMetadata([
          "repository": (value: repository, privacy: .private),
          "error": (value: error.localizedDescription, privacy: .private)
        ]),
        source: "KeychainResticCredentialManager"
      )

      throw ResticError
        .credentialError("Failed to retrieve credentials: \(error.localizedDescription)")
    }
  }

  /// Stores credentials for a repository
  ///
  /// - Parameters:
  ///   - credentials: The credentials to store
  ///   - repository: The repository identifier to associate with these credentials
  public func storeCredentials(
    _ credentials: ResticCredentials,
    for repository: String
  ) async throws {
    // Validate we have a password to store
    guard !credentials.password.isEmpty else {
      throw ResticError.invalidParameter("Cannot store empty password")
    }

    await logger.debug(
      "Storing credentials for repository",
      metadata: PrivacyMetadata([
        "repository": (value: repository, privacy: .private)
      ]),
      source: "KeychainResticCredentialManager"
    )

    do {
      // Store the password in the keychain
      try await keychain.storePassword(
        credentials.password,
        for: keychainKey(for: repository),
        keychainOptions: KeychainOptions.standard
      )

      await logger.debug(
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

      throw ResticError
        .credentialError("Failed to store credentials: \(error.localizedDescription)")
    }
  }

  /// Removes credentials for a repository
  ///
  /// - Parameter repository: Repository path or identifier
  public func removeCredentials(
    for repository: String
  ) async throws {
    await logger.debug(
      "Removing credentials for repository",
      metadata: PrivacyMetadata([
        "repository": (value: repository, privacy: .private)
      ]),
      source: "KeychainResticCredentialManager"
    )

    do {
      try await keychain.deletePassword(
        for: keychainKey(for: repository),
        keychainOptions: KeychainOptions.standard
      )

      await logger.debug(
        "Successfully removed credentials",
        metadata: PrivacyMetadata([
          "repository": (value: repository, privacy: .private)
        ]),
        source: "KeychainResticCredentialManager"
      )
    } catch {
      // Don't throw if the item doesn't exist - treat as success
      if
        let nsError=error as NSError?,
        nsError.domain == "com.apple.security" && nsError.code == -25300
      {
        return
      }

      await logger.error(
        "Failed to remove credentials: \(error.localizedDescription)",
        metadata: PrivacyMetadata([
          "repository": (value: repository, privacy: .private),
          "error": (value: error.localizedDescription, privacy: .private)
        ]),
        source: "KeychainResticCredentialManager"
      )

      throw ResticError
        .credentialError("Failed to remove credentials: \(error.localizedDescription)")
    }
  }

  /// Creates a keychain key from a repository path
  ///
  /// - Parameter repository: Repository path or identifier
  /// - Returns: Keychain key string
  private func keychainKey(for repository: String) -> String {
    "restic_repo_\(repository.replacingOccurrences(of: "/", with: "_"))"
  }
}
