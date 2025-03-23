import Foundation

/// Extension for converting between Foundation types and DateTimeDTO
extension DateTimeDTO {
  /// Create a DateTimeDTO from a Foundation Date
  /// - Parameters:
  ///   - date: The Date to convert
  ///   - timeZone: The TimeZone to use, defaults to UTC
  /// - Returns: A DateTimeDTO representing the same date and time
  public static func from(
    date: Date,
    timeZone: TimeZone=TimeZone(secondsFromGMT: 0)!
  ) -> DateTimeDTO {
    // Get time zone offset
    let offsetSeconds=timeZone.secondsFromGMT()
    let isPositive=offsetSeconds >= 0
    let absoluteSeconds=abs(offsetSeconds)
    let hours=absoluteSeconds / 3600
    let minutes=(absoluteSeconds % 3600) / 60
    let offset=TimeZoneOffset(hours: hours, minutes: minutes, isPositive: isPositive)

    // Get date components in the specified time zone
    let calendar=Calendar(identifier: .gregorian)
    var calendarTimeZone=calendar
    calendarTimeZone.timeZone=timeZone

    let components=calendarTimeZone.dateComponents(
      [.year, .month, .day, .hour, .minute, .second, .nanosecond],
      from: date
    )

    // Extract components
    let year=components.year ?? 1970
    let month=Month(rawValue: components.month ?? 1) ?? .january
    let day=components.day ?? 1
    let hour=components.hour ?? 0
    let minute=components.minute ?? 0
    let second=components.second ?? 0
    let nanosecond=components.nanosecond ?? 0

    return DateTimeDTO(
      year: year,
      month: month,
      day: day,
      hour: hour,
      minute: minute,
      second: second,
      nanosecond: nanosecond,
      timeZoneOffset: offset
    )
  }

  /// Convert to a Foundation Date
  /// - Returns: A Foundation Date representing the same point in time
  public func toDate() -> Date {
    Date(timeIntervalSince1970: timestamp)
  }
}

/// Extension for converting between Foundation types and DateFormatterDTO
extension DateFormatterDTO {
  /// Create a DateFormatterDTO from a Foundation DateFormatter
  /// - Parameter formatter: The DateFormatter to convert
  /// - Returns: A DateFormatterDTO with equivalent formatting settings
  public static func from(formatter: DateFormatter) -> DateFormatterDTO {
    // Convert date style
    let dateStyle: FormatStyle=switch formatter.dateStyle {
      case .none:
        .none
      case .short:
        .short
      case .medium:
        .medium
      case .long:
        .long
      case .full:
        .full
      @unknown default:
        .medium
    }

    // Convert time style
    let timeStyle: TimeStyle=switch formatter.timeStyle {
      case .none:
        .none
      case .short:
        .short
      case .medium:
        .medium
      case .long:
        .long
      case .full:
        .full
      @unknown default:
        .medium
    }

    // If custom format is set, use that instead
    if !formatter.dateFormat.isEmpty {
      return DateFormatterDTO(
        dateStyle: .custom(formatter.dateFormat),
        timeStyle: .none,
        localeIdentifier: formatter.locale?.identifier
      )
    }

    return DateFormatterDTO(
      dateStyle: dateStyle,
      timeStyle: timeStyle,
      localeIdentifier: formatter.locale?.identifier
    )
  }

  /// Convert to a Foundation DateFormatter
  /// - Returns: A DateFormatter with equivalent formatting settings
  public func toDateFormatter() -> DateFormatter {
    let formatter=DateFormatter()

    // Set locale if provided
    if let localeIdentifier {
      formatter.locale=Locale(identifier: localeIdentifier)
    }

    // Configure date style
    switch dateStyle {
      case .none:
        formatter.dateStyle=DateFormatter.Style.none
      case .short:
        formatter.dateStyle = .short
      case .medium:
        formatter.dateStyle = .medium
      case .long:
        formatter.dateStyle = .long
      case .full:
        formatter.dateStyle = .full
      case let .custom(format):
        formatter.dateFormat=format
        return formatter // Return early for custom format
    }

    // Configure time style
    switch timeStyle {
      case .none:
        formatter.timeStyle=DateFormatter.Style.none
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

    return formatter
  }
}
