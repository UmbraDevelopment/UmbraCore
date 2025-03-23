import CryptoSwiftFoundationIndependent
import ErrorHandlingCore
import ErrorHandlingInterfaces
import ErrorHandlingDomains
import ErrorHandlingMapping
import Foundation
import SecurityProtocolsCore
import UmbraCoreTypes

@_implementationOnly import var Security.errSecSuccess
@_implementationOnly import var Security.kSecRandomDefault

// Importing necessary crypto services
@_implementationOnly import class Security.SecKey
@_implementationOnly import struct Security.SecKeyAlgorithm
@_implementationOnly import func Security.SecRandomCopyBytes

/// Implementation of the CryptoServiceProtocol
public final class CryptoServiceImpl: CryptoServiceProtocol {
  // MARK: - Properties

  /// Service for symmetric encryption operations
  private let symmetricCrypto: SymmetricCrypto

  /// Service for hashing operations
  private let hashingService: HashingService

  /// Service for key generation
  private let keyGenerator: KeyGenerator

  // MARK: - Initialisation

  public init() {
    symmetricCrypto = SymmetricCrypto()
    hashingService = HashingService()
    keyGenerator = KeyGenerator()
  }

  // MARK: - CryptoServiceProtocol Implementation

  public func encrypt(
    data: SecureBytes,
    using key: SecureBytes
  ) async -> Result<SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    // Use the symmetric crypto service with default configuration
    let result = await symmetricCrypto.encryptData(
      data: data,
      key: key,
      algorithm: "AES-GCM",
      iv: nil
    )

    if result.success, let encryptedData = result.data {
      return .success(encryptedData)
    } else {
      return .failure(.encryptionFailed(result.errorMessage ?? "Unknown encryption error"))
    }
  }

  public func decrypt(
    data: SecureBytes,
    using key: SecureBytes
  ) async -> Result<SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    // Use the symmetric crypto service with default configuration
    let result = await symmetricCrypto.decryptData(
      data: data,
      key: key,
      algorithm: "AES-GCM",
      iv: nil
    )

    if result.success, let decryptedData = result.data {
      return .success(decryptedData)
    } else {
      return .failure(.decryptionFailed(result.errorMessage ?? "Unknown decryption error"))
    }
  }

  public func hash(data: SecureBytes) async -> Result<SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    // Use SHA-256 as the default algorithm
    await hash(data: data, config: SecurityConfigDTO(algorithm: "SHA-256", keySizeInBits: 256))
  }

  public func generateKey() async -> Result<SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    // Generate a secure random key with 256-bit size for AES
    let result = await keyGenerator.generateKey(bits: 256, algorithm: "AES")

    if result.success, let key = result.data {
      return .success(key)
    } else {
      return .failure(.internalError(result.errorMessage ?? "Unknown key generation error"))
    }
  }

  public func verify(
    data: SecureBytes,
    against hash: SecureBytes
  ) async -> Result<Bool, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    // Hash the data using SHA-256
    let hashResult = await self.hash(data: data)

    switch hashResult {
      case let .success(computedHash):
        // Compare the computed hash with the provided hash
        let match = (0..<min(computedHash.count, hash.count))
          .allSatisfy { computedHash[$0] == hash[$0] }
          && computedHash.count == hash.count
        return .success(match)
      case let .failure(error):
        return .failure(error)
    }
  }

  // MARK: - Extended Protocol Methods

  public func generateRandomData(length: Int) async
  -> Result<SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    // Generate secure random data of specified length
    var randomBytes = [UInt8](repeating: 0, count: length)
    let status = SecRandomCopyBytes(kSecRandomDefault, length, &randomBytes)

    if status == errSecSuccess {
      return .success(SecureBytes(bytes: randomBytes))
    } else {
      return .failure(.internalError("Random data generation failed"))
    }
  }

  // MARK: - Symmetric Encryption

  public func encryptSymmetric(
    data: SecureBytes,
    key: SecureBytes,
    config: SecurityConfigDTO
  ) async -> Result<SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    // Use the symmetric crypto service with the provided configuration
    let result = await symmetricCrypto.encryptData(
      data: data,
      key: key,
      algorithm: config.algorithm,
      iv: config.initializationVector
    )

    if result.success, let encryptedData = result.data {
      return .success(encryptedData)
    } else {
      return .failure(.encryptionFailed(result.errorMessage ?? "Unknown encryption error"))
    }
  }

  public func decryptSymmetric(
    data: SecureBytes,
    key: SecureBytes,
    config: SecurityConfigDTO
  ) async -> Result<SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    // Use the symmetric crypto service with the provided configuration
    let result = await symmetricCrypto.decryptData(
      data: data,
      key: key,
      algorithm: config.algorithm,
      iv: config.initializationVector
    )

    if result.success, let decryptedData = result.data {
      return .success(decryptedData)
    } else {
      return .failure(.decryptionFailed(result.errorMessage ?? "Unknown decryption error"))
    }
  }

  // MARK: - Asymmetric Encryption

  public func encryptAsymmetric(
    data _: SecureBytes,
    publicKey _: SecureBytes,
    config _: SecurityConfigDTO
  ) async -> Result<SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    // For now, return unsupported operation as we focus on symmetric operations
    .failure(.unsupportedOperation(name: "Asymmetric encryption not implemented"))
  }

  public func decryptAsymmetric(
    data _: SecureBytes,
    privateKey _: SecureBytes,
    config _: SecurityConfigDTO
  ) async -> Result<SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    // For now, return unsupported operation as we focus on symmetric operations
    .failure(.unsupportedOperation(name: "Asymmetric decryption not implemented"))
  }

  // MARK: - Advanced Hashing

  public func hash(
    data: SecureBytes,
    config: SecurityConfigDTO
  ) async -> Result<SecureBytes, ErrorHandlingDomains.UmbraErrors.Security.Protocols> {
    // Use the hashing service with the provided algorithm
    let result = await hashingService.hashData(
      data: data,
      algorithm: config.algorithm
    )

    if result.success, let hashedData = result.data {
      return .success(hashedData)
    } else {
      return .failure(.internalError(result.errorMessage ?? "Unknown hashing error"))
    }
  }
}
