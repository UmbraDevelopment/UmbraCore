import CoreSecurityTypes
import Foundation

/**
 Domain-specific cryptographic types for security operations.

 This file contains specialised types for cryptographic operations
 that build upon the core security types.
 */

/// Represents a cryptographic key with associated metadata
public struct CryptoKey: Sendable, Equatable {
  /// Unique identifier for the key
  public let id: String

  /// Key material
  private let keyData: Data

  /// Key creation date
  public let creationDate: Date

  /// Optional expiration date
  public let expirationDate: Date?

  /// Key usage purpose
  public let purpose: KeyPurpose

  /// Key algorithm
  public let algorithm: EncryptionAlgorithm

  /// Key metadata
  public let metadata: [String: String]?

  /**
   Initialises a new cryptographic key.

   - Parameters:
     - id: Unique identifier for the key
     - keyData: Raw key material
     - creationDate: Key creation date
     - expirationDate: Optional expiration date
     - purpose: Key usage purpose
     - algorithm: Key algorithm
     - metadata: Optional metadata
   */
  public init(
    id: String,
    keyData: Data,
    creationDate: Date=Date(),
    expirationDate: Date?=nil,
    purpose: KeyPurpose,
    algorithm: EncryptionAlgorithm,
    metadata: [String: String]?=nil
  ) {
    self.id=id
    self.keyData=keyData
    self.creationDate=creationDate
    self.expirationDate=expirationDate
    self.purpose=purpose
    self.algorithm=algorithm
    self.metadata=metadata
  }

  /**
   Securely provides access to the key data.

   - Parameter handler: Closure that receives the key data
   - Returns: The value returned by the handler
   */
  public func withUnsafeKeyData<T>(_ handler: (Data) throws -> T) rethrows -> T {
    try handler(keyData)
  }

  /// Returns whether the key has expired
  public var isExpired: Bool {
    guard let expirationDate else {
      return false
    }
    return Date() > expirationDate
  }
}

/// Defines the purpose of a cryptographic key
public enum KeyPurpose: String, Sendable, Codable, Equatable, CaseIterable {
  /// Encryption key
  case encryption

  /// Signing key
  case signing

  /// Authentication key
  case authentication

  /// Master key
  case master

  /// General purpose key
  case general
}

/// Represents a cryptographic signature
public struct CryptoSignature: Sendable, Equatable {
  /// Signature data
  public let signatureData: Data

  /// Algorithm used for signing
  public let algorithm: HashAlgorithm

  /// Signature creation timestamp
  public let timestamp: Date

  /// Key identifier used for signing
  public let keyIdentifier: String

  /**
   Initialises a new cryptographic signature.

   - Parameters:
     - signatureData: Raw signature data
     - algorithm: Algorithm used for signing
     - timestamp: Signature creation timestamp
     - keyIdentifier: Identifier of the key used for signing
   */
  public init(
    signatureData: Data,
    algorithm: HashAlgorithm,
    timestamp: Date=Date(),
    keyIdentifier: String
  ) {
    self.signatureData=signatureData
    self.algorithm=algorithm
    self.timestamp=timestamp
    self.keyIdentifier=keyIdentifier
  }
}
