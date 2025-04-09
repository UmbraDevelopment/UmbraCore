import ErrorLoggingInterfaces
import Foundation
import LoggingInterfaces
import LoggingServices
import LoggingTypes
import UmbraErrors

/**
 # Error Logger Factory

 Factory for creating error logging services that follow the actor-based
 Alpha Dot Five architecture with privacy-enhanced logging.

 ## Thread Safety

 All loggers created by this factory are actor-based implementations,
 ensuring thread-safe logging operations across concurrent contexts.

 ## Privacy Controls

 The loggers created by this factory implement comprehensive privacy controls
 for sensitive information, following the Alpha Dot Five architecture principles:
 
 - Public information is logged normally
 - Private information is redacted in production builds
 - Sensitive information is always redacted
 - Proper metadata classification ensures compliance with privacy regulations

 ## Usage Example

 ```swift
 // Create a default error logger
 let errorLogger = await ErrorLoggerFactory.createDefault()

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
  public static func createDefault() async -> ErrorLoggingInterfaces
  .ErrorLoggingProtocol {
    // Get the default logging service
    let loggingService = await LoggingServiceFactory.shared.createService(
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
    loggerIdentifier: String = "ErrorLogger"
  ) async -> ErrorLoggingInterfaces.ErrorLoggingProtocol {
    // Get a logging service with appropriate level
    let loggingService = await LoggingServiceFactory.shared.createService(
      minimumLevel: configuration.minimumLevel.toUmbraLogLevel()
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
    configuration: ErrorLoggerConfiguration? = nil
  ) async -> ErrorLoggingInterfaces.ErrorLoggingProtocol {
    // Create an OSLog-based logger
    let osLogger = await LoggingServiceFactory.shared.createOSLogger(
      subsystem: subsystem,
      category: category,
      minimumLevel: configuration?.minimumLevel.toUmbraLogLevel() ?? .info
    )

    // Create the error logger with the specified configuration
    if let configuration {
      return ErrorLoggerActor(logger: osLogger, configuration: configuration)
    } else {
      return ErrorLoggerActor(logger: osLogger)
    }
  }

  /**
   Create an error logger for debugging purposes.

   This method provides a debug-oriented logger with more verbose output
   and relaxed privacy controls, suitable for development environments.

   - Returns: A debug-configured error logger
   */
  public static func createDebugErrorLogger() async -> ErrorLoggingInterfaces.ErrorLoggingProtocol {
    // Use the debug configuration
    let configuration = ErrorLoggerConfiguration.debugConfiguration()
    
    // Create a logger with debug settings
    let loggingService = await LoggingServiceFactory.shared.createService(
      minimumLevel: .debug
    )
    
    // Return the configured logger
    return ErrorLoggerActor(logger: loggingService, configuration: configuration)
  }

  /**
   Create an error logger for production environments.

   This method provides a production-oriented logger with appropriate
   privacy controls and reduced verbosity.

   - Returns: A production-configured error logger
   */
  public static func createProductionErrorLogger() async -> ErrorLoggingInterfaces.ErrorLoggingProtocol {
    // Use the production configuration
    let configuration = ErrorLoggerConfiguration.productionConfiguration()
    
    // Create a logger with production settings
    let loggingService = await LoggingServiceFactory.shared.createService(
      minimumLevel: configuration.minimumLevel.toUmbraLogLevel()
    )
    
    // Return the configured logger
    return ErrorLoggerActor(logger: loggingService, configuration: configuration)
  }

  /**
   Create an error logger for testing environments.

   This method provides a test-oriented logger with balanced
   verbosity and privacy controls.

   - Returns: A test-configured error logger
   */
  public static func createTestingErrorLogger() async -> ErrorLoggingInterfaces.ErrorLoggingProtocol {
    // Use the testing configuration
    let configuration = ErrorLoggerConfiguration.testingConfiguration()
    
    // Create a logger with test settings
    let loggingService = await LoggingServiceFactory.shared.createService(
      minimumLevel: configuration.minimumLevel.toUmbraLogLevel()
    )
    
    // Return the configured logger
    return ErrorLoggerActor(logger: loggingService, configuration: configuration)
  }

  /**
   Create a domain-specific error logger.

   This method provides an error logger that is pre-configured for a specific
   domain, with appropriate filtering and metadata handling.

   - Parameters:
     - domain: The domain this logger will handle
     - minimumLevel: The minimum level to log for this domain
     - configuration: Optional base configuration to extend
   - Returns: A domain-specific error logger
   */
  public static func createDomainErrorLogger(
    domain: String,
    minimumLevel: ErrorLoggingLevel = .info,
    configuration: ErrorLoggerConfiguration? = nil
  ) async -> ErrorLoggingInterfaces.ErrorLoggingProtocol {
    // Create a configuration that filters by domain
    let config = configuration ?? ErrorLoggerConfiguration(
      minimumLevel: minimumLevel,
      includeSourceInfo: true
    )
    
    // Create the base logger
    let errorLogger = await createErrorLogger(configuration: config)
    
    // Set domain-specific filter
    await errorLogger.setLogLevel(minimumLevel, forDomain: domain)
    
    return errorLogger
  }
}

/**
 Extension to convert between error logging levels and Umbra log levels.
 */
extension ErrorLoggingLevel {
  /**
   Convert an ErrorLoggingLevel to the corresponding LogLevel.
   
   - Returns: The equivalent LogLevel for this error logging level
   */
  public func toUmbraLogLevel() -> LogLevel {
    switch self {
      case .debug:
        return .debug
      case .info:
        return .info
      case .warning:
        return .warning
      case .error:
        return .error
      case .critical:
        return .critical
    }
  }
}
