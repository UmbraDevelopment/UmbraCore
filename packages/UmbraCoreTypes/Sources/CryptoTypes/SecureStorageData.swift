import DomainSecurityTypes
import Foundation

/// Data structure for storing encrypted data with its IV
public struct SecureStorageData: Codable, Sendable {
  /// The encrypted data
  public let encryptedData: [UInt8]
  /// The initialisation vector used for encryption
  public let iv: [UInt8]

  /// Initialise a new secure storage data structure
  /// - Parameters:
  ///   - encryptedData: The encrypted data
  ///   - iv: The initialisation vector used for encryption
  public init(encryptedData: [UInt8], iv: [UInt8]) {
    self.encryptedData=encryptedData
    self.iv=iv
  }

  /// Convert to a Data object for persistence
  /// - Returns: Data object containing serialised storage data
  public func toData() throws -> Data {
    try JSONEncoder().encode(self)
  }

  /// Create SecureStorageData from serialised data
  /// - Parameter data: Serialised data
  /// - Returns: SecureStorageData instance
  public static func from(data: Data) throws -> SecureStorageData {
    try JSONDecoder().decode(SecureStorageData.self, from: data)
  }
}
