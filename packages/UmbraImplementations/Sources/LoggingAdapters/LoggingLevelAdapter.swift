import LoggingInterfaces
import LoggingTypes
import LoggingWrapperServices

/**
 # Logging Level Adapter

 Converts between different logging level types in the Alpha Dot Five architecture.
 This adapter bridges the gap between our core logging types and the wrapper implementation.
 */
public enum LoggingLevelAdapter {
  /**
   Convert UmbraLogLevel to LoggingInterfaces.LogLevel

   - Parameter level: The UmbraLogLevel to convert
   - Returns: The equivalent LoggingInterfaces.LogLevel
   */
  public static func convertLevel(_ level: LoggingTypes.UmbraLogLevel) -> LoggingInterfaces
  .LogLevel {
    switch level {
      case .verbose:
        .trace
      case .debug:
        .debug
      case .info:
        .info
      case .warning:
        .warning
      case .error:
        .error
      case .critical:
        .critical
    }
  }

  /**
   Convert LoggingInterfaces.LogLevel to UmbraLogLevel

   - Parameter level: The LoggingInterfaces.LogLevel to convert
   - Returns: The equivalent UmbraLogLevel
   */
  public static func convertToUmbraLevel(_ level: LoggingInterfaces.LogLevel) -> LoggingTypes
  .UmbraLogLevel {
    switch level {
      case .trace:
        .verbose
      case .debug:
        .debug
      case .info:
        .info
      case .warning:
        .warning
      case .error:
        .error
      case .critical:
        .critical
    }
  }

  /**
   Convert LoggingTypes.LogLevel to UmbraLogLevel

   - Parameter level: The LogLevel to convert
   - Returns: The equivalent UmbraLogLevel
   */
  public static func convertFromCoreLogLevel(_ level: LoggingTypes.LogLevel) -> LoggingTypes
  .UmbraLogLevel {
    switch level {
      case .trace:
        .verbose
      case .debug:
        .debug
      case .info:
        .info
      case .warning:
        .warning
      case .error:
        .error
      case .critical:
        .critical
    }
  }

  /**
   Configure the default logger with standard settings.

   This sets up the logging wrapper with standard settings.

   - Returns: True if configuration was successful
   */
  public static func configureDefaultLogger() -> Bool {
    // Configure the logging wrapper with default settings
    Logger.configure(.standard)
    return true
  }
}
