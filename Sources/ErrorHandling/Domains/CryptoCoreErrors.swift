import Foundation
// Use the shared declarations instead of local ones
import Interfaces
import UmbraErrorsCore


/// Error domain namespace

/// Error context protocol

/// Base error context implementation

/// Core cryptography error domain for UmbraCore
///
/// This file defines standardised error types for cryptographic operations in the UmbraCore
/// framework.
/// These errors represent failures related to encryption/decryption, key management,
/// signing/verification,
/// and other cryptographic operations.
///
/// ## Usage Examples
///
/// ### Throwing cryptography errors:
/// ```swift
/// func encryptData(_ data: Data, using key: CryptoKey) throws -> Data {
///   guard key.isValid else {
///     throw UmbraErrors.Crypto.Core.makeInvalidKeyError(keyType: "RSA", reason: "Key has expired")
///   }
///
///   guard isAlgorithmSupported(key.algorithm) else {
///     throw UmbraErrors.Crypto.Core.makeUnsupportedAlgorithmError(algorithm: key.algorithm)
///   }
///
///   // Encryption implementation...
/// }
/// ```
///
/// ### Handling cryptography errors:
/// ```swift
/// do {
///   let encryptedData = try cryptoService.encrypt(data, using: key)
/// } catch let error as UmbraErrors.Crypto.Core {
///   switch error {
///   case let .invalidKey(keyType, reason):
///     // Handle invalid key error
///   case let .unsupportedAlgorithm(algorithm):
///     // Handle unsupported algorithm
///   case let .encryptionFailed(algorithm, reason):
///     // Handle encryption failure
///   default:
///     // Handle other crypto errors
///   }
/// }
/// ```
///
/// Use the `UmbraErrorMapper` to convert between domain-specific errors and public API errors:
/// ```swift
/// let publicError = UmbraErrorMapper.shared.mapCryptoError(cryptoError)
/// ```
extension UmbraErrors.Crypto {
  /// Core cryptography errors related to cryptographic operations
  public enum Core: Error, UmbraErrorsCore.UmbraError, StandardErrorCapabilitiesProtocol {
    // Encryption/Decryption errors
    /// Failed to encrypt data
    case encryptionFailed(algorithm: String, reason: String)

    /// Failed to decrypt data
    case decryptionFailed(algorithm: String, reason: String)

    /// Invalid or corrupted ciphertext
    case invalidCiphertext(reason: String)

    /// Padding validation failed during decryption
    case paddingValidationFailed(algorithm: String)

    // Key management errors
    /// Failed to generate cryptographic key
    case keyGenerationFailed(keyType: String, reason: String)

    /// Failed to derive key from password or other material
    case keyDerivationFailed(algorithm: String, reason: String)

    /// Key has invalid format or size
    case invalidKey(keyType: String, reason: String)

    /// Key not found
    case keyNotFound(keyIdentifier: String)

    // Signing/Verification errors
    /// Failed to sign data
    case signatureFailed(algorithm: String, reason: String)

    /// Signature verification failed
    case signatureVerificationFailed(algorithm: String, reason: String)

    /// Invalid signature format
    case invalidSignature(reason: String)

    // Hash/Digest errors
    /// Failed to compute hash
    case hashingFailed(algorithm: String, reason: String)

    /// Hash verification failed
    case hashVerificationFailed(algorithm: String)

    // Algorithm errors
    /// Cryptographic algorithm not supported
    case unsupportedAlgorithm(algorithm: String)

    /// Invalid algorithm parameters
    case invalidParameters(algorithm: String, parameter: String, reason: String)

    /// Incompatible algorithm parameters
    case incompatibleParameters(algorithm: String, parameter: String, reason: String)

    // Random number generation errors
    /// Failed to generate secure random data
    case randomGenerationFailed(reason: String)

    /// Insufficient entropy for secure operation
    case insufficientEntropy

    // Internal errors
    /// Internal cryptographic error
    case internalError(String)

    // MARK: - UmbraError Protocol

    /// Domain identifier for crypto core errors
    public var domain: String {
      "Crypto.Core"
    }

    /// Error code uniquely identifying the error type
    public var code: String {
      switch self {
        case .encryptionFailed:
          "encryption_failed"
        case .decryptionFailed:
          "decryption_failed"
        case .invalidCiphertext:
          "invalid_ciphertext"
        case .paddingValidationFailed:
          "padding_validation_failed"
        case .keyGenerationFailed:
          "key_generation_failed"
        case .keyDerivationFailed:
          "key_derivation_failed"
        case .invalidKey:
          "invalid_key"
        case .keyNotFound:
          "key_not_found"
        case .signatureFailed:
          "signature_failed"
        case .signatureVerificationFailed:
          "signature_verification_failed"
        case .invalidSignature:
          "invalid_signature"
        case .hashingFailed:
          "hashing_failed"
        case .hashVerificationFailed:
          "hash_verification_failed"
        case .unsupportedAlgorithm:
          "unsupported_algorithm"
        case .invalidParameters:
          "invalid_parameters"
        case .incompatibleParameters:
          "incompatible_parameters"
        case .randomGenerationFailed:
          "random_generation_failed"
        case .insufficientEntropy:
          "insufficient_entropy"
        case .internalError:
          "internal_error"
      }
    }

    /// Human-readable description of the error
    public var errorDescription: String {
      switch self {
        case let .encryptionFailed(algorithm, reason):
          "Failed to encrypt data with algorithm '\(algorithm)': \(reason)"
        case let .decryptionFailed(algorithm, reason):
          "Failed to decrypt data with algorithm '\(algorithm)': \(reason)"
        case let .invalidCiphertext(reason):
          "Invalid or corrupted ciphertext: \(reason)"
        case let .paddingValidationFailed(algorithm):
          "Padding validation failed during decryption with algorithm '\(algorithm)'"
        case let .keyGenerationFailed(keyType, reason):
          "Failed to generate cryptographic key of type '\(keyType)': \(reason)"
        case let .keyDerivationFailed(algorithm, reason):
          "Failed to derive key using algorithm '\(algorithm)': \(reason)"
        case let .invalidKey(keyType, reason):
          "Invalid cryptographic key of type '\(keyType)': \(reason)"
        case let .keyNotFound(keyIdentifier):
          "Cryptographic key not found: \(keyIdentifier)"
        case let .signatureFailed(algorithm, reason):
          "Failed to sign data with algorithm '\(algorithm)': \(reason)"
        case let .signatureVerificationFailed(algorithm, reason):
          "Signature verification failed with algorithm '\(algorithm)': \(reason)"
        case let .invalidSignature(reason):
          "Invalid signature format: \(reason)"
        case let .hashingFailed(algorithm, reason):
          "Failed to compute hash with algorithm '\(algorithm)': \(reason)"
        case let .hashVerificationFailed(algorithm):
          "Hash verification failed with algorithm '\(algorithm)'"
        case let .unsupportedAlgorithm(algorithm):
          "Cryptographic algorithm not supported: '\(algorithm)'"
        case let .invalidParameters(algorithm, parameter, reason):
          "Invalid parameter '\(parameter)' for algorithm '\(algorithm)': \(reason)"
        case let .incompatibleParameters(algorithm, parameter, reason):
          "Incompatible parameter '\(parameter)' for algorithm '\(algorithm)': \(reason)"
        case let .randomGenerationFailed(reason):
          "Failed to generate secure random data: \(reason)"
        case .insufficientEntropy:
          "Insufficient entropy for secure cryptographic operation"
        case let .internalError(message):
          "Internal cryptographic error: \(message)"
      }
    }

    /// Source information about where the error occurred
    public var source: UmbraErrorsCore.ErrorSource? {
      nil // Source is typically set when the error is created with context
    }

    /// The underlying error, if any
    public var underlyingError: Error? {
      nil // Underlying error is typically set when the error is created with context
    }

    /// Additional context for the error
    public var context: UmbraErrorsCore.ErrorContext {
      UmbraErrorsCore.ErrorContext(
        source: domain,
        operation: "crypto_operation",
        details: errorDescription
      )
    }

    /// Creates a new instance of the error with additional context
    public func with(context _: UmbraErrorsCore.ErrorContext) -> Self {
      // Since these are enum cases, we need to return a new instance with the same value
      switch self {
        case let .encryptionFailed(algorithm, reason):
          .encryptionFailed(algorithm: algorithm, reason: reason)
        case let .decryptionFailed(algorithm, reason):
          .decryptionFailed(algorithm: algorithm, reason: reason)
        case let .invalidCiphertext(reason):
          .invalidCiphertext(reason: reason)
        case let .paddingValidationFailed(algorithm):
          .paddingValidationFailed(algorithm: algorithm)
        case let .keyGenerationFailed(keyType, reason):
          .keyGenerationFailed(keyType: keyType, reason: reason)
        case let .keyDerivationFailed(algorithm, reason):
          .keyDerivationFailed(algorithm: algorithm, reason: reason)
        case let .invalidKey(keyType, reason):
          .invalidKey(keyType: keyType, reason: reason)
        case let .keyNotFound(keyIdentifier):
          .keyNotFound(keyIdentifier: keyIdentifier)
        case let .signatureFailed(algorithm, reason):
          .signatureFailed(algorithm: algorithm, reason: reason)
        case let .signatureVerificationFailed(algorithm, reason):
          .signatureVerificationFailed(algorithm: algorithm, reason: reason)
        case let .invalidSignature(reason):
          .invalidSignature(reason: reason)
        case let .hashingFailed(algorithm, reason):
          .hashingFailed(algorithm: algorithm, reason: reason)
        case let .hashVerificationFailed(algorithm):
          .hashVerificationFailed(algorithm: algorithm)
        case let .unsupportedAlgorithm(algorithm):
          .unsupportedAlgorithm(algorithm: algorithm)
        case let .invalidParameters(algorithm, parameter, reason):
          .invalidParameters(algorithm: algorithm, parameter: parameter, reason: reason)
        case let .incompatibleParameters(algorithm, parameter, reason):
          .incompatibleParameters(algorithm: algorithm, parameter: parameter, reason: reason)
        case let .randomGenerationFailed(reason):
          .randomGenerationFailed(reason: reason)
        case .insufficientEntropy:
          .insufficientEntropy
        case let .internalError(message):
          .internalError(message)
      }
      // In a real implementation, we would attach the context
    }

    /// Creates a new instance of the error with a specified underlying error
    public func with(underlyingError _: Error) -> Self {
      // Similar to above, return a new instance with the same value
      self // In a real implementation, we would attach the underlying error
    }

    /// Creates a new instance of the error with source information
    public func with(source: UmbraErrorsCore.ErrorSource) -> Self {
      // Similar to above, return a new instance with the same value
      self // In a real implementation, we would attach the source information
    }
  }
}

// MARK: - Factory Methods

extension UmbraErrors.Crypto.Core {
  /// Create an error for a failed encryption operation
  public static func makeEncryptionFailedError(
    algorithm: String,
    reason: String,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> Self {
    .encryptionFailed(algorithm: algorithm, reason: reason)
  }

  /// Create an error for a failed decryption operation
  public static func makeDecryptionFailedError(
    algorithm: String,
    reason: String,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> Self {
    .decryptionFailed(algorithm: algorithm, reason: reason)
  }

  /// Create an error for failed key generation
  public static func makeKeyGenerationFailedError(
    keyType: String,
    reason: String,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> Self {
    .keyGenerationFailed(keyType: keyType, reason: reason)
  }

  /// Create an error for an invalid key
  public static func makeInvalidKeyError(
    keyType: String,
    reason: String,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> Self {
    .invalidKey(keyType: keyType, reason: reason)
  }

  /// Create an error for a key that was not found
  public static func makeKeyNotFoundError(
    keyIdentifier: String,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> Self {
    .keyNotFound(keyIdentifier: keyIdentifier)
  }

  /// Create an error for an unsupported algorithm
  public static func makeUnsupportedAlgorithmError(
    algorithm: String,
    file _: String=#file,
    line _: Int=#line,
    function _: String=#function
  ) -> Self {
    .unsupportedAlgorithm(algorithm: algorithm)
  }
}
