import CoreSecurityTypes
import Foundation

/**
 Error types for security provider operations.

 These errors represent the various failure modes that can occur during
 cryptographic operations and are consistently used across all security provider
 implementations to ensure uniform error handling.
 */
public enum SecurityProviderError: Error, Sendable, Equatable {
  /// Invalid key size for the requested operation
  case invalidKeySize(expected: Int, actual: Int)

  /// Invalid initialization vector size for the requested operation
  case invalidIVSize(expected: Int, actual: Int)

  /// Encryption operation failed
  case encryptionFailed(String)

  /// Decryption operation failed
  case decryptionFailed(String)

  /// Hashing operation failed
  case hashingFailed(String)

  /// Digital signature operation failed
  case signingFailed(String)

  /// Signature verification failed
  case verificationFailed(String)

  /// Random number generation failed
  case randomGenerationFailed(String)

  /// Key generation failed
  case keyGenerationFailed(String)

  /// Algorithm not supported by this provider
  case unsupportedAlgorithm(CoreSecurityTypes.EncryptionAlgorithm)

  /// Provider configuration error
  case configurationError(String)

  /// Internal error in the provider
  case internalError(String)
  
  /// Failed to create a cryptor instance
  case cryptorCreationFailed(Int32)
  
  /// Failed to process additional authenticated data (AAD)
  case aadProcessingFailed(Int32)
  
  /// Encryption finalisation failed
  case encryptionFinalisationFailed(Int32)
  
  /// Authentication tag generation failed
  case authenticationTagGenerationFailed(Int32)
  
  /// The data format is invalid (e.g., missing tag)
  case invalidDataFormat
  
  /// Decryption finalisation failed
  case decryptionFinalisationFailed(Int32)
  
  /// Authentication tag verification failed
  case authenticationTagVerificationFailed(Int32)
  
  /// Authentication tag does not match expected value
  case authenticationTagMismatch
  
  /// Key derivation failed
  case keyDerivationFailed(Int32)
  
  /// Unable to convert between types
  case conversionError(String)

  // MARK: - Equatable Implementation

  public static func == (lhs: SecurityProviderError, rhs: SecurityProviderError) -> Bool {
    switch (lhs, rhs) {
      case (.invalidKeySize(let lhsExpected, let lhsActual), .invalidKeySize(let rhsExpected, let rhsActual)):
        return lhsExpected == rhsExpected && lhsActual == rhsActual
      case (.invalidIVSize(let lhsExpected, let lhsActual), .invalidIVSize(let rhsExpected, let rhsActual)):
        return lhsExpected == rhsExpected && lhsActual == rhsActual
      case (.encryptionFailed(let lhsMessage), .encryptionFailed(let rhsMessage)):
        return lhsMessage == rhsMessage
      case (.decryptionFailed(let lhsMessage), .decryptionFailed(let rhsMessage)):
        return lhsMessage == rhsMessage
      case (.hashingFailed(let lhsMessage), .hashingFailed(let rhsMessage)):
        return lhsMessage == rhsMessage
      case (.signingFailed(let lhsMessage), .signingFailed(let rhsMessage)):
        return lhsMessage == rhsMessage
      case (.verificationFailed(let lhsMessage), .verificationFailed(let rhsMessage)):
        return lhsMessage == rhsMessage
      case (.randomGenerationFailed(let lhsMessage), .randomGenerationFailed(let rhsMessage)):
        return lhsMessage == rhsMessage
      case (.keyGenerationFailed(let lhsMessage), .keyGenerationFailed(let rhsMessage)):
        return lhsMessage == rhsMessage
      case (.unsupportedAlgorithm(let lhsAlgo), .unsupportedAlgorithm(let rhsAlgo)):
        return lhsAlgo == rhsAlgo
      case (.configurationError(let lhsMessage), .configurationError(let rhsMessage)):
        return lhsMessage == rhsMessage
      case (.internalError(let lhsMessage), .internalError(let rhsMessage)):
        return lhsMessage == rhsMessage
      case (.cryptorCreationFailed(let lhsStatus), .cryptorCreationFailed(let rhsStatus)):
        return lhsStatus == rhsStatus
      case (.aadProcessingFailed(let lhsStatus), .aadProcessingFailed(let rhsStatus)):
        return lhsStatus == rhsStatus
      case (.encryptionFinalisationFailed(let lhsStatus), .encryptionFinalisationFailed(let rhsStatus)):
        return lhsStatus == rhsStatus
      case (.authenticationTagGenerationFailed(let lhsStatus), .authenticationTagGenerationFailed(let rhsStatus)):
        return lhsStatus == rhsStatus
      case (.invalidDataFormat, .invalidDataFormat):
        return true
      case (.decryptionFinalisationFailed(let lhsStatus), .decryptionFinalisationFailed(let rhsStatus)):
        return lhsStatus == rhsStatus
      case (.authenticationTagVerificationFailed(let lhsStatus), .authenticationTagVerificationFailed(let rhsStatus)):
        return lhsStatus == rhsStatus
      case (.authenticationTagMismatch, .authenticationTagMismatch):
        return true
      case (.keyDerivationFailed(let lhsStatus), .keyDerivationFailed(let rhsStatus)):
        return lhsStatus == rhsStatus
      case (.conversionError(let lhsMessage), .conversionError(let rhsMessage)):
        return lhsMessage == rhsMessage
      default:
        return false
    }
  }
}
