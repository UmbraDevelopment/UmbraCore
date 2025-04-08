import Foundation

/**
 # DateTimeDTO

 A comprehensive representation of a date and time that abstracts away
 Foundation's Date type while providing all necessary functionality.

 This DTO follows the Alpha Dot Five architecture principles by providing
 a Sendable, value-type representation of date and time that can be safely
 passed across actor boundaries.

 ## Thread Safety

 This type is designed to be thread-safe and can be safely used across
 actor boundaries as it conforms to Sendable and uses only immutable properties.

 ## British Spelling

 This implementation uses British spelling conventions where appropriate
 in documentation and public-facing elements.
 */
public struct DateTimeDTO: Sendable, Equatable, Codable {
  /// The timestamp in seconds since 1970-01-01 00:00:00 UTC
  public let timestamp: Double

  /// Optional nanosecond precision component (0-999999999)
  public let nanoseconds: Int?

  /// Optional timezone offset from GMT in seconds
  public let timezoneOffset: Int?

  /// Optional calendar identifier for this date time
  public let calendarIdentifier: String?

  /**
   Initialises a new date time DTO.

   - Parameters:
      - timestamp: The timestamp in seconds since 1970-01-01 00:00:00 UTC
      - nanoseconds: Optional nanosecond precision component
      - timezoneOffset: Optional timezone offset from GMT in seconds
      - calendarIdentifier: Optional calendar identifier
   */
  public init(
    timestamp: Double,
    nanoseconds: Int?=nil,
    timezoneOffset: Int?=nil,
    calendarIdentifier: String?=nil
  ) {
    self.timestamp=timestamp
    self.nanoseconds=nanoseconds
    self.timezoneOffset=timezoneOffset
    self.calendarIdentifier=calendarIdentifier
  }

  /**
   Creates a DateTimeDTO representing the current time.

   - Returns: A DateTimeDTO instance representing now
   */
  public static func now() -> DateTimeDTO {
    let currentDate=Date()
    return DateTimeDTO(
      timestamp: currentDate.timeIntervalSince1970,
      timezoneOffset: TimeZone.current.secondsFromGMT()
    )
  }

  /**
   Converts this DateTimeDTO to a Foundation Date.

   This method should only be used when interacting with APIs that
   specifically require Foundation's Date type. For normal operations,
   use the DateTimeServiceProtocol methods instead.

   - Returns: A Foundation Date representation of this DateTimeDTO
   */
  public func toFoundationDate() -> Date {
    Date(timeIntervalSince1970: timestamp)
  }

  /**
   Creates a DateTimeDTO from a Foundation Date.

   This method should only be used when receiving dates from external
   APIs that provide Foundation's Date type. For normal operations,
   create DateTimeDTO instances directly.

   - Parameter date: The Foundation Date to convert
   - Returns: A DateTimeDTO representation of the provided Date
   */
  public static func from(date: Date) -> DateTimeDTO {
    DateTimeDTO(
      timestamp: date.timeIntervalSince1970,
      timezoneOffset: TimeZone.current.secondsFromGMT()
    )
  }

  /**
   Adds a time interval to this date time.

   - Parameter interval: The interval to add in seconds
   - Returns: A new DateTimeDTO with the interval added
   */
  public func adding(seconds interval: Double) -> DateTimeDTO {
    DateTimeDTO(
      timestamp: timestamp + interval,
      nanoseconds: nanoseconds,
      timezoneOffset: timezoneOffset,
      calendarIdentifier: calendarIdentifier
    )
  }

  /**
   Subtracts a time interval from this date time.

   - Parameter interval: The interval to subtract in seconds
   - Returns: A new DateTimeDTO with the interval subtracted
   */
  public func subtracting(seconds interval: Double) -> DateTimeDTO {
    DateTimeDTO(
      timestamp: timestamp - interval,
      nanoseconds: nanoseconds,
      timezoneOffset: timezoneOffset,
      calendarIdentifier: calendarIdentifier
    )
  }

  /**
   Calculates the time interval between this date time and another.

   - Parameter other: The other date time to calculate the interval to
   - Returns: The time interval in seconds
   */
  public func timeIntervalSince(_ other: DateTimeDTO) -> Double {
    timestamp - other.timestamp
  }

  /**
   Creates a DateTimeDTO from an ISO8601 formatted string.

   - Parameter iso8601String: The ISO8601 formatted string to parse
   - Returns: A DateTimeDTO if parsing was successful, nil otherwise
   */
  public static func fromISO8601String(_ iso8601String: String) -> DateTimeDTO? {
    let formatter=ISO8601DateFormatter()
    formatter.formatOptions=[.withInternetDateTime, .withFractionalSeconds]

    if let date=formatter.date(from: iso8601String) {
      return DateTimeDTO.from(date: date)
    }

    // Try again without fractional seconds if the first attempt failed
    formatter.formatOptions=[.withInternetDateTime]
    if let date=formatter.date(from: iso8601String) {
      return DateTimeDTO.from(date: date)
    }

    return nil
  }

  /**
   Returns an ISO8601 formatted string representation of this date time.
   */
  public var iso8601String: String {
    let formatter=ISO8601DateFormatter()
    formatter.formatOptions=[.withInternetDateTime, .withFractionalSeconds]
    return formatter.string(from: toFoundationDate())
  }
}
