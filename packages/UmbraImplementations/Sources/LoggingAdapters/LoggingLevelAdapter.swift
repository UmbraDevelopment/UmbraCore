import LoggingTypes
import LoggingWrapperInterfaces
import LoggingWrapperServices

/// Adapter for converting between UmbraLogLevel and LoggingWrapper.LogLevel
public enum LoggingLevelAdapter {
  /// Convert UmbraLogLevel to LoggingWrapper.LogLevel
  /// - Parameter level: The UmbraLogLevel to convert
  /// - Returns: The equivalent LoggingWrapper.LogLevel
  public static func convertLevel(_ level: UmbraLogLevel) -> LogLevel {
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

  /// Convert LoggingWrapper.LogLevel to UmbraLogLevel
  /// - Parameter level: The LogLevel to convert
  /// - Returns: The equivalent UmbraLogLevel
  public static func convertToUmbraLevel(_ level: LogLevel) -> UmbraLogLevel {
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

  /// Configure the logger with default settings
  /// - Returns: True if configuration was successful
  public static func configureDefaultLogger() -> Bool {
    // Configure the logging wrapper with default settings
    Logger.configure()
    return true
  }
}
