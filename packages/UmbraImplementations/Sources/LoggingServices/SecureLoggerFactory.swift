import Foundation
import LoggingInterfaces
import LoggingTypes

/**
 # SecureLoggerFactory

 Factory for creating secure logging components that follow
 the Alpha Dot Five architecture principles.

 This factory provides methods for creating properly configured
 SecureLoggerActor instances with appropriate dependencies
 and integration with the wider logging system.

 ## Usage

 ```swift
 // Create a secure logger with default configuration
 let secureLogger = await SecureLoggerFactory.createSecureLogger(
     category: "AuthenticationService"
 )

 // Log a sensitive operation with privacy tagging
 await secureLogger.securityEvent(
     action: "UserLogin",
     status: .success,
     subject: "user123",
     resource: "UserAccount",
     additionalMetadata: [
         "ipAddress": PrivacyTaggedValue(value: "192.168.1.1", privacyLevel: .private),
         "userAgent": PrivacyTaggedValue(value: "Safari/15.0", privacyLevel: .public)
     ]
 )
 ```
 */
public enum SecureLoggerFactory {
  /**
   Creates a secure logger actor with the specified configuration.

   - Parameters:
      - subsystem: The subsystem identifier (typically the application bundle identifier)
      - category: The category for this logger (typically the component name)
      - includeTimestamps: Whether to include timestamps in log messages
      - loggingServiceActor: Optional logging service actor for integration with the wider logging system

   - Returns: A new SecureLoggerActor instance
   */
  public static func createSecureLogger(
    subsystem: String="com.umbra.security",
    category: String,
    includeTimestamps: Bool=true,
    loggingServiceActor: LoggingServiceActor?=nil
  ) -> SecureLoggerActor {
    SecureLoggerActor(
      subsystem: subsystem,
      category: category,
      includeTimestamps: includeTimestamps,
      loggingServiceActor: loggingServiceActor
    )
  }

  /**
   Creates a secure logger actor that integrates with the default logging system.

   This factory method automatically creates a logger that will send logs both
   to the system logging facility and to the default logging service.

   - Parameters:
      - subsystem: The subsystem identifier
      - category: The category for this logger
      - includeTimestamps: Whether to include timestamps in log messages

   - Returns: A new SecureLoggerActor instance integrated with the default logging service
   */
  public static func createIntegratedSecureLogger(
    subsystem: String="com.umbra.security",
    category: String,
    includeTimestamps: Bool=true
  ) async -> SecureLoggerActor {
    // Create a logging service actor
    let loggingServiceActor=await LoggingServiceFactory.shared.createDefault()

    // Create a secure logger that integrates with the logging service
    return SecureLoggerActor(
      subsystem: subsystem,
      category: category,
      includeTimestamps: includeTimestamps,
      loggingServiceActor: loggingServiceActor
    )
  }
}
