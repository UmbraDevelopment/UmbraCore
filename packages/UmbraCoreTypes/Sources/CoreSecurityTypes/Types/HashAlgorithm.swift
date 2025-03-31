import Foundation

/**
 Defines the supported cryptographic hash algorithms in the security subsystem.

 This enumeration follows the architecture pattern for type-safe
 representation of domain concepts.
 */
public enum HashAlgorithm: String, Sendable, Codable, Equatable, CaseIterable {
  /// SHA-256 hash algorithm
  case sha256="SHA-256"

  /// SHA-512 hash algorithm
  case sha512="SHA-512"

  /// BLAKE2b hash algorithm
  case blake2b="BLAKE2b"

  /// Returns a human-readable description of the algorithm
  public var localizedDescription: String {
    switch self {
      case .sha256:
        "SHA-256"
      case .sha512:
        "SHA-512"
      case .blake2b:
        "BLAKE2b"
    }
  }

  /// Returns the output size in bytes for this hash algorithm
  public var outputSizeBytes: Int {
    switch self {
      case .sha256:
        32
      case .sha512:
        64
      case .blake2b:
        64
    }
  }
}
