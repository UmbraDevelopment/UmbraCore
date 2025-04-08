import DateTimeInterfaces
import DateTimeTypes
import Foundation

/**
 # DateTimeServiceImpl
 
 Implementation of the DateTimeServiceProtocol that provides comprehensive
 date and time operations while abstracting away Foundation dependencies.
 
 This service follows the Alpha Dot Five architecture principles by providing
 a clear separation between interface and implementation, and ensuring thread
 safety through actor isolation.
 
 ## Thread Safety
 
 This implementation is an actor, ensuring all operations are thread-safe
 and can be safely called from multiple concurrent contexts.
 
 ## British Spelling
 
 This implementation uses British spelling conventions where appropriate
 in documentation and public-facing elements.
 */
public actor DateTimeServiceImpl: DateTimeServiceProtocol {
    /// The calendar identifier used for date calculations
    private let calendarIdentifier: String
    
    /// The default locale identifier for formatting operations
    private let localeIdentifier: String
    
    /// The default time zone identifier for operations
    private let timeZoneIdentifier: String
    
    /// The time zone offset in seconds from GMT
    private let timeZoneOffset: Int
    
    /**
     Initialises a new date time service with the specified configuration.
     
     - Parameters:
        - calendarIdentifier: The calendar identifier to use for date calculations
        - localeIdentifier: The locale identifier to use for formatting
        - timeZoneIdentifier: The time zone identifier to use for operations
        - timeZoneOffset: The time zone offset in seconds from GMT
     */
    public init(
        calendarIdentifier: String = "gregorian",
        localeIdentifier: String = "en_GB",
        timeZoneIdentifier: String = "GMT",
        timeZoneOffset: Int = 0
    ) {
        self.calendarIdentifier = calendarIdentifier
        self.localeIdentifier = localeIdentifier
        self.timeZoneIdentifier = timeZoneIdentifier
        self.timeZoneOffset = timeZoneOffset
    }
    
    /**
     Returns a DTO representing the current point in time.
     
     - Returns: A DateTimeDTO representing now
     */
    public func now() async -> DateTimeTypes.DateTimeDTO {
        return DateTimeTypes.DateTimeDTO.now()
    }
    
    /**
     Calculates the time interval between two date time points.
     
     - Parameter from: The starting date time
     - Parameter to: The ending date time
     - Returns: A TimeIntervalDTO representing the duration between dates
     */
    public func timeIntervalBetween(from: DateTimeTypes.DateTimeDTO, to: DateTimeTypes.DateTimeDTO) async -> TimeIntervalDTO {
        let interval = to.timestamp - from.timestamp
        return TimeIntervalDTO(seconds: interval)
    }
    
    /**
     Adds a time interval to a date time point.
     
     - Parameter interval: The interval to add
     - Parameter date: The date to add the interval to
     - Returns: A new DateTimeDTO with the interval added
     */
    public func add(interval: TimeIntervalDTO, to date: DateTimeTypes.DateTimeDTO) async -> DateTimeTypes.DateTimeDTO {
        return date.adding(seconds: interval.seconds)
    }
    
    /**
     Subtracts a time interval from a date time point.
     
     - Parameter interval: The interval to subtract
     - Parameter date: The date to subtract the interval from
     - Returns: A new DateTimeDTO with the interval subtracted
     */
    public func subtract(interval: TimeIntervalDTO, from date: DateTimeTypes.DateTimeDTO) async -> DateTimeTypes.DateTimeDTO {
        return date.subtracting(seconds: interval.seconds)
    }
    
    /**
     Determines if a date time point is before another.
     
     - Parameter date: The date to check
     - Parameter otherDate: The date to compare against
     - Returns: true if date is before otherDate
     */
    public func isBefore(_ date: DateTimeTypes.DateTimeDTO, _ otherDate: DateTimeTypes.DateTimeDTO) async -> Bool {
        return date.timestamp < otherDate.timestamp
    }
    
    /**
     Determines if a date time point is after another.
     
     - Parameter date: The date to check
     - Parameter otherDate: The date to compare against
     - Returns: true if date is after otherDate
     */
    public func isAfter(_ date: DateTimeTypes.DateTimeDTO, _ otherDate: DateTimeTypes.DateTimeDTO) async -> Bool {
        return date.timestamp > otherDate.timestamp
    }
    
    /**
     Formats a date time point as a string using the specified format.
     
     - Parameter date: The date to format
     - Parameter format: The format to use (ISO8601, RFC3339, custom, etc.)
     - Returns: A formatted string representation of the date
     */
    public func format(date: DateTimeTypes.DateTimeDTO, using format: DateTimeFormatDTO) async -> String {
        // For ISO8601 format, use the built-in method on DateTimeDTO
        if format.isPredefined && format.formatString == "ISO8601" {
            return date.iso8601String
        }
        
        // For other formats, delegate to the formatter implementation
        return formatWithImplementation(date: date, using: format)
    }
    
    /**
     Parses a string into a date time point using the specified format.
     
     - Parameter string: The string to parse
     - Parameter format: The format to use for parsing
     - Returns: A DateTimeDTO if parsing was successful, nil otherwise
     */
    public func parse(string: String, using format: DateTimeFormatDTO) async -> DateTimeTypes.DateTimeDTO? {
        // For ISO8601 format, use the built-in method on DateTimeDTO
        if format.isPredefined && format.formatString == "ISO8601" {
            return DateTimeTypes.DateTimeDTO.fromISO8601String(string)
        }
        
        // For other formats, delegate to the formatter implementation
        return parseWithImplementation(string: string, using: format)
    }
    
    // MARK: - Private Helper Methods
    
    /**
     Formats a date using the implementation-specific formatter.
     
     - Parameter date: The date to format
     - Parameter format: The format to use
     - Returns: A formatted string
     */
    private func formatWithImplementation(date: DateTimeTypes.DateTimeDTO, using format: DateTimeFormatDTO) -> String {
        // Use Foundation for formatting
        let formatter = DateFormatter()
        
        // Set locale if provided, otherwise use the service's default
        if let localeIdentifier = format.localeIdentifier {
            formatter.locale = Locale(identifier: localeIdentifier)
        } else {
            formatter.locale = Locale(identifier: self.localeIdentifier)
        }
        
        // Set time zone if provided, otherwise use the service's default
        if let timeZoneIdentifier = format.timeZoneIdentifier {
            formatter.timeZone = TimeZone(identifier: timeZoneIdentifier) ?? TimeZone(identifier: self.timeZoneIdentifier) ?? TimeZone.current
        } else {
            formatter.timeZone = TimeZone(identifier: self.timeZoneIdentifier) ?? TimeZone.current
        }
        
        // Configure the format
        if format.isPredefined {
            switch format.formatString {
            case "ISO8601":
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            case "RFC3339":
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            case "SHORT_DATE":
                formatter.dateStyle = .short
                formatter.timeStyle = .none
            case "MEDIUM_DATE":
                formatter.dateStyle = .medium
                formatter.timeStyle = .none
            case "LONG_DATE":
                formatter.dateStyle = .long
                formatter.timeStyle = .none
            case "SHORT_TIME":
                formatter.dateStyle = .none
                formatter.timeStyle = .short
            case "MEDIUM_TIME":
                formatter.dateStyle = .none
                formatter.timeStyle = .medium
            case "SHORT_DATETIME":
                formatter.dateStyle = .short
                formatter.timeStyle = .short
            case "MEDIUM_DATETIME":
                formatter.dateStyle = .medium
                formatter.timeStyle = .medium
            case "LONG_DATETIME":
                formatter.dateStyle = .long
                formatter.timeStyle = .long
            default:
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            }
        } else {
            formatter.dateFormat = format.formatString
        }
        
        return formatter.string(from: date.toFoundationDate())
    }
    
    /**
     Parses a string using the implementation-specific formatter.
     
     - Parameter string: The string to parse
     - Parameter format: The format to use
     - Returns: A DateTimeDTO if parsing was successful
     */
    private func parseWithImplementation(string: String, using format: DateTimeFormatDTO) -> DateTimeTypes.DateTimeDTO? {
        let formatter = DateFormatter()
        
        // Set locale if provided, otherwise use the service's default
        if let localeIdentifier = format.localeIdentifier {
            formatter.locale = Locale(identifier: localeIdentifier)
        } else {
            formatter.locale = Locale(identifier: self.localeIdentifier)
        }
        
        // Set time zone if provided, otherwise use the service's default
        if let timeZoneIdentifier = format.timeZoneIdentifier {
            formatter.timeZone = TimeZone(identifier: timeZoneIdentifier) ?? TimeZone(identifier: self.timeZoneIdentifier) ?? TimeZone.current
        } else {
            formatter.timeZone = TimeZone(identifier: self.timeZoneIdentifier) ?? TimeZone.current
        }
        
        // Configure the format
        if format.isPredefined {
            switch format.formatString {
            case "ISO8601":
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            case "RFC3339":
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            case "SHORT_DATE":
                formatter.dateStyle = .short
                formatter.timeStyle = .none
            case "MEDIUM_DATE":
                formatter.dateStyle = .medium
                formatter.timeStyle = .none
            case "LONG_DATE":
                formatter.dateStyle = .long
                formatter.timeStyle = .none
            case "SHORT_TIME":
                formatter.dateStyle = .none
                formatter.timeStyle = .short
            case "MEDIUM_TIME":
                formatter.dateStyle = .none
                formatter.timeStyle = .medium
            case "SHORT_DATETIME":
                formatter.dateStyle = .short
                formatter.timeStyle = .short
            case "MEDIUM_DATETIME":
                formatter.dateStyle = .medium
                formatter.timeStyle = .medium
            case "LONG_DATETIME":
                formatter.dateStyle = .long
                formatter.timeStyle = .long
            default:
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            }
        } else {
            formatter.dateFormat = format.formatString
        }
        
        guard let date = formatter.date(from: string) else {
            return nil
        }
        
        return DateTimeTypes.DateTimeDTO.from(date: date)
    }
    
    // MARK: - Date Component Helpers
    
    /**
     Gets the year component from a DateTimeDTO.
     
     - Parameter date: The date to extract the year from
     - Returns: The year component
     */
    private func getYear(from date: DateTimeTypes.DateTimeDTO) -> Int {
        let components = Calendar(identifier: .gregorian).dateComponents([.year], from: date.toFoundationDate())
        return components.year ?? 1970
    }
    
    /**
     Gets the month component from a DateTimeDTO.
     
     - Parameter date: The date to extract the month from
     - Returns: The month component (1-12)
     */
    private func getMonth(from date: DateTimeTypes.DateTimeDTO) -> Int {
        let components = Calendar(identifier: .gregorian).dateComponents([.month], from: date.toFoundationDate())
        return components.month ?? 1
    }
    
    /**
     Gets the day component from a DateTimeDTO.
     
     - Parameter date: The date to extract the day from
     - Returns: The day component (1-31)
     */
    private func getDay(from date: DateTimeTypes.DateTimeDTO) -> Int {
        let components = Calendar(identifier: .gregorian).dateComponents([.day], from: date.toFoundationDate())
        return components.day ?? 1
    }
    
    /**
     Gets the hour component from a DateTimeDTO.
     
     - Parameter date: The date to extract the hour from
     - Returns: The hour component (0-23)
     */
    private func getHour(from date: DateTimeTypes.DateTimeDTO) -> Int {
        let components = Calendar(identifier: .gregorian).dateComponents([.hour], from: date.toFoundationDate())
        return components.hour ?? 0
    }
    
    /**
     Gets the minute component from a DateTimeDTO.
     
     - Parameter date: The date to extract the minute from
     - Returns: The minute component (0-59)
     */
    private func getMinute(from date: DateTimeTypes.DateTimeDTO) -> Int {
        let components = Calendar(identifier: .gregorian).dateComponents([.minute], from: date.toFoundationDate())
        return components.minute ?? 0
    }
    
    /**
     Gets the second component from a DateTimeDTO.
     
     - Parameter date: The date to extract the second from
     - Returns: The second component (0-59)
     */
    private func getSecond(from date: DateTimeTypes.DateTimeDTO) -> Int {
        let components = Calendar(identifier: .gregorian).dateComponents([.second], from: date.toFoundationDate())
        return components.second ?? 0
    }
    
    /**
     Calculates a timestamp from date components.
     
     - Parameters:
        - year: The year
        - month: The month (1-12)
        - day: The day (1-31)
        - hour: The hour (0-23)
        - minute: The minute (0-59)
        - second: The second (0-59)
     - Returns: The timestamp in seconds since 1970-01-01 00:00:00 UTC
     */
    private func calculateTimestamp(year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int) -> Double {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        
        let calendar = Calendar(identifier: .gregorian)
        if let date = calendar.date(from: components) {
            return date.timeIntervalSince1970
        }
        return 0
    }
}
