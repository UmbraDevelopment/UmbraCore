
import UmbraErrorsCore
import UmbraCoreTypes
import UmbraErrorsDomains

/// Protocol error type for XPC service operations
public enum SecurityProtocolError: Error, Equatable, Sendable {
  /// Internal error within the security system
  case internalError(String)

  /// Operation is not supported
  case unsupportedOperation(name: String)

  /// Service error with code
  case serviceError(code: Int, message: String)
}

/// Protocol defining core XPC service functionality without Foundation dependencies.
/// This protocol uses SecureBytes for binary data to avoid custom type definitions
/// and ensure compatibility with the rest of the security architecture.
public protocol XPCServiceProtocolCore: Sendable {
  /// Protocol identifier used for service discovery and protocol negotiation
  static var protocolIdentifier: String { get }

  /// Test connectivity with the XPC service
  /// - Returns: Boolean indicating whether the service is responsive
  func ping() async -> Result<Bool, SecurityProtocolError>

  /// Synchronise encryption keys across processes
  /// - Parameter syncData: Key synchronisation data
  /// - Returns: Success or a descriptive error
  func synchronizeKeys(_ syncData: SecureBytes) async
    -> Result<Void, SecurityProtocolError>

  /// Encrypt data using a service-managed key
  /// - Parameter data: Data to encrypt
  /// - Returns: Encrypted data or an error
  func encrypt(data: SecureBytes) async
    -> Result<SecureBytes, SecurityProtocolError>

  /// Decrypt data using a service-managed key
  /// - Parameter data: Data to decrypt
  /// - Returns: Decrypted data or an error
  func decrypt(data: SecureBytes) async
    -> Result<SecureBytes, SecurityProtocolError>

  /// Generate a new cryptographic key
  /// - Returns: Generated key or an error
  func generateKey() async -> Result<SecureBytes, SecurityProtocolError>

  /// Compute a cryptographic hash of data
  /// - Parameter data: Data to hash
  /// - Returns: Hash value or an error
  func hash(data: SecureBytes) async
    -> Result<SecureBytes, SecurityProtocolError>
}

/// Default implementations for XPCServiceProtocolCore functions
extension XPCServiceProtocolCore {
  /// Default protocol identifier
  public static var protocolIdentifier: String {
    "com.umbra.xpc.service.protocol.core"
  }

  /// Default implementation that returns a ping success
  public func ping() async -> Result<Bool, SecurityProtocolError> {
    .success(true)
  }

  /// Default implementation that returns a not implemented error
  public func synchronizeKeys(_: SecureBytes) async
  -> Result<Void, SecurityProtocolError> {
    .failure(.unsupportedOperation(name: "synchronizeKeys"))
  }

  /// Default implementation that returns a not implemented error
  public func encrypt(data _: SecureBytes) async
  -> Result<SecureBytes, SecurityProtocolError> {
    .failure(.unsupportedOperation(name: "encrypt"))
  }

  /// Default implementation that returns a not implemented error
  public func decrypt(data _: SecureBytes) async
  -> Result<SecureBytes, SecurityProtocolError> {
    .failure(.unsupportedOperation(name: "decrypt"))
  }

  /// Default implementation that returns a not implemented error
  public func generateKey() async -> Result<SecureBytes, SecurityProtocolError> {
    .failure(.unsupportedOperation(name: "generateKey"))
  }

  /// Default implementation that returns a not implemented error
  public func hash(data _: SecureBytes) async
  -> Result<SecureBytes, SecurityProtocolError> {
    .failure(.unsupportedOperation(name: "hash"))
  }
}
