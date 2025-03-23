import CoreErrors
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
 # Standard XPC Service Protocol

 This file defines the standard protocol for XPC services in UmbraCore, building upon the basic
 protocol to provide more comprehensive cryptographic and security functionality.

 ## Features

 * Extends the basic XPC service protocol with cryptographic functions
 * Support for encryption, decryption, and key management
 * Status reporting and health checking capabilities
 * Support for modern SecureBytes for better memory safety and security

 ## Protocol Inheritance

 This protocol inherits from XPCServiceProtocolBasic and adds additional functionality.
 Services can choose to implement this protocol if they need to provide standard
 cryptographic capabilities.
 */

/// Protocol defining a standard set of cryptographic operations for XPC services
public protocol XPCServiceProtocolStandard: XPCServiceProtocolBasic {
  /// Generate random data of specified length
  /// - Parameter length: Length in bytes of random data to generate
  /// - Returns: Result with SecureBytes on success or SecurityError on failure
  func generateRandomData(length: Int) async
    -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols>

  /// Encrypt data using the service's encryption mechanism
  /// - Parameters:
  ///   - data: SecureBytes to encrypt
  ///   - keyIdentifier: Optional identifier for the key to use
  /// - Returns: Result with encrypted SecureBytes on success or SecurityError on failure
  func encryptSecureData(_ data: UmbraCoreTypes.SecureBytes, keyIdentifier: String?) async
    -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols>

  /// Decrypt data using the service's decryption mechanism
  /// - Parameters:
  ///   - data: SecureBytes to decrypt
  ///   - keyIdentifier: Optional identifier for the key to use
  /// - Returns: Result with decrypted SecureBytes on success or SecurityError on failure
  func decryptSecureData(_ data: UmbraCoreTypes.SecureBytes, keyIdentifier: String?) async
    -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols>

  /// Sign data using the service's signing mechanism
  /// - Parameters:
  ///   - data: SecureBytes to sign
  ///   - keyIdentifier: Identifier for the signing key
  /// - Returns: Result with signature as SecureBytes on success or SecurityError on failure
  func sign(_ data: UmbraCoreTypes.SecureBytes, keyIdentifier: String) async
    -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols>

  /// Verify signature for data
  /// - Parameters:
  ///   - signature: SecureBytes containing the signature to verify
  ///   - data: SecureBytes containing the data to verify
  ///   - keyIdentifier: Identifier for the verification key
  /// - Returns: Result with boolean indicating verification result or SecurityError on failure
  func verify(
    signature: UmbraCoreTypes.SecureBytes,
    for data: UmbraCoreTypes.SecureBytes,
    keyIdentifier: String
  ) async -> Result<Bool, ErrorHandlingDomains.UmbraErrors.Security.Protocols>

  /// Standard protocol ping - extends basic ping with better error handling
  /// - Returns: Result with boolean indicating service status or SecurityError on failure
  func pingStandard() async -> Result<Bool, ErrorHandlingDomains.UmbraErrors.Security.Protocols>

  /// Reset the security state of the service
  /// - Returns: Result with void on success or SecurityError on failure
  func resetSecurity() async -> Result<Void, ErrorHandlingDomains.UmbraErrors.Security.Protocols>

  /// Get the service version
  /// - Returns: Result with version string on success or SecurityError on failure
  func getServiceVersion() async
    -> Result<String, ErrorHandlingDomains.UmbraErrors.Security.Protocols>

  /// Get the hardware identifier
  /// - Returns: Result with identifier string on success or SecurityError on failure
  func getHardwareIdentifier() async
    -> Result<String, ErrorHandlingDomains.UmbraErrors.Security.Protocols>

  /// Get the service status
  /// - Returns: Result with status dictionary on success or SecurityError on failure
  func status() async -> Result<[String: Any], ErrorHandlingDomains.UmbraErrors.Security.Protocols>
}

/// Default implementations for the standard protocol methods
extension XPCServiceProtocolStandard {
  /// Default protocol identifier for the standard protocol.
  public static var protocolIdentifier: String {
    "com.umbra.xpc.service.standard"
  }

  /// Default implementation forwards to the basic ping
  public func pingStandard() async
  -> Result<Bool, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    // Simple implementation that doesn't throw
    let pingResult=await ping()
    return .success(pingResult)
  }

  /// Default service status implementation
  public func status() async
  -> Result<[String: Any], ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    let versionResult=await getServiceVersion()

    var statusDict: [String: Any]=[
      "timestamp": Date().timeIntervalSince1970,
      "protocol": Self.protocolIdentifier
    ]

    if case let .success(version)=versionResult {
      statusDict["version"]=version
    }

    return .success(statusDict)
  }

  /// Encrypt data with default implementation
  public func encrypt(
    data: UmbraCoreTypes
      .SecureBytes
  ) async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    await encryptSecureData(data, keyIdentifier: nil)
  }

  /// Decrypt data with default implementation
  public func decrypt(
    data: UmbraCoreTypes
      .SecureBytes
  ) async
  -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    await decryptSecureData(data, keyIdentifier: nil)
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
  ) async -> Result<String, ErrorHandlingDomains.UmbraErrors.Security.Protocols>

  /// Delete a key
  /// - Parameter keyIdentifier: Identifier for the key to delete
  /// - Returns: Result with void on success or SecurityError on failure
  func deleteKey(keyIdentifier: String) async
    -> Result<Void, ErrorHandlingDomains.UmbraErrors.Security.Protocols>

  /// List all keys
  /// - Returns: Result with array of key identifiers on success or SecurityError on failure
  func listKeys() async -> Result<[String], ErrorHandlingDomains.UmbraErrors.Security.Protocols>

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
  ) async -> Result<String, ErrorHandlingDomains.UmbraErrors.Security.Protocols>

  /// Export a key
  /// - Parameters:
  ///   - keyIdentifier: Identifier for the key to export
  ///   - format: Format to export the key in
  /// - Returns: Result with key data as SecureBytes on success or SecurityError on failure
  func exportKey(
    keyIdentifier: String,
    format: XPCProtocolTypeDefs.KeyFormat
  ) async -> Result<UmbraCoreTypes.SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols>
}
