/// LoggingServices Module
///
/// This module provides thread-safe, actor-based logging implementations following
/// the Alpha Dot Five architecture principles. It includes:
///
/// - **LoggingServiceActor**: Core actor-based implementation of LoggingServiceProtocol
/// - **ConsoleLogDestination**: Log destination that writes to standard output
/// - **FileLogDestination**: Log destination that writes to files with rotation support
/// - **LoggingServiceFactory**: Convenience factory for creating common logger configurations
/// - **SecureLoggerActor**: Privacy-focused actor for security-sensitive logging
///
/// ## Usage Example
///
/// ```swift
/// // Create a standard console logger
/// let logger = LoggingServiceFactory.createStandardLogger()
///
/// // Log messages at different levels
/// await logger.info("Application started", metadata: nil, source: "AppDelegate")
/// await logger.warning("Network connectivity limited", metadata: nil, source: "NetworkMonitor")
/// await logger.error("Failed to save file", metadata: LogMetadata(dictionary: ["path":
/// "/tmp/file.txt"]), source: "FileManager")
///
/// // Create a production logger with file output
/// let prodLogger = LoggingServiceFactory.createProductionLogger(
///     logDirectoryPath: "/var/log/myapp"
/// )
///
/// // Create a secure logger for security operations
/// let secureLogger = await LoggingServices.createSecureLogger(category: "Authentication")
///
/// // Log a security event with proper privacy tagging
/// await secureLogger.securityEvent(
///   action: "UserLogin",
///   status: .success,
///   subject: "user@example.com",  // Will be handled as private data
///   additionalMetadata: [
///     "ipAddress": PrivacyTaggedValue(value: "192.168.1.1", privacyLevel: .private)
///   ]
/// )
/// ```
///
/// ## Alpha Dot Five Compliance
///
/// This implementation follows the Alpha Dot Five architectural principles:
///
/// - **Actor-based concurrency**: Thread safety through Swift actors
/// - **Foundation independence**: Core types avoid Foundation dependencies where possible
/// - **British spelling in documentation**: All user-facing documentation uses British English
/// - **Descriptive naming**: All components have clear, descriptive names
/// - **No unnecessary type aliases**: Direct type references are used throughout
///
/// All implementations are Swift 6 compliant with proper concurrency annotations.

@_exported import LoggingInterfaces
@_exported import LoggingTypes

/**
 Main entry point for logging services, providing factory methods
 to create various logging components.
 */
public enum LoggingServices {
  /**
   Creates a logging service with default configuration.

   - Returns: A new logging service actor
   */
  public static func createLogger() async -> LoggingServiceActor {
    await LoggingServiceFactory.createDefaultService()
  }

  /**
   Creates a logging service with the specified destinations.

   - Parameter destinations: The log destinations to use
   - Returns: A new logging service actor
   */
  public static func createLogger(
    destinations: [LoggingTypes.LogDestination]
  ) async -> LoggingServiceActor {
    await LoggingServiceFactory.createService(destinations: destinations)
  }

  /**
   Creates a secure logger for privacy-aware logging of sensitive operations.

   - Parameters:
     - subsystem: The subsystem identifier (defaults to security subsystem)
     - category: The category for this logger (typically the component name)
     - includeTimestamps: Whether to include timestamps in log messages

   - Returns: A new secure logger actor integrated with the default logging service
   */
  public static func createSecureLogger(
    subsystem: String="com.umbra.security",
    category: String,
    includeTimestamps: Bool=true
  ) async -> SecureLoggerActor {
    await SecureLoggerFactory.createIntegratedSecureLogger(
      subsystem: subsystem,
      category: category,
      includeTimestamps: includeTimestamps
    )
  }
}
