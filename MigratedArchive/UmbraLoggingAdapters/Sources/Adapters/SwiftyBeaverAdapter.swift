import Foundation
import LoggingWrapper
import LoggingWrapperInterfaces
import UmbraLogging

/// Adapter for converting between UmbraLogging and LoggingWrapper types
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
      case .critical, .fault:
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
    Logger.configure()
    return true
  }
}
