import Foundation

/// Service error type for CoreErrors module
public struct ServiceError: Error, Equatable {
  /// Error description
  public let description: String

  /// Initialize with a description
  public init(description: String) {
    self.description=description
  }

  /// Compare two ServiceErrors
  public static func == (lhs: ServiceError, rhs: ServiceError) -> Bool {
    lhs.description == rhs.description
  }
}
