import Foundation

// MARK: - Concrete Error Types (No Type Aliases)

/// Resource error implementation - replaces typealias with concrete type
public struct ResourceError: Error, Equatable {
  /// Error description
  public let description: String

  /// Initialize with a description
  public init(description: String) {
    self.description=description
  }

  /// Compare two ResourceErrors
  public static func == (lhs: ResourceError, rhs: ResourceError) -> Bool {
    lhs.description == rhs.description
  }
}

/// Security error implementation - replaces typealias with concrete type
public struct SecurityError: Error, Equatable {
  /// Error description
  public let description: String

  /// Initialize with a description
  public init(description: String) {
    self.description=description
  }

  /// Compare two SecurityErrors
  public static func == (lhs: SecurityError, rhs: SecurityError) -> Bool {
    lhs.description == rhs.description
  }
}

// MARK: - Error Types Definition

/// Error types specific to UmbraCoreTypes SecureBytes
public enum SecureBytesError: Error, Equatable {
  case invalidHexString
  case outOfBounds
  case allocationFailed
}

/// Error types specific to UmbraCoreTypes TimePoint
public enum TimePointError: Error, Equatable {
  case invalidFormat
  case outOfRange
}
