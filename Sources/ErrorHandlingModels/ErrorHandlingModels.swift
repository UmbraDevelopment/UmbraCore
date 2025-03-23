import Foundation

/// Generic error model
public struct GenericError: Error, Equatable {
  /// Error domain
  public let domain: String
  /// Error code
  public let code: Int
  /// Error description
  public let description: String

  /// Initialize with domain, code and description
  public init(domain: String, code: Int, description: String) {
    self.domain = domain
    self.code = code
    self.description = description
  }

  /// Compare two generic errors
  public static func == (lhs: GenericError, rhs: GenericError) -> Bool {
    lhs.domain == rhs.domain &&
      lhs.code == rhs.code &&
      lhs.description == rhs.description
  }
}
