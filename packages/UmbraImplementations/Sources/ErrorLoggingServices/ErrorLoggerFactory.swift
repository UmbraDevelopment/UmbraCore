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
  public static func createDefaultErrorLogger() async -> ErrorLoggingInterfaces
  .ErrorLoggingProtocol {
    // Get the default logging service
    let loggingService=await LoggingServiceFactory.shared.createStandardLogger(
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
    let loggingService=await LoggingServiceFactory.shared.createStandardLogger(
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
    let osLogger=await LoggingServiceFactory.shared.createOSLogger(
      subsystem: subsystem,
      category: category,
      minimumLevel: configuration?.globalMinimumLevel.toUmbraLogLevel() ?? .info
    )

    // Create the error logger with the OSLog logger
    return ErrorLoggerActor(
      logger: osLogger,
      configuration: configuration ?? ErrorLoggerConfiguration()
    )
  }

  /**
   Create a comprehensive error logger with multiple output destinations.

   This method provides an actor-based error logger that outputs to
   multiple destinations including OSLog, console, and file.

   - Parameters:
     - osLogSubsystem: The subsystem identifier for OSLog
     - osLogCategory: The category identifier for OSLog
     - logDirectoryPath: Directory to store log files
     - configuration: Optional custom configuration
   - Returns: An actor-based error logger with multiple output destinations
   */
  public static func createComprehensiveErrorLogger(
    osLogSubsystem: String,
    osLogCategory: String,
    logDirectoryPath: String,
    configuration: ErrorLoggerConfiguration?=nil
  ) async -> ErrorLoggingInterfaces.ErrorLoggingProtocol {
    // Create a comprehensive logger with multiple destinations
    let loggingService=await LoggingServiceFactory.shared.createComprehensiveLogger(
      subsystem: osLogSubsystem,
      category: osLogCategory,
      logDirectoryPath: logDirectoryPath,
      logFileName: "errors.log",
      minimumLevel: configuration?.globalMinimumLevel.toUmbraLogLevel() ?? .info,
      fileMinimumLevel: .warning
    )

    // Create the error logger with the comprehensive logger
    return ErrorLoggerActor(
      logger: loggingService,
      configuration: configuration ?? ErrorLoggerConfiguration()
    )
  }

  /**
   Create an error logger specifically for domain-specific errors.

   This method provides an actor-based error logger optimised for
   handling errors from specific domains with appropriate filtering.

   - Parameters:
     - domains: Array of domain identifiers to include
     - minimumLevel: Minimum error level to log
     - configuration: Optional custom configuration
   - Returns: An actor-based error logger for domain-specific errors
   */
  public static func createDomainSpecificErrorLogger(
    domains: [String],
    minimumLevel: ErrorLoggingLevel,
    configuration: ErrorLoggerConfiguration?=nil
  ) async -> ErrorLoggingInterfaces.ErrorLoggingProtocol {
    // Create a configuration that filters by domain
    let config=configuration ?? ErrorLoggerConfiguration(
      globalMinimumLevel: minimumLevel,
      includeSourceInfo: true
    )

    let loggingService=await LoggingServiceFactory.shared.createStandardLogger(
      minimumLevel: minimumLevel.toUmbraLogLevel()
    )

    // Create a domain-filtered error logger
    let errorLogger=ErrorLoggerActor(
      logger: loggingService,
      configuration: config
    )

    // Set up domain filters for the logger
    for domain in domains {
      await errorLogger.setLogLevel(minimumLevel, forDomain: domain)
    }

    return errorLogger
  }

  /**
   Create a development-focused error logger with detailed output.

   This method provides an actor-based error logger with comprehensive
   details suitable for development and debugging.

   - Parameters:
     - minimumLevel: Minimum error level to log
     - includeSourceInfo: Whether to include source file and line information
   - Returns: An actor-based error logger optimised for development
   */
  public static func createDevelopmentErrorLogger(
    minimumLevel: ErrorLoggingLevel = .debug,
    includeSourceInfo: Bool=true
  ) async -> ErrorLoggingInterfaces.ErrorLoggingProtocol {
    // Create a development-focused configuration
    let config=ErrorLoggerConfiguration(
      globalMinimumLevel: minimumLevel,
      includeSourceInfo: includeSourceInfo
    )
    let loggingService=await LoggingServiceFactory.shared.createStandardLogger(
      minimumLevel: minimumLevel.toUmbraLogLevel()
    )

    // Create the development-focused error logger
    return ErrorLoggerActor(
      logger: loggingService,
      configuration: config
    )
  }
}
