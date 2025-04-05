import CoreSecurityTypes
import CryptoTypes
import Foundation

/**
 Options for configuring hashing operations.

 These options control the algorithm and parameters used for hashing operations.
 */
public struct HashingOptions: Sendable, Equatable {
  /// The hash algorithm to use
  public let algorithm: CoreSecurityTypes.HashAlgorithm

  /// Default initialiser
  /// - Parameter algorithm: The hash algorithm to use (defaults to SHA-256)
  public init(
    algorithm: CoreSecurityTypes.HashAlgorithm = .sha256
  ) {
    self.algorithm=algorithm
  }
}
