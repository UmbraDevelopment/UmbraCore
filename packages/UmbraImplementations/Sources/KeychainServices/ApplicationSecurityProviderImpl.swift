import CoreInterfaces
import Foundation
import LoggingInterfaces
import SecurityCoreTypes
import SecurityTypes

/**
 # Application Security Provider Implementation

 Provides implementations of security-related services for the KeychainServices module.
 This implementation follows the Alpha Dot Five architecture's provider-based abstraction
 pattern, enabling different security implementations while maintaining a consistent interface.
 */
public enum ApplicationSecurityFactory {
  /**
   Creates a security provider for application use.

   - Parameter logger: Optional logging service to use
   - Returns: A security provider implementation
   */
  public static func createApplicationSecurityProvider(
    logger: (any LoggingServiceProtocol)?
  ) async -> any ApplicationSecurityProviderProtocol {
    // Create a key manager adapter
    let keyManager=await MockKeyManagerFactory.shared.createKeyManager()

    // Use default logger if none provided
    let loggerAdapter=logger != nil ? LoggingAdapter(wrapping: logger!) : DefaultLogger()

    // Return a mock implementation for now - this should be replaced with a proper implementation
    // as part of the Alpha Dot Five architecture migration
    return MockSecurityProvider(
      logger: loggerAdapter,
      keyManager: keyManager
    )
  }

  /**
   Creates a standard security provider (alias for createApplicationSecurityProvider).

   - Parameter logger: Optional logging service to use
   - Returns: A security provider implementation
   */
  public static func createSecurityProvider(
    logger: (any LoggingServiceProtocol)?
  ) async -> any ApplicationSecurityProviderProtocol {
    await createApplicationSecurityProvider(logger: logger)
  }
}

/**
 # Key Management Protocol

 Interface for key management operations
 */
public protocol KeyManagementProtocol: Sendable {
  // Key generation
  func generateKey(with config: KeyGenerationConfig) async throws -> KeyGenerationResult

  // Key retrieval - returns a Result with either the retrieved key or an error
  func retrieveKey(withIdentifier keyID: String) async -> Result<SecureBytes, SecurityProtocolError>

  // Key storage - returns a Result indicating success or failure
  func storeKey(_ key: SecureBytes, withIdentifier keyID: String) async
    -> Result<Void, SecurityProtocolError>

  // Key deletion - returns a Result indicating success or failure
  func deleteKey(withIdentifier keyID: String) async -> Result<Void, SecurityProtocolError>

  // Key listing - returns a Result with either a list of key identifiers or an error
  func listKeyIdentifiers() async -> Result<[String], SecurityProtocolError>
}

/**
 # Security Protocol Error

 Error type for security protocol operations
 */
public enum SecurityProtocolError: Error, Equatable {
  case unsupportedOperation(name: String)
  case keyNotFound(identifier: String)
  case keyGenerationFailed(reason: String)
  case encryptionFailed(reason: String)
  case decryptionFailed(reason: String)
  case invalidKey(reason: String)
  case invalidData(reason: String)
  case accessDenied(reason: String)
  case systemError(code: Int, description: String)
  case unexpectedError(description: String)
}

/**
 # Secure Bytes

 A secure container for sensitive data. This provides additional memory security
 and ensures sensitive data is zeroed out when no longer needed.
 */
public struct SecureBytes: Equatable, Sendable {
  // The underlying data
  private let data: Data

  // Create a new SecureBytes instance
  public init(_ data: Data) {
    self.data=data
  }

  // Get the underlying data - use with caution
  public var rawData: Data {
    data
  }
}

/**
 # Mock Key Manager Factory

 Factory for creating mock key management implementations for testing.
 */
public final class MockKeyManagerFactory: @unchecked Sendable {
  /// Shared instance
  public static let shared=MockKeyManagerFactory()

  private init() {}

  /// Creates a key manager implementation
  public func createKeyManager() async -> any KeyManagementProtocol {
    MockKeyManager()
  }
}

/**
 # Mock Key Manager

 Basic implementation of KeyManagementProtocol for testing purposes
 */
private final class MockKeyManager: KeyManagementProtocol {
  public func generateKey(with config: KeyGenerationConfig) async throws -> KeyGenerationResult {
    KeyGenerationResult(
      keyIdentifier: "mock-key-\(UUID().uuidString)",
      algorithm: config.algorithm,
      metadata: config.metadata
    )
  }

  public func retrieveKey(withIdentifier _: String) async
  -> Result<SecureBytes, SecurityProtocolError> {
    .failure(.unsupportedOperation(name: "Mock implementation does not support key retrieval"))
  }

  public func storeKey(
    _: SecureBytes,
    withIdentifier _: String
  ) async -> Result<Void, SecurityProtocolError> {
    .failure(.unsupportedOperation(name: "Mock implementation does not support key storage"))
  }

  public func deleteKey(withIdentifier _: String) async -> Result<Void, SecurityProtocolError> {
    .failure(.unsupportedOperation(name: "Mock implementation does not support key deletion"))
  }

  public func listKeyIdentifiers() async -> Result<[String], SecurityProtocolError> {
    .failure(.unsupportedOperation(name: "Mock implementation does not support listing keys"))
  }
}

/**
 # Encryption Config

 Configuration for encryption operations
 */
public struct EncryptionConfig: Sendable, Hashable {
  public let keyIdentifier: String?
  public let algorithm: EncryptionAlgorithm

  public init(keyIdentifier: String?=nil, algorithm: EncryptionAlgorithm = .aes256gcm) {
    self.keyIdentifier=keyIdentifier
    self.algorithm=algorithm
  }
}

/**
 # Encryption Algorithm

 Supported encryption algorithms
 */
public enum EncryptionAlgorithm: String, Sendable, Codable, Hashable, CaseIterable {
  case aes256gcm
  case aes256cbc
  case aes256
  case chaCha20Poly1305
}

/**
 # Signing Config

 Configuration for digital signature operations
 */
public struct SigningConfig: Sendable, Hashable {
  public let keyIdentifier: String?
  public let algorithm: SigningAlgorithm

  public init(keyIdentifier: String?=nil, algorithm: SigningAlgorithm = .ecdsaP256) {
    self.keyIdentifier=keyIdentifier
    self.algorithm=algorithm
  }
}

/**
 # Signing Algorithm

 Supported digital signature algorithms
 */
public enum SigningAlgorithm: String, Sendable, Codable, Hashable, CaseIterable {
  case ecdsaP256
  case ecdsaP384
  case ed25519
  case hmacSHA256
}

/**
 # Hashing Config

 Configuration for hashing operations
 */
public struct HashingConfig: Sendable, Hashable {
  public let algorithm: HashAlgorithm

  public init(algorithm: HashAlgorithm = .sha256) {
    self.algorithm=algorithm
  }
}

/**
 # Hash Algorithm

 Supported hash algorithms
 */
public enum HashAlgorithm: String, Sendable, Codable, Hashable, CaseIterable {
  case sha256
  case sha384
  case sha512
  case blake2b
}

/**
 # Key Generation Config

 Configuration for key generation operations
 */
public struct KeyGenerationConfig: Sendable, Hashable {
  public let algorithm: KeyAlgorithm
  public let usage: KeyUsage
  public let metadata: [String: String]

  public init(
    algorithm: KeyAlgorithm = .aes256,
    usage: KeyUsage = .encryptionAndDecryption,
    metadata: [String: String]=[:]
  ) {
    self.algorithm=algorithm
    self.usage=usage
    self.metadata=metadata
  }
}

/**
 # Key Algorithm

 Supported key algorithms
 */
public enum KeyAlgorithm: String, Sendable, Codable, Hashable, CaseIterable {
  case aes256
  case ecdsaP256
  case ecdsaP384
  case ed25519
}

/**
 # Key Usage

 Supported key usage flags
 */
public struct KeyUsage: OptionSet, Sendable, Codable, Hashable {
  public let rawValue: UInt

  public init(rawValue: UInt) {
    self.rawValue=rawValue
  }

  public static let encryption=KeyUsage(rawValue: 1 << 0)
  public static let decryption=KeyUsage(rawValue: 1 << 1)
  public static let signing=KeyUsage(rawValue: 1 << 2)
  public static let verification=KeyUsage(rawValue: 1 << 3)

  public static let encryptionAndDecryption: KeyUsage=[.encryption, .decryption]
  public static let signingAndVerification: KeyUsage=[.signing, .verification]
}

/**
 # Encryption Result

 Result of an encryption operation
 */
public struct EncryptionResult: Sendable, Hashable {
  public let ciphertext: Data
  public let keyIdentifier: String
  public let algorithm: EncryptionAlgorithm
  public let metadata: [String: String]

  public init(
    ciphertext: Data,
    keyIdentifier: String,
    algorithm: EncryptionAlgorithm,
    metadata: [String: String]
  ) {
    self.ciphertext=ciphertext
    self.keyIdentifier=keyIdentifier
    self.algorithm=algorithm
    self.metadata=metadata
  }
}

/**
 # Decryption Result

 Result of a decryption operation
 */
public struct DecryptionResult: Sendable, Hashable {
  public let plaintext: Data
  public let algorithm: EncryptionAlgorithm
  public let metadata: [String: String]

  public init(
    plaintext: Data,
    algorithm: EncryptionAlgorithm,
    metadata: [String: String]
  ) {
    self.plaintext=plaintext
    self.algorithm=algorithm
    self.metadata=metadata
  }
}

/**
 # Hash Result

 Result of a hashing operation
 */
public struct HashResult: Sendable, Hashable {
  public let digest: Data
  public let algorithm: HashAlgorithm

  public init(digest: Data, algorithm: HashAlgorithm) {
    self.digest=digest
    self.algorithm=algorithm
  }
}

/**
 # Signature Result

 Result of a signing operation
 */
public struct SignatureResult: Sendable, Hashable {
  public let signature: Data
  public let algorithm: SigningAlgorithm
  public let keyIdentifier: String

  public init(
    signature: Data,
    algorithm: SigningAlgorithm,
    keyIdentifier: String
  ) {
    self.signature=signature
    self.algorithm=algorithm
    self.keyIdentifier=keyIdentifier
  }
}

/**
 # Key Generation Result

 Result of a key generation operation
 */
public struct KeyGenerationResult: Sendable, Hashable {
  public let keyIdentifier: String
  public let algorithm: KeyAlgorithm
  public let metadata: [String: String]

  public init(
    keyIdentifier: String,
    algorithm: KeyAlgorithm,
    metadata: [String: String]
  ) {
    self.keyIdentifier=keyIdentifier
    self.algorithm=algorithm
    self.metadata=metadata
  }
}

/**
 Application Security Provider Protocol

 The primary interface for accessing all security-related
 functionality in UmbraCore applications. Serves as the main entry point for the security subsystem,
 coordinating cryptographic operations, key management, and secure storage.
 */
public protocol ApplicationSecurityProviderProtocol: Sendable {
  /// Access to the cryptographic service implementation
  var cryptoService: any ApplicationCryptoServiceProtocol { get }

  /// Access to the key management service implementation
  var keyManager: any KeyManagementProtocol { get }

  /// Access to the secure storage service implementation
  var secureStorage: any SecureStorageProtocol { get }

  /// Encrypts data using the specified configuration
  func encrypt(data: Data, with config: EncryptionConfig) async throws -> EncryptionResult

  /// Decrypts data using the specified configuration
  func decrypt(data: Data, with config: EncryptionConfig) async throws -> DecryptionResult

  /// Signs data using the specified configuration
  func sign(data: Data, with config: SigningConfig) async throws -> SignatureResult

  /// Verifies a signature for the given data
  func verify(
    signature: Data,
    for data: Data,
    with config: SigningConfig
  ) async throws -> Bool

  /// Generates a new key with the specified configuration
  func generateKey(
    with config: KeyGenerationConfig
  ) async throws -> KeyGenerationResult
}

/**
 Application Crypto Service Protocol

 Interface for cryptographic operations in UmbraCore applications.
 */
public protocol ApplicationCryptoServiceProtocol: Sendable {
  /// Encrypts data using the specified configuration
  func encrypt(data: Data, with config: EncryptionConfig) async throws -> EncryptionResult

  /// Decrypts data using the specified configuration
  func decrypt(data: Data, with config: EncryptionConfig) async throws -> DecryptionResult

  /// Generates a hash for the given data
  func hash(data: Data, with config: HashingConfig) async throws -> HashResult

  /// Signs data using the specified configuration
  func sign(data: Data, with config: SigningConfig) async throws -> SignatureResult

  /// Verifies a signature for the given data
  func verify(
    signature: Data,
    for data: Data,
    with config: SigningConfig
  ) async throws -> Bool

  /// Generates a new key with the specified configuration
  func generateKey(
    with config: KeyGenerationConfig
  ) async throws -> KeyGenerationResult
}

/**
 # Secure Storage Protocol

 Interface for securely storing and retrieving sensitive data.
 */
public protocol SecureStorageProtocol: Sendable {
  /// Store a password securely
  func storePassword(_ password: String, for account: String) async throws

  /// Retrieve a password
  func retrievePassword(for account: String) async throws -> String

  /// Delete a password
  func deletePassword(for account: String) async throws

  /// Check if a password exists
  func passwordExists(for account: String) async -> Bool
}

/**
 # Log Metadata

 Type alias for log metadata dictionary
 */
public typealias LogMetadata=[String: String]

/**
 Mock implementation of ApplicationSecurityProviderProtocol for testing and development.
 This provides a basic implementation that delegates to real services where possible,
 and returns placeholder implementations where necessary.
 */
private final class MockSecurityProvider: ApplicationSecurityProviderProtocol {
  private let logger: any LoggingProtocol
  private let keyMgr: any KeyManagementProtocol

  init(logger: any LoggingProtocol, keyManager: any KeyManagementProtocol) {
    self.logger=logger
    keyMgr=keyManager
  }

  public var keyManager: any KeyManagementProtocol {
    keyMgr
  }

  public var cryptoService: any ApplicationCryptoServiceProtocol {
    fatalError("Not implemented in mock provider")
  }

  public var secureStorage: any SecureStorageProtocol {
    fatalError("Not implemented in mock provider")
  }

  public func encrypt(data: Data, with _: EncryptionConfig) async throws -> EncryptionResult {
    await logger.warning(
      "Mock encryption used - not secure",
      metadata: LogMetadata(),
      source: "MockSecurityProvider"
    )
    return EncryptionResult(
      ciphertext: data,
      keyIdentifier: "mock-key-id",
      algorithm: .aes256gcm,
      metadata: [:]
    )
  }

  public func decrypt(data: Data, with _: EncryptionConfig) async throws -> DecryptionResult {
    await logger.warning(
      "Mock decryption used - not secure",
      metadata: LogMetadata(),
      source: "MockSecurityProvider"
    )
    return DecryptionResult(
      plaintext: data,
      algorithm: .aes256gcm,
      metadata: [:]
    )
  }

  public func sign(data: Data, with _: SigningConfig) async throws -> SignatureResult {
    await logger.warning(
      "Mock signing used - not secure",
      metadata: LogMetadata(),
      source: "MockSecurityProvider"
    )
    return SignatureResult(
      signature: data,
      algorithm: .ecdsaP256,
      keyIdentifier: "mock-key-id"
    )
  }

  public func verify(
    signature _: Data,
    for _: Data,
    with _: SigningConfig
  ) async throws -> Bool {
    await logger.warning(
      "Mock signature verification used - not secure",
      metadata: LogMetadata(),
      source: "MockSecurityProvider"
    )
    return true
  }

  public func generateKey(
    with config: KeyGenerationConfig
  ) async throws -> KeyGenerationResult {
    try await keyManager.generateKey(with: config)
  }
}
