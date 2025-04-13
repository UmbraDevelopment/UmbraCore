import CryptoInterfaces
import CryptoTypes
import DomainSecurityTypes
import Foundation
import LoggingInterfaces
import SecurityCoreInterfaces
import UmbraErrors
import UmbraErrorsCore
import UmbraErrorsDTOs

/// Default implementation of CredentialManagerProtocol using a SecureStorageProvider
public actor DefaultCredentialManager: CredentialManagerProtocol {
  /// The secure storage provider used for storing credentials
  private let storageProvider: SecureStorageProvider

  /// The crypto service used for encryption/decryption
  private let cryptoService: CryptoServiceProtocol

  /// Initialise a new credential manager
  /// - Parameters:
  ///   - storageProvider: The storage provider to use
  ///   - cryptoService: The crypto service to use
  public init(storageProvider: SecureStorageProvider, cryptoService: CryptoServiceProtocol) {
    self.storageProvider=storageProvider
    self.cryptoService=cryptoService
  }

  /// Save a credential securely
  /// - Parameters:
  ///   - data: Data to store
  ///   - identifier: Identifier for the credential
  public func save(_ data: Data, forIdentifier identifier: String) async throws {
    // In a real implementation, we would encrypt the data before storing
    // This is a simplified implementation that delegates to the storage provider
    do {
      try await storageProvider.securelyStore(data: data, withIdentifier: identifier, options: nil)
    } catch {
      let context=ErrorContext([
        "identifier": identifier,
        "error": error.localizedDescription
      ])
      throw CryptoErrorDTO(
        type: CryptoErrorDTO.CryptoErrorType.operationFailed,
        description: "Failed to store credential",
        context: context,
        underlyingError: error
      )
    }
  }

  /// Retrieve a credential securely
  /// - Parameter identifier: Identifier for the credential
  /// - Returns: Stored data
  public func retrieve(forIdentifier identifier: String) async throws -> Data {
    do {
      return try await storageProvider.retrieveSecureData(withIdentifier: identifier)
    } catch {
      let context=ErrorContext([
        "identifier": identifier,
        "error": error.localizedDescription
      ])
      throw CryptoErrorDTO(
        type: CryptoErrorDTO.CryptoErrorType.operationFailed,
        description: "Failed to retrieve credential",
        context: context,
        underlyingError: error
      )
    }
  }

  /// Delete a credential securely
  /// - Parameter identifier: Identifier for the credential
  public func delete(forIdentifier identifier: String) async throws {
    do {
      try await storageProvider.deleteSecureData(withIdentifier: identifier)
    } catch {
      let context=ErrorContext([
        "identifier": identifier,
        "error": error.localizedDescription
      ])
      throw CryptoErrorDTO(
        type: CryptoErrorDTO.CryptoErrorType.operationFailed,
        description: "Failed to delete credential",
        context: context,
        underlyingError: error
      )
    }
  }

  /// Check if a credential exists
  /// - Parameter identifier: Identifier for the credential
  /// - Returns: True if the credential exists, false otherwise
  public func exists(forIdentifier identifier: String) async -> Bool {
    do {
      _=try await storageProvider.retrieveSecureData(withIdentifier: identifier)
      return true
    } catch {
      return false
    }
  }
}
