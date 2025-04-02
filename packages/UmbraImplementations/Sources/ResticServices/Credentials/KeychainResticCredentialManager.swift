import Foundation
import KeychainServices
import LoggingInterfaces
import ResticInterfaces
import UmbraErrors

/// A secure implementation of ResticCredentialManager that stores credentials in the system
/// keychain
public actor KeychainResticCredentialManager: ResticCredentialManager {
  /// Service identifier used for keychain storage
  private let serviceIdentifier: String

  /// Keychain security provider used for secure storage
  private let keychain: any KeychainSecurityProvider

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
    keychain: any KeychainSecurityProvider,
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
      metadata: ["repository": .string(repository)],
      source: "KeychainResticCredentialManager"
    )

    do {
      let passwordData=try await keychain.getSecurePasswordData(
        service: serviceIdentifier,
        account: makeAccountIdentifier(for: repository)
      )

      guard let password=String(data: passwordData, encoding: .utf8) else {
        throw ResticError.credentialError("Unable to decode stored password")
      }

      // For simplicity, we're not storing additional environment variables yet
      return ResticCredentials(
        repositoryIdentifier: repository,
        password: password
      )
    } catch {
      await logger.error(
        error,
        privacyLevel: .sensitive,
        source: "KeychainResticCredentialManager"
      )
      throw ResticError
        .credentialError("Failed to retrieve credentials: \(error.localizedDescription)")
    }
  }

  /// Stores credentials for a specific repository
  ///
  /// - Parameters:
  ///   - credentials: The credentials to store
  ///   - repository: The repository identifier to associate with these credentials
  /// - Throws: SecurityError if credentials cannot be stored
  public func storeCredentials(
    _ credentials: ResticCredentials,
    for repository: String
  ) async throws {
    await logger.debug(
      "Storing credentials for repository",
      metadata: ["repository": .string(repository)],
      source: "KeychainResticCredentialManager"
    )

    guard let passwordData=credentials.password.data(using: .utf8) else {
      throw ResticError.credentialError("Unable to encode password as data")
    }

    do {
      try await keychain.storeSecurePasswordData(
        passwordData,
        service: serviceIdentifier,
        account: makeAccountIdentifier(for: repository)
      )

      await logger.info(
        "Successfully stored credentials for repository",
        metadata: ["repository": .string(repository)],
        source: "KeychainResticCredentialManager"
      )
    } catch {
      await logger.error(
        error,
        privacyLevel: .sensitive,
        source: "KeychainResticCredentialManager",
        metadata: ["repository": .string(repository)]
      )
      throw ResticError
        .credentialError("Failed to store credentials: \(error.localizedDescription)")
    }
  }

  /// Removes stored credentials for a specific repository
  ///
  /// - Parameter repository: The repository identifier to remove credentials for
  /// - Throws: SecurityError if credentials cannot be removed
  public func removeCredentials(for repository: String) async throws {
    await logger.debug(
      "Removing credentials for repository",
      metadata: ["repository": .string(repository)],
      source: "KeychainResticCredentialManager"
    )

    do {
      try await keychain.deleteSecureItem(
        service: serviceIdentifier,
        account: makeAccountIdentifier(for: repository)
      )

      await logger.info(
        "Successfully removed credentials for repository",
        metadata: ["repository": .string(repository)],
        source: "KeychainResticCredentialManager"
      )
    } catch {
      await logger.error(
        error,
        privacyLevel: .public,
        source: "KeychainResticCredentialManager",
        metadata: ["repository": .string(repository)]
      )

      // If the error is "item not found", consider this a success
      if
        let keychainError=error as? KeychainError,
        case .itemNotFound=keychainError
      {
        // Not an error, item was already removed
        return
      }

      throw ResticError
        .credentialError("Failed to remove credentials: \(error.localizedDescription)")
    }
  }

  /// Checks if credentials exist for a specific repository
  ///
  /// - Parameter repository: The repository identifier to check
  /// - Returns: True if credentials exist, false otherwise
  public func hasCredentials(for repository: String) async -> Bool {
    do {
      _=try await keychain.getSecurePasswordData(
        service: serviceIdentifier,
        account: makeAccountIdentifier(for: repository)
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
