import Foundation
import CoreSecurityTypes

/**
 Local module option types for encryption, decryption, hashing, and key generation.
 These types mirror the ones in SecurityCoreInterfaces to provide type-safe conversions.
 
 NOTE: These types are being deprecated in favor of using the native types from CoreSecurityTypes directly.
 */

/**
 Encryption mode options available in this module.
 */
public enum EncryptionMode: String, Sendable {
  case cbc="CBC"
  case gcm="GCM"
}

/**
 Key type options available in this module.
 */
public enum KeyType: String, Sendable {
  case aes="AES"
  case rsa="RSA"
  case ec="EC"
}

/**
 Options for configuring encryption operations.
 */
public struct LocalEncryptionOptions: Sendable {
  /// The encryption algorithm to use
  public let algorithm: CoreSecurityTypes.EncryptionAlgorithm

  /// The encryption mode to use (if applicable for the algorithm)
  public let mode: EncryptionMode

  /// The encryption padding to use
  public let padding: PaddingMode

  /// Additional authenticated data for authenticated encryption modes
  public let additionalAuthenticatedData: [UInt8]?

  /**
   Creates a new instance with the specified options
   
   - Parameters:
     - algorithm: The encryption algorithm to use
     - mode: The encryption mode to use
     - padding: The encryption padding to use
     - additionalAuthenticatedData: Additional authenticated data for AEAD modes
   */
  public init(
    algorithm: CoreSecurityTypes.EncryptionAlgorithm = .aes256GCM,
    mode: EncryptionMode = .gcm,
    padding: PaddingMode = .pkcs7,
    additionalAuthenticatedData: [UInt8]?=nil
  ) {
    self.algorithm=algorithm
    self.mode=mode
    self.padding=padding
    self.additionalAuthenticatedData=additionalAuthenticatedData
  }
}

/**
 Options for configuring decryption operations.
 Uses the same type parameters as encryption for consistency.
 */
public typealias LocalDecryptionOptions = LocalEncryptionOptions

/**
 Options for configuring hashing operations.
 */
public struct LocalHashingOptions: Sendable {
  /// The hashing algorithm to use
  public let algorithm: CoreSecurityTypes.HashAlgorithm

  /// Whether to include extra salt for the hash
  public let useSalt: Bool

  /// Whether to base64 encode the output
  public let base64Encode: Bool

  /**
   Initialize a new hashing options struct with the given parameters.

   - Parameters:
      - algorithm: The hashing algorithm to use
      - useSalt: Whether to include salt for the hash
      - base64Encode: Whether to base64 encode the output
   */
  public init(
    algorithm: CoreSecurityTypes.HashAlgorithm = .sha256,
    useSalt: Bool = true,
    base64Encode: Bool = true
  ) {
    self.algorithm=algorithm
    self.useSalt=useSalt
    self.base64Encode=base64Encode
  }
}

/**
 A sendable wrapper for a dictionary of options
 */
public struct SendableOptionsDictionary: Sendable {
  /// The underlying dictionary
  public let dictionary: [String: Any]
  
  /**
   Initialize with the specified dictionary
   
   - Parameter dictionary: The dictionary to wrap
   */
  public init(dictionary: [String: Any]) {
    self.dictionary = dictionary
  }
}

/**
 Options for configuring key generation operations.
 */
public struct KeyGenerationOptions: Sendable {
  /// The type of key to generate
  public let keyType: KeyType

  /// Whether to use secure enclave for storage (Apple platforms only)
  public let useSecureEnclave: Bool

  /// Whether the key is extractable
  public let isExtractable: Bool

  /// Additional options for key generation
  public let options: SendableOptionsDictionary?

  /**
   Initialize a new key generation options struct with the given parameters.

   - Parameters:
      - keyType: The type of key to generate
      - useSecureEnclave: Whether to use secure enclave
      - isExtractable: Whether the key can be extracted
      - options: Additional options for key generation
   */
  public init(
    keyType: KeyType = .aes,
    useSecureEnclave: Bool = false,
    isExtractable: Bool = true,
    options: [String: Any]? = nil
  ) {
    self.keyType=keyType
    self.useSecureEnclave=useSecureEnclave
    self.isExtractable=isExtractable
    self.options=options.map { SendableOptionsDictionary(dictionary: $0) }
  }
}

// Type aliases for cleaner migration paths
// public typealias EncryptionAlgorithm = CoreSecurityTypes.EncryptionAlgorithm
