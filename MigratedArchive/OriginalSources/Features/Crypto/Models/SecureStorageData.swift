import Foundation

/// Structure representing encrypted data and its metadata
@frozen
public struct SecureStorageData: Codable, Sendable {
  /// The encrypted data
  public let encryptedData: Data
  /// The initialization vector used for encryption
  public let initializationVector: Data
  /// Salt used for key derivation, if applicable
  public let salt: Data?
  /// Timestamp when the data was stored
  public let timestamp: Date
  /// Version of the encryption format
  public let version: Int

  /// Current version of the storage format
  public static let currentVersion=1

  /// Initialises new secure storage data
  /// - Parameters:
  ///   - encryptedData: The encrypted data
  ///   - initializationVector: The initialization vector used for encryption
  ///   - salt: Salt used for key derivation, if applicable
  ///   - timestamp: When the data was stored (defaults to now)
  ///   - version: Storage format version (defaults to current)
  public init(
    encryptedData: Data,
    initializationVector: Data,
    salt: Data?=nil,
    timestamp: Date=Date(),
    version: Int=SecureStorageData.currentVersion
  ) {
    self.encryptedData=encryptedData
    self.initializationVector=initializationVector
    self.salt=salt
    self.timestamp=timestamp
    self.version=version
  }
}
