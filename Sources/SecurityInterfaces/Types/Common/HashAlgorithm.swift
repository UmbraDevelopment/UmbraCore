import Foundation

/// Hash algorithm options for cryptographic hashing
public enum HashAlgorithm: Sendable, Equatable, Hashable, CaseIterable {
  /// SHA-256 hash algorithm
  case sha256

  /// SHA-512 hash algorithm
  case sha512
  
  /// HMAC-SHA-256 keyed hash algorithm
  case hmacSha256
  
  /// HMAC-SHA-512 keyed hash algorithm
  case hmacSha512

  /// The length of the digest in bytes
  public var digestLength: Int {
    switch self {
      case .sha256, .hmacSha256:
        32 // 256 bits = 32 bytes
      case .sha512, .hmacSha512:
        64 // 512 bits = 64 bytes
    }
  }

  /// String representation of the algorithm for use in configuration
  public var stringValue: String {
    switch self {
      case .sha256:
        return "SHA256"
      case .sha512:
        return "SHA512"
      case .hmacSha256:
        return "HMAC-SHA256"
      case .hmacSha512:
        return "HMAC-SHA512"
    }
  }
  
  /// Initialise from a string representation
  /// - Parameter string: String representation of the algorithm
  /// - Returns: The corresponding HashAlgorithm, or nil if not recognised
  public init?(from string: String) {
    let normalised = string.uppercased()
    switch normalised {
      case "SHA256", "SHA-256":
        self = .sha256
      case "SHA512", "SHA-512":
        self = .sha512
      case "HMAC-SHA256", "HMACSHA256":
        self = .hmacSha256
      case "HMAC-SHA512", "HMACSHA512":
        self = .hmacSha512
      default:
        return nil
    }
  }
}
