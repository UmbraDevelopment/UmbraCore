import Foundation

/// Error context implementation
public struct ErrorContext: Equatable {
  /// Domain of the error
  public let domain: String
  /// Code of the error
  public let code: Int
  /// Description of the error
  public let description: String

  /// Initialize with domain, code and description
  public init(domain: String, code: Int, description: String) {
    self.domain=domain
    self.code=code
    self.description=description
  }

  /// Compare two error contexts
  public static func == (lhs: ErrorContext, rhs: ErrorContext) -> Bool {
    lhs.domain == rhs.domain &&
      lhs.code == rhs.code &&
      lhs.description == rhs.description
  }
}
