import Foundation
import UmbraCoreTypes
import UmbraErrors

/// Type definitions for XPC protocol operations
public enum XPCProtocolTypeDefs {
  /// Key type enumeration
  public enum KeyType: String, Sendable, Codable {
    /// Symmetric encryption key
    case symmetric
    /// Public key
    case publicKey
    /// Private key
    case privateKey
    /// Certificate
    case certificate
    /// Secret key
    case secret
  }

  /// Key format enumeration
  public enum KeyFormat: String, Sendable, Codable {
    /// Raw format
    case raw
    /// PEM format
    case pem
    /// DER format
    case der
    /// PKCS#12 format
    case pkcs12
  }
}

/// Key management protocol extension for services that handle cryptographic keys
public protocol KeyManagementServiceProtocol: Sendable {
  /// Generate a new key
  /// - Parameters:
  ///   - keyType: Type of key to generate
  ///   - keyIdentifier: Optional identifier for the key
  ///   - metadata: Optional metadata for the key
  /// - Returns: Result with key identifier on success or SecurityError on failure
  func generateKey(
    keyType: XPCProtocolTypeDefs.KeyType,
    keyIdentifier: String?,
    metadata: [String: String]?
  ) async -> Result<String, UmbraErrors.SecurityError>

  /// Delete a key
  /// - Parameter keyIdentifier: Identifier for the key to delete
  /// - Returns: Result with void on success or SecurityError on failure
  func deleteKey(keyIdentifier: String) async
    -> Result<Void, UmbraErrors.SecurityError>

  /// List all keys
  /// - Returns: Result with array of key identifiers on success or SecurityError on failure
  func listKeys() async -> Result<[String], UmbraErrors.SecurityError>

  /// Import a key
  /// - Parameters:
  ///   - keyData: SecureBytes containing the key data
  ///   - keyType: Type of key being imported
  ///   - keyIdentifier: Optional identifier for the key
  ///   - metadata: Optional metadata for the key
  /// - Returns: Result with key identifier on success or SecurityError on failure
  func importKey(
    keyData: UmbraCoreTypes.SecureBytes,
    keyType: XPCProtocolTypeDefs.KeyType,
    keyIdentifier: String?,
    metadata: [String: String]?
  ) async -> Result<String, UmbraErrors.SecurityError>

  /// Export a key
  /// - Parameters:
  ///   - keyIdentifier: Identifier for the key to export
  ///   - format: Format to export the key in
  /// - Returns: Result with key data as SecureBytes on success or SecurityError on failure
  func exportKey(
    keyIdentifier: String,
    format: XPCProtocolTypeDefs.KeyFormat
  ) async -> Result<UmbraCoreTypes.SecureBytes, UmbraErrors.SecurityError>
}
