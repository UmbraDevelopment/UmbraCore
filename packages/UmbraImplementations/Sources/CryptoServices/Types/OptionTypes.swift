import Foundation
import CoreSecurityTypes
import UnifiedCryptoTypes

/**
 Local module option types for encryption, decryption, hashing, and key generation.
 These types mirror the ones in SecurityCoreInterfaces to provide type-safe conversions.
 
 NOTE: These types are being deprecated in favor of the unified types defined in UnifiedCryptoTypes.
 New code should use the types from UnifiedCryptoTypes instead.
 */

/**
 Encryption algorithm options available in this module.
 
 DEPRECATED: Use UnifiedCryptoTypes.EncryptionAlgorithm instead.
 */
@available(*, deprecated, message: "Use UnifiedCryptoTypes.EncryptionAlgorithm instead")
public typealias LocalEncryptionAlgorithm = UnifiedCryptoTypes.EncryptionAlgorithm

/**
 Encryption mode options available in this module.
 */
public enum EncryptionMode: String, Sendable {
  case cbc="CBC"
  case gcm="GCM"
}

/**
 Encryption padding options available in this module.
 */
public enum EncryptionPadding: String, Sendable {
  case none="None"
  case pkcs7="PKCS7"
}

/**
 Options for configuring encryption operations.
 
 DEPRECATED: Use UnifiedCryptoTypes.EncryptionOptions instead.
 */
@available(*, deprecated, message: "Use UnifiedCryptoTypes.EncryptionOptions instead")
public struct LocalEncryptionOptions: Sendable {
  /// The encryption algorithm to use
  public let algorithm: UnifiedCryptoTypes.EncryptionAlgorithm

  /// The encryption mode to use
  public let mode: EncryptionMode

  /// The padding scheme to use
  public let padding: EncryptionPadding

  /// Additional authenticated data for authenticated encryption modes
  public let additionalAuthenticatedData: [UInt8]?

  /**
   Creates a new set of encryption options.

   - Parameters:
      - algorithm: The encryption algorithm to use
      - mode: The encryption mode to use
      - padding: The padding scheme to use
      - additionalAuthenticatedData: Additional data to authenticate (for GCM)
   */
  public init(
    algorithm: UnifiedCryptoTypes.EncryptionAlgorithm = .aes256GCM,
    mode: EncryptionMode = .gcm,
    padding: EncryptionPadding = .pkcs7,
    additionalAuthenticatedData: [UInt8]?=nil
  ) {
    self.algorithm = algorithm
    self.mode = mode
    self.padding = padding
    self.additionalAuthenticatedData = additionalAuthenticatedData
  }
}

/**
 Options for configuring decryption operations.
 Uses the same type parameters as encryption for consistency.
 
 DEPRECATED: Use UnifiedCryptoTypes.EncryptionOptions for decryption as well.
 */
@available(*, deprecated, message: "Use UnifiedCryptoTypes.EncryptionOptions instead")
public typealias LocalDecryptionOptions = LocalEncryptionOptions

/**
 Hashing algorithm options available in this module.
 
 DEPRECATED: Use CoreSecurityTypes.HashAlgorithm instead.
 */
@available(*, deprecated, message: "Use CoreSecurityTypes.HashAlgorithm instead")
public typealias LocalHashingAlgorithm = CoreSecurityTypes.HashAlgorithm

/**
 Options for configuring hashing operations.
 
 DEPRECATED: Use UnifiedCryptoTypes.HashingOptions instead.
 */
@available(*, deprecated, message: "Use UnifiedCryptoTypes.HashingOptions instead")
public struct LocalHashingOptions: Sendable {
  /// The hashing algorithm to use
  public let algorithm: CoreSecurityTypes.HashAlgorithm

  /// Optional salt to use in hashing
  public let salt: [UInt8]?

  /**
   Creates a new set of hashing options.

   - Parameters:
      - algorithm: The hashing algorithm to use
      - salt: Optional salt for the hash
   */
  public init(
    algorithm: CoreSecurityTypes.HashAlgorithm = .sha256,
    salt: [UInt8]?=nil
  ) {
    self.algorithm = algorithm
    self.salt = salt
  }
}

// Provide clean migration path with type aliases to the canonical types
public typealias EncryptionAlgorithm = UnifiedCryptoTypes.EncryptionAlgorithm
public typealias EncryptionOptions = UnifiedCryptoTypes.EncryptionOptions
public typealias DecryptionOptions = UnifiedCryptoTypes.EncryptionOptions  // Same options used for both
public typealias HashingAlgorithm = CoreSecurityTypes.HashAlgorithm
public typealias HashingOptions = UnifiedCryptoTypes.HashingOptions

/**
 Key type options available in this module.
 */
public enum KeyType: String, Sendable {
  case symmetric="Symmetric"
  case asymmetric="Asymmetric"
}

/**
 Options for configuring key generation operations.
 */
public struct KeyGenerationOptions: Sendable {
  /// The type of key to generate
  public let keyType: KeyType

  /// Whether to use secure enclave for storage (Apple platforms only)
  public let useSecureEnclave: Bool

  /// Optional custom identifier for the key
  public let customIdentifier: String?

  /**
   Creates a new set of key generation options.

   - Parameters:
      - keyType: The type of key to generate
      - useSecureEnclave: Whether to use secure enclave
      - customIdentifier: Optional custom identifier
   */
  public init(
    keyType: KeyType = .symmetric,
    useSecureEnclave: Bool=false,
    customIdentifier: String?=nil
  ) {
    self.keyType=keyType
    self.useSecureEnclave=useSecureEnclave
    self.customIdentifier=customIdentifier
  }
}
