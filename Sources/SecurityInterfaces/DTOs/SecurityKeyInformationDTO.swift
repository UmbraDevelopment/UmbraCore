import Foundation

/// Data transfer object for key information without exposing the actual key material
public struct SecurityKeyInformationDTO: Sendable, Equatable {
  /// The unique identifier for the key
  public let keyID: String

  /// Algorithm used for this key (e.g., "AES256", "RSA2048")
  public let algorithm: String

  /// Date when the key was created
  public let creationDate: Date

  /// Optional expiry date for the key
  public let expiryDate: Date?

  /// Current status of the key (e.g., "active", "expired", "compromised")
  public let status: String

  /// Additional metadata associated with the key
  public let metadata: [String: String]

  /// Initialize a new SecurityKeyInformationDTO
  /// - Parameters:
  ///   - keyID: The unique identifier for the key
  ///   - algorithm: Algorithm used for this key
  ///   - creationDate: Date when the key was created
  ///   - expiryDate: Optional expiry date for the key
  ///   - status: Current status of the key
  ///   - metadata: Additional metadata associated with the key
  public init(
    keyID: String,
    algorithm: String,
    creationDate: Date,
    expiryDate: Date?=nil,
    status: String,
    metadata: [String: String]=[:]
  ) {
    self.keyID=keyID
    self.algorithm=algorithm
    self.creationDate=creationDate
    self.expiryDate=expiryDate
    self.status=status
    self.metadata=metadata
  }
}
