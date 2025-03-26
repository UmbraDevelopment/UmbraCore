import UmbraCoreTypes

/// Enumeration of security operations that can be performed by a security provider
/// This enum serves as a type-safe way to request specific security operations
public enum SecurityOperation: String, Sendable, Equatable, CaseIterable {
  // MARK: - Cryptographic Operations

  /// Encrypt data using a symmetric key
  case encrypt

  /// Decrypt data using a symmetric key
  case decrypt

  /// Generate a cryptographic key
  case generateKey

  /// Calculate a cryptographic hash
  case hash

  /// Sign data with a private key
  case sign

  /// Verify a signature with a public key
  case verify

  // MARK: - Key Management Operations

  /// Store a key securely
  case storeKey

  /// Retrieve a key from secure storage
  case retrieveKey

  /// Delete a key from secure storage
  case deleteKey

  /// List available keys in secure storage
  case listKeys

  // MARK: - Random Data Operations

  /// Generate cryptographically secure random data
  case generateRandomData

  // MARK: - Swift 6 Compatibility

  /// Reserved for forward compatibility
  @available(*, unavailable, message: "This case exists only for Swift 6+ forward compatibility")
  case _unspecified

  /// All available cases, excluding unavailable cases
  public static var allCases: [SecurityOperation] {
    [
      .encrypt,
      .decrypt,
      .generateKey,
      .hash,
      .sign,
      .verify,
      .storeKey,
      .retrieveKey,
      .deleteKey,
      .listKeys,
      .generateRandomData
    ]
  }
}
