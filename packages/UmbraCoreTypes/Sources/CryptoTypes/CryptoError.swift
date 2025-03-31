import Foundation

/// Errors that can occur during cryptographic operations.
public enum CryptoError: Error, Sendable, Equatable, CustomStringConvertible, LocalizedError {
  // MARK: - Key Management Errors

  /// Failed to generate a secure random key.
  case keyGenerationFailed(reason: String)

  /// Invalid key format or length.
  case invalidKey(reason: String)

  /// Key not found in storage.
  case keyNotFound(identifier: String)

  /// Key derivation from password failed.
  case keyDerivationFailed(reason: String)

  /// Insufficient entropy for secure key generation.
  case insufficientEntropy(required: Int, available: Int)

  // MARK: - Encryption/Decryption Errors

  /// Failed to encrypt data.
  case encryptionFailed(reason: String)

  /// Failed to decrypt data.
  case decryptionFailed(reason: String)

  /// Failed to verify the integrity of encrypted data.
  case integrityCheckFailed(reason: String)

  /// Invalid padding or formatting in encrypted data.
  case invalidPadding(reason: String)

  // MARK: - Input/Algorithm Errors

  /// Invalid input data provided.
  case invalidInput(reason: String)

  /// Invalid algorithm or parameters specified.
  case invalidAlgorithm(reason: String)

  /// Incompatible algorithm versions.
  case algorithmVersionMismatch(expected: String, received: String)

  /// Operation not supported by the current implementation.
  case unsupportedOperation(reason: String)

  // MARK: - System/Resource Errors

  /// System crypto resources unavailable.
  case resourceUnavailable(resource: String)

  /// Memory allocation or access error.
  case memoryError(reason: String)

  /// General cryptographic operation failure.
  case operationFailed(reason: String)

  // MARK: - Description

  /// A human-readable description of the error.
  public var description: String {
    switch self {
      case let .keyGenerationFailed(reason):
        "Key generation failed: \(reason)"
      case let .encryptionFailed(reason):
        "Encryption failed: \(reason)"
      case let .decryptionFailed(reason):
        "Decryption failed: \(reason)"
      case let .invalidKey(reason):
        "Invalid key: \(reason)"
      case let .invalidInput(reason):
        "Invalid input: \(reason)"
      case let .invalidAlgorithm(reason):
        "Invalid algorithm: \(reason)"
      case let .unsupportedOperation(reason):
        "Unsupported operation: \(reason)"
      case let .keyNotFound(identifier):
        "Key not found: \(identifier)"
      case let .operationFailed(reason):
        "Cryptographic operation failed: \(reason)"
      case let .keyDerivationFailed(reason):
        "Key derivation failed: \(reason)"
      case let .insufficientEntropy(required, available):
        "Insufficient entropy: required \(required) bytes, available \(available) bytes"
      case let .integrityCheckFailed(reason):
        "Integrity check failed: \(reason)"
      case let .invalidPadding(reason):
        "Invalid padding: \(reason)"
      case let .algorithmVersionMismatch(expected, received):
        "Algorithm version mismatch: expected \(expected), received \(received)"
      case let .resourceUnavailable(resource):
        "Cryptographic resource unavailable: \(resource)"
      case let .memoryError(reason):
        "Memory error: \(reason)"
    }
  }

  // MARK: - LocalizedError Conformance

  /// The localized description of the error.
  public var errorDescription: String? {
    description
  }

  /// A localized message describing the reason for the failure.
  public var failureReason: String? {
    switch self {
      case let .keyGenerationFailed(reason),
           let .encryptionFailed(reason),
           let .decryptionFailed(reason),
           let .invalidKey(reason),
           let .invalidInput(reason),
           let .invalidAlgorithm(reason),
           let .unsupportedOperation(reason),
           let .operationFailed(reason),
           let .keyDerivationFailed(reason),
           let .integrityCheckFailed(reason),
           let .invalidPadding(reason),
           let .memoryError(reason):
        reason
      case let .keyNotFound(identifier):
        "No key found with identifier: \(identifier)"
      case let .insufficientEntropy(required, available):
        "System could only provide \(available) bytes of entropy, but \(required) bytes were needed"
      case let .algorithmVersionMismatch(expected, received):
        "Expected algorithm version \(expected), but received \(received)"
      case let .resourceUnavailable(resource):
        "The required resource '\(resource)' is unavailable or access was denied"
    }
  }

  /// A localized message describing how one might recover from the failure.
  public var recoverySuggestion: String? {
    switch self {
      case .keyGenerationFailed:
        "Try again or check system entropy sources"
      case .encryptionFailed, .decryptionFailed:
        "Verify that the key and input data are correct"
      case .invalidKey:
        "Ensure the key has the correct size and format"
      case .invalidInput:
        "Verify the input data is properly formatted"
      case .invalidAlgorithm:
        "Use a supported algorithm with correct parameters"
      case .unsupportedOperation:
        "Use an alternative operation supported by this implementation"
      case .keyNotFound:
        "Create or import the required key before using it"
      case .operationFailed:
        "Check logs for more details and try again"
      case .keyDerivationFailed:
        "Check that the password and salt are correct"
      case .insufficientEntropy:
        "Wait for the system to gather more entropy and try again"
      case .integrityCheckFailed:
        "The data may have been tampered with or corrupted"
      case .invalidPadding:
        "The data format or padding scheme may be incorrect"
      case .algorithmVersionMismatch:
        "Use the same algorithm version for encryption and decryption"
      case .resourceUnavailable:
        "Check system permissions and availability of cryptographic services"
      case .memoryError:
        "Close unnecessary applications to free memory"
    }
  }

  /// The help anchor for the corresponding documentation.
  public var helpAnchor: String? {
    switch self {
      case .keyGenerationFailed, .keyNotFound, .invalidKey, .keyDerivationFailed,
           .insufficientEntropy:
        "crypto_key_management"
      case .encryptionFailed, .decryptionFailed, .integrityCheckFailed, .invalidPadding:
        "crypto_encryption_decryption"
      case .invalidInput, .invalidAlgorithm, .algorithmVersionMismatch, .unsupportedOperation:
        "crypto_algorithms"
      case .resourceUnavailable, .memoryError, .operationFailed:
        "crypto_system_resources"
    }
  }
}
