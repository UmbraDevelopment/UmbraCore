import CoreDTOs
import DateTimeInterfaces
import DateTimeTypes
import Foundation

/// Foundation-independent adapter for date and time operations
///
/// This class provides a concrete implementation of the DateTimeDTOProtocol,
/// bridging between the Foundation date/time APIs and our foundation-independent
/// DateTimeDTO structure.
public final class DateTimeDTOAdapter: DateTimeDTOProtocol {
  // MARK: - Initialisation

  /// Initialise a new DateTimeDTOAdapter
  public init() {}

  // MARK: - DateTimeDTOProtocol Implementation

  /// Get the current date and time
  /// - Parameter timeZoneOffset: Optional time zone offset (defaults to UTC)
  /// - Returns: Current date and time
  public func now(in timeZoneOffset: DateTimeDTO.TimeZoneOffset?=nil) -> DateTimeDTO {
    let currentDate=Date()
    let timestamp=currentDate.timeIntervalSince1970

    if let offsetToUse=timeZoneOffset {
      return DateTimeDTO(timestamp: timestamp, timeZoneOffset: offsetToUse)
    } else {
      // Default to UTC if no time zone provided
      return DateTimeDTO(timestamp: timestamp, timeZoneOffset: DateTimeDTO.TimeZoneOffset.utc)
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
    let dateFormatter=DateFormatter()

    // Configure the formatter based on DateFormatterDTO properties
    configureFormatter(dateFormatter, with: formatter)

    guard let parsedDate=dateFormatter.date(from: string) else {
      return nil
    }

    let timestamp=parsedDate.timeIntervalSince1970

    // Create a time zone offset based on formatter's time zone
    let secondsFromGMT=dateFormatter.timeZone.secondsFromGMT()
    let totalMinutes=secondsFromGMT / 60
    let timeZoneOffset=DateTimeDTO.TimeZoneOffset(totalMinutes: totalMinutes)

    return DateTimeDTO(timestamp: timestamp, timeZoneOffset: timeZoneOffset)
  }

  /// Configure a Foundation DateFormatter using a DateFormatterDTO
  /// - Parameters:
  ///   - dateFormatter: The Foundation DateFormatter to configure
  ///   - formatterDTO: The DateFormatterDTO to use for configuration
  private func configureFormatter(
    _ dateFormatter: DateFormatter,
    with formatterDTO: DateFormatterDTO
  ) {
    // Set locale if provided
    if let localeIdentifier=formatterDTO.localeIdentifier {
      dateFormatter.locale=Locale(identifier: localeIdentifier)
    }

    // Apply date style
    switch formatterDTO.dateStyle {
      case .none:
        dateFormatter.dateStyle = .none
      case .short:
        dateFormatter.dateStyle = .short
      case .medium:
        dateFormatter.dateStyle = .medium
      case .long:
        dateFormatter.dateStyle = .long
      case .full:
        dateFormatter.dateStyle = .full
      case let .custom(formatString):
        dateFormatter.dateFormat=formatString
    }

    // Apply time style
    switch formatterDTO.timeStyle {
      case .none:
        dateFormatter.timeStyle = .none
      case .short:
        dateFormatter.timeStyle = .short
      case .medium:
        dateFormatter.timeStyle = .medium
      case .long:
        dateFormatter.timeStyle = .long
      case .full:
        dateFormatter.timeStyle = .full
      case let .custom(formatString):
        dateFormatter.dateFormat=formatString
    }
  }

  /// Add a time interval to a date
  /// - Parameters:
  ///   - date: The base date
  ///   - seconds: Seconds to add
  /// - Returns: New date with seconds added
  public func add(to date: DateTimeDTO, seconds: Double) -> DateTimeDTO {
    // Add the seconds to the timestamp
    let newTimestamp=date.timestamp + seconds

    // Return a new DateTimeDTO with the same time zone
    return DateTimeDTO(timestamp: newTimestamp, timeZoneOffset: date.timeZoneOffset)
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
    years: Int,
    months: Int,
    days: Int,
    hours: Int,
    minutes: Int,
    seconds: Int
  ) -> DateTimeDTO {
    // Convert to Foundation Date
    let timestamp=date.timestamp
    let dateValue=Date(timeIntervalSince1970: timestamp)

    // Create date components to add
    var components=DateComponents()
    components.year=years
    components.month=months
    components.day=days
    components.hour=hours
    components.minute=minutes
    components.second=seconds

    // Create calendar in the date's time zone
    let calendar=Calendar.current

    // Convert TimeZoneOffset to Foundation TimeZone
    let tzTotalMinutes=date.timeZoneOffset.totalMinutes
    let timeZone=TimeZone(secondsFromGMT: tzTotalMinutes * 60)!

    var calendarWithTimeZone=calendar
    calendarWithTimeZone.timeZone=timeZone

    // Add the components
    guard let newDate=calendarWithTimeZone.date(byAdding: components, to: dateValue) else {
      return date // Return original if addition fails
    }

    let newTimestamp=newDate.timeIntervalSince1970
    return DateTimeDTO(timestamp: newTimestamp, timeZoneOffset: date.timeZoneOffset)
  }

  /// Calculate the difference between two dates in seconds
  /// - Parameters:
  ///   - date1: First date
  ///   - date2: Second date
  /// - Returns: Difference in seconds
  public func difference(between date1: DateTimeDTO, and date2: DateTimeDTO) -> Double {
    let timestamp1=date1.timestamp
    let timestamp2=date2.timestamp

    return timestamp2 - timestamp1
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

    // Get current seconds from GMT for the time zone
    let secondsFromGMT=timeZone.secondsFromGMT()
    let totalMinutes=secondsFromGMT / 60

    return DateTimeDTO.TimeZoneOffset(totalMinutes: totalMinutes)
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
    hour: Int,
    minute: Int,
    second: Int,
    nanosecond: Int,
    timeZoneOffset: DateTimeDTO.TimeZoneOffset=DateTimeDTO.TimeZoneOffset.utc
  ) -> DateTimeDTO? {
    // Create date components
    var components=DateComponents()
    components.year=year
    components.month=month.rawValue
    components.day=day
    components.hour=hour
    components.minute=minute
    components.second=second
    components.nanosecond=nanosecond

    // Create calendar in the specified time zone
    let calendar=Calendar.current

    // Convert TimeZoneOffset to Foundation TimeZone
    let tzTotalMinutes=timeZoneOffset.totalMinutes
    let timeZone=TimeZone(secondsFromGMT: tzTotalMinutes * 60)!

    var calendarWithTimeZone=calendar
    calendarWithTimeZone.timeZone=timeZone

    // Create the date
    guard let date=calendarWithTimeZone.date(from: components) else {
      return nil
    }

    let timestamp=date.timeIntervalSince1970
    return DateTimeDTO(timestamp: timestamp, timeZoneOffset: timeZoneOffset)
  }
}
