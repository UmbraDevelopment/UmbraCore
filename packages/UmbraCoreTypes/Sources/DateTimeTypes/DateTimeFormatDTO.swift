import Foundation

/**
 # DateTimeFormatDTO

 Represents a format for displaying or parsing date and time values
 that abstracts away Foundation's DateFormatter.

 This DTO follows the Alpha Dot Five architecture principles by providing
 a Sendable, value-type representation of date formats that can be safely
 passed across actor boundaries.

 ## Thread Safety

 This type is designed to be thread-safe and can be safely used across
 actor boundaries as it conforms to Sendable and uses only immutable properties.

 ## British Spelling

 This implementation uses British spelling conventions where appropriate
 in documentation and public-facing elements.
 */
public struct DateTimeFormatDTO: Sendable, Equatable, Codable {
  /// The format string or predefined format type
  public let formatString: String

  /// The locale identifier for this format
  public let localeIdentifier: String?

  /// The timezone identifier for this format
  public let timeZoneIdentifier: String?

  /// Whether this is a predefined format
  public let isPredefined: Bool

  /**
   Initialises a new date time format DTO with a custom format string.

   - Parameters:
      - formatString: The format string to use
      - localeIdentifier: Optional locale identifier
      - timeZoneIdentifier: Optional timezone identifier
   */
  public init(
    formatString: String,
    localeIdentifier: String?=nil,
    timeZoneIdentifier: String?=nil
  ) {
    self.formatString=formatString
    self.localeIdentifier=localeIdentifier
    self.timeZoneIdentifier=timeZoneIdentifier
    isPredefined=false
  }

  /**
   Initialises a new date time format DTO with a predefined format.

   - Parameters:
      - predefinedFormat: The predefined format to use
      - localeIdentifier: Optional locale identifier
      - timeZoneIdentifier: Optional timezone identifier
   */
  private init(
    predefinedFormat: String,
    localeIdentifier: String?=nil,
    timeZoneIdentifier: String?=nil
  ) {
    formatString=predefinedFormat
    self.localeIdentifier=localeIdentifier
    self.timeZoneIdentifier=timeZoneIdentifier
    isPredefined=true
  }

  /// ISO8601 format (yyyy-MM-dd'T'HH:mm:ss.SSSZ)
  public static func iso8601(
    timeZoneIdentifier: String?="UTC",
    localeIdentifier: String?=nil
  ) -> DateTimeFormatDTO {
    DateTimeFormatDTO(
      predefinedFormat: "ISO8601",
      localeIdentifier: localeIdentifier,
      timeZoneIdentifier: timeZoneIdentifier
    )
  }

  /// RFC3339 format (yyyy-MM-dd'T'HH:mm:ssZ)
  public static func rfc3339(
    timeZoneIdentifier: String?="UTC",
    localeIdentifier: String?=nil
  ) -> DateTimeFormatDTO {
    DateTimeFormatDTO(
      predefinedFormat: "RFC3339",
      localeIdentifier: localeIdentifier,
      timeZoneIdentifier: timeZoneIdentifier
    )
  }

  /// Short date format (e.g., 01/01/2023)
  public static func shortDate(
    localeIdentifier: String?=nil,
    timeZoneIdentifier: String?=nil
  ) -> DateTimeFormatDTO {
    DateTimeFormatDTO(
      predefinedFormat: "SHORT_DATE",
      localeIdentifier: localeIdentifier,
      timeZoneIdentifier: timeZoneIdentifier
    )
  }

  /// Medium date format (e.g., Jan 1, 2023)
  public static func mediumDate(
    localeIdentifier: String?=nil,
    timeZoneIdentifier: String?=nil
  ) -> DateTimeFormatDTO {
    DateTimeFormatDTO(
      predefinedFormat: "MEDIUM_DATE",
      localeIdentifier: localeIdentifier,
      timeZoneIdentifier: timeZoneIdentifier
    )
  }

  /// Long date format (e.g., January 1, 2023)
  public static func longDate(
    localeIdentifier: String?=nil,
    timeZoneIdentifier: String?=nil
  ) -> DateTimeFormatDTO {
    DateTimeFormatDTO(
      predefinedFormat: "LONG_DATE",
      localeIdentifier: localeIdentifier,
      timeZoneIdentifier: timeZoneIdentifier
    )
  }

  /// Short time format (e.g., 12:00 PM)
  public static func shortTime(
    localeIdentifier: String?=nil,
    timeZoneIdentifier: String?=nil
  ) -> DateTimeFormatDTO {
    DateTimeFormatDTO(
      predefinedFormat: "SHORT_TIME",
      localeIdentifier: localeIdentifier,
      timeZoneIdentifier: timeZoneIdentifier
    )
  }

  /// Medium time format (e.g., 12:00:00 PM)
  public static func mediumTime(
    localeIdentifier: String?=nil,
    timeZoneIdentifier: String?=nil
  ) -> DateTimeFormatDTO {
    DateTimeFormatDTO(
      predefinedFormat: "MEDIUM_TIME",
      localeIdentifier: localeIdentifier,
      timeZoneIdentifier: timeZoneIdentifier
    )
  }

  /// Short date and time format (e.g., 01/01/2023 12:00 PM)
  public static func shortDateTime(
    localeIdentifier: String?=nil,
    timeZoneIdentifier: String?=nil
  ) -> DateTimeFormatDTO {
    DateTimeFormatDTO(
      predefinedFormat: "SHORT_DATETIME",
      localeIdentifier: localeIdentifier,
      timeZoneIdentifier: timeZoneIdentifier
    )
  }

  /// Medium date and time format (e.g., Jan 1, 2023 12:00:00 PM)
  public static func mediumDateTime(
    localeIdentifier: String?=nil,
    timeZoneIdentifier: String?=nil
  ) -> DateTimeFormatDTO {
    DateTimeFormatDTO(
      predefinedFormat: "MEDIUM_DATETIME",
      localeIdentifier: localeIdentifier,
      timeZoneIdentifier: timeZoneIdentifier
    )
  }

  /// Long date and time format (e.g., January 1, 2023 at 12:00:00 PM GMT)
  public static func longDateTime(
    localeIdentifier: String?=nil,
    timeZoneIdentifier: String?=nil
  ) -> DateTimeFormatDTO {
    DateTimeFormatDTO(
      predefinedFormat: "LONG_DATETIME",
      localeIdentifier: localeIdentifier,
      timeZoneIdentifier: timeZoneIdentifier
    )
  }
}
