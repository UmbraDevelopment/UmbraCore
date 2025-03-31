/**
 # Security Type Definitions

 Core type definitions for the security interfaces in the Alpha Dot Five architecture.
 These types provide strong typing and structured data models for security operations
 following the Alpha Dot Five principles.
 */

import Foundation

/**
 Defines signature algorithms for cryptographic signing operations.
 */
public enum SignatureAlgorithm: String, Sendable, Equatable, CaseIterable {
  /// ECDSA signature using the P256 curve
  case ecdsaP256

  /// ECDSA signature using the P384 curve
  case ecdsaP384

  /// RSA signature with PKCS#1 padding
  case rsaPKCS1

  /// RSA signature with PSS padding
  case rsaPSS

  /// Ed25519 signature
  case ed25519
}

/**
 Defines signing algorithms for cryptographic operations.
 */
public typealias SigningAlgorithm=SignatureAlgorithm

/**
 Configuration for secure storage operations.
 */
public struct SecureStorageConfig: Sendable, Equatable {
  /// Access control options for the stored data
  public let accessControl: SecureStorageAccessControl

  /// Whether to encrypt the data before storage
  public let encrypt: Bool

  /// Additional context data for the operation
  public let context: [String: String]

  /**
   Initialises a new secure storage configuration.

   - Parameters:
      - accessControl: Access control options
      - encrypt: Whether to encrypt the data
      - context: Additional context data
   */
  public init(
    accessControl: SecureStorageAccessControl = .standard,
    encrypt: Bool=true,
    context: [String: String]=[:]
  ) {
    self.accessControl=accessControl
    self.encrypt=encrypt
    self.context=context
  }
}

/**
 Access control options for secure storage.
 */
public enum SecureStorageAccessControl: String, Sendable, Equatable {
  /// Standard access control (application-only)
  case standard

  /// Biometric authentication required
  case biometric

  /// User presence required
  case userPresence

  /// Biometric or password required
  case biometricOrPassword
}

/**
 Configuration for decryption operations.
 */
public struct DecryptionConfig: Sendable, Equatable {
  /// Cryptographic algorithm to use
  public let algorithm: String?

  /// Key size in bits
  public let keySize: Int?

  /// Additional options for the operation
  public let options: [String: String]

  /**
   Initialises a new decryption configuration.

   - Parameters:
      - algorithm: Cryptographic algorithm
      - keySize: Key size in bits
      - options: Additional options
   */
  public init(
    algorithm: String?=nil,
    keySize: Int?=nil,
    options: [String: String]=[:]
  ) {
    self.algorithm=algorithm
    self.keySize=keySize
    self.options=options
  }
}

/**
 Result of a decryption operation.
 */
public struct DecryptionResult: Sendable, Equatable {
  /// The decrypted data
  public let data: Data

  /// Additional metadata from the operation
  public let metadata: [String: String]

  /**
   Initialises a new decryption result.

   - Parameters:
      - data: The decrypted data
      - metadata: Additional metadata
   */
  public init(data: Data, metadata: [String: String]=[:]) {
    self.data=data
    self.metadata=metadata
  }
}

/**
 Result of a digital signature operation.
 */
public struct SignatureResult: Sendable, Equatable {
  /// The generated signature
  public let signature: Data

  /// Algorithm used for the signature
  public let algorithm: SignatureAlgorithm

  /// Additional metadata from the operation
  public let metadata: [String: String]

  /**
   Initialises a new signature result.

   - Parameters:
      - signature: The generated signature
      - algorithm: Algorithm used
      - metadata: Additional metadata
   */
  public init(
    signature: Data,
    algorithm: SignatureAlgorithm,
    metadata: [String: String]=[:]
  ) {
    self.signature=signature
    self.algorithm=algorithm
    self.metadata=metadata
  }
}

/**
 Result of a signature verification operation.
 */
public struct VerificationResult: Sendable, Equatable {
  /// Whether the signature is valid
  public let isValid: Bool

  /// Additional metadata from the operation
  public let metadata: [String: String]

  /**
   Initialises a new verification result.

   - Parameters:
      - isValid: Whether the signature is valid
      - metadata: Additional metadata
   */
  public init(isValid: Bool, metadata: [String: String]=[:]) {
    self.isValid=isValid
    self.metadata=metadata
  }
}

/**
 Result of a secure storage operation.
 */
public struct StorageResult: Sendable, Equatable {
  /// Whether the operation was successful
  public let success: Bool

  /// Identifier for the stored data
  public let identifier: String

  /// Additional metadata from the operation
  public let metadata: [String: String]

  /**
   Initialises a new storage result.

   - Parameters:
      - success: Whether the operation was successful
      - identifier: Identifier for the stored data
      - metadata: Additional metadata
   */
  public init(
    success: Bool,
    identifier: String,
    metadata: [String: String]=[:]
  ) {
    self.success=success
    self.identifier=identifier
    self.metadata=metadata
  }
}

/**
 Result of a secure retrieval operation.
 */
public struct RetrievalResult: Sendable, Equatable {
  /// Retrieved data
  public let data: Data?

  /// Whether the operation was successful
  public let success: Bool

  /// Additional metadata from the operation
  public let metadata: [String: String]

  /**
   Initialises a new retrieval result.

   - Parameters:
      - data: Retrieved data
      - success: Whether the operation was successful
      - metadata: Additional metadata
   */
  public init(
    data: Data?,
    success: Bool,
    metadata: [String: String]=[:]
  ) {
    self.data=data
    self.success=success
    self.metadata=metadata
  }
}

/**
 Result of a secure deletion operation.
 */
public struct DeletionResult: Sendable, Equatable {
  /// Whether the operation was successful
  public let success: Bool

  /// Additional metadata from the operation
  public let metadata: [String: String]

  /**
   Initialises a new deletion result.

   - Parameters:
      - success: Whether the operation was successful
      - metadata: Additional metadata
   */
  public init(success: Bool, metadata: [String: String]=[:]) {
    self.success=success
    self.metadata=metadata
  }
}
