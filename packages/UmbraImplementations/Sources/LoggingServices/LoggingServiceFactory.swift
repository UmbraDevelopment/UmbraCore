import Foundation
import LoggingInterfaces
import LoggingTypes

/// Factory for creating and configuring logging services
///
/// This factory simplifies the creation of properly configured logging services
/// following the Alpha Dot Five architecture guidelines. It provides standard
/// configurations for common logging scenarios while allowing for customisation.
public enum LoggingServiceFactory {
  /// Create a standard logging service with console output
  /// - Parameters:
  ///   - minimumLevel: Minimum log level to display (defaults to info)
  ///   - formatter: Optional custom formatter to use
  /// - Returns: A configured logging service actor
  public static func createStandardLogger(
    minimumLevel: LoggingTypes.UmbraLogLevel = .info,
    formatter: LoggingInterfaces.LogFormatterProtocol?=nil
  ) -> LoggingServiceActor {
    let consoleDestination=ConsoleLogDestination(
      minimumLevel: minimumLevel,
      formatter: formatter
    )

    return LoggingServiceActor(
      destinations: [consoleDestination],
      minimumLogLevel: minimumLevel,
      formatter: formatter
    )
  }

  /// Create a development logging service with more detailed output
  /// - Parameters:
  ///   - minimumLevel: Minimum log level to display (defaults to debug)
  ///   - formatter: Optional custom formatter to use
  /// - Returns: A configured logging service actor for development
  public static func createDevelopmentLogger(
    minimumLevel: LoggingTypes.UmbraLogLevel = .debug,
    formatter: LoggingInterfaces.LogFormatterProtocol?=nil
  ) -> LoggingServiceActor {
    let consoleDestination=ConsoleLogDestination(
      minimumLevel: minimumLevel,
      formatter: formatter
    )

    return LoggingServiceActor(
      destinations: [consoleDestination],
      minimumLogLevel: minimumLevel,
      formatter: formatter
    )
  }

  /// Create a default logging service with standard configuration
  /// - Returns: A configured logging service actor with default settings
  public static func createDefaultService() async -> LoggingServiceActor {
    // Create a standard logger with info level and default formatter
    let actor=createStandardLogger(
      minimumLevel: .info,
      formatter: StandardLogFormatter()
    )

    // Return the configured actor
    return actor
  }

  /// Create a logging service with custom destinations
  /// - Parameter destinations: The log destinations to use
  /// - Returns: A configured logging service actor with the specified destinations
  public static func createService(destinations: [LoggingTypes.LogDestination]) async
  -> LoggingServiceActor {
    // Create a logger with the specified destinations
    let actor=LoggingServiceActor(
      destinations: destinations,
      minimumLogLevel: .info,
      formatter: StandardLogFormatter()
    )

    // Return the configured actor
    return actor
  }

  /// Create a production logging service with file and console output
  /// - Parameters:
  ///   - logDirectoryPath: Directory to store log files
  ///   - logFileName: Name of the log file (without path)
  ///   - minimumLevel: Minimum log level to display (defaults to info)
  ///   - maxFileSizeMB: Maximum log file size in megabytes before rotation
  ///   - maxBackupCount: Number of backup log files to keep
  ///   - formatter: Optional custom formatter to use
  /// - Returns: A configured logging service actor for production
  public static func createProductionLogger(
    logDirectoryPath: String,
    logFileName: String="umbra.log",
    minimumLevel: LoggingTypes.UmbraLogLevel = .info,
    maxFileSizeMB: UInt64=10,
    maxBackupCount: Int=5,
    formatter: LoggingInterfaces.LogFormatterProtocol?=nil
  ) -> LoggingServiceActor {
    let filePath=(logDirectoryPath as NSString).appendingPathComponent(logFileName)

    let consoleDestination=ConsoleLogDestination(
      identifier: "console-prod",
      minimumLevel: minimumLevel,
      formatter: formatter
    )

    let fileDestination=FileLogDestination(
      identifier: "file-prod",
      filePath: filePath,
      minimumLevel: minimumLevel,
      maxFileSize: maxFileSizeMB * 1024 * 1024,
      maxBackupCount: maxBackupCount,
      formatter: formatter
    )

    return LoggingServiceActor(
      destinations: [consoleDestination, fileDestination],
      minimumLogLevel: minimumLevel,
      formatter: formatter
    )
  }

  /// Create a custom logging service with specified destinations
  /// - Parameters:
  ///   - destinations: Array of log destinations
  ///   - minimumLevel: Global minimum log level
  ///   - formatter: Optional formatter to use
  /// - Returns: A configured logging service actor
  public static func createCustomLogger(
    destinations: [LoggingTypes.LogDestination],
    minimumLevel: LoggingTypes.UmbraLogLevel = .info,
    formatter: LoggingInterfaces.LogFormatterProtocol?=nil
  ) -> LoggingServiceActor {
    LoggingServiceActor(
      destinations: destinations,
      minimumLogLevel: minimumLevel,
      formatter: formatter
    )
  }

  /// Create an OSLog-based logging service
  /// - Parameters:
  ///   - subsystem: The subsystem identifier (typically reverse-DNS bundle identifier)
  ///   - category: The logging category (module or component name)
  ///   - minimumLevel: Minimum log level to display (defaults to info)
  ///   - formatter: Optional custom formatter to use
  /// - Returns: A configured logging service actor that uses OSLog
  public static func createOSLogger(
    subsystem: String,
    category: String,
    minimumLevel: LoggingTypes.UmbraLogLevel = .info,
    formatter: LoggingInterfaces.LogFormatterProtocol?=nil
  ) -> LoggingServiceActor {
    let osLogDestination=OSLogDestination(
      subsystem: subsystem,
      category: category,
      minimumLevel: minimumLevel,
      formatter: formatter
    )

    return LoggingServiceActor(
      destinations: [osLogDestination],
      minimumLogLevel: minimumLevel,
      formatter: formatter
    )
  }

  /// Create a comprehensive logging service with OSLog, file and console output
  /// - Parameters:
  ///   - subsystem: The subsystem identifier for OSLog
  ///   - category: The category for OSLog
  ///   - logDirectoryPath: Directory to store log files
  ///   - logFileName: Name of the log file (without path)
  ///   - minimumLevel: Minimum log level to display (defaults to info)
  ///   - fileMinimumLevel: Minimum level for file logging (defaults to warning)
  ///   - osLogMinimumLevel: Minimum level for OSLog (defaults to info)
  ///   - consoleMinimumLevel: Minimum level for console (defaults to info)
  ///   - maxFileSizeMB: Maximum log file size in megabytes before rotation
  ///   - maxBackupCount: Number of backup log files to keep
  ///   - formatter: Optional custom formatter to use
  /// - Returns: A logging service actor with multiple destinations
  public static func createComprehensiveLogger(
    subsystem: String,
    category: String,
    logDirectoryPath: String,
    logFileName: String="umbra.log",
    minimumLevel: LoggingTypes.UmbraLogLevel = .info,
    fileMinimumLevel: LoggingTypes.UmbraLogLevel = .warning,
    osLogMinimumLevel: LoggingTypes.UmbraLogLevel = .info,
    consoleMinimumLevel: LoggingTypes.UmbraLogLevel = .info,
    maxFileSizeMB: UInt64=10,
    maxBackupCount: Int=5,
    formatter: LoggingInterfaces.LogFormatterProtocol?=nil
  ) -> LoggingServiceActor {
    let filePath=(logDirectoryPath as NSString).appendingPathComponent(logFileName)

    let consoleDestination=ConsoleLogDestination(
      identifier: "console-comprehensive",
      minimumLevel: consoleMinimumLevel,
      formatter: formatter
    )

    let fileDestination=FileLogDestination(
      identifier: "file-comprehensive",
      filePath: filePath,
      minimumLevel: fileMinimumLevel,
      maxFileSize: maxFileSizeMB * 1024 * 1024,
      maxBackupCount: maxBackupCount,
      formatter: formatter
    )

    let osLogDestination=OSLogDestination(
      identifier: "oslog-comprehensive",
      subsystem: subsystem,
      category: category,
      minimumLevel: osLogMinimumLevel,
      formatter: formatter
    )

    return LoggingServiceActor(
      destinations: [consoleDestination, fileDestination, osLogDestination],
      minimumLogLevel: minimumLevel,
      formatter: formatter
    )
  }
}
