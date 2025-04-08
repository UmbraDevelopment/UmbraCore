import Foundation

/**
 # TimeIntervalDTO
 
 Represents a duration or time interval that abstracts away Foundation's
 TimeInterval type while providing all necessary functionality.
 
 This DTO follows the Alpha Dot Five architecture principles by providing
 a Sendable, value-type representation of time intervals that can be safely
 passed across actor boundaries.
 
 ## Thread Safety
 
 This type is designed to be thread-safe and can be safely used across
 actor boundaries as it conforms to Sendable and uses only immutable properties.
 
 ## British Spelling
 
 This implementation uses British spelling conventions where appropriate
 in documentation and public-facing elements.
 */
public struct TimeIntervalDTO: Sendable, Equatable, Codable {
    /// The interval in seconds
    public let seconds: Double
    
    /**
     Initialises a new time interval DTO.
     
     - Parameter seconds: The interval in seconds
     */
    public init(seconds: Double) {
        self.seconds = seconds
    }
    
    /**
     Creates a time interval representing the specified number of seconds.
     
     - Parameter value: The number of seconds
     - Returns: A TimeIntervalDTO representing the specified duration
     */
    public static func seconds(_ value: Double) -> TimeIntervalDTO {
        return TimeIntervalDTO(seconds: value)
    }
    
    /**
     Creates a time interval representing the specified number of minutes.
     
     - Parameter value: The number of minutes
     - Returns: A TimeIntervalDTO representing the specified duration
     */
    public static func minutes(_ value: Double) -> TimeIntervalDTO {
        return TimeIntervalDTO(seconds: value * 60)
    }
    
    /**
     Creates a time interval representing the specified number of hours.
     
     - Parameter value: The number of hours
     - Returns: A TimeIntervalDTO representing the specified duration
     */
    public static func hours(_ value: Double) -> TimeIntervalDTO {
        return TimeIntervalDTO(seconds: value * 3600)
    }
    
    /**
     Creates a time interval representing the specified number of days.
     
     - Parameter value: The number of days
     - Returns: A TimeIntervalDTO representing the specified duration
     */
    public static func days(_ value: Double) -> TimeIntervalDTO {
        return TimeIntervalDTO(seconds: value * 86400)
    }
    
    /**
     Adds two time intervals together.
     
     - Parameter other: The other time interval to add
     - Returns: A new TimeIntervalDTO representing the sum
     */
    public func adding(_ other: TimeIntervalDTO) -> TimeIntervalDTO {
        return TimeIntervalDTO(seconds: seconds + other.seconds)
    }
    
    /**
     Subtracts another time interval from this one.
     
     - Parameter other: The other time interval to subtract
     - Returns: A new TimeIntervalDTO representing the difference
     */
    public func subtracting(_ other: TimeIntervalDTO) -> TimeIntervalDTO {
        return TimeIntervalDTO(seconds: seconds - other.seconds)
    }
    
    /**
     Multiplies this time interval by a factor.
     
     - Parameter factor: The factor to multiply by
     - Returns: A new TimeIntervalDTO representing the product
     */
    public func multiplying(by factor: Double) -> TimeIntervalDTO {
        return TimeIntervalDTO(seconds: seconds * factor)
    }
    
    /**
     Divides this time interval by a divisor.
     
     - Parameter divisor: The divisor to divide by
     - Returns: A new TimeIntervalDTO representing the quotient
     */
    public func dividing(by divisor: Double) -> TimeIntervalDTO {
        return TimeIntervalDTO(seconds: seconds / divisor)
    }
    
    /**
     Converts this time interval to a Foundation TimeInterval.
     
     This method should only be used when interacting with APIs that
     specifically require Foundation's TimeInterval type. For normal operations,
     use the TimeIntervalDTO methods instead.
     
     - Returns: A Foundation TimeInterval representation of this TimeIntervalDTO
     */
    public func toFoundationTimeInterval() -> TimeInterval {
        return seconds
    }
    
    /**
     Creates a TimeIntervalDTO from a Foundation TimeInterval.
     
     This method should only be used when receiving time intervals from external
     APIs that provide Foundation's TimeInterval type. For normal operations,
     create TimeIntervalDTO instances directly.
     
     - Parameter timeInterval: The Foundation TimeInterval to convert
     - Returns: A TimeIntervalDTO representation of the provided TimeInterval
     */
    public static func from(timeInterval: TimeInterval) -> TimeIntervalDTO {
        return TimeIntervalDTO(seconds: timeInterval)
    }
}
