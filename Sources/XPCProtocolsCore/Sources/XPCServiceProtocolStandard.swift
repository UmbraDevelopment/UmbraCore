import Foundation
import UmbraCoreTypes
import UmbraErrors
import UmbraErrorsCore

/**
 # Standard XPC Service Protocol
 
 Defines the standard XPC service protocol for cryptographic and security operations.
 This protocol extends the basic protocol with more comprehensive operations
 and error handling capabilities.
 */

/// Standard XPC service protocol for security and cryptographic operations
public protocol XPCServiceProtocolStandard: XPCServiceProtocolBasic {
  /// Generate random data of specified length
  /// - Parameter length: Length in bytes of random data to generate
  /// - Returns: Result with SecureBytes on success or SecurityError on failure
  func generateRandomData(length: Int) async
    -> Result<UmbraCoreTypes.SecureBytes, UmbraErrors.SecurityError>

  /// Encrypt data using the service's encryption mechanism
  /// - Parameters:
  ///   - data: SecureBytes to encrypt
  ///   - keyIdentifier: Optional identifier for the key to use
  /// - Returns: Result with encrypted SecureBytes on success or SecurityError on failure
  func encryptSecureData(_ data: UmbraCoreTypes.SecureBytes, keyIdentifier: String?) async
    -> Result<UmbraCoreTypes.SecureBytes, UmbraErrors.SecurityError>

  /// Decrypt data using the service's decryption mechanism
  /// - Parameters:
  ///   - data: SecureBytes to decrypt
  ///   - keyIdentifier: Optional identifier for the key to use
  /// - Returns: Result with decrypted SecureBytes on success or SecurityError on failure
  func decryptSecureData(_ data: UmbraCoreTypes.SecureBytes, keyIdentifier: String?) async
    -> Result<UmbraCoreTypes.SecureBytes, UmbraErrors.SecurityError>

  /// Sign data using the service's signing mechanism
  /// - Parameters:
  ///   - data: SecureBytes to sign
  ///   - keyIdentifier: Identifier for the signing key
  /// - Returns: Result with signature as SecureBytes on success or SecurityError on failure
  func sign(_ data: UmbraCoreTypes.SecureBytes, keyIdentifier: String) async
    -> Result<UmbraCoreTypes.SecureBytes, UmbraErrors.SecurityError>

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
  ) async -> Result<Bool, UmbraErrors.SecurityError>

  /// Standard protocol ping - extends basic ping with better error handling
  /// - Returns: Result with boolean indicating service status or SecurityError on failure
  func pingStandard() async -> Result<Bool, UmbraErrors.SecurityError>

  /// Reset the security state of the service
  /// - Returns: Result with void on success or SecurityError on failure
  func resetSecurity() async -> Result<Void, UmbraErrors.SecurityError>

  /// Get the service version
  /// - Returns: Result with version string on success or SecurityError on failure
  func getServiceVersion() async
    -> Result<String, UmbraErrors.SecurityError>

  /// Get the hardware identifier
  /// - Returns: Result with identifier string on success or SecurityError on failure
  func getHardwareIdentifier() async
    -> Result<String, UmbraErrors.SecurityError>

  /// Get the service status
  /// - Returns: Result with status dictionary on success or SecurityError on failure
  func status() async -> Result<[String: Any], UmbraErrors.SecurityError>
}

/// Default implementations for the standard protocol methods
extension XPCServiceProtocolStandard {
  /// Default protocol identifier for the standard protocol.
  public static var protocolIdentifier: String {
    "com.umbra.xpc.service.standard"
  }

  /// Default implementation forwards to the basic ping
  public func pingStandard() async
  -> Result<Bool, UmbraErrors.SecurityError> {
    // Simple implementation that doesn't throw
    let pingResult=await ping()
    return .success(pingResult)
  }

  /// Default service status implementation
  public func status() async
  -> Result<[String: Any], UmbraErrors.SecurityError> {
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
  -> Result<UmbraCoreTypes.SecureBytes, UmbraErrors.SecurityError> {
    await encryptSecureData(data, keyIdentifier: nil)
  }

  /// Decrypt data with default implementation
  public func decrypt(
    data: UmbraCoreTypes
      .SecureBytes
  ) async
  -> Result<UmbraCoreTypes.SecureBytes, UmbraErrors.SecurityError> {
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
