import DomainSecurityTypes

/// Data structure for storing encrypted data with its IV
public struct SecureStorageData: Codable, Sendable {
  /// The encrypted data
  public let encryptedData: SecureBytes
  /// The initialization vector used for encryption
  public let iv: SecureBytes

  /// Initialize a new secure storage data structure
  /// - Parameters:
  ///   - encryptedData: The encrypted data
  ///   - iv: The initialization vector used for encryption
  public init(encryptedData: SecureBytes, iv: SecureBytes) {
    self.encryptedData=encryptedData
    self.iv=iv
  }
}
