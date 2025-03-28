import Foundation

/// Domain for date and time related errors
public enum DateTimeErrorDomain {
  /// The identifier for the date and time error domain
  public static let identifier="DateTime"
}

/// Error type for date and time operations
public enum DateTimeError: Int, Error, Sendable, CustomStringConvertible {
  /// Invalid time zone identifier
  case invalidTimeZoneIdentifier=1001
  /// Failed to parse date string
  case dateParsingFailed=1002
  /// Invalid date components provided
  case invalidDateComponents=1003

  /// Get the error domain
  public var domain: String {
    DateTimeErrorDomain.identifier
  }

  /// Get the error code
  public var code: Int {
    rawValue
  }

  /// Get a human-readable description of the error
  public var description: String {
    switch self {
      case .invalidTimeZoneIdentifier:
        "[\(domain):\(code)] The provided time zone identifier is invalid."
      case .dateParsingFailed:
        "[\(domain):\(code)] Failed to parse the date string with the provided format."
      case .invalidDateComponents:
        "[\(domain):\(code)] The provided date components cannot form a valid date."
    }
  }
}
