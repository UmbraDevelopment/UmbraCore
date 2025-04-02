import Foundation

/**
 # KeyMetadataDTO

 Data transfer object for cryptographic key metadata in the Alpha Dot Five architecture.
 Provides structured information about a cryptographic key, including its usage context,
 creation details, and other relevant attributes.

 This type allows for consistent handling of key metadata across different services
 and modules within the UmbraCore system.
 */
public struct KeyMetadataDTO: Sendable, Equatable {
  /// Unique identifier for the key
  public let keyIdentifier: String

  /// Human-readable name for the key (optional)
  public let name: String?

  /// Creation date of the key
  public let creationDate: Date

  /// Expiration date of the key (if applicable)
  public let expirationDate: Date?

  /// Purpose for which the key is intended
  public let purpose: KeyPurpose

  /// Algorithm used by this key
  public let algorithm: String

  /// Key length in bits
  public let keyLengthBits: Int

  /// Tags associated with this key
  public let tags: [String]

  /// Additional metadata as key-value pairs
  public let additionalMetadata: [String: String]

  /// Whether this key is currently active
  public let isActive: Bool

  /// Create a new key metadata object
  /// - Parameters:
  ///   - keyIdentifier: Unique identifier for the key
  ///   - name: Human-readable name (optional)
  ///   - creationDate: Creation date
  ///   - expirationDate: Expiration date (if applicable)
  ///   - purpose: Purpose for which the key is intended
  ///   - algorithm: Algorithm used by this key
  ///   - keyLengthBits: Key length in bits
  ///   - tags: Tags associated with this key
  ///   - additionalMetadata: Additional metadata as key-value pairs
  ///   - isActive: Whether this key is currently active
  public init(
    keyIdentifier: String,
    name: String?=nil,
    creationDate: Date=Date(),
    expirationDate: Date?=nil,
    purpose: KeyPurpose,
    algorithm: String,
    keyLengthBits: Int,
    tags: [String]=[],
    additionalMetadata: [String: String]=[:],
    isActive: Bool=true
  ) {
    self.keyIdentifier=keyIdentifier
    self.name=name
    self.creationDate=creationDate
    self.expirationDate=expirationDate
    self.purpose=purpose
    self.algorithm=algorithm
    self.keyLengthBits=keyLengthBits
    self.tags=tags
    self.additionalMetadata=additionalMetadata
    self.isActive=isActive
  }
}

/// Purpose for which a cryptographic key is intended
public enum KeyPurpose: String, Sendable, Equatable, CaseIterable {
  /// Key used for encryption operations
  case encryption

  /// Key used for digital signatures
  case signing

  /// Key used for key agreement protocols
  case keyAgreement

  /// Key used for message authentication
  case authentication

  /// Master key used to derive other keys
  case masterKey

  /// Key used for symmetric encryption
  case symmetricEncryption

  /// Key used for asymmetric encryption
  case asymmetricEncryption

  /// General purpose key
  case general
}
