import Foundation

/// Hash algorithm options for cryptographic hashing
public enum HashAlgorithm: Sendable, Equatable, Hashable {
  /// SHA-256 hash algorithm
  case sha256

  /// SHA-512 hash algorithm
  case sha512

  /// The length of the digest in bytes
  public var digestLength: Int {
    switch self {
      case .sha256:
        32 // 256 bits = 32 bytes
      case .sha512:
        64 // 512 bits = 64 bytes
    }
  }

  /// String representation of the algorithm for use in configuration
  public var stringValue: String {
    switch self {
      case .sha256:
        "SHA256"
      case .sha512:
        "SHA512"
    }
  }
}
