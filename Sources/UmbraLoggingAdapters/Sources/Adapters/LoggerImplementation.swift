import Foundation
import LoggingWrapper
import UmbraLogging

/// A thread-safe logging service implementation that wraps LoggingWrapper
public actor LoggerImplementation: LoggingProtocol {
  /// The shared logger instance
  public static let shared=LoggerImplementation()

  /// Initialise the logger with default configuration
  public init() {
    // LoggingWrapper has its own internal configuration
    Logger.configure()
  }

  /// Initialise the logger with specific destinations
  /// - Parameter destinations: Array of log destinations
  private init(destinations _: [Any]) {
    // LoggingWrapper handles destinations internally
    Logger.configure()
  }

  /// Swift 6-compatible factory method to create a logger with specific destinations
  /// - Parameter destinations: Array of Sendable-compliant destinations
  /// - Returns: A new LoggerImplementation instance
  public static func withDestinations(_: [some Sendable]) -> LoggerImplementation {
    // Create a new logger instance with default configuration
    // LoggingWrapper doesn't expose destination configuration in the same way as SwiftyBeaver
    let logger=LoggerImplementation()

    // Configure the logger
    Logger.configure()

    return logger
  }

  /// Log a message at the specified level
  /// - Parameter entry: The log entry to record
  private func log(_ entry: LogEntry) {
    let logLevel=mapToLogLevel(entry.level)

    if let metadata=entry.metadata {
      // If we have metadata, include it in the message
      Logger.log(logLevel, "\(entry.message) | \(metadata)")
    } else {
      Logger.log(logLevel, entry.message)
    }
  }

  /// Maps UmbraLogLevel to LoggingWrapper's LogLevel
  /// - Parameter umbraLevel: The UmbraLogLevel to map
  /// - Returns: The corresponding LogLevel
  private func mapToLogLevel(_ umbraLevel: UmbraLogLevel) -> LogLevel {
    switch umbraLevel {
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

  /// Log a debug message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  public func debug(_ message: String, metadata: LogMetadata?) async {
    log(LogEntry(level: UmbraLogLevel.debug, message: message, metadata: metadata))
  }

  /// Log an info message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  public func info(_ message: String, metadata: LogMetadata?) async {
    log(LogEntry(level: UmbraLogLevel.info, message: message, metadata: metadata))
  }

  /// Log a warning message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  public func warning(_ message: String, metadata: LogMetadata?) async {
    log(LogEntry(level: UmbraLogLevel.warning, message: message, metadata: metadata))
  }

  /// Log an error message
  /// - Parameters:
  ///   - message: The message to log
  ///   - metadata: Optional metadata
  public func error(_ message: String, metadata: LogMetadata?) async {
    log(LogEntry(level: UmbraLogLevel.error, message: message, metadata: metadata))
  }
}
