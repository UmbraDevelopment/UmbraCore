import LoggingTypes
import LoggingWrapperInterfaces
import LoggingWrapperServices

/**
 # Logging Level Adapter
 
 Converts between different logging level types in the Alpha Dot Five architecture.
 This adapter bridges the gap between our core logging types and the wrapper implementation.
 */
public enum LoggingLevelAdapter {
  /**
   Convert UmbraLogLevel to LoggingWrapper.LogLevel
   
   - Parameter level: The UmbraLogLevel to convert
   - Returns: The equivalent LoggingWrapper.LogLevel
   */
  public static func convertLevel(_ level: LoggingTypes.UmbraLogLevel) -> LoggingWrapperInterfaces.LogLevel {
    switch level {
      case .verbose:
        return .trace
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

  /**
   Convert LoggingTypes.LogLevel to UmbraLogLevel
   
   - Parameter level: The LogLevel to convert
   - Returns: The equivalent UmbraLogLevel
   */
  public static func convertFromCoreLogLevel(_ level: LoggingTypes.LogLevel) -> LoggingTypes.UmbraLogLevel {
    switch level {
      case .trace:
        return .verbose
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

  /**
   Convert LoggingWrapper.LogLevel to UmbraLogLevel
   
   - Parameter level: The LogLevel to convert
   - Returns: The equivalent UmbraLogLevel
   */
  public static func convertToUmbraLevel(_ level: LoggingWrapperInterfaces.LogLevel) -> LoggingTypes.UmbraLogLevel {
    switch level {
      case .trace:
        return .verbose
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

  /**
   Configure the logger with default settings
   
   - Returns: True if configuration was successful
   */
  public static func configureDefaultLogger() -> Bool {
    // Configure the logging wrapper with default settings
    Logger.configure()
    return true
  }
}
