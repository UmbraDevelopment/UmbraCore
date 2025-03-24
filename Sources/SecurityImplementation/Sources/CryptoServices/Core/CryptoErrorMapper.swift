import ErrorHandlingCore
import ErrorHandlingDomains
import ErrorHandlingInterfaces
import ErrorHandlingMapping
import Foundation

/// Provides mapping functions between SecurityImplementation's CryptoError and
/// UmbraErrors.Crypto.Core
///
/// This mapper facilitates the transition from the implementation-specific CryptoError type to the
/// canonical UmbraErrors.Crypto.Core type. It ensures consistent error handling
/// across the codebase.
public enum CryptoErrorMapper {
  /// Maps from SecurityImplementation's CryptoError to canonical UmbraErrors.Crypto.Core
  ///
  /// - Parameter error: Implementation-specific CryptoError to map
  /// - Returns: Equivalent UmbraErrors.Crypto.Core instance
  public static func mapToCanonicalError(_ error: CryptoError) -> UmbraErrors.Crypto.Core {
    switch error {
      case let .encryptionError(reason):
        .encryptionFailed(
          algorithm: "unknown",
          reason: reason
        )

      case let .decryptionError(reason):
        .decryptionFailed(
          algorithm: "unknown",
          reason: reason
        )

      case let .hashingError(reason):
        .hashingFailed(
          algorithm: "unknown",
          reason: reason
        )

      case let .keyGenerationError(reason):
        .keyGenerationFailed(
          keyType: "unknown",
          reason: reason
        )

      case let .keyDerivationFailed(reason):
        .keyDerivationFailed(
          algorithm: "unknown",
          reason: reason
        )

      case let .invalidKeySize(size):
        .invalidParameters(
          algorithm: "unknown",
          parameter: "keySize",
          reason: "Invalid key size: \(size)"
        )

      case let .invalidLength(length):
        .invalidParameters(
          algorithm: "unknown",
          parameter: "length",
          reason: "Invalid data length: \(length)"
        )

      case let .unsupportedAlgorithm(algorithm):
        .unsupportedAlgorithm(
          algorithm: algorithm
        )

      case let .asymmetricEncryptionError(reason):
        .encryptionFailed(
          algorithm: "asymmetric",
          reason: reason
        )

      case let .asymmetricDecryptionError(reason):
        .decryptionFailed(
          algorithm: "asymmetric",
          reason: reason
        )

      case let .randomGenerationFailed(status):
        .randomGenerationFailed(
          reason: "Random number generation failed with status: \(status)"
        )

      // Add catch-all to handle all other CoreErrors.CryptoError cases
      default:
        .internalError(
          "Unmapped crypto error: \(error.localizedDescription)"
        )
    }
  }

  /// Maps from canonical UmbraErrors.Crypto.Core to legacy CoreErrors.CryptoError
  ///
  /// Note: This mapping is lossy as the canonical error type has more specific cases than the
  /// implementation-specific type.
  /// It should be used only where compatibility with the implementation-specific type is required.
  ///
  /// - Parameter error: Canonical UmbraErrors.Crypto.Core error to map
  /// - Returns: Best-fit equivalent CryptoError instance for the SecurityImplementation module
  public static func mapToImplementationError(_ error: UmbraErrors.Crypto.Core) -> CryptoError {
    switch error {
      case let .encryptionFailed(algorithm, reason):
        if algorithm.contains("asymmetric") {
          return .asymmetricEncryptionError(reason)
        } else {
          return .encryptionError(reason)
        }

      case let .decryptionFailed(algorithm, reason):
        if algorithm.contains("asymmetric") {
          return .asymmetricDecryptionError(reason)
        } else {
          return .decryptionError(reason)
        }

      case let .invalidCiphertext(reason):
        return .decryptionError("Invalid ciphertext: \(reason)")

      case let .paddingValidationFailed(algorithm):
        return .decryptionError("Padding validation failed with \(algorithm)")

      case let .keyGenerationFailed(keyType, reason):
        return .keyGenerationError(reason: "\(keyType): \(reason)")

      case let .keyDerivationFailed(algorithm, reason):
        return .keyDerivationFailed(reason: "\(algorithm): \(reason)")

      case let .invalidKey(keyType, reason):
        return .invalidKey(reason: "Invalid key of type \(keyType): \(reason)")

      case .keyNotFound:
        return .keyGenerationError(reason: "Key not found")

      case let .signatureFailed(_, reason),
           let .signatureVerificationFailed(_, reason):
        return .signatureError(reason: "Signature operation failed: \(reason)")

      case let .invalidSignature(reason):
        return .signatureError(reason: "Invalid signature: \(reason)")

      case let .hashingFailed(algorithm, reason):
        return .hashingError("Hashing failed with \(algorithm): \(reason)")

      case let .hashVerificationFailed(algorithm):
        return .hashingError("Hash verification failed with \(algorithm)")

      case let .unsupportedAlgorithm(algorithm):
        return .unsupportedAlgorithm(algorithm)

      case let .invalidParameters(algorithm, parameter, reason):
        if parameter == "keySize" {
          return .invalidKeySize(reason: "\(algorithm): \(reason)")
        } else if parameter == "length" {
          return .invalidLength(0) // Cannot extract specific length from reason
        } else {
          return .invalidParameters(reason: "\(parameter) for \(algorithm): \(reason)")
        }

      case let .incompatibleParameters(algorithm, parameter, reason):
        return .invalidParameters(reason: "Incompatible \(parameter) for \(algorithm): \(reason)")

      case .randomGenerationFailed:
        return .randomGenerationFailed(status: 0) // Cannot convert string reason to OSStatus

      case .insufficientEntropy:
        return .randomGenerationFailed(status: -1)

      case let .internalError(description):
        return .encryptionError("Internal error: \(description)")

      @unknown default:
        return .encryptionError("Unmapped crypto error: \(error.localizedDescription)")
    }
  }
}

extension CryptoError {
  /// Converts this implementation-specific CryptoError to the canonical UmbraErrors.Crypto.Core
  /// type
  ///
  /// - Returns: Canonical error type for use with UmbraCore error handling
  public func toCanonical() -> UmbraErrors.Crypto.Core {
    CryptoErrorMapper.mapToCanonicalError(self)
  }
}

extension UmbraErrors.Crypto.Core {
  /// Converts a canonical Crypto.Core error to implementation-specific CryptoError
  ///
  /// Note: This is lossy conversion and should only be used where necessary.
  ///
  /// - Returns: Best-fit equivalent CryptoError instance for the SecurityImplementation module
  public func toImplementation() -> CryptoError {
    CryptoErrorMapper.mapToImplementationError(self)
  }
}
