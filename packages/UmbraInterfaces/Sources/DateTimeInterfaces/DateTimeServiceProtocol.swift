import DateTimeTypes
import Foundation

/**
 # DateTimeServiceProtocol

 Provides a standardised interface for date and time operations
 that abstracts away Foundation dependencies.

 This protocol follows the Alpha Dot Five architecture principles
 by providing a clear separation between the interface and implementation,
 allowing for better testability and reduced coupling to Foundation.
 */
public protocol DateTimeServiceProtocol: Sendable {
  /**
   Returns a DTO representing the current point in time.

   - Returns: A DateTimeDTO representing now
   */
  func now() async -> DateTimeTypes.DateTimeDTO

  /**
   Calculates the time interval between two date time points.

   - Parameter from: The starting date time
   - Parameter to: The ending date time
   - Returns: A TimeIntervalDTO representing the duration between dates
   */
  func timeIntervalBetween(from: DateTimeTypes.DateTimeDTO, to: DateTimeTypes.DateTimeDTO) async
    -> TimeIntervalDTO

  /**
   Adds a time interval to a date time point.

   - Parameter interval: The interval to add
   - Parameter date: The date to add the interval to
   - Returns: A new DateTimeDTO with the interval added
   */
  func add(interval: TimeIntervalDTO, to date: DateTimeTypes.DateTimeDTO) async -> DateTimeTypes
    .DateTimeDTO

  /**
   Subtracts a time interval from a date time point.

   - Parameter interval: The interval to subtract
   - Parameter date: The date to subtract the interval from
   - Returns: A new DateTimeDTO with the interval subtracted
   */
  func subtract(interval: TimeIntervalDTO, from date: DateTimeTypes.DateTimeDTO) async
    -> DateTimeTypes.DateTimeDTO

  /**
   Determines if a date time point is before another.

   - Parameter date: The date to check
   - Parameter otherDate: The date to compare against
   - Returns: true if date is before otherDate
   */
  func isBefore(_ date: DateTimeTypes.DateTimeDTO, _ otherDate: DateTimeTypes.DateTimeDTO) async
    -> Bool

  /**
   Determines if a date time point is after another.

   - Parameter date: The date to check
   - Parameter otherDate: The date to compare against
   - Returns: true if date is after otherDate
   */
  func isAfter(_ date: DateTimeTypes.DateTimeDTO, _ otherDate: DateTimeTypes.DateTimeDTO) async
    -> Bool

  /**
   Formats a date time point as a string using the specified format.

   - Parameter date: The date to format
   - Parameter format: The format to use (ISO8601, RFC3339, custom, etc.)
   - Returns: A formatted string representation of the date
   */
  func format(date: DateTimeTypes.DateTimeDTO, using format: DateTimeFormatDTO) async -> String

  /**
   Parses a string into a date time point using the specified format.

   - Parameter string: The string to parse
   - Parameter format: The format to use for parsing
   - Returns: A DateTimeDTO if parsing was successful, nil otherwise
   */
  func parse(string: String, using format: DateTimeFormatDTO) async -> DateTimeTypes.DateTimeDTO?
}
