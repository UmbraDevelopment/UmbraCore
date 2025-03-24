import UmbraErrors
import UmbraErrorsCore
import Foundation
import UmbraCoreTypes

// Local type declarations to replace imports
// These replace the removed ErrorHandling and ErrorHandlingDomains imports

/// Error domain namespace
public enum ErrorDomain {
  /// Security domain
  public static let security="Security"
  /// Crypto domain
  public static let crypto="Crypto"
  /// Application domain
  public static let application="Application"
}

/// Error context protocol
public protocol ErrorContext {
  /// Domain of the error
  var domain: String { get }
  /// Code of the error
  var code: Int { get }
  /// Description of the error
  var description: String { get }
}

/// Base error context implementation
public struct BaseErrorContext: ErrorContext {
  /// Domain of the error
  public let domain: String
  /// Code of the error
  public let code: Int
  /// Description of the error
  public let description: String

  /// Initialise with domain, code and description
  public init(domain: String, code: Int, description: String) {
    self.domain=domain
    self.code=code
    self.description=description
  }
}

/**
 # Complete XPC Service Protocol

 This file defines the most comprehensive protocol for XPC services in UmbraCore,
 building upon the standard protocol to provide a complete suite of cryptographic
 and security functionality.

 ## Features

 * Advanced cryptographic operations with SecureBytes
 * Comprehensive key management and derivation
 * Digital signature creation and verification with modern interfaces
 * Status reporting and monitoring with structured return types
 * Fully async/await-based API with Result return types for detailed error handling

 ## Protocol Inheritance

 This protocol inherits from XPCServiceProtocolStandard and adds additional
 functionality. Services implement this protocol when they need to provide
 the full suite of cryptographic capabilities.
 */

/// The most comprehensive XPC service protocol that provides a complete suite
/// of cryptographic operations and security functionality. This protocol builds
/// upon the standard protocol to offer advanced features for sophisticated
/// security needs.
///
/// Services that implement this protocol provide the full range of cryptographic
/// capabilities including encryption, decryption, key generation, digital
/// signatures, and secure storage.
public protocol XPCServiceProtocolComplete: XPCServiceProtocolStandard {
  /// Ping the service with an asynchronous Result response that supports
  /// detailed errors.
  /// - Returns: Success with a boolean indicating service health, or error
  ///   with detailed failure information.
  func pingAsync() async -> Result<Bool, UmbraErrors.Security.Protocols>

  /// Get diagnostic information about the service
  /// - Returns: Result with diagnostic string on success or
  /// UmbraErrors.Security.Protocols on failure
  func getDiagnosticInfo() async
    -> Result<String, UmbraErrors.Security.Protocols>

  /// Get the service version
  /// - Returns: Result with version string on success or
  /// UmbraErrors.Security.Protocols on failure
  func getVersion() async -> Result<String, UmbraErrors.Security.Protocols>

  /// Get metrics about service performance
  /// - Returns: Result with metrics dictionary on success or
  /// UmbraErrors.Security.Protocols on failure
  func getMetrics() async
    -> Result<[String: Double], UmbraErrors.Security.Protocols>

  /// Get the service configuration
  /// - Returns: Result with configuration dictionary on success or
  /// UmbraErrors.Security.Protocols on failure
  func getConfiguration() async
    -> Result<[String: String], UmbraErrors.Security.Protocols>

  /// Set the service configuration
  /// - Parameter configuration: Dictionary of configuration settings
  /// - Returns: Result with boolean success indicator or
  /// UmbraErrors.Security.Protocols on failure
  func setConfiguration(_ configuration: [String: String]) async
    -> Result<Bool, UmbraErrors.Security.Protocols>

  /// Get the service's current status with detailed information
  /// - Returns: Structured status information or error details on failure
  func getServiceStatus() async
    -> Result<XPCServiceStatus, UmbraErrors.Security.Protocols>

  /// Generate a cryptographic key
  /// - Parameters:
  ///   - algorithm: String identifying the algorithm
  ///   - keySize: Size of the key in bits
  ///   - purpose: Purpose of the key (e.g., "encryption", "signing")
  /// - Returns: Result with key identifier on success or
  /// UmbraErrors.Security.Protocols on failure
  func generateKey(
    algorithm: String,
    keySize: Int,
    purpose: String
  ) async -> Result<String, UmbraErrors.Security.Protocols>

  /// Derive a key from a password
  /// - Parameters:
  ///   - password: Password to derive key from
  ///   - salt: Salt for derivation
  ///   - iterations: Number of iterations
  ///   - keySize: Size of the derived key in bits
  /// - Returns: Result with derived key as SecureBytes or
  /// UmbraErrors.Security.Protocols on failure
  func deriveKey(
    password: String,
    salt: UmbraCoreTypes.SecureBytes,
    iterations: Int,
    keySize: Int
  ) async -> Result<UmbraCoreTypes.SecureBytes, UmbraErrors.Security.Protocols>

  /// Derive a key from another key
  /// - Parameters:
  ///   - sourceKeyIdentifier: Identifier of the source key
  ///   - algorithm: Derivation algorithm to use
  ///   - keySize: Size of the derived key in bits
  /// - Returns: Result with derived key as SecureBytes or
  /// UmbraErrors.Security.Protocols on failure
  func deriveKeyFromKey(
    sourceKeyIdentifier: String,
    algorithm: String,
    keySize: Int
  ) async -> Result<UmbraCoreTypes.SecureBytes, UmbraErrors.Security.Protocols>

  /// Get a list of available key identifiers
  /// - Returns: Result with array of key identifiers or
  /// UmbraErrors.Security.Protocols on failure
  func getKeyIdentifiers() async
    -> Result<[String], UmbraErrors.Security.Protocols>

  /// Get information about a specific key
  /// - Parameter keyIdentifier: Identifier of the key
  /// - Returns: Result with key information dictionary or
  /// UmbraErrors.Security.Protocols on failure
  func getKeyInfo(keyIdentifier: String) async
    -> Result<[String: String], UmbraErrors.Security.Protocols>

  /// Delete a key from the service
  /// - Parameter keyIdentifier: Identifier of the key to delete
  /// - Returns: Result with boolean success indicator or
  /// UmbraErrors.Security.Protocols on failure
  func deleteKey(keyIdentifier: String) async
    -> Result<Bool, UmbraErrors.Security.Protocols>

  /// Encrypt data with authenticated encryption
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - keyIdentifier: Identifier for the key to use
  ///   - associatedData: Optional associated data for authentication
  /// - Returns: Result with encrypted data as SecureBytes or
  /// UmbraErrors.Security.Protocols on failure
  func encryptAuthenticated(
    data: UmbraCoreTypes.SecureBytes,
    keyIdentifier: String,
    associatedData: UmbraCoreTypes.SecureBytes?
  ) async -> Result<UmbraCoreTypes.SecureBytes, UmbraErrors.Security.Protocols>

  /// Decrypt data with authenticated verification
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - keyIdentifier: Identifier for the key to use
  ///   - associatedData: Optional associated data for authentication
  /// - Returns: Result with decrypted data as SecureBytes or
  /// UmbraErrors.Security.Protocols on failure
  func decryptAuthenticated(
    data: UmbraCoreTypes.SecureBytes,
    keyIdentifier: String,
    associatedData: UmbraCoreTypes.SecureBytes?
  ) async -> Result<UmbraCoreTypes.SecureBytes, UmbraErrors.Security.Protocols>

  /// Generate a digital signature of data using a private key
  /// - Parameters:
  ///   - data: Data to sign
  ///   - keyIdentifier: Identifier for the signing key
  ///   - algorithm: Algorithm to use
  /// - Returns: Result with signature as SecureBytes or
  /// UmbraErrors.Security.Protocols on failure
  func generateSignature(
    data: UmbraCoreTypes.SecureBytes,
    keyIdentifier: String,
    algorithm: String
  ) async -> Result<UmbraCoreTypes.SecureBytes, UmbraErrors.Security.Protocols>

  /// Verify a digital signature
  /// - Parameters:
  ///   - signature: Signature to verify
  ///   - data: Original data that was signed
  ///   - keyIdentifier: Identifier for the verification key
  ///   - algorithm: Algorithm to use
  /// - Returns: Result with boolean verification result or
  /// UmbraErrors.Security.Protocols on failure
  func verifySignature(
    signature: UmbraCoreTypes.SecureBytes,
    data: UmbraCoreTypes.SecureBytes,
    keyIdentifier: String,
    algorithm: String
  ) async -> Result<Bool, UmbraErrors.Security.Protocols>

  /// Create a secure backup of keys
  /// - Parameter password: Password to encrypt the backup
  /// - Returns: Result with backup data as SecureBytes or
  /// UmbraErrors.Security.Protocols on failure
  func createSecureBackup(password: String) async
    -> Result<UmbraCoreTypes.SecureBytes, UmbraErrors.Security.Protocols>

  /// Restore from a secure backup
  /// - Parameters:
  ///   - backup: Backup data
  ///   - password: Password to decrypt the backup
  /// - Returns: Result with boolean success indicator or
  /// UmbraErrors.Security.Protocols on failure
  func restoreFromSecureBackup(
    backup: UmbraCoreTypes.SecureBytes,
    password: String
  ) async -> Result<Bool, UmbraErrors.Security.Protocols>

  /// Reset the service to initial state
  /// - Returns: Result with boolean success indicator or
  /// UmbraErrors.Security.Protocols on failure
  func resetService() async -> Result<Bool, UmbraErrors.Security.Protocols>
}

/// Default implementations for the complete XPC service protocol
extension XPCServiceProtocolComplete {
  /// Default protocol identifier for the complete protocol.
  public static var protocolIdentifier: String {
    "com.umbra.xpc.service.complete"
  }

  /// Default implementation for ping with async error handling
  public func pingAsync() async
  -> Result<Bool, UmbraErrors.Security.Protocols> {
    let pingResult=await ping()
    return .success(pingResult)
  }

  /// Default implementation for diagnostics
  public func getDiagnosticInfo() async
  -> Result<String, UmbraErrors.Security.Protocols> {
    .failure(.notImplemented("Diagnostics not implemented"))
  }

  /// Default implementation for version
  public func getVersion() async
  -> Result<String, UmbraErrors.Security.Protocols> {
    .failure(.notImplemented("Version reporting not implemented"))
  }

  /// Default implementation for metrics
  public func getMetrics() async
  -> Result<[String: Double], UmbraErrors.Security.Protocols> {
    .failure(.notImplemented("Metrics not implemented"))
  }

  /// Default implementation for configuration retrieval
  public func getConfiguration() async
  -> Result<[String: String], UmbraErrors.Security.Protocols> {
    .failure(.notImplemented("Configuration access not implemented"))
  }

  /// Default implementation for configuration setting
  public func setConfiguration(_: [String: String]) async
  -> Result<Bool, UmbraErrors.Security.Protocols> {
    .failure(.notImplemented("Configuration setting not implemented"))
  }

  /// Default implementation for status
  public func getServiceStatus() async
  -> Result<XPCServiceStatus, UmbraErrors.Security.Protocols> {
    .failure(.notImplemented("Status reporting not implemented"))
  }

  /// Default implementation for key generation
  public func generateKey(
    algorithm _: String,
    keySize _: Int,
    purpose _: String
  ) async -> Result<String, UmbraErrors.Security.Protocols> {
    .failure(.notImplemented("Key generation not implemented"))
  }

  /// Default implementation for password-based key derivation
  public func deriveKey(
    password _: String,
    salt _: UmbraCoreTypes.SecureBytes,
    iterations _: Int,
    keySize _: Int
  ) async
  -> Result<UmbraCoreTypes.SecureBytes, UmbraErrors.Security.Protocols> {
    .failure(.notImplemented("Password-based key derivation not implemented"))
  }

  /// Default implementation for key-based key derivation
  public func deriveKeyFromKey(
    sourceKeyIdentifier _: String,
    algorithm _: String,
    keySize _: Int
  ) async
  -> Result<UmbraCoreTypes.SecureBytes, UmbraErrors.Security.Protocols> {
    .failure(.notImplemented("Key-based derivation not implemented"))
  }

  /// Default implementation for key listing
  public func getKeyIdentifiers() async
  -> Result<[String], UmbraErrors.Security.Protocols> {
    .failure(.notImplemented("Key listing not implemented"))
  }

  /// Default implementation for key info
  public func getKeyInfo(keyIdentifier _: String) async
  -> Result<[String: String], UmbraErrors.Security.Protocols> {
    .failure(.notImplemented("Key information not implemented"))
  }

  /// Default implementation for key deletion
  public func deleteKey(keyIdentifier _: String) async
  -> Result<Bool, UmbraErrors.Security.Protocols> {
    .failure(.notImplemented("Key deletion not implemented"))
  }

  /// Default implementation for authenticated encryption
  public func encryptAuthenticated(
    data _: UmbraCoreTypes.SecureBytes,
    keyIdentifier _: String,
    associatedData _: UmbraCoreTypes.SecureBytes?
  ) async
  -> Result<UmbraCoreTypes.SecureBytes, UmbraErrors.Security.Protocols> {
    .failure(.notImplemented("Authenticated encryption not implemented"))
  }

  /// Default implementation for authenticated decryption
  public func decryptAuthenticated(
    data _: UmbraCoreTypes.SecureBytes,
    keyIdentifier _: String,
    associatedData _: UmbraCoreTypes.SecureBytes?
  ) async
  -> Result<UmbraCoreTypes.SecureBytes, UmbraErrors.Security.Protocols> {
    .failure(.notImplemented("Authenticated decryption not implemented"))
  }

  /// Default implementation for signature generation
  public func generateSignature(
    data _: UmbraCoreTypes.SecureBytes,
    keyIdentifier _: String,
    algorithm _: String
  ) async
  -> Result<UmbraCoreTypes.SecureBytes, UmbraErrors.Security.Protocols> {
    .failure(.notImplemented("Signature generation not implemented"))
  }

  /// Default implementation for signature verification
  public func verifySignature(
    signature _: UmbraCoreTypes.SecureBytes,
    data _: UmbraCoreTypes.SecureBytes,
    keyIdentifier _: String,
    algorithm _: String
  ) async -> Result<Bool, UmbraErrors.Security.Protocols> {
    .failure(.notImplemented("Signature verification not implemented"))
  }

  /// Default implementation for secure backup
  public func createSecureBackup(password _: String) async
  -> Result<UmbraCoreTypes.SecureBytes, UmbraErrors.Security.Protocols> {
    .failure(.notImplemented("Secure backup not implemented"))
  }

  /// Default implementation for backup restoration
  public func restoreFromSecureBackup(
    backup _: UmbraCoreTypes.SecureBytes,
    password _: String
  ) async -> Result<Bool, UmbraErrors.Security.Protocols> {
    .failure(.notImplemented("Backup restoration not implemented"))
  }

  /// Default implementation for service reset
  public func resetService() async
  -> Result<Bool, UmbraErrors.Security.Protocols> {
    .failure(.notImplemented("Service reset not implemented"))
  }

  /// Default implementation for export key without format specification
  public func exportKey(keyIdentifier _: String) async
  -> Result<UmbraCoreTypes.SecureBytes, UmbraErrors.Security.Protocols> {
    // Provide a simple default implementation that returns not implemented
    // Instead of calling the format-specific version which could cause infinite recursion
    .failure(.notImplemented("Key export not implemented"))
  }
}
