import CoreDTOs
import ErrorHandling
import Foundation
import UmbraCoreTypes

/// An adapter for security utilities that uses Foundation-independent DTOs
public struct SecurityUtilsDTOAdapter {
  // MARK: - Properties

  /// Access to the security utilities implementation
  private let securityUtils: any SecurityUtilsProtocol

  // MARK: - Initialization

  /// Initialize the adapter with a security utilities implementation
  /// - Parameter securityUtils: The security utilities to adapt
  public init(securityUtils: any SecurityUtilsProtocol) {
    self.securityUtils=securityUtils
  }

  /// Initialize the adapter with the default security utilities
  public init() {
    securityUtils=DefaultSecurityUtils()
  }

  // MARK: - Public Methods

  /// Generate a random key based on the provided configuration
  /// - Parameter config: The security configuration
  /// - Returns: Result containing the generated key or an error
  public func generateKey(
    config: SecurityConfigDTO
  ) -> OperationResultDTO<[UInt8]> {
    do {
      // Generate key based on configuration
      let keySize=config.keySizeInBits / 8 // Convert bits to bytes
      var keyData=[UInt8](repeating: 0, count: keySize)

      // Use SecRandomCopyBytes for secure random generation
      let result=SecRandomCopyBytes(kSecRandomDefault, keySize, &keyData)

      guard result == errSecSuccess else {
        return .failure(
          errorCode: 1001, // Using the key error code from SecurityErrorDTO
          errorMessage: "Failed to generate random key",
          details: ["osStatus": "\(result)"]
        )
      }

      return .success(keyData)
    } catch {
      return .failure(
        errorCode: 1001, // Using the key error code from SecurityErrorDTO
        errorMessage: "Unknown error generating key: \(error.localizedDescription)",
        details: ["error": "\(error)"]
      )
    }
  }

  /// Hash data using the specified algorithm
  /// - Parameters:
  ///   - data: The data to hash
  ///   - config: The security configuration
  /// - Returns: Result containing the hash or an error
  public func hashData(
    _ data: [UInt8],
    config: SecurityConfigDTO
  ) -> OperationResultDTO<[UInt8]> {
    do {
      // Convert data to Data type
      let inputData=Data(data)

      // Get hash algorithm from config
      let algorithm=config.algorithm

      // Hash data using security utils
      let hashData=try securityUtils.hashData(inputData, using: algorithm)

      // Convert result to [UInt8]
      let hashBytes=[UInt8](hashData)

      return .success(hashBytes)
    } catch {
      return .failure(
        errorCode: 1002, // Using the hash error code from SecurityErrorDTO
        errorMessage: "Failed to hash data: \(error.localizedDescription)",
        details: ["algorithm": config.algorithm]
      )
    }
  }

  /// Encrypt data using the configured algorithm and key
  /// - Parameters:
  ///   - data: The data to encrypt
  ///   - config: The security configuration
  /// - Returns: Result containing the encrypted data or an error
  public func encryptData(
    _ data: [UInt8],
    config: SecurityConfigDTO
  ) -> OperationResultDTO<[UInt8]> {
    do {
      // Convert data to Data type
      let inputData=Data(data)

      // Get algorithm and key from config
      let algorithm=config.algorithm

      // Check if we have a key in the options
      guard let keyBase64=config.options["key"] else {
        return .failure(
          errorCode: 1003, // Using the encryption error code from SecurityErrorDTO
          errorMessage: "Missing encryption key in configuration",
          details: ["algorithm": algorithm]
        )
      }

      // Convert key from Base64
      guard let keyData=Data(base64Encoded: keyBase64) else {
        return .failure(
          errorCode: 1003, // Using the encryption error code from SecurityErrorDTO
          errorMessage: "Invalid encryption key format",
          details: ["algorithm": algorithm]
        )
      }

      // Encrypt data using security utils
      let encryptedData=try securityUtils.encryptData(inputData, using: algorithm, key: keyData)

      // Convert result to [UInt8]
      let encryptedBytes=[UInt8](encryptedData)

      return .success(encryptedBytes)
    } catch {
      return .failure(
        errorCode: 1003, // Using the encryption error code from SecurityErrorDTO
        errorMessage: "Failed to encrypt data: \(error.localizedDescription)",
        details: ["algorithm": config.algorithm]
      )
    }
  }

  /// Decrypt data using the configured algorithm and key
  /// - Parameters:
  ///   - data: The encrypted data
  ///   - config: The security configuration
  /// - Returns: Result containing the decrypted data or an error
  public func decryptData(
    _ data: [UInt8],
    config: SecurityConfigDTO
  ) -> OperationResultDTO<[UInt8]> {
    do {
      // Convert data to Data type
      let inputData=Data(data)

      // Get algorithm and key from config
      let algorithm=config.algorithm

      // Check if we have a key in the options
      guard let keyBase64=config.options["key"] else {
        return .failure(
          errorCode: 1004, // Using the decryption error code from SecurityErrorDTO
          errorMessage: "Missing decryption key in configuration",
          details: ["algorithm": algorithm]
        )
      }

      // Convert key from Base64
      guard let keyData=Data(base64Encoded: keyBase64) else {
        return .failure(
          errorCode: 1004, // Using the decryption error code from SecurityErrorDTO
          errorMessage: "Invalid decryption key format",
          details: ["algorithm": algorithm]
        )
      }

      // Decrypt data using security utils
      let decryptedData=try securityUtils.decryptData(inputData, using: algorithm, key: keyData)

      // Convert result to [UInt8]
      let decryptedBytes=[UInt8](decryptedData)

      return .success(decryptedBytes)
    } catch {
      return .failure(
        errorCode: 1004, // Using the decryption error code from SecurityErrorDTO
        errorMessage: "Failed to decrypt data: \(error.localizedDescription)",
        details: ["algorithm": config.algorithm]
      )
    }
  }
}

// MARK: - Factory Methods for SecurityConfigDTO

extension SecurityConfigDTO {
  /// Create a configuration for hashing operations
  /// - Parameter algorithm: The hash algorithm to use (e.g., "SHA256", "SHA512")
  /// - Returns: A SecurityConfigDTO configured for hashing
  public static func hash(algorithm: String="SHA256") -> SecurityConfigDTO {
    SecurityConfigDTO(
      algorithm: algorithm,
      keySizeInBits: 0 // No key required for hashing
    )
  }
}

// MARK: - Security Utilities Protocol

/// Protocol defining security utilities operations
public protocol SecurityUtilsProtocol {
  /// Hash data using the specified algorithm
  /// - Parameters:
  ///   - data: The data to hash
  ///   - algorithm: The hashing algorithm to use
  /// - Returns: The hashed data
  func hashData(_ data: Data, using algorithm: String) throws -> Data

  /// Encrypt data using the specified algorithm and key
  /// - Parameters:
  ///   - data: The data to encrypt
  ///   - algorithm: The encryption algorithm to use
  ///   - key: The encryption key
  /// - Returns: The encrypted data
  func encryptData(_ data: Data, using algorithm: String, key: Data) throws -> Data

  /// Decrypt data using the specified algorithm and key
  /// - Parameters:
  ///   - data: The encrypted data
  ///   - algorithm: The encryption algorithm used
  ///   - key: The decryption key
  /// - Returns: The decrypted data
  func decryptData(_ data: Data, using algorithm: String, key: Data) throws -> Data
}

// MARK: - Security Utilities Errors

/// Errors that can occur during security operations
public enum SecurityUtilsError: Error, LocalizedError {
  /// Failed to hash data
  case hashingFailed(algorithm: String, reason: String)
  /// Failed to encrypt data
  case encryptionFailed(algorithm: String, reason: String)
  /// Failed to decrypt data
  case decryptionFailed(algorithm: String, reason: String)
  /// Invalid algorithm specified
  case invalidAlgorithm(name: String, operation: String)
  /// Invalid key format or size
  case invalidKey(algorithm: String, reason: String)

  public var errorDescription: String? {
    switch self {
      case let .hashingFailed(algorithm, reason):
        "Failed to hash data using \(algorithm): \(reason)"
      case let .encryptionFailed(algorithm, reason):
        "Failed to encrypt data using \(algorithm): \(reason)"
      case let .decryptionFailed(algorithm, reason):
        "Failed to decrypt data using \(algorithm): \(reason)"
      case let .invalidAlgorithm(name, operation):
        "Invalid algorithm '\(name)' for \(operation) operation"
      case let .invalidKey(algorithm, reason):
        "Invalid key for \(algorithm): \(reason)"
    }
  }
}

// MARK: - Default Implementation

/// Default implementation of SecurityUtilsProtocol
public struct DefaultSecurityUtils: SecurityUtilsProtocol {
  public init() {}

  /// Hash data using the specified algorithm
  /// - Parameters:
  ///   - data: The data to hash
  ///   - algorithm: The hashing algorithm to use
  /// - Returns: The hashed data
  public func hashData(_: Data, using _: String) throws -> Data {
    // Simple implementation using Common Crypto
    // In a real implementation, this would use CommonCrypto directly
    // or CryptoKit for modern Swift apps

    // This is a mock implementation for demonstration purposes
    Data(repeating: 0x42, count: 32)
  }

  /// Encrypt data using the specified algorithm and key
  /// - Parameters:
  ///   - data: The data to encrypt
  ///   - algorithm: The encryption algorithm to use
  ///   - key: The encryption key
  /// - Returns: The encrypted data
  public func encryptData(_ data: Data, using _: String, key _: Data) throws -> Data {
    // Simple implementation for demo purposes
    // In a real implementation, would use CommonCrypto or CryptoKit

    // This is a mock implementation for demonstration purposes
    Data(repeating: 0x41, count: data.count + 16)
  }

  /// Decrypt data using the specified algorithm and key
  /// - Parameters:
  ///   - data: The encrypted data
  ///   - algorithm: The encryption algorithm used
  ///   - key: The decryption key
  /// - Returns: The decrypted data
  public func decryptData(_ data: Data, using _: String, key _: Data) throws -> Data {
    // Simple implementation for demo purposes
    // In a real implementation, would use CommonCrypto or CryptoKit

    // This is a mock implementation for demonstration purposes
    data.count > 16 ? Data(data.prefix(data.count - 16)) : Data()
  }
}
