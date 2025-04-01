import Foundation

/**
 Represents a specific point in time with precision suitable for logging and event tracking.
 
 This DTO provides a standardised way to pass timestamp information
 between components while maintaining type safety and ensuring compatibility
 with Alpha Dot Five architecture principles.
 */
public struct TimePointDTO: Sendable, Equatable, Codable {
    /// The date represented as seconds since 1970 (Unix timestamp)
    public let timestamp: TimeInterval
    
    /// Optional nanosecond precision component (0-999999999)
    public let nanoseconds: Int?
    
    /// Optional timezone information as an offset from GMT in seconds
    public let timezoneOffset: Int?
    
    /**
     Initialises a new time point.
     
     - Parameters:
        - timestamp: The date represented as seconds since 1970
        - nanoseconds: Optional nanosecond precision component
        - timezoneOffset: Optional timezone offset from GMT in seconds
     */
    public init(
        timestamp: TimeInterval,
        nanoseconds: Int? = nil,
        timezoneOffset: Int? = nil
    ) {
        self.timestamp = timestamp
        self.nanoseconds = nanoseconds
        self.timezoneOffset = timezoneOffset
    }
    
    /**
     Creates a TimePointDTO representing the current time
     */
    public static func now() -> TimePointDTO {
        let currentDate = Date()
        return TimePointDTO(
            timestamp: currentDate.timeIntervalSince1970,
            timezoneOffset: TimeZone.current.secondsFromGMT()
        )
    }
    
    /**
     Converts the TimePointDTO to a Date object
     */
    public func toDate() -> Date {
        return Date(timeIntervalSince1970: timestamp)
    }
    
    /**
     Returns a string representation of this time point in ISO 8601 format
     */
    public func toISOString() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: toDate())
    }
}
