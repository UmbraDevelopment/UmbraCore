/// UmbraLogging Module
///
/// Provides a comprehensive logging framework for UmbraCore with support
/// for multiple logging destinations, log levels, and structured logging.
///
/// # Key Features
/// - Structured logging
/// - Multiple log levels
/// - Secure logging practices
/// - Performance optimisation
///
/// # Module Organisation
///
/// ## Core Types
/// ```swift
/// Logger
/// LogEntry
/// LogLevel
/// ```
///
/// ## Destinations
/// ```swift
/// FileDestination
/// ConsoleDestination
/// NetworkDestination
/// ```
///
/// ## Formatters
/// ```swift
/// LogFormatter
/// JSONFormatter
/// TextFormatter
/// ```
///
/// # Log Levels
/// Supported logging levels:
/// - Trace: Detailed debugging
/// - Debug: Development information
/// - Info: General information
/// - Notice: Important events
/// - Warning: Potential issues
/// - Error: Runtime errors
/// - Critical: System failures
///
/// # Security Considerations
///
/// ## Sensitive Data
/// The logging system automatically:
/// - Redacts sensitive information
/// - Sanitises user data
/// - Filters credentials
///
/// ## Log Storage
/// Secure log storage with:
/// - Encryption at rest
/// - Rotation policies
/// - Retention limits
///
/// # Performance
/// Optimised logging implementation:
/// - Asynchronous logging
/// - Buffer management
/// - Resource limiting
///
/// # Usage Example
/// ```swift
/// let logger = Logger.shared
///
/// logger.info("Operation completed",
///            metadata: [
///                "duration": duration,
///                "status": "success"
///            ])
/// ```
///
/// # Integration
/// Integrates with system logging:
/// - os_log integration
/// - Unified logging
/// - Console.app support
///
/// # Thread Safety
/// The logging system is thread-safe:
/// - Concurrent log writing
/// - Atomic operations
/// - Queue isolation
public enum UmbraLogging {
  /// Current version of the UmbraLogging module
  public static let version="1.0.0"

  /// Initialise UmbraLogging with default configuration
  public static func initialise() {
    // Configure logging system
  }

  /// Create a new instance of the logger
  /// - Returns: A logger instance conforming to LoggingProtocol
  public static func createLogger() -> LoggingProtocol {
    // This will be replaced at build time by the UmbraLoggingAdapters module
    #if canImport(UmbraLoggingAdapters)
      return UmbraLoggingAdapters.createLogger()
    #else
      // Use a fallback console logger for testing
      return FallbackConsoleLogger()
    #endif
  }

  /// Create a new logger with specific destinations
  /// - Parameter destinations: Array of log destinations
  /// - Returns: A logger instance conforming to LoggingProtocol
  public static func createLoggerWithDestinations(_ destinations: [Any]) -> LoggingProtocol {
    #if canImport(UmbraLoggingAdapters)
      return UmbraLoggingAdapters.createLoggerWithDestinations(destinations)
    #else
      // Use a fallback console logger for testing
      return FallbackConsoleLogger()
    #endif
  }
}

/// A simple fallback console logger for use in tests when UmbraLoggingAdapters is not available
private final class FallbackConsoleLogger: LoggingProtocol {
  func debug(_ message: String, metadata _: LogMetadata?) async {
    print("[DEBUG] \(message)")
  }

  func info(_ message: String, metadata _: LogMetadata?) async {
    print("[INFO] \(message)")
  }

  func warning(_ message: String, metadata _: LogMetadata?) async {
    print("[WARNING] \(message)")
  }

  func error(_ message: String, metadata _: LogMetadata?) async {
    print("[ERROR] \(message)")
  }
}
