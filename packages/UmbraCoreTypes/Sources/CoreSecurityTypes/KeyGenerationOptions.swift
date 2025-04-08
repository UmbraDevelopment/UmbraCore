import Foundation

/**
 * Options for cryptographic key generation operations.
 *
 * This type encapsulates various parameters that can be used to
 * customise key generation operations.
 */
public struct KeyGenerationOptions: Sendable, Equatable {
  /// Type of key to generate
  public let keyType: KeyType

  /// Purpose for which the key will be used
  public let purpose: KeyPurpose

  /// Whether the key should be exportable
  public let exportable: Bool

  /// Optional metadata to associate with the key
  public let metadata: [String: String]?

  /**
   * Creates new key generation options.
   *
   * - Parameters:
   *   - keyType: Type of key to generate
   *   - purpose: Purpose for which the key will be used
   *   - exportable: Whether the key should be exportable
   *   - metadata: Optional metadata to associate with the key
   */
  public init(
    keyType: KeyType = .symmetric,
    purpose: KeyPurpose = .encryption,
    exportable: Bool=false,
    metadata: [String: String]?=nil
  ) {
    self.keyType=keyType
    self.purpose=purpose
    self.exportable=exportable
    self.metadata=metadata
  }

  /// Default options for symmetric encryption key
  public static let `default`=KeyGenerationOptions()

  /// Options for generating an RSA key pair
  public static let rsaKeyPair=KeyGenerationOptions(
    keyType: .asymmetric(.rsa),
    purpose: .encryption,
    exportable: false
  )

  /// Options for generating an ECC key pair
  public static let eccKeyPair=KeyGenerationOptions(
    keyType: .asymmetric(.ecc),
    purpose: .signing,
    exportable: false
  )

  /// Options for generating a signing key
  public static let signingKey=KeyGenerationOptions(
    keyType: .symmetric,
    purpose: .signing,
    exportable: false
  )
}

/**
 * Types of cryptographic keys.
 */
public enum KeyType: Sendable, Equatable {
  /// Symmetric key (same key for encryption and decryption)
  case symmetric

  /// Asymmetric key pair (public and private keys)
  case asymmetric(AsymmetricAlgorithm)

  /// Derived key (derived from another key or password)
  case derived(KeyDerivationMethod)
}

/**
 * Asymmetric cryptography algorithms.
 */
public enum AsymmetricAlgorithm: String, Sendable, Equatable, CaseIterable {
  /// RSA (Rivest-Shamir-Adleman)
  case rsa

  /// ECC (Elliptic Curve Cryptography)
  case ecc

  /// DSA (Digital Signature Algorithm)
  case dsa
}

/**
 * Methods for deriving cryptographic keys.
 */
public enum KeyDerivationMethod: String, Sendable, Equatable, CaseIterable {
  /// PBKDF2 (Password-Based Key Derivation Function 2)
  case pbkdf2

  /// HKDF (HMAC-based Key Derivation Function)
  case hkdf

  /// Argon2 password hashing
  case argon2
}

/**
 * Purposes for which a cryptographic key can be used.
 */
public enum KeyPurpose: String, Sendable, Equatable, CaseIterable {
  /// Key for encryption/decryption operations
  case encryption

  /// Key for digital signature operations
  case signing

  /// Key for key wrapping (encrypting other keys)
  case keyWrapping

  /// Key for key agreement protocols
  case keyAgreement

  /// Key for message authentication codes
  case mac
}
