import Foundation
import SecurityTypes
import UmbraErrors

/// Protocol defining the core security provider interface without Foundation dependencies
/// This is the base protocol that all security providers must implement
public protocol SecurityProviderProtocol: Sendable {
  /// Protocol identifier - used for protocol negotiation
  static var protocolIdentifier: String { get }

  /// Encrypt binary data using the provider's encryption mechanism
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - key: Encryption key
  /// - Returns: Encrypted data
  /// - Throws: SecurityProtocolError if encryption fails
  func encrypt(_ data: SecureBytes, key: SecureBytes) async throws -> SecureBytes

  /// Decrypt binary data using the provider's decryption mechanism
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - key: Decryption key
  /// - Returns: Decrypted data
  /// - Throws: SecurityProtocolError if decryption fails
  func decrypt(_ data: SecureBytes, key: SecureBytes) async throws -> SecureBytes

  /// Generate a cryptographically secure random key
  /// - Parameter length: Length of the key in bytes
  /// - Returns: Generated key
  /// - Throws: SecurityProtocolError if key generation fails
  func generateKey(length: Int) async throws -> SecureBytes

  /// Hash data using the provider's hashing mechanism
  /// - Parameter data: Data to hash
  /// - Returns: Hash of the data
  /// - Throws: SecurityProtocolError if hashing fails
  func hash(_ data: SecureBytes) async throws -> SecureBytes
}

/// Default implementation for SecurityProviderProtocol
extension SecurityProviderProtocol {
  /// Default protocol identifier
  public static var protocolIdentifier: String {
    "com.umbra.security.provider.protocol"
  }
}
