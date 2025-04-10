import Foundation

/**
 # Checksum Algorithm

 An enumeration of supported cryptographic hash algorithms for file integrity verification.

 ## Alpha Dot Five Architecture

 This type follows the Alpha Dot Five architecture principles:
 - Uses proper enumeration with associated values
 - Implements Sendable for safe concurrent access
 - Provides clear, well-documented cases
 - Uses British spelling in documentation
 */
public enum ChecksumAlgorithm: Sendable, Equatable {
  /// MD5 algorithm (not recommended for security-critical applications)
  case md5

  /// SHA-1 algorithm (legacy, not recommended for security-critical applications)
  case sha1

  /// SHA-256 algorithm
  case sha256

  /// SHA-512 algorithm
  case sha512

  /// Custom algorithm with identifier
  case custom(String)

  /**
   Returns the algorithm name as a string.

   - Returns: String representation of the algorithm
   */
  public var name: String {
    switch self {
      case .md5:
        "MD5"
      case .sha1:
        "SHA-1"
      case .sha256:
        "SHA-256"
      case .sha512:
        "SHA-512"
      case let .custom(name):
        name
    }
  }
}
