import ErrorLoggingInterfaces
import Foundation
import LoggingInterfaces
import LoggingServices
import LoggingTypes
import UmbraErrors

/**
 # Error Logger Factory

 Factory for creating error logging services that follow the actor-based
 Alpha Dot Five architecture.

 ## Thread Safety

 All loggers created by this factory are actor-based implementations,
 ensuring thread-safe logging operations across concurrent contexts.

 ## Usage Example

 ```swift
 // Create a default error logger
 let errorLogger = await ErrorLoggerFactory.createDefaultErrorLogger()

 // Log an error with automatic context extraction
 await errorLogger.log(someError)

 // Log with custom context
 let context = ErrorContext(
     domain: "SecurityDomain",
     operation: "decryption",
     metadata: ["file": "secret.txt"]
 )
 await errorLogger.logWithContext(error, context: context, level: .error)
 ```
 */
public enum ErrorLoggerFactory {
  /**
   Create a default error logger with standard configuration.

   This method provides an actor-based error logger suitable for
   most application needs with reasonable defaults.

   - Returns: An actor-based error logger with default settings
   */
  public static func createDefaultErrorLogger() async -> ErrorLoggingInterfaces.ErrorLoggingProtocol {
    // Get the default logging service
    let loggingService=LoggingServiceFactory.createStandardLogger(
      minimumLevel: .info
    )

    // Create the error logger with default configuration
    return ErrorLoggerActor(logger: loggingService)
  }

  /**
   Create an error logger with custom configuration.

   This method allows full customisation of the error logger behaviour
   while maintaining the thread-safety benefits of the actor model.

   - Parameters:
     - configuration: Custom error logger configuration
     - loggerIdentifier: Optional identifier for the underlying logger
   - Returns: A configured actor-based error logger instance
   */
  public static func createErrorLogger(
    configuration: ErrorLoggerConfiguration,
    loggerIdentifier _: String="ErrorLogger"
  ) async -> ErrorLoggingInterfaces.ErrorLoggingProtocol {
    // Get a logging service with appropriate level
    let loggingService=LoggingServiceFactory.createStandardLogger(
      minimumLevel: configuration.globalMinimumLevel.toUmbraLogLevel()
    )

    // Create the error logger with the specified configuration
    return ErrorLoggerActor(logger: loggingService, configuration: configuration)
  }

  /**
   Create an error logger that uses OSLog for output.

   This method provides an actor-based error logger that outputs
   through Apple's OSLog system for efficient system-level logging.

   - Parameters:
     - subsystem: The subsystem identifier for OSLog
     - category: The category identifier for OSLog
     - configuration: Optional custom configuration
   - Returns: An actor-based error logger that outputs through OSLog
   */
  public static func createOSLogErrorLogger(
    subsystem: String,
    category: String,
    configuration: ErrorLoggerConfiguration?=nil
  ) async -> ErrorLoggingInterfaces.ErrorLoggingProtocol {
    // Create an OSLog-based logger
    let osLogger=LoggingServiceFactory.createOSLogger(
      subsystem: subsystem,
      category: category,
      minimumLevel: configuration?.globalMinimumLevel.toUmbraLogLevel() ?? .info
    )

    // Create the error logger with appropriate configuration
    if let config=configuration {
      return ErrorLoggerActor(logger: osLogger, configuration: config)
    } else {
      return ErrorLoggerActor(logger: osLogger)
    }
  }

  /**
   Create an error logger with a comprehensive logging setup.

   This method provides an actor-based error logger that outputs to multiple
   destinations simultaneously while maintaining thread safety.

   - Parameters:
     - fileURL: URL for log file output
     - osLogSubsystem: Subsystem for OSLog output
     - osLogCategory: Category for OSLog output
     - configuration: Optional custom configuration
   - Returns: An actor-based error logger that outputs to both file and OSLog
   */
  public static func createComprehensiveErrorLogger(
    fileURL: URL,
    osLogSubsystem: String,
    osLogCategory: String,
    configuration: ErrorLoggerConfiguration?=nil
  ) async -> ErrorLoggingInterfaces.ErrorLoggingProtocol {
    // Create a comprehensive logger with multiple destinations
    let loggingService=LoggingServiceFactory.createComprehensiveLogger(
      subsystem: osLogSubsystem,
      category: osLogCategory,
      logDirectoryPath: fileURL.deletingLastPathComponent().path,
      logFileName: fileURL.lastPathComponent,
      minimumLevel: configuration?.globalMinimumLevel.toUmbraLogLevel() ?? .info,
      fileMinimumLevel: configuration?.globalMinimumLevel.toUmbraLogLevel() ?? .info,
      osLogMinimumLevel: configuration?.globalMinimumLevel.toUmbraLogLevel() ?? .info,
      consoleMinimumLevel: configuration?.globalMinimumLevel.toUmbraLogLevel() ?? .info,
      maxFileSizeMB: 10,
      maxBackupCount: 3
    )

    // Create the error logger with appropriate configuration
    if let config=configuration {
      return ErrorLoggerActor(logger: loggingService, configuration: config)
    } else {
      return ErrorLoggerActor(logger: loggingService)
    }
  }

  /**
   Create an error logger specifically for domain-specific errors.

   This method provides an actor-based error logger pre-configured with
   domain-specific filters and appropriate severity mappings.

   - Parameters:
     - domains: Array of error domains to specifically handle
     - minimumLevel: Minimum logging level for these domains
     - configuration: Optional custom configuration
   - Returns: An actor-based error logger optimised for specific domains
   */
  public static func createDomainSpecificErrorLogger(
    domains: [String],
    minimumLevel: ErrorLoggingLevel,
    configuration: ErrorLoggerConfiguration?=nil
  ) async -> ErrorLoggingInterfaces.ErrorLoggingProtocol {
    // Create base logger with appropriate configuration
    let config=configuration ?? ErrorLoggerConfiguration(
      globalMinimumLevel: .warning,
      includeSourceInfo: true
    )

    let loggingService=LoggingServiceFactory.createStandardLogger(
      minimumLevel: minimumLevel.toUmbraLogLevel()
    )

    // Create the error logger
    let errorLogger=ErrorLoggerActor(logger: loggingService, configuration: config)

    // Set up domain filters
    for domain in domains {
      await errorLogger.setLogLevel(minimumLevel, forDomain: domain)
    }

    return errorLogger
  }

  /**
   Create a comprehensive error logger with enhanced privacy controls and domain filtering.
   
   - Parameters:
     - domains: The domains to include in logging
     - minimumLevel: The minimum level to log
     - configuration: Optional configuration for logger behaviour
   
   - Returns: A properly configured error logger
   */
  public static func createPrivacyAwareErrorLogger(
    domains: [String],
    minimumLevel: ErrorLoggingLevel,
    configuration: ErrorLoggerConfiguration?=nil
  ) async -> ErrorLoggingInterfaces.ErrorLoggingProtocol {
    // Create base logger with appropriate configuration
    let config=configuration ?? ErrorLoggerConfiguration(
      globalMinimumLevel: .warning,
      includeSourceInfo: true
    )
    let loggingService=LoggingServiceFactory.createStandardLogger(
      minimumLevel: minimumLevel.toUmbraLogLevel()
    )

    // Create the error logger
    let errorLogger=ErrorLoggerActor(logger: loggingService, configuration: config)

    // Set up domain filters
    for domain in domains {
      await errorLogger.setLogLevel(minimumLevel, forDomain: domain)
    }

    return errorLogger
  }
}
