import CoreTypesInterfaces
import Foundation

/// Data transfer object for security keys
public struct SecurityKeyDTO: Sendable, Equatable {
  /// Unique identifier for the key
  public let id: String

  /// Algorithm used for this key (e.g., "AES256", "RSA2048")
  public let algorithm: String

  /// The actual key data
  public let keyData: BinaryData

  /// Additional metadata associated with the key
  public let metadata: [String: String]

  /// Initialize a new SecurityKeyDTO
  /// - Parameters:
  ///   - id: Unique identifier for the key
  ///   - algorithm: Algorithm used for this key
  ///   - keyData: The actual key data
  ///   - metadata: Additional metadata associated with the key
  public init(id: String, algorithm: String, keyData: BinaryData, metadata: [String: String]=[:]) {
    self.id=id
    self.algorithm=algorithm
    self.keyData=keyData
    self.metadata=metadata
  }
}
