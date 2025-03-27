import Foundation

/// A Foundation-independent representation of date formatting options.
///
/// `DateFormatterDTO` provides a configurable way to format dates and times
/// without relying on Foundation's `DateFormatter`. It supports various
/// predefined styles as well as custom format patterns.
///
/// ## Overview
/// This formatter offers:
/// - Predefined date and time styles (short, medium, long, full)
/// - Custom format patterns
/// - Locale-aware formatting
/// - Time zone handling
///
/// ## Example Usage
/// ```swift
/// // Create a formatter for a long date with short time
/// let formatter = DateFormatterDTO(
///     dateStyle: .long,
///     timeStyle: .short,
///     localeIdentifier: "en_GB"
/// )
///
/// // Format a date
/// let date = DateTimeDTO(year: 2025, month: .january, day: 15)
/// let formatted = formatter.format(date)  // "15 January 2025, 00:00"
///
/// // Create a custom formatter
/// let customFormatter = DateFormatterDTO.custom("yyyy-MM-dd'T'HH:mm:ss")
/// let iso8601String = customFormatter.format(date)  // "2025-01-15T00:00:00"
/// ```
public struct DateFormatterDTO: Sendable, Equatable, Hashable {
  // MARK: - Types

  /// Date format style.
  ///
  /// Defines how the date portion should be formatted, with options ranging
  /// from compact representations to fully spelled out forms.
  public enum FormatStyle: Sendable, Equatable, Hashable {
    /// No style - don't display this component.
    /// Used when you want to show only the date or only the time.
    case none
    /// Short style (e.g., "12/31/23").
    /// A compact, numeric representation suitable for space-constrained interfaces.
    case short
    /// Medium style (e.g., "Dec 31, 2023").
    /// A balance between brevity and readability with abbreviated month names.
    case medium
    /// Long style (e.g., "December 31, 2023").
    /// A more verbose format with full month names.
    case long
    /// Full style (e.g., "Sunday, December 31, 2023").
    /// The most comprehensive format including the day of the week.
    case full
    /// Custom format string using strftime-like format.
    /// Allows for complete customisation of the date format.
    case custom(String)
  }

  /// Time format style.
  ///
  /// Defines how the time portion should be formatted, with options ranging
  /// from no time representation to fully spelled out forms.
  public enum TimeStyle: Sendable, Equatable, Hashable {
    /// No time.
    /// Excludes the time component entirely from the formatted string.
    case none
    /// Short style (e.g., "12:30 PM").
    /// A concise time format with hours and minutes.
    case short
    /// Medium style (e.g., "12:30:45 PM").
    /// A standard time format including seconds.
    case medium
    /// Long style (e.g., "12:30:45 PM GMT").
    /// A more detailed time format with time zone abbreviation.
    case long
    /// Full style (e.g., "12:30:45 PM Greenwich Mean Time").
    /// The most comprehensive time format with the full time zone name.
    case full
    /// Custom format string using strftime-like format.
    /// Allows for complete customisation of the time format.
    case custom(String)
  }

  // MARK: - Properties

  /// Date format style.
  public let dateStyle: FormatStyle

  /// Time format style.
  public let timeStyle: TimeStyle

  /// Locale identifier (e.g., "en_US", "fr_FR").
  ///
  /// The locale affects how dates and times are formatted according to
  /// regional preferences and conventions.
  public let localeIdentifier: String?

  // MARK: - Initialization

  /// Initialize with format styles.
  ///
  /// - Parameters:
  ///   - dateStyle: Date format style, defaults to `.medium`
  ///   - timeStyle: Time format style, defaults to `.medium`
  ///   - localeIdentifier: Optional locale identifier (e.g., "en_GB")
  ///
  /// Creates a formatter with the specified date and time styles, optionally
  /// using a specific locale.
  public init(
    dateStyle: FormatStyle = .medium,
    timeStyle: TimeStyle = .medium,
    localeIdentifier: String?=nil
  ) {
    self.dateStyle=dateStyle
    self.timeStyle=timeStyle
    self.localeIdentifier=localeIdentifier
  }

  // MARK: - Formatting Methods

  /// Format a DateTimeDTO as a string.
  ///
  /// - Parameter date: Date to format
  /// - Returns: Formatted date string
  ///
  /// This method applies the configured style settings to produce a formatted
  /// representation of the provided date and time.
  public func format(_ date: DateTimeDTO) -> String {
    // Convert to Foundation Date for formatting
    let timestamp=date.timestamp
    let foundationDate=Date(timeIntervalSince1970: timestamp)

    // Create DateFormatter
    let formatter=DateFormatter()

    // Set locale if provided
    if let localeIdentifier {
      formatter.locale=Locale(identifier: localeIdentifier)
    }

    // Set time zone
    formatter.timeZone=TimeZone(secondsFromGMT: date.timeZoneOffset.totalMinutes * 60)

    // Configure date style
    switch dateStyle {
      case .none:
        formatter.dateFormat=""
      case .short:
        formatter.dateStyle = .short
      case .medium:
        formatter.dateStyle = .medium
      case .long:
        formatter.dateStyle = .long
      case .full:
        formatter.dateStyle = .full
      case let .custom(format):
        // Custom format for date part
        formatter.dateFormat=format
    }

    // Configure time style if using predefined styles
    if case .custom=dateStyle {
      // Already handled in date format
    } else {
      switch timeStyle {
        case .none:
          formatter.timeStyle = .none
        case .short:
          formatter.timeStyle = .short
        case .medium:
          formatter.timeStyle = .medium
        case .long:
          formatter.timeStyle = .long
        case .full:
          formatter.timeStyle = .full
        case let .custom(format):
          // For custom time format with predefined date format,
          // we need to combine them
          let dateFormat=formatter.dateFormat ?? ""
          formatter.dateFormat="\(dateFormat) \(format)"
      }
    }

    return formatter.string(from: foundationDate)
  }

  // MARK: - Static Factory Methods

  /// Create a date-only formatter.
  ///
  /// - Parameters:
  ///   - style: Date format style, defaults to `.medium`
  ///   - localeIdentifier: Optional locale identifier (e.g., "en_GB")
  ///
  /// Creates a formatter configured for date-only formatting.
  public static func dateOnly(
    style: FormatStyle = .medium,
    localeIdentifier: String?=nil
  ) -> DateFormatterDTO {
    DateFormatterDTO(
      dateStyle: style,
      timeStyle: .none,
      localeIdentifier: localeIdentifier
    )
  }

  /// Create a time-only formatter.
  ///
  /// - Parameters:
  ///   - style: Time format style, defaults to `.medium`
  ///   - localeIdentifier: Optional locale identifier (e.g., "en_GB")
  ///
  /// Creates a formatter configured for time-only formatting.
  public static func timeOnly(
    style: TimeStyle = .medium,
    localeIdentifier: String?=nil
  ) -> DateFormatterDTO {
    DateFormatterDTO(
      dateStyle: .none,
      timeStyle: style,
      localeIdentifier: localeIdentifier
    )
  }

  /// Create a formatter with ISO 8601 format.
  ///
  /// Returns a formatter configured for ISO 8601 format.
  public static func iso8601() -> DateFormatterDTO {
    DateFormatterDTO(
      dateStyle: .custom("yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"),
      timeStyle: .none
    )
  }

  /// Create a formatter with a custom format string.
  ///
  /// - Parameters:
  ///   - format: Custom format string
  ///   - localeIdentifier: Optional locale identifier (e.g., "en_GB")
  ///
  /// Creates a formatter with the specified custom format.
  public static func custom(
    format: String,
    localeIdentifier: String?=nil
  ) -> DateFormatterDTO {
    DateFormatterDTO(
      dateStyle: .custom(format),
      timeStyle: .none,
      localeIdentifier: localeIdentifier
    )
  }
}
