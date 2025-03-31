import CoreDTOs
import Foundation

/// Protocol defining a Foundation-independent interface for date and time operations
public protocol DateTimeDTOProtocol: Sendable {
  /// Get the current date and time
  /// - Parameter timeZoneOffset: Optional time zone offset (defaults to UTC)
  /// - Returns: Current date and time
  func now(in timeZoneOffset: DateTimeDTO.TimeZoneOffset?) -> DateTimeDTO

  /// Format a date using the specified formatter
  /// - Parameters:
  ///   - date: The date to format
  ///   - formatter: The formatter to use
  /// - Returns: Formatted date string
  func format(date: DateTimeDTO, using formatter: DateFormatterDTO) -> String

  /// Parse a date string using the specified formatter
  /// - Parameters:
  ///   - string: The string to parse
  ///   - formatter: The formatter to use
  /// - Returns: Parsed date or nil if parsing failed
  func parse(string: String, using formatter: DateFormatterDTO) -> DateTimeDTO?

  /// Add a time interval to a date
  /// - Parameters:
  ///   - date: The base date
  ///   - seconds: Seconds to add
  /// - Returns: New date with seconds added
  func add(to date: DateTimeDTO, seconds: Double) -> DateTimeDTO

  /// Add calendar components to a date
  /// - Parameters:
  ///   - date: The base date
  ///   - years: Years to add
  ///   - months: Months to add
  ///   - days: Days to add
  ///   - hours: Hours to add
  ///   - minutes: Minutes to add
  ///   - seconds: Seconds to add
  /// - Returns: New date with components added
  func add(
    to date: DateTimeDTO,
    years: Int,
    months: Int,
    days: Int,
    hours: Int,
    minutes: Int,
    seconds: Int
  ) -> DateTimeDTO

  /// Calculate the difference between two dates in seconds
  /// - Parameters:
  ///   - date1: First date
  ///   - date2: Second date
  /// - Returns: Difference in seconds
  func difference(between date1: DateTimeDTO, and date2: DateTimeDTO) -> Double

  /// Convert a date to a different time zone
  /// - Parameters:
  ///   - date: The date to convert
  ///   - timeZoneOffset: Target time zone offset
  /// - Returns: Date in the new time zone
  func convert(date: DateTimeDTO, to timeZoneOffset: DateTimeDTO.TimeZoneOffset) -> DateTimeDTO

  /// Get time zone offset for a specific time zone identifier
  /// - Parameter identifier: Time zone identifier (e.g., "Europe/London", "America/New_York")
  /// - Returns: Time zone offset or UTC if not found
  func timeZoneOffset(for identifier: String) -> DateTimeDTO.TimeZoneOffset

  /// Get available time zone identifiers
  /// - Returns: Array of available time zone identifiers
  func availableTimeZoneIdentifiers() -> [String]

  /// Create a date from components
  /// - Parameters:
  ///   - year: Year component
  ///   - month: Month component
  ///   - day: Day component
  ///   - hour: Hour component
  ///   - minute: Minute component
  ///   - second: Second component
  ///   - nanosecond: Nanosecond component
  ///   - timeZoneOffset: Time zone offset
  /// - Returns: Created date or nil if invalid
  func date(
    year: Int,
    month: DateTimeDTO.Month,
    day: Int,
    hour: Int,
    minute: Int,
    second: Int,
    nanosecond: Int,
    timeZoneOffset: DateTimeDTO.TimeZoneOffset
  ) -> DateTimeDTO?
}
