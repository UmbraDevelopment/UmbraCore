import Foundation
import DateTimeInterfaces
import DateTimeTypes

/**
 # DateTimeServiceFactory
 
 Factory for creating DateTimeServiceProtocol implementations.
 This factory follows the Alpha Dot Five architecture pattern
 of providing asynchronous factory methods that return actor-based
 implementations.
 
 ## Usage Examples
 
 ```swift
 // Create a default implementation
 let dateTimeService = await DateTimeServiceFactory.createDefault()
 
 // Create a service with custom locale and time zone
 let customService = await DateTimeServiceFactory.createWithLocale(
   locale: Locale(identifier: "en_GB"),
   timeZone: TimeZone(identifier: "Europe/London")!
 )
 ```
 */
public enum DateTimeServiceFactory {
    /**
     Creates a default date time service implementation.
     
     - Returns: A DateTimeServiceProtocol implementation
     */
    public static func createDefault() async -> DateTimeServiceProtocol {
        return DateTimeServiceImpl()
    }
    
    /**
     Creates a date time service with the specified locale and time zone.
     
     - Parameters:
        - locale: The locale to use for formatting
        - timeZone: The time zone to use for operations
        - calendar: The calendar to use for date calculations
     - Returns: A DateTimeServiceProtocol implementation
     */
    public static func createWithLocale(
        locale: Locale,
        timeZone: TimeZone,
        calendar: Calendar = .current
    ) async -> DateTimeServiceProtocol {
        return DateTimeServiceImpl(
            calendarIdentifier: String(describing: calendar.identifier),
            localeIdentifier: locale.identifier,
            timeZoneIdentifier: timeZone.identifier,
            timeZoneOffset: timeZone.secondsFromGMT()
        )
    }
    
    /**
     Creates a date time service for the British locale.
     
     - Parameter timeZone: Optional time zone, defaults to London
     - Returns: A DateTimeServiceProtocol implementation
     */
    public static func createBritishLocale(
        timeZone: TimeZone = TimeZone(identifier: "Europe/London") ?? .current
    ) async -> DateTimeServiceProtocol {
        let britishLocale = Locale(identifier: "en_GB")
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = britishLocale
        calendar.timeZone = timeZone
        
        return DateTimeServiceImpl(
            calendarIdentifier: String(describing: calendar.identifier),
            localeIdentifier: britishLocale.identifier,
            timeZoneIdentifier: timeZone.identifier,
            timeZoneOffset: timeZone.secondsFromGMT()
        )
    }
    
    /**
     Creates a date time service for UTC operations.
     
     - Parameter locale: Optional locale, defaults to current
     - Returns: A DateTimeServiceProtocol implementation
     */
    public static func createUTC(
        locale: Locale = .current
    ) async -> DateTimeServiceProtocol {
        let utcTimeZone = TimeZone(identifier: "UTC") ?? .current
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = utcTimeZone
        
        return DateTimeServiceImpl(
            calendarIdentifier: String(describing: calendar.identifier),
            localeIdentifier: locale.identifier,
            timeZoneIdentifier: utcTimeZone.identifier,
            timeZoneOffset: utcTimeZone.secondsFromGMT()
        )
    }
}
