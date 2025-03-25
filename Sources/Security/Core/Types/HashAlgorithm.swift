import Foundation

/// Hash algorithm options for cryptographic hashing
/// Defines standard hash algorithms used across the security framework
public enum HashAlgorithm: String, Sendable, CaseIterable {
  /// SHA-256 hash algorithm (256 bits)
  case sha256 = "SHA256"

  /// SHA-384 hash algorithm (384 bits)
  case sha384 = "SHA384"

  /// SHA-512 hash algorithm (512 bits)
  case sha512 = "SHA512"

  /// The length of the digest in bytes
  public var digestLength: Int {
    switch self {
      case .sha256:
        return 32  // 256 bits = 32 bytes
      case .sha384:
        return 48  // 384 bits = 48 bytes
      case .sha512:
        return 64  // 512 bits = 64 bytes
    }
  }
  
  /// Standard algorithm identifier string
  public var algorithmIdentifier: String {
    self.rawValue
  }
  
  /// Returns the algorithm identifier suitable for the platform's native crypto libraries
  public var platformIdentifier: Int {
    switch self {
      case .sha256:
        return 6  // Corresponds to kCCHmacAlgSHA256 on Apple platforms
      case .sha384:
        return 8  // Custom value for SHA384
      case .sha512:
        return 7  // Corresponds to kCCHmacAlgSHA512 on Apple platforms
    }
  }
}
