import Foundation

/**
 * Options for hashing operations.
 *
 * This type encapsulates various parameters that can be used to
 * customise hashing operations.
 */
public struct HashingOptions: Sendable, Equatable {
  /// Algorithm to use for hashing
  public let algorithm: HashAlgorithm

  /// Salt to use for the hashing operation
  public let salt: [UInt8]?

  /// Number of iterations for iterative hashing algorithms
  public let iterations: Int?

  /**
   * Creates new hashing options.
   *
   * - Parameters:
   *   - algorithm: Algorithm to use for hashing
   *   - salt: Optional salt to use for the hashing operation
   *   - iterations: Optional number of iterations for iterative hashing algorithms
   */
  public init(
    algorithm: HashAlgorithm = .sha256,
    salt: [UInt8]?=nil,
    iterations: Int?=nil
  ) {
    self.algorithm=algorithm
    self.salt=salt
    self.iterations=iterations
  }

  /// Default options using SHA-256
  public static let `default`=HashingOptions()

  /// Options for SHA-512 hashing
  public static let sha512=HashingOptions(algorithm: .sha512)

  /// Options for HMAC-SHA-256 with a provided key
  public static func hmacSHA256(key: [UInt8]) -> HashingOptions {
    HashingOptions(algorithm: .hmacSHA256, salt: key)
  }

  /// Options for PBKDF2 with SHA-256 and specified iterations
  public static func pbkdf2(salt: [UInt8], iterations: Int=10000) -> HashingOptions {
    HashingOptions(algorithm: .pbkdf2, salt: salt, iterations: iterations)
  }
}
