import CoreSecurityTypes
import Foundation

/**
 Options for hashing operations.

 This struct defines the options that can be used when performing hashing operations
 through the security interfaces. It allows specifying the algorithm and whether to
 use salt for the hashing operation.
 */
public struct HashingOptions: Sendable, Codable, Equatable {
  /// The hashing algorithm to use
  public let algorithm: CoreSecurityTypes.HashAlgorithm

  /// Salt data to use for the hashing operation (if applicable)
  public let salt: [UInt8]?

  /**
   Initialises a new HashingOptions instance.

   - Parameters:
      - algorithm: The hashing algorithm to use
      - salt: Optional salt data to use for the hashing operation
   */
  public init(
    algorithm: CoreSecurityTypes.HashAlgorithm = .sha256,
    salt: [UInt8]?=nil
  ) {
    self.algorithm=algorithm
    self.salt=salt
  }
}
