import CoreDTOs
import ErrorHandling
import ErrorHandlingDomains
import Foundation
import SecurityBridgeTypes
import UmbraCoreTypes

/// Hash algorithm types supported by the security service
public enum HashAlgorithm {
  case sha1
  case sha224
  case sha256
  case sha384
  case sha512
  case md5
}

/// Protocol for the security service provided by UmbraSecurity
public protocol SecurityService {
  /// Generate random bytes
  /// - Parameter count: Number of random bytes to generate
  /// - Throws: Error if generation fails
  /// - Returns: Array of random bytes
  func generateRandomBytes(count: Int) throws -> [UInt8]

  /// Generate a secure token as a string (base64-encoded or similar)
  /// - Parameter byteCount: Number of bytes to use for the token
  /// - Throws: Error if token generation fails
  /// - Returns: String representation of the token
  func generateSecureToken(byteCount: Int) throws -> String

  /// Hash data using the specified algorithm
  /// - Parameters:
  ///   - data: Data to hash
  ///   - algorithm: Hash algorithm to use
  /// - Throws: Error if hashing fails
  /// - Returns: Hashed data
  func hashData(_ data: Data, algorithm: HashAlgorithm) throws -> Data

  /// Encrypt data using the specified key
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - key: Encryption key
  /// - Throws: Error if encryption fails
  /// - Returns: Encrypted data
  func encrypt(_ data: [UInt8], key: [UInt8]) throws -> [UInt8]

  /// Decrypt data using the specified key
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - key: Decryption key
  /// - Throws: Error if decryption fails
  /// - Returns: Decrypted data
  func decrypt(_ data: [UInt8], key: [UInt8]) throws -> [UInt8]
}

/// Default implementation of the security service
public class DefaultSecurityService: SecurityService {
  /// Shared instance
  public static let shared: DefaultSecurityService = .init()

  public init() {}

  public func generateRandomBytes(count: Int) throws -> [UInt8] {
    // Stub implementation
    Array(repeating: 0, count: count)
  }

  public func generateSecureToken(byteCount _: Int) throws -> String {
    // Stub implementation
    "secure_token"
  }

  public func hashData(_ data: Data, algorithm _: HashAlgorithm) throws -> Data {
    // Stub implementation
    data
  }

  public func encrypt(_ data: [UInt8], key _: [UInt8]) throws -> [UInt8] {
    // Stub implementation
    data
  }

  public func decrypt(_ data: [UInt8], key _: [UInt8]) throws -> [UInt8] {
    // Stub implementation
    data
  }
}

/// Protocol for Foundation-independent security service operations
public protocol SecurityServiceDTOProtocol {
  /// Generate random bytes
  /// - Parameter count: Number of bytes to generate
  /// - Returns: A result containing the random bytes or an error
  func generateRandomBytes(count: Int) -> OperationResultDTO<[UInt8]>

  /// Generate a secure token
  /// - Parameter byteCount: Number of bytes in the token
  /// - Returns: A result containing the token as a hex string or an error
  func generateSecureToken(byteCount: Int) -> OperationResultDTO<String>

  /// Hash data using the specified algorithm
  /// - Parameters:
  ///   - data: Data to hash
  ///   - config: Configuration with algorithm and options
  /// - Returns: A result containing the hash or an error
  func hashData(_ data: [UInt8], config: SecurityConfigDTO) -> OperationResultDTO<[UInt8]>

  /// Encrypt data using the specified key and algorithm
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - key: Encryption key
  ///   - config: Configuration with algorithm and options
  /// - Returns: A result containing the encrypted data or an error
  func encrypt(_ data: [UInt8], key: [UInt8], config: SecurityConfigDTO)
    -> OperationResultDTO<[UInt8]>

  /// Decrypt data using the specified key and algorithm
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - key: Decryption key
  ///   - config: Configuration with algorithm and options
  /// - Returns: A result containing the decrypted data or an error
  func decrypt(_ data: [UInt8], key: [UInt8], config: SecurityConfigDTO)
    -> OperationResultDTO<[UInt8]>
}

/// Adapter for SecurityService that provides a Foundation-independent interface
public final class SecurityServiceDTOAdapter: SecurityServiceDTOProtocol {
  // MARK: - Properties

  /// The underlying security service
  private let securityService: SecurityService

  // MARK: - Initialization

  /// Initialize with a security service
  /// - Parameter securityService: The security service to adapt
  public init(securityService: SecurityService=DefaultSecurityService.shared) {
    self.securityService=securityService
  }

  // MARK: - SecurityServiceDTOProtocol Implementation

  /// Generate random bytes
  /// - Parameter count: Number of bytes to generate
  /// - Returns: A result containing the random bytes or an error
  public func generateRandomBytes(count: Int) -> OperationResultDTO<[UInt8]> {
    do {
      let bytes=try securityService.generateRandomBytes(count: count)
      return .success(bytes)
    } catch {
      return .failure(
        errorCode: Int32(SecurityErrorDTO.generalErrorCode),
        errorMessage: "Failed to generate random bytes: \(error.localizedDescription)"
      )
    }
  }

  /// Generate a secure token
  /// - Parameter byteCount: Number of bytes in the token
  /// - Returns: A result containing the token as a hex string or an error
  public func generateSecureToken(byteCount: Int) -> OperationResultDTO<String> {
    do {
      let token=try securityService.generateSecureToken(byteCount: byteCount)
      return .success(token)
    } catch {
      return .failure(
        errorCode: Int32(SecurityErrorDTO.generalErrorCode),
        errorMessage: "Failed to generate secure token: \(error.localizedDescription)"
      )
    }
  }

  /// Hash data using the specified algorithm
  /// - Parameters:
  ///   - data: Data to hash
  ///   - config: Configuration with algorithm and options
  /// - Returns: A result containing the hash or an error
  public func hashData(_ data: [UInt8], config: SecurityConfigDTO) -> OperationResultDTO<[UInt8]> {
    do {
      let algorithm=mapHashAlgorithm(from: config)
      let hash=try securityService.hashData(Data(data), algorithm: algorithm)
      return .success([UInt8](hash))
    } catch {
      return .failure(
        errorCode: Int32(SecurityErrorDTO.generalErrorCode),
        errorMessage: "Failed to hash data: \(error.localizedDescription)"
      )
    }
  }

  /// Encrypt data using the specified key and algorithm
  /// - Parameters:
  ///   - data: Data to encrypt
  ///   - key: Encryption key
  ///   - config: Configuration with algorithm and options
  /// - Returns: A result containing the encrypted data or an error
  public func encrypt(
    _ data: [UInt8],
    key: [UInt8],
    config _: SecurityConfigDTO
  ) -> OperationResultDTO<[UInt8]> {
    do {
      let encryptedData=try securityService.encrypt(data, key: key)
      return .success(encryptedData)
    } catch {
      return .failure(
        errorCode: Int32(SecurityErrorDTO.generalErrorCode),
        errorMessage: "Failed to encrypt data: \(error.localizedDescription)"
      )
    }
  }

  /// Decrypt data using the specified key and algorithm
  /// - Parameters:
  ///   - data: Data to decrypt
  ///   - key: Decryption key
  ///   - config: Configuration with algorithm and options
  /// - Returns: A result containing the decrypted data or an error
  public func decrypt(
    _ data: [UInt8],
    key: [UInt8],
    config _: SecurityConfigDTO
  ) -> OperationResultDTO<[UInt8]> {
    do {
      let decryptedData=try securityService.decrypt(data, key: key)
      return .success(decryptedData)
    } catch {
      return .failure(
        errorCode: Int32(SecurityErrorDTO.generalErrorCode),
        errorMessage: "Failed to decrypt data: \(error.localizedDescription)"
      )
    }
  }

  // MARK: - Helper Methods

  /// Map a hash algorithm from configuration
  /// - Parameter config: The security configuration
  /// - Returns: The hash algorithm
  private func mapHashAlgorithm(from config: SecurityConfigDTO) -> HashAlgorithm {
    // Default to SHA256 if not specified
    guard let algorithmName=config.options["algorithm"] else {
      return .sha256
    }

    switch algorithmName.lowercased() {
      case "sha1": return .sha1
      case "sha224": return .sha224
      case "sha384": return .sha384
      case "sha512": return .sha512
      case "md5": return .md5
      default: return .sha256
    }
  }

  /// Map errors to operation failure
  /// - Parameter error: The error to map
  /// - Returns: An operation failure
  private func mapError(_ error: Error)
  -> (code: Int32, message: String, details: [String: String]) {
    if let securityError=error as? UmbraErrors.Security.Core {
      let errorDTO=mapSecurityError(securityError)
      return (Int32(errorDTO.code), errorDTO.message, errorDTO.details)
    } else {
      return (
        Int32(SecurityErrorDTO.generalErrorCode),
        "Security operation failed: \(error.localizedDescription)",
        [:]
      )
    }
  }

  /// Map security errors to DTOs
  /// - Parameter error: The security error to map
  /// - Returns: A security error DTO
  private func mapSecurityError(_ error: UmbraErrors.Security.Core) -> SecurityErrorDTO {
    // Handle all possible security errors with appropriate mappings
    let errorDTO=SecurityErrorDTO(
      code: 1001,
      domain: "security.service",
      message: "Security operation failed",
      details: ["error": "\(error)"]
    )
    return errorDTO
  }
}
