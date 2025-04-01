/**
 # Security API Operations

 Defines operations related to security, key management, and encryption/decryption
 in the Umbra system. These operations follow the Alpha Dot Five architecture principles
 with strict typing, clear domain boundaries, and privacy-aware logging integration.
 */

import DomainSecurityTypes
import Foundation

/**
 Base protocol for all security-related API operations.
 */
public protocol SecurityAPIOperation: DomainAPIOperation {}

/// Default domain for security operations
extension SecurityAPIOperation {
  public static var domain: APIDomain {
    .security
  }
}

/**
 Operation to encrypt data with a specified key or using a system-generated key.
 */
public struct EncryptDataOperation: SecurityAPIOperation {
  /// The operation result type
  public typealias ResultType=EncryptionResult

  /// Data to encrypt
  public let data: SendableCryptoMaterial

  /// Optional encryption key - if not provided, a system key will be used or generated
  public let key: SendableCryptoMaterial?

  /// Optional algorithm to use (defaults to system default)
  public let algorithm: String?

  /// Whether to store the encryption key in the keychain for later use
  public let storeKey: Bool

  /// Optional key identifier if storeKey is true
  public let keyIdentifier: String?

  /**
   Initialises a new encrypt data operation.

   - Parameters:
      - data: Data to encrypt
      - key: Optional encryption key
      - algorithm: Optional encryption algorithm
      - storeKey: Whether to store the key
      - keyIdentifier: Optional key identifier
   */
  public init(
    data: SendableCryptoMaterial,
    key: SendableCryptoMaterial?=nil,
    algorithm: String?=nil,
    storeKey: Bool=false,
    keyIdentifier: String?=nil
  ) {
    self.data=data
    self.key=key
    self.algorithm=algorithm
    self.storeKey=storeKey
    self.keyIdentifier=keyIdentifier
  }
}

/**
 Operation to decrypt data with a specified key or using a stored key.
 */
public struct DecryptDataOperation: SecurityAPIOperation {
  /// The operation result type
  public typealias ResultType=SendableCryptoMaterial

  /// Encrypted data to decrypt
  public let data: SendableCryptoMaterial

  /// Optional decryption key - if not provided, the system will attempt to retrieve a stored key
  public let key: SendableCryptoMaterial?

  /// Optional key identifier to retrieve a stored key
  public let keyIdentifier: String?

  /**
   Initialises a new decrypt data operation.

   - Parameters:
      - data: Encrypted data to decrypt
      - key: Optional decryption key
      - keyIdentifier: Optional key identifier for a stored key
   */
  public init(
    data: SendableCryptoMaterial,
    key: SendableCryptoMaterial?=nil,
    keyIdentifier: String?=nil
  ) {
    self.data=data
    self.key=key
    self.keyIdentifier=keyIdentifier
  }
}

/**
 Operation to generate a cryptographic key.
 */
public struct GenerateKeyOperation: SecurityAPIOperation {
  /// The operation result type
  public typealias ResultType=KeyGenerationResult

  /// Key size in bits
  public let keySizeInBits: Int

  /// Key type to generate
  public let keyType: KeyType

  /// Whether to store the generated key
  public let storeKey: Bool

  /// Optional key identifier for storing the key
  public let keyIdentifier: String?

  /**
   Initialises a new generate key operation.

   - Parameters:
      - keySizeInBits: Key size in bits
      - keyType: Type of key to generate
      - storeKey: Whether to store the key
      - keyIdentifier: Optional key identifier
   */
  public init(
    keySizeInBits: Int=256,
    keyType: KeyType = .symmetric,
    storeKey: Bool=false,
    keyIdentifier: String?=nil
  ) {
    self.keySizeInBits=keySizeInBits
    self.keyType=keyType
    self.storeKey=storeKey
    self.keyIdentifier=keyIdentifier
  }
}

/**
 Operation to retrieve a stored key.
 */
public struct RetrieveKeyOperation: SecurityAPIOperation {
  /// The operation result type
  public typealias ResultType=SendableCryptoMaterial

  /// Key identifier
  public let keyIdentifier: String

  /**
   Initialises a new retrieve key operation.

   - Parameter keyIdentifier: Key identifier
   */
  public init(keyIdentifier: String) {
    self.keyIdentifier=keyIdentifier
  }
}

/**
 Operation to delete a stored key.
 */
public struct DeleteKeyOperation: SecurityAPIOperation {
  /// The operation result type
  public typealias ResultType=Void

  /// Key identifier
  public let keyIdentifier: String

  /**
   Initialises a new delete key operation.

   - Parameter keyIdentifier: Key identifier
   */
  public init(keyIdentifier: String) {
    self.keyIdentifier=keyIdentifier
  }
}

/**
 Operation to compute a hash of data.
 */
public struct HashDataOperation: SecurityAPIOperation {
  /// The operation result type
  public typealias ResultType=SendableCryptoMaterial

  /// Data to hash
  public let data: SendableCryptoMaterial

  /// Hash algorithm to use
  public let algorithm: HashAlgorithm

  /**
   Initialises a new hash data operation.

   - Parameters:
      - data: Data to hash
      - algorithm: Hashing algorithm to use
   */
  public init(
    data: SendableCryptoMaterial,
    algorithm: HashAlgorithm = .sha256
  ) {
    self.data=data
    self.algorithm=algorithm
  }
}

/**
 Operation to store a secret in the system keychain.
 */
public struct StoreSecretOperation: SecurityAPIOperation {
  /// The operation result type
  public typealias ResultType=Void

  /// Secret to store
  public let secret: SendableCryptoMaterial

  /// Account identifier
  public let account: String

  /// Whether to encrypt the secret before storing
  public let encrypt: Bool

  /**
   Initialises a new store secret operation.

   - Parameters:
      - secret: Secret data to store
      - account: Account identifier
      - encrypt: Whether to encrypt the secret first
   */
  public init(
    secret: SendableCryptoMaterial,
    account: String,
    encrypt: Bool=true
  ) {
    self.secret=secret
    self.account=account
    self.encrypt=encrypt
  }
}

/**
 Operation to retrieve a secret from the system keychain.
 */
public struct RetrieveSecretOperation: SecurityAPIOperation {
  /// The operation result type
  public typealias ResultType=SendableCryptoMaterial

  /// Account identifier
  public let account: String

  /**
   Initialises a new retrieve secret operation.

   - Parameter account: Account identifier
   */
  public init(account: String) {
    self.account=account
  }
}

/**
 Operation to delete a secret from the system keychain.
 */
public struct DeleteSecretOperation: SecurityAPIOperation {
  /// The operation result type
  public typealias ResultType=Void

  /// Account identifier
  public let account: String

  /**
   Initialises a new delete secret operation.

   - Parameter account: Account identifier
   */
  public init(account: String) {
    self.account=account
  }
}

/**
 Operation to generate a random number.
 */
public struct GenerateRandomOperation: SecurityAPIOperation {
  /// The operation result type
  public typealias ResultType=Int

  /// Minimum value (inclusive)
  public let min: Int

  /// Maximum value (inclusive)
  public let max: Int

  /**
   Initialises a new generate random operation.

   - Parameters:
      - min: Minimum value (inclusive)
      - max: Maximum value (inclusive)
   */
  public init(min: Int, max: Int) {
    self.min=min
    self.max=max
  }
}

/**
 Result of an encryption operation.
 */
public struct EncryptionResult: Sendable {
  /// Encrypted data
  public let encryptedData: SendableCryptoMaterial

  /// Key identifier if the key was stored
  public let keyIdentifier: String?

  /**
   Initialises a new encryption result.

   - Parameters:
      - encryptedData: The encrypted data
      - keyIdentifier: Optional identifier for the stored key
   */
  public init(
    encryptedData: SendableCryptoMaterial,
    keyIdentifier: String?=nil
  ) {
    self.encryptedData=encryptedData
    self.keyIdentifier=keyIdentifier
  }
}

/**
 Result of a key generation operation.
 */
public struct KeyGenerationResult: Sendable {
  /// Generated key
  public let key: SendableCryptoMaterial

  /// Key identifier if the key was stored
  public let keyIdentifier: String?

  /**
   Initialises a new key generation result.

   - Parameters:
      - key: The generated key
      - keyIdentifier: Optional identifier for the stored key
   */
  public init(
    key: SendableCryptoMaterial,
    keyIdentifier: String?=nil
  ) {
    self.key=key
    self.keyIdentifier=keyIdentifier
  }
}

/**
 Types of cryptographic keys.
 */
public enum KeyType: String, Sendable, CaseIterable {
  /// Symmetric encryption key (same key for encryption and decryption)
  case symmetric

  /// Asymmetric encryption key pair (public/private)
  case asymmetric
}

/**
 Supported hash algorithms.
 */
public enum HashAlgorithm: String, Sendable, CaseIterable {
  /// SHA-256 algorithm
  case sha256

  /// SHA-512 algorithm
  case sha512

  /// Blake2b algorithm
  case blake2b
}
