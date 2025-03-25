import Foundation
import UmbraCoreTypes
import UmbraErrors

/**
 # CryptoError

 Defines the error types specific to cryptographic operations.

 ## Responsibilities

 * Provide specific error types for cryptographic operations
 * Ensure consistent error handling across the cryptographic services
 */

/// Error type for cryptographic operations in Security Implementation
public enum CryptoError: Error, Equatable, Sendable {
  /// Error during encryption operation
  case encryptionError(reason: String)

  /// Error during decryption operation
  case decryptionError(reason: String)

  /// Error during hashing operation
  case hashingError(reason: String)

  /// Error during key generation
  case keyGenerationError(reason: String)

  /// Error during key derivation
  case keyDerivationFailed(reason: String)

  /// Error for invalid key size
  case invalidKeySize(size: Int)

  /// Error for invalid key format
  case invalidKeyFormat(reason: String)

  /// Error for invalid parameters
  case invalidParameters(reason: String)

  /// Error for algorithm not supported
  case algorithmNotSupported(algorithm: String)

  /// Error for asymmetric encryption
  case asymmetricEncryptionError(String)

  /// Error for asymmetric decryption
  case asymmetricDecryptionError(String)

  /// Error for symmetric encryption
  case symmetricEncryptionError(String)

  /// Error for symmetric decryption
  case symmetricDecryptionError(String)

  /// Error for invalid key identifier
  case invalidKeyIdentifier(String)

  /// Error for invalid nonce/IV
  case invalidNonce(String)
  
  /// Error for authentication failure
  case authenticationFailed(String)
  
  /// General internal failure
  case internalError(String)
}
