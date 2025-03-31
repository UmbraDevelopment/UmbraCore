import UmbraCoreTypes

/// FoundationIndependent representation of security operations.
/// Defines the possible security operations that can be performed.
public enum SecurityOperation: String, Sendable, Equatable, CaseIterable {
  // MARK: - Cryptographic Operations

  /// Symmetric encryption
  case symmetricEncryption

  /// Symmetric decryption
  case symmetricDecryption

  /// Asymmetric encryption
  case asymmetricEncryption

  /// Asymmetric decryption
  case asymmetricDecryption

  /// Hash generation
  case hashing

  /// Message authentication code generation
  case macGeneration

  // MARK: - Key Management Operations

  /// Key generation
  case keyGeneration

  /// Key storage
  case keyStorage

  /// Key retrieval
  case keyRetrieval

  /// Key rotation
  case keyRotation

  /// Key deletion
  case keyDeletion

  // MARK: - Special Operations

  /// Secure random number generation
  case randomGeneration

  /// Digital signature generation
  case signatureGeneration

  /// Digital signature verification
  case signatureVerification
}
