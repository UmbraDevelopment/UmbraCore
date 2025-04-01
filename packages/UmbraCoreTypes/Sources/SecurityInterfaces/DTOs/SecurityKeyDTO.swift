import CoreDTOs
import DomainSecurityTypes
import Foundation

/// Data transfer object for security keys
public struct SecurityKeyDTO: Sendable, Equatable {
  /// Unique identifier for the key
  public let id: String

  /// Algorithm used for this key (e.g., "AES256", "RSA2048")
  public let algorithm: String

  /// The actual key data as a byte array
  public let keyData: [UInt8]

  /// Additional metadata associated with the key
  public let metadata: [String: String]

  /// Initialize a new SecurityKeyDTO
  /// - Parameters:
  ///   - id: Unique identifier for the key
  ///   - algorithm: Algorithm used for this key
  ///   - keyData: The actual key data as byte array
  ///   - metadata: Additional metadata associated with the key
  public init(id: String, algorithm: String, keyData: [UInt8], metadata: [String: String]=[:]) {
    self.id=id
    self.algorithm=algorithm
    self.keyData=keyData
    self.metadata=metadata
  }

  /// Equality operator implementation that compares all properties.
  /// - Parameters:
  ///   - lhs: Left-hand side SecurityKeyDTO
  ///   - rhs: Right-hand side SecurityKeyDTO
  /// - Returns: True if the DTOs are considered equal
  public static func == (lhs: SecurityKeyDTO, rhs: SecurityKeyDTO) -> Bool {
    // First check the simple properties
    guard
      lhs.id == rhs.id &&
      lhs.algorithm == rhs.algorithm &&
      lhs.metadata == rhs.metadata
    else {
      return false
    }

    // Then compare the key data bytes
    // Using a constant-time comparison would be better for production code
    return lhs.keyData == rhs.keyData
  }
}
