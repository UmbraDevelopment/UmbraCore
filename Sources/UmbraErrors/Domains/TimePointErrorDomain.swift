import Foundation
import UmbraErrorsCore

/// Domain for TimePoint-related errors
public enum TimePointErrorDomain: String, CaseIterable, Sendable {
  /// Domain identifier
  public static let domain="UmbraErrors.TimePoint"

  /// Time format is invalid
  case invalidFormat="INVALID_FORMAT"

  /// Time value is out of range
  case outOfRange="OUT_OF_RANGE"
}

/// Error types specific to UmbraCore TimePoint operations
public enum TimePointError: Error, Equatable, Sendable {
  /// The time format is invalid or malformed
  case invalidFormat

  /// The time value is out of allowed range
  case outOfRange

  /// Get the equivalent UmbraError for this error type
  public func toUmbraError() -> UmbraError {
    switch self {
      case .invalidFormat:
        TimePointErrorDomain.makeInvalidFormatError()
      case .outOfRange:
        TimePointErrorDomain.makeOutOfRangeError()
    }
  }
}

/// Factory methods for TimePoint-related errors
extension TimePointErrorDomain {
  /// Creates an error for invalid time format
  ///
  /// - Parameters:
  ///   - description: Optional custom description
  ///   - source: Optional source of the error
  ///   - underlyingError: Optional underlying error
  ///   - context: Optional error context
  /// - Returns: A fully configured UmbraError
  public static func makeInvalidFormatError(
    description: String="The time format is invalid or malformed",
    source: ErrorSource?=nil,
    underlyingError: Error?=nil,
    context: ErrorContext=ErrorContext()
  ) -> UmbraError {
    ResourceError(
      type: .invalidResource,
      code: TimePointErrorDomain.invalidFormat.rawValue,
      description: description,
      context: context,
      underlyingError: underlyingError,
      source: source
    )
  }

  /// Creates an error for out-of-range time values
  ///
  /// - Parameters:
  ///   - description: Optional custom description
  ///   - source: Optional source of the error
  ///   - underlyingError: Optional underlying error
  ///   - context: Optional error context
  /// - Returns: A fully configured UmbraError
  public static func makeOutOfRangeError(
    description: String="The time value is out of allowed range",
    source: ErrorSource?=nil,
    underlyingError: Error?=nil,
    context: ErrorContext=ErrorContext()
  ) -> UmbraError {
    ResourceError(
      type: .invalidResource,
      code: TimePointErrorDomain.outOfRange.rawValue,
      description: description,
      context: context,
      underlyingError: underlyingError,
      source: source
    )
  }
}
