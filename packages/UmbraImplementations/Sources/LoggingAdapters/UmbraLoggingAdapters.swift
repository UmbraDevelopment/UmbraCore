import LoggingInterfaces
import LoggingTypes
import LoggingWrapperInterfaces
import LoggingWrapperServices

/// Facade for LoggingAdapters module
public enum UmbraLoggingAdapters {
  /// Create a new instance of the logger implementation
  /// - Returns: A logger instance conforming to LoggingProtocol
  public static func createLogger() -> LoggingProtocol {
    LoggerImplementation.shared
  }

  /// Create a new logger with a specific configuration
  /// - Parameter destinations: Array of log destinations (must be Sendable types)
  /// - Returns: A logger instance conforming to LoggingProtocol
  public static func createLoggerWithDestinations(_ destinations: [some Sendable])
  -> LoggingProtocol {
    // Use a dedicated initialiser method that properly isolates the destinations
    // This ensures thread safety for Swift 6 compatibility
    LoggerImplementation.withDestinations(destinations)
  }
}
