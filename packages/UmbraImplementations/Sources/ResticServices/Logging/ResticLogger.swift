import Foundation
import LoggingInterfaces
import LoggingTypes

/// Restic-specific logger implementation
public actor ResticLogger {
  // Underlying logger instance
  private let underlyingLogger: any LoggingProtocol

  /// Create a new Restic logger
  public init(logger: any LoggingProtocol) {
    underlyingLogger = logger
  }

  /// Log a message with debug level
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - context: The logging context with metadata
  public func debug(
    _ message: String, 
    context: LogContextDTO
  ) async {
    await underlyingLogger.debug(message, context: context)
  }

  /// Log a message with info level
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - context: The logging context with metadata
  public func info(
    _ message: String, 
    context: LogContextDTO
  ) async {
    await underlyingLogger.info(message, context: context)
  }

  /// Log a message with warning level
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - context: The logging context with metadata
  public func warning(
    _ message: String, 
    context: LogContextDTO
  ) async {
    await underlyingLogger.warning(message, context: context)
  }

  /// Log a message with error level
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - context: The logging context with metadata
  public func error(
    _ message: String, 
    context: LogContextDTO
  ) async {
    await underlyingLogger.error(message, context: context)
  }

  /// Log a message with critical level
  ///
  /// - Parameters:
  ///   - message: The message to log
  ///   - context: The logging context with metadata
  public func critical(
    _ message: String, 
    context: LogContextDTO
  ) async {
    await underlyingLogger.critical(message, context: context)
  }

  /// Log a message with the specified level
  ///
  /// - Parameters:
  ///   - level: The log level
  ///   - message: The message to log
  ///   - context: The logging context with metadata
  public func log(
    _ level: LogLevel,
    _ message: String,
    context: LogContextDTO
  ) async {
    await underlyingLogger.log(level, message, context: context)
  }
}
