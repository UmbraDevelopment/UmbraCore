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
  public func now(in timeZoneOffset: CoreDTOs.DateTimeDTO.TimeZoneOffset? = nil) -> CoreDTOs.DateTimeDTO {
    let currentDate = Date()
    let timestamp = currentDate.timeIntervalSince1970

    if let offsetToUse = timeZoneOffset {
      return CoreDTOs.DateTimeDTO(timestamp: timestamp, timeZoneOffset: offsetToUse)
    } else {
      // Default to UTC if no time zone provided
      return CoreDTOs.DateTimeDTO(timestamp: timestamp, timeZoneOffset: CoreDTOs.DateTimeDTO.TimeZoneOffset.utc)
    }
  }

  /// Format a date using the specified formatter
  /// - Parameters:
  ///   - date: The date to format
  ///   - formatter: The formatter to use
  /// - Returns: Formatted date string
  public func format(date: CoreDTOs.DateTimeDTO, using formatter: DateFormatterDTO) -> String {
    formatter.format(date)
  }

  /// Parse a date string using the specified formatter
  /// - Parameters:
  ///   - string: The string to parse
  ///   - formatter: The formatter to use
  /// - Returns: Parsed date or nil if parsing failed
  public func parse(string: String, using formatter: DateFormatterDTO) -> CoreDTOs.DateTimeDTO? {
    let dateFormatter = DateFormatter()

    // Configure the formatter based on DateFormatterDTO properties
    switch formatter.dateStyle {
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
      case .custom(let format):
        dateFormatter.dateFormat = format
    }
    
    switch formatter.timeStyle {
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
      case .custom(let format):
        dateFormatter.dateFormat = format
    }

    if let localeIdentifier = formatter.localeIdentifier {
      dateFormatter.locale = Locale(identifier: localeIdentifier)
    }

    // Parse the string
    guard let date = dateFormatter.date(from: string) else {
      return nil
    }

    // Convert to DateTimeDTO
    let timestamp = date.timeIntervalSince1970
    let offset = dateFormatter.timeZone.secondsFromGMT()
    
    // Calculate hours and minutes from seconds
    let hours = abs(offset) / 3600
    let minutes = (abs(offset) % 3600) / 60
    let isPositive = offset >= 0
    
    return CoreDTOs.DateTimeDTO(
      timestamp: timestamp,
      timeZoneOffset: CoreDTOs.DateTimeDTO.TimeZoneOffset(
        hours: hours,
        minutes: minutes,
        isPositive: isPositive
      )
    )
  }

  /// Add seconds to a date
  /// - Parameters:
  ///   - date: The date to add to
  ///   - seconds: Seconds to add
  /// - Returns: New date with seconds added
  public func add(to date: CoreDTOs.DateTimeDTO, seconds: Double) -> CoreDTOs.DateTimeDTO {
    // Add the seconds to the timestamp
    let newTimestamp = date.timestamp + seconds

    // Create a new DateTimeDTO with the updated timestamp
    return CoreDTOs.DateTimeDTO(
      timestamp: newTimestamp,
      timeZoneOffset: date.timeZoneOffset
    )
  }

  /// Add components to a date
  /// - Parameters:
  ///   - date: The date to add to
  ///   - years: Years to add
  ///   - months: Months to add
  ///   - days: Days to add
  ///   - hours: Hours to add
  ///   - minutes: Minutes to add
  ///   - seconds: Seconds to add
  /// - Returns: New date with components added
  public func add(
    to date: CoreDTOs.DateTimeDTO,
    years: Int,
    months: Int,
    days: Int,
    hours: Int,
    minutes: Int,
    seconds: Int
  ) -> CoreDTOs.DateTimeDTO {
    // Convert to Foundation Date
    let timestamp = date.timestamp
    let dateValue = Date(timeIntervalSince1970: timestamp)

    // Create date components to add
    var components = DateComponents()
    components.year = years
    components.month = months
    components.day = days
    components.hour = hours
    components.minute = minutes
    components.second = seconds

    // Add the components
    let calendar = Calendar.current
    guard let newDate = calendar.date(byAdding: components, to: dateValue) else {
      // If addition fails, return the original date
      return date
    }

    // Convert back to DateTimeDTO
    let newTimestamp = newDate.timeIntervalSince1970
    return CoreDTOs.DateTimeDTO(
      timestamp: newTimestamp,
      timeZoneOffset: date.timeZoneOffset
    )
  }

  /// Calculate the difference between two dates in seconds
  /// - Parameters:
  ///   - date1: First date
  ///   - date2: Second date
  /// - Returns: Difference in seconds
  public func difference(between date1: CoreDTOs.DateTimeDTO, and date2: CoreDTOs.DateTimeDTO) -> Double {
    let timestamp1 = date1.timestamp
    let timestamp2 = date2.timestamp

    return timestamp2 - timestamp1
  }

  /// Convert a date to a different time zone
  /// - Parameters:
  ///   - date: The date to convert
  ///   - timeZoneOffset: The target time zone offset
  /// - Returns: Date in the new time zone
  public func convert(
    date: CoreDTOs.DateTimeDTO,
    to timeZoneOffset: CoreDTOs.DateTimeDTO.TimeZoneOffset
  ) -> CoreDTOs.DateTimeDTO {
    let timestamp = date.timestamp

    // The timestamp is always in UTC, so we just need to change the offset
    return CoreDTOs.DateTimeDTO(
      timestamp: timestamp,
      timeZoneOffset: timeZoneOffset
    )
  }

  /// Get the time zone offset for a given identifier
  /// - Parameter identifier: Time zone identifier (e.g., "Europe/London", "America/New_York")
  /// - Returns: Time zone offset or UTC if not found
  public func timeZoneOffset(for identifier: String) -> CoreDTOs.DateTimeDTO.TimeZoneOffset {
    guard let timeZone = TimeZone(identifier: identifier) else {
      return CoreDTOs.DateTimeDTO.TimeZoneOffset.utc
    }

    let seconds = timeZone.secondsFromGMT()
    let hours = abs(seconds) / 3600
    let minutes = (abs(seconds) % 3600) / 60
    let isPositive = seconds >= 0
    
    return CoreDTOs.DateTimeDTO.TimeZoneOffset(
      hours: hours,
      minutes: minutes,
      isPositive: isPositive
    )
  }
  
  /// Get available time zone identifiers
  /// - Returns: Array of available time zone identifiers
  public func availableTimeZoneIdentifiers() -> [String] {
    return TimeZone.knownTimeZoneIdentifiers
  }

  /// Create a date from components
  /// - Parameters:
  ///   - year: Year component
  ///   - month: Month component (1-12)
  ///   - day: Day component (1-31)
  ///   - hour: Hour component (0-23)
  ///   - minute: Minute component (0-59)
  ///   - second: Second component (0-59)
  ///   - nanosecond: Nanosecond component (0-999999999)
  ///   - timeZoneOffset: Time zone offset
  /// - Returns: A DateTimeDTO if valid, nil otherwise
  public func date(
    year: Int,
    month: CoreDTOs.DateTimeDTO.Month,
    day: Int,
    hour: Int,
    minute: Int,
    second: Int,
    nanosecond: Int,
    timeZoneOffset: CoreDTOs.DateTimeDTO.TimeZoneOffset = CoreDTOs.DateTimeDTO.TimeZoneOffset.utc
  ) -> CoreDTOs.DateTimeDTO? {
    // Create date components
    var components = DateComponents()
    components.year = year
    components.month = month.rawValue
    components.day = day
    components.hour = hour
    components.minute = minute
    components.second = second
    components.nanosecond = nanosecond

    // Create calendar with the specified time zone
    var calendar = Calendar(identifier: .gregorian)
    
    // Convert TimeZoneOffset to seconds
    let offsetSeconds = (timeZoneOffset.isPositive ? 1 : -1) * 
                        (timeZoneOffset.hours * 3600 + timeZoneOffset.minutes * 60)
    
    calendar.timeZone = TimeZone(secondsFromGMT: offsetSeconds) ?? TimeZone(identifier: "UTC")!

    // Create the date
    guard let date = calendar.date(from: components) else {
      return nil
    }

    // Convert to DateTimeDTO
    let timestamp = date.timeIntervalSince1970
    return CoreDTOs.DateTimeDTO(
      timestamp: timestamp,
      timeZoneOffset: timeZoneOffset
    )
  }
}
