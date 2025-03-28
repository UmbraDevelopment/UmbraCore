/**
 # AnyCryptoServiceAdapter

 This adapter implements a type-erasure pattern for CryptoServiceProtocol, allowing
 different implementations to be used interchangeably. It wraps any CryptoServiceProtocol
 implementation and forwards calls to it, providing a unified interface.

 ## Responsibilities

 * Provide type erasure for CryptoServiceProtocol implementations
 * Forward method calls to the wrapped implementation
 * Maintain protocol conformance guarantees
 * Enable dependency injection and simplified testing
 */

import Foundation
import SecurityCoreInterfaces
import SecurityCoreTypes
import SecurityTypes
import UmbraErrors

/// Type-erasing adapter for CryptoServiceProtocol
public final class AnyCryptoServiceAdapter: CryptoServiceProtocol, Sendable {
  // MARK: - Properties

  /// The wrapped crypto service implementation
  private let wrapped: CryptoServiceProtocol

  // MARK: - Initialisation

  /// Create a new adapter that wraps the specified crypto service
  /// - Parameter wrapped: The crypto service to wrap
  public init(wrapped: CryptoServiceProtocol) {
    self.wrapped=wrapped
  }

  // MARK: - CryptoServiceProtocol Implementation

  /// Encrypt data using the provided key
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - key: Encryption key
  /// - Returns: Encrypted data or error
  public func encrypt(
    data: SecureBytes,
    using key: SecureBytes
  ) async -> Result<SecureBytes, SecurityProtocolError> {
    await wrapped.encrypt(data: data, using: key)
  }

  /// Decrypt data using the provided key
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - key: Decryption key
  /// - Returns: Decrypted data or error
  public func decrypt(
    data: SecureBytes,
    using key: SecureBytes
  ) async -> Result<SecureBytes, SecurityProtocolError> {
    await wrapped.decrypt(data: data, using: key)
  }

  /// Hashes the provided data using a cryptographically strong algorithm
  /// - Parameter data: The data to hash
  /// - Returns: The resulting hash or error
  public func hash(data: SecureBytes) async
  -> Result<SecureBytes, SecurityProtocolError> {
    await wrapped.hash(data: data)
  }

  /// Verifies the integrity of data against a known hash
  /// - Parameters:
  ///   - data: The data to verify
  ///   - expectedHash: The expected hash value
  /// - Returns: Boolean indicating whether the hash matches or error
  public func verifyHash(data: SecureBytes, expectedHash: SecureBytes) async
  -> Result<Bool, SecurityProtocolError> {
    await wrapped.verifyHash(data: data, expectedHash: expectedHash)
  }
}
