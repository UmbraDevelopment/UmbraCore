import Foundation
import UmbraErrorsCore

/// Domain identifier for crypto errors
public enum CryptoErrorDomain: String, CaseIterable, Sendable {
  /// Domain identifier
  public static let domain="Crypto"

  // Error codes within the crypto domain
  case encryptionFailed="ENCRYPTION_FAILED"
  case decryptionFailed="DECRYPTION_FAILED"
  case signatureFailed="SIGNATURE_FAILED"
  case verificationFailed="VERIFICATION_FAILED"
  case keyGenerationFailed="KEY_GENERATION_FAILED"
  case keyDerivationFailed="KEY_DERIVATION_FAILED"
  case algorithmNotSupported="ALGORITHM_NOT_SUPPORTED"
  case invalidParameters="INVALID_PARAMETERS"
  case invalidKeyData="INVALID_KEY_DATA"
  case invalidKey="INVALID_KEY"
  case invalidInput="INVALID_INPUT"
  case hashFailed="HASH_FAILED"
  case dataCorrupted="DATA_CORRUPTED"
  case randomDataGenerationFailed="RANDOM_DATA_GENERATION_FAILED"
  case osError="OS_ERROR"
  case internalError="INTERNAL_ERROR"
  case unspecified="UNSPECIFIED"
}
