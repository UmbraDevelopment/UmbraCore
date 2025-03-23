import CommonCrypto
import CoreDTOs
import CoreErrors
import CoreServicesTypes
import CryptoTypes
import CryptoTypesTypes
import Foundation
import KeyManagementTypes
import SecurityTypes

/// Configuration for cryptographic operations.
///
/// This struct defines the parameters used for key derivation, encryption,
/// and other cryptographic operations. Default values are chosen to provide
/// a good balance of security and performance.
/// @deprecated This will be replaced by CryptoTypesTypes.CryptoConfig in a future version.
/// New code should use CryptoTypesTypes.CryptoConfig instead.
@available(
  *,
  deprecated,
  message: "This will be replaced by CryptoTypesTypes.CryptoConfig in a future version. Use CryptoTypesTypes.CryptoConfig instead."
)
public typealias CryptoConfig = CryptoTypesTypes.CryptoConfig

// Keep existing functionality for backward compatibility
extension CryptoTypesTypes.CryptoConfig {
  /// The number of iterations for key derivation.
  ///
  /// Higher values increase security but also increase processing time.
  @available(*, deprecated, message: "Will be removed in a future version")
  public var iterations: Int {
    10_000
  }

  /// Creates a legacy crypto configuration.
  ///
  /// - Parameters:
  ///   - keySize: Key size in bits. Defaults to 256.
  ///   - ivSize: IV size in bits. Defaults to 96 (12 bytes) for AES-GCM.
  ///   - iterations: PBKDF2 iterations (ignored in modern implementation). Defaults to 10,000.
  @available(*, deprecated, message: "Use the standard initializer instead")
  public static func legacyInit(
    keySize: Int = 256,
    ivSize: Int = 96,
    iterations _: Int = 10_000
  ) -> CryptoTypesTypes.CryptoConfig {
    CryptoTypesTypes.CryptoConfig(keyLength: keySize, ivLength: ivSize / 8)
  }
}

/// The result of an encryption operation.
///
/// Contains the encrypted data, initialization vector, and authentication tag.
public struct EncryptionResult: Sendable {
  /// The encrypted data
  public let encrypted: [UInt8]

  /// The initialization vector used for encryption
  public let initializationVector: [UInt8]

  /// The authentication tag for verifying data integrity
  public let tag: [UInt8]
}

/// A service that provides cryptographic operations.
///
/// `CryptoService` handles encryption, decryption, and key derivation operations
/// in a thread-safe manner. It uses industry-standard algorithms and practices
/// to ensure data security.
/// @deprecated This will be replaced by CryptoTypesTypes.CryptoService in a future version.
/// New code should use CryptoTypesTypes.CryptoService implementation instead.
@available(
  *,
  deprecated,
  message: "This will be replaced by CryptoTypesTypes.CryptoService in a future version. Use CryptoTypesTypes.CryptoService implementation instead."
)
public actor CryptoService: UmbraService {
  /// The unique identifier for this service.
  public static let serviceIdentifier = "com.umbracore.crypto"

  /// The internal state of the service.
  private var _state: ServiceState = .uninitialized

  /// The current state of the service, accessible from any context.
  public private(set) nonisolated(unsafe) var state: ServiceState = .uninitialized

  /// The configuration for cryptographic operations.
  private let config: CryptoTypesTypes.CryptoConfig

  /// Creates a new crypto service with the specified configuration.
  ///
  /// - Parameter config: The configuration to use for cryptographic operations.
  ///                    Defaults to standard secure parameters.
  public init(config: CryptoTypesTypes.CryptoConfig = CryptoTypesTypes.CryptoConfig.default) {
    self.config = config
  }

  /// Initializes the service and validates its configuration.
  ///
  /// - Throws: `ServiceError.configurationError` if the service is already
  ///           initialized or if the configuration is invalid.
  public func initialize() async throws {
    guard _state == .uninitialized else {
      throw CoreErrors.ServiceError.configurationError
    }

    state = .initializing
    _state = .initializing

    // Validate configuration
    guard config.keyLength > 0, config.ivLength > 0 else {
      state = .error
      _state = .error
      throw CoreErrors.ServiceError.configurationError
    }

    state = .running
    _state = .running
  }

  /// Gracefully shuts down the service.
  ///
  /// - Throws: No errors are thrown by this method.
  public func shutdown() async {
    if _state == .running {
      state = .shuttingDown
      _state = .shuttingDown
      // Perform any cleanup if needed
      state = .uninitialized
      _state = .uninitialized
    }
  }

  /// Generates a random key of the configured size.
  ///
  /// - Returns: Random bytes for use as a key.
  /// - Throws: `CryptoError` if key generation fails.
  public func generateKey() throws -> [UInt8] {
    guard _state == .initializing || _state == .running else {
      throw CoreErrors.ServiceError.invalidState
    }

    var key = [UInt8](repeating: 0, count: config.keyLength)
    let status = SecRandomCopyBytes(kSecRandomDefault, key.count, &key)
    guard status == errSecSuccess else {
      throw CoreErrors.CryptoError.keyGenerationFailed
    }
    return key
  }

  /// Generates a random initialization vector.
  ///
  /// - Returns: Random bytes for use as an IV.
  /// - Throws: `CryptoError` if IV generation fails.
  public func generateIV() throws -> [UInt8] {
    guard _state == .initializing || _state == .running else {
      throw CoreErrors.ServiceError.invalidState
    }

    var iv = [UInt8](repeating: 0, count: config.ivLength)
    let status = SecRandomCopyBytes(kSecRandomDefault, iv.count, &iv)
    guard status == errSecSuccess else {
      throw CoreErrors.CryptoError.ivGenerationFailed
    }
    return iv
  }

  /// Encrypts data using AES-GCM.
  ///
  /// - Parameters:
  ///   - data: Data to encrypt.
  ///   - key: Encryption key.
  /// - Returns: Encrypted data with IV and tag.
  /// - Throws: `CryptoError` on failure.
  public func encrypt(
    _ data: [UInt8],
    using key: [UInt8]
  ) throws -> EncryptionResult {
    guard _state == .running else {
      throw CoreErrors.ServiceError.invalidState
    }

    let initializationVector = try generateIV()
    let encrypted = try encrypt(data, key: key, iv: initializationVector)
    let tag = try generateTag(data: data, key: key, iv: initializationVector)
    return EncryptionResult(
      encrypted: encrypted,
      initializationVector: initializationVector,
      tag: tag
    )
  }

  private func encrypt(_: [UInt8], key _: [UInt8], iv _: [UInt8]) throws -> [UInt8] {
    // Placeholder implementation - will be replaced by ResticBar
    throw CoreErrors.CryptoError.encryptionFailed(reason: "Not implemented")
  }

  private func generateTag(data _: [UInt8], key _: [UInt8], iv _: [UInt8]) throws -> [UInt8] {
    // Placeholder implementation - will be replaced by ResticBar
    throw CoreErrors.CryptoError.tagGenerationFailed
  }

  /// Decrypts data using AES-GCM.
  ///
  /// - Parameters:
  ///   - encryptedData: The encrypted data and associated cryptographic parameters.
  ///   - key: Decryption key.
  /// - Returns: Decrypted data.
  /// - Throws: `CryptoError` on failure.
  public func decrypt(
    _ encryptedData: EncryptionResult,
    using key: [UInt8]
  ) throws -> [UInt8] {
    guard _state == .running else {
      throw CoreErrors.ServiceError.invalidState
    }

    return try decrypt(
      encryptedData.encrypted,
      key: key,
      iv: encryptedData.initializationVector,
      tag: encryptedData.tag
    )
  }

  private func decrypt(
    _: [UInt8],
    key _: [UInt8],
    iv _: [UInt8],
    tag _: [UInt8]
  ) throws -> [UInt8] {
    // Placeholder implementation - will be replaced by ResticBar
    throw CoreErrors.CryptoError.decryptionFailed(reason: "Not implemented")
  }

  /// Derives a key from a password using PBKDF2.
  ///
  /// - Parameters:
  ///   - password: Password to derive key from.
  ///   - salt: Salt for key derivation.
  /// - Returns: Derived key.
  /// - Throws: `CryptoError` on failure.
  public func deriveKey(from _: String, salt _: [UInt8]) async throws -> [UInt8] {
    guard _state == .running else {
      throw CoreErrors.ServiceError.invalidState
    }

    // Placeholder implementation - will be replaced by ResticBar
    throw CoreErrors.CryptoError.keyDerivationFailed(reason: "Not implemented")
  }

  /// Generates secure random bytes for cryptographic operations.
  ///
  /// - Parameter length: The number of bytes to generate.
  /// - Returns: Random bytes as Data.
  /// - Throws: `CryptoError` on failure.
  public func generateSecureRandomBytes(length: Int) async throws -> Data {
    guard _state == .running else {
      throw CoreErrors.ServiceError.invalidState
    }

    var bytes = [UInt8](repeating: 0, count: length)
    let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)

    guard status == errSecSuccess else {
      throw CoreErrors.CryptoError.randomGenerationFailed(status: status)
    }

    return Data(bytes)
  }

  /// Generates random bytes.
  ///
  /// - Parameter count: Number of random bytes to generate.
  /// - Returns: Array of random bytes.
  /// - Throws: `CryptoError` if random generation fails.
  public func generateRandomBytes(count: Int) throws -> [UInt8] {
    guard state == .running else {
      throw CoreErrors.ServiceError.invalidState
    }

    var bytes = [UInt8](repeating: 0, count: count)
    let status = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
    guard status == errSecSuccess else {
      throw CoreErrors.CryptoError.randomGenerationFailed(status: status)
    }
    return bytes
  }

  /// Calculate a hash of the provided data
  ///
  /// - Parameter data: The data to hash
  /// - Returns: The resulting hash value as a byte array
  /// - Throws: ServiceError if the service is not ready
  public func hash(_ data: [UInt8]) async throws -> [UInt8] {
    guard state == .running else {
      throw CoreErrors.ServiceError.invalidState
    }

    // Use CommonCrypto for SHA-256 hash
    // This is a simple implementation that should be enhanced in production
    let hashData = Data(data)
    var hashBytes = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))

    hashData.withUnsafeBytes { dataBuffer in
      _ = CC_SHA256(dataBuffer.baseAddress, CC_LONG(data.count), &hashBytes)
    }

    return hashBytes
  }

  /// Check if the service is in a usable state
  public func isUsable() async -> Bool {
    switch state {
      case .uninitialized:
        false
      case .initializing:
        false
      case .running:
        true
      case .ready:
        true
      case .shuttingDown:
        false
      case .error:
        false
      case .suspended:
        false
      case .shutdown:
        false
    }
  }
}
