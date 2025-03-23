import Foundation

/// Data structure for storing encrypted data with its IV
public struct SecureStorageData: Codable, Sendable {
  /// The encrypted data
  public let encryptedData: Data
  /// The initialization vector used for encryption
  public let iv: Data

  /// Initialize a new secure storage data structure
  /// - Parameters:
  ///   - encryptedData: The encrypted data
  ///   - iv: The initialization vector used for encryption
  public init(encryptedData: Data, iv: Data) {
    self.encryptedData=encryptedData
    self.iv=iv
  }
}
