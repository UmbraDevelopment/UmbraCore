import CoreDTOs
import Foundation
import UmbraCoreTypes

// Local type declarations to replace imports
// These replace the removed ErrorHandling and ErrorHandlingDomains imports

/// Error domain namespace
public enum ErrorDomain {
  /// Security domain
  public static let security="Security"
  /// Crypto domain
  public static let crypto="Crypto"
  /// Application domain
  public static let application="Application"
}

/// Error context protocol
public protocol ErrorContext {
  /// Domain of the error
  var domain: String { get }
  /// Code of the error
  var code: Int { get }
  /// Description of the error
  var description: String { get }
}

/// Base error context implementation
public struct BaseErrorContext: ErrorContext {
  /// Domain of the error
  public let domain: String
  /// Code of the error
  public let code: Int
  /// Description of the error
  public let description: String

  /// Initialise with domain, code and description
  public init(domain: String, code: Int, description: String) {
    self.domain=domain
    self.code=code
    self.description=description
  }
}

/// Foundation-independent adapter for date and time operations
public class DateTimeDTOAdapter: DateTimeDTOProtocol {
  // MARK: - Initialization

  /// Initialize a new DateTimeDTOAdapter
  public init() {}

  // MARK: - DateTimeDTOProtocol Implementation

  /// Get the current date and time
  /// - Parameter timeZoneOffset: Optional time zone offset (defaults to UTC)
  /// - Returns: Current date and time
  public func now(in timeZoneOffset: DateTimeDTO.TimeZoneOffset?=nil) -> DateTimeDTO {
    let currentDate=Date()

    if let offset=timeZoneOffset {
      // Convert to specified time zone
      let timeZone=TimeZone(secondsFromGMT: offset.totalMinutes * 60) ??
        TimeZone(secondsFromGMT: 0)!
      return DateTimeDTO.from(date: currentDate, timeZone: timeZone)
    } else {
      // Use UTC
      return DateTimeDTO.from(date: currentDate, timeZone: TimeZone(secondsFromGMT: 0)!)
    }
  }

  /// Format a date using the specified formatter
  /// - Parameters:
  ///   - date: The date to format
  ///   - formatter: The formatter to use
  /// - Returns: Formatted date string
  public func format(date: DateTimeDTO, using formatter: DateFormatterDTO) -> String {
    formatter.format(date)
  }

  /// Parse a date string using the specified formatter
  /// - Parameters:
  ///   - string: The string to parse
  ///   - formatter: The formatter to use
  /// - Returns: Parsed date or nil if parsing failed
  public func parse(string: String, using formatter: DateFormatterDTO) -> DateTimeDTO? {
    let dateFormatter=formatter.toDateFormatter()

    if let parsedDate=dateFormatter.date(from: string) {
      let timeZone=dateFormatter.timeZone ?? TimeZone(secondsFromGMT: 0)!
      return DateTimeDTO.from(date: parsedDate, timeZone: timeZone)
    }

    return nil
  }

  /// Add a time interval to a date
  /// - Parameters:
  ///   - date: The base date
  ///   - seconds: Seconds to add
  /// - Returns: New date with seconds added
  public func add(to date: DateTimeDTO, seconds: Double) -> DateTimeDTO {
    // Convert to Foundation Date
    let foundationDate=date.toDate()

    // Add seconds
    let newDate=foundationDate.addingTimeInterval(seconds)

    // Convert back to DateTimeDTO
    let timeZone=TimeZone(secondsFromGMT: date.timeZoneOffset.totalMinutes * 60) ??
      TimeZone(secondsFromGMT: 0)!
    return DateTimeDTO.from(date: newDate, timeZone: timeZone)
  }

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
  public func add(
    to date: DateTimeDTO,
    years: Int=0,
    months: Int=0,
    days: Int=0,
    hours: Int=0,
    minutes: Int=0,
    seconds: Int=0
  ) -> DateTimeDTO {
    // Convert to Foundation Date
    let foundationDate=date.toDate()

    // Create calendar in the correct time zone
    let calendar=Calendar(identifier: .gregorian)
    let timeZone=TimeZone(secondsFromGMT: date.timeZoneOffset.totalMinutes * 60) ??
      TimeZone(secondsFromGMT: 0)!
    var calendarWithTimeZone=calendar
    calendarWithTimeZone.timeZone=timeZone

    // Create date components to add
    var dateComponents=DateComponents()
    dateComponents.year=years
    dateComponents.month=months
    dateComponents.day=days
    dateComponents.hour=hours
    dateComponents.minute=minutes
    dateComponents.second=seconds

    // Add components
    if let newDate=calendarWithTimeZone.date(byAdding: dateComponents, to: foundationDate) {
      return DateTimeDTO.from(date: newDate, timeZone: timeZone)
    }

    // Return original date if calculation fails
    return date
  }

  /// Calculate the difference between two dates in seconds
  /// - Parameters:
  ///   - date1: First date
  ///   - date2: Second date
  /// - Returns: Difference in seconds
  public func difference(between date1: DateTimeDTO, and date2: DateTimeDTO) -> Double {
    date2.timestamp - date1.timestamp
  }

  /// Convert a date to a different time zone
  /// - Parameters:
  ///   - date: The date to convert
  ///   - timeZoneOffset: Target time zone offset
  /// - Returns: Date in the new time zone
  public func convert(
    date: DateTimeDTO,
    to timeZoneOffset: DateTimeDTO.TimeZoneOffset
  ) -> DateTimeDTO {
    // Use the timestamp to preserve the exact same moment in time
    let timestamp=date.timestamp
    return DateTimeDTO(timestamp: timestamp, timeZoneOffset: timeZoneOffset)
  }

  /// Get time zone offset for a specific time zone identifier
  /// - Parameter identifier: Time zone identifier (e.g., "Europe/London", "America/New_York")
  /// - Returns: Time zone offset or UTC if not found
  public func timeZoneOffset(for identifier: String) -> DateTimeDTO.TimeZoneOffset {
    guard let timeZone=TimeZone(identifier: identifier) else {
      return DateTimeDTO.TimeZoneOffset.utc
    }

    let offsetSeconds=timeZone.secondsFromGMT()
    let isPositive=offsetSeconds >= 0
    let absoluteSeconds=abs(offsetSeconds)
    let hours=absoluteSeconds / 3600
    let minutes=(absoluteSeconds % 3600) / 60

    return DateTimeDTO.TimeZoneOffset(
      hours: hours,
      minutes: minutes,
      isPositive: isPositive
    )
  }

  /// Get available time zone identifiers
  /// - Returns: Array of available time zone identifiers
  public func availableTimeZoneIdentifiers() -> [String] {
    TimeZone.knownTimeZoneIdentifiers
  }

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
  public func date(
    year: Int,
    month: DateTimeDTO.Month,
    day: Int,
    hour: Int=0,
    minute: Int=0,
    second: Int=0,
    nanosecond: Int=0,
    timeZoneOffset: DateTimeDTO.TimeZoneOffset=DateTimeDTO.TimeZoneOffset.utc
  ) -> DateTimeDTO? {
    // Create calendar components
    var components=DateComponents()
    components.year=year
    components.month=month.rawValue
    components.day=day
    components.hour=hour
    components.minute=minute
    components.second=second
    components.nanosecond=nanosecond

    // Set time zone
    let timeZone=TimeZone(secondsFromGMT: timeZoneOffset.totalMinutes * 60) ??
      TimeZone(secondsFromGMT: 0)!
    components.timeZone=timeZone

    // Create calendar
    let calendar=Calendar(identifier: .gregorian)

    // Create date
    if let date=calendar.date(from: components) {
      return DateTimeDTO.from(date: date, timeZone: timeZone)
    }

    return nil
  }
}
