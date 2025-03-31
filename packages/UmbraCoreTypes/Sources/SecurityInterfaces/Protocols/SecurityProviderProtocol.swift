import DomainSecurityTypes
import Foundation
import UmbraErrors

/// Protocol defining the core security provider interface without Foundation dependencies.
///
/// This is the base protocol that all security providers must implement to provide
/// cryptographic services in the Alpha Dot Five architecture. It ensures proper
/// abstraction of different security implementations.
public protocol SecurityProviderProtocol: Sendable {
  /// Protocol identifier - used for provider identification and negotiation
  static var protocolIdentifier: String { get }
  
  /// The security level provided by this implementation
  var securityLevel: SecurityLevelDTO { get }

  /// Encrypt binary data using the provider's encryption mechanism
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - key: Encryption key
  ///   - iv: Optional initialisation vector
  /// - Returns: Encrypted data
  /// - Throws: SecurityError if encryption fails
  func encrypt(data: [UInt8], key: [UInt8], iv: [UInt8]?) async throws -> [UInt8]

  /// Decrypt binary data using the provider's decryption mechanism
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - key: Decryption key
  ///   - iv: Optional initialisation vector
  /// - Returns: Decrypted data
  /// - Throws: SecurityError if decryption fails
  func decrypt(data: [UInt8], key: [UInt8], iv: [UInt8]?) async throws -> [UInt8]

  /// Generate a cryptographically secure random key
  /// - Parameter length: Length of the key in bytes
  /// - Returns: Generated key
  /// - Throws: SecurityError if key generation fails
  func generateKey(length: Int) async throws -> [UInt8]

  /// Hash data using the specified algorithm
  /// - Parameters:
  ///   - data: Data to hash
  ///   - algorithm: Name of the hash algorithm to use
  /// - Returns: Hash of the data
  /// - Throws: SecurityError if hashing fails
  func hash(data: [UInt8], algorithm: String) async throws -> [UInt8]
  
  /// Generate cryptographically secure random bytes
  /// - Parameter count: Number of bytes to generate
  /// - Returns: Random bytes
  /// - Throws: SecurityError if random generation fails
  func generateRandomBytes(count: Int) async throws -> [UInt8]
  
  /// Signs data using the specified key
  /// - Parameters:
  ///   - data: Data to sign
  ///   - key: Signing key
  /// - Returns: Signature
  /// - Throws: SecurityError if signing fails
  func sign(data: [UInt8], key: [UInt8]) async throws -> [UInt8]
  
  /// Verifies a signature against the original data
  /// - Parameters:
  ///   - signature: Signature to verify
  ///   - data: Original data
  ///   - key: Verification key
  /// - Returns: True if signature is valid, false otherwise
  /// - Throws: SecurityError if verification fails
  func verify(signature: [UInt8], data: [UInt8], key: [UInt8]) async throws -> Bool
  
  /// Securely wipes sensitive data from memory
  /// - Parameter data: Data to wipe
  /// - Throws: SecurityError if wiping fails
  func secureWipe(data: inout [UInt8]) async throws
}

/// Default implementation for SecurityProviderProtocol
extension SecurityProviderProtocol {
  /// Default protocol identifier
  public static var protocolIdentifier: String {
    "uk.co.umbra.security.provider.protocol.v2"
  }
  
  /// Default security level
  public var securityLevel: SecurityLevelDTO {
    .standard
  }
  
  /// Default implementation for hashing with no specific algorithm
  /// Uses SHA-256 as the default algorithm
  public func hash(_ data: [UInt8]) async throws -> [UInt8] {
    try await hash(data: data, algorithm: "SHA-256")
  }
  
  /// Default implementation for encryption without IV
  /// Throws an error as most secure algorithms require an IV
  public func encrypt(_ data: [UInt8], key: [UInt8]) async throws -> [UInt8] {
    try await encrypt(data: data, key: key, iv: nil)
  }
  
  /// Default implementation for decryption without IV
  /// Throws an error as most secure algorithms require an IV
  public func decrypt(_ data: [UInt8], key: [UInt8]) async throws -> [UInt8] {
    try await decrypt(data: data, key: key, iv: nil)
  }
}
