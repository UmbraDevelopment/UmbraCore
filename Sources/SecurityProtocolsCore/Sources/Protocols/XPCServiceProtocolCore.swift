import Errors
import UmbraCoreTypes
import UmbraErrors
import UmbraErrorsCore

/// Protocol defining core XPC service functionality without Foundation dependencies.
/// This protocol uses SecureBytes for binary data to avoid custom type definitions
/// and ensure compatibility with the rest of the security architecture.
public protocol XPCServiceProtocolCore: Sendable {
  /// Protocol identifier used for service discovery and protocol negotiation
  static var protocolIdentifier: String { get }

  /// Test connectivity with the XPC service
  /// - Returns: Boolean indicating whether the service is responsive
  func ping() async -> Result<Bool, Errors.SecurityProtocolError>

  /// Synchronise encryption keys across processes
  /// - Parameter syncData: Key synchronisation data
  /// - Returns: Success or a descriptive error
  func synchronizeKeys(_ syncData: SecureBytes) async
    -> Result<Void, Errors.SecurityProtocolError>

  /// Encrypt data using a service-managed key
  /// - Parameter data: Data to encrypt
  /// - Returns: Encrypted data or an error
  func encrypt(data: SecureBytes) async
    -> Result<SecureBytes, Errors.SecurityProtocolError>

  /// Decrypt data using a service-managed key
  /// - Parameter data: Data to decrypt
  /// - Returns: Decrypted data or an error
  func decrypt(data: SecureBytes) async
    -> Result<SecureBytes, Errors.SecurityProtocolError>

  /// Generate a new cryptographic key
  /// - Returns: Generated key or an error
  func generateKey() async -> Result<SecureBytes, Errors.SecurityProtocolError>

  /// Compute a cryptographic hash of data
  /// - Parameter data: Data to hash
  /// - Returns: Hash value or an error
  func hash(data: SecureBytes) async
    -> Result<SecureBytes, Errors.SecurityProtocolError>
}

/// Default implementations for XPCServiceProtocolCore functions
extension XPCServiceProtocolCore {
  /// Default protocol identifier
  public static var protocolIdentifier: String {
    "com.umbra.xpc.service.protocol.core"
  }

  /// Default ping implementation
  public func ping() async -> Result<Bool, Errors.SecurityProtocolError> {
    .success(true)
  }

  /// Default key synchronisation implementation that does nothing
  public func synchronizeKeys(_: SecureBytes) async
  -> Result<Void, Errors.SecurityProtocolError> {
    .success(())
  }

  /// Default encryption implementation
  public func encrypt(data _: SecureBytes) async
  -> Result<SecureBytes, Errors.SecurityProtocolError> {
    .failure(.unsupportedOperation(name: "encrypt"))
  }

  /// Default decryption implementation
  public func decrypt(data _: SecureBytes) async
  -> Result<SecureBytes, Errors.SecurityProtocolError> {
    .failure(.unsupportedOperation(name: "decrypt"))
  }

  /// Default key generation implementation
  public func generateKey() async -> Result<SecureBytes, Errors.SecurityProtocolError> {
    .failure(.unsupportedOperation(name: "generateKey"))
  }

  /// Default hashing implementation
  public func hash(data _: SecureBytes) async
  -> Result<SecureBytes, Errors.SecurityProtocolError> {
    .failure(.unsupportedOperation(name: "hash"))
  }
}
