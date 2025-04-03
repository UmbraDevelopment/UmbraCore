import DomainSecurityTypes
import Foundation
import UmbraErrors
import UmbraErrorsDomains
import UmbraErrorsDTOs

/// Adapter for SecurityProviderProtocol implementations
///
/// This adapter allows for easier integration with the new Alpha Dot Five architecture
/// by providing a standard interface for security provider implementations.
public final class SecurityProviderAdapter {
  // Define the SecurityProviderProtocol locally since we can't import it due to circular
  // dependencies
  private let provider: any SecurityProviderProtocolAdapter

  /// Initialise with a security provider implementation
  /// - Parameter provider: The security provider to adapt
  public init(provider: any SecurityProviderProtocolAdapter) {
    self.provider=provider
  }

  /// Encrypts data with the specified key
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - key: Encryption key
  /// - Returns: Result containing either encrypted data or an error
  public func encrypt(
    _ data: SecureBytes,
    key: SecureBytes
  ) async -> Result<SecureBytes, SecurityErrorDTO> {
    do {
      let encryptedData=try await provider.encrypt(data, key: key)
      return .success(encryptedData)
    } catch {
      let errorDTO=SecurityErrorDTO(
        type: .encryption,
        description: "Encryption failed: \(error.localizedDescription)",
        context: ["operation": "encrypt"],
        underlyingError: error
      )
      return .failure(errorDTO)
    }
  }

  /// Decrypts data with the specified key
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - key: Decryption key
  /// - Returns: Result containing either decrypted data or an error
  public func decrypt(
    _ data: SecureBytes,
    key: SecureBytes
  ) async -> Result<SecureBytes, SecurityErrorDTO> {
    do {
      let decryptedData=try await provider.decrypt(data, key: key)
      return .success(decryptedData)
    } catch {
      let errorDTO=SecurityErrorDTO(
        type: .decryption,
        description: "Decryption failed: \(error.localizedDescription)",
        context: ["operation": "decrypt"],
        underlyingError: error
      )
      return .failure(errorDTO)
    }
  }

  /// Generates a cryptographic key of the specified length
  /// - Parameter length: Length of the key in bytes
  /// - Returns: Result containing either generated key or an error
  public func generateKey(length: Int) async -> Result<SecureBytes, SecurityErrorDTO> {
    do {
      let key=try await provider.generateKey(length: length)
      return .success(key)
    } catch {
      let errorDTO=SecurityErrorDTO(
        type: .keyManagement,
        description: "Key generation failed: \(error.localizedDescription)",
        context: ["operation": "generateKey", "length": "\(length)"],
        underlyingError: error
      )
      return .failure(errorDTO)
    }
  }

  /// Hashes the provided data
  /// - Parameter data: Data to hash
  /// - Returns: Result containing either hashed data or an error
  public func hash(_ data: SecureBytes) async -> Result<SecureBytes, SecurityErrorDTO> {
    do {
      let hashedData=try await provider.hash(data)
      return .success(hashedData)
    } catch {
      let errorDTO=SecurityErrorDTO(
        type: .encryption,
        description: "Hashing failed: \(error.localizedDescription)",
        context: ["operation": "hash"],
        underlyingError: error
      )
      return .failure(errorDTO)
    }
  }
}

/// Local protocol definition to avoid circular dependencies
public protocol SecurityProviderProtocolAdapter: Sendable {
  func encrypt(_ data: SecureBytes, key: SecureBytes) async throws -> SecureBytes
  func decrypt(_ data: SecureBytes, key: SecureBytes) async throws -> SecureBytes
  func generateKey(length: Int) async throws -> SecureBytes
  func hash(_ data: SecureBytes) async throws -> SecureBytes
}
