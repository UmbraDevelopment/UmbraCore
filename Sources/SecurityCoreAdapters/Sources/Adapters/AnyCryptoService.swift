import ErrorHandlingDomains
import SecurityProtocolsCore
import UmbraCoreTypes

// Alias UmbraErrors.Security.Protocols as SecurityError to match the existing code expectations
public typealias SecurityError=UmbraErrors.Security.Protocols

/// Type-erased wrapper for CryptoServiceProtocol
/// This allows for cleaner interfaces without exposing implementation details
public final class AnyCryptoService: CryptoServiceProtocol {
  // MARK: - Private Properties

  private let _encrypt: @Sendable (SecureBytes, SecureBytes) async -> Result<
    SecureBytes,
    SecurityError
  >
  private let _decrypt: @Sendable (SecureBytes, SecureBytes) async -> Result<
    SecureBytes,
    SecurityError
  >
  private let _hash: @Sendable (SecureBytes) async -> Result<SecureBytes, SecurityError>
  private let _generateKey: @Sendable () async -> Result<SecureBytes, SecurityError>
  private let _generateRandomData: @Sendable (Int) async -> Result<SecureBytes, SecurityError>

  // New required methods with corrected return types
  private let _verify: @Sendable (SecureBytes, SecureBytes) async -> Result<Bool, SecurityError>
  private let _encryptSymmetric: @Sendable (SecureBytes, SecureBytes, SecurityConfigDTO) async
    -> Result<SecureBytes, SecurityError>
  private let _decryptSymmetric: @Sendable (SecureBytes, SecureBytes, SecurityConfigDTO) async
    -> Result<SecureBytes, SecurityError>
  private let _encryptAsymmetric: @Sendable (SecureBytes, SecureBytes, SecurityConfigDTO) async
    -> Result<SecureBytes, SecurityError>
  private let _decryptAsymmetric: @Sendable (SecureBytes, SecureBytes, SecurityConfigDTO) async
    -> Result<SecureBytes, SecurityError>
  private let _hashWithConfig: @Sendable (SecureBytes, SecurityConfigDTO) async -> Result<
    SecureBytes,
    SecurityError
  >

  // MARK: - Initialization

  /// Create a type-erased crypto service from an existing implementation
  /// - Parameter service: The crypto service to wrap
  public init(_ service: some CryptoServiceProtocol & Sendable) {
    // Fixed Sendable warning by explicitly capturing methods as @Sendable functions
    _encrypt={ @Sendable [service] in await service.encrypt(data: $0, using: $1) }
    _decrypt={ @Sendable [service] in await service.decrypt(data: $0, using: $1) }
    _hash={ @Sendable [service] in await service.hash(data: $0) }
    _generateKey={ @Sendable [service] in await service.generateKey() }
    _generateRandomData={ @Sendable [service] in await service.generateRandomData(length: $0) }

    // New property initializations with correct return types
    _verify={ @Sendable [service] in await service.verify(data: $0, against: $1) }
    _encryptSymmetric={ @Sendable [service] in
      await service.encryptSymmetric(data: $0, key: $1, config: $2)
    }
    _decryptSymmetric={ @Sendable [service] in
      await service.decryptSymmetric(data: $0, key: $1, config: $2)
    }
    _encryptAsymmetric={ @Sendable [service] in
      await service.encryptAsymmetric(data: $0, publicKey: $1, config: $2)
    }
    _decryptAsymmetric={ @Sendable [service] in
      await service.decryptAsymmetric(data: $0, privateKey: $1, config: $2)
    }
    _hashWithConfig={ @Sendable [service] in await service.hash(data: $0, config: $1) }
  }

  // MARK: - CryptoServiceProtocol Implementation

  public func encrypt(
    data: SecureBytes,
    using key: SecureBytes
  ) async -> Result<SecureBytes, SecurityError> {
    await _encrypt(data, key)
  }

  public func decrypt(
    data: SecureBytes,
    using key: SecureBytes
  ) async -> Result<SecureBytes, SecurityError> {
    await _decrypt(data, key)
  }

  public func hash(data: SecureBytes) async -> Result<SecureBytes, SecurityError> {
    await _hash(data)
  }

  public func generateKey() async -> Result<SecureBytes, SecurityError> {
    await _generateKey()
  }

  public func generateRandomData(length: Int) async -> Result<SecureBytes, SecurityError> {
    await _generateRandomData(length)
  }

  // New method implementations with correct return types

  public func verify(
    data: SecureBytes,
    against hash: SecureBytes
  ) async -> Result<Bool, SecurityError> {
    await _verify(data, hash)
  }

  public func encryptSymmetric(
    data: SecureBytes,
    key: SecureBytes,
    config: SecurityConfigDTO
  ) async -> Result<SecureBytes, SecurityError> {
    await _encryptSymmetric(data, key, config)
  }

  public func decryptSymmetric(
    data: SecureBytes,
    key: SecureBytes,
    config: SecurityConfigDTO
  ) async -> Result<SecureBytes, SecurityError> {
    await _decryptSymmetric(data, key, config)
  }

  public func encryptAsymmetric(
    data: SecureBytes,
    publicKey: SecureBytes,
    config: SecurityConfigDTO
  ) async -> Result<SecureBytes, SecurityError> {
    await _encryptAsymmetric(data, publicKey, config)
  }

  public func decryptAsymmetric(
    data: SecureBytes,
    privateKey: SecureBytes,
    config: SecurityConfigDTO
  ) async -> Result<SecureBytes, SecurityError> {
    await _decryptAsymmetric(data, privateKey, config)
  }

  public func hash(
    data: SecureBytes,
    config: SecurityConfigDTO
  ) async -> Result<SecureBytes, SecurityError> {
    await _hashWithConfig(data, config)
  }
}
